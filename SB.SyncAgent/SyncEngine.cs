using System;
using System.Data;
using System.Data.SqlClient;
using System.Threading;

namespace SB.SyncAgent
{
    internal sealed class SyncEngine
    {
        private const int PushIntervalMs = 2000;
        private const int PullIntervalMs = 5000;
        private const int MaxRetries = 10;
        private const int DefaultBatchSize = 100;

        private DateTime _lastPush = DateTime.MinValue;
        private DateTime _lastPull = DateTime.MinValue;

        public void RunCycle()
        {
            bool cloudOk = false;
            try
            {
                if (DateTime.UtcNow - _lastPush > TimeSpan.FromMilliseconds(PushIntervalMs))
                {
                    PushLocalToCloud();
                    _lastPush = DateTime.UtcNow;
                }

                if (DateTime.UtcNow - _lastPull > TimeSpan.FromMilliseconds(PullIntervalMs))
                {
                    PullCloudToLocal();
                    _lastPull = DateTime.UtcNow;
                }

                cloudOk = true;
            }
            catch (Exception ex)
            {
                Log("Sync cycle error: " + ex.Message);
            }

            UpdateCloudOnline(cloudOk);
        }

        private void PushLocalToCloud()
        {
            using (var local = ConnectionIni.OpenLocal())
            using (var cloud = ConnectionIni.OpenCloud())
            {
                var batch = ClaimBatch(local, "L2C");
                foreach (DataRow row in batch.Rows)
                    ApplyOutboxRow(local, cloud, row, true);
            }
        }

        private void PullCloudToLocal()
        {
            using (var cloud = ConnectionIni.OpenCloud())
            using (var local = ConnectionIni.OpenLocal())
            {
                EnsureOpen(local);
                Log("C2L pull Local DB=" + local.Database + " Server=" + local.DataSource);
                var batch = ClaimBatch(cloud, "C2L");
                foreach (DataRow row in batch.Rows)
                    ApplyOutboxRow(cloud, local, row, false);
            }
        }

        /// <summary>
        /// source owns the outbox row. target is where the row is applied.
        /// A failed apply can close the SqlConnection (timeout or severity 20).
        /// The next ExecuteScalar then throws "current state is closed".
        /// Re-open before each row, and retry that row once after a closed connection.
        /// </summary>
        private void ApplyOutboxRow(SqlConnection source, SqlConnection target, DataRow row, bool push)
        {
            long outboxId = Convert.ToInt64(row["OutboxID"]);
            string table = row["TableName"].ToString();
            Exception last = null;
            for (int attempt = 1; attempt <= 2; attempt++)
            {
                try
                {
                    EnsureOpen(source);
                    EnsureOpen(target);
                    if (push)
                    {
                        ApplyOnCloud(target, row);
                        EnsureOpen(source);
                        CompleteOutbox(source, outboxId, "Synced");
                    }
                    else
                    {
                        var outcome = ApplyOnLocal(target, row);
                        EnsureOpen(source);
                        if (outcome == ApplyOutcome.ConflictSkipped)
                        {
                            CompleteOutbox(source, outboxId, "Conflict",
                                "LocalWinsSkipped on " + target.Database + " for " + table
                                + " " + Convert.ToString(row["PrimaryKeyJson"]));
                            Log("C2L conflict OutboxID=" + outboxId + " " + table
                                + " " + Convert.ToString(row["PrimaryKeyJson"]));
                        }
                        else
                        {
                            CompleteOutbox(source, outboxId, "Synced");
                        }
                    }
                    last = null;
                    break;
                }
                catch (Exception ex)
                {
                    last = ex;
                    if (attempt == 1 && ConnectionNeedsReopen(source, target, ex))
                    {
                        Log((push ? "Push" : "Pull") + " retry OutboxID=" + outboxId + " " + table + " after closed connection.");
                        TryReopen(source);
                        TryReopen(target);
                        continue;
                    }
                    break;
                }
            }

            if (last == null)
                return;

            try
            {
                EnsureOpen(source);
                FailOutbox(source, outboxId, last.Message);
            }
            catch (Exception failEx)
            {
                Log("FailOutbox failed OutboxID=" + outboxId + ": " + failEx.Message);
            }

            string where = push ? "" : (" LocalDB=" + SafeDatabaseName(target));
            Log((push ? "Push" : "Pull") + " failed OutboxID=" + outboxId + " " + table + where + ": " + last.Message);
        }

        private static void EnsureOpen(SqlConnection cnn)
        {
            if (cnn == null)
                throw new InvalidOperationException("SQL connection is missing.");
            if (cnn.State == ConnectionState.Open)
                return;
            // Broken and Closed both need Close() before Open() or the next command stays dead.
            cnn.Close();
            cnn.Open();
        }

        private static void TryReopen(SqlConnection cnn)
        {
            if (cnn == null)
                return;
            try
            {
                // Always recycle. State can still read Open after the server has already dropped the session.
                cnn.Close();
                cnn.Open();
            }
            catch
            {
                // The caller records the original apply error.
            }
        }

        private static bool ConnectionNeedsReopen(SqlConnection source, SqlConnection target, Exception ex)
        {
            if (source != null && source.State != ConnectionState.Open)
                return true;
            if (target != null && target.State != ConnectionState.Open)
                return true;
            string message = ex == null ? "" : ex.Message;
            return message.IndexOf("current state is closed", StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static string SafeDatabaseName(SqlConnection cnn)
        {
            try
            {
                if (cnn != null && cnn.State == ConnectionState.Open)
                    return cnn.Database;
            }
            catch { }
            return "?";
        }

        private static DataTable ClaimBatch(SqlConnection cnn, string direction)
        {
            EnsureOpen(cnn);
            using (var cmd = new SqlCommand("dbo.SyncClaimOutboxBatch", cnn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@Direction", direction);
                cmd.Parameters.AddWithValue("@BatchSize", DefaultBatchSize);
                var dt = new DataTable();
                using (var da = new SqlDataAdapter(cmd))
                    da.Fill(dt);
                return dt;
            }
        }

        private static void ApplyOnCloud(SqlConnection cloud, DataRow row)
        {
            ExecApply(cloud, "Local", row);
        }

        private static ApplyOutcome ApplyOnLocal(SqlConnection local, DataRow row)
        {
            return ExecApply(local, "Cloud", row);
        }

        private enum ApplyOutcome { Applied, ConflictSkipped }

        private static ApplyOutcome ExecApply(SqlConnection cnn, string source, DataRow row)
        {
            EnsureOpen(cnn);
            string table = row["TableName"].ToString();
            // C2L: always SyncApply_Generic when present so Local NEW_OK post-apply check cannot be bypassed
            // by a stale SyncApply_<Table> wrapper. L2C still prefers table-specific procs.
            string specificProc = "dbo.SyncApply_" + table;
            bool c2l = string.Equals(source, "Cloud", StringComparison.OrdinalIgnoreCase);
            string proc;
            if (c2l && ProcedureExists(cnn, "dbo.SyncApply_Generic"))
                proc = "dbo.SyncApply_Generic";
            else
                proc = ProcedureExists(cnn, specificProc) ? specificProc : "dbo.SyncApply_Generic";

            using (var cmd = new SqlCommand(proc, cnn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                if (proc == "dbo.SyncApply_Generic")
                    cmd.Parameters.AddWithValue("@TableName", table);
                cmd.Parameters.AddWithValue("@Source", source);
                cmd.Parameters.AddWithValue("@PayloadJson", row["PayloadJson"] ?? DBNull.Value);
                cmd.Parameters.AddWithValue("@RemoteModifiedAt", row["SyncModifiedAt"]);
                cmd.Parameters.AddWithValue("@PrimaryKeyJson", row["PrimaryKeyJson"]);
                cmd.Parameters.AddWithValue("@OutboxID", row["OutboxID"]);
                // Pass @Operation only when the target proc declares it (avoids
                // "too many arguments" on stale SyncApply_SaleHead / Customer wrappers).
                if (ProcedureHasParameter(cnn, proc, "@Operation"))
                    cmd.Parameters.AddWithValue("@Operation",
                        row["Operation"] == DBNull.Value ? (object)DBNull.Value : row["Operation"].ToString());

                var conflict = new SqlParameter("@ConflictLogged", SqlDbType.Bit) { Direction = ParameterDirection.Output };
                var appliedParam = new SqlParameter("@Applied", SqlDbType.Bit) { Direction = ParameterDirection.Output };
                cmd.Parameters.Add(conflict);
                cmd.Parameters.Add(appliedParam);
                cmd.CommandTimeout = 0;
                EnsureOpen(cnn);
                cmd.ExecuteNonQuery();

                bool conflictLogged = conflict.Value != DBNull.Value && (bool)conflict.Value;
                bool applied = appliedParam.Value != DBNull.Value && (bool)appliedParam.Value;

                if (!applied && !conflictLogged)
                    throw new InvalidOperationException(proc + " did not apply row.");

                // Detail Op=D is a physical DELETE. The row being gone is success.
                // Head Op=D stays in the table (soft IsDeleted) and must still be found.
                string operation = row["Operation"] == DBNull.Value
                    ? ""
                    : Convert.ToString(row["Operation"]).Trim();
                bool detailHardDelete = string.Equals(operation, "D", StringComparison.OrdinalIgnoreCase)
                    && table.EndsWith("Detail", StringComparison.OrdinalIgnoreCase);

                // C2L must actually land on Local before Cloud outbox can be Synced.
                if (c2l
                    && applied && !conflictLogged
                    && !detailHardDelete
                    && !RowExistsForPrimaryKey(cnn, table, Convert.ToString(row["PrimaryKeyJson"])))
                {
                    throw new InvalidOperationException(
                        proc + " reported Applied but row missing on Local for " + table
                        + " " + Convert.ToString(row["PrimaryKeyJson"])
                        + " (Local DB=" + cnn.Database + " / " + cnn.DataSource + ")."
                        + " Check DBConnection.ini Data Source / Initial Catalog.");
                }

                return conflictLogged ? ApplyOutcome.ConflictSkipped : ApplyOutcome.Applied;
            }
        }

        private static bool RowExistsForPrimaryKey(SqlConnection cnn, string table, string primaryKeyJson)
        {
            EnsureOpen(cnn);
            if (string.IsNullOrWhiteSpace(table) || string.IsNullOrWhiteSpace(primaryKeyJson))
                return false;
            if (table.IndexOfAny(new[] { ';', '-', ' ', '\'' }) >= 0)
                return false;

            // Supports single-column PK JSON: {"ID":123}
            using (var cmd = new SqlCommand(@"
DECLARE @pk sysname;
SELECT TOP 1 @pk = c.name
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
INNER JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = OBJECT_ID(@table) AND i.is_primary_key = 1
ORDER BY ic.key_ordinal;
IF @pk IS NULL RETURN;
DECLARE @sql nvarchar(max) = N'SELECT CASE WHEN EXISTS (SELECT 1 FROM '
    + QUOTENAME(PARSENAME(@table, 1)) + N' WHERE ' + QUOTENAME(@pk)
    + N' = TRY_CAST(JSON_VALUE(@pkjson, N''$.'' + @pk) AS bigint)) THEN 1 ELSE 0 END';
-- JSON path must be literal — rebuild with known PK name
SET @sql = N'SELECT CASE WHEN EXISTS (SELECT 1 FROM ' + QUOTENAME(PARSENAME(@table, 1))
    + N' WHERE ' + QUOTENAME(@pk) + N' = TRY_CAST(JSON_VALUE(@pkjson, ''$.' + @pk + ''') AS bigint)) THEN 1 ELSE 0 END';
EXEC sp_executesql @sql, N'@pkjson nvarchar(500)', @pkjson = @pkjson;
", cnn))
            {
                // Simpler portable check for ID PK (all txn heads/details use ID)
                cmd.CommandText = @"
SELECT CASE WHEN EXISTS (
    SELECT 1 FROM [" + table.Replace("]", "]]") + @"] WHERE ID = TRY_CAST(JSON_VALUE(@pkjson, '$.ID') AS bigint)
) THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END";
                cmd.Parameters.Clear();
                cmd.Parameters.AddWithValue("@pkjson", primaryKeyJson);
                object o = cmd.ExecuteScalar();
                return o != null && o != DBNull.Value && Convert.ToBoolean(o);
            }
        }

        private static bool ProcedureExists(SqlConnection cnn, string procName)
        {
            EnsureOpen(cnn);
            using (var cmd = new SqlCommand(
                "SELECT 1 FROM sys.procedures WHERE object_id = OBJECT_ID(@name)", cnn))
            {
                cmd.Parameters.AddWithValue("@name", procName);
                return cmd.ExecuteScalar() != null;
            }
        }

        private static bool ProcedureHasParameter(SqlConnection cnn, string procName, string paramName)
        {
            EnsureOpen(cnn);
            using (var cmd = new SqlCommand(@"
SELECT 1
FROM sys.parameters p
WHERE p.object_id = OBJECT_ID(@proc)
  AND p.name = @param", cnn))
            {
                cmd.Parameters.AddWithValue("@proc", procName);
                cmd.Parameters.AddWithValue("@param", paramName);
                return cmd.ExecuteScalar() != null;
            }
        }

        private static void ExecApplyCustomer(SqlConnection cnn, string source, DataRow row)
        {
            ExecApply(cnn, source, row);
        }

        private static void CompleteOutbox(SqlConnection cnn, long outboxId, string status, string lastError = null)
        {
            EnsureOpen(cnn);
            if (lastError == null)
            {
                using (var cmd = new SqlCommand("dbo.SyncCompleteOutbox", cnn))
                {
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@OutboxID", outboxId);
                    cmd.Parameters.AddWithValue("@Status", status);
                    cmd.ExecuteNonQuery();
                }
                return;
            }

            // Conflict path: write LastError so Cloud SSMS shows LocalWins reason.
            using (var cmd = new SqlCommand(@"
UPDATE dbo.SyncOutbox
SET Status = @Status,
    SyncedAt = SYSUTCDATETIME(),
    LastError = @Err
WHERE OutboxID = @Id;", cnn))
            {
                cmd.Parameters.AddWithValue("@Id", outboxId);
                cmd.Parameters.AddWithValue("@Status", status);
                cmd.Parameters.AddWithValue("@Err", lastError);
                cmd.ExecuteNonQuery();
            }
        }

        private static void FailOutbox(SqlConnection cnn, long outboxId, string error)
        {
            EnsureOpen(cnn);
            using (var cmd = new SqlCommand(@"
UPDATE dbo.SyncOutbox
SET Status = CASE WHEN AttemptCount >= @Max THEN 'DeadLetter' ELSE 'Pending' END,
    LastError = @Err
WHERE OutboxID = @Id;

IF (SELECT AttemptCount FROM dbo.SyncOutbox WHERE OutboxID = @Id) >= @Max
    INSERT INTO dbo.SyncDeadLetter (OutboxID, TableName, PrimaryKeyJson, PayloadJson, LastError)
    SELECT OutboxID, TableName, PrimaryKeyJson, PayloadJson, @Err
    FROM dbo.SyncOutbox WHERE OutboxID = @Id AND Status = 'DeadLetter';
", cnn))
            {
                cmd.Parameters.AddWithValue("@Id", outboxId);
                cmd.Parameters.AddWithValue("@Err", error);
                cmd.Parameters.AddWithValue("@Max", MaxRetries);
                cmd.ExecuteNonQuery();
            }
        }

        private static void UpdateCloudOnline(bool online)
        {
            try
            {
                using (var local = ConnectionIni.OpenLocal())
                using (var cmd = new SqlCommand(@"
MERGE dbo.SyncState AS t
USING (SELECT N'CloudOnline' AS StateKey, @Val AS StateValue) AS s
ON t.StateKey = s.StateKey
WHEN MATCHED THEN UPDATE SET StateValue = s.StateValue, UpdatedAt = sysutcdatetime()
WHEN NOT MATCHED THEN INSERT (StateKey, StateValue) VALUES (s.StateKey, s.StateValue);
", local))
                {
                    cmd.Parameters.AddWithValue("@Val", online ? "1" : "0");
                    cmd.ExecuteNonQuery();
                }
            }
            catch
            {
                // SyncState may not exist until scripts are run
            }
        }

        private static void Log(string message)
        {
            LogInfo(message);
        }

        public static string LogFilePath
        {
            get { return System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SyncAgent.log"); }
        }

        public static void LogInfo(string message)
        {
            try
            {
                string line = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " " + message + Environment.NewLine;
                System.IO.File.AppendAllText(LogFilePath, line);
            }
            catch { }
        }

        public static void RunOnce()
        {
            new SyncEngine().RunCycle();
        }

        public static void RunDrain(int maxMinutes)
        {
            var deadline = DateTime.UtcNow.AddMinutes(maxMinutes <= 0 ? 480 : maxMinutes);
            var engine = new SyncEngine();
            int cycle = 0;
            while (DateTime.UtcNow < deadline)
            {
                engine.RunCycle();
                cycle++;
                if (cycle % 30 == 0)
                {
                    int pending = GetPendingCount("L2C");
                    LogInfo("Drain progress: L2C Pending=" + pending);
                    if (pending == 0)
                        break;
                }
                Thread.Sleep(500);
            }
            LogInfo("Drain finished. L2C Pending=" + GetPendingCount("L2C"));
        }

        private static int GetPendingCount(string direction)
        {
            try
            {
                using (var local = ConnectionIni.OpenLocal())
                using (var cmd = new SqlCommand(
                    "SELECT COUNT(*) FROM dbo.SyncOutbox WHERE Direction=@d AND Status='Pending'", local))
                {
                    cmd.Parameters.AddWithValue("@d", direction);
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
            catch
            {
                return -1;
            }
        }

        public static void RunLoop(CancellationToken token)
        {
            var engine = new SyncEngine();
            while (!token.IsCancellationRequested)
            {
                engine.RunCycle();
                Thread.Sleep(500);
            }
        }
    }
}
