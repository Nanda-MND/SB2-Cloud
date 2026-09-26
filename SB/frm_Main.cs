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
    public partial class frm_Main : Form
    {
        Boolean show_left_panel = false, HideZero = false;
        String CustAging = String.Empty;
        Form frm;
        private ProgressBar tspbHistoryLoad;
        private HistoryProgressHost tspbHistoryLoadHost;
        private ToolStripMenuItem cmsPrint;
        private int _historyLoadDepth;
        private bool _inHistoryProgressWait;
        private System.Collections.ArrayList _selectionBeforePointer;
        private bool _pointerCtrl;
        private bool _pointerShift;
        private System.Collections.ArrayList _lastMultiSelection;
        private System.Collections.ArrayList _pendingMulti;
        private bool _multiReapplyQueued;
        private bool _restoreMultiOnContext;
        private bool _historyDeleteAllowed = true;

        private sealed class HistoryProgressHost : ToolStripControlHost
        {
            public HistoryProgressHost(ProgressBar bar) : base(bar)
            {
                AutoSize = false;
            }

            public ProgressBar Bar
            {
                get { return (ProgressBar)Control; }
            }

            protected override AccessibleObject CreateAccessibilityInstance()
            {
                return Control.AccessibilityObject;
            }
        }
        private static void MouseEnter(Button btn, EventArgs e)
        {
            btn.BackColor = Color.FromArgb(130, 60, 180); ;
        }
        private static void MouseLeave(Button btn, EventArgs e)
        {
            btn.BackColor = Color.FromArgb(150, 90, 255);
        }

        private void LeftPanelShowHide()
        {

            if (show_left_panel)
            {
                pbShowLeftPanel.Image = global::SB.Properties.Resources.arrow_rigth;
                splitContainer1.SplitterDistance = 30;
                splitContainer3.SplitterDistance = 0;
                //tlpLeft.Width = 0;
            }
            else
            {
                pbShowLeftPanel.Image = global::SB.Properties.Resources.arrow_left;
                splitContainer1.SplitterDistance = 280;
                //tlpLeft.Width = 180;
            }
        }

        public frm_Main()
        {
            InitializeComponent();
            EnsureHistoryChrome();
        }

        private void EnsureHistoryChrome()
        {
            if (tspbHistoryLoad == null && statusStrip1 != null)
            {
                tspbHistoryLoad = new ProgressBar();
                tspbHistoryLoad.Name = "tspbHistoryLoad";
                tspbHistoryLoad.AccessibleName = "tspbHistoryLoad";
                tspbHistoryLoad.AccessibleRole = AccessibleRole.ProgressBar;
                tspbHistoryLoad.Width = 180;
                tspbHistoryLoad.Height = 18;
                tspbHistoryLoad.Minimum = 0;
                tspbHistoryLoad.Maximum = 100;
                tspbHistoryLoad.Style = ProgressBarStyle.Marquee;
                tspbHistoryLoad.MarqueeAnimationSpeed = 30;
                tspbHistoryLoad.Visible = true;

                tspbHistoryLoadHost = new HistoryProgressHost(tspbHistoryLoad);
                tspbHistoryLoadHost.Name = "tspbHistoryLoadHost";
                tspbHistoryLoadHost.AccessibleName = "tspbHistoryLoad";
                tspbHistoryLoadHost.AccessibleRole = AccessibleRole.ProgressBar;
                tspbHistoryLoadHost.AutoSize = false;
                tspbHistoryLoadHost.Width = 180;
                tspbHistoryLoadHost.Height = 22;
                tspbHistoryLoadHost.Visible = false;
                tspbHistoryLoad.Visible = false;
                statusStrip1.Items.Insert(1, tspbHistoryLoadHost);
            }

            dlvHistory.SelectionChanged -= dlvHistory_SelectionChanged;
            dlvHistory.SelectionChanged += dlvHistory_SelectionChanged;
            dlvHistory.MouseDown -= dlvHistory_MouseDown;
            dlvHistory.MouseDown += dlvHistory_MouseDown;
            dlvHistory.MouseUp -= dlvHistory_MouseUp;
            dlvHistory.MouseUp += dlvHistory_MouseUp;

            if (cmsPrint == null && cmsTransaction != null)
            {
                cmsPrint = new ToolStripMenuItem();
                cmsPrint.Name = "cmsPrint";
                cmsPrint.Text = "Print";
                cmsPrint.Enabled = false;
                cmsPrint.Click += cmsPrint_Click;
                int deleteAt = cmsTransaction.Items.IndexOf(deleteToolStripMenuItem);
                cmsTransaction.Items.Insert(deleteAt < 0 ? cmsTransaction.Items.Count : deleteAt + 1, cmsPrint);
            }

            KeepHistorySelectionMode();
            LayoutHistoryStatusSummary();
        }

        private void KeepHistorySelectionMode()
        {
            if (dlvHistory == null)
                return;
            // Assigning MultiSelect clears the current selection, so only write it when needed.
            if (!dlvHistory.MultiSelect)
                dlvHistory.MultiSelect = true;
            dlvHistory.FullRowSelect = true;
            dlvHistory.HideSelection = false;
        }

        private void BeginHistoryLoadProgress()
        {
            if (tspbHistoryLoad == null || tspbHistoryLoadHost == null || statusStrip1 == null)
                return;
            _historyLoadDepth++;
            if (_historyLoadDepth != 1)
                return;
            statusStrip1.Visible = true;
            tspbHistoryLoad.Style = ProgressBarStyle.Marquee;
            tspbHistoryLoad.MarqueeAnimationSpeed = 30;
            tspbHistoryLoad.Visible = true;
            tspbHistoryLoadHost.Visible = true;
            tspbHistoryLoadHost.Available = true;
            tspbHistoryLoad.CreateControl();
            statusStrip1.PerformLayout();
            statusStrip1.Refresh();
            tspbHistoryLoad.Refresh();
            // Pump once so UI Automation can see the bar before the query blocks the UI thread.
            Application.DoEvents();
        }

        private void EndHistoryLoadProgress()
        {
            if (tspbHistoryLoad == null || tspbHistoryLoadHost == null)
                return;
            if (_historyLoadDepth > 0)
                _historyLoadDepth--;
            if (_historyLoadDepth > 0)
                return;
            if (_inHistoryProgressWait)
                return;
            _inHistoryProgressWait = true;
            try
            {
                // Queries block the UI thread, so a watcher cannot sample the bar until we pump.
                // Stay visible after the bind (success or failure), then hide and pump the hide.
                DateTime visibleUntil = DateTime.UtcNow.AddMilliseconds(600);
                while (DateTime.UtcNow < visibleUntil)
                {
                    Application.DoEvents();
                    System.Threading.Thread.Sleep(25);
                }
                tspbHistoryLoadHost.Visible = false;
                tspbHistoryLoad.Visible = false;
                tspbHistoryLoad.Style = ProgressBarStyle.Continuous;
                tspbHistoryLoad.Value = 0;
                if (statusStrip1 != null)
                    statusStrip1.Refresh();
                Application.DoEvents();
            }
            finally
            {
                _inHistoryProgressWait = false;
            }
        }

        private void cmsPrint_Click(object sender, EventArgs e)
        {
            if (dlvHistory.SelectedItems.Count < 1)
                return;
            using (frm_PrintSelect dlg = new frm_PrintSelect())
                dlg.ShowDialog(this);
        }

        private void splitContainer2_Panel2_Paint(object sender, PaintEventArgs e)
        {

        }

        private void ChangeFilter()
        {
            switch (LocalData.Menu)
            {
                case LocalData.myMenu.SaleOrder:
                case LocalData.myMenu.Sale:
                case LocalData.myMenu.SaleReturn:
                case LocalData.myMenu.CustSettlement:
                case LocalData.myMenu.CustBalance:
                    if (lbCustomer.Text != "Customer")
                    {
                        lbCustomer.Text = "Customer";
                        cboCustomer.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Customer where isnull(Deleted,0) <> 1 order by Name");
                        cboCustomer.DisplayMember = "Name";
                        cboCustomer.ValueMember = "ID";
                        cboCustomer.SelectedValue = -1;
                    }
                    break;
                case LocalData.myMenu.PurchaseOrder:
                case LocalData.myMenu.Purchase:
                case LocalData.myMenu.Receive:
                case LocalData.myMenu.PurchaseReturn:
                case LocalData.myMenu.SupplierOpening:
                case LocalData.myMenu.SupSettlement:
                case LocalData.myMenu.SupBalance:
                case LocalData.myMenu.ReturnReceive:
                case LocalData.myMenu.GoodsReceive:
                    if (lbCustomer.Text != "Supplier")
                    {
                        lbCustomer.Text = "Supplier";
                        cboCustomer.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Supplier where isnull(Deleted,0) <> 1 order by Name");
                        cboCustomer.DisplayMember = "Name";
                        cboCustomer.ValueMember = "ID";
                        cboCustomer.SelectedValue = -1;
                    }
                    break;
                case LocalData.myMenu.Adjustment:
                    break;
                case LocalData.myMenu.Transfer:
                    break;
                case LocalData.myMenu.StockOpening: 
                    break;
                case LocalData.myMenu.Manufacture:
                    break;
                case LocalData.myMenu.StockBalance:
                    break;
                case LocalData.myMenu.AcctOpening:
                case LocalData.myMenu.IncomeExpense:
                    break;
                case LocalData.myMenu.Journal:
                    break;
                case LocalData.myMenu.Exchange:
                    break;
                case LocalData.myMenu.PriceChange:
                    break;
                case LocalData.myMenu.RawIssue:
                case LocalData.myMenu.FinishGoods:
                case LocalData.myMenu.ManufacturerOpening:
                case LocalData.myMenu.ManuSettlement:
                case LocalData.myMenu.ManuBalance:
                case LocalData.myMenu.ReturnStock:
                case LocalData.myMenu.GetStock:
                case LocalData.myMenu.GoodsRecieveManu:
                    if (lbCustomer.Text != "Manufacturer")
                    {
                        lbCustomer.Text = "Manufacturer";
                        cboCustomer.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Manufacturer where isnull(Deleted,0) <> 1 order by Name");
                        cboCustomer.DisplayMember = "Name";
                        cboCustomer.ValueMember = "ID";
                        cboCustomer.SelectedValue = -1;
                    }
                    break;
                default:
                    break;
            }

            if (LocalData.Menu == LocalData.myMenu.AcctOpening || LocalData.Menu == LocalData.myMenu.IncomeExpense || LocalData.Menu == LocalData.myMenu.Journal)
            {
                if (lbBrand.Text != "Account")
                {
                    lbBrand.Text = "Account";
                    cboBrand.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From AccountName where isnull(Deleted,0) <> 1 order by Name");
                    cboBrand.DisplayMember = "Name";
                    cboBrand.ValueMember = "ID";
                    cboBrand.SelectedValue = -1;
                }

            }
            else
            {
                if (lbBrand.Text != "Brand")
                {
                    lbBrand.Text = "Brand";
                    cboBrand.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = 'None' Union All Select ID = 0, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Brand where isnull(Deleted,0) <> 1 order by Name");
                    cboBrand.DisplayMember = "Name";
                    cboBrand.ValueMember = "ID";
                    cboBrand.SelectedValue = 0;

                }

            }
        }

        private void frm_Main_Load(object sender, EventArgs e)
        {
            RightMenuReset();
            dtpFromDate.Value = LocalData.SettingDate;
            dtpToDate.Value = LocalData.SettingDate;

            cboLocation.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cboLocation.DisplayMember = "Name";
            cboLocation.ValueMember = "ID";
            cboLocation.SelectedValue = -1;

            cboPayment.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From PaymentType where isnull(Deleted,0) <> 1 Union All select ID, Name = Short + '-' + Name from AccountName where SysAcctID IN (2,6) and isnull(deleted,0)<>1 order by ID");
            cboPayment.DisplayMember = "Name";
            cboPayment.ValueMember = "ID";
            cboPayment.SelectedValue = -1;

            cboTownship.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Township where isnull(Deleted,0) <> 1 order by Name");
            cboTownship.DisplayMember = "Name";
            cboTownship.ValueMember = "ID";
            cboTownship.SelectedValue = -1;

            cboCustomer.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Customer where isnull(Deleted,0) <> 1 order by Name");
            cboCustomer.DisplayMember = "Name";
            cboCustomer.ValueMember = "ID";
            cboCustomer.SelectedValue = -1;

            cboBrand.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = 'None' Union All Select ID = 0, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Brand where isnull(Deleted,0) <> 1 order by Name");
            cboBrand.DisplayMember = "Name";
            cboBrand.ValueMember = "ID";
            cboBrand.SelectedValue = 0;

            cboTransport.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = 'None' Union All Select ID = 0, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Transport where isnull(Deleted,0) <> 1 order by Name");
            cboTransport.DisplayMember = "Name";
            cboTransport.ValueMember = "ID";
            cboTransport.SelectedValue = 0;

            cboGate.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' All' Union All Select ID,Name = Short + ' - '+ Name From Division where isnull(Deleted,0) <> 1 order by Name");
            cboGate.DisplayMember = "Name";
            cboGate.ValueMember = "ID";
            cboGate.SelectedValue = -1;

            if (LocalData.UserID == 1 || LocalData.UserID == 3)
            {
                pmSetting.Visible = true;
            }
            else
            {
                pmSetting.Visible = false;
            }
            tslbUser.Text = DBConnection.roExecSQL("Select Name From Users Where ID = " + LocalData.UserID.ToString()).ToString();
        }

        private void btSales_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btSales_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btSales_Click(object sender, EventArgs e)
        {
            
        }

        private void btPurchase_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btPurchase_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btStockOpening_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btStockOpening_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btTransfer_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btTransfer_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btAdjustment_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btAdjustment_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btCustStatemet_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btCustStatemet_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btAcctOpening_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btAcctOpening_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btCashBook_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btCashBook_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btJournal_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btJournal_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btSetup_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btSetup_MouseLeave(object sender, EventArgs e)
        {

        }

        private void btReports_MouseEnter(object sender, EventArgs e)
        {

        }

        private void btReports_MouseLeave(object sender, EventArgs e)
        {

        }

        private void pbShowLeftPanel_Click(object sender, EventArgs e)
        {
            show_left_panel = !show_left_panel;
            LeftPanelShowHide();
        }

        private void pmMenu1_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSaleOrder.BackColor = Color.FromArgb(130, 60, 180);
            pmSaleOrder.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.SaleOrder;
            ChangeFilter();
            FillListView();
        }

        private void pmMenu2_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSalesInvoice.BackColor = Color.FromArgb(130, 60, 180);
            pmSalesInvoice.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.Sale;
            ChangeFilter();
            FillListView();

        }

        private void pmMenu3_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSalesReturn.BackColor = Color.FromArgb(130, 60, 180);
            pmSalesReturn.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.SaleReturn;
            ChangeFilter();
            FillListView();
        }

        private void pmSales_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmSales.BackColor = Color.FromArgb(130, 60, 180);
            pmSales.TextColor = Color.White;
            RightMenuReset();

            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,1,1)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSaleOrder, cellPos);
                pmSaleOrder.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,2,1)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSalesInvoice, cellPos);
                pmSalesInvoice.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,3,1)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSalesReturn, cellPos);
                pmSalesReturn.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,33,1)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmGoodsIssue, cellPos);
                pmGoodsIssue.Visible = true;
                i++;
            }

        }

        private void LeftMenuDefault()
        {
            pnHistory.Visible = true;
            foreach (PageMenu pm in tlpLeft.Controls)
            {
                pm.BackColor = Color.Transparent;
                pm.TextColor = Color.Black;
                //pm.Margin.Left = 4;
            }

        }

        private void RightMenuDefault()
        {
            foreach (PageMenu pm in tlpRight.Controls)
            {
                pm.BackColor = Color.Transparent;
                pm.TextColor = Color.Black;
            }
        }
        private void RightMenuReset()
        {
            foreach (PageMenu pm in tlpRight.Controls)
            {
                pm.BackColor = Color.Transparent;
                pm.TextColor = Color.Black;
                pm.Visible = false;
            }
            tlpRight.RowCount = 1;
        }
        private void pmPurchase_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmPurchase.BackColor = Color.FromArgb(130, 60, 180);
            pmPurchase.TextColor = Color.White;
            RightMenuReset();
            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,4,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmPurOrder, cellPos);
                pmPurOrder.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,5,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmPurInvoice, cellPos);
                pmPurInvoice.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,6,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmShipment, cellPos);
                pmShipment.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,7,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmPurReturn, cellPos);
                pmPurReturn.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,32,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmReturnReceive, cellPos);
                pmReturnReceive.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,34,2)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmGoodsReceive, cellPos);
                pmGoodsReceive.Visible = true;
                i++;
            }


        }

        private void pmTransfer_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmTransfer.BackColor = Color.FromArgb(130, 60, 180);
            pmTransfer.TextColor = Color.White;
            RightMenuReset();
            LocalData.Menu = LocalData.myMenu.Transfer;
            FillListView();
        }

        private void pmAdjustment_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmAdjustment.BackColor = Color.FromArgb(130, 60, 180);
            pmAdjustment.TextColor = Color.White;
            RightMenuReset();
            LocalData.Menu = LocalData.myMenu.Adjustment;
            FillListView();
        }

        private void pmManufacture_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmManufacture.BackColor = Color.FromArgb(130, 60, 180);
            pmManufacture.TextColor = Color.White;

            RightMenuReset();
            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,24,5)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmRawIssue, cellPos);
                pmRawIssue.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,25,5)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmFinishGoods, cellPos);
                pmFinishGoods.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,30,5)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmStockReturn, cellPos);
                pmStockReturn.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,31,5)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmStockGet, cellPos);
                pmStockGet.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,35,5)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmGoodsReceiveManu, cellPos);
                pmGoodsReceiveManu.Visible = true;
                i++;
            }

        }

        private void pmPriceChange_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmPriceChange.BackColor = Color.FromArgb(130, 60, 180);
            pmPriceChange.TextColor = Color.White;
        }

        private void pmBalance_MouseMove(object sender, MouseEventArgs e)
        {

        }

        private void pmOpening_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustomerOpening;
            FillListView();

            RightMenuReset();
            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,11,8)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmCustomerOpening, cellPos);
                pmCustomerOpening.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,12,8)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSupOpening, cellPos);
                pmSupOpening.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,13,8)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmManuOpening, cellPos);
                pmManuOpening.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,19,8)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmAcctOpening, cellPos);
                pmAcctOpening.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,10,8)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmStockOpening, cellPos);
                pmStockOpening.Visible = true;
                i++;
            }

        }

        private void pmIncome_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmIncome.BackColor = Color.FromArgb(130, 60, 180);
            pmIncome.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.IncomeExpense;
            FillListView();

            RightMenuReset();
            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,14,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmCustPayment, cellPos);
                pmCustPayment.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,15,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSupplier, cellPos);
                pmSupplier.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,16,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmManufacturer, cellPos);
                pmManufacturer.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,20,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmCashbook, cellPos);
                pmCashbook.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,21,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmJrnl, cellPos);
                pmJrnl.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,29,9)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmCustSup, cellPos);
                pmCustSup.Visible = true;
                i++;
            }
            //tlpRight.SetColumn(pmShipment, 1);
            //pmShipment.Visible = true;
            //tlpRight.SetColumn(pmPurInvoice, 2);
            //pmPurInvoice.Visible = true;
            //tlpRight.SetColumn(pmPurReturn, 3);
            //pmPurReturn.Visible = true;

        }

        private void pmJournal_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmSetting.BackColor = Color.FromArgb(130, 60, 180);
            pmSetting.TextColor = Color.White;
        }

        private void pmExchange_MouseSelected(object sender, EventArgs e)
        {
            //LeftMenuDefault();
            //pmExchange.BackColor = Color.FromArgb(130, 60, 180);
            //pmExchange.TextColor = Color.White;
        }

        private void pmSettlement_MouseSelected(object sender, EventArgs e)
        {
            //LeftMenuDefault();
            //pmSettlement.BackColor = Color.FromArgb(130, 60, 180);
            //pmSettlement.TextColor = Color.White;
        }

        private void pmReports_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmReports.BackColor = Color.FromArgb(130, 60, 180);
            pmReports.TextColor = Color.White;
            frm = new frm_Reports();
            frm.ShowDialog();
        }

        private void pmSetup_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmSetup.BackColor = Color.FromArgb(130, 60, 180);
            pmSetup.TextColor = Color.White;
            frm = new frm_Setup();
            frm.ShowDialog();
        }

        private void pmBalance_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmBalance.BackColor = Color.FromArgb(130, 60, 180);
            pmBalance.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustBalance;
            Transaction.MinAmount = 0;
            Transaction.MaxAmount = 0;
            FillListView();

            RightMenuReset();
            int i = 0;
            TableLayoutPanelCellPosition cellPos;
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,26,7)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmCustOutstand, cellPos);
                pmCustOutstand.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,27,7)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmSupOutstand, cellPos);
                pmSupOutstand.Visible = true;
                i++;
            }
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserRights(" + LocalData.UserID.ToString() + ",2,28,7)").ToString(), out allow);
            if (allow)
            {
                cellPos = new TableLayoutPanelCellPosition(i, 0);
                tlpRight.SetCellPosition(pmManuBalance, cellPos);
                pmManuBalance.Visible = true;
                i++;
            }
        }

        private void pmSales_Load(object sender, EventArgs e)
        {

        }

        private void cmsNew_Click(object sender, EventArgs e)
        {

            switch (LocalData.Menu)
            {
                case LocalData.myMenu.SaleOrder:
                case LocalData.myMenu.Sale:
                case LocalData.myMenu.SaleReturn:
                    frm = new frm_SalesOrder(0);
                    break;
                case LocalData.myMenu.PurchaseOrder:
                case LocalData.myMenu.Purchase:
                case LocalData.myMenu.PurchaseReturn:
                case LocalData.myMenu.Receive:
                case LocalData.myMenu.ReturnReceive:
                case LocalData.myMenu.GoodsReceive:
                    frm = new frm_Purchasecs(0);
                    break;
                case LocalData.myMenu.Adjustment:
                case LocalData.myMenu.Transfer:
                    frm = new frm_Transfer(0);
                    break;
                case LocalData.myMenu.StockOpening:
                case LocalData.myMenu.CustomerOpening:
                case LocalData.myMenu.SupplierOpening:
                case LocalData.myMenu.ManufacturerOpening:
                    frm = new frm_CustOpening(0);
                    break;
                case LocalData.myMenu.CustSettlement:
                case LocalData.myMenu.SupSettlement:
                case LocalData.myMenu.ManuSettlement:
                case LocalData.myMenu.IncomeExpense:
                case LocalData.myMenu.Journal:
                    frm = new frm_IncomeExpense(0);
                    break;
                case LocalData.myMenu.Manufacture:
                    break;
                case LocalData.myMenu.StockBalance:
                    break;
                case LocalData.myMenu.AcctOpening:
                    frm = new frm_AcctOpening(0);
                    break;
                case LocalData.myMenu.Exchange:
                    break;
                case LocalData.myMenu.PriceChange:
                    break;
                case LocalData.myMenu.RawIssue:
                case LocalData.myMenu.FinishGoods:
                case LocalData.myMenu.ReturnStock:
                case LocalData.myMenu.GetStock:
                case LocalData.myMenu.GoodsRecieveManu:
                    frm = new frm_Manufacture(0);
                    break;
                case LocalData.myMenu.CustSup:
                    frm = new frm_CustSupTransfer(0);
                    break;
                default:
                    break;
            }

            frm.ShowDialog();
        }

        private void pmPurOrder_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmPurOrder.BackColor = Color.FromArgb(130, 60, 180);
            pmPurOrder.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.PurchaseOrder;
            ChangeFilter();
            FillListView();
        }

        private void pmShipment_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmShipment.BackColor = Color.FromArgb(130, 60, 180);
            pmShipment.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.Receive;
            ChangeFilter();
            FillListView();
        }

        private void pmPurReturn_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmPurReturn.BackColor = Color.FromArgb(130, 60, 180);
            pmPurReturn.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.PurchaseReturn;
            ChangeFilter();
            FillListView();
        }

        private void pmPurInvoice_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmPurInvoice.BackColor = Color.FromArgb(130, 60, 180);
            pmPurInvoice.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.Purchase;
            ChangeFilter();
            FillListView();
        }

        private void frm_Main_FormClosing(object sender, FormClosingEventArgs e)
        {

        }

        private void frm_Main_FormClosed(object sender, FormClosedEventArgs e)
        {
            DBConnection.ExecSQL("Delete UserStatus Where UserID = " + LocalData.UserID.ToString()); ;
            Application.Exit();
        }

        private void GetFilter()
        {
            LocalData.FromDate = dtpFromDate.Value;
            LocalData.ToDate = dtpToDate.Value;



            if ((Int32)cboLocation.SelectedValue != -1)
            {
                LocalData.LocationID = (Int32)cboLocation.SelectedValue;
            }
            else
            {
                LocalData.LocationID = -1;
            }


            if ((Int32)cboPayment.SelectedValue != -1)
            {
                LocalData.PaymentID = (Int32)cboPayment.SelectedValue;
            }
            else
            {
                LocalData.PaymentID = -1;
            }


            if ((Int32)cboTownship.SelectedValue != -1)
            {
                LocalData.CustGroupID = (Int32)cboTownship.SelectedValue;
            }
            else
            {
                LocalData.CustGroupID = -1;
            }



            if ((Int32)cboCustomer.SelectedValue != -1)
            {
                LocalData.CustomerID = (Int32)cboCustomer.SelectedValue;
            }
            else
            {

                LocalData.CustomerID = -1;
            }

            if ((Int32)cboBrand.SelectedValue != 0)
            {
                LocalData.BrandID = (Int32)cboBrand.SelectedValue;
            }
            else
            {
                LocalData.BrandID = 0;
            }
            if (tbCode.Text != "")
            {
                LocalData.Code = "'%" + tbCode.Text.ToString() + "%'";
            }
            else
            {
                LocalData.Code = "'%'";
            }

            if ((Int32)cboTransport.SelectedValue != 0)
            {
                LocalData.TransportID = (Int32)cboTransport.SelectedValue;
            }
            else
            {
                LocalData.TransportID = 0;
            }
            if ((Int32)cboTownship.SelectedValue != 0)
            {
                LocalData.TownshipID = (Int32)cboTownship.SelectedValue;
            }
            else
            {
                LocalData.TownshipID = 0;
            }
            if ((Int32)cboGate.SelectedValue != 0)
            {
                LocalData.CarID = (Int32)cboGate.SelectedValue;
            }
            else
            {
                LocalData.CarID = 0;
            }

            //if ((Int32)cboCode.SelectedValue != -1)
            //{
            //    LocalData.CodeID = (Int32)cboCode.SelectedValue;
            //}
            //else
            //{
            //    LocalData.CodeID = -1;
            //}

            //if (tbDocumentID.Text != "")
            //{
            //    LocalData.DocumentID = "%" + tbDocumentID.Text.ToString() + "%";
            //}
            //else
            //{
            //    LocalData.DocumentID = "%";
            //}


            //if (tbAutoID.Text != "")
            //{
            //    LocalData.AutoID = "%" + tbAutoID.Text.ToString() + "%";
            //}
            //else
            //{
            //    LocalData.AutoID = "%";
            //}
        }
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.F1)
            {
                //if (dgvDetail.IsCurrentCellInEditMode)
                //{
                //    if (dgvDetail.CurrentCell.ColumnIndex == 4)
                //    {
                //        frm = new frm_CodeList(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
                //        if (frm.ShowDialog() == DialogResult.OK)
                //        {
                //            int i;
                //            int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + frm_CodeList.CodeID.ToString()).ToString(), out i);
                //            dgvDetail.EndEdit();
                //            dgvDetail.CurrentRow.Cells["CodeID"].Value = frm_CodeList.CodeID;
                //            dgvDetail.CurrentRow.Cells["Code"].Value = frm_CodeList.Code;
                //            dgvDetail.CurrentRow.Cells["Name"].Value = frm_CodeList.Description;
                //            dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
                //            //dgvDetail.CurrentRow.Cells["Price"].Value = frm_CodeList.SalePrice;
                //            dgvDetail.CurrentRow.Cells["Unit"].Value = i;
                //            //dgvDetail.CurrentRow.Cells["PrintCharge"].Value = frm_CodeList.Print;
                //            //dgvDetail.CurrentRow.Cells["Weight"].Value = frm_CodeList.Weight;
                //            dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Brand"];
                //        }

                //    }

                //}

                return true;    // indicate that you handled this keystroke
            }
            else if (keyData == Keys.Enter)
            {
                SendKeys.Send("{TAB}");
                return true;
            }
            else if (keyData == Keys.F2)
            {

                return true;
            }
            else if (keyData == Keys.F10)
            {
                if (LocalData.Menu == LocalData.myMenu.CustBalance || LocalData.Menu == LocalData.myMenu.SupBalance || LocalData.Menu == LocalData.myMenu.ManuBalance)
                {
                    frm = new frm_Amount();
                    if (frm.ShowDialog() == DialogResult.OK)
                    {
                        FillListView();
                    }
                }

                return true;
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }
        private void FillListView()
        {
            LocalData.FromDate = dtpFromDate.Value;
            LocalData.ToDate = dtpToDate.Value;

            string m_name, st_group, st_detail, gcol, gtable, gwh, dcol, dtable, dwh, wh1, wh2;
            int count = 0;
            ListViewItem lvitem;
            ColumnHeader header;

            DataTable dt, dtcol;
            int col_count, col_width, width;

            m_name = string.Empty;
            st_group = string.Empty;
            st_detail = string.Empty;
            gcol = string.Empty;
            gtable = string.Empty;
            gwh = string.Empty;
            dcol = string.Empty;
            dtable = string.Empty;
            dwh = string.Empty;
            wh1 = string.Empty;
            wh2 = string.Empty;


            this.Cursor = Cursors.WaitCursor;
            try
            {
            BeginHistoryLoadProgress();
            dwh = " 1 = 1";
            GetFilter();

            int TempUserID;
            if (LocalData.AllowAll)
            {
                TempUserID = 0;
            }
            else
            {
                TempUserID = LocalData.UserID;
            }
            tssbBalance.Visible = false;
            switch (LocalData.Menu)
            {
                case LocalData.myMenu.SaleOrder:
                    m_name = "SaleOrder";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Customer, Remark, FAmount = cast(Amount as numeric), Amount, Printed ";
                    dtable = "dbo.SaleOrderHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() +"  )";
                    //dwh = dwh + "And  DocumentID Like N'" + LocalData.DocumentID.ToString() + "' And AutoID Like  N'" + LocalData.AutoID.ToString() + "' ";
                    break;
                case LocalData.myMenu.Sale:
                    m_name = "Sales";
                    dcol = "ID, Date, AutoID, Township,  DocumentID, Location, Customer, PK, Payment, Transport, Car, Remark, PaidAmount = cast(Paid as numeric), Charges = cast(isnull(Charges,0) as numeric), FAmount = cast(Amount as numeric), Amount, Printed, PanSar ";
                    dtable = "dbo.SaleHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + ","+ LocalData.CustGroupID.ToString()+","+ LocalData.CustomerID.ToString()+", "+LocalData.PaymentID.ToString()+"," + LocalData.Code.ToString() + ","+LocalData.BrandID.ToString()+ "," + LocalData.TransportID + "," + LocalData.CarID+ "  )";
                    //dwh = dwh + "And  DocumentID Like N'" + LocalData.DocumentID.ToString() + "' And AutoID Like  N'" + LocalData.AutoID.ToString() + "' ";
                    break;
                case LocalData.myMenu.SaleReturn:
                    m_name = "SaleReturn";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Customer, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.SaleReturnHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.PurchaseOrder:
                    m_name = "PurOrder";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Supplier, Remark, Printed,  FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.PurchaseOrderHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Purchase:
                    m_name = "Purchase";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, StockReceived, Location, Supplier, PK, Payment, Remark, PaidAmount = cast(Paid as numeric), FAmount = FORMAT(Amount, '#,###'), Amount, Currency, ExgRate ";
                    dtable = "dbo.PurchaseHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Receive:
                    m_name = "Receive";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Supplier, PK, Remark ";
                    dtable = "dbo.StockReceiveHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.PurchaseReturn:
                    m_name = "PurReturn";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Supplier, Payment, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.PurchaseReturnHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.ReturnReceive:
                    m_name = "PurReturn";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Supplier, Payment, Remark, Printed = 0, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.ReturnReceiveHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.GoodsReceive:
                    m_name = "Purchase";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, StockReceived, Location, Supplier, PK, Payment, Remark, PaidAmount = cast(Paid as numeric), FAmount = FORMAT(Amount, '#,###'), Amount, Currency, ExgRate ";
                    dtable = "dbo.PurchaseHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Adjustment:
                    m_name = "Adjust";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.AdjustmentHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Transfer:
                    m_name = "Transfer";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, FromLocation, ToLocation, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.TransferHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.StockOpening:
                    m_name = "StockOpen";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location,  Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.StockOpeningHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() +  "," + LocalData.Code.ToString()+ "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.CustomerOpening:
                    m_name = "CustOpen";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.CustOpeningHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.SupplierOpening:
                    m_name = "SupOpen";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.SupOpeningHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.ManufacturerOpening:
                    m_name = "ManuOpen";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.ManuOpeningHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.CustSettlement:
                    m_name = "CashBook";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, CashbookType, Account, Remark, FAmount = FORMAT(TotalIncome, '#,###'), TotalIncome, FAmount1 = FORMAT(TotalExpense, '#,###'), TotalExpense ";
                    dtable = "dbo.CashbookHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', 3,"+ LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.SupSettlement:
                    m_name = "SupSettle";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, CashbookType, Account, Remark, Currency, ExgRate, FAmount = FORMAT(TotalIncome, '#,###'), TotalIncome, FAmount1 = FORMAT(TotalExpense, '#,###'), TotalExpense ";
                    dtable = "dbo.CashbookHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', 4," + LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.ManuSettlement:
                    m_name = "CashBook";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, CashbookType, Account, Remark, FAmount = FORMAT(TotalIncome, '#,###'), TotalIncome, FAmount1 = FORMAT(TotalExpense, '#,###'), TotalExpense ";
                    dtable = "dbo.CashbookHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', 5," + LocalData.CustomerID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Journal:
                    m_name = "CashBook";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, CashbookType, Account = '', Remark, FAmount = FORMAT(TotalIncome, '#,###'), TotalIncome, FAmount1 = FORMAT(TotalExpense, '#,###'), TotalExpense ";
                    dtable = "dbo.CashbookHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', 2,"+LocalData.BrandID.ToString()+")";
                    break;
                case LocalData.myMenu.IncomeExpense:
                    m_name = "SupSettle";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, CashbookType, Account, Remark, Currency, ExgRate, FAmount = FORMAT(TotalIncome, '#,###'), TotalIncome, FAmount1 = FORMAT(TotalExpense, '#,###'), TotalExpense ";
                    dtable = "dbo.CashbookHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', 1," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.Manufacture:
                    break;
                case LocalData.myMenu.StockBalance:
                    break;
                case LocalData.myMenu.AcctOpening:
                    m_name = "AcctOpen";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Remark, FAmount = FORMAT(TotalDebit, '#,###'), TotalDebit, FAmount1 = FORMAT(TotalCredit, '#,###'), TotalCredit ";
                    dtable = "dbo.AccountOpeningHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', -1  )";
                    break;
                case LocalData.myMenu.Exchange:
                    break;
                case LocalData.myMenu.PriceChange:
                    break;
                case LocalData.myMenu.RawIssue:
                    m_name = "Raw";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Manufacturer, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.RawHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.FinishGoods:
                    m_name = "Raw";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Manufacturer, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.FinishGoodsHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.GoodsRecieveManu:
                    m_name = "FinishGood";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Manufacturer, PK, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.FinishGoodsHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.ReturnStock:
                    m_name = "ReturnGet";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Manufacturer, Printed, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.ReturnStockHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.GetStock:
                    m_name = "ReturnGet";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, Location, Manufacturer, Printed, Remark, FAmount = FORMAT(Amount, '#,###'), Amount ";
                    dtable = "dbo.GetStockHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "'," + LocalData.LocationID.ToString() + "," + LocalData.CustGroupID.ToString() + "," + LocalData.CustomerID.ToString() + ", " + LocalData.PaymentID.ToString() + "," + LocalData.Code.ToString() + "," + LocalData.BrandID.ToString() + "  )";
                    break;
                case LocalData.myMenu.CustBalance:
                    tssbBalance.Visible = true;
                    SqlParameter[] CBarg = new SqlParameter[6];
                    CBarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); CBarg[0].Value = LocalData.FromDate.ToString("yyyy-MM-dd");
                    CBarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); CBarg[1].Value = LocalData.ToDate.ToString("yyyy-MM-dd");
                    CBarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); CBarg[2].Value = "";
                    CBarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); CBarg[3].Value = LocalData.TownshipID <= 0 ? "": LocalData.TownshipID.ToString();
                    CBarg[4] = new SqlParameter("@Customer", SqlDbType.NVarChar); CBarg[4].Value = LocalData.CustomerID <= 0 ? "" : LocalData.CustomerID.ToString();
                    CBarg[5] = new SqlParameter("@UserID", SqlDbType.Int); CBarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("CustomerOutstand", CBarg);

                    if (CustAging != "")
                    {
                        SqlParameter[] UCA = new SqlParameter[1];
                        UCA[0] = new SqlParameter("@UserID", SqlDbType.Int); UCA[0].Value = LocalData.UserID;

                        DBConnection.ExecSp("UpdateCustomerAging", UCA);
                    }

                    m_name = "CustOutstand";
                    dcol = "ID = 1, Short, LedgerName, Opening = FORMAT(Opening, '#,###'), Sales = FORMAT(Sales, '#,###'), SaleReturn = FORMAT(SaleReturn, '#,###'), Payment = FORMAT(Payment, '#,###'), AcctTransfer = FORMAT(AcctTransfer, '#,###'),  Closing = cast(Closing as money), FClosing = Closing ";
                    dtable = "dbo.CustomerOutstandHistory(" + LocalData.UserID.ToString() + ")";
                    if (Transaction.MinAmount != 0 || Transaction.MaxAmount !=0)
                    {
                        dwh = dwh + " and Closing Between " + Transaction.MinAmount + " and " + Transaction.MaxAmount;

                    }
                    if (HideZero)
                    {
                        dwh = dwh + " and isnull(Closing,0)<> 0 ";
                    }
                    if (CustAging == "ToDay")
                    {
                        dwh = dwh + " and GroupID = 1";
                    }
                    else if (CustAging == "OneWeek")
                    {
                        dwh = dwh + " and GroupID = 2";
                    }
                    else if (CustAging == "TwoWeek")
                    {
                        dwh = dwh + " and GroupID = 3";
                    }
                    else if (CustAging == "OneMonth")
                    {
                        dwh = dwh + " and GroupID = 4";
                    }
                    else if (CustAging == "OverDate")
                    {
                        dwh = dwh + " and GroupID = 5";
                    }
                    break;
                case LocalData.myMenu.SupBalance:
                    tssbBalance.Visible = true;
                    SqlParameter[] SBarg = new SqlParameter[6];
                    SBarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); SBarg[0].Value = LocalData.FromDate.ToString("yyyy-MM-dd");
                    SBarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); SBarg[1].Value = LocalData.ToDate.ToString("yyyy-MM-dd");
                    SBarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); SBarg[2].Value = "";
                    SBarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); SBarg[3].Value = LocalData.TownshipID<=0 ? "" : LocalData.TownshipID.ToString();
                    SBarg[4] = new SqlParameter("@Supplier", SqlDbType.NVarChar); SBarg[4].Value = LocalData.CustomerID<=0 ? "" : LocalData.CustomerID.ToString();
                    SBarg[5] = new SqlParameter("@UserID", SqlDbType.Int); SBarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("SupplierOutstand", SBarg);

                    m_name = "SupOutstand";
                    dcol = "ID = 1, LedgerName, Opening = FORMAT(Opening, '#,###'), Purchase = FORMAT(Purchase, '#,###'), PurchaseReturn = FORMAT(PurchaseReturn, '#,###'), Payment = FORMAT(Payment, '#,###'), AcctTransfer = FORMAT(AcctTransfer, '#,###'),  Closing = cast(Closing as Money), FClosing = Closing ";
                    dtable = "dbo.SupplierOutstandHistory(" + LocalData.UserID.ToString() + ")";
                    if (Transaction.MinAmount != 0 || Transaction.MinAmount != 0)
                    {
                        dwh = dwh + " and Closing Between " + Transaction.MinAmount + " and " + Transaction.MaxAmount;

                    }
                    if (HideZero)
                    {
                        dwh = dwh + " and isnull(Closing,0) <> 0 ";
                    }
                    break;
                case LocalData.myMenu.ManuBalance:
                    tssbBalance.Visible = true;
                    SqlParameter[] MBarg = new SqlParameter[6];
                    MBarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); MBarg[0].Value = LocalData.FromDate.ToString("yyyy-MM-dd");
                    MBarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); MBarg[1].Value = LocalData.ToDate.ToString("yyyy-MM-dd");
                    MBarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); MBarg[2].Value = "";
                    MBarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); MBarg[3].Value = LocalData.TownshipID <=0 ? "" : LocalData.TownshipID.ToString();
                    MBarg[4] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); MBarg[4].Value = LocalData.CustomerID <= 0 ? "" : LocalData.CustomerID.ToString();
                    MBarg[5] = new SqlParameter("@UserID", SqlDbType.Int); MBarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("ManufacturerOutstand", MBarg);

                    m_name = "ManuOutstand";
                    dcol = "ID = 1, LedgerName, Opening = FORMAT(Opening, '#,###'), FinishedGood = FORMAT(FinishedGood, '#,###'),  Payment = FORMAT(Payment, '#,###'), AcctTransfer = FORMAT(AcctTransfer, '#,###'),  Closing = cast(Closing as money), FClosing = Closing ";
                    dtable = "dbo.ManufacturerOutstandHistory(" + LocalData.UserID.ToString() + ")";
                    if (Transaction.MinAmount != 0 || Transaction.MinAmount != 0)
                    {
                        dwh = dwh + " and Closing Between " + Transaction.MinAmount + " and " + Transaction.MaxAmount;

                    }
                    if (HideZero)
                    {
                        dwh = dwh + " and isnull(Closing,0) <> 0 ";
                    }
                    break;
                case LocalData.myMenu.CustSup:
                    m_name = "CustSup";
                    dcol = "ID, Date = Format(Date,'dd/MM/yyyy'), AutoID,  DocumentID, FromAcct,  FromName, ToAcct, ToName, Remark, Amount, FAmount = FORMAT(Amount, '#,###') ";
                    dtable = "dbo.CustSupHistory(" + TempUserID.ToString() + ",'" + LocalData.FromDate.ToString("yyyy-MM-dd") + "','" + LocalData.ToDate.ToString("yyyy-MM-dd") + "', -1, -1, -1  )";
                    break;
                default:
                    break;
            }

            
            //st_group = string.Format("Select Date From {0} Where isnull(deleted,0)<> 1 and {1} group by date", gtable, gwh);
            st_detail = string.Format("Select {0} From {1} Where {2} order by ID", dcol, dtable, dwh);
            //dt = new DataTable();
            //dt = DBConnection.GetSQLTable("Select ColumnHeader, ColumnWidth From ListviewItem Where MenuName = '" + m_name + "' and ColumnName <> 'ID' ");
            //col_count = dt.Rows.Count;
            //col_width = (lvHistory.Width - 500) / col_count;

            //foreach (DataRow drow in dt.Rows)
            //{
            //    //header = new ColumnHeader();
            //    //header.Text = drow["ColumnHeader"].ToString();
            //    //int.TryParse(drow["ColumnWidth"].ToString(), out width);
            //    //header.Width = col_width + width;
            //    //lvHistory.Columns.Add(header);
            //}

            dt = new DataTable();
            DataColumn AutoNumberColumn = new DataColumn();
            AutoNumberColumn.ColumnName = "Sr";
            AutoNumberColumn.DataType = typeof(int);
            AutoNumberColumn.AutoIncrement = true;
            AutoNumberColumn.AutoIncrementSeed = 1;
            AutoNumberColumn.AutoIncrementStep = 1;
            dt.Columns.Add(AutoNumberColumn);
            DateTime date;
            decimal amount;
            try
            {
                SqlDataAdapter adp = new SqlDataAdapter(st_detail, DBConnection.ActiveConnection);
                adp.Fill(dt);
            }
            catch (Exception)
            {
                // SaleHistory may not expose Charges yet — retry without it and add blank column for footer.
                if (LocalData.Menu == LocalData.myMenu.Sale && dcol.Contains("Charges ="))
                {
                    dcol = dcol.Replace("Charges = cast(isnull(Charges,0) as numeric), ", "");
                    st_detail = string.Format("Select {0} From {1} Where {2} order by ID", dcol, dtable, dwh);
                    dt = new DataTable();
                    DataColumn srCol = new DataColumn("Sr", typeof(int));
                    srCol.AutoIncrement = true;
                    srCol.AutoIncrementSeed = 1;
                    srCol.AutoIncrementStep = 1;
                    dt.Columns.Add(srCol);
                    SqlDataAdapter adp2 = new SqlDataAdapter(st_detail, DBConnection.ActiveConnection);
                    adp2.Fill(dt);
                    if (!dt.Columns.Contains("Charges"))
                    {
                        DataColumn chg = new DataColumn("Charges", typeof(decimal));
                        chg.DefaultValue = 0m;
                        dt.Columns.Add(chg);
                    }
                }
                else
                    throw;
            }
            //dt = DBConnection.GetSQLTable(st_detail);

            ShowTotalAmount(dt);

            dlvHistory.Clear();
            dlvHistory.AllColumns.Clear();
            dlvHistory.DataSource = dt;
            dlvHistory.View = View.Details;
            dlvHistory.Columns["Sr"].Width = 50;
            dlvHistory.HeaderFont = new System.Drawing.Font("Pyidaungsu", 13F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            //dlvHistory.HeaderFormatStyle.SetBackColor(Color.FromArgb(130, 60, 180));
            //dlvHistory.HeaderFormatStyle.SetForeColor(Color.White);

            dtcol = DBConnection.GetSQLTable("Select ColumnName, ColumnWidth, ColumnHeader From ListviewItem Where MenuName = '" + m_name + "'");
            foreach (DataRow crow in dtcol.Rows)
            {
                string colName = crow["ColumnName"].ToString();
                if (dlvHistory.Columns[colName] == null)
                    continue;
                dlvHistory.Columns[colName].Width = (int)crow["ColumnWidth"];
                dlvHistory.Columns[colName].Text = crow["ColumnHeader"].ToString();
                if (crow["ColumnName"].ToString() == "FAmount")
                {
                    decimal amt;
                    dlvHistory.Columns[crow["ColumnName"].ToString()].TextAlign = HorizontalAlignment.Right;
                     
                    
                }
                else if (crow["ColumnName"].ToString() == "IncomeAmount")
                {
                    decimal Inamt;
                    dlvHistory.Columns[crow["ColumnName"].ToString()].TextAlign = HorizontalAlignment.Right;
                    
                }
                else if (crow["ColumnName"].ToString() == "ExpenseAmount")
                {

                    dlvHistory.Columns[crow["ColumnName"].ToString()].TextAlign = HorizontalAlignment.Right;
                }
                else if (crow["ColumnName"].ToString() == "Charges" || crow["ColumnName"].ToString() == "PaidAmount")
                {
                    dlvHistory.Columns[crow["ColumnName"].ToString()].TextAlign = HorizontalAlignment.Right;
                }
                else if (crow["ColumnHeader"].ToString() == "Opening" || crow["ColumnHeader"].ToString() == "Sales" || crow["ColumnHeader"].ToString() == "Purchase" || crow["ColumnHeader"].ToString() == "ကုန်ချောယူ"  || crow["ColumnHeader"].ToString() == "Return" || crow["ColumnHeader"].ToString() == "Payment" || crow["ColumnHeader"].ToString() == "Acct Transfer" || crow["ColumnHeader"].ToString() == "Balance")
                {

                    dlvHistory.Columns[crow["ColumnName"].ToString()].TextAlign = HorizontalAlignment.Right;
       
                }

            }

            // Ensure Bank Charges column is labeled even if ListviewItem row missing
            if (dt.Columns.Contains("Charges") && dlvHistory.Columns["Charges"] != null)
            {
                if (string.IsNullOrWhiteSpace(dlvHistory.Columns["Charges"].Text) ||
                    dlvHistory.Columns["Charges"].Text == "Charges")
                    dlvHistory.Columns["Charges"].Text = "Bank Charges";
                if (dlvHistory.Columns["Charges"].Width < 90)
                    dlvHistory.Columns["Charges"].Width = 110;
                dlvHistory.Columns["Charges"].TextAlign = HorizontalAlignment.Right;
            }

            // FAmount is the visible Amount; keep raw Amount only for footer Sum(Amount)
            HideHistoryHelperColumns();

            FitHistoryColumnsToView();
            ApplySalesHistoryColumnWidths();
            KeepHistorySelectionMode();
            LayoutHistoryStatusSummary();
            }
            finally
            {
                EndHistoryLoadProgress();
                this.Cursor = Cursors.Default;
            }
        }

        /// <summary>Hide internal columns that duplicate visible ones (Amount vs FAmount, etc.).</summary>
        private void HideHistoryHelperColumns()
        {
            if (dlvHistory == null)
                return;

            if (dlvHistory.Columns["ID"] != null)
                dlvHistory.Columns["ID"].Width = 0;

            // FAmount is display Amount; raw Amount is only for footer Sum(Amount)
            if (dlvHistory.Columns["FAmount"] != null && dlvHistory.Columns["Amount"] != null)
                dlvHistory.Columns["Amount"].Width = 0;

            if (dlvHistory.Columns["FAmount"] != null)
            {
                if (string.IsNullOrWhiteSpace(dlvHistory.Columns["FAmount"].Text) ||
                    dlvHistory.Columns["FAmount"].Text == "FAmount")
                    dlvHistory.Columns["FAmount"].Text = "Amount";
            }
        }

        /// <summary>Sales: Charges stays visible, Car/Discount stay narrow, visible Amount (FAmount) is not scaled away.</summary>
        private void ApplySalesHistoryColumnWidths()
        {
            if (dlvHistory == null || LocalData.Menu != LocalData.myMenu.Sale)
                return;
            SetHistoryColumnWidth("Car", 55);
            if (dlvHistory.Columns["Discount"] != null)
                SetHistoryColumnWidth("Discount", 70);
            if (dlvHistory.Columns["Charges"] != null)
            {
                if (dlvHistory.Columns["Charges"].Width < 90)
                    SetHistoryColumnWidth("Charges", 90);
                dlvHistory.Columns["Charges"].TextAlign = HorizontalAlignment.Right;
            }
            if (dlvHistory.Columns["FAmount"] != null && dlvHistory.Columns["FAmount"].Width < 110)
                SetHistoryColumnWidth("FAmount", 110);
        }

        private void SetHistoryColumnWidth(string columnName, int width)
        {
            if (dlvHistory.Columns[columnName] == null)
                return;
            dlvHistory.Columns[columnName].Width = width;
        }

        /// <summary>Scale column widths so all Sales/history columns fit without horizontal clip when possible.</summary>
        private void FitHistoryColumnsToView()
        {
            if (dlvHistory == null || dlvHistory.Columns.Count == 0)
                return;
            int avail = dlvHistory.ClientSize.Width - SystemInformation.VerticalScrollBarWidth - 6;
            if (avail < 200)
                return;
            int total = 0;
            for (int i = 0; i < dlvHistory.Columns.Count; i++)
            {
                if (dlvHistory.Columns[i].Width <= 0)
                    continue;
                total += dlvHistory.Columns[i].Width;
            }
            if (total <= 0 || total <= avail)
                return;
            double scale = (double)avail / total;
            for (int i = 0; i < dlvHistory.Columns.Count; i++)
            {
                if (dlvHistory.Columns[i].Width <= 0)
                    continue;
                int minW = (dlvHistory.Columns[i].Text == "Sr") ? 40 : 55;
                dlvHistory.Columns[i].Width = Math.Max(minW, (int)(dlvHistory.Columns[i].Width * scale));
            }
        }

        /// <summary>Keep PK / Paid / Bank Charges / Total Amount visible on the status strip.</summary>
        private void LayoutHistoryStatusSummary()
        {
            if (statusStrip1 == null)
                return;
            statusStrip1.SizingGrip = false;
            if (tssLeft != null)
            {
                tssLeft.Spring = true;
                tssLeft.AutoSize = false;
                tssLeft.Text = string.Empty;
            }
            if (toolStripStatusLabel3 != null)
            {
                toolStripStatusLabel3.Spring = true;
                toolStripStatusLabel3.AutoSize = false;
                toolStripStatusLabel3.Text = string.Empty;
            }
            if (tsLablePK != null)
                tsLablePK.AutoSize = true;
            if (tsLabelPaid != null)
                tsLabelPaid.AutoSize = true;
            if (tsLabelBankCharges != null)
                tsLabelBankCharges.AutoSize = true;
            if (tslbMachine != null)
            {
                tslbMachine.AutoSize = true;
                tslbMachine.RightToLeft = RightToLeft.No;
            }
        }

        private void ShowTotalAmount(DataTable dt)
        {
            decimal TotalAmount, Paid;
            int pk;
            //if (dt.Rows.Count > 0 && LocalData.Menu == LocalData.myMenu.Sale)
            //{
            //    decimal.TryParse(dt.Compute("Sum(Amount)", "").ToString(), out TotalAmount);
            //    tslbMachine.Text = "Total Amount : " + TotalAmount.ToString("#,##0");

            //    decimal.TryParse(dt.Compute("Sum(PaidAmount)", "").ToString(), out Paid);
            //    tsLabelPaid.Text = "Paid Amount : " + Paid.ToString("#,##0");
            //}
            tslbMachine.Visible = false;
            tsLabelPaid.Visible = false;
            tsLablePK.Visible = false;
            if (tsLabelBankCharges != null)
                tsLabelBankCharges.Visible = false;
            switch (LocalData.Menu)
            {
                case LocalData.myMenu.SaleOrder:
                case LocalData.myMenu.Sale:
                case LocalData.myMenu.SaleReturn:
                case LocalData.myMenu.PurchaseOrder:
                case LocalData.myMenu.Purchase:
                case LocalData.myMenu.PurchaseReturn:
                case LocalData.myMenu.ReturnReceive:
                case LocalData.myMenu.GoodsReceive:
                case LocalData.myMenu.Adjustment:
                case LocalData.myMenu.Transfer:
                case LocalData.myMenu.StockOpening:
                case LocalData.myMenu.CustomerOpening:
                case LocalData.myMenu.SupplierOpening:
                case LocalData.myMenu.ManufacturerOpening:
                case LocalData.myMenu.Manufacture:
                case LocalData.myMenu.RawIssue:
                case LocalData.myMenu.FinishGoods:
                case LocalData.myMenu.ReturnStock:
                case LocalData.myMenu.GetStock:
                case LocalData.myMenu.GoodsRecieveManu:

                    decimal.TryParse(dt.Compute("Sum(Amount)", "").ToString(), out TotalAmount);
                    tslbMachine.Text = "Total Amount : " + TotalAmount.ToString("#,##0");
                    tslbMachine.Visible = true;
                    if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.Purchase)
                    {
                        decimal.TryParse(dt.Compute("Sum(PaidAmount)", "").ToString(), out Paid);
                        tsLabelPaid.Text = "Paid Amount : " + Paid.ToString("#,##0");
                        tsLabelPaid.Visible = true;
                        int.TryParse(dt.Compute("Sum(PK)", "").ToString(), out pk);
                        tsLablePK.Text = " PK : " + pk.ToString();
                        tsLablePK.Visible = true;
                    }
                    if (LocalData.Menu == LocalData.myMenu.Sale && tsLabelBankCharges != null)
                    {
                        decimal bankChg = 0;
                        if (dt.Columns.Contains("Charges"))
                            decimal.TryParse(dt.Compute("Sum(Charges)", "").ToString(), out bankChg);
                        tsLabelBankCharges.Text = "Bank Charges : " + bankChg.ToString("#,##0");
                        tsLabelBankCharges.Visible = true;
                    }
                    break;
                case LocalData.myMenu.StockBalance:
                    break;
                case LocalData.myMenu.AcctOpening:
                    break;

                case LocalData.myMenu.Journal:
                    break;
                case LocalData.myMenu.Exchange:
                    break;
                case LocalData.myMenu.PriceChange:
                    break;
                case LocalData.myMenu.CustBalance:
                case LocalData.myMenu.SupBalance:
                case LocalData.myMenu.ManuBalance:
                    decimal.TryParse(dt.Compute("Sum(Closing)", "").ToString(), out TotalAmount);
                    tslbMachine.Text = "Total Amount : " + TotalAmount.ToString("#,##0");
                    tsLabelPaid.Text = "                 " ;
                    tsLabelPaid.Visible = true;
                    tslbMachine.Visible = true;
                    break;
                case LocalData.myMenu.CustSettlement:
                case LocalData.myMenu.SupSettlement:
                case LocalData.myMenu.ManuSettlement:
                case LocalData.myMenu.IncomeExpense:
                    decimal.TryParse(dt.Compute("Sum(TotalIncome)", "").ToString(), out TotalAmount);
                    tslbMachine.Text = "Total Income : " + TotalAmount.ToString("#,##0");
                    tslbMachine.Visible = true;
                    decimal.TryParse(dt.Compute("Sum(TotalExpense)", "").ToString(), out Paid);
                    tsLabelPaid.Text = "Total Expense : " + Paid.ToString("#,##0");
                    tsLabelPaid.Visible = true;

                    break;
                default:
                    break;
            }
        }
        private void cmsEdit_Click(object sender, EventArgs e)
        {
            int i;

            if (dlvHistory.SelectedItems.Count != 1)
            {
                MessageBox.Show(dlvHistory.SelectedItems.Count <= 0
                    ? "Select Voucher!"
                    : "Select one voucher to edit.");
                return;
            }

            int.TryParse(dlvHistory.SelectedItem.SubItems[1].Text.ToString(), out i);
            Boolean edit;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckEditVoucher(" + LocalData.UserID.ToString() + "," + i.ToString() + "," + ((int)LocalData.Menu).ToString() + ")").ToString(), out edit);
            if (!edit)
            {
                switch (LocalData.Menu)
                {
                    case LocalData.myMenu.SaleOrder:
                    case LocalData.myMenu.Sale:
                    case LocalData.myMenu.SaleReturn:
                        frm = new frm_SalesOrder(i);
                        break;
                    case LocalData.myMenu.PurchaseOrder:
                    case LocalData.myMenu.Purchase:
                    case LocalData.myMenu.Receive:
                    case LocalData.myMenu.PurchaseReturn:
                    case LocalData.myMenu.ReturnReceive:
                    case LocalData.myMenu.GoodsReceive:
                        frm = new frm_Purchasecs(i);
                        break;
                    case LocalData.myMenu.Adjustment:
                    case LocalData.myMenu.Transfer:
                        frm = new frm_Transfer(i);
                        break;
                    case LocalData.myMenu.StockOpening:
                    case LocalData.myMenu.CustomerOpening:
                    case LocalData.myMenu.SupplierOpening:
                    case LocalData.myMenu.ManufacturerOpening:
                        frm = new frm_CustOpening(i);
                        break;
                    case LocalData.myMenu.CustSettlement:
                    case LocalData.myMenu.SupSettlement:
                    case LocalData.myMenu.ManuSettlement:
                    case LocalData.myMenu.IncomeExpense:
                    case LocalData.myMenu.Journal:
                        frm = new frm_IncomeExpense(i);
                        break;
                    case LocalData.myMenu.Manufacture:
                        break;
                    case LocalData.myMenu.StockBalance:
                        break;
                    case LocalData.myMenu.AcctOpening:
                        frm = new frm_AcctOpening(i);
                        break;
                    case LocalData.myMenu.Exchange:
                        break;
                    case LocalData.myMenu.PriceChange:
                        break;
                    case LocalData.myMenu.RawIssue:
                    case LocalData.myMenu.FinishGoods:
                    case LocalData.myMenu.ReturnStock:
                    case LocalData.myMenu.GetStock:
                    case LocalData.myMenu.GoodsRecieveManu:
                        frm = new frm_Manufacture(i);
                        break;
                    case LocalData.myMenu.CustSup:
                        frm = new frm_CustSupTransfer(i);
                        break;
                    default:
                        break;
                }

                if (frm.ShowDialog() == DialogResult.OK)
                {
                    FillListView();
                }

            }
            else
            {
                int uid;
                int.TryParse(DBConnection.roExecSQL("select UserID from VoucherEditing Where TranID = " + i.ToString() + " and MenuID = " + ((int)LocalData.Menu).ToString()).ToString(), out uid);
                MessageBox.Show("This Voucher is Editing By " + DBConnection.rExecSQL("Select Name From Users Where ID = " + uid.ToString()).ToString());
            }
            

        }

        private void cboLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboLocation.DroppedDown = true;
            LocalData.AutoComplete(cboLocation, e, true);
        }

        private void cboPayment_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboPayment.DroppedDown = true;
            LocalData.AutoComplete(cboPayment, e, true);
        }

        private void cboTownship_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboTownship.DroppedDown = true;
            LocalData.AutoComplete(cboTownship, e, true);
        }

        private void cboCustomer_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboCustomer.DroppedDown = true;
            LocalData.AutoComplete(cboCustomer, e, true);
        }

        private void cboBrand_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboBrand.DroppedDown = true;
            LocalData.AutoComplete(cboBrand, e, true);
        }

        private void cboCode_KeyPress(object sender, KeyPressEventArgs e)
        {
            //cboCode.DroppedDown = true;
            //LocalData.AutoComplete(cboCode, e, true);
        }

        private void cboTransport_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboTransport.DroppedDown = true;
            LocalData.AutoComplete(cboTransport, e, true);
        }

        private void cboGate_KeyPress(object sender, KeyPressEventArgs e)
        {
            cboGate.DroppedDown = true;
            LocalData.AutoComplete(cboGate, e, true);
        }

        private void dtpFromDate_Validated(object sender, EventArgs e)
        {
            FillListView();
        }

        private void dtpToDate_Validated(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboLocation_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboPayment_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboLocation_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboPayment_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboTownship_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboTownship_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboCustomer_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboCustomer_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboBrand_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboBrand_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboCode_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboCode_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboTransport_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboTransport_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboGate_DropDownClosed(object sender, EventArgs e)
        {
            FillListView();
        }

        private void cboGate_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView();
        }

        private void deleteToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (dlvHistory.SelectedItems.Count <= 0)
            {
                MessageBox.Show("Select Voucher!");
                return;
            }
            int i;
            int.TryParse(dlvHistory.SelectedItem.SubItems[1].Text.ToString(), out i);
            if (MessageBox.Show("Are you sure want to delete '" + dlvHistory.SelectedItem.SubItems[4].Text.ToString() + "' ?", "Transaction", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) == DialogResult.Yes)
            {
                switch (LocalData.Menu)
                {
                    case LocalData.myMenu.SaleOrder:
                        DBConnection.ExecSQL("Update SaleOrderHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Sale:
                        try
                        {
                            SaleAuditLog.LogSaleDelete(i);
                        }
                        catch (Exception ex)
                        {
                            MessageBox.Show("Sale audit log failed (delete continues): " + ex.Message);
                        }
                        DBConnection.ExecSQL("Update SaleHead Set Deleted = 1 Where ID = " + i.ToString());
                        //DBConnection.ExecSQL("Update SaleOrderHead Set isSales = 0 Where ID in (Select OrderRefID From SaleDetail Where RefID = " + i.ToString() + " Group By OrderRefID)");
                        break;
                    case LocalData.myMenu.SaleReturn:
                        DBConnection.ExecSQL("Update SaleReturnHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.PurchaseOrder:
                        DBConnection.ExecSQL("Update PurchaseOrderHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Purchase:
                        DBConnection.ExecSQL("Update PurchaseHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Receive:
                        DBConnection.ExecSQL("Update StockReceiveHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.PurchaseReturn:
                        DBConnection.ExecSQL("Update PurchaseReturnHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.ReturnReceive:
                        DBConnection.ExecSQL("Update ReturnReceiveHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Adjustment:
                        DBConnection.ExecSQL("Update AdjustmentHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Transfer:
                        DBConnection.ExecSQL("Update TransferHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.StockOpening:
                        DBConnection.ExecSQL("Update StockOpeningHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.CustomerOpening:
                        break;
                    case LocalData.myMenu.SupplierOpening:
                        break;
                    case LocalData.myMenu.ManufacturerOpening:
                        break;
                    case LocalData.myMenu.CustSettlement:
                    case LocalData.myMenu.SupSettlement:
                    case LocalData.myMenu.ManuSettlement:
                    case LocalData.myMenu.IncomeExpense:
                    case LocalData.myMenu.Journal:
                        DBConnection.ExecSQL("Update IncomeExpenseHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.Manufacture:
                        break;
                    case LocalData.myMenu.StockBalance:
                        break;
                    case LocalData.myMenu.AcctOpening:
                        DBConnection.ExecSQL("Update AccountOpeningHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;

                    case LocalData.myMenu.Exchange:
                        break;
                    case LocalData.myMenu.PriceChange:
                        break;
                    case LocalData.myMenu.RawIssue:
                        DBConnection.ExecSQL("Update RawIssueHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.FinishGoods:
                    case LocalData.myMenu.GoodsRecieveManu:
                        DBConnection.ExecSQL("Update FinishGoodsHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.ReturnStock:
                        DBConnection.ExecSQL("Update ReturnStockHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.GetStock:
                        DBConnection.ExecSQL("Update GetStockHead Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    case LocalData.myMenu.CustSup:
                        DBConnection.ExecSQL("Update CustSupTransfer Set Deleted = 1 Where ID = " + i.ToString());
                        break;
                    default:
                        break;
                }
                FillListView();

            }
        }

        private void pmCustomerOpening_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmCustomerOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmCustomerOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustomerOpening;
            ChangeFilter();
            FillListView();
        }

        private void pmCustPayment_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmCustPayment.BackColor = Color.FromArgb(130, 60, 180);
            pmCustPayment.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustSettlement;
            ChangeFilter();
            FillListView();
        }

        private void pmCashbook_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmCashbook.BackColor = Color.FromArgb(130, 60, 180);
            pmCashbook.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.IncomeExpense;
            ChangeFilter();
            FillListView();
        }

        private void pmSupplier_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSupplier.BackColor = Color.FromArgb(130, 60, 180);
            pmSupplier.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.SupSettlement;
            ChangeFilter();
            FillListView();
        }

        private void pmManufacturer_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmManufacturer.BackColor = Color.FromArgb(130, 60, 180);
            pmManufacturer.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.ManuSettlement;
            ChangeFilter();
            FillListView();
        }

        private void pmJrnl_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmJrnl.BackColor = Color.FromArgb(130, 60, 180);
            pmJrnl.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.Journal;
            ChangeFilter();
            FillListView();
        }

        private void pmSupOpening_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSupOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmSupOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.SupplierOpening;
            ChangeFilter();
            FillListView();


        }

        private void deleteToolStripMenuItem_DropDownOpening(object sender, EventArgs e)
        {
            //if ( LocalData.UserID == 1 || LocalData.UserID == 3  || LocalData.UserID == 5 || LocalData.UserID)
            //{
            //    deleteToolStripMenuItem.Visible = true;
            //}

        }

        private void cmsTransaction_Opening(object sender, CancelEventArgs e)
        {
            //if (LocalData.UserID == 1 || LocalData.UserID == 2 || LocalData.UserID == 3 || LocalData.UserID == 5 || LocalData.UserID == 6)
            //{
            //    deleteToolStripMenuItem.Visible = true;
            //    deleteToolStripMenuItem.Enabled = true;
            //}
            //else if (LocalData.UserID == 9)
            //{
            //    deleteToolStripMenuItem.Visible = false;
            //    deleteToolStripMenuItem.Enabled = false;
            //    cmsEdit.Visible = false;
            //    cmsEdit.Enabled = false;
            //}
            //else
            //{
            //    deleteToolStripMenuItem.Visible = false;
            //    deleteToolStripMenuItem.Enabled = false;
            //}
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserPermission(" + LocalData.UserID.ToString() + ",2,"+((int)LocalData.Menu).ToString()+",2)").ToString(), out allow);
            deleteToolStripMenuItem.Visible = allow;
            _historyDeleteAllowed = allow;
            // Right-click selects only the row under the cursor before this menu opens.
            if (_restoreMultiOnContext)
                RestoreMultiSelectionAt(dlvHistory.PointToClient(Cursor.Position));
            _restoreMultiOnContext = false;
            ApplyHistorySelectionChrome();
        }

        private void pmAcctOpening_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmAcctOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmAcctOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.AcctOpening;
            ChangeFilter();
            FillListView();
        }

        private void pmManuOpening_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmManuOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmManuOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.ManufacturerOpening;
            ChangeFilter();
            FillListView();
        }

        private void pmStockOpening_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmStockOpening.BackColor = Color.FromArgb(130, 60, 180);
            pmStockOpening.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.StockOpening;
            ChangeFilter();
            FillListView();
        }

        private void pmRawIssue_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmRawIssue.BackColor = Color.FromArgb(130, 60, 180);
            pmRawIssue.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.RawIssue;
            ChangeFilter();
            FillListView();
        }

        private void pmFinishGoods_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmFinishGoods.BackColor = Color.FromArgb(130, 60, 180);
            pmFinishGoods.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.FinishGoods;
            ChangeFilter();
            FillListView();
        }

        private void pmStockReturn_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmStockReturn.BackColor = Color.FromArgb(130, 60, 180);
            pmStockReturn.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.ReturnStock;
            ChangeFilter();
            FillListView();
        }

        private void pmStockGet_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmStockGet.BackColor = Color.FromArgb(130, 60, 180);
            pmStockGet.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.GetStock;
            ChangeFilter();
            FillListView();
        }

        private void pmReturnReceive_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmReturnReceive.BackColor = Color.FromArgb(130, 60, 180);
            pmReturnReceive.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.ReturnReceive;
            ChangeFilter();
            FillListView();
        }

        private void pmGoodsReceive_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmGoodsReceive.BackColor = Color.FromArgb(130, 60, 180);
            pmGoodsReceive.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.GoodsReceive;
            ChangeFilter();
            FillListView();
        }

        private void pmGoodsReceiveManu_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmGoodsReceiveManu.BackColor = Color.FromArgb(130, 60, 180);
            pmGoodsReceiveManu.TextColor = Color.White;
            LocalData.Menu = LocalData.myMenu.GoodsRecieveManu;
            ChangeFilter();
            FillListView();
        }

        private void tbCode_Validated(object sender, EventArgs e)
        {
            FillListView();
        }

        private void pmSetting_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmSetting.BackColor = Color.FromArgb(130, 60, 180);
            pmSetting.TextColor = Color.White;
            frm = new Frm_Profile(1);
            frm.ShowDialog();
        }

        private void pmCustOutstand_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmCustOutstand.BackColor = Color.FromArgb(130, 60, 180);
            pmCustOutstand.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustBalance;
            ChangeFilter();
            FillListView();
        }

        private void dlvHistory_KeyPress(object sender, KeyPressEventArgs e)
        {

        }

        private void pmSupOutstand_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmSupOutstand.BackColor = Color.FromArgb(130, 60, 180);
            pmSupOutstand.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.SupBalance;
            ChangeFilter();
            FillListView();
        }

        private void pmManuBalance_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmManuBalance.BackColor = Color.FromArgb(130, 60, 180);
            pmManuBalance.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.ManuBalance;
            ChangeFilter();
            FillListView();
        }

        private void pmBalance_Load(object sender, EventArgs e)
        {

        }

        private void toolStripMenuItem2_Click(object sender, EventArgs e)
        {
            HideZero = true;
            tssbBalance.Text = "Balance  < > 0 ";
            FillListView();
        }

        private void pmCustSup_MouseSelected(object sender, EventArgs e)
        {
            RightMenuDefault();
            pmCustSup.BackColor = Color.FromArgb(130, 60, 180);
            pmCustSup.TextColor = Color.White;

            LocalData.Menu = LocalData.myMenu.CustSup;
            ChangeFilter();
            FillListView();
        }

        private void tssNew_Click(object sender, EventArgs e)
        {
            cmsNew_Click(sender, e);
        }

        private void tssEdit_Click(object sender, EventArgs e)
        {
            cmsEdit_Click(sender, e);
        }

        private void tsDelete_Click(object sender, EventArgs e)
        {
            deleteToolStripMenuItem_Click(sender, e);
        }

        private void dlvHistory_FormatCell(object sender, BrightIdeasSoftware.FormatCellEventArgs e)
        {
            if (e.ColumnIndex == 8 || e.ColumnIndex == 9)
            {

            }
        }

        private void dlvHistory_ItemsAdding(object sender, BrightIdeasSoftware.ItemsAddingEventArgs e)
        {

        }

        private void dlvHistory_SelectedIndexChanged(object sender, EventArgs e)
        {
            ApplyHistorySelectionChrome();
        }

        private void dlvHistory_SelectionChanged(object sender, EventArgs e)
        {
            ApplyHistorySelectionChrome();
        }

        private void dlvHistory_MouseDown(object sender, MouseEventArgs e)
        {
            KeepHistorySelectionMode();
            _pointerCtrl = (Control.ModifierKeys & Keys.Control) == Keys.Control;
            _pointerShift = (Control.ModifierKeys & Keys.Shift) == Keys.Shift;
            _selectionBeforePointer = CopySelectedModels();
            if (e.Button == MouseButtons.Right)
            {
                object hit = HitHistoryModel(e.Location);
                _restoreMultiOnContext = hit != null
                    && _lastMultiSelection != null
                    && _lastMultiSelection.Count >= 2
                    && _lastMultiSelection.Contains(hit);
            }
        }

        private void dlvHistory_MouseUp(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Right)
            {
                if (_restoreMultiOnContext)
                    RestoreMultiSelectionAt(e.Location);
                return;
            }
            if (e.Button != MouseButtons.Left)
                return;

            // DataListView's currency manager keeps a single Position and replaces
            // SelectedObject whenever that position changes, so Ctrl/Shift clicks
            // collapse back to one row. Rebuild the selection from the pre-click set.
            if (!_pointerCtrl && !_pointerShift)
            {
                _lastMultiSelection = null;
                ApplyHistorySelectionChrome();
                return;
            }

            object hit = HitHistoryModel(e.Location);
            if (hit == null)
            {
                ApplyHistorySelectionChrome();
                return;
            }

            System.Collections.ArrayList next = new System.Collections.ArrayList();
            if (_pointerShift)
            {
                int hitIndex = ModelIndex(hit);
                int anchor = _selectionBeforePointer != null && _selectionBeforePointer.Count > 0
                    ? ModelIndex(_selectionBeforePointer[0])
                    : hitIndex;
                if (anchor < 0)
                    anchor = hitIndex;
                if (hitIndex < 0)
                    hitIndex = anchor;
                int lo = Math.Min(anchor, hitIndex);
                int hi = Math.Max(anchor, hitIndex);
                for (int i = lo; i <= hi; i++)
                {
                    object model = dlvHistory.GetModelObject(i);
                    if (model != null)
                        next.Add(model);
                }
            }
            else
            {
                if (_selectionBeforePointer != null)
                {
                    foreach (object model in _selectionBeforePointer)
                    {
                        if (model != null && ModelIndex(model) >= 0)
                            next.Add(model);
                    }
                }
                if (next.Contains(hit))
                    next.Remove(hit);
                else
                    next.Add(hit);
            }

            if (next.Count > 1)
                _lastMultiSelection = next;
            else
                _lastMultiSelection = null;
            ApplyModelSelection(next);
            QueueMultiReapply(next);
        }

        private void QueueMultiReapply(System.Collections.ArrayList models)
        {
            _pendingMulti = models;
            if (_multiReapplyQueued)
                return;
            _multiReapplyQueued = true;
            Application.Idle += HistoryMultiReapplyOnIdle;
        }

        private void HistoryMultiReapplyOnIdle(object sender, EventArgs e)
        {
            Application.Idle -= HistoryMultiReapplyOnIdle;
            _multiReapplyQueued = false;
            System.Collections.ArrayList pending = _pendingMulti;
            _pendingMulti = null;
            if (IsDisposed || dlvHistory == null || pending == null)
                return;
            // Runs after DataSourceAdapter's SelectionChanged handler, which would
            // otherwise leave only the currency-manager row selected.
            if (!SelectionEquals(pending))
            {
                KeepHistorySelectionMode();
                dlvHistory.SelectedObjects = pending;
            }
            if (pending.Count > 1)
                _lastMultiSelection = pending;
            ApplyHistorySelectionChrome();
        }

        private void RestoreMultiSelectionAt(Point clientLocation)
        {
            if (_lastMultiSelection == null || _lastMultiSelection.Count < 2 || dlvHistory == null)
                return;
            object hit = HitHistoryModel(clientLocation);
            bool hitInMulti = hit != null && _lastMultiSelection.Contains(hit);
            System.Collections.ArrayList current = CopySelectedModels();
            // A right-click reduces the list to the row under the pointer before the menu opens.
            bool collapsedFromMulti = _restoreMultiOnContext
                && current.Count <= 1
                && (current.Count == 0 || _lastMultiSelection.Contains(current[0]));
            if (!hitInMulti && !collapsedFromMulti)
                return;
            KeepHistorySelectionMode();
            dlvHistory.SelectedObjects = _lastMultiSelection;
            ApplyHistorySelectionChrome();
        }

        private System.Collections.ArrayList CopySelectedModels()
        {
            System.Collections.ArrayList copy = new System.Collections.ArrayList();
            if (dlvHistory == null || dlvHistory.SelectedObjects == null)
                return copy;
            foreach (object model in dlvHistory.SelectedObjects)
                copy.Add(model);
            return copy;
        }

        private bool SelectionEquals(System.Collections.ArrayList expected)
        {
            System.Collections.ArrayList current = CopySelectedModels();
            if (current.Count != expected.Count)
                return false;
            foreach (object model in expected)
            {
                if (!current.Contains(model))
                    return false;
            }
            return true;
        }

        private int ModelIndex(object model)
        {
            if (model == null || dlvHistory == null)
                return -1;
            for (int i = 0; i < dlvHistory.GetItemCount(); i++)
            {
                if (object.Equals(dlvHistory.GetModelObject(i), model))
                    return i;
            }
            return -1;
        }

        private object HitHistoryModel(Point location)
        {
            if (dlvHistory == null)
                return null;
            BrightIdeasSoftware.OlvListViewHitTestInfo hit = dlvHistory.OlvHitTest(location.X, location.Y);
            if (hit != null && hit.RowObject != null)
                return hit.RowObject;
            ListViewHitTestInfo plain = dlvHistory.HitTest(location);
            if (plain == null || plain.Item == null)
                return null;
            return dlvHistory.GetModelObject(plain.Item.Index);
        }

        private void ApplyModelSelection(System.Collections.ArrayList models)
        {
            KeepHistorySelectionMode();
            dlvHistory.SelectedObjects = models ?? new System.Collections.ArrayList();
            ApplyHistorySelectionChrome();
        }

        private int HistorySelectionCount()
        {
            int fromItems = dlvHistory.SelectedItems == null ? 0 : dlvHistory.SelectedItems.Count;
            int fromIndices = dlvHistory.SelectedIndices == null ? 0 : dlvHistory.SelectedIndices.Count;
            int fromObjects = dlvHistory.SelectedObjects == null ? 0 : dlvHistory.SelectedObjects.Count;
            int selected = fromItems;
            if (fromIndices > selected)
                selected = fromIndices;
            if (fromObjects > selected)
                selected = fromObjects;
            if (selected > 1)
                _lastMultiSelection = CopySelectedModels();
            return selected;
        }

        private void ApplyHistorySelectionChrome()
        {
            int selected = HistorySelectionCount();
            tssEdit.Enabled = selected == 1;
            cmsEdit.Enabled = selected == 1;
            if (cmsPrint != null)
                cmsPrint.Enabled = selected >= 1;
            bool canDelete = _historyDeleteAllowed && selected >= 1;
            tsDelete.Enabled = canDelete;
            deleteToolStripMenuItem.Enabled = canDelete;
        }

        private void todayToolStripMenuItem_Click(object sender, EventArgs e)
        {
            CustAging = "ToDay";
            tssbBalance.Text = "Balance  = Today ";
            FillListView();
        }

        private void oneWeekToolStripMenuItem_Click(object sender, EventArgs e)
        {
            CustAging = "OneWeek";
            tssbBalance.Text = "Balance  = One Week";
            FillListView();
        }

        private void twoWeekToolStripMenuItem_Click(object sender, EventArgs e)
        {
            CustAging = "TwoWeek";
            tssbBalance.Text = "Balance  = Two Week";
            FillListView();
        }

        private void oneMonthToolStripMenuItem_Click(object sender, EventArgs e)
        {
            CustAging = "OneMonth";
            tssbBalance.Text = "Balance  = One Month";
            FillListView();
        }

        private void overOneMonthToolStripMenuItem_Click(object sender, EventArgs e)
        {
            CustAging = "OverDate";
            tssbBalance.Text = "Balance  = Over One Month ";
            FillListView();
        }

        private void allToolStripMenuItem_Click(object sender, EventArgs e)
        {

            HideZero = false;
            tssbBalance.Text = "Balance  = All";
            FillListView();
        }
    }
}
