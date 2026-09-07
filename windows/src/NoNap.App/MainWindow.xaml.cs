using System.ComponentModel;
using System.Globalization;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Threading;
using NoNap.Core;
using Forms = System.Windows.Forms;

namespace NoNap.Windows;

public partial class MainWindow : Window
{
    private readonly PowerController _powerController;
    private readonly UserSettings _settings;
    private readonly DispatcherTimer _timer;
    private readonly Forms.NotifyIcon _trayIcon;
    private readonly System.Drawing.Icon? _ownedTrayIcon;
    private readonly Forms.ToolStripMenuItem _showMenuItem;
    private readonly Forms.ToolStripMenuItem _toggleMenuItem;
    private readonly Forms.ToolStripMenuItem _exitMenuItem;
    private DateTimeOffset? _countdownEnd;
    private bool _updating;
    private bool _allowClose;
    private bool _uiDisposed;
    private int _pollTicks;

    private bool Chinese => _settings.Language == "zh-CN";

    internal MainWindow(PowerController powerController, bool startHidden)
    {
        _powerController = powerController;
        _settings = SettingsStore.Load();
        _updating = true;
        InitializeComponent();
        _updating = false;

        var menu = new Forms.ContextMenuStrip();
        _showMenuItem = new Forms.ToolStripMenuItem();
        _showMenuItem.Click += (_, _) => ShowPanel();
        _toggleMenuItem = new Forms.ToolStripMenuItem();
        _toggleMenuItem.Click += (_, _) => ToggleKeepAwake();
        _exitMenuItem = new Forms.ToolStripMenuItem();
        _exitMenuItem.Click += (_, _) => ExitApplication();
        menu.Items.AddRange([_showMenuItem, _toggleMenuItem, new Forms.ToolStripSeparator(), _exitMenuItem]);

        _ownedTrayIcon = Environment.ProcessPath is string executablePath
            ? System.Drawing.Icon.ExtractAssociatedIcon(executablePath)
            : null;
        _trayIcon = new Forms.NotifyIcon
        {
            Icon = _ownedTrayIcon ?? System.Drawing.SystemIcons.Application,
            ContextMenuStrip = menu,
            Visible = true
        };
        _trayIcon.DoubleClick += (_, _) => ShowPanel();

        _timer = new DispatcherTimer(DispatcherPriority.Background)
        {
            Interval = TimeSpan.FromSeconds(1)
        };
        _timer.Tick += Timer_Tick;

        Closing += Window_Closing;
        Loaded += (_, _) =>
        {
            if (startHidden)
            {
                Hide();
            }
        };

        LoadControls();
        ApplyLanguage();
        RefreshState();
        PollBattery();
        _timer.Start();
    }

    private string T(string english, string chinese) => Chinese ? chinese : english;

    private void LoadControls()
    {
        _updating = true;
        CountdownSlider.Value = _settings.CountdownMinutes / 60.0;
        BatterySlider.Value = _settings.BatteryFloorPercent;
        StartupCheckBox.IsChecked = StartupManager.IsEnabled();
        LanguagePicker.SelectedIndex = Chinese ? 1 : 0;
        _updating = false;
    }

    private void ApplyLanguage()
    {
        Title = "NoNap";
        CountdownLabel.Text = T("Countdown", "倒计时");
        NoLimitText.Text = T("No time limit", "不限时");
        MaxTimeText.Text = T("24 hours", "24 小时");
        BatteryLabel.Text = T("Battery protection", "电量保护");
        StartupCheckBox.Content = T("Open at sign-in", "登录时打开");
        LanguageLabel.Text = T("Language", "语言");
        SafetyText.Text = T(
            "NoNap restores your previous plugged-in and battery lid settings when it stops.",
            "NoNap 停止时会恢复原来的接通电源和使用电池合盖设置。");
        HideButton.Content = T("Hide", "隐藏");
        _showMenuItem.Text = T("Open NoNap", "打开 NoNap");
        _exitMenuItem.Text = T("Exit", "退出");
        RefreshState();
        UpdateCountdownDisplay();
        PollBattery();
    }

    private void RefreshState()
    {
        _updating = true;
        KeepAwakeToggle.IsChecked = _powerController.IsActive;
        KeepAwakeToggle.Content = _powerController.IsActive ? T("Turn off", "关闭") : T("Turn on", "开启");
        StateText.Text = _powerController.IsActive
            ? T("Lid-closed operation is on", "已开启合盖运行")
            : _powerController.HasPendingRestore
                ? T("Power request stopped · Restore pending", "电源请求已停止 · 等待恢复设置")
            : T("The computer can sleep normally", "电脑可正常休眠");
        _toggleMenuItem.Text = _powerController.IsActive
            ? T("Stop keeping awake", "停止保持运行")
            : T("Keep awake", "保持运行");
        _trayIcon.Text = _powerController.IsActive ? "NoNap - On" : "NoNap - Off";
        _updating = false;
    }

    private void ToggleKeepAwake()
    {
        if (_powerController.IsActive)
        {
            StopKeepAwake(true);
            return;
        }

        if (!_powerController.Enable(out var error))
        {
            ShowError(error ?? T("Windows rejected the power setting change.", "Windows 拒绝了电源设置更改。"));
            RefreshState();
            return;
        }

        _countdownEnd = _settings.CountdownMinutes > 0
            ? DateTimeOffset.UtcNow.AddMinutes(_settings.CountdownMinutes)
            : null;
        RefreshState();
        UpdateCountdownDisplay();
        PollBattery();
    }

    private bool StopKeepAwake(bool showErrors)
    {
        _countdownEnd = null;
        var restored = _powerController.Disable(out var error);
        if (!restored && showErrors)
        {
            ShowError(error ?? T("The original power settings could not be restored.", "无法恢复原电源设置。"));
        }
        RefreshState();
        UpdateCountdownDisplay();
        return restored;
    }

    private void SafetyStop(string english, string chinese)
    {
        var restored = StopKeepAwake(false);
        var message = restored
            ? T(english, chinese)
            : T(
                "The power request stopped, but the original lid settings could not be restored. NoNap will retry.",
                "电源请求已停止，但无法恢复原合盖设置；NoNap 将自动重试。");
        _trayIcon.BalloonTipTitle = "NoNap";
        _trayIcon.BalloonTipText = message;
        _trayIcon.BalloonTipIcon = Forms.ToolTipIcon.Info;
        _trayIcon.ShowBalloonTip(5000);
    }

    private void Timer_Tick(object? sender, EventArgs e)
    {
        UpdateCountdownDisplay();
        if (_powerController.IsActive && _countdownEnd is not null && DateTimeOffset.UtcNow >= _countdownEnd)
        {
            SafetyStop("The countdown ended. NoNap turned off.", "倒计时结束，NoNap 已关闭。");
            return;
        }

        _pollTicks++;
        if (_pollTicks >= 30)
        {
            _pollTicks = 0;
            if (!_powerController.IsActive && _powerController.HasPendingRestore &&
                _powerController.RecoverPreviousSession(out _))
            {
                RefreshState();
                _trayIcon.BalloonTipTitle = "NoNap";
                _trayIcon.BalloonTipText = T("The original lid settings were restored.", "原合盖设置已恢复。");
                _trayIcon.BalloonTipIcon = Forms.ToolTipIcon.Info;
                _trayIcon.ShowBalloonTip(3000);
            }
            PollBattery();
            if (_powerController.IsActive && !_powerController.OwnedSettingsAreApplied())
            {
                SafetyStop(
                    "The lid setting changed outside NoNap, so its power request was stopped.",
                    "合盖设置已被其他程序更改，NoNap 已停止电源请求。");
            }
        }
    }

    private void PollBattery()
    {
        var status = PowerStatus.Read();
        if (status is null)
        {
            BatteryEstimateText.Text = T("Battery state unavailable", "无法读取电池状态");
            if (_powerController.IsActive)
            {
                SafetyStop("Battery state became unavailable. NoNap turned off safely.", "无法读取电池状态，NoNap 已安全关闭。");
            }
            return;
        }

        var percentText = status.Percent is null ? "?" : $"{status.Percent}%";
        var estimate = BatteryPolicy.EstimateMinutesToFloor(
            status.MinutesToEmpty, status.Percent, _settings.BatteryFloorPercent);
        BatteryEstimateText.Text = !status.OnBattery
            ? T($"Plugged in · Battery {percentText}", $"已接通电源 · 电量 {percentText}")
            : estimate is null
                ? T($"On battery · {percentText}", $"使用电池 · {percentText}")
                : T($"About {Countdown.Format(estimate.Value, false)} to the cutoff", $"距保护阈值约 {Countdown.Format(estimate.Value, true)}");

        if (_powerController.IsActive && BatteryPolicy.ShouldStop(
                status.OnBattery, status.Percent, status.BatterySaver, _settings.BatteryFloorPercent))
        {
            SafetyStop(
                status.BatterySaver ? "Battery Saver is on. NoNap turned off." : "The battery cutoff was reached. NoNap turned off.",
                status.BatterySaver ? "已开启节电模式，NoNap 已关闭。" : "电量已达到保护阈值，NoNap 已关闭。");
        }
    }

    private void UpdateCountdownDisplay()
    {
        var displayed = _countdownEnd is null
            ? _settings.CountdownMinutes
            : Math.Clamp((int)Math.Ceiling((_countdownEnd.Value - DateTimeOffset.UtcNow).TotalMinutes), 0, Countdown.MaximumMinutes);
        _updating = true;
        if (!CountdownField.IsKeyboardFocusWithin)
        {
            CountdownField.Text = Countdown.Format(displayed, Chinese);
        }
        CountdownSlider.Value = displayed / 60.0;
        BatteryFloorText.Text = $"{_settings.BatteryFloorPercent}%";
        _updating = false;
    }

    private void ApplyCountdown(int minutes)
    {
        _settings.CountdownMinutes = Math.Clamp(minutes, 0, Countdown.MaximumMinutes);
        SettingsStore.Save(_settings);
        if (_powerController.IsActive)
        {
            _countdownEnd = _settings.CountdownMinutes > 0
                ? DateTimeOffset.UtcNow.AddMinutes(_settings.CountdownMinutes)
                : null;
        }
        UpdateCountdownDisplay();
    }

    private void KeepAwakeToggle_Click(object sender, RoutedEventArgs e)
    {
        if (!_updating)
        {
            ToggleKeepAwake();
        }
    }

    private void CountdownSlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (!_updating)
        {
            ApplyCountdown((int)Math.Round(e.NewValue * 2) * 30);
        }
    }

    private void CountdownField_LostFocus(object sender, RoutedEventArgs e)
    {
        if (Countdown.TryParse(CountdownField.Text, out var minutes))
        {
            ApplyCountdown(minutes);
        }
        else
        {
            UpdateCountdownDisplay();
        }
    }

    private void CountdownField_KeyDown(object sender, System.Windows.Input.KeyEventArgs e)
    {
        if (e.Key == System.Windows.Input.Key.Enter)
        {
            Keyboard.ClearFocus();
            e.Handled = true;
        }
    }

    private void BatterySlider_ValueChanged(object sender, RoutedPropertyChangedEventArgs<double> e)
    {
        if (_updating)
        {
            return;
        }

        _settings.BatteryFloorPercent = Math.Clamp((int)Math.Round(e.NewValue), 5, 50);
        SettingsStore.Save(_settings);
        UpdateCountdownDisplay();
        PollBattery();
    }

    private void StartupCheckBox_Click(object sender, RoutedEventArgs e)
    {
        if (_updating)
        {
            return;
        }

        try
        {
            StartupManager.SetEnabled(StartupCheckBox.IsChecked == true);
        }
        catch (Exception exception)
        {
            ShowError(exception.Message);
            _updating = true;
            StartupCheckBox.IsChecked = StartupManager.IsEnabled();
            _updating = false;
        }
    }

    private void LanguagePicker_SelectionChanged(object sender, SelectionChangedEventArgs e)
    {
        if (_updating || LanguagePicker.SelectedItem is not ComboBoxItem item)
        {
            return;
        }

        _settings.Language = item.Tag?.ToString() == "zh-CN" ? "zh-CN" : "en";
        SettingsStore.Save(_settings);
        ApplyLanguage();
    }

    private void HideButton_Click(object sender, RoutedEventArgs e) => Hide();

    private void ShowPanel()
    {
        Show();
        WindowState = WindowState.Normal;
        Activate();
    }

    private void ExitApplication()
    {
        if (!StopKeepAwake(true))
        {
            return;
        }
        _allowClose = true;
        DisposeUi();
        System.Windows.Application.Current.Shutdown();
    }

    internal void ExitForUninstall()
    {
        StopKeepAwake(false);
        _allowClose = true;
        DisposeUi();
        System.Windows.Application.Current.Shutdown();
    }

    private void DisposeUi()
    {
        if (_uiDisposed)
        {
            return;
        }

        _uiDisposed = true;
        _timer.Stop();
        _trayIcon.Visible = false;
        _trayIcon.Dispose();
        _ownedTrayIcon?.Dispose();
    }

    private void Window_Closing(object? sender, CancelEventArgs e)
    {
        if (_allowClose)
        {
            return;
        }

        e.Cancel = true;
        Hide();
    }

    private void ShowError(string message)
    {
        System.Windows.MessageBox.Show(this, message, "NoNap", MessageBoxButton.OK, MessageBoxImage.Error);
    }
}
