using NoNap.Core;

static void Check(bool condition, string message)
{
    if (!condition)
    {
        throw new InvalidOperationException(message);
    }
}

Check(Countdown.TryParse("9:59", out var clock) && clock == 599, "9:59 parsing failed");
Check(Countdown.TryParse("1h 30m", out var english) && english == 90, "English parsing failed");
Check(Countdown.TryParse("2时05分", out var chinese) && chinese == 125, "Chinese parsing failed");
Check(!Countdown.TryParse("24:01", out _), "Countdown exceeded 24 hours");
Check(Countdown.Format(599, false) == "9h 59m", "English formatting failed");
Check(Countdown.Format(599, true) == "9时59分", "Chinese formatting failed");
Check(BatteryPolicy.ShouldStop(true, 15, false, 15), "Battery floor did not stop");
Check(BatteryPolicy.ShouldStop(true, 80, true, 15), "Battery Saver did not stop");
Check(!BatteryPolicy.ShouldStop(false, 10, true, 15), "AC power should not stop");
Check(BatteryPolicy.EstimateMinutesToFloor(240, 80, 20) == 180, "Battery estimate failed");

Console.WriteLine("Windows core checks passed");
