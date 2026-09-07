using System.Threading;
using System.Windows;

namespace NoNap.Windows;

public partial class App : System.Windows.Application
{
    private const string MutexName = "Local\\NoNap.Windows.Singleton";
    private const string ExitEventName = "Local\\NoNap.Windows.ExitForUninstall";
    private Mutex? _instanceMutex;
    private EventWaitHandle? _exitEvent;
    private RegisteredWaitHandle? _exitRegistration;
    private PowerController? _powerController;
    private bool _ownsMutex;

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        var restoreOnly = e.Args.Contains("--restore-and-exit", StringComparer.OrdinalIgnoreCase);
        _instanceMutex = new Mutex(false, MutexName);
        _ownsMutex = TryAcquireMutex(_instanceMutex, TimeSpan.Zero);
        if (!_ownsMutex && restoreOnly)
        {
            try
            {
                using var exitEvent = EventWaitHandle.OpenExisting(ExitEventName);
                exitEvent.Set();
            }
            catch (WaitHandleCannotBeOpenedException)
            {
                // The first process is still starting; mutex acquisition below remains the fallback.
            }

            _ownsMutex = TryAcquireMutex(_instanceMutex, TimeSpan.FromSeconds(15));
        }

        if (!_ownsMutex)
        {
            Shutdown();
            return;
        }

        _exitEvent = new EventWaitHandle(false, EventResetMode.AutoReset, ExitEventName);
        _exitRegistration = ThreadPool.RegisterWaitForSingleObject(
            _exitEvent,
            (_, _) => Dispatcher.BeginInvoke(() =>
            {
                if (MainWindow is MainWindow window)
                {
                    window.ExitForUninstall();
                }
                else
                {
                    Shutdown();
                }
            }),
            null,
            Timeout.Infinite,
            false);

        _powerController = new PowerController();
        var recovered = _powerController.RecoverPreviousSession(out var recoveryError);
        if (!recovered && restoreOnly)
        {
            Shutdown(2);
            return;
        }

        if (!recovered && recoveryError is not null)
        {
            System.Windows.MessageBox.Show(recoveryError, "NoNap", MessageBoxButton.OK, MessageBoxImage.Warning);
        }

        if (restoreOnly)
        {
            Shutdown(0);
            return;
        }

        var startHidden = e.Args.Contains("--startup", StringComparer.OrdinalIgnoreCase);
        var window = new MainWindow(_powerController, startHidden);
        MainWindow = window;
        if (!startHidden)
        {
            window.Show();
        }
    }

    protected override void OnExit(ExitEventArgs e)
    {
        if (_powerController is not null)
        {
            _powerController.Disable(out _);
            _powerController.Dispose();
        }

        _exitRegistration?.Unregister(null);
        _exitEvent?.Dispose();
        if (_ownsMutex)
        {
            _instanceMutex?.ReleaseMutex();
        }
        _instanceMutex?.Dispose();
        base.OnExit(e);
    }

    private static bool TryAcquireMutex(Mutex mutex, TimeSpan timeout)
    {
        try
        {
            return mutex.WaitOne(timeout);
        }
        catch (AbandonedMutexException)
        {
            return true;
        }
    }
}
