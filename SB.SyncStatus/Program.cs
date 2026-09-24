using System;
using System.Threading;
using System.Windows.Forms;

namespace SB.SyncStatus
{
    internal static class Program
    {
        private const string MutexName = @"Local\SB.SyncStatus";

        [STAThread]
        private static void Main(string[] args)
        {
            bool createdNew;
            using (var mutex = new Mutex(true, MutexName, out createdNew))
            {
                if (!createdNew)
                    return;

                if (args != null && args.Length > 0)
                {
                    if (string.Equals(args[0], "/uninstall-startup", StringComparison.OrdinalIgnoreCase))
                    {
                        StartupHelper.SetEnabled(false);
                        return;
                    }
                    if (string.Equals(args[0], "/install-startup", StringComparison.OrdinalIgnoreCase))
                    {
                        StartupHelper.Ensure();
                        return;
                    }
                }

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new TrayApp());
            }
        }
    }
}
