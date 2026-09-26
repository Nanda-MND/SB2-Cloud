using System;
using System.Data.SqlClient;
using System.IO;
using System.Text;

namespace SB.SyncAgent
{
    internal static class ConnectionIni
    {
        public const string EncryptKey = "27042005";

        public static string ReadDecrypted(string fileName)
        {
            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, fileName);
            if (!File.Exists(path))
                throw new FileNotFoundException("Missing connection file: " + path);

            string tmp = File.ReadAllText(path, Encoding.UTF8);
            var engine = new RC4Engine { EncryptionKey = EncryptKey, CryptedText = tmp };
            if (!engine.Decrypt())
                throw new InvalidOperationException("Failed to decrypt " + fileName);
            DevTestGuard.RejectIfForbidden(engine.InClearText);
            return engine.InClearText;
        }

        public static void WriteEncrypted(string fileName, string connectionString)
        {
            DevTestGuard.RejectIfForbidden(connectionString);
            var engine = new RC4Engine { EncryptionKey = EncryptKey, InClearText = connectionString };
            if (!engine.Encrypt())
                throw new InvalidOperationException("Failed to encrypt connection string.");

            string path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, fileName);
            File.WriteAllText(path, engine.CryptedText, Encoding.UTF8);
        }

        public static SqlConnection OpenLocal()
        {
            var builder = new SqlConnectionStringBuilder(ReadDecrypted("DBConnection.ini"));
            var cnn = new SqlConnection(builder.ConnectionString);
            cnn.Open();
            return cnn;
        }

        public static SqlConnection OpenCloud()
        {
            var builder = new SqlConnectionStringBuilder(ReadDecrypted("CloudConnection.ini"));
            var cnn = new SqlConnection(builder.ConnectionString);
            cnn.Open();
            return cnn;
        }
    }
}
