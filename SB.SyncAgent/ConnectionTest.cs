using System;

namespace SB.SyncAgent
{
    internal static class ConnectionTest
    {
        public static int Run()
        {
            int errors = 0;
            Console.WriteLine("Testing Local (DBConnection.ini)...");
            try
            {
                using (var cnn = ConnectionIni.OpenLocal())
                    Console.WriteLine("  OK — " + cnn.Database + " on " + cnn.DataSource);
            }
            catch (Exception ex)
            {
                Console.WriteLine("  FAIL — " + ex.Message);
                errors++;
            }

            Console.WriteLine("Testing Cloud (CloudConnection.ini)...");
            try
            {
                using (var cnn = ConnectionIni.OpenCloud())
                    Console.WriteLine("  OK — " + cnn.Database + " on " + cnn.DataSource);
            }
            catch (Exception ex)
            {
                Console.WriteLine("  FAIL — " + ex.Message);
                errors++;
            }

            return errors;
        }
    }
}
