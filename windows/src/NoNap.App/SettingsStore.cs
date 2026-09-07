using System.Globalization;
using System.IO;
using System.Text.Json;

namespace NoNap.Windows;

internal sealed class UserSettings
{
    public int CountdownMinutes { get; set; }
    public int BatteryFloorPercent { get; set; } = 15;
    public string Language { get; set; } = CultureInfo.CurrentUICulture.Name.StartsWith("zh", StringComparison.OrdinalIgnoreCase)
        ? "zh-CN"
        : "en";
}

internal static class SettingsStore
{
    private static readonly string DirectoryPath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "NoNap");
    private static readonly string FilePath = Path.Combine(DirectoryPath, "settings.json");

    public static UserSettings Load()
    {
        try
        {
            if (File.Exists(FilePath))
            {
                var settings = JsonSerializer.Deserialize<UserSettings>(File.ReadAllText(FilePath));
                if (settings is not null)
                {
                    settings.CountdownMinutes = Math.Clamp(settings.CountdownMinutes, 0, 24 * 60);
                    settings.BatteryFloorPercent = Math.Clamp(settings.BatteryFloorPercent, 5, 50);
                    settings.Language = settings.Language == "zh-CN" ? "zh-CN" : "en";
                    return settings;
                }
            }
        }
        catch
        {
            // Invalid preferences fall back to safe defaults.
        }

        return new UserSettings();
    }

    public static void Save(UserSettings settings)
    {
        Directory.CreateDirectory(DirectoryPath);
        var temporary = FilePath + ".tmp";
        File.WriteAllText(temporary, JsonSerializer.Serialize(settings, new JsonSerializerOptions { WriteIndented = true }));
        File.Move(temporary, FilePath, true);
    }
}
