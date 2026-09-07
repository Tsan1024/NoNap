using Microsoft.Win32;

namespace NoNap.Windows;

internal static class StartupManager
{
    private const string RunKeyPath = @"Software\Microsoft\Windows\CurrentVersion\Run";
    private const string ValueName = "NoNap";

    public static bool IsEnabled()
    {
        using var key = Registry.CurrentUser.OpenSubKey(RunKeyPath, false);
        return key?.GetValue(ValueName) is string;
    }

    public static void SetEnabled(bool enabled)
    {
        using var key = Registry.CurrentUser.CreateSubKey(RunKeyPath, true)
            ?? throw new InvalidOperationException("Could not open the Windows startup registry key.");
        if (!enabled)
        {
            key.DeleteValue(ValueName, false);
            return;
        }

        var executable = Environment.ProcessPath
            ?? throw new InvalidOperationException("Could not determine the NoNap executable path.");
        key.SetValue(ValueName, $"\"{executable}\" --startup", RegistryValueKind.String);
    }
}
