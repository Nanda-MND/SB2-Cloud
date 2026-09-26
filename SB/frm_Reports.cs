using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace SB
{
    public partial class frm_Reports : Form
    {
        public static int SelNode = 0;
        public int i;
        DataTable dtMenu, dtMenu_Sub;
        public static DateTime FDate, TDate, TransportFromDate, TransportToDate;
        string DocID, ExpLoc;
        public static string ReportFilterName = "";
        string Dateformat = "yyyy-MM-dd";

        public static string DocumentID, AutoID, FilterLocation, FilterToLocation, FilterDivision, FilterTownship, FilterCustomer, FilterBrand, FilterStockType, FilterStockGroup, FilterStock, FilterUnit, FilterPayment, FilterTransport, FilterUsers, FilterLogin, FilterSaleType, FilterAcctGroup, FilterAccount, FilterSupplier, FilterManufacturer, FilterGate, FilterCar, FilterSign, FilterQty;

        private void tbAutoID_TextChanged(object sender, EventArgs e)
        {

        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        private void printToolStripMenuItem1_Click(object sender, EventArgs e)
        {

        }

        public static int AcctiD, FilterPurchaseTypeID;
        private void cbAccount_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbAccount.DroppedDown = true;
            LocalData.AutoComplete(cbAccount, e, true);
        }

        private void trvReports_NodeMouseDoubleClick(object sender, TreeNodeMouseClickEventArgs e)
        {
            Preview();
        }

        private void trvReports_DoubleClick(object sender, EventArgs e)
        {

        }

        public frm_Reports()
        {
            InitializeComponent();
        }

        private void frm_Reports_Load(object sender, EventArgs e)
        {
            //msLocation.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name= ' Select All', Selected = cast(0 as bit), SortID = 0 Union All Select ID,Name, Selected = cast(0 as bit), SortID = isnull(SortID,999) From Location where isnull(Deleted,0) <> 1 order by SortID");

            cbAccount.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From AccountName where isnull(Deleted,0) <> 1 order by Name");
            cbAccount.DisplayMember = "Name";
            cbAccount.ValueMember = "ID";
            // -1 = All accounts. Do NOT default to a fixed cash account (was 288 Cash in Hand).
            cbAccount.SelectedValue = -1;

            cboBalQty.DataSource = DBConnection.GetSQLTable("Select ID,Name = Name From OperatorSign  order by ID");
            cboBalQty.DisplayMember = "Name";
            cboBalQty.ValueMember = "ID";
            cboBalQty.SelectedValue = 1;

            cbPurchaseType.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From PurchaseType where isnull(Deleted,0) <> 1 order by Name");
            cbPurchaseType.DisplayMember = "Name";
            cbPurchaseType.ValueMember = "ID";
            cbPurchaseType.SelectedValue = -1;
            

            msLocation.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Location where isnull(Deleted,0) <> 1 order By ID");
            msToLocation.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Location where isnull(Deleted,0) <> 1 order By ID");
            msPayment.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From PaymentType where isnull(Deleted,0) <> 1 order By ID");
            msTransport.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name = ' Select All', Selected = cast(0 as bit) Union All Select ID = -1, Name = 'None', Selected = cast(0 as bit) Union All Select ID, Name = Short + '-' + Name, Selected = cast(0 as bit) From Transport where isnull(Deleted, 0) <> 1 order By ID");
            msDivision.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Division where isnull(Deleted,0) <> 1 order By ID");
            msTownship.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Township where isnull(Deleted,0) <> 1 order By ID");
            msCustomer.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Customer where isnull(Deleted,0) <> 1 order By ID");
            msStockType.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From StockType where isnull(Deleted,0) <> 1 order By ID");
            msStockGroup.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From StockGroup where isnull(Deleted,0) <> 1 order By ID");
            //msStock.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Stock where isnull(Deleted,0) <> 1 order By ID");
            msBrand.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID = -1, Name = 'None', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Brand where isnull(Deleted,0) <> 1 order By ID");
            msUnit.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit)  Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Unit where isnull(Deleted,0) <> 1 order By ID");
            msGate.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID = -1, Name= 'None', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Gates where isnull(Deleted,0) <> 1 order By ID");
            msCar.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID = -1, Name= 'None', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Cars where isnull(Deleted,0) <> 1 order By ID");

            msSupplier.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Supplier where isnull(Deleted,0) <> 1 order By ID");
            msManufacturer.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID,Name = Short + '-' + Name, Selected = cast(0 as bit) From Manufacturer where isnull(Deleted,0) <> 1 order By ID");

            // Account Info: Short-Name only
            msAcctGroup.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = Short + '-' + Name, Selected = cast(0 as bit) From AcctGroup where isnull(Deleted,0) <> 1 order By ID");
            msAccount.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = Short + '-' + Name, Selected = cast(0 as bit) From AccountName where isnull(Deleted,0) <> 1 order By ID");

            // Account Code: ISNULL(NULLIF(code,''), Short) + '-' + Name (fallback if columns missing)
            try
            {
                msGroupCode.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = ISNULL(NULLIF(GroupCode,''), Short) + '-' + Name, Selected = cast(0 as bit) From AcctGroup where isnull(Deleted,0) <> 1 order By ID");
            }
            catch
            {
                msGroupCode.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = Short + '-' + Name, Selected = cast(0 as bit) From AcctGroup where isnull(Deleted,0) <> 1 order By ID");
            }
            try
            {
                msAccountCode.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = ISNULL(NULLIF(AccountCode,''), Short) + '-' + Name, Selected = cast(0 as bit) From AccountName where isnull(Deleted,0) <> 1 order By ID");
            }
            catch
            {
                msAccountCode.DataSource = DBConnection.GetSQLTable("Select ID = -2, Name= ' Select All', Selected = cast(0 as bit) Union All Select ID, Name = Short + '-' + Name, Selected = cast(0 as bit) From AccountName where isnull(Deleted,0) <> 1 order By ID");
            }

            FillTreeView();

        }

        private void FillTreeView()
        {
            int iMenuSub = 0;
            trvReports.BeginUpdate();
            trvReports.Nodes.Clear();


            trvReports.Nodes.Add("SB PLASTICS").ToString();
            //dtMenu = DBConnection.GetSQLTable("SELECT Sort, ID, Name From dbo.ReportName Where ID IN ( Select RS.RefID From MenuSub MS Join UserRights UR on MenuSubID = SubID  Join dbo.ReportName RS on RS.ID = MS.SubID WHERE ModuleID = 1 and  UR.MenuID = 3  and  AllowTransaction = 1 and UserID = " + frm_Main.UserID + ")order by ID ");
            dtMenu = DBConnection.GetSQLTable("Select ID, Name, SortID From ReportName Where isnull(isRoot,0) = 1 and isnull(isVisible,0) = 1 Order by SortID");
            foreach (DataRow caRow in dtMenu.Rows)
            {
                TreeNode tnMenu = new TreeNode();
                tnMenu.Text = caRow["Name"].ToString();
                tnMenu.Tag = caRow["ID"].ToString();
                tnMenu.ImageIndex = 1;
                tnMenu.SelectedImageIndex = 1;
                int.TryParse(caRow["ID"].ToString(), out iMenuSub);
                trvReports.Nodes[0].Nodes.Add(tnMenu);
                trvReports.Nodes[0].Tag = "R";


                //dtMenu_Sub = DBConnection.GetSQLTable("SELECT ID,Name From dbo.ReportName Where ID IN ( Select RS.ID From MenuSub MS Join UserRights UR on MenuSubID = SubID  Join dbo.ReportName RS on RS.ID = MS.SubID WHERE   RefID =  " + iMenuSub + " AND UR.MenuID = 3  and  AllowTransaction = 1 and GroupID = 2  and UserID = " + frm_Main.UserID + ")order by Sort");
                // DISTINCT: duplicate UserRights rows otherwise show the same report twice in the tree
                dtMenu = DBConnection.GetSQLTable("Select Distinct R.ID, R.Name, SortID From ReportName R Join UserRights U  on R.ID = U.MenuSubID Where isnull(isRoot,0) = 0 and isnull(isVisible,0) = 1 and U.MenuID = 3 and dbo.CheckUserRights(U.UserID, 3, U.MenuSubID, 0) = 1 and U.UserID = " + LocalData.UserID.ToString() + " and RefID = " + iMenuSub.ToString() + " Order by SortID ");
                foreach (DataRow crow in dtMenu.Rows)
                {
                    TreeNode tnMenu_Sub = new TreeNode();
                    tnMenu_Sub.Text = crow["Name"].ToString();
                    tnMenu_Sub.Tag = crow["ID"].ToString();
                    tnMenu_Sub.ImageIndex = 2;
                    tnMenu_Sub.SelectedImageIndex = 2;
                    tnMenu.Nodes.Add(tnMenu_Sub);
                }
            }

            trvReports.Nodes[0].Expand();
            trvReports.EndUpdate();
        }

        private void Preview()
        {
            int rptid;

            
            int.TryParse(trvReports.SelectedNode.Tag.ToString(), out rptid);
            Filter();

            Form frm = new frm_Preview(rptid);
            frm.ShowDialog();
        }

        private void Filter()
        {

            FDate = dtpFrom.Value.Date + dtpTransportFrom.Value.TimeOfDay;
            TDate = dtpTo.Value.Date + dtpTransportTo.Value.TimeOfDay;
            TransportFromDate = dtpTransportFrom.Value;
            TransportToDate = dtpTransportTo.Value;

            //if (LocalData.ShowTime)
            //{
            //    Dateformat = "yyyy-MM-dd hh:mm:ss tt";
            //}


            DocumentID = tbDocumentID.Text.ToString();
            AutoID = tbAutoID.Text.ToString();

            if (cbPurchaseType.SelectedValue != null)
                int.TryParse(cbPurchaseType.SelectedValue.ToString(), out FilterPurchaseTypeID);

            FilterLocation = msLocation.GetSelection;
            FilterToLocation = msToLocation.GetSelection;
            FilterDivision = msDivision.GetSelection;
            FilterTownship = msTownship.GetSelection;
            FilterCustomer = msCustomer.GetSelection;
            FilterBrand = msBrand.GetSelection;
            FilterStockType = msStockType.GetSelection;
            FilterStockGroup = msStockGroup.GetSelection;
            //FilterStock = msStock.GetSelection;
            FilterUnit = msUnit.GetSelection;
            FilterPayment = msPayment.GetSelection;
            FilterTransport = msTransport.GetSelection;
            //FilterUsers = msUsers.GetSelection;
            //FilterLogin = msMachine.GetSelection;
            FilterAcctGroup = MergeIdSelections(msAcctGroup.GetSelection, msGroupCode.GetSelection);
            FilterAccount = MergeIdSelections(msAccount.GetSelection, msAccountCode.GetSelection);
            FilterSupplier = msSupplier.GetSelection;
            FilterManufacturer = msManufacturer.GetSelection;
            FilterGate = msGate.GetSelection;
            FilterCar = msCar.GetSelection;

            FilterStock = tbCode.Text.ToString();
            FilterSign = cboBalQty.Text.ToString();
            FilterQty = cboBalQty.Text.ToString();

            // GL / ledger reports use AcctiD (single Int for legacy SPs).
            // MultiSelect "Select All" leaves FilterAccount empty → all accounts (-1).
            // One ID → that account. Multiple IDs → AcctiD=-1 (SP all) + FilterAccount kept for CodeID IN (...).
            // Never fall back to hidden cbAccount cash default when Select All / multi is chosen.
            if (string.IsNullOrWhiteSpace(FilterAccount))
            {
                AcctiD = -1;
            }
            else if (FilterAccount.IndexOf(',') < 0)
            {
                if (!int.TryParse(FilterAccount.Trim(), out AcctiD))
                    AcctiD = -1;
            }
            else
            {
                AcctiD = -1;
            }
        }

        /// <summary>
        /// Append account filter for GL result sets when user picked specific accounts
        /// (not Select All). Select All → empty FilterAccount → no extra predicate.
        /// GL SP stores account as LedgerName (= AccountName.Name); CodeID is not filled by dbo.GL.
        /// </summary>
        public static string GlAccountCodeFilterSql()
        {
            if (string.IsNullOrWhiteSpace(FilterAccount))
                return string.Empty;
            // Only digits, commas, spaces, minus — IDs from MultiSelect
            foreach (char c in FilterAccount)
            {
                if (!(char.IsDigit(c) || c == ',' || c == ' ' || c == '-'))
                    return string.Empty;
            }
            return " AND LedgerName IN (SELECT Name FROM AccountName WHERE ID IN (" + FilterAccount + "))";
        }
        /// <summary>
        /// Merge MultiSelect ID lists into FilterAcctGroup / FilterAccount (dedupe, preserve order).
        /// Empty / Select-All selections contribute nothing.
        /// </summary>
        private static string MergeIdSelections(params string[] selections)
        {
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var parts = new List<string>();
            if (selections == null) return string.Empty;
            foreach (string sel in selections)
            {
                if (string.IsNullOrWhiteSpace(sel)) continue;
                foreach (string raw in sel.Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries))
                {
                    string id = raw.Trim();
                    if (id.Length == 0 || id == "-2") continue;
                    if (seen.Add(id))
                        parts.Add(id);
                }
            }
            return string.Join(",", parts);
        }
    }
}
