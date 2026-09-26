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
using CrystalDecisions.CrystalReports.Engine;
using System.Drawing.Printing;

namespace SB
{
    public partial class frm_Purchasecs : Form
    {
        public static int PrintID = 0;
        int ID, codeid;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;
        Form frm;
        delegate void SetComboBoxCellType(int rIndex);
        bool isComboBox = false;
        ReportDocument rd;
        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            int UnitID, Discount, Qty1, Qty2;
            decimal Weight, Qty, TotalWeight, Price, CostCon, CostTran, NetPrice, ExgRate;
            string Code;
            if (LocalData.Menu != LocalData.myMenu.Receive && LocalData.Menu != LocalData.myMenu.GoodsReceive)
            {
                switch (e.ColumnIndex)
                {
                    case 4:
                        Code = dgvDetail.CurrentRow.Cells["Code"].EditedFormattedValue.ToString();
                        if ((Convert.ToInt32(DBConnection.roExecSQL("select count(*) from Stock where isnull(Deleted,0)<>1 and short = '" + Code + "'").ToString()) > 0))
                        {

                            DataTable dt = new DataTable();
                            dt = DBConnection.GetSQLTable("select ID, Code = Short, Name, StdUnitID from Stock Where Short = N'" + Code.ToString() + "'");

                            dgvDetail.CurrentRow.Cells["CodeID"].Value = dt.Rows[0]["ID"].ToString();
                            dgvDetail.CurrentRow.Cells["Code"].Value = dt.Rows[0]["Code"].ToString();
                            dgvDetail.CurrentRow.Cells["Name"].Value = dt.Rows[0]["Name"].ToString();
                            dgvDetail.CurrentRow.Cells["Unit"].Value = dt.Rows[0]["StdUnitID"].ToString();

                            //foreach (DataRow dr in dt.Rows)
                            //{
                            //    dgvDetail.CurrentRow.Cells["CodeID"].Value = dr["ID"].ToString();
                            //    dgvDetail.CurrentRow.Cells["Code"].Value = dr["Code"].ToString();
                            //    dgvDetail.CurrentRow.Cells["Name"].Value = dr["Name"].ToString();
                            //}
                        }
                        else
                        {
                            MessageBox.Show("Please Check your Code !!!");
                            return;
                        }
                        break;
                    case 7:
                    case 8:

                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out Qty2);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * Qty2;
                        dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Qty"];
                        break;
                    case 9:
                    case 10:
                        dgvDetail.EndEdit();

                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        if (codeid > 0)
                        {
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(PurPrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        }

                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);
                        break;
                    case 11:
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        break;
                    default:
                        break;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                switch (e.ColumnIndex)
                {
                    case 4:
                        Code = dgvDetail.CurrentRow.Cells["Code"].EditedFormattedValue.ToString();
                        if ((Convert.ToInt32(DBConnection.roExecSQL("select count(*) from Stock where isnull(Deleted,0)<>1 and short = '" + Code + "'").ToString()) > 0))
                        {

                            DataTable dt = new DataTable();
                            dt = DBConnection.GetSQLTable("select ID, Code = Short, Name, StdUnitID from Stock Where Short = N'" + Code.ToString() + "'");

                            dgvDetail.CurrentRow.Cells["CodeID"].Value = dt.Rows[0]["ID"].ToString();
                            dgvDetail.CurrentRow.Cells["Code"].Value = dt.Rows[0]["Code"].ToString();
                            dgvDetail.CurrentRow.Cells["Name"].Value = dt.Rows[0]["Name"].ToString();
                            dgvDetail.CurrentRow.Cells["Unit"].Value = dt.Rows[0]["StdUnitID"].ToString();
                        }
                        else
                        {
                            MessageBox.Show("Please Check your Code !!!");
                            return;
                        }
                        break;
                    case 7:
                    case 8:

                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out Qty2);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * Qty2;
                        dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Qty"];
                        break;
                    case 9:
                    case 10:
                        dgvDetail.EndEdit();

                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);
                        break;

                    default:
                        break;
                }
            }
            else
            {
                switch (e.ColumnIndex)
                {
                    case 4:
                        Code = dgvDetail.CurrentRow.Cells["Code"].EditedFormattedValue.ToString();
                        if ((Convert.ToInt32(DBConnection.roExecSQL("select count(*) from Stock where isnull(Deleted,0)<>1 and short = '" + Code + "'").ToString()) > 0))
                        {

                            DataTable dt = new DataTable();
                            dt = DBConnection.GetSQLTable("select ID, Code = Short, Name, StdUnitID from Stock Where Short = N'" + Code.ToString() + "'");

                            dgvDetail.CurrentRow.Cells["CodeID"].Value = dt.Rows[0]["ID"].ToString();
                            dgvDetail.CurrentRow.Cells["Code"].Value = dt.Rows[0]["Code"].ToString();
                            dgvDetail.CurrentRow.Cells["Name"].Value = dt.Rows[0]["Name"].ToString();
                            dgvDetail.CurrentRow.Cells["Unit"].Value = dt.Rows[0]["StdUnitID"].ToString();

                            //foreach (DataRow dr in dt.Rows)
                            //{
                            //    dgvDetail.CurrentRow.Cells["CodeID"].Value = dr["ID"].ToString();
                            //    dgvDetail.CurrentRow.Cells["Code"].Value = dr["Code"].ToString();
                            //    dgvDetail.CurrentRow.Cells["Name"].Value = dr["Name"].ToString();
                            //}
                        }
                        else
                        {
                            MessageBox.Show("Please Check your Code !!!");
                            return;
                        }
                        break;
                    case 7:
                    case 8:

                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out Qty2);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * Qty2;
                        dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Qty"];
                        break;
                    case 9:
                    case 10:
                        dgvDetail.EndEdit();

                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);
                        break;
                    case 11:
                    case 12:
                    case 13:
                    case 14:
                        Decimal.TryParse(tbExgRate.Text.ToString(), out ExgRate);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["PurPrice"].Value.ToString(), out Price);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["CostCon"].Value.ToString(), out CostCon);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["CostTran"].Value.ToString(), out CostTran);
                        dgvDetail.CurrentRow.Cells["Price"].Value = (Price * ExgRate);
                        dgvDetail.CurrentRow.Cells["NetPrice"].Value = ((Price * ExgRate) + CostCon + CostTran);
                        break;
                    default:
                        break;
                }
            }

        }

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            //if (e.ColumnIndex == 2 || e.ColumnIndex == 5 || e.ColumnIndex == 12 || e.ColumnIndex == 13 || e.ColumnIndex == 14)
            if (e.ColumnIndex == 2 )
            {
                    SendKeys.Send("{Tab}");
            }
            else if (e.ColumnIndex == 10 )
            {
                int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[3].Value.ToString(), out codeid);
                SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox);
                dgvDetail.BeginInvoke(cct, e.RowIndex);
                isComboBox = false;
            }
        }
        private void ChangeCellToCombox(int r_index)
        {
            if (isComboBox == false)
            {
                //int i;
                //int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + codeid.ToString()).ToString(), out i);
                DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.DropDownButton;
                combocell.DataSource = DBConnection.GetTable("dbo.GetStockUnit(" + codeid.ToString() + ")", "");
                combocell.ValueMember = "ID";
                combocell.DisplayMember = "Name";
                dgvDetail.Rows[r_index].Cells[dgvDetail.CurrentCell.ColumnIndex] = combocell;
                isComboBox = true;

                dgvDetail.BeginEdit(false);

                var ec = dgvDetail.EditingControl as DataGridViewComboBoxEditingControl;
                if (ec != null)
                    ec.DroppedDown = true;
            }
        }
        public frm_Purchasecs(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void frm_Purchasecs_Load(object sender, EventArgs e)
        {
            cbLocation.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cbLocation.DisplayMember = "Name";
            cbLocation.ValueMember = "ID";
            cbLocation.SelectedValue = 1;

            cbPayment.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From PaymentType where isnull(Deleted,0) <> 1 order by Name");
            cbPayment.DisplayMember = "Name";
            cbPayment.ValueMember = "ID";
            cbPayment.SelectedValue = 2;

            cbAccount.DataSource = DBConnection.GetSQLTable("select * from dbo.GetSalesPaymentAccount(-1)");
            cbAccount.DisplayMember = "Name";
            cbAccount.ValueMember = "ID";
            cbAccount.SelectedValue = 288;

            cbCurrency.DataSource = DBConnection.GetSQLTable("select * from Currency");
            cbCurrency.DisplayMember = "Name";
            cbCurrency.ValueMember = "ID";
            cbCurrency.SelectedValue = 1;

            cbSupplier.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Supplier where isnull(Deleted,0) <> 1 order by Short");
            cbSupplier.DisplayMember = "Name";
            cbSupplier.ValueMember = "ID";
            cbSupplier.SelectedValue = 17;

            dtHead = new DataTable();

            if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                this.Text = "Purchase Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, StockReceived, LocationID, SupplierID, CurrencyID,  PaymentID, AccountID, ExgRate, Remark,Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, UserID, EditDate From PurchaseHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
            {
                this.Text = "Purchase Order Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, SupplierID, Amount, Remark, UserID, EditDate From PurchaseOrderHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);

                lbCurrency.Visible = false;
                cbCurrency.Visible = false;
                lbPayment.Visible = false;
                cbPayment.Visible = false;
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                chkTax.Visible = false;
                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbTax.Visible = false;
                tbTax.Visible = false;
                lbCharges.Visible = false;
                tbCharges.Visible = false;
                lbTotalAmount.Visible = false;
                tbTotalAmount.Visible = false;
                lbPaidAmount.Visible = false;
                tbPaidAmount.Visible = false;
                lbNetBalance.Visible = false;
                tbNetBalance.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
                chkReceive.Visible = false;
                lbExgRate.Visible = false;
                tbExgRate.Visible = false;

            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                this.Text = "Purchase Return Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, StockChange, LocationID, SupplierID,  PaymentID, AccountID, ExgRate, Remark,Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, UserID, EditDate From PurchaseReturnHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                chkReceive.Visible = false;
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                this.Text = "Return Receive Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, SupplierID,  Remark, Amount, UserID, EditDate From ReturnReceiveHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lbCurrency.Visible = false;
                cbCurrency.Visible = false;
                lbPayment.Visible = false;
                cbPayment.Visible = false;
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                chkTax.Visible = false;
                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbTax.Visible = false;
                tbTax.Visible = false;
                lbCharges.Visible = false;
                tbCharges.Visible = false;
                lbTotalAmount.Visible = false;
                tbTotalAmount.Visible = false;
                lbPaidAmount.Visible = false;
                tbPaidAmount.Visible = false;
                lbNetBalance.Visible = false;
                tbNetBalance.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
                lbExgRate.Visible = false;
                tbExgRate.Visible = false;
                chkReceive.Visible = false;
                lblRef.Visible = true;
                cbInvRef.Visible = true;
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                this.Text = "Shipment Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, SupplierID, PurchaseID,  Remark, ExgRate, UserID, EditDate From StockReceiveHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lblRef.Visible = true;
                cbInvRef.Visible = true;
                lbTotalPkg.Visible = true;
                tbTotalPkg.Visible = true;
                chkReceive.Visible = false;
                lbCurrency.Visible = false;
                cbCurrency.Visible = false;
                lbPayment.Visible = false;
                cbPayment.Visible = false;
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                lbExgRate.Visible = true;
                tbExgRate.Visible = true;
                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbTotalAmount.Visible = false;
                tbTotalAmount.Visible = false;
                tbCreditBalance.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
                lbTax.Visible = false;
                tbTax.Visible = false;
                lbAmount.Visible = false;
                tbAmount.Visible = false;
                lbPaidAmount.Visible = false;
                tbPaidAmount.Visible = false;
                lbNetBalance.Visible = false;
                tbNetBalance.Visible = false;
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                this.Text = "Goods Receive Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, StockReceived, LocationID, SupplierID, CurrencyID,  PaymentID, AccountID, ExgRate, Remark,Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, UserID, EditDate From PurchaseHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lblRef.Visible = false;
                cbInvRef.Visible = false;
                lbTotalPkg.Visible = true;
                tbTotalPkg.Visible = true;
                chkReceive.Visible = false;
                lbCurrency.Visible = false;
                cbCurrency.Visible = false;
                lbPayment.Visible = false;
                cbPayment.Visible = false;
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                lbExgRate.Visible = false;
                tbExgRate.Visible = false;
                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbTotalAmount.Visible = false;
                tbTotalAmount.Visible = false;
                tbCreditBalance.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
                lbTax.Visible = false;
                tbTax.Visible = false;
                lbAmount.Visible = false;
                tbAmount.Visible = false;
                lbPaidAmount.Visible = false;
                tbPaidAmount.Visible = false;
                lbNetBalance.Visible = false;
                tbNetBalance.Visible = false;
                chkTax.Visible = false;
            }

            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                dtHead.Rows[0]["SupplierID"] = 1;
                dtHead.Rows[0]["LocationID"] = 1;
                dtHead.Rows[0]["UserID"] = LocalData.UserID;
                if (LocalData.Menu == LocalData.myMenu.Purchase)
                {
                    dtHead.Rows[0]["PaymentID"] = 2;
                    dtHead.Rows[0]["CurrencyID"] = 1;
                    dtHead.Rows[0]["ExgRate"] = 1;
                    dtHead.Rows[0]["Amount"] = 0;
                }
                else if (LocalData.Menu == LocalData.myMenu.Receive)
                {
                    dtHead.Rows[0]["ExgRate"] = 1;
                }
                else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
                {
                    dtHead.Rows[0]["PaymentID"] = 2;
                    dtHead.Rows[0]["ExgRate"] = 1;
                    dtHead.Rows[0]["Amount"] = 0;
                    dtHead.Rows[0]["StockChange"] = true;
                }


            }
            else
            {
                int i, CustID;
                int.TryParse(dtHead.Rows[0]["SupplierID"].ToString(), out CustID);
                tbPhone.Text = DBConnection.rExecSQL("Select isnull(Phone,'') From Supplier Where ID = " + CustID.ToString());                
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();
                if (LocalData.Menu == LocalData.myMenu.Purchase)
                {
                    int.TryParse(dtHead.Rows[0]["PaymentID"].ToString(), out i);
                    Boolean rec = false;
                    Boolean.TryParse(DBConnection.roExecSQL("Select isnull(StockReceived,0) from PurchaseHead Where ID = " + ID.ToString()).ToString(), out rec);
                    chkReceive.Checked = rec;
                }
            }
            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            cbLocation.DataBindings.Add("SelectedValue", dtHead, "LocationID");
            cbSupplier.DataBindings.Add("SelectedValue", dtHead, "SupplierID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");

            if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                cbPayment.DataBindings.Add("SelectedValue", dtHead, "PaymentID");
                cbAccount.DataBindings.Add("SelectedValue", dtHead, "AccountID");
                tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
                cbCurrency.DataBindings.Add("SelectedValue", dtHead, "CurrencyID");
                tbCreditBalance.DataBindings.Add("Text", dtHead, "Balance");
                tbAmount.DataBindings.Add("Text", dtHead, "Amount");
                tbDiscount.DataBindings.Add("Text", dtHead, "Discount");
                tbNetAmount.DataBindings.Add("Text", dtHead, "NetAmount");
                tbTax.DataBindings.Add("Text", dtHead, "TaxAmount");
                //tbCharges.DataBindings.Add("Text", dtHead, "AddAmount");
                tbTotalAmount.DataBindings.Add("Text", dtHead, "TotalAmount");
                tbPaidAmount.DataBindings.Add("Text", dtHead, "PaidAmount");
                tbNetBalance.DataBindings.Add("Text", dtHead, "TotalBalance");
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                cbPayment.DataBindings.Add("SelectedValue", dtHead, "PaymentID");
                cbAccount.DataBindings.Add("SelectedValue", dtHead, "AccountID");
                tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
                tbCreditBalance.DataBindings.Add("Text", dtHead, "Balance");
                tbAmount.DataBindings.Add("Text", dtHead, "Amount");
                tbDiscount.DataBindings.Add("Text", dtHead, "Discount");
                tbNetAmount.DataBindings.Add("Text", dtHead, "NetAmount");
                tbTax.DataBindings.Add("Text", dtHead, "TaxAmount");
                tbTotalAmount.DataBindings.Add("Text", dtHead, "TotalAmount");
                tbPaidAmount.DataBindings.Add("Text", dtHead, "PaidAmount");
                tbNetBalance.DataBindings.Add("Text", dtHead, "TotalBalance");
            }


            FillDataGridView();

            cbSupplier.Focus();
        }

        private void chkReceive_CheckedChanged(object sender, EventArgs e)
        {
            lbLocation.Visible = chkReceive.Checked;
            cbLocation.Visible = chkReceive.Checked;
            //lblRef.Visible = chkReceive.Checked;
            //cbInvRef.Visible = chkReceive.Checked;
        }

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            CalculateNetAmount();
        }

        private void dgvDetail_UserAddedRow(object sender, DataGridViewRowEventArgs e)
        {
            dgvDetail.CurrentRow.Cells["Sr"].Value = e.Row.Index;
        }

        private void dgvDetail_UserDeletedRow(object sender, DataGridViewRowEventArgs e)
        {
            foreach (DataGridViewRow row in dgvDetail.Rows)
            {
                if (!row.IsNewRow)
                {
                    row.Cells["Sr"].Value = row.Index + 1;
                }
            }
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }
            Save();
            frm_Purchasecs_Load(sender, e);
        }

        private void Save()
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }

            if (cbLocation.SelectedValue == null)
            {
                cbLocation.Focus();
                erptransaction.SetError(cbLocation, "Select Location!");
                return;
            }

            if (cbSupplier.SelectedValue == null)
            {
                cbSupplier.Focus();
                erptransaction.SetError(cbSupplier, "Select Supplier!");
                return;
            }




            //dgvDetail.RefreshEdit();
            //dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.NewRowIndex].Cells["Code"];


            DateTime e_Date;
            Boolean Receive;

            Receive = chkReceive.Checked;
            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));

            //dtHead.Rows[0]["Date"] = dtpDate.Value.Date + e_Date.TimeOfDay;
            if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                dtHead.Rows[0]["StockReceived"] = Receive;
                dtHead.Rows[0]["ExgRate"] = tbExgRate.Text;
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                dtHead.Rows[0]["ExgRate"] = tbExgRate.Text.ToString();
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                dtHead.Rows[0]["StockChange"] = true;
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                dtHead.Rows[0]["StockReceived"] = 1;
                dtHead.Rows[0]["CurrencyID"] = 1;
                dtHead.Rows[0]["ExgRate"] = 1;
                dtHead.Rows[0]["PaymentID"] = 2;
            }


            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            scb = new SqlCommandBuilder(sdaHead);
            sdaHead.Update(dtHead);


            if (ID <= 0)
            {
                if (LocalData.Menu == LocalData.myMenu.Purchase)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from PurchaseHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.Purchase, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from PurchaseOrderHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.PurchaseOrder, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from PurchaseReturnHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.PurchaseReturn, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.Receive)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from StockReceiveHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.Receive, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from ReturnReceiveHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.ReturnReceive, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from PurchaseHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.Purchase, dtpDate.Value);
                }

            }

            foreach (DataRow dr in dtDetail.Rows)
            {
                switch (dr.RowState)
                {
                    case DataRowState.Added:
                        dr["refID"] = ID;
                        break;
                    case DataRowState.Deleted:
                    case DataRowState.Detached:
                        continue;
                    case DataRowState.Modified:

                        break;
                    case DataRowState.Unchanged:
                        continue;
                    default:
                        break;
                }
            }

            if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark, PurchaseID  from PurchaseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark from PurchaseOrderDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark from PurchaseReturnDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, TotalWeight, Qty1, Qty2, Remark, PurchaseID, PurPrice, Price, CostCon, CostTran, NetPrice from StockReceiveDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark, ReturnID from ReturnReceiveDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, TotalWeight, Qty1, Qty2, Remark, PurchaseID  from PurchaseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }

            scb = new SqlCommandBuilder(sdaDetail);
            sdaDetail.Update(dtDetail);

            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                UpdatePurchasePrice(dtDetail);
            }
            //UpdateSalePrice(dtDetail);

            MessageBox.Show("Save Successfully");
            PrintID = ID;

            scb.Dispose();
            sdaHead.Dispose();
            sdaDetail.Dispose();
            dtHead.Dispose();
            dtDetail.Dispose();


            dtpDate.DataBindings.Clear();
            tbAutoID.DataBindings.Clear();
            tbDocumentID.DataBindings.Clear();
            cbLocation.DataBindings.Clear();
            cbSupplier.DataBindings.Clear();
            tbRemark.DataBindings.Clear();

            if (LocalData.Menu != LocalData.myMenu.Receive && LocalData.Menu != LocalData.myMenu.PurchaseOrder)
            {
                cbCurrency.DataBindings.Clear();
                cbAccount.DataBindings.Clear();
                cbPayment.DataBindings.Clear();
                tbCreditBalance.DataBindings.Clear();
                tbAmount.DataBindings.Clear();
                tbDiscount.DataBindings.Clear();
                tbNetAmount.DataBindings.Clear();
                tbTax.DataBindings.Clear();
                //tbCharges.DataBindings.Clear();
                tbTotalAmount.DataBindings.Clear();
                tbPaidAmount.DataBindings.Clear();
                tbNetBalance.DataBindings.Clear();
                tbExgRate.DataBindings.Clear();
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                tbExgRate.DataBindings.Clear();
            }


            ID = 0;

        }

        private void UpdatePurchasePrice(DataTable dt)
        {

            foreach (DataRow dRow in dt.Rows)
            {
                if (dRow["CodeID"].ToString() != "")
                {
                    DBConnection.ExecSQL("Update StockDetail Set  CostCon = " + dRow["CostCon"].ToString() + ", CostTran = " + dRow["CostTran"].ToString() + " Where StockID =" + dRow["CodeID"].ToString() + " and UnitID = " + dRow["UnitID"].ToString());
                }

            }



        }

        private void cbLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbLocation.DroppedDown = true;
            LocalData.AutoComplete(cbLocation, e, true);
        }

        private void cbSupplier_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbSupplier.DroppedDown = true;
            LocalData.AutoComplete(cbSupplier, e, true);
        }

        private void cbSupplier_DropDownClosed(object sender, EventArgs e)
        {
            decimal Opn;
            dtHead.Rows[0]["SupplierID"] = cbSupplier.SelectedValue;

            tbPhone.Text = DBConnection.rExecSQL("Select Phone From Supplier Where ID = " + cbSupplier.SelectedValue.ToString());
            //tbAddress.Text = DBConnection.rExecSQL("Select Address From Customer Where ID = " + cbCustomer.SelectedValue.ToString());
            decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetSupplierBalance( " + cbSupplier.SelectedValue.ToString() + ")").ToString(), out Opn);
            tbCreditBalance.Text = Opn.ToString();

            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                cbInvRef.DataSource = DBConnection.GetSQLTable("select ID = RefID, Name = isnull(DocumentID, AutoID) + '  [' + Format(Date, 'dd/MM/yyyy') + ']' from dbo.GetPurchaseBalReceive(" + cbSupplier.SelectedValue.ToString() + ") Group by RefID, Date, DocumentID, AutoID");
                cbInvRef.DisplayMember = "Name";
                cbInvRef.ValueMember = "ID";
                cbInvRef.SelectedValue = 0;
            }

            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                cbInvRef.DataSource = DBConnection.GetSQLTable("select ID = RefID, Name = isnull(DocumentID, AutoID) + '  [' + Format(Date, 'dd/MM/yyyy') + ']' from dbo.GetPurchaseBalReceive(" + cbSupplier.SelectedValue.ToString() + ") Group by RefID, Date, DocumentID, AutoID");
                cbInvRef.DisplayMember = "Name";
                cbInvRef.ValueMember = "ID";
                cbInvRef.SelectedValue = 0;
            }
            else if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                cbInvRef.DataSource = DBConnection.GetSQLTable("Select ID = Max(RefID), Name = Short + '-' + Customer + '  ['+ Format(Date,'dd/MM/yyyy') + ']' + '-' + isnull(AutoID,'') from dbo.GetPurchaseOrderBal(" + cbSupplier.SelectedValue.ToString() + ") Group By  AutoID, Short, Customer, Date order by Short");
                cbInvRef.DisplayMember = "Name";
                cbInvRef.ValueMember = "ID";
                cbInvRef.SelectedValue = 0;
                decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetSupplierBalance( " + cbSupplier.SelectedValue.ToString() + ")").ToString(), out Opn);
                tbCreditBalance.Text = Opn.ToString();
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                cbInvRef.DataSource = DBConnection.GetSQLTable("select ID = RefID, Name = isnull(DocumentID, AutoID) + '  [' + Format(Date, 'dd/MM/yyyy') + ']' from dbo.GetReturnBalReceive(" + cbSupplier.SelectedValue.ToString() + ") Group by RefID, Date, DocumentID, AutoID");
                cbInvRef.DisplayMember = "Name";
                cbInvRef.ValueMember = "ID";
                cbInvRef.SelectedValue = 0;
            }

        }

        private void cbSupplier_SelectionChangeCommitted(object sender, EventArgs e)
        {
            cbSupplier_DropDownClosed(sender, e);
        }

        private void cbPayment_DropDownClosed(object sender, EventArgs e)
        {
            dtHead.Rows[0]["PaymentID"] = cbPayment.SelectedValue;
            ChangeAccount();
        }
        private void ChangeAccount()
        {
            int payid;
            int.TryParse(cbPayment.SelectedValue.ToString(), out payid);
            if (payid == 3)
            {
                dtHead.Rows[0]["AccountID"] = 436;

            }
            else if (payid == 1)
            {
                dtHead.Rows[0]["AccountID"] = 288;

            }
            else if (payid == 2)
            {
                dtHead.Rows[0]["AccountID"] = 288;

            }
        }

        private void cbPayment_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbPayment.DroppedDown = true;
            LocalData.AutoComplete(cbPayment, e, true);
        }

        private void cbPayment_SelectionChangeCommitted(object sender, EventArgs e)
        {
            dtHead.Rows[0]["PaymentID"] = cbPayment.SelectedValue;
            ChangeAccount();
        }

        private void cbInvRef_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillPurchase();
        }

        private void FillPurchase()
        {
            dtDetail.Rows.Clear();
            DataTable dtfill;
            dtfill = new DataTable();

            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, B.Qty1, B.Qty2, B.Price, B.CostCon, B.CostTran, Weight = B.Weight , S.Short, S.Name  From dbo.GetPurchaseBalReceive(" + cbSupplier.SelectedValue.ToString() + ") B Join Stock S on B.CodeID = S.ID Where RefID = " + cbInvRef.SelectedValue.ToString());
                DataRow dtNrow;
                int i = 0;
                decimal netPrice = 0, Price = 0, CostCon = 0, CostTran = 0, PurPrice = 0;
                Decimal exgrate;
                Decimal.TryParse(tbExgRate.Text.ToString(), out exgrate);
                foreach (DataRow row in dtfill.Rows)
                {
                    decimal.TryParse(row["Price"].ToString(), out PurPrice);
                    decimal.TryParse(row["CostCon"].ToString(), out CostCon);
                    decimal.TryParse(row["CostTran"].ToString(), out CostTran);

                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["PurchaseID"] = row["RefID"];
                    dtNrow["CodeID"] = row["CodeID"];
                    dtNrow["Code"] = row["Short"];
                    dtNrow["Name"] = row["Name"];
                    dtNrow["UnitID"] = row["UnitID"];
                    dtNrow["BrandID"] = row["BrandID"];
                    dtNrow["Qty"] = row["Qty"];
                    dtNrow["Qty1"] = row["Qty1"];
                    dtNrow["Qty2"] = row["Qty2"];
                    dtNrow["PurPrice"] = PurPrice;
                    dtNrow["Price"] = PurPrice * exgrate;
                    dtNrow["CostCon"] = row["CostCon"];
                    dtNrow["CostTran"] = row["CostTran"];
                    dtNrow["Weight"] = row["Weight"];
                    netPrice = (PurPrice * exgrate) + CostCon + CostTran;
                    dtNrow["NetPrice"] = netPrice;
                    dtDetail.Rows.Add(dtNrow);

                }

            }
            else if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                DateTime tmp;
                string st;

                tmp = Convert.ToDateTime(DBConnection.rExecSQL("Select Date From dbo.GetPurchaseOrderBal(" + cbSupplier.SelectedValue.ToString() + ") Where RefID = " + cbInvRef.SelectedValue.ToString()));
                st = DBConnection.rExecSQL("Select AutoID From dbo.GetPurchaseOrderBal(" + cbSupplier.SelectedValue.ToString() + ") Where RefID = " + cbInvRef.SelectedValue.ToString()).ToString();
                dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, B.Qty1, B.Qty2, B.Price, B.Weight, S.Short, S.Name, Amount = B.Qty * B.Price  From dbo.GetPurchaseOrderBal(" + cbSupplier.SelectedValue.ToString() + ") B Join Stock S on B.CodeID = S.ID Where Date = '" + tmp.ToString("yyyy-MM-dd") + "' and AutoID ='" + st.ToString() + "' Order by RefID");
                DataRow dtNrow;
                int i = 0;
                foreach (DataRow row in dtfill.Rows)
                {
                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["PurchaseID"] = row["RefID"];
                    dtNrow["CodeID"] = row["CodeID"];
                    dtNrow["Code"] = row["Short"];
                    dtNrow["Name"] = row["Name"];
                    dtNrow["UnitID"] = row["UnitID"];
                    dtNrow["BrandID"] = row["BrandID"];
                    dtNrow["Qty"] = row["Qty"];
                    dtNrow["Qty1"] = row["Qty1"];
                    dtNrow["Qty2"] = row["Qty2"];
                    dtNrow["Weight"] = row["Weight"];
                    dtNrow["Price"] = row["Price"];
                    dtNrow["Amount"] = row["Amount"];
                    dtDetail.Rows.Add(dtNrow);

                }
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, B.Qty1, B.Qty2, B.Price, B.Weight, S.Short, S.Name, Amount = B.Qty * B.Price  From dbo.GetReturnBalReceive(" + cbSupplier.SelectedValue.ToString() + ") B Join Stock S on B.CodeID = S.ID Where RefID = " + cbInvRef.SelectedValue.ToString());
                DataRow dtNrow;
                int i = 0;
                foreach (DataRow row in dtfill.Rows)
                {
                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["ReturnID"] = row["RefID"];
                    dtNrow["CodeID"] = row["CodeID"];
                    dtNrow["Code"] = row["Short"];
                    dtNrow["Name"] = row["Name"];
                    dtNrow["UnitID"] = row["UnitID"];
                    dtNrow["BrandID"] = row["BrandID"];
                    dtNrow["Qty"] = row["Qty"];
                    dtNrow["Qty1"] = row["Qty1"];
                    dtNrow["Qty2"] = row["Qty2"];
                    dtNrow["Weight"] = row["Weight"];
                    dtNrow["Price"] = row["Price"];
                    dtNrow["Amount"] = row["Amount"];
                    dtDetail.Rows.Add(dtNrow);

                }
            }

        }

        private void cbCurrency_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbCurrency.DroppedDown = true;
            LocalData.AutoComplete(cbCurrency, e, true);
        }

        private void cbAccount_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbAccount.DroppedDown = true;
            LocalData.AutoComplete(cbAccount, e, true);
        }

        private void btSave_Click(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click(sender, e);
        }

        private void btPrint_Click(object sender, EventArgs e)
        {
            rd = new ReportDocument();
            PrintDocument localPrinter = new PrintDocument();
            //rd.PrintOptions.PrinterName = "EPSON TM-U220 ReceiptE4";
            rd.PrintOptions.PrinterName = localPrinter.PrinterSettings.PrinterName;

            if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                Save();
                rd.FileName = Environment.CurrentDirectory + @"\Reports\RawInvoice.rpt";
                rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                rd.SetDatabaseLogon("sa", "27042005@MND");

                rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID,  C.Name, Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, D.Amount, Qty1, Qty2, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark from PurchaseReturnHead H Join PurchaseReturnDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID   Where H.ID = " + frm_Purchasecs.PrintID.ToString()));

                rd.PrintToPrinter(1, false, 0, 0);
                DBConnection.ExecSQL("Update PurchaseReturnHead Set Printed = 1 Where ID = " + frm_Purchasecs.PrintID.ToString());
                frm_Purchasecs_Load(sender, e);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
            {
                PrinterSettings PrnSetting = new PrinterSettings();
                PageSettings PgSetting = new PageSettings();
                string prnName = string.Empty;

                Save();
                prnName = DBConnection.rExecSQL("Select Voucher From LogInClient Where ID = " + LocalData.LoginID).ToString();
                PrnSetting.PrinterName = prnName;
                //PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                PrnSetting.Copies = 1;
                PgSetting.PaperSize = new PaperSize("Custom", 479, 1684);

                rd.FileName = Environment.CurrentDirectory + @"\Reports\OrderVoucher.rpt";
                rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                rd.SetDatabaseLogon("sa", "27042005@MND");

                rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select * From Setting"));
                rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID = isnull(Cast(DocumentID as nvarchar(10)), AutoID), SaleID = '', C.Name, Location = L.Short, Sr,  Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, D.Amount, Qty1 = isnull(Qty1, 0), Qty2 = isnull(Qty2, 0), TotalWeight, NetAmount = isnull(H.Amount, 0), H.Remark from PurchaseOrderHead H Join PurchaseOrderDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID   Where H.ID = " + frm_Purchasecs.PrintID.ToString()));
                rd.SetParameterValue("Header", "Purchase Order");

                rd.PrintToPrinter(PrnSetting, PgSetting, false);
                DBConnection.ExecSQL("Update PurchaseOrderHead Set Printed = 1 Where ID = " + frm_Purchasecs.PrintID.ToString());
                frm_Purchasecs_Load(sender, e);
            }
        }

        private void tbCreditBalance_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbCreditBalance);
        }

        private void tbAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbAmount);
        }

        private void tbNetAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbNetAmount);
        }

        private void tbTotalAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbTotalAmount);
        }

        private void tbNetBalance_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbNetBalance);
        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {
            btPrint_Click(sender, e);
        }

        private void tbExgRate_Leave(object sender, EventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                Decimal rate, price;
                int costtran, costcon;
                foreach (DataRow dr in dtDetail.Rows)
                {
                    Decimal.TryParse(tbExgRate.Text.ToString(), out rate);
                    Decimal.TryParse(dr["PurPrice"].ToString(), out price);
                    int.TryParse(dr["CostCon"].ToString(), out costcon);
                    int.TryParse(dr["CostTran"].ToString(), out costtran);
                    dr["Price"] = rate * price;
                    dr["NetPrice"] = (rate * price) + costtran + costcon;
                }
            }
        }

        private void FillDataGridView()
        {

            dtDetail = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, PurchaseID From PurchaseDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, PurchaseID = 0 From PurchaseOrderDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark From PurchaseReturnDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID,  Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, ReturnID From ReturnReceiveDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID, PurPrice, Price, CostCon, CostTran, NetPrice, Weight, TotalWeight, Remark, PurchaseID From StockReceiveDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }
            if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Weight, TotalWeight, Remark, PurchaseID From PurchaseDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
            }


            dgvDetail.DataSource = dtDetail;
            dgvDetail.Columns["ID"].Visible = false;
            dgvDetail.Columns["RefID"].Visible = false;
            dgvDetail.Columns["CodeID"].Visible = false;
            dgvDetail.Columns["Remark"].Visible = false;
            dgvDetail.Columns["Sr"].ReadOnly = true;
            dgvDetail.Columns["Sr"].Width = 40;
            dgvDetail.Columns["Code"].Width = 120;
            dgvDetail.Columns["Name"].HeaderText = "Description";
            dgvDetail.Columns["Name"].ReadOnly = true;
            dgvDetail.Columns["Name"].Width = 250;
            dgvDetail.Columns["Qty1"].Width = 60;
            dgvDetail.Columns["Qty1"].HeaderText = "PK";
            dgvDetail.Columns["Qty2"].Width = 60;
            dgvDetail.Columns["Qty2"].HeaderText = "";
            dgvDetail.Columns["Qty"].Width = 80;
            dgvDetail.Columns["Weight"].Width = 80;
            dgvDetail.Columns["TotalWeight"].Width = 120;


            if (LocalData.Menu == LocalData.myMenu.Receive)
            {
                dgvDetail.Columns["PurchaseID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["NetPrice"].ReadOnly = true;
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                //dgvDetail.Columns["Weight"].ReadOnly = true;
                //dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                //dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                //dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                //dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                //dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Weight"].Width = 100;
                dgvDetail.Columns["Weight"].Visible = true;
                dgvDetail.Columns["TotalWeight"].Visible = false;
                dgvDetail.Columns["PurPrice"].Width = 120;
                dgvDetail.Columns["PurPrice"].HeaderText = "Price";
                dgvDetail.Columns["Price"].Width = 120;
                dgvDetail.Columns["Price"].HeaderText = "Price(Ks)";
                dgvDetail.Columns["CostCon"].Width = 120;
                dgvDetail.Columns["CostCon"].HeaderText = "Oversea Cost(Ks)";
                dgvDetail.Columns["CostTran"].Width = 120;
                dgvDetail.Columns["CostTran"].HeaderText = "Local Cost(Ks)";
                dgvDetail.Columns["NetPrice"].Width = 120;
                dgvDetail.Columns["NetPrice"].HeaderText = "Net Price(Ks)";

                dgvDetail.Columns["PurPrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["PurPrice"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#,###";
                dgvDetail.Columns["CostCon"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["CostCon"].DefaultCellStyle.Format = "#,###";
                dgvDetail.Columns["CostTran"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["CostTran"].DefaultCellStyle.Format = "#,###";
                dgvDetail.Columns["NetPrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["NetPrice"].DefaultCellStyle.Format = "#,###";
            }
            else if (LocalData.Menu == LocalData.myMenu.Purchase)
            {
                dgvDetail.Columns["Remark"].Visible = true;
                dgvDetail.Columns["PurchaseID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                dgvDetail.Columns["Remark"].Width = 250;
                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                dgvDetail.Columns["ReturnID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                //dgvDetail.Columns["PurchaseID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsReceive)
            {
                dgvDetail.Columns["PurchaseID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Remark"].Visible = true;
                dgvDetail.Columns["Remark"].Width = 150;
            }
            else
            {
                dgvDetail.Columns["PurchaseID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#,###.######";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            //dgvDetail.Columns["SaleOrderID"].Visible = false;
            //dgvDetail.Columns["TotalWeight"].Visible = false;


            DataGridViewComboBoxColumn UnitID = new DataGridViewComboBoxColumn();
            UnitID.Name = "Unit";
            UnitID.HeaderText = "Unit";
            UnitID.Width = 70;
            UnitID.DataSource = DBConnection.GetSQLTable("Select ID, Name From unit");
            UnitID.ValueMember = "ID";
            UnitID.DisplayMember = "Name";
            UnitID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
            if (dgvDetail.Columns.Contains("UnitID"))
            {
                dgvDetail.Columns.Remove("UnitID");
            }
            else if (dgvDetail.Columns.Contains("Unit"))
            {
                dgvDetail.Columns.Remove("Unit");
            }
            UnitID.DataPropertyName = "UnitID";
            dgvDetail.Columns.Insert(dgvDetail.Columns["Qty"].Index + 1, UnitID);

            //DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
            //BrandID.Name = "Brand";
            //BrandID.HeaderText = "Brand";
            //BrandID.Width = 80;
            //BrandID.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID, Name = Short From Brand");
            //BrandID.ValueMember = "ID";
            //BrandID.DisplayMember = "Name";
            //BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
            //if (dgvDetail.Columns.Contains("BrandID"))
            //{
            //    dgvDetail.Columns.Remove("BrandID");
            //}
            //else if (dgvDetail.Columns.Contains("Brand"))
            //{
            //    dgvDetail.Columns.Remove("Brand");
            //}
            //BrandID.DataPropertyName = "BrandID";
            //dgvDetail.Columns.Insert(dgvDetail.Columns["Name"].Index + 1, BrandID);




        }


        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.F1)
            {
                if (dgvDetail.IsCurrentCellInEditMode)
                {
                    if (dgvDetail.CurrentCell.ColumnIndex == 4)
                    {
                        frm = new frm_CodeList(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
                        if (frm.ShowDialog() == DialogResult.OK)
                        {
                            int i;
                            int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + frm_CodeList.CodeID.ToString()).ToString(), out i);
                            dgvDetail.EndEdit();
                            dgvDetail.CurrentRow.Cells["CodeID"].Value = frm_CodeList.CodeID;
                            dgvDetail.CurrentRow.Cells["Code"].Value = frm_CodeList.Code;
                            dgvDetail.CurrentRow.Cells["Name"].Value = frm_CodeList.Description;
                            //dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
                            //dgvDetail.CurrentRow.Cells["Price"].Value = frm_CodeList.SalePrice;
                            dgvDetail.CurrentRow.Cells["Unit"].Value = i;
                            //dgvDetail.CurrentRow.Cells["PrintCharge"].Value = frm_CodeList.Print;
                            //dgvDetail.CurrentRow.Cells["Weight"].Value = frm_CodeList.Weight;
                            dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Name"];
                        }

                    }

                }

                return true;    // indicate that you handled this keystroke
            }
            else if (keyData == Keys.Enter)
            {
                SendKeys.Send("{TAB}");
                return true;
            }
            else if (keyData == Keys.F2)
            {
                tbDiscount.Focus();
                return true;
            }
            else if (keyData == Keys.F3)
            {
                tbPaidAmount.Focus();
                return true;
            }
            else if (keyData == Keys.Left)
            {
                SendKeys.Send("+{TAB}");
                return true;
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void CalculateNetAmount()
        {
            decimal NetAmount, amount, discount, tax, charges, TotalAmount, TotalWeight, PaidAmount, BalanceAmount;
            int Qty, Qty1;

            int.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out Qty);
            tbTotalQty.Text = Qty.ToString("#,##0");
            int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out Qty1);
            tbTotalPkg.Text = Qty1.ToString("#,##0");
            decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
            tbTotalWeight.Text = TotalWeight.ToString("#.##0");

            if (LocalData.Menu == LocalData.myMenu.Purchase || LocalData.Menu == LocalData.myMenu.PurchaseReturn)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
                tbAmount.Text = amount.ToString("#,###.###");
                decimal.TryParse(tbCreditBalance.Text.ToString(), out BalanceAmount);
                decimal.TryParse(tbDiscount.Text.ToString(), out discount);
                tbNetAmount.Text = (amount - discount).ToString("#,###.###");
                dtHead.Rows[0]["Amount"] = amount;
                dtHead.Rows[0]["Balance"] = BalanceAmount;
                dtHead.Rows[0]["Discount"] = discount;
                dtHead.Rows[0]["NetAmount"] = amount - discount;
                if (chkTax.Checked)
                {
                    tbTax.Text = ((amount - discount) * 5 / 100).ToString("#,##0");

                }
                else
                {
                    tbTax.Text = "0";
                }
                decimal.TryParse(tbTax.Text.ToString(), out tax);
                decimal.TryParse(tbCharges.Text.ToString(), out charges);
                decimal.TryParse(tbPaidAmount.Text.ToString(), out PaidAmount);
                dtHead.Rows[0]["TaxAmount"] = tax;
                //dtHead.Rows[0]["AddAmount"] = charges;
                dtHead.Rows[0]["PaidAmount"] = PaidAmount;
                tbTotalAmount.Text = (amount - discount + tax + charges).ToString("#,###.###");
                tbNetBalance.Text = (BalanceAmount + amount - discount + tax + charges - PaidAmount).ToString("#,###.###");
                dtHead.Rows[0]["TotalAmount"] = amount - discount + tax + charges;
                dtHead.Rows[0]["TotalBalance"] = BalanceAmount + amount - discount + tax + charges - PaidAmount;
            }
            else if (LocalData.Menu == LocalData.myMenu.PurchaseOrder)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
                dtHead.Rows[0]["Amount"] = amount;
                tbAmount.Text = amount.ToString("#,###.###");
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnReceive)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
                dtHead.Rows[0]["Amount"] = amount;
                tbAmount.Text = amount.ToString("#,###.###");
            }

        }
    }
}
