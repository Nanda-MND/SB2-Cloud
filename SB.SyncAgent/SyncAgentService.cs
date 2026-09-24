using System;
using System.ServiceProcess;
using System.Threading;

namespace SB.SyncAgent
{
    internal sealed class SyncAgentService : ServiceBase
    {
        private CancellationTokenSource _cts;

        public SyncAgentService()
        {
            ServiceName = "SB.SyncAgent";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            SyncEngine.LogInfo("Service started. Log file: " + SyncEngine.LogFilePath);
            _cts = new CancellationTokenSource();
            ThreadPool.QueueUserWorkItem(_ => SyncEngine.RunLoop(_cts.Token));
        }

        protected override void OnStop()
        {
            if (_cts != null)
                _cts.Cancel();
        }
    }
}
