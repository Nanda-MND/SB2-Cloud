using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data.SqlClient;
using System.Data;
using System.Windows.Forms;
namespace SB
{
    class LocalData
    {
        private static string m_CompanyName = "MinnNandar";
        private static int m_UserID = 1;
        private static int m_LoginID = 0;
        private static string m_image;
        private static DateTime m_SettingDate;
        private static DateTime m_SettingStartDate;
        private static DateTime m_SettingEndDate;
        private static string m_LetterHeadCompanyName;
        private static string m_companylogo;
        private static string m_PhoneNo;
        private static string m_Address;
        private static string m_EmailAddress;
        private static int m_Logdate;
        private static int m_DefaultBranchID;
        private static int m_FromBranchDataID;
        private static int m_FromBranchID;
        private static int m_AllowranceUser = 0;
        private static int m_LogInBranchID = 0;
        private static Boolean m_IsPersonSetup = false;
        private static string m_Login = "";
        private static string m_UserName = "";
        public static DateTime SaleDate;
        public static int ci = 0;


        private static int m_BrandID = 0, m_LocationID = 0, m_CustGroupID = -1, m_CustomerID = -1, m_StockTypeID = 0, m_CodeID = 0, m_SupGroupID = 0, m_SupplierID = 0, m_PaymentID = -1, m_TransportID = 0, m_CarID = 0, m_TownshipID =0, m_ManufacturerID = 0;
        private static string m_AutoID = "", m_DocumentID = "", m_InvoiceID = "";
        private static DateTime m_FromDate, m_ToDate;
        private static string m_CurrencyFormat = "#,##0.#";
        private static string m_IntegerFormat = "#,##0";
        public static string m_moneyformat = "#,##0.#0";
        private static string m_Invoice = "00000#";
        private static string m_DateFormat = "d";
        private static string m_CurrencySymbol = "$";
        private static string m_Query = "";
        private static string m_Filter = "";
        private static string m_GroupBy = "";
        private static string m_FromLocation = "ALL";
        private static string m_ToLocation = "ALL";
        public static Boolean u_Edit = false, u_Delete = false;
        public static Boolean AllowDateChange = true, AllowAll = true, AllowPrint = true, AllowEntry = true, AllowEdit = true, AllowDelete = true, SetupAllowEntry = true, SetupAllowEdit = true, SetupAllowDelete = true, AllowExport = true, HidePurPrice = true, ShowTime = false, CheckVr = false, AllowBackDate = true;

        public static string m_Brand = "";
        public static string m_Size = "";
        public static string m_code = "";
        public static string m_Unit = "";

        public static string UserName { get { return m_UserName; } set { m_UserName = value; } }
        public static string Login { get { return m_Login; } set { m_Login = value; } }
        public static string Brand { get { return m_Brand; } set { m_Brand = value; } }
        public static string Size { get { return m_Size; } set { m_Size = value; } }
        public static string Code { get { return m_code; } set { m_code = value; } }
        public static string Unit { get { return m_Unit; } set { m_Unit = value; } }

        public static DateTime SettingStartDate { get { return m_SettingStartDate; } set { m_SettingStartDate = value; } }
        public static DateTime SettingEndDate { get { return m_SettingEndDate; } set { m_SettingEndDate = value; } }
        public static DateTime SettingDate { get { return m_SettingDate; } set { m_SettingDate = value; } }
        public static int DefaultBranchID { get { return m_DefaultBranchID; } set { m_DefaultBranchID = value; } }
        public static int FromBranchDataID { get { return m_FromBranchDataID; } set { m_FromBranchDataID = value; } }
        public static int FromBranchID { get { return m_FromBranchID; } set { m_FromBranchID = value; } }
        public static Boolean CanEdit { get { return u_Edit; } set { u_Edit = value; } }
        public static Boolean CanDelete { get { return u_Delete; } set { u_Delete = value; } }
        public static string image { get { return m_image; } set { m_image = value; } }
        public static int LogDate { get { return m_Logdate; } set { m_Logdate = value; } }
        public static int UserID { get { return m_UserID; } set { m_UserID = value; } }
        public static int LoginID { get { return m_LoginID; } set { m_LoginID = value; } }
        public static int BrandID { get { return m_BrandID; } set { m_BrandID = value; } }
        public static int LocationID { get { return m_LocationID; } set { m_LocationID = value; } }
        public static int CustGroupID { get { return m_CustGroupID; } set { m_CustGroupID = value; } }
        public static int CustomerID { get { return m_CustomerID; } set { m_CustomerID = value; } }
        public static int SupGroupID { get { return m_SupGroupID; } set { m_SupGroupID = value; } }
        public static int SupplierID { get { return m_SupplierID; } set { m_SupplierID = value; } }
        public static int ManufacturerID { get { return m_ManufacturerID; } set { m_ManufacturerID = value; } }
        public static int StockTypeID { get { return m_StockTypeID; } set { m_StockTypeID = value; } }
        public static int PaymentID { get { return m_PaymentID; } set { m_PaymentID = value; } }
        public static int CodeID { get { return m_CodeID; } set { m_CodeID = value; } }
        public static int TownshipID { get { return m_TownshipID; } set { m_TownshipID = value; } }
        public static int TransportID { get { return m_TransportID; } set { m_TransportID = value; } }
        public static int CarID { get { return m_CarID; } set { m_CarID = value; } }
        public static DateTime FromDate { get { return m_FromDate; } set { m_FromDate = value; } }
        public static DateTime ToDate { get { return m_ToDate; } set { m_ToDate = value; } }
        public static string CurrencyFormat { get { return m_CurrencyFormat + m_CurrencySymbol; } set { m_CurrencyFormat = value; } }
        public static string CurrencySymbol { get { return m_CurrencySymbol; } set { m_CurrencySymbol = value; } }
        public static string IntegerFormat { get { return m_IntegerFormat; } set { m_IntegerFormat = value; } }
        public static string moneyformat { get { return m_moneyformat; } set { m_moneyformat = value; } }
        public static string Invoice { get { return m_Invoice; } set { m_Invoice = value; } }
        public static string DateFormat { get { return m_DateFormat; } set { m_DateFormat = value; } }
        public static string AutoID { get { return m_AutoID; } set { m_AutoID = value; } }
        public static string FromLocation { get { return m_FromLocation; } set { m_FromLocation = value; } }
        public static string ToLocation { get { return m_ToLocation; } set { m_ToLocation = value; } }
        public static string DocumentID { get { return m_DocumentID; } set { m_DocumentID = value; } }
        public static string InvoiceNo { get { return m_InvoiceID; } set { m_InvoiceID = value; } }
        public static string Filter { get { return m_Filter; } set { m_Filter = value; } }
        public static string GroupBy { get { return m_GroupBy; } set { m_GroupBy = value; } }
        public static string Query { get { return m_Query; } set { m_Query = value; } }
        public static int AlloranceUser { get { return m_AllowranceUser; } set { m_AllowranceUser = value; } }

        public static string Logo { get { return m_companylogo; } set { m_companylogo = value; } }
        public static string LetterheadCompanyname { get { return m_LetterHeadCompanyName; } set { m_LetterHeadCompanyName = value; } }
        public static string PhoneNo { get { return m_PhoneNo; } set { m_PhoneNo = value; } }
        public static string Address { get { return m_Address; } set { m_Address = value; } }
        public static string EmailAddress { get { return m_EmailAddress; } set { m_EmailAddress = value; } }
        public static int LogInBranchID { get { return m_LogInBranchID; } set { m_LogInBranchID = value; } }
        public static Boolean IsPersonSetup { get { return m_IsPersonSetup; } set { m_IsPersonSetup = value; } }

        public static void AutoComplete(ComboBox cb, KeyPressEventArgs e, bool LimitToList)
        {
            String strFindStr = "";
            if (e.KeyChar == (char)8)
            {
                if (cb.SelectionStart <= 1)
                {
                    cb.Text = "";
                    return;
                }
                if (cb.SelectionLength == 0)
                {
                    strFindStr = cb.Text.Substring(0, cb.Text.Length - 1);

                }
                else
                {
                    strFindStr = cb.Text.Substring(0, cb.SelectionStart - 1);
                }
            }
            else
            {
                if (cb.SelectionLength == 0)
                {
                    strFindStr = cb.Text + e.KeyChar;
                }
                else
                {
                    strFindStr = cb.Text.Substring(0, cb.SelectionStart) + e.KeyChar;
                }
            }

            int index = -1;
            index = cb.FindString(strFindStr);
            if (index != -1)
            {
                cb.SelectedText = "";
                cb.SelectedIndex = index;
                cb.SelectionStart = strFindStr.Length;
                cb.SelectionLength = cb.Text.Length;
                e.Handled = true;
            }
            else
            {
                e.Handled = LimitToList;
            }
        }

        public static void TextboxCurrencyFormat(TextBox tb)
        {
            decimal amount;
            decimal.TryParse(tb.Text.ToString(), out amount);
            tb.Text = amount.ToString("#,##0");
        }

        public static void Initializing()
        {
            CompanyName = DBConnection.rExecSQL(@"select Name from Setting");
            LocalData.CurrencySymbol = DBConnection.rExecSQL("select Symbol from Currency where Home = 1 ");
            LocalData.CurrencyFormat = DBConnection.rExecSQL("select CurrencyFormat from Setting");

        }

        public static string CompanyName { get { return m_CompanyName; } set { m_CompanyName = value; } }

        public enum mySetup
        { Branch = 1, Location = 2, Class = 3, Category = 4, Code = 5, Division = 6, Township = 7, Customer = 8, Supplier = 9, Manufacturer = 10, Transport = 11, Gate = 12, Account = 13, Unit = 14, Users = 15, Brand = 16, Cars =17, AcctGroup = 18, BrandNStock = 19, AcctSubGroup = 20 }

        public static mySetup Setup = mySetup.Branch;

        /// <summary>Optional MainGroupID when creating AcctSubGroup from tree New.</summary>
        public static int PrefillMainGroupID = 0;

        public enum myMenu
        {
            SaleOrder = 1, Sale = 2, SaleReturn = 3, PurchaseOrder = 4, Purchase = 5, Receive = 6, PurchaseReturn = 7, Adjustment = 8, Transfer = 9, StockOpening = 10, CustomerOpening = 11, SupplierOpening = 12, ManufacturerOpening = 13, CustSettlement = 14, SupSettlement = 15, ManuSettlement = 16, Manufacture = 17, StockBalance = 18, AcctOpening = 19, IncomeExpense = 20, Journal = 21, Exchange = 22, PriceChange = 23, RawIssue = 24, FinishGoods = 25, CustBalance =26, SupBalance = 27, ManuBalance =28, CustSup = 29, ReturnStock = 30, GetStock = 31, ReturnReceive = 32, GoodsIssue = 33, GoodsReceive = 34, GoodsRecieveManu = 35
        }

        public static myMenu Menu = myMenu.Sale;



        public static void SetAutoID(myMenu type, DateTime date)
        {
            SqlParameter[] para = new SqlParameter[3];
            para[0] = new SqlParameter("@UserID", SqlDbType.Int); para[0].Value = LocalData.UserID;
            para[1] = new SqlParameter("@Date", SqlDbType.Date); para[1].Value = date;
            para[2] = new SqlParameter("@MenuID", SqlDbType.TinyInt); para[2].Value = Convert.ToInt32(type);
            DBConnection.ExecSp("SetAutoID", para);
        }


        public static bool IsNumeric(string text)
        {
            int isNumber = 0;
            if (!int.TryParse(text.ToString(), out isNumber))
            {
                MessageBox.Show("Please Type Number Only !!!");
                return true;
            }
            else
            {
                return false;
            }
        }

        public static string CreatePassword(int length)
        {
            const string valid = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~!@#";
            StringBuilder res = new StringBuilder();
            Random rnd = new Random();
            while (0 < length--)
            {
                res.Append(valid[rnd.Next(valid.Length)]);
            }
            return res.ToString();
        }

    }
}
