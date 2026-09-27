using System.ComponentModel;
using System.Configuration.Install;
using System.ServiceProcess;

namespace SB.SyncAgent
{
    [RunInstaller(true)]
    public sealed class ProjectInstaller : Installer
    {
        public ProjectInstaller()
        {
            var process = new ServiceProcessInstaller
            {
                Account = ServiceAccount.LocalSystem
            };

            var service = new ServiceInstaller
            {
                ServiceName = "SB2.SyncAgent.Dev",
                DisplayName = "SB2 Data Sync Agent (Dev)",
                Description = "Syncs Dev Local SB2 to Test Cloud only. Do not install against live or client endpoints.",
                StartType = ServiceStartMode.Automatic
            };

            Installers.Add(process);
            Installers.Add(service);
        }
    }
}
