using System.Globalization;

namespace NoNap.Core;

public static class Countdown
{
    public const int MaximumMinutes = 24 * 60;

    public static bool TryParse(string? value, out int minutes)
    {
        minutes = 0;
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        var normalized = value.Trim().ToLowerInvariant()
            .Replace("小时", ":", StringComparison.Ordinal)
            .Replace("分钟", "", StringComparison.Ordinal)
            .Replace("时", ":", StringComparison.Ordinal)
            .Replace("分", "", StringComparison.Ordinal)
            .Replace("h", ":", StringComparison.Ordinal)
            .Replace("m", "", StringComparison.Ordinal)
            .Replace(" ", "", StringComparison.Ordinal)
            .Replace(',', '.');

        var parts = normalized.Replace(':', '.').Split('.', StringSplitOptions.None);
        if (parts.Length is < 1 or > 2 ||
            !int.TryParse(parts[0], NumberStyles.None, CultureInfo.InvariantCulture, out var hours) ||
            hours is < 0 or > 24)
        {
            return false;
        }

        var minutePart = 0;
        if (parts.Length == 2)
        {
            if (parts[1].Length is < 1 or > 2 ||
                !int.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out minutePart))
            {
                return false;
            }

            if (parts[1].Length == 1)
            {
                minutePart *= 10;
            }
        }

        if (minutePart >= 60 || (hours == 24 && minutePart != 0))
        {
            return false;
        }

        minutes = hours * 60 + minutePart;
        return true;
    }

    public static string Format(int minutes, bool chinese)
    {
        var bounded = Math.Clamp(minutes, 0, MaximumMinutes);
        var hours = bounded / 60;
        var remainder = bounded % 60;
        return chinese
            ? $"{hours}时{remainder:00}分"
            : $"{hours}h {remainder:00}m";
    }
}
