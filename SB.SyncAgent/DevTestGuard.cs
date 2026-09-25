using System;
using System.Text.RegularExpressions;

namespace SB.SyncAgent
{
    /// <summary>
    /// Dev/Test lock. Refuses SB1 and the production cloud host.
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

            if (connectionText.IndexOf("site4now", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("sql1002", StringComparison.OrdinalIgnoreCase) >= 0
                || connectionText.IndexOf("db_abbe78", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                throw new InvalidOperationException("SB2 Dev/Test lock: refusing the production cloud host.");
            }
        }
    }
}
