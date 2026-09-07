using System.Runtime.InteropServices;

namespace NoNap.Windows;

internal sealed record PowerStatus(bool OnBattery, int? Percent, bool BatterySaver, int? MinutesToEmpty)
{
    public static PowerStatus? Read()
    {
        if (!Native.GetSystemPowerStatus(out var status))
        {
            return null;
        }

        int? percent = status.BatteryLifePercent == byte.MaxValue ? null : status.BatteryLifePercent;
        var minutes = status.BatteryLifeTime == uint.MaxValue
            ? null
            : (int?)Math.Min(status.BatteryLifeTime / 60, (uint)int.MaxValue);
        return new PowerStatus(
            status.ACLineStatus == 0,
            percent,
            status.SystemStatusFlag != 0,
            minutes);
    }

    private static class Native
    {
        [StructLayout(LayoutKind.Sequential)]
        internal struct SystemPowerStatus
        {
            internal byte ACLineStatus;
            internal byte BatteryFlag;
            internal byte BatteryLifePercent;
            internal byte SystemStatusFlag;
            internal uint BatteryLifeTime;
            internal uint BatteryFullLifeTime;
        }

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        internal static extern bool GetSystemPowerStatus(out SystemPowerStatus systemPowerStatus);
    }
}
