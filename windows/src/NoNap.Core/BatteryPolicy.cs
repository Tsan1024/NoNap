namespace NoNap.Core;

public static class BatteryPolicy
{
    public static bool ShouldStop(bool onBattery, int? percent, bool batterySaver, int floorPercent)
    {
        if (!onBattery)
        {
            return false;
        }

        return batterySaver || percent is null || percent <= Math.Clamp(floorPercent, 5, 50);
    }

    public static int? EstimateMinutesToFloor(int? minutesToEmpty, int? percent, int floorPercent)
    {
        if (minutesToEmpty is null || minutesToEmpty <= 0 || percent is null || percent <= 0)
        {
            return null;
        }

        var floor = Math.Clamp(floorPercent, 5, 50);
        if (percent <= floor)
        {
            return 0;
        }

        return (int)Math.Round(minutesToEmpty.Value * (percent.Value - floor) / (double)percent.Value);
    }
}
