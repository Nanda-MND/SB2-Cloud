using System;
using System.Data.SqlClient;
using System.Diagnostics;
using System.ServiceProcess;
using SB.SyncAgent;

namespace SB.SyncStatus
{
    internal static class StatusReader
    {
        private const string AgentServiceName = "SB.SyncAgent";

        public static StatusSnapshot Read()
        {
            var snap = new StatusSnapshot();
            snap.AgentRunning = IsAgentRunning();

            try
            {
                using (var cnn = ConnectionIni.OpenLocal())
                using (var cmd = new SqlCommand(@"
SELECT
    (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction = N'L2C' AND Status IN (N'Pending', N'Syncing')) AS L2CPending,
    (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction = N'C2L' AND Status IN (N'Pending', N'Syncing')) AS C2LPending,
    (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status = N'DeadLetter') AS DeadLetter,
    (SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Status = N'Conflict') AS Conflict,
    (SELECT MAX(SyncedAt) FROM dbo.SyncOutbox WHERE Status = N'Synced') AS LastSyncedAt,
    (SELECT TOP 1 LEFT(LastError, 200) FROM dbo.SyncOutbox WHERE LastError IS NOT NULL ORDER BY OutboxID DESC) AS LastError,
    (SELECT StateValue FROM dbo.SyncState WHERE StateKey = N'CloudOnline') AS CloudOnline,
    (SELECT UpdatedAt FROM dbo.SyncState WHERE StateKey = N'CloudOnline') AS CloudOnlineAt;
", cnn))
                {
                    cmd.CommandTimeout = 8;
                    using (var r = cmd.ExecuteReader())
                    {
                        if (!r.Read())
                            return StatusSnapshot.Fail("Sync tables returned no row.");

                        snap.L2CPending = r.IsDBNull(0) ? 0 : Convert.ToInt32(r.GetValue(0));
                        snap.C2LPending = r.IsDBNull(1) ? 0 : Convert.ToInt32(r.GetValue(1));
                        snap.DeadLetter = r.IsDBNull(2) ? 0 : Convert.ToInt32(r.GetValue(2));
                        snap.Conflict = r.IsDBNull(3) ? 0 : Convert.ToInt32(r.GetValue(3));
                        snap.LastSyncedAt = r.IsDBNull(4) ? (DateTime?)null : r.GetDateTime(4);
                        snap.LastError = r.IsDBNull(5) ? null : r.GetString(5);
                        string cloudVal = r.IsDBNull(6) ? "0" : r.GetString(6);
                        snap.CloudOnline = cloudVal == "1";
                        snap.CloudHeartbeatUtc = r.IsDBNull(7) ? (DateTime?)null : r.GetDateTime(7);
                    }
                }
            }
            catch (Exception ex)
            {
                return StatusSnapshot.Fail(ex.Message);
            }

            int pending = snap.L2CPending + snap.C2LPending;
            bool heartbeatStale = snap.CloudHeartbeatUtc.HasValue
                && (DateTime.UtcNow - ToUtc(snap.CloudHeartbeatUtc.Value)) > TimeSpan.FromMinutes(2);

            if (!snap.AgentRunning)
            {
                snap.Level = StatusLevel.Error;
                snap.Headline = "Agent stopped";
            }
            else if (!snap.CloudOnline || heartbeatStale)
            {
                snap.Level = StatusLevel.Error;
                snap.Headline = heartbeatStale ? "Cloud stale" : "Cloud offline";
            }
            else if (snap.DeadLetter > 0)
            {
                snap.Level = StatusLevel.Error;
                snap.Headline = "Dead letter";
            }
            else if (pending > 0 || snap.Conflict > 0)
            {
                snap.Level = StatusLevel.Busy;
                snap.Headline = "Syncing";
            }
            else
            {
                snap.Level = StatusLevel.Ok;
                snap.Headline = "OK";
            }

            snap.Detail = snap.Headline;
            snap.Tooltip = BuildTooltip(snap, pending);
            return snap;
        }

        private static string BuildTooltip(StatusSnapshot snap, int pending)
        {
            string last = snap.LastSyncedAt.HasValue
                ? ToLocal(snap.LastSyncedAt.Value).ToString("HH:mm")
                : "-";
            string line = "SB Sync: " + snap.Headline
                + Environment.NewLine
                + "Pending " + pending
                + "  Last " + last;
            if (line.Length > 120)
                line = line.Substring(0, 120);
            return line;
        }

        private static DateTime ToUtc(DateTime value)
        {
            if (value.Kind == DateTimeKind.Utc)
                return value;
            if (value.Kind == DateTimeKind.Local)
                return value.ToUniversalTime();
            return DateTime.SpecifyKind(value, DateTimeKind.Utc);
        }

        private static DateTime ToLocal(DateTime value)
        {
            if (value.Kind == DateTimeKind.Local)
                return value;
            if (value.Kind == DateTimeKind.Utc)
                return value.ToLocalTime();
            return DateTime.SpecifyKind(value, DateTimeKind.Utc).ToLocalTime();
        }

        private static bool IsAgentRunning()
        {
            try
            {
                using (var sc = new ServiceController(AgentServiceName))
                {
                    sc.Refresh();
                    if (sc.Status == ServiceControllerStatus.Running)
                        return true;
                }
            }
            catch
            {
                // Service not installed — fall through to process check.
            }

            try
            {
                return Process.GetProcessesByName("SB.SyncAgent").Length > 0;
            }
            catch
            {
                return false;
            }
        }
    }
}
