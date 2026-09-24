using System;

namespace SB.SyncStatus
{
    internal enum StatusLevel
    {
        Ok,
        Busy,
        Error
    }

    internal sealed class StatusSnapshot
    {
        public StatusLevel Level;
        public string Headline;
        public bool AgentRunning;
        public bool CloudOnline;
        public DateTime? CloudHeartbeatUtc;
        public int L2CPending;
        public int C2LPending;
        public int DeadLetter;
        public int Conflict;
        public DateTime? LastSyncedAt;
        public string LastError;
        public string Detail;
        public string Tooltip;

        public static StatusSnapshot Fail(string message)
        {
            return new StatusSnapshot
            {
                Level = StatusLevel.Error,
                Headline = "Error",
                Detail = message,
                LastError = message,
                Tooltip = "SB Sync: Error"
            };
        }
    }
}
