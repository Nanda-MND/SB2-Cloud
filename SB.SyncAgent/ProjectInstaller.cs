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
                ServiceName = "SB.SyncAgent",
                DisplayName = "SB Data Sync Agent",
                Description = "Syncs Local ERP database to Cloud (site4now.net)",
                StartType = ServiceStartMode.Automatic
            };

            Installers.Add(process);
            Installers.Add(service);
        }
    }
}
