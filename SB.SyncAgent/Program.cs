using System;
using System.ServiceProcess;
using System.Threading;

namespace SB.SyncAgent
{
    internal static class Program
    {
        static void Main(string[] args)
        {
            if (args.Length >= 2 && string.Equals(args[0], "/encrypt", StringComparison.OrdinalIgnoreCase))
            {
                string fileName = "CloudConnection.ini";
                int connStart = 1;
                if (args.Length >= 3 && args[1].EndsWith(".ini", StringComparison.OrdinalIgnoreCase))
                {
                    fileName = args[1];
                    connStart = 2;
                }
                string conn = string.Join(" ", args, connStart, args.Length - connStart).Trim('"');
                ConnectionIni.WriteEncrypted(fileName, conn);
                Console.WriteLine("Wrote " + fileName);
                return;
            }

            if (args.Length >= 1 && string.Equals(args[0], "/test", StringComparison.OrdinalIgnoreCase))
            {
                int errors = ConnectionTest.Run();
                Environment.Exit(errors > 0 ? 1 : 0);
                return;
            }

            if (args.Length >= 1 && string.Equals(args[0], "/once", StringComparison.OrdinalIgnoreCase))
            {
                SyncEngine.RunOnce();
                Console.WriteLine("Sync cycle completed.");
                return;
            }

            if (args.Length >= 1 && string.Equals(args[0], "/drain", StringComparison.OrdinalIgnoreCase))
            {
                int minutes = 480;
                if (args.Length >= 2)
                    int.TryParse(args[1], out minutes);
                Console.WriteLine("Draining outbox until empty or " + minutes + " minutes...");
                SyncEngine.RunDrain(minutes);
                Console.WriteLine("Drain completed. See SyncAgent.log");
                return;
            }

            if (Environment.UserInteractive)
            {
                Console.WriteLine("SB Sync Agent — console test mode (Ctrl+C to stop)");
                var cts = new CancellationTokenSource();
                Console.CancelKeyPress += (s, e) => { e.Cancel = true; cts.Cancel(); };
                SyncEngine.RunLoop(cts.Token);
                return;
            }

            ServiceBase.Run(new ServiceBase[] { new SyncAgentService() });
        }
    }
}
