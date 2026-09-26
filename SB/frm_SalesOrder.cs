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
using System.Drawing.Printing;
using CrystalDecisions.CrystalReports.Engine;


namespace SB
{
    public partial class frm_SalesOrder : Form
    {
        public static int PrintID = 0;
        int ID, codeid;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;
        Form frm;
        delegate void SetComboBoxCellType(int rIndex);
        bool isComboBox = false;
        decimal chg_percnet = 0;
        bool suppressBankChargesRecalc = false;
        bool customerHardcodeApplied = false;

        public frm_SalesOrder(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }



        private void label12_Click(object sender, EventArgs e)
        {

        }

        private void textBox8_TextChanged(object sender, EventArgs e)
        {

        }

        private void codeListsToolStripMenuItem_Click(object sender, EventArgs e)
        {
            MessageBox.Show("Code List " + dgvDetail.CurrentCell.EditedFormattedValue.ToString());
        }

        private void dgvDetail_EditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
        {
            int colIndex = dgvDetail.CurrentCell.ColumnIndex;

            if (colIndex == 4)
            {
                //TextBox tbCode = (TextBox)e.Control;
                //tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                //tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                //tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                //DataGridViewTextBoxEditingControl tb = (DataGridViewTextBoxEditingControl)e.Control;
                //tb.KeyPress += new KeyPressEventHandler(dataGridViewTextBox_KeyPress);
                //e.Control.KeyPress += new KeyPressEventHandler(dataGridViewTextBox_KeyPress);
            }
            //else
            //{
            //    //TextBox tbCode = (TextBox)e.Control;
            //    //tbCode.AutoCompleteMode = AutoCompleteMode.None;
            //}
        }

        //private void dataGridViewTextBox_KeyPress(object sender, KeyPressEventArgs e)
        //{
        //    //when i press enter,bellow code never run?
        //    if (e.KeyChar == (char)Keys.Enter)
        //    {
        //        MessageBox.Show(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
        //    }
        //}

        private void dgvDetail_KeyPress(object sender, KeyPressEventArgs e)
        {
            if (e.KeyChar == (char)Keys.F1)
            {
                MessageBox.Show(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
            }
        }

        private void dgvDetail_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                MessageBox.Show(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
            }
        }

        private void dgvDetail_PreviewKeyDown(object sender, PreviewKeyDownEventArgs e)
        {
            if (e.KeyCode == Keys.F1)
            {
                MessageBox.Show(dgvDetail.CurrentCell.EditedFormattedValue.ToString());
            }
        }

        private void textBox5_KeyDown(object sender, KeyEventArgs e)
        {

        }

        private void frm_SalesOrder_Load(object sender, EventArgs e)
        {
            //this.KeyPreview = true;
            //dtpDate.MinDate = Transaction.MinDate;
            //dtpDate.MaxDate = Transaction.MaxDate;

            cbLocation.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cbLocation.DisplayMember = "Name";
            cbLocation.ValueMember = "ID";
            cbLocation.SelectedValue = 1;

            cbPayment.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From PaymentType where isnull(Deleted,0) <> 1 order by Name");
            cbPayment.DisplayMember = "Name";
            cbPayment.ValueMember = "ID";
            cbPayment.SelectedValue = 2;

            cbCustomer.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Customer where isnull(Deleted,0) <> 1 and isnull(InActive,0) <>1 order by Short");
            cbCustomer.DisplayMember = "Name";
            cbCustomer.ValueMember = "ID";
            cbCustomer.SelectedValue = 17;

            cbAccount.DataSource = DBConnection.GetSQLTable("select * from dbo.GetSalesPaymentAccount(-1)");
            cbAccount.DisplayMember = "Name";
            cbAccount.ValueMember = "ID";
            cbAccount.SelectedValue = 37;

            cbTransport.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID,Name = Short + ' - '+ Name From Transport where isnull(Deleted,0) <> 1 order by Name");
            cbTransport.DisplayMember = "Name";
            cbTransport.ValueMember = "ID";
            cbTransport.SelectedValue = -1;

            cbGate.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID,Name = Short + ' - '+ Name From Gates where isnull(Deleted,0) <> 1  order by Name");
            cbGate.DisplayMember = "Name";
            cbGate.ValueMember = "ID";
            cbGate.SelectedValue = -1;

            cbCar.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID,Name = Short + ' - '+ Name From Cars where isnull(Deleted,0) <> 1  order by Name");
            cbCar.DisplayMember = "Name";
            cbCar.ValueMember = "ID";
            cbCar.SelectedValue = -1;

            dtHead = new DataTable();

            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                this.Text = "Sales Entry";
                // Prefer IsBankCharges when column exists (run SaleHead_IsBankCharges.sql first)
                try
                {
                    sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, SaleID, LocationID, CustomerID,  PaymentID, AccountID, OrderID,  AdvBalance, AdvAmount,  Balance, Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, Remark, TransportID, GateID, CarID,  UserID, EditDate, IsBankCharges = ISNULL(IsBankCharges,0) From SaleHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                    // Probe schema once
                    using (var tmp = new DataTable())
                    {
                        sdaHead.FillSchema(tmp, SchemaType.Source);
                    }
                }
                catch
                {
                    sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, SaleID, LocationID, CustomerID,  PaymentID, AccountID, OrderID,  AdvBalance, AdvAmount,  Balance, Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, Remark, TransportID, GateID, CarID,  UserID, EditDate From SaleHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                }
                sdaHead.Fill(dtHead);
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                this.Text = "Sales Order Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, SaleID, LocationID, CustomerID,  PaymentID, AccountID, OrderID, Balance, Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, Remark, TransportID, GateID, CarID, UserID, EditDate, AdvAmount From SaleOrderHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);

                lbOrder.Visible = false;
                cbOrder.Visible = false;
                //lbPayment.Visible = false;
                //cbPayment.Visible = false;
                //lbAccount.Visible = false;
                //cbAccount.Visible = false;
                lbTransport.Visible = false;
                cbTransport.Visible = false;
                lbGate.Visible = false;
                cbGate.Visible = false;
                lbCar.Visible = false;
                cbCar.Visible = false;
                chkTax.Visible = false;
                chkBankCharges.Visible = false;
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
                lbAdvance.Visible = false;
                tbAdvance.Visible = false;

            }
            else if (LocalData.Menu == LocalData.myMenu.SaleReturn)
            {
                this.Text = "Sales Return Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, SaleRefID, LocationID, CustomerID,  PaymentID, AccountID, Balance, Amount, Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, Remark, TransportID, GateID, CarID, UserID, EditDate From SaleReturnHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);

                lbOrder.Visible = false;
                cbOrder.Visible = false;
                //lbPayment.Visible = false;
                //cbPayment.Visible = false;
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                lbTransport.Visible = false;
                cbTransport.Visible = false;
                lbGate.Visible = false;
                cbGate.Visible = false;
                lbCar.Visible = false;
                cbCar.Visible = false;
                chkTax.Visible = false;
                chkBankCharges.Visible = false;
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

            }
            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                //dtHead.Rows[0]["DueDate"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                //dtHead.Rows[0]["DocumentID"] = DBConnection.rExecSQL("Select dbo.GetInvoice(" + ((int)LocalData.Menu).ToString() + ")");
                dtHead.Rows[0]["CustomerID"] = 1;
                dtHead.Rows[0]["LocationID"] = 1;
                dtHead.Rows[0]["PaymentID"] = 1;
                //dtHead.Rows[0]["AccountID"] = 1;
                //dtHead.Rows[0]["AccountID"] = 1;
                dtHead.Rows[0]["TransportID"] = -1;
                dtHead.Rows[0]["GateID"] = -1;
                dtHead.Rows[0]["CarID"] = -1;
                dtHead.Rows[0]["Amount"] = 0;
                dtHead.Rows[0]["UserID"] = LocalData.UserID;
                if (dtHead.Columns.Contains("IsBankCharges"))
                    dtHead.Rows[0]["IsBankCharges"] = false;
                customerHardcodeApplied = false;

            }
            else
            {
                int i, CustID;
                int.TryParse(dtHead.Rows[0]["CustomerID"].ToString(), out CustID);
                tbPhone.Text = DBConnection.rExecSQL("Select isnull(Info2,'') From Customer Where ID = " + CustID.ToString());
                tbAddress.Text = DBConnection.rExecSQL("Select isnull(Address,'') From Customer Where ID = " + CustID.ToString());

                int.TryParse(dtHead.Rows[0]["PaymentID"].ToString(), out i);
                if (LocalData.Menu == LocalData.myMenu.SaleOrder)
                {
                    //int payid;
                    //int.TryParse(cbPayment.SelectedValue.ToString(), out payid);
                    if (i == 2 || i == 5)
                    {
                        lbAdvance.Visible = false;
                        tbAdvance.Visible = false;
                    }
                    else
                    {
                        lbAdvance.Visible = true;
                        tbAdvance.Visible = true;
                    }
                }

                int.TryParse(dtHead.Rows[0]["PaymentID"].ToString(), out i);
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();

                DBConnection.ExecSQL("Insert into VoucherEditing(MenuID, TranID, UserID) Select " + (int)  LocalData.Menu + ","  + ID + "," + LocalData.UserID);
                Boolean allow;
                Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserPermission(" + LocalData.UserID.ToString() + ",2," + ((int)LocalData.Menu).ToString() + ",1)").ToString(), out allow);
                saveToolStripMenuItem.Visible = allow;
                saveToolStripMenuItem.Enabled = allow;
                btSave.Enabled = allow;

            }
            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");

            cbLocation.DataBindings.Add("SelectedValue", dtHead, "LocationID");
            cbPayment.DataBindings.Add("SelectedValue", dtHead, "PaymentID");
            cbCustomer.DataBindings.Add("SelectedValue", dtHead, "CustomerID");
            if (LocalData.Menu != LocalData.myMenu.SaleReturn)
            {
                cbOrder.DataBindings.Add("SelectedValue", dtHead, "OrderID");
                tbSaleID.DataBindings.Add("Text", dtHead, "SaleID");
            }            
            cbAccount.DataBindings.Add("SelectedValue", dtHead, "AccountID");
            cbTransport.DataBindings.Add("SelectedValue", dtHead, "TransportID");
            cbGate.DataBindings.Add("SelectedValue", dtHead, "GateID");
            cbCar.DataBindings.Add("SelectedValue", dtHead, "CarID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbCreditBalance.DataBindings.Add("Text", dtHead, "Balance");
            tbAmount.DataBindings.Add("Text", dtHead, "Amount");
            tbDiscount.DataBindings.Add("Text", dtHead, "Discount");
            tbNetAmount.DataBindings.Add("Text", dtHead, "NetAmount");
            tbTax.DataBindings.Add("Text", dtHead, "TaxAmount");
            tbCharges.DataBindings.Add("Text", dtHead, "AddAmount");
            tbTotalAmount.DataBindings.Add("Text", dtHead, "TotalAmount");
            tbPaidAmount.DataBindings.Add("Text", dtHead, "PaidAmount");
            tbNetBalance.DataBindings.Add("Text", dtHead, "TotalBalance");

            if (LocalData.Menu == LocalData.myMenu.Sale && dtHead.Columns.Contains("IsBankCharges"))
            {
                bool isBc = false;
                Boolean.TryParse(dtHead.Rows[0]["IsBankCharges"].ToString(), out isBc);
                decimal savedFee = 0;
                decimal.TryParse(dtHead.Rows[0]["AddAmount"].ToString(), out savedFee);
                suppressBankChargesRecalc = true;
                chkBankCharges.Checked = isBc || savedFee != 0;
                suppressBankChargesRecalc = false;
                chkBankCharges.Visible = true;
            }
            else
            {
                chkBankCharges.Visible = LocalData.Menu == LocalData.myMenu.Sale;
            }

            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                tbAdvance.DataBindings.Add("Text", dtHead, "AdvBalance");
                //tbSaleID.DataBindings.Add("Text", dtHead, "SaleID");
                //cbOrder.DataBindings.Add("SelectedValue", dtHead, "OrderID");
                //cbQR.DataBindings.Add("SelectedValue", dtHead, "QRID");
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                tbAdvance.DataBindings.Add("Text", dtHead, "AdvAmount");
            }

            FillDataGridView();

            decimal dis, paid;
            decimal.TryParse(tbDiscount.Text.ToString(), out dis);
            decimal.TryParse(tbPaidAmount.Text.ToString(), out paid);
            tbDiscount.Text = dis.ToString("#,##0");
            tbPaidAmount.Text = paid.ToString("#,##0");
            if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleReturn)
                CalculateNetAmount();

            // Edit/open: if customer is QR Pay Customer, lock Payment+Account
            if (LocalData.Menu == LocalData.myMenu.Sale && ID > 0)
            {
                int qrCustId = 0;
                int.TryParse(Convert.ToString(dtHead.Rows[0]["CustomerID"]), out qrCustId);
                TryLockQrCustomerPaymentAccount(qrCustId);
            }

            cbCustomer.Focus();
           
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
                            dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
                            //dgvDetail.CurrentRow.Cells["Price"].Value = frm_CodeList.SalePrice;
                            dgvDetail.CurrentRow.Cells["Unit"].Value = i;
                            //dgvDetail.CurrentRow.Cells["PrintCharge"].Value = frm_CodeList.Print;
                            //dgvDetail.CurrentRow.Cells["Weight"].Value = frm_CodeList.Weight;
                            dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Brand"];
                        }

                    }

                }

                return true;    // indicate that you handled this keystroke
            }
            else if (keyData == Keys.Enter)
            {
                if (dgvDetail.Focused)
                {

                    if (dgvDetail.CurrentCell.ColumnIndex == 15)
                    {
                        SendKeys.Send("{TAB}");
                        SendKeys.Send("{TAB}");
                        return true;

                    }
                    else
                    {
                        SendKeys.Send("{TAB}");
                        return true;
                    }
                }
                else
                {
                    SendKeys.Send("{TAB}");
                    return true;
                }

            }
            else if (keyData==Keys.F2)
            {
                tbDiscount.Focus();
                return true;
            }
            else if (keyData == Keys.F3)
            {
                tbPaidAmount.Focus();
                return true;
            }
            else if (keyData == Keys.Left )
            {                
                SendKeys.Send("+{TAB}");
                return true;
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            int UnitID, Discount, Qty1, Qty2;
            decimal Weight, Qty, TotalWeight, Price;
            string Code;
            int GateID;

            if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleReturn)
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
                            dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
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

                        decimal _qty;
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out _qty);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * _qty;
                        //dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.CurrentRow.Index].Cells["Qty"];

                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        if (codeid == 9950)
                        {
                            int.TryParse(cbGate.SelectedValue.ToString(), out GateID);
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select dbo.GetGateCharges( " + GateID + ")");
                            dgvDetail.CurrentRow.Cells["Weight"].Value = 0;
                        }
                        else if (codeid > 0)
                        {
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

                        }
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);

                        break;
                    case 9:
                    case 10:
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        if (codeid == 9950)
                        {
                            int.TryParse(cbGate.SelectedValue.ToString(), out GateID);
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select dbo.GetGateCharges( " + GateID + ")");
                            dgvDetail.CurrentRow.Cells["Weight"].Value = 0;
                        }
                        else if(codeid > 0)
                        {
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
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
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
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
                            dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
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
                        decimal _qty;
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out _qty);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * _qty;
                        break;
                    case 10:
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetMinQty(" + codeid.ToString() + "," + UnitID.ToString() + ",1)").ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["MinQty"].Value = Weight;
                        dgvDetail.CurrentRow.Cells["TotalMinQty"].Value = Weight * Qty;
                        dgvDetail.CurrentRow.Cells["Remark"].Value = DBConnection.rExecSQL("Select dbo.GetOrderDetailRemark(" + codeid.ToString() + "," + UnitID.ToString() + "," + Qty.ToString() + ")");
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);

                        break;
                    case 9:
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
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

        }

        private void dgvDetail_UserAddedRow(object sender, DataGridViewRowEventArgs e)
        {
            int LocID;
            dgvDetail.CurrentRow.Cells["Sr"].Value = e.Row.Index;
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                int.TryParse(cbLocation.SelectedValue.ToString(), out LocID);
                dgvDetail.CurrentRow.Cells["Loc"].Value = LocID;
            }
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

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            CalculateNetAmount();
        }

        private void CalculateNetAmount()
        {
            decimal NetAmount, amount, discount, tax, charges, TotalAmount, TotalWeight, PaidAmount, BalanceAmount, AdvBalance, AdvAmount;
            decimal Qty;
            int Pkg;


            if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleReturn)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);

                tbAmount.Text = amount.ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out Qty);
                tbTotalQty.Text = Qty.ToString("#,##0.#0");
                int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out Pkg);
                tbTotalPkg.Text = Pkg.ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
                tbTotalWeight.Text = TotalWeight.ToString("#.##0");

                decimal.TryParse(tbAdvance.Text.ToString(), out AdvBalance);
                decimal.TryParse(tbCreditBalance.Text.ToString(), out BalanceAmount);
                decimal.TryParse(tbDiscount.Text.ToString(), out discount);
                tbNetAmount.Text = (amount - discount).ToString("#,##0");
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
                if (LocalData.Menu == LocalData.myMenu.Sale)
                {
                    if (AdvBalance >= amount)
                    {
                        dtHead.Rows[0]["AdvAmount"] = amount;
                    }
                    else
                    {
                        dtHead.Rows[0]["AdvAmount"] = AdvBalance;
                    }


                    if (LocalData.Menu == LocalData.myMenu.Sale)
                    {
                        ApplyBankChargesFee(amount, discount);
                    }



                }
                decimal.TryParse(tbTax.Text.ToString(), out tax);
                decimal.TryParse(tbCharges.Text.ToString(), out charges);
                decimal.TryParse(tbPaidAmount.Text.ToString(), out PaidAmount);
                dtHead.Rows[0]["TaxAmount"] = tax;
                dtHead.Rows[0]["AddAmount"] = charges;
                dtHead.Rows[0]["PaidAmount"] = PaidAmount;
                if (dtHead.Columns.Contains("IsBankCharges") && LocalData.Menu == LocalData.myMenu.Sale)
                    dtHead.Rows[0]["IsBankCharges"] = chkBankCharges.Checked;
                tbTotalAmount.Text = (amount - discount + tax + charges).ToString("#,##0");
                tbNetBalance.Text = (BalanceAmount + amount - discount + tax + charges - PaidAmount - AdvBalance).ToString("#,##0");
                // Persist goods net only in TotalAmount (fee stays in AddAmount)
                dtHead.Rows[0]["TotalAmount"] = amount - discount + tax;
                dtHead.Rows[0]["TotalBalance"] = BalanceAmount + amount - discount + tax + charges - PaidAmount - AdvBalance;
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
                dtHead.Rows[0]["Amount"] = amount;
                tbAmount.Text = amount.ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out Qty);
                tbTotalQty.Text = Qty.ToString("#,##0");
                int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out Pkg);
                tbTotalPkg.Text = Pkg.ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(TotalMinQty)", "").ToString(), out TotalWeight);
                tbTotalWeight.Text = TotalWeight.ToString("#.##0");

                decimal.TryParse(tbCreditBalance.Text.ToString(), out BalanceAmount);
                decimal.TryParse(tbDiscount.Text.ToString(), out discount);
                tbNetAmount.Text = (amount - discount).ToString("#,##0");
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
                dtHead.Rows[0]["AddAmount"] = charges;
                dtHead.Rows[0]["PaidAmount"] = PaidAmount;
                tbTotalAmount.Text = (amount - discount + tax + charges).ToString("#,##0");
                tbNetBalance.Text = (BalanceAmount + amount - discount + tax + charges - PaidAmount).ToString("#,##0");
                dtHead.Rows[0]["TotalAmount"] = amount - discount + tax;
                dtHead.Rows[0]["TotalBalance"] = BalanceAmount + amount - discount + tax + charges - PaidAmount;
            }

        }

        /// <summary>
        /// Bank fee % from AccountName.BankCharges (0 if not set).
        /// </summary>
        private static void GetAccountBankChargeRate(int accountId, out decimal bankPct, out int sysAcctId)
        {
            bankPct = 0;
            sysAcctId = 0;
            if (accountId <= 0)
                return;
            try
            {
                System.Data.DataTable dt = DBConnection.GetSQLTable(
                    "Select ISNULL(BankCharges,0) as BankCharges, ISNULL(SysAcctID,0) as SysAcctID From AccountName Where ID = " + accountId.ToString());
                if (dt != null && dt.Rows.Count > 0)
                {
                    decimal.TryParse(dt.Rows[0]["BankCharges"].ToString(), out bankPct);
                    int.TryParse(dt.Rows[0]["SysAcctID"].ToString(), out sysAcctId);
                }
            }
            catch
            {
                decimal.TryParse(DBConnection.roExecSQL("Select ISNULL(BankCharges,0) From AccountName Where ID = " + accountId.ToString()).ToString(), out bankPct);
            }
            // Unset / null BankCharges → 0% (no SysAcctID default)
        }

        private void ApplyBankChargesFee(decimal amount, decimal discount)
        {
            if (suppressBankChargesRecalc)
                return;

            // Only while checkbox is visible + checked (Sale menu)
            if (!chkBankCharges.Visible || !chkBankCharges.Checked)
            {
                tbCharges.Text = "0";
                chg_percnet = 0;
                return;
            }

            int acctid = 0;
            if (cbAccount.SelectedValue != null)
                int.TryParse(cbAccount.SelectedValue.ToString(), out acctid);

            decimal accountBankPct = 0;
            int sysAcctId = 0;
            if (acctid > 0)
                GetAccountBankChargeRate(acctid, out accountBankPct, out sysAcctId);

            // Edit + Account.BankCharges = 0 → keep saved AddAmount (do not wipe)
            if (ID > 0 && accountBankPct == 0)
            {
                decimal saved = 0;
                decimal.TryParse(tbCharges.Text.ToString(), out saved);
                if (saved == 0 && dtHead != null && dtHead.Rows.Count > 0)
                    decimal.TryParse(dtHead.Rows[0]["AddAmount"].ToString(), out saved);
                tbCharges.Text = saved.ToString();
                chg_percnet = 0;
                return;
            }

            chg_percnet = accountBankPct;
            // SB formula (unchanged): net / ((100 - %) / 100) - net  when 0 < % < 100
            // Equivalent: fee = net * % / (100 - %)
            decimal net = amount - discount;
            if (chg_percnet > 0 && chg_percnet < 100 && net != 0)
            {
                decimal denom = (100m - chg_percnet) / 100m;
                decimal fee = (net / denom) - net;
                tbCharges.Text = Math.Round(fee, 0, MidpointRounding.AwayFromZero).ToString();
            }
            else if (ID <= 0)
                tbCharges.Text = "0";
        }

        private void chkBankCharges_CheckedChanged(object sender, EventArgs e)
        {
            if (suppressBankChargesRecalc)
                return;
            if (dtHead != null && dtHead.Rows.Count > 0 && dtHead.Columns.Contains("IsBankCharges"))
                dtHead.Rows[0]["IsBankCharges"] = chkBankCharges.Checked;
            CalculateNetAmount();
        }

        private void chkTax_CheckedChanged(object sender, EventArgs e)
        {
            CalculateNetAmount();
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }
            if (!Transaction.CheckLogDay(dtpDate.Value))
            {
                MessageBox.Show("This date is over Log Date!. Cannot Save Data.");
            }
            else
            {
                Save();
                frm_SalesOrder_Load(sender, e);
            }

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

            if (cbCustomer.SelectedValue == null)
            {
                cbCustomer.Focus();
                erptransaction.SetError(cbCustomer, "Select Customer!");
                return;
            }

            
           

            //dgvDetail.RefreshEdit();
            //dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.NewRowIndex].Cells["Code"];


            DateTime e_Date;

            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));
            dtHead.Rows[0]["Date"] = dtpDate.Value.Date + e_Date.TimeOfDay;
            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            // Sales edit audit (line Add/Update/Delete only) — before Update so Original values remain
            if (LocalData.Menu == LocalData.myMenu.Sale && ID > 0)
            {
                try
                {
                    SaleAuditLog.LogSaleEdit(ID, dtHead.Rows[0], dtDetail);
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Sale audit log failed (save continues): " + ex.Message);
                }
            }

            scb = new SqlCommandBuilder(sdaHead);
            sdaHead.Update(dtHead);


            if (ID <= 0)
            {
                if (LocalData.Menu == LocalData.myMenu.Sale)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from SaleHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.Sale, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from SaleOrderHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.SaleOrder, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.SaleReturn)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from SaleReturnHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.SaleOrder, dtpDate.Value);
                }


            }
            else
            {
                DBConnection.ExecSQL("Delete VoucherEditing Where MenuID = " + (int)LocalData.Menu + " and  TranID = " + ID + " and  UserID = " + LocalData.UserID);
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

            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark, OrderRefID, LocID from SaleDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Price, Amount, MinQty, TotalMinQty, Qty1, Qty2, Remark from SaleOrderDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleReturn)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Weight, Price, TotalWeight, Amount, Qty1, Qty2, Remark, SaleRefID from SaleReturnDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            scb = new SqlCommandBuilder(sdaDetail);
            sdaDetail.Update(dtDetail);

            UpdateSalePrice(dtDetail);

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
            cbPayment.DataBindings.Clear();
            cbCustomer.DataBindings.Clear();
            if (LocalData.Menu != LocalData.myMenu.SaleReturn)
            {
                cbOrder.DataBindings.Clear();
                tbSaleID.DataBindings.Clear();
            }
            cbAccount.DataBindings.Clear();
            cbTransport.DataBindings.Clear();
            cbGate.DataBindings.Clear();
            cbCar.DataBindings.Clear();
            tbRemark.DataBindings.Clear();
            tbCreditBalance.DataBindings.Clear();
            tbAmount.DataBindings.Clear();
            tbDiscount.DataBindings.Clear();
            tbNetAmount.DataBindings.Clear();
            tbTax.DataBindings.Clear();
            tbCharges.DataBindings.Clear();
            tbTotalAmount.DataBindings.Clear();
            tbPaidAmount.DataBindings.Clear();
            tbNetBalance.DataBindings.Clear();
            if (LocalData.Menu == LocalData.myMenu.Sale|| LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                tbAdvance.DataBindings.Clear();
                //cbOrder.DataBindings.Clear();
                //tbSaleID.DataBindings.Clear();
                //cbQR.DataBindings.Clear();

            }

            ID = 0;
            
        }

        private void UpdateSalePrice(DataTable dt)
        {
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                foreach (DataRow dRow in dt.Rows)
                {
                    if (dRow["CodeID"].ToString() != "")
                    {
                        DBConnection.ExecSQL("Update StockDetail Set SalePrice = " + dRow["Price"].ToString() + " Where StockID =" + dRow["CodeID"].ToString() + " and UnitID = " + dRow["UnitID"].ToString());
                    }
                }
            }

        
        }

        private void cbLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbLocation.DroppedDown = true;
            LocalData.AutoComplete(cbLocation, e, true);
        }

        private void cbCustomer_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbCustomer.DroppedDown = true;
            LocalData.AutoComplete(cbCustomer, e, true);
        }

        private void cbCustomer_DropDownClosed(object sender, EventArgs e)
        {
            decimal Opn;
            Boolean AllowCredit;
            int CustID;

            if (cbCustomer.SelectedValue == null)
                return;

            int.TryParse(cbCustomer.SelectedValue.ToString(), out CustID);
            dtHead.Rows[0]["CustomerID"] = cbCustomer.SelectedValue;

            cbOrder.DataSource = DBConnection.GetSQLTable("Select ID = Max(RefID), Name = Short + '-' + Customer + '  ['+ Format(Date,'dd/MM/yyyy') + ']' + '-' + isnull(AutoID,'')  From dbo.GetSaleOrderBalSales(" + cbCustomer.SelectedValue.ToString() + ") Group By  AutoID, Short, Customer, Date order by Short");
            cbOrder.DisplayMember = "Name";
            cbOrder.ValueMember = "ID";
            cbOrder.SelectedValue = 0;

            string custShort = "";
            string custName = "";
            try { custShort = Convert.ToString(DBConnection.rExecSQL("Select ISNULL(Short,'') From Customer Where ID = " + CustID.ToString())); }
            catch { custShort = ""; }
            try { custName = Convert.ToString(DBConnection.rExecSQL("Select ISNULL(Name,'') From Customer Where ID = " + CustID.ToString())); }
            catch { custName = ""; }
            string shortUpper = (custShort ?? "").ToUpperInvariant();
            string nameUpper = (custName ?? "").ToUpperInvariant();
            // QR Pay Customer only (Short = QR) — do not match KBZQ
            bool isQrCustomer = shortUpper == "QR" || nameUpper.Contains("QR PAY");
            bool isKbzq = CustID == 6444 || shortUpper.Contains("KBZQ");
            bool isAyassa = CustID == 2756 || shortUpper.Contains("AYASSA") || shortUpper.Contains("AYARWADDY") || shortUpper.Contains("AYA ");

            Boolean.TryParse(DBConnection.rExecSQL("Select AllowCredit From Customer Where ID = " + cbCustomer.SelectedValue.ToString()).ToString(), out AllowCredit);

            // QR customer: always force Banking + MMQR account and lock both (Sale only)
            if (LocalData.Menu == LocalData.myMenu.Sale && isQrCustomer)
            {
                TryLockQrCustomerPaymentAccount(CustID);
            }
            // KBZQ / ayassa hardcode: new invoice, first customer pick (works even when Payment combo disabled)
            else
            {
                bool applyHardcode = LocalData.Menu == LocalData.myMenu.Sale && ID <= 0 && !customerHardcodeApplied;

                if (!AllowCredit)
                {
                    if (applyHardcode && isKbzq)
                    {
                        ApplyHardcodedPaymentAccount(4, 1482, disablePayment: true, disableAccount: true);
                        customerHardcodeApplied = true;
                    }
                    else if (applyHardcode && isAyassa)
                    {
                        ApplyHardcodedPaymentAccount(3, 436, disablePayment: true, disableAccount: false);
                        customerHardcodeApplied = true;
                    }
                    else
                    {
                        cbPayment.Enabled = false;
                        cbPayment.SelectedValue = 1;
                        dtHead.Rows[0]["PaymentID"] = 1;
                        cbAccount.SelectedValue = 288;
                        dtHead.Rows[0]["AccountID"] = 288;
                        ChangeAccount();
                    }
                }
                else
                {
                    cbPayment.Enabled = true;
                    if (applyHardcode && isKbzq)
                    {
                        ApplyHardcodedPaymentAccount(4, 1482, disablePayment: true, disableAccount: true);
                        customerHardcodeApplied = true;
                    }
                    else if (applyHardcode && isAyassa)
                    {
                        ApplyHardcodedPaymentAccount(3, 436, disablePayment: true, disableAccount: false);
                        customerHardcodeApplied = true;
                    }
                    else
                    {
                        cbPayment.SelectedValue = 2;
                        dtHead.Rows[0]["PaymentID"] = 2;
                        ChangeAccount();
                    }
                }
            } // end non-QR
            tbPhone.Text = DBConnection.rExecSQL("Select Info1 From Customer Where ID = " + cbCustomer.SelectedValue.ToString());
            tbPansar.Text = DBConnection.rExecSQL("Select Info2 From Customer Where ID = " + cbCustomer.SelectedValue.ToString());
            tbAddress.Text = DBConnection.rExecSQL("Select Address From Customer Where ID = " + cbCustomer.SelectedValue.ToString());
            decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetCustomerBalance( " + cbCustomer.SelectedValue.ToString() + ")").ToString(), out Opn);
            tbCreditBalance.Text = Opn.ToString();
            dtHead.Rows[0]["Balance"] = Opn;
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetCustomerAdvance( " + cbCustomer.SelectedValue.ToString() + ")").ToString(), out Opn);
                tbAdvance.Text = Opn.ToString(LocalData.IntegerFormat);
                //dtHead.Rows[0]["AdvAmount"] = Opn;
                dtHead.Rows[0]["AdvBalance"] = Opn;
            }
            CalculateNetAmount();
            cbOrder.Focus();
        }

        /// <summary>Resolve AccountName.ID by Short (exact preferred) or name/short contains token.</summary>
        private static int ResolveAccountIdByShort(string exactShort, string containsToken)
        {
            try
            {
                string sql = "Select TOP 1 ID From AccountName Where ISNULL(Deleted,0)<>1 AND ("
                    + "UPPER(Short) = '" + (exactShort ?? "").Replace("'", "''").ToUpperInvariant() + "'";
                if (!string.IsNullOrWhiteSpace(containsToken))
                {
                    string tok = containsToken.Replace("'", "''");
                    sql += " OR Short LIKE '%" + tok + "%' OR Name LIKE '%" + tok + "%'";
                }
                sql += ") ORDER BY CASE WHEN UPPER(Short) = '" + (exactShort ?? "").Replace("'", "''").ToUpperInvariant()
                    + "' THEN 0 ELSE 1 END, ID";
                int id;
                int.TryParse(Convert.ToString(DBConnection.rExecSQL(sql)), out id);
                return id;
            }
            catch
            {
                return 0;
            }
        }

        /// <summary>
        /// Force Payment+Account even when combos are disabled (QR / KBZQ / ayassa).
        /// </summary>
        private void ApplyHardcodedPaymentAccount(int paymentId, int accountId, bool disablePayment, bool disableAccount)
        {
            // Load account list that includes the target account before assigning SelectedValue
            if (paymentId == 4)
            {
                cbAccount.DataSource = DBConnection.GetSQLTable("Select ID , Name = Short + '-' + Name  From AccountName Where SysAcctID IN (2,6) and isnull(Deleted,0)<>1 order by Short");
                cbAccount.DisplayMember = "Name";
                cbAccount.ValueMember = "ID";
            }
            else if (paymentId == 3)
            {
                cbAccount.DataSource = DBConnection.GetSQLTable("Select ID , Name = Short + '-' + Name  From AccountName Where SysAcctID = 6 and isnull(Deleted,0)<>1 order by Short");
                cbAccount.DisplayMember = "Name";
                cbAccount.ValueMember = "ID";
            }

            cbPayment.SelectedValue = paymentId;
            dtHead.Rows[0]["PaymentID"] = paymentId;
            cbAccount.SelectedValue = accountId;
            dtHead.Rows[0]["AccountID"] = accountId;
            cbPayment.Enabled = !disablePayment;
            cbAccount.Enabled = !disableAccount;
            RefreshBankChargesPercentFromAccount();
        }

        private void FillOrder()
        {
            DateTime tmp;
            string st;

            tmp = Convert.ToDateTime(DBConnection.rExecSQL("Select Date From dbo.GetSaleOrderBalSales(" + cbCustomer.SelectedValue.ToString() + ") Where RefID = " + cbOrder.SelectedValue.ToString()));
            st = DBConnection.rExecSQL("Select AutoID From dbo.GetSaleOrderBalSales(" + cbCustomer.SelectedValue.ToString() + ") Where RefID = " + cbOrder.SelectedValue.ToString()).ToString();
            dtDetail.Rows.Clear();
            DataTable dtfill;
            dtfill = new DataTable();
            dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, B.Qty1, B.Qty2,  B.Price, B.Weight, S.Short, S.Name, B.Remark  From dbo.GetSaleOrderBalSales(" + cbCustomer.SelectedValue.ToString() + ") B Join Stock S on B.CodeID = S.ID Where Date = '" + tmp.ToString("yyyy-MM-dd") + "' and AutoID ='" + st.ToString() + "' Order by Sr");
            DataRow dtNrow;
            int i = 0, LocID = 1;
            decimal qty, price;
            int.TryParse(cbLocation.SelectedValue.ToString(), out LocID);
            foreach (DataRow row in dtfill.Rows)
            {
                dtNrow = dtDetail.NewRow();
                dtNrow["Sr"] = ++i;
                dtNrow["OrderRefID"] = row["RefID"];
                dtNrow["CodeID"] = row["CodeID"];
                dtNrow["Code"] = row["Short"];
                dtNrow["Name"] = row["Name"];
                dtNrow["UnitID"] = row["UnitID"];
                dtNrow["BrandID"] = row["BrandID"];
                dtNrow["Qty"] = row["Qty"];
                dtNrow["Qty1"] = row["Qty1"];
                dtNrow["Qty2"] = row["Qty2"];
                dtNrow["Price"] = row["Price"];
                dtNrow["Weight"] = row["Weight"];
                decimal.TryParse(row["Qty"].ToString(), out qty);
                decimal.TryParse(row["Price"].ToString(), out price);
                dtNrow["Amount"] = qty * price;
                dtNrow["Remark"] = row["Remark"];
                dtNrow["LocID"] = LocID;
                dtDetail.Rows.Add(dtNrow);

            }

        }

        /// <summary>QR Pay Customer only: force Banking + MMQR and lock Payment/Account.</summary>
        private void TryLockQrCustomerPaymentAccount(int custId)
        {
            if (LocalData.Menu != LocalData.myMenu.Sale || custId <= 0)
                return;
            string custShort = "";
            string custName = "";
            try { custShort = Convert.ToString(DBConnection.rExecSQL("Select ISNULL(Short,'') From Customer Where ID = " + custId.ToString())); }
            catch { custShort = ""; }
            try { custName = Convert.ToString(DBConnection.rExecSQL("Select ISNULL(Name,'') From Customer Where ID = " + custId.ToString())); }
            catch { custName = ""; }
            string shortUpper = (custShort ?? "").ToUpperInvariant();
            string nameUpper = (custName ?? "").ToUpperInvariant();
            // Short = QR only — do not match KBZQ
            if (shortUpper != "QR" && !nameUpper.Contains("QR PAY"))
                return;
            int qrAcctId = ResolveAccountIdByShort("ayarmmqr", "MMQR");
            if (qrAcctId <= 0)
                qrAcctId = 198;
            ApplyHardcodedPaymentAccount(4, qrAcctId, disablePayment: true, disableAccount: true);
        }

        private void cbCustomer_SelectionChangeCommitted(object sender, EventArgs e)
        {
            cbCustomer_DropDownClosed(sender, e);
        }

        private void cbPayment_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbPayment.DroppedDown = true;
            LocalData.AutoComplete(cbPayment, e, true);
        }

        private void cbAccount_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbAccount.DroppedDown = true;
            LocalData.AutoComplete(cbAccount, e, true);
        }

        private void cbTransport_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbTransport.DroppedDown = true;
            LocalData.AutoComplete(cbTransport, e, true);
        }

        private void cbGate_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbGate.DroppedDown = true;
            LocalData.AutoComplete(cbGate, e, true);
        }

        private void cbCar_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbCar.DroppedDown = true;
            LocalData.AutoComplete(cbCar, e, true);
        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Boolean allow;
            Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserPermission(" + LocalData.UserID.ToString() + ",2," + ((int)LocalData.Menu).ToString() + ",1)").ToString(), out allow);
            if (allow || ID <1)
            {
                Save();
            }
            else
            {
                PrintID = ID;

                //scb.Dispose();
                //sdaHead.Dispose();
                //sdaDetail.Dispose();
                dtHead.Dispose();
                dtDetail.Dispose();


                dtpDate.DataBindings.Clear();
                tbAutoID.DataBindings.Clear();
                tbDocumentID.DataBindings.Clear();

                cbLocation.DataBindings.Clear();
                cbPayment.DataBindings.Clear();
                cbCustomer.DataBindings.Clear();
                if (LocalData.Menu != LocalData.myMenu.SaleReturn)
                {
                    cbOrder.DataBindings.Clear();
                    tbSaleID.DataBindings.Clear();
                }
                cbAccount.DataBindings.Clear();
                cbTransport.DataBindings.Clear();
                cbGate.DataBindings.Clear();
                cbCar.DataBindings.Clear();
                tbRemark.DataBindings.Clear();
                tbCreditBalance.DataBindings.Clear();
                tbAmount.DataBindings.Clear();
                tbDiscount.DataBindings.Clear();
                tbNetAmount.DataBindings.Clear();
                tbTax.DataBindings.Clear();
                tbCharges.DataBindings.Clear();
                tbTotalAmount.DataBindings.Clear();
                tbPaidAmount.DataBindings.Clear();
                tbNetBalance.DataBindings.Clear();
                if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleOrder)
                {
                    tbAdvance.DataBindings.Clear();
                    //cbOrder.DataBindings.Clear();
                    //tbSaleID.DataBindings.Clear();
                    //cbQR.DataBindings.Clear();

                }
                DBConnection.ExecSQL("Delete VoucherEditing Where MenuID = " + (int)LocalData.Menu + " and  TranID = " + ID + " and  UserID = " + LocalData.UserID);
                ID = 0;
            }
            
            if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                frm = new frm_PrintSelect();
                if (frm.ShowDialog() == DialogResult.OK)
                {

                    frm_SalesOrder_Load(sender, e);
                }
            }
            else 
            {
                //ReportDocument rd;
                //rd = new ReportDocument();
                //PrintDocument localPrinter = new PrintDocument();
                ////rd.PrintOptions.PrinterName = "EPSON TM-U220 ReceiptE4";
                //rd.PrintOptions.PrinterName = localPrinter.PrinterSettings.PrinterName;
                //rd.FileName = Environment.CurrentDirectory + @"\Reports\OrderInvoice.rpt";
                //rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                //rd.SetDatabaseLogon("sa", "27042005@MND");
                //rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                //rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, TotalMinQty, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark from SaleOrderHead H Join SaleOrderDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID    Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                //rd.PrintToPrinter(2, false, 0, 0);
                frm = new frm_Preview(4);
                frm.ShowDialog();
            }

        }

        private void tbAmount_Validated(object sender, EventArgs e)
        {

        }

        private void tbAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbAmount);
        }

        private void tbDiscount_TextChanged(object sender, EventArgs e)
        {

        }

        private void tbCreditBalance_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbCreditBalance);
        }

        private void tbNetAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbNetAmount);
        }

        private void tbTax_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbTax);
        }

        private void tbCharges_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbCharges);
        }

        private void tbTotalAmount_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbTotalAmount);
        }

        private void tbPaidAmount_TextChanged(object sender, EventArgs e)
        {

        }

        private void tbNetBalance_TextChanged(object sender, EventArgs e)
        {
            LocalData.TextboxCurrencyFormat(tbNetBalance);
        }

        private void paidToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        private void tbDiscount_Validated(object sender, EventArgs e)
        {
            CalculateNetAmount();
            LocalData.TextboxCurrencyFormat(tbDiscount);
        }

        private void tbPaidAmount_Validated(object sender, EventArgs e)
        {
            CalculateNetAmount();
            LocalData.TextboxCurrencyFormat(tbPaidAmount);
        }

        private void codeListsToolStripMenuItem_Click_1(object sender, EventArgs e)
        {

        }

        private void cbPayment_DropDownClosed(object sender, EventArgs e)
        {
            dtHead.Rows[0]["PaymentID"] = cbPayment.SelectedValue;
            ChangeAccount();
            if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                int payid;
                int.TryParse(cbPayment.SelectedValue.ToString(), out payid);
                if (payid == 2 || payid == 5)
                {
                    lbAdvance.Visible = false;
                    tbAdvance.Visible = false;
                }
                else
                {
                    lbAdvance.Visible = true;
                    tbAdvance.Visible = true;
                }
            }

        }

        private void ChangeAccount()
        {
            int payid;
            int.TryParse(cbPayment.SelectedValue.ToString(), out payid);
            if (payid == 3)
            {
                cbAccount.DataSource = DBConnection.GetSQLTable("Select ID , Name = Short + '-' + Name  From AccountName Where SysAcctID = 6 and isnull(Deleted,0)<>1 order by Short");
                cbAccount.DisplayMember = "Name";
                cbAccount.ValueMember = "ID";
                cbAccount.SelectedValue = 436;

                dtHead.Rows[0]["AccountID"] = 436;
                cbAccount.Enabled = true;
            }
            else if (payid == 1)
            {

                dtHead.Rows[0]["AccountID"] = 288;
                cbAccount.SelectedValue = 288;
                cbAccount.Enabled = false;
            }
            else if (payid == 2)
            {
                // Credit: optional bank/cash account for Bank Charges (SysAcctID 2=bank, 6=cash)
                object prevAcct = dtHead.Rows[0]["AccountID"];
                cbAccount.DataSource = DBConnection.GetSQLTable("Select ID = 0, Name = ' - ' Union All Select ID , Name = Short + '-' + Name  From AccountName Where SysAcctID IN (2,6) and isnull(Deleted,0)<>1 order by ID");
                cbAccount.DisplayMember = "Name";
                cbAccount.ValueMember = "ID";
                int prevId = 0;
                int.TryParse(Convert.ToString(prevAcct), out prevId);
                if (prevId > 0)
                {
                    cbAccount.SelectedValue = prevId;
                    dtHead.Rows[0]["AccountID"] = prevId;
                }
                else
                {
                    cbAccount.SelectedValue = 0;
                    dtHead.Rows[0]["AccountID"] = 0;
                }
                cbAccount.Enabled = true;
            }
            else if (payid == 4)
            {
                cbAccount.DataSource = DBConnection.GetSQLTable("Select ID , Name = Short + '-' + Name  From AccountName Where SysAcctID = 2 and isnull(Deleted,0)<>1 order by Short");
                cbAccount.DisplayMember = "Name";
                cbAccount.ValueMember = "ID";
                cbAccount.SelectedValue = 198;

                dtHead.Rows[0]["AccountID"] = 198;
                cbAccount.Enabled = true;
            }

            RefreshBankChargesPercentFromAccount();
            CalculateNetAmount();
        }

        private void RefreshBankChargesPercentFromAccount()
        {
            chg_percnet = 0;
            if (cbAccount.SelectedValue == null)
                return;
            int acctid;
            int.TryParse(cbAccount.SelectedValue.ToString(), out acctid);
            int sysAcctId = 0;
            if (acctid > 0)
                GetAccountBankChargeRate(acctid, out chg_percnet, out sysAcctId);

            // New invoice: checkbox ON when Account.BankCharges > 0 (including Credit)
            if (LocalData.Menu == LocalData.myMenu.Sale && ID <= 0 && chg_percnet > 0 && !chkBankCharges.Checked)
            {
                suppressBankChargesRecalc = true;
                chkBankCharges.Checked = true;
                if (dtHead.Columns.Contains("IsBankCharges"))
                    dtHead.Rows[0]["IsBankCharges"] = true;
                suppressBankChargesRecalc = false;
            }
        }

        private void cbPayment_SelectionChangeCommitted(object sender, EventArgs e)
        {
            dtHead.Rows[0]["PaymentID"] = cbPayment.SelectedValue;
            ChangeAccount();
        }

        private void dtpDate_Validated(object sender, EventArgs e)
        {

        }

        private void dtpDate_ValueChanged(object sender, EventArgs e)
        {
            if (!Transaction.CheckLogDay(dtpDate.Value))
            {
                MessageBox.Show("Date not between allow date range!");
                return;
                
            }
            if (dtpDate.Value.Date < LocalData.SettingDate)
            {
                if (!LocalData.AllowBackDate)
                {
                    dtpDate.Value = LocalData.SettingDate.Date;
                    return;
                }
            }
        }

        private void cbOrder_DropDownClosed(object sender, EventArgs e)
        {
            FillOrder();
        }

        private void frm_SalesOrder_FormClosing(object sender, FormClosingEventArgs e)
        {

            DBConnection.ExecSQL("Delete VoucherEditing Where MenuID = "+ (int)LocalData.Menu+" and  TranID = " + ID + " and  UserID = " + LocalData.UserID );
        }

        private void btSave_Click(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click(sender, e);
        }

        private void btPrint_Click(object sender, EventArgs e)
        {
            printToolStripMenuItem_Click(sender, e);
        }

        private void cbAccount_DropDownClosed(object sender, EventArgs e)
        {
            if (cbAccount.SelectedValue != null)
            {
                dtHead.Rows[0]["AccountID"] = cbAccount.SelectedValue;
                RefreshBankChargesPercentFromAccount();
                CalculateNetAmount();
            }
        }

        private void cbAccount_SelectionChangeCommitted(object sender, EventArgs e)
        {
            if (cbAccount.SelectedValue != null)
            {
                dtHead.Rows[0]["AccountID"] = cbAccount.SelectedValue;
                RefreshBankChargesPercentFromAccount();
                CalculateNetAmount();
            }
        }

        private void cbLocation_DropDownClosed(object sender, EventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                int locid;
                int.TryParse(cbLocation.SelectedValue.ToString(), out locid);
                if (locid > 0)
                {
                    foreach (DataGridViewRow dr in dgvDetail.Rows)
                    {
                        dr.Cells["Loc"].Value = locid;
                    }
                }

            }
        }

        private void cbLocation_SelectionChangeCommitted(object sender, EventArgs e)
        {
            cbLocation_DropDownClosed(sender, e);
        }

        private void ChangeCellToCombox(int r_index)
        {
            if (isComboBox == false)
            {
                //int i;
                //int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + codeid.ToString()).ToString(), out i);
                DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                combocell.DataSource = DBConnection.GetTable("dbo.GetStockUnit("+codeid.ToString()+")", "");
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

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.Sale || LocalData.Menu == LocalData.myMenu.SaleReturn)
            {
                //if (e.ColumnIndex == 2 || e.ColumnIndex == 5 || e.ColumnIndex == 12 || e.ColumnIndex == 14)
                if (e.ColumnIndex == 2)
                {
                    //SendKeys.Send("{Tab}");
                }
                else if (e.ColumnIndex == 10)
                {
                    int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[3].Value.ToString(), out codeid);
                    SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox);
                    dgvDetail.BeginInvoke(cct, e.RowIndex);
                    isComboBox = false;

                }
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                if (e.ColumnIndex == 2 || e.ColumnIndex == 5 || e.ColumnIndex == 12)
                {
                    SendKeys.Send("{Tab}");
                }
                else if (e.ColumnIndex == 10)
                {
                    int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[3].Value.ToString(), out codeid);
                    SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox);
                    dgvDetail.BeginInvoke(cct, e.RowIndex);
                    isComboBox = false;
                }
            }

        }

        private void FillDataGridView()
        {

            //int.TryParse(cbSaleType.SelectedValue.ToString(),out SaleTypeID);

            dtDetail = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, OrderRefID, LocID From SaleDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Remark"].Visible = true;
                dgvDetail.Columns["OrderRefID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 120;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 300;
                dgvDetail.Columns["Qty1"].Width = 60;
                dgvDetail.Columns["Qty1"].HeaderText = "PK";
                dgvDetail.Columns["Qty2"].Width = 60;
                dgvDetail.Columns["Qty2"].HeaderText = "";
                dgvDetail.Columns["Qty"].Width = 70;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 120;
                dgvDetail.Columns["Weight"].Width = 70;
                dgvDetail.Columns["TotalWeight"].Width = 100;
                dgvDetail.Columns["Remark"].Width = 130;
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

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "Brand";
                BrandID.HeaderText = "Brand";
                BrandID.Width = 80;
                BrandID.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID, Name = Short From Brand");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("BrandID"))
                {
                    dgvDetail.Columns.Remove("BrandID");
                }
                else if (dgvDetail.Columns.Contains("Brand"))
                {
                    dgvDetail.Columns.Remove("Brand");
                }
                BrandID.DataPropertyName = "BrandID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Name"].Index + 1, BrandID);

                DataGridViewComboBoxColumn LocID = new DataGridViewComboBoxColumn();
                LocID.Name = "Loc";
                LocID.HeaderText = "Location";
                LocID.Width = 80;
                LocID.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short From Location Where isnull(Deleted,0)<>1 and TypeID = 1");
                LocID.ValueMember = "ID";
                LocID.DisplayMember = "Name";
                LocID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("LocID"))
                {
                    dgvDetail.Columns.Remove("LocID");
                }
                else if (dgvDetail.Columns.Contains("Loc"))
                {
                    dgvDetail.Columns.Remove("Loc");
                }
                LocID.DataPropertyName = "LocID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Remark"].Index + 1, LocID);


                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty2"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, MinQty, TotalMinQty, Remark From SaleOrderDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);
                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["MinQty"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 150;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 320;
                dgvDetail.Columns["TotalMinQty"].HeaderText = "Total Qty";
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Qty1"].Width = 60;
                dgvDetail.Columns["Qty1"].HeaderText = "PK";
                dgvDetail.Columns["Qty2"].Width = 60;
                dgvDetail.Columns["Qty2"].HeaderText = "";
                dgvDetail.Columns["Qty"].Width = 80;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty2"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Amount"].Width = 150;
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Remark"].Width = 170;
                dgvDetail.Columns["TotalMinQty"].Width = 120;
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

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "Brand";
                BrandID.HeaderText = "Brand";
                BrandID.Width = 80;
                BrandID.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID, Name = Short From Brand");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("BrandID"))
                {
                    dgvDetail.Columns.Remove("BrandID");
                }
                else if (dgvDetail.Columns.Contains("Brand"))
                {
                    dgvDetail.Columns.Remove("Brand");
                }
                BrandID.DataPropertyName = "BrandID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Name"].Index + 1, BrandID);


                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Remark"].ReadOnly = true;
                dgvDetail.Columns["TotalMinQty"].ReadOnly = true;
                dgvDetail.Columns["TotalMinQty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalMinQty"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleReturn)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, SaleRefID From SaleReturnDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Remark"].Visible = false;
                dgvDetail.Columns["SaleRefID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 150;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 400;
                dgvDetail.Columns["Qty1"].Width = 60;
                dgvDetail.Columns["Qty1"].HeaderText = "PK";
                dgvDetail.Columns["Qty2"].Width = 60;
                dgvDetail.Columns["Qty2"].HeaderText = "";
                dgvDetail.Columns["Qty"].Width = 80;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                dgvDetail.Columns["Weight"].Width = 80;
                dgvDetail.Columns["TotalWeight"].Width = 120;
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

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "Brand";
                BrandID.HeaderText = "Brand";
                BrandID.Width = 80;
                BrandID.DataSource = DBConnection.GetSQLTable("Select ID = -1, Name = ' None' Union All Select ID, Name = Short From Brand");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("BrandID"))
                {
                    dgvDetail.Columns.Remove("BrandID");
                }
                else if (dgvDetail.Columns.Contains("Brand"))
                {
                    dgvDetail.Columns.Remove("Brand");
                }
                BrandID.DataPropertyName = "BrandID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Name"].Index + 1, BrandID);


                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty2"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }




        }
    }
}
