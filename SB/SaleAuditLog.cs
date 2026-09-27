using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;

namespace SB
{
    /// <summary>
    /// Sales-only edit/delete audit (line-level: Add/Update/Delete only).
    /// Forward-looking — past edits are not backfilled.
    /// </summary>
    internal static class SaleAuditLog
    {
        private static string SqlStr(object value)
        {
            if (value == null || value == DBNull.Value)
                return "NULL";
            return "N'" + value.ToString().Replace("'", "''") + "'";
        }

        private static string SqlNum(object value)
        {
            if (value == null || value == DBNull.Value)
                return "NULL";
            decimal d;
            if (decimal.TryParse(value.ToString(), NumberStyles.Any, CultureInfo.InvariantCulture, out d)
                || decimal.TryParse(value.ToString(), out d))
                return d.ToString(CultureInfo.InvariantCulture);
            return "NULL";
        }

        private static string SqlInt(object value)
        {
            if (value == null || value == DBNull.Value)
                return "NULL";
            int i;
            if (int.TryParse(value.ToString(), out i))
                return i.ToString(CultureInfo.InvariantCulture);
            return "NULL";
        }

        private static string SqlDate(object value)
        {
            if (value == null || value == DBNull.Value)
                return "NULL";
            DateTime dt;
            if (DateTime.TryParse(value.ToString(), out dt))
                return "'" + dt.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture) + "'";
            return "NULL";
        }

        private static decimal ToDecimalValue(object value)
        {
            if (value == null || value == DBNull.Value)
                return 0m;
            decimal d;
            string s = Convert.ToString(value);
            if (decimal.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out d))
                return d;
            if (decimal.TryParse(s, out d))
                return d;
            return 0m;
        }

        private static bool SameDec(object a, object b)
        {
            return Math.Abs(ToDecimalValue(a) - ToDecimalValue(b)) < 0.0001m;
        }

        private static object GetVersion(DataRow row, string col, DataRowVersion ver)
        {
            if (row == null || !row.Table.Columns.Contains(col))
                return DBNull.Value;
            try
            {
                if (ver == DataRowVersion.Original && (row.RowState == DataRowState.Added || row.HasVersion(DataRowVersion.Original) == false))
                    return DBNull.Value;
                return row[col, ver];
            }
            catch
            {
                return DBNull.Value;
            }
        }

        private static bool LineChanged(DataRow row)
        {
            string[] cols = { "CodeID", "BrandID", "UnitID", "Qty", "Price", "Amount", "Weight", "Qty1", "Qty2", "Remark", "Sr" };
            foreach (string c in cols)
            {
                if (!row.Table.Columns.Contains(c))
                    continue;
                object o = GetVersion(row, c, DataRowVersion.Original);
                object n = GetVersion(row, c, DataRowVersion.Current);
                if (Convert.ToString(o) != Convert.ToString(n))
                    return true;
            }
            return false;
        }

        /// <summary>
        /// Call before SaleHead/SaleDetail Update when editing an existing Sale.
        /// </summary>
        public static void LogSaleEdit(int saleHeadId, DataRow headRow, DataTable dtDetail)
        {
            if (saleHeadId <= 0 || headRow == null || dtDetail == null)
                return;
            if (OBJECT_MISSING())
                return;

            DataTable oldHead = DBConnection.GetSQLTable(
                "Select Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, AutoID, DocumentID, SaleID, CustomerID, LocationID, Date From SaleHead Where ID = " + saleHeadId.ToString());
            if (oldHead == null || oldHead.Rows.Count == 0)
                return;
            DataRow oh = oldHead.Rows[0];

            bool headChanged =
                !SameDec(oh["Amount"], headRow["Amount"])
                || !SameDec(oh["Discount"], headRow["Discount"])
                || !SameDec(oh["NetAmount"], headRow["NetAmount"])
                || !SameDec(oh["TaxAmount"], headRow["TaxAmount"])
                || !SameDec(oh["AddAmount"], headRow["AddAmount"])
                || !SameDec(oh["TotalAmount"], headRow["TotalAmount"])
                || !SameDec(oh["PaidAmount"], headRow["PaidAmount"])
                || Convert.ToString(oh["CustomerID"]) != Convert.ToString(headRow["CustomerID"])
                || Convert.ToString(oh["LocationID"]) != Convert.ToString(headRow["LocationID"])
                || Convert.ToString(oh["DocumentID"]) != Convert.ToString(headRow["DocumentID"])
                || !SameDate(oh["Date"], headRow["Date"]);

            List<string> detailSql = new List<string>();
            foreach (DataRow row in dtDetail.Rows)
            {
                if (row.RowState == DataRowState.Detached)
                    continue;

                if (row.RowState == DataRowState.Added)
                {
                    detailSql.Add(BuildDetailInsert('A', row, DataRowVersion.Current, DataRowVersion.Current));
                }
                else if (row.RowState == DataRowState.Deleted)
                {
                    detailSql.Add(BuildDetailInsert('D', row, DataRowVersion.Original, DataRowVersion.Original));
                }
                else if (row.RowState == DataRowState.Modified && LineChanged(row))
                {
                    detailSql.Add(BuildDetailInsert('U', row, DataRowVersion.Original, DataRowVersion.Current));
                }
            }

            if (!headChanged && detailSql.Count == 0)
                return;

            int auditId = InsertHead(
                saleHeadId,
                'E',
                oh,
                headRow,
                ToDecimalValue(oh["TotalAmount"]),
                ToDecimalValue(headRow["TotalAmount"]));

            if (auditId <= 0)
                return;

            foreach (string sql in detailSql)
            {
                if (string.IsNullOrEmpty(sql))
                    continue;
                DBConnection.ExecSQL(sql.Replace("{AUDITID}", auditId.ToString(CultureInfo.InvariantCulture)));
            }
        }

        /// <summary>
        /// Call before soft-deleting SaleHead.
        /// </summary>
        public static void LogSaleDelete(int saleHeadId)
        {
            if (saleHeadId <= 0)
                return;
            if (OBJECT_MISSING())
                return;

            DataTable oldHead = DBConnection.GetSQLTable(
                "Select Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, AutoID, DocumentID, SaleID, CustomerID, LocationID, Date From SaleHead Where ID = " + saleHeadId.ToString() + " And ISNULL(Deleted,0)<>1");
            if (oldHead == null || oldHead.Rows.Count == 0)
                return;
            DataRow oh = oldHead.Rows[0];

            DataTable oldDetail = DBConnection.GetSQLTable(
                "Select ID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, Amount, Qty1, Qty2, Remark From SaleDetail Where RefID = " + saleHeadId.ToString());

            int auditId = InsertHead(
                saleHeadId,
                'D',
                oh,
                oh,
                ToDecimalValue(oh["TotalAmount"]),
                ToDecimalValue(oh["TotalAmount"]));

            if (auditId <= 0 || oldDetail == null)
                return;

            foreach (DataRow row in oldDetail.Rows)
            {
                string sql =
                    "Insert Into SaleAuditDetail (AuditID, LineAction, SaleDetailID, Sr, CodeID, BrandID, UnitID, " +
                    "OldQty, OldPrice, OldAmount, OldWeight, OldQty1, OldQty2, NewQty, NewPrice, NewAmount, NewWeight, NewQty1, NewQty2, Remark) Values (" +
                    auditId.ToString(CultureInfo.InvariantCulture) + ", 'D', " +
                    SqlInt(row["ID"]) + ", " + SqlInt(row["Sr"]) + ", " + SqlInt(row["CodeID"]) + ", " +
                    SqlInt(row["BrandID"]) + ", " + SqlInt(row["UnitID"]) + ", " +
                    SqlNum(row["Qty"]) + ", " + SqlNum(row["Price"]) + ", " + SqlNum(row["Amount"]) + ", " +
                    SqlNum(row["Weight"]) + ", " + SqlNum(row["Qty1"]) + ", " + SqlNum(row["Qty2"]) + ", " +
                    "NULL, NULL, NULL, NULL, NULL, NULL, " + SqlStr(row["Remark"]) + ")";
                DBConnection.ExecSQL(sql);
            }
        }

        private static bool OBJECT_MISSING()
        {
            object o = DBConnection.roExecSQL("Select OBJECT_ID(N'dbo.SaleAuditHead', N'U')");
            return o == null || o == DBNull.Value || Convert.ToInt32(o) == 0;
        }

        private static bool SameDate(object a, object b)
        {
            DateTime da = DateTime.MinValue;
            DateTime db = DateTime.MinValue;
            bool okA = a != null && a != DBNull.Value && DateTime.TryParse(a.ToString(), out da);
            bool okB = b != null && b != DBNull.Value && DateTime.TryParse(b.ToString(), out db);
            if (!okA && !okB)
                return true;
            if (!okA || !okB)
                return false;
            return da.Date == db.Date;
        }

        private static int InsertHead(int saleHeadId, char action, DataRow oldHead, DataRow newHead, decimal oldTotal, decimal newTotal)
        {
            // ActionDate = when Edit/Delete was performed (GETDATE)
            // OldDate/NewDate = invoice Date before/after
            // OldCustomerID/NewCustomerID = customer before/after
            object oldDate = oldHead["Date"];
            object newDate = newHead["Date"];
            object oldCust = oldHead["CustomerID"];
            object newCust = newHead["CustomerID"];

            string insertSql =
                "Insert Into SaleAuditHead (SaleHeadID, Action, UserID, ActionDate, InvoiceDate, OldDate, NewDate, AutoID, DocumentID, SaleID, " +
                "CustomerID, OldCustomerID, NewCustomerID, LocationID, " +
                "Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, OldTotalAmount, NewTotalAmount) " +
                "Output INSERTED.ID Values (" +
                saleHeadId.ToString(CultureInfo.InvariantCulture) + ", '" + action + "', " +
                LocalData.UserID.ToString(CultureInfo.InvariantCulture) + ", GETDATE(), " +
                SqlDate(newDate) + ", " +
                SqlDate(oldDate) + ", " +
                SqlDate(newDate) + ", " +
                SqlStr(newHead["AutoID"]) + ", " +
                SqlStr(newHead["DocumentID"]) + ", " +
                SqlInt(newHead.Table.Columns.Contains("SaleID") ? newHead["SaleID"] : DBNull.Value) + ", " +
                SqlInt(newCust) + ", " +
                SqlInt(oldCust) + ", " +
                SqlInt(newCust) + ", " +
                SqlInt(newHead["LocationID"]) + ", " +
                SqlNum(newHead["Amount"]) + ", " +
                SqlNum(newHead["Discount"]) + ", " +
                SqlNum(newHead["NetAmount"]) + ", " +
                SqlNum(newHead["TaxAmount"]) + ", " +
                SqlNum(newHead["AddAmount"]) + ", " +
                SqlNum(newHead["TotalAmount"]) + ", " +
                SqlNum(newHead["PaidAmount"]) + ", " +
                oldTotal.ToString(CultureInfo.InvariantCulture) + ", " +
                newTotal.ToString(CultureInfo.InvariantCulture) + ")";

            object idObj = DBConnection.roExecSQL(insertSql);
            int id;
            if (idObj != null && int.TryParse(Convert.ToDecimal(idObj).ToString("0", CultureInfo.InvariantCulture), out id))
                return id;
            return 0;
        }

        private static string BuildDetailInsert(char lineAction, DataRow row, DataRowVersion oldVer, DataRowVersion newVer)
        {
            object oldQty = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Qty", oldVer);
            object oldPrice = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Price", oldVer);
            object oldAmount = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Amount", oldVer);
            object oldWeight = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Weight", oldVer);
            object oldQty1 = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Qty1", oldVer);
            object oldQty2 = lineAction == 'A' ? DBNull.Value : GetVersion(row, "Qty2", oldVer);

            object newQty = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Qty", newVer);
            object newPrice = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Price", newVer);
            object newAmount = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Amount", newVer);
            object newWeight = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Weight", newVer);
            object newQty1 = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Qty1", newVer);
            object newQty2 = lineAction == 'D' ? DBNull.Value : GetVersion(row, "Qty2", newVer);

            DataRowVersion idVer = lineAction == 'A' ? DataRowVersion.Current : DataRowVersion.Original;
            if (lineAction == 'U')
                idVer = DataRowVersion.Current;

            return
                "Insert Into SaleAuditDetail (AuditID, LineAction, SaleDetailID, Sr, CodeID, BrandID, UnitID, " +
                "OldQty, OldPrice, OldAmount, OldWeight, OldQty1, OldQty2, NewQty, NewPrice, NewAmount, NewWeight, NewQty1, NewQty2, Remark) Values (" +
                "{AUDITID}, '" + lineAction + "', " +
                SqlInt(GetVersion(row, "ID", idVer)) + ", " +
                SqlInt(GetVersion(row, "Sr", lineAction == 'D' ? DataRowVersion.Original : DataRowVersion.Current)) + ", " +
                SqlInt(GetVersion(row, "CodeID", lineAction == 'D' ? DataRowVersion.Original : DataRowVersion.Current)) + ", " +
                SqlInt(GetVersion(row, "BrandID", lineAction == 'D' ? DataRowVersion.Original : DataRowVersion.Current)) + ", " +
                SqlInt(GetVersion(row, "UnitID", lineAction == 'D' ? DataRowVersion.Original : DataRowVersion.Current)) + ", " +
                SqlNum(oldQty) + ", " + SqlNum(oldPrice) + ", " + SqlNum(oldAmount) + ", " +
                SqlNum(oldWeight) + ", " + SqlNum(oldQty1) + ", " + SqlNum(oldQty2) + ", " +
                SqlNum(newQty) + ", " + SqlNum(newPrice) + ", " + SqlNum(newAmount) + ", " +
                SqlNum(newWeight) + ", " + SqlNum(newQty1) + ", " + SqlNum(newQty2) + ", " +
                SqlStr(GetVersion(row, "Remark", lineAction == 'D' ? DataRowVersion.Original : DataRowVersion.Current)) + ")";
        }
    }
}
