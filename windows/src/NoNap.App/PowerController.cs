using System.ComponentModel;
using System.IO;
using System.Runtime.InteropServices;
using System.Text.Json;

namespace NoNap.Windows;

internal sealed class PowerController : IDisposable
{
    private static readonly Guid SystemButtonSubgroup = new("4f971e89-eebd-4455-a8de-9e59040e7347");
    private static readonly Guid LidCloseAction = new("5ca83367-6e45-459f-a27b-476b1d01c936");
    private static readonly string StateDirectory = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "NoNap");
    private static readonly string JournalPath = Path.Combine(StateDirectory, "power-session.json");

    private IntPtr _powerRequest = IntPtr.Zero;

    public bool IsActive { get; private set; }
    public bool HasPendingRestore => File.Exists(JournalPath);

    public bool Enable(out string? error)
    {
        error = null;
        if (IsActive)
        {
            return true;
        }

        if (!RecoverPreviousSession(out error))
        {
            return false;
        }

        try
        {
            var scheme = GetActiveScheme();
            var originalAc = ReadValue(scheme, true);
            var originalDc = ReadValue(scheme, false);
            SaveJournal(new PowerSession(scheme, originalAc, originalDc, DateTimeOffset.UtcNow));

            WriteValue(scheme, true, 0);
            try
            {
                WriteValue(scheme, false, 0);
                ThrowIfError(Native.PowerSetActiveScheme(IntPtr.Zero, ref scheme), "activate the updated power plan");
                CreateSystemRequiredRequest();
            }
            catch
            {
                RestoreJournalCore();
                throw;
            }

            IsActive = true;
            return true;
        }
        catch (Exception exception)
        {
            error = $"Windows could not enable lid-closed operation. {exception.Message}";
            return false;
        }
    }

    public bool Disable(out string? error)
    {
        error = null;
        ClearSystemRequiredRequest();
        IsActive = false;

        try
        {
            RestoreJournalCore();
            return true;
        }
        catch (Exception exception)
        {
            error = $"NoNap stopped its power request, but could not fully restore the lid settings. {exception.Message}";
            return false;
        }
    }

    public bool RecoverPreviousSession(out string? error)
    {
        error = null;
        if (!File.Exists(JournalPath))
        {
            return true;
        }

        try
        {
            RestoreJournalCore();
            return true;
        }
        catch (Exception exception)
        {
            error = $"NoNap found an unfinished session but could not restore its lid settings. {exception.Message}";
            return false;
        }
    }

    public bool OwnedSettingsAreApplied()
    {
        if (!IsActive || !File.Exists(JournalPath))
        {
            return false;
        }

        try
        {
            var session = LoadJournal();
            return ReadValue(session.SchemeGuid, true) == 0 && ReadValue(session.SchemeGuid, false) == 0;
        }
        catch
        {
            return false;
        }
    }

    private static Guid GetActiveScheme()
    {
        ThrowIfError(Native.PowerGetActiveScheme(IntPtr.Zero, out var pointer), "read the active power plan");
        try
        {
            return Marshal.PtrToStructure<Guid>(pointer);
        }
        finally
        {
            Native.LocalFree(pointer);
        }
    }

    private static uint ReadValue(Guid scheme, bool ac)
    {
        var subgroup = SystemButtonSubgroup;
        var setting = LidCloseAction;
        uint result;
        var status = ac
            ? Native.PowerReadACValueIndex(IntPtr.Zero, ref scheme, ref subgroup, ref setting, out result)
            : Native.PowerReadDCValueIndex(IntPtr.Zero, ref scheme, ref subgroup, ref setting, out result);
        ThrowIfError(status, $"read the {(ac ? "plugged-in" : "battery")} lid action");
        return result;
    }

    private static void WriteValue(Guid scheme, bool ac, uint value)
    {
        var subgroup = SystemButtonSubgroup;
        var setting = LidCloseAction;
        var status = ac
            ? Native.PowerWriteACValueIndex(IntPtr.Zero, ref scheme, ref subgroup, ref setting, value)
            : Native.PowerWriteDCValueIndex(IntPtr.Zero, ref scheme, ref subgroup, ref setting, value);
        ThrowIfError(status, $"write the {(ac ? "plugged-in" : "battery")} lid action");
    }

    private void CreateSystemRequiredRequest()
    {
        var reasonPointer = Marshal.StringToHGlobalUni("NoNap is keeping a user-requested task running");
        try
        {
            var context = new Native.ReasonContext
            {
                Version = 0,
                Flags = 1,
                ReasonString = reasonPointer
            };
            _powerRequest = Native.PowerCreateRequest(ref context);
            if (_powerRequest == IntPtr.Zero || _powerRequest == new IntPtr(-1))
            {
                throw new Win32Exception(Marshal.GetLastWin32Error(), "Could not create a Windows power request.");
            }

            if (!Native.PowerSetRequest(_powerRequest, Native.PowerRequestType.SystemRequired))
            {
                var exception = new Win32Exception(Marshal.GetLastWin32Error(), "Could not activate the Windows power request.");
                Native.CloseHandle(_powerRequest);
                _powerRequest = IntPtr.Zero;
                throw exception;
            }
        }
        finally
        {
            Marshal.FreeHGlobal(reasonPointer);
        }
    }

    private void ClearSystemRequiredRequest()
    {
        if (_powerRequest == IntPtr.Zero)
        {
            return;
        }

        Native.PowerClearRequest(_powerRequest, Native.PowerRequestType.SystemRequired);
        Native.CloseHandle(_powerRequest);
        _powerRequest = IntPtr.Zero;
    }

    private static void SaveJournal(PowerSession session)
    {
        Directory.CreateDirectory(StateDirectory);
        var temporary = JournalPath + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(session));
        File.Move(temporary, JournalPath, true);
    }

    private static PowerSession LoadJournal()
    {
        return JsonSerializer.Deserialize<PowerSession>(File.ReadAllText(JournalPath))
            ?? throw new InvalidDataException("The saved power session is invalid.");
    }

    private static void RestoreJournalCore()
    {
        if (!File.Exists(JournalPath))
        {
            return;
        }

        var session = LoadJournal();

        // Preserve a setting changed by the user or an administrator while NoNap was active.
        if (ReadValue(session.SchemeGuid, true) == 0)
        {
            WriteValue(session.SchemeGuid, true, session.OriginalAcLidAction);
        }

        if (ReadValue(session.SchemeGuid, false) == 0)
        {
            WriteValue(session.SchemeGuid, false, session.OriginalDcLidAction);
        }

        var scheme = session.SchemeGuid;
        ThrowIfError(Native.PowerSetActiveScheme(IntPtr.Zero, ref scheme), "reactivate the restored power plan");
        File.Delete(JournalPath);
    }

    private static void ThrowIfError(uint status, string operation)
    {
        if (status != 0)
        {
            throw new Win32Exception((int)status, $"Could not {operation}.");
        }
    }

    public void Dispose()
    {
        ClearSystemRequiredRequest();
    }

    private sealed record PowerSession(
        Guid SchemeGuid,
        uint OriginalAcLidAction,
        uint OriginalDcLidAction,
        DateTimeOffset StartedAtUtc);

    private static partial class Native
    {
        internal enum PowerRequestType
        {
            DisplayRequired = 0,
            SystemRequired = 1,
            AwayModeRequired = 2,
            ExecutionRequired = 3
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct ReasonContext
        {
            internal uint Version;
            internal uint Flags;
            internal IntPtr ReasonString;
        }

        [DllImport("powrprof.dll")]
        internal static extern uint PowerGetActiveScheme(IntPtr userRootPowerKey, out IntPtr activePolicyGuid);

        [DllImport("powrprof.dll")]
        internal static extern uint PowerSetActiveScheme(IntPtr userRootPowerKey, ref Guid schemeGuid);

        [DllImport("powrprof.dll")]
        internal static extern uint PowerReadACValueIndex(IntPtr rootPowerKey, ref Guid schemeGuid,
            ref Guid subgroupGuid, ref Guid settingGuid, out uint valueIndex);

        [DllImport("powrprof.dll")]
        internal static extern uint PowerReadDCValueIndex(IntPtr rootPowerKey, ref Guid schemeGuid,
            ref Guid subgroupGuid, ref Guid settingGuid, out uint valueIndex);

        [DllImport("powrprof.dll")]
        internal static extern uint PowerWriteACValueIndex(IntPtr rootPowerKey, ref Guid schemeGuid,
            ref Guid subgroupGuid, ref Guid settingGuid, uint valueIndex);

        [DllImport("powrprof.dll")]
        internal static extern uint PowerWriteDCValueIndex(IntPtr rootPowerKey, ref Guid schemeGuid,
            ref Guid subgroupGuid, ref Guid settingGuid, uint valueIndex);

        [DllImport("kernel32.dll", SetLastError = true)]
        internal static extern IntPtr PowerCreateRequest(ref ReasonContext context);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool PowerSetRequest(IntPtr powerRequest, PowerRequestType requestType);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool PowerClearRequest(IntPtr powerRequest, PowerRequestType requestType);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool CloseHandle(IntPtr handle);

        [DllImport("kernel32.dll")]
        internal static extern IntPtr LocalFree(IntPtr memory);
    }
}
