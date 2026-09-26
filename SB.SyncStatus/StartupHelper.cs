using System;
using System.Windows.Forms;
using Microsoft.Win32;

namespace SB.SyncStatus
{
    internal static class StartupHelper
    {
        private const string RunKey = @"Software\Microsoft\Windows\CurrentVersion\Run";
        private const string ValueName = "SB2.SyncStatus.Dev";

        public static string ExePath
        {
            get { return Application.ExecutablePath; }
        }

        public static bool IsEnabled()
        {
            using (var key = Registry.CurrentUser.OpenSubKey(RunKey, false))
            {
                if (key == null)
                    return false;
                object val = key.GetValue(ValueName);
                return val != null && string.Equals(Convert.ToString(val), QuotedPath(), StringComparison.OrdinalIgnoreCase);
            }
        }

        public static void Ensure()
        {
            SetEnabled(true);
        }

        public static void SetEnabled(bool enabled)
        {
            using (var key = Registry.CurrentUser.CreateSubKey(RunKey))
            {
                if (key == null)
                    return;
                if (enabled)
                    key.SetValue(ValueName, QuotedPath());
                else
                    key.DeleteValue(ValueName, false);
            }
        }

        private static string QuotedPath()
        {
            return "\"" + ExePath + "\"";
        }
    }
}
