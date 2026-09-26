using System;
using System.Text.RegularExpressions;

namespace SB.SyncAgent
{
    /// <summary>
    /// Dev/Test lock for this test run.
    /// Allows local\SB2 and sql8006.site4now.net / db_abe8c0_sb2.
    /// Refuses SB1, SQL1002, and the other account databases.
    /// </summary>
    internal static class DevTestGuard
    {
        public static void RejectIfForbidden(string connectionText)
        {
            if (string.IsNullOrEmpty(connectionText))
                throw new InvalidOperationException("Connection string is empty.");

            if (Regex.IsMatch(connectionText, @"Initial\s+Catalog\s*=\s*SB1\b", RegexOptions.IgnoreCase)
                || Regex.IsMatch(connectionText, @"Database\s*=\s*SB1\b", RegexOptions.IgnoreCase)
                || Regex.IsMatch(connectionText, @"Initial\s+Catalog\s*=\s*SB(?![A-Za-z0-9_])", RegexOptions.IgnoreCase)
                || Regex.IsMatch(connectionText, @"(^|\\)SB1($|\\)", RegexOptions.IgnoreCase))
            {
                throw new InvalidOperationException("SB2 Dev/Test lock: refusing SB1 or the live SB catalog.");
            }

            if (connectionText.IndexOf("sql1002", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("sql8020", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("sql8010", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("db_abbe78", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("db_abe8c0_erp", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("db_abe8c0_luckyone", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                throw new InvalidOperationException("SB2 Dev/Test lock: refusing production or another account database.");
            }

            if (connectionText.IndexOf("site4now", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                bool testServer = connectionText.IndexOf("sql8006.site4now.net", StringComparison.OrdinalIgnoreCase) >= 0;
                bool testCatalog = Regex.IsMatch(connectionText, @"Initial\s+Catalog\s*=\s*db_abe8c0_sb2\b", RegexOptions.IgnoreCase);
                if (!testServer || !testCatalog)
                    throw new InvalidOperationException("site4now is allowed only for Test Cloud sql8006.site4now.net / db_abe8c0_sb2.");
            }
        }
    }
}
