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
    public partial class frm_IncomeExpense : Form
    {
        public static int PrintID = 0;
        int ID, TypeID = 3, codeid;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;

        delegate void SetComboBoxCellType(int rIndex);
        bool isComboBox = false;
        public frm_IncomeExpense(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void cbType_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbCurrency.DroppedDown = true;
            LocalData.AutoComplete(cbCurrency, e, true);
        }

        private void ChangeCellToCombox(int r_index)
        {
            if (isComboBox == false)
            {
                //int i;
                //int.tryparse(dbconnection.roexecsql("select stdunitid from stock where id = " + codeid.tostring()).tostring(), out i);
                DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.DropDownButton;
                //combocell.DataSource = DBConnection.GetTable("dbo.GetPurchasePayable(" + codeid.ToString() + ")", "");
                combocell.DataSource = DBConnection.GetSQLTable("select ID = -1, Name = ' None'  Union All select ID, Name = isnull(DocumentID, AutoID) From PurchaseHead where isnull(Deleted,0) <> 1 and PaymentID = 2 and StockReceived = 0 and SupplierID = " + codeid.ToString());
                combocell.ValueMember = "ID";
                combocell.DisplayMember = "Name";
                dgvDetail.Rows[r_index].Cells[dgvDetail.CurrentCell.ColumnIndex] = combocell;
                isComboBox = true;
            }
        }
        private void ChangeCellToCombox1(int r_index)
        {
            if (isComboBox == false)
            {
                //int i;
                //int.tryparse(dbconnection.roexecsql("select stdunitid from stock where id = " + codeid.tostring()).tostring(), out i);
                DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.DropDownButton;
                //combocell.DataSource = DBConnection.GetTable("dbo.GetPurchasePayable(" + codeid.ToString() + ")", "");
                combocell.DataSource = DBConnection.GetSQLTable("select ID, Name  From GetJournalCustSup(" + codeid.ToString()+")");
                combocell.ValueMember = "ID";
                combocell.DisplayMember = "Name";
                dgvDetail.Rows[r_index].Cells[dgvDetail.CurrentCell.ColumnIndex] = combocell;
                isComboBox = true;
            }
        }
        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {

            if (e.ColumnIndex == 2 )
            {
                SendKeys.Send("{Tab}");
            }
            else if (e.ColumnIndex == 5)
            {
               //if (LocalData.Menu == LocalData.myMenu.Journal)
               // {
               //     int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[3].Value.ToString(), out codeid);
               //     SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox1);
               //     dgvDetail.BeginInvoke(cct, e.RowIndex);
               //     isComboBox = false;
               // }
            }
            else if (e.ColumnIndex == 6)
            {
                if (LocalData.Menu == LocalData.myMenu.SupSettlement)
                {
                    int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[4].Value.ToString(), out codeid);
                    SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox);
                    dgvDetail.BeginInvoke(cct, e.RowIndex);
                    isComboBox = false;
                }

            }
            //if (TypeID == 3)
            //{
            //    if (e.ColumnIndex == 3)
            //    {
            //        dgvDetail.CurrentCell.Value = 289;
            //        SendKeys.Send("{Tab}");
            //    }
            //}
            //else if (TypeID == 4 || TypeID == 5)
            //{
            //    if (e.ColumnIndex == 3)
            //    {
            //        dgvDetail.CurrentCell.Value = 26;
            //        SendKeys.Send("{Tab}");
            //    }
            //}
        }

        private void cbType_SelectionChangeCommitted(object sender, EventArgs e)
        {
            //int.TryParse(cbCurrency.SelectedValue.ToString(), out TypeID);
        }

        private void cbType_DropDownClosed(object sender, EventArgs e)
        {
            //int.TryParse(cbCurrency.SelectedValue.ToString(), out TypeID);

        }

        private void dgvDetail_EditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.CustSettlement)
            {
                int colIndex = dgvDetail.CurrentCell.ColumnIndex;

                if (colIndex == 5)
                {
                    TextBox tbCode = (TextBox)e.Control;

                    tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                    tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                    tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                }
                else if (colIndex == 3)
                {

                }
                else
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.None;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                int colIndex = dgvDetail.CurrentCell.ColumnIndex;

                if (colIndex == 4)
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                    tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                    tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                }
                else if (colIndex == 3)
                {

                }
                else
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.None;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                int colIndex = dgvDetail.CurrentCell.ColumnIndex;

                if (colIndex == 5)
                {
                    TextBox tbCode = (TextBox)e.Control;

                    tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                    tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                    tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                }
                else if (colIndex == 3 || colIndex == 6)
                {

                }
                else
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.None;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
            {
                int colIndex = dgvDetail.CurrentCell.ColumnIndex;

                if (colIndex == 5)
                {
                    TextBox tbCode = (TextBox)e.Control;

                    tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                    tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                    tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                }
                else if (colIndex == 3)
                {

                }
                else
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.None;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                int colIndex = dgvDetail.CurrentCell.ColumnIndex;

                if (colIndex == 4)
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.SuggestAppend;
                    tbCode.AutoCompleteCustomSource = GetAutoCompleteCode();
                    tbCode.AutoCompleteSource = AutoCompleteSource.CustomSource;
                }
                else
                {
                    TextBox tbCode = (TextBox)e.Control;
                    tbCode.AutoCompleteMode = AutoCompleteMode.None;
                }
            }
        }

        private AutoCompleteStringCollection GetAutoCompleteCode()
        {
            AutoCompleteStringCollection collection = new AutoCompleteStringCollection();
            DataTable dt = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.CustSettlement)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Customer Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name  From AccountName Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Supplier Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Manufacturer Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name  From AccountName Where isnull(Deleted,0)<>1 ");
            }

            foreach (DataRow dr in dt.Rows)
            {
                collection.Add(dr["Short"].ToString());
            }

            return collection;

        }

        private void dgvDetail_UserAddedRow(object sender, DataGridViewRowEventArgs e)
        {
            dgvDetail.CurrentRow.Cells["Sr"].Value = e.Row.Index;
        }

        private void dgvDetail_UserDeletingRow(object sender, DataGridViewRowCancelEventArgs e)
        {
            foreach (DataGridViewRow row in dgvDetail.Rows)
            {
                if (!row.IsNewRow)
                {
                    row.Cells["Sr"].Value = row.Index + 1;
                }
            }
        }

        private void dgvDetail_RowValidating(object sender, DataGridViewCellCancelEventArgs e)
        {

        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }
            Save();
            frm_IncomeExpense_Load(sender, e);
        }

        private void Save()
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }


            DateTime e_Date;

            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));
            //dtHead.Rows[0]["Date"] = dtpDate.Value.Date + e_Date.TimeOfDay;
            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            scb = new SqlCommandBuilder(sdaHead);
            sdaHead.Update(dtHead);


            if (ID <= 0)
            {
                int.TryParse(DBConnection.roExecSQL("Select Max(ID) from IncomeExpenseHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                LocalData.SetAutoID(LocalData.myMenu.CustomerOpening, dtpDate.Value);

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

            if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, DetailAccountID, SourceID, Description, Debit, Credit, ExgRate, MMKDebit, MMKCredit from IncomeExpenseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, DetailAccountID, SourceID, InvoiceID, Description, Debit, Credit from IncomeExpenseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement || LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, DetailAccountID, SourceID,  Description, Debit, Credit from IncomeExpenseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, DetailAccountID, SourceID, Description, Debit, Credit, Discount, Surplus, NetAmount from IncomeExpenseDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }

            scb = new SqlCommandBuilder(sdaDetail);
            sdaDetail.Update(dtDetail);

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
            tbRemark.DataBindings.Clear();
            tbExgRate.DataBindings.Clear();
            cbCurrency.DataBindings.Clear();
            cbAccount.DataBindings.Clear();
            tbInAmount.DataBindings.Clear();
            tbExpAmount.DataBindings.Clear();

            ID = 0;

        }

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            string cust, code;
            int index, custid;
            decimal Bal, Net, Dis, Sur;
            if (LocalData.Menu == LocalData.myMenu.CustSettlement)
            {
                if (e.ColumnIndex == 5)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Name"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);

                    int.TryParse(DBConnection.roExecSQL("Select ID From Customer Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["SourceID"].Value = custid;
                    //dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = 289;

                    decimal.TryParse(DBConnection.roExecSQL("Select dbo.GetCustomerBalance( " + custid.ToString() + ")").ToString(), out Bal);
                    dgvDetail.CurrentRow.Cells["Debit"].Value = Bal;
                    dgvDetail.CurrentRow.Cells["NetAmount"].Value = Bal;
                }
                else if (e.ColumnIndex == 6 || e.ColumnIndex == 8 || e.ColumnIndex == 9)
                {
                    decimal.TryParse(dgvDetail.CurrentRow.Cells["Debit"].Value.ToString(), out Bal);
                    decimal.TryParse(dgvDetail.CurrentRow.Cells["Discount"].Value.ToString(), out Dis);
                    decimal.TryParse(dgvDetail.CurrentRow.Cells["Surplus"].Value.ToString(), out Sur);
                    Net = Bal - Dis + Sur;
                    dgvDetail.CurrentRow.Cells["NetAmount"].Value = Net;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                if (e.ColumnIndex == 4)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Account"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);
                    cust = cust.Substring(index + 3, cust.Length - (index + 3));

                    //dgvDetail.CurrentRow.Cells["Account"].Value = cust.ToString();

                    int.TryParse(DBConnection.roExecSQL("Select ID From AccountName Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = custid;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                if (e.ColumnIndex == 5)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Name"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);

                    int.TryParse(DBConnection.roExecSQL("Select ID From Supplier Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["SourceID"].Value = custid;
                    //dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = 26;
                    //int.TryParse(DBConnection.roExecSQL("Select ID From Customer Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    //dgvDetail.CurrentRow.Cells["SourceID"].Value = custid;
                    ////dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = 289;

                    decimal.TryParse(DBConnection.roExecSQL("Select dbo.GetSupplierBalance( " + custid.ToString() + ")").ToString(), out Bal);
                    dgvDetail.CurrentRow.Cells["Credit"].Value = Bal;
                    dgvDetail.CurrentRow.Cells["NetAmount"].Value = Bal;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
            {
                if (e.ColumnIndex == 5)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Name"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);

                    int.TryParse(DBConnection.roExecSQL("Select ID From Manufacturer Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["SourceID"].Value = custid;
                    //dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = 26;
                    decimal.TryParse(DBConnection.roExecSQL("Select dbo.GetManufacturerBalance( " + custid.ToString() + ")").ToString(), out Bal);
                    dgvDetail.CurrentRow.Cells["Credit"].Value = Bal;
                    dgvDetail.CurrentRow.Cells["NetAmount"].Value = Bal;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                int amt, rate;
                if (e.ColumnIndex == 4)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Account"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);
                    cust = cust.Substring(index + 3, cust.Length - (index + 3));

                    //dgvDetail.CurrentRow.Cells["Account"].Value = cust.ToString();

                    int.TryParse(DBConnection.roExecSQL("Select ID From AccountName Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["DetailAccountID"].Value = custid;
                    dgvDetail.CurrentRow.Cells["ExgRate"].Value = 1;
                }
                else if (e.ColumnIndex == 7 || e.ColumnIndex == 8 || e.ColumnIndex == 9)
                {
                    int.TryParse(dgvDetail.CurrentRow.Cells["ExgRate"].Value.ToString(), out rate);
                    int.TryParse(dgvDetail.CurrentRow.Cells["Debit"].Value.ToString(), out amt);
                    dgvDetail.CurrentRow.Cells["MMKDebit"].Value = amt * rate;
                    int.TryParse(dgvDetail.CurrentRow.Cells["Credit"].Value.ToString(), out amt);
                    dgvDetail.CurrentRow.Cells["MMKCredit"].Value = amt * rate;

                }
            }

        }

        private void menuStrip1_ItemClicked(object sender, ToolStripItemClickedEventArgs e)
        {

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

        private void btPrint_Click(object sender, EventArgs e)
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
                Boolean allow;
                Boolean.TryParse(DBConnection.roExecSQL("Select dbo.CheckUserPermission(" + LocalData.UserID.ToString() + ",2," + ((int)LocalData.Menu).ToString() + ",1)").ToString(), out allow);
                if (allow || ID < 1)
                {
                    Save();
                }
                else
                {
                    PrintID = ID;

                    dtHead.Dispose();
                    dtDetail.Dispose();


                    dtpDate.DataBindings.Clear();
                    tbAutoID.DataBindings.Clear();
                    tbDocumentID.DataBindings.Clear();
                    tbRemark.DataBindings.Clear();
                    tbExgRate.DataBindings.Clear();
                    cbCurrency.DataBindings.Clear();
                    cbAccount.DataBindings.Clear();
                    tbInAmount.DataBindings.Clear();
                    tbExpAmount.DataBindings.Clear();
                    ID = 0;
                }
                Form frm;
                frm = new frm_Preview(8);
                frm.ShowDialog();
                DBConnection.ExecSQL("Update IncomeExpenseHead Set Printed = 1 Where ID = " + PrintID.ToString());
                frm_IncomeExpense_Load(sender, e);
            }
        }

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            decimal amount, ExgRate;
            //int ExgRate = 1;
            if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                decimal.TryParse(dtDetail.Compute("Sum(MMKDebit)", "").ToString(), out amount);
                dtHead.Rows[0]["TotalIncome"] = amount;
                tbInAmount.Text = amount.ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(MMKCredit)", "").ToString(), out amount);
                dtHead.Rows[0]["TotalExpense"] = amount;
                tbExpAmount.Text = amount.ToString("#,##0");
            }
            else
            {
                decimal.TryParse(tbExgRate.Text.ToString(), out ExgRate );
                decimal.TryParse(dtDetail.Compute("Sum(Debit)", "").ToString(), out amount);
                dtHead.Rows[0]["TotalIncome"] = amount * ExgRate;
                tbInAmount.Text = (amount * ExgRate).ToString("#,##0");
                decimal.TryParse(dtDetail.Compute("Sum(Credit)", "").ToString(), out amount);
                dtHead.Rows[0]["TotalExpense"] = amount * ExgRate;
                tbExpAmount.Text = (amount * ExgRate).ToString("#,##0");

            }

            }

        private void frm_IncomeExpense_Load(object sender, EventArgs e)
        {
            
            cbCurrency.DataSource = DBConnection.GetSQLTable("Select ID,Name From Currency order by ID");
            cbCurrency.DisplayMember = "Name";
            cbCurrency.ValueMember = "ID";
            cbCurrency.SelectedValue = 1;
            

            cbAccount.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From AccountName where isnull(Deleted,0) <> 1 order by Name");
            cbAccount.DisplayMember = "Name";
            cbAccount.ValueMember = "ID";
            cbAccount.SelectedValue = 1;

            dtHead = new DataTable();

            sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, CashbookTypeID, CurrencyID, AccountID, ExgRate, Remark, TotalIncome, TotalExpense, UserID, EditDate From IncomeExpenseHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
            sdaHead.Fill(dtHead);

            if (LocalData.Menu == LocalData.myMenu.CustSettlement)
            {
                this.Text = "Customer Receive Entry";
                TypeID = 3;
            }
            else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                this.Text = "Income/Expense Entry";
                TypeID = 1;
            }
            else if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                lbCurrency.Visible = false;
                cbCurrency.Visible = false;
                this.Text = "Journal Entry";
                lbAccount.Visible = false;
                cbAccount.Visible = false;
                lbExgRate.Visible = false;
                tbExgRate.Visible = false;
                lbInAmount.Text = "Debit Total: ";
                lbExpAmount.Text = "Credit Total: ";
                TypeID = 2;
            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                this.Text = "Supplier Payment Entry";
                TypeID = 4;
            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
            {
                this.Text = "Manufacturer Payment Entry";
                TypeID = 5;
            }



            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                dtHead.Rows[0]["AccountID"] = 11;
                dtHead.Rows[0]["ExgRate"] = 1;
                dtHead.Rows[0]["CurrencyID"] = 1;
                if (LocalData.Menu == LocalData.myMenu.CustSettlement)
                {
                    dtHead.Rows[0]["CashbookTypeID"] = 3;
                }
                else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
                {
                    dtHead.Rows[0]["CashbookTypeID"] = 1;
                }
                else if (LocalData.Menu == LocalData.myMenu.Journal)
                {
                    dtHead.Rows[0]["CashbookTypeID"] = 2;
                }
                else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
                {
                    dtHead.Rows[0]["CashbookTypeID"] = 4;
                }
                else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
                {
                    dtHead.Rows[0]["CashbookTypeID"] = 5; 
                }
                cbAccount.Focus();
            }
            else
            {
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();

            }

            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            cbCurrency.DataBindings.Add("SelectedValue", dtHead, "CurrencyID");
            cbAccount.DataBindings.Add("SelectedValue", dtHead, "AccountID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
            tbInAmount.DataBindings.Add("Text", dtHead, "TotalIncome");
            tbExpAmount.DataBindings.Add("Text", dtHead, "TotalExpense");

            FillDataGridView();

            tbDocumentID.Focus();

        }

        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.Enter)
            {
                SendKeys.Send("{TAB}");
                return true;
            }


            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void FillDataGridView()
        {
            dtDetail = new DataTable();

            if (LocalData.Menu == LocalData.myMenu.CustSettlement)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, DetailAccountID, SourceID, Name = Short + ' - ' + Name, Debit, Credit, Discount, Surplus, NetAmount,  Description From IncomeExpenseDetail D Join Customer C on D.SourceID = C.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["DetailAccountID"].Visible = false;
                dgvDetail.Columns["SourceID"].Visible = false;
                //dgvDetail.Columns["Credit"].Visible = false;

                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 35;
                dgvDetail.Columns["Name"].Width = 350;
                dgvDetail.Columns["Description"].Width = 350;
                dgvDetail.Columns["Debit"].Width = 120;
                dgvDetail.Columns["Debit"].HeaderText = "Income";
                dgvDetail.Columns["Credit"].Width = 120;
                dgvDetail.Columns["Credit"].HeaderText = "Expense";
                dgvDetail.Columns["Discount"].Width = 100;
                dgvDetail.Columns["Discount"].HeaderText = "လျော့ပေးငွေ";
                dgvDetail.Columns["Surplus"].Width = 100;
                dgvDetail.Columns["Surplus"].HeaderText = "ပိုရငွေ";
                dgvDetail.Columns["NetAmount"].Width = 150;
                dgvDetail.Columns["NetAmount"].HeaderText = "Net Amount";

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "DetailAccountID";
                BrandID.HeaderText = "Account";
                BrandID.Width = 150;
                BrandID.DataSource = DBConnection.GetSQLTable("select ID, Name from AccountName where ID in (289, 1491)");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("DetailAccountID"))
                {
                    dgvDetail.Columns.Remove("DetailAccountID");
                }
                else if (dgvDetail.Columns.Contains("DetailAccount"))
                {
                    dgvDetail.Columns.Remove("DetailAccount");
                }
                BrandID.DataPropertyName = "DetailAccountID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Sr"].Index + 1, BrandID);

                dgvDetail.Columns["Debit"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Debit"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Format = LocalData.IntegerFormat;

            }
            else if (LocalData.Menu == LocalData.myMenu.IncomeExpense)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, DetailAccountID, Account = A.Short + ' - ' + A.Name , SourceID, Debit, Credit,  Description From IncomeExpenseDetail D Join AccountName A on DetailAccountID = A.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["DetailAccountID"].Visible = false;
                dgvDetail.Columns["SourceID"].Visible = false;

                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Account"].Width = 500;
                dgvDetail.Columns["Description"].Width = 300;
                dgvDetail.Columns["Debit"].Width = 150;
                dgvDetail.Columns["Credit"].Width = 150;
                dgvDetail.Columns["Debit"].HeaderText = "Income";
                dgvDetail.Columns["Credit"].HeaderText = "Expense";

            }
            else if (LocalData.Menu == LocalData.myMenu.SupSettlement)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, DetailAccountID, SourceID, Name = Short + ' - ' + Name, InvoiceID,  Debit, Credit, Discount, Surplus, NetAmount,  Description From IncomeExpenseDetail D Join Supplier C on D.SourceID = C.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["DetailAccountID"].Visible = false;
                dgvDetail.Columns["SourceID"].Visible = false;

                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 35;
                dgvDetail.Columns["Name"].Width = 300;
                dgvDetail.Columns["Description"].Width = 350;
                dgvDetail.Columns["Debit"].Width = 120;
                dgvDetail.Columns["Debit"].HeaderText = "Income";
                dgvDetail.Columns["Credit"].Width = 120;
                dgvDetail.Columns["Credit"].HeaderText = "Expense";
                dgvDetail.Columns["Discount"].Width = 100;
                dgvDetail.Columns["Discount"].HeaderText = "လျော့ပေးငွေ";
                dgvDetail.Columns["Surplus"].Width = 100;
                dgvDetail.Columns["Surplus"].HeaderText = "ပိုရငွေ";
                dgvDetail.Columns["NetAmount"].Width = 150;
                dgvDetail.Columns["NetAmount"].HeaderText = "Net Amount";

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "DetailAccountID";
                BrandID.HeaderText = "Account";
                BrandID.Width = 150;
                BrandID.DataSource = DBConnection.GetSQLTable("select ID, Name from AccountName where ID in (26, 1492)");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("DetailAccountID"))
                {
                    dgvDetail.Columns.Remove("DetailAccountID");
                }
                else if (dgvDetail.Columns.Contains("DetailAccount"))
                {
                    dgvDetail.Columns.Remove("DetailAccount");
                }
                BrandID.DataPropertyName = "DetailAccountID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Sr"].Index + 1, BrandID);

                DataGridViewComboBoxColumn PurID = new DataGridViewComboBoxColumn();
                PurID.Name = "InvoiceID";
                PurID.HeaderText = "Invoice ID";
                PurID.Width = 250;
                PurID.DataSource = DBConnection.GetSQLTable("select ID = -1, Name = ' None' 	Union All select ID, Name = isnull(DocumentID,AutoID) From PurchaseHead where isnull(Deleted,0) <>1 and  PaymentID = 2 and StockReceived = 0 ");
                PurID.ValueMember = "ID";
                PurID.DisplayMember = "Name";
                PurID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("InvoiceID"))
                {
                    dgvDetail.Columns.Remove("InvoiceID");
                }
                else if (dgvDetail.Columns.Contains("Invoice"))
                {
                    dgvDetail.Columns.Remove("InvoiceID");
                }
                PurID.DataPropertyName = "InvoiceID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Name"].Index + 1, PurID);

                dgvDetail.Columns["Debit"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Debit"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Format = LocalData.IntegerFormat;


            }
            else if (LocalData.Menu == LocalData.myMenu.ManuSettlement)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, DetailAccountID, SourceID, Name = Short + ' - ' + Name, Debit, Credit, Discount, Surplus, NetAmount,  Description From IncomeExpenseDetail D Join Manufacturer C on D.SourceID = C.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["DetailAccountID"].Visible = false;
                dgvDetail.Columns["SourceID"].Visible = false;

                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 35;
                dgvDetail.Columns["Name"].Width = 300;
                dgvDetail.Columns["Description"].Width = 350;
                dgvDetail.Columns["Debit"].Width = 120;
                dgvDetail.Columns["Debit"].HeaderText = "Income";
                dgvDetail.Columns["Credit"].Width = 120;
                dgvDetail.Columns["Credit"].HeaderText = "Expense";
                dgvDetail.Columns["Discount"].Width = 100;
                dgvDetail.Columns["Discount"].HeaderText = "လျော့ပေးငွေ";
                dgvDetail.Columns["Surplus"].Width = 100;
                dgvDetail.Columns["Surplus"].HeaderText = "ပိုရငွေ";
                dgvDetail.Columns["NetAmount"].Width = 150;
                dgvDetail.Columns["NetAmount"].HeaderText = "Net Amount";

                DataGridViewComboBoxColumn BrandID = new DataGridViewComboBoxColumn();
                BrandID.Name = "DetailAccountID";
                BrandID.HeaderText = "Account";
                BrandID.Width = 150;
                BrandID.DataSource = DBConnection.GetSQLTable("select ID, Name from AccountName where ID in (1452, 1493)");
                BrandID.ValueMember = "ID";
                BrandID.DisplayMember = "Name";
                BrandID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("DetailAccountID"))
                {
                    dgvDetail.Columns.Remove("DetailAccountID");
                }
                else if (dgvDetail.Columns.Contains("DetailAccount"))
                {
                    dgvDetail.Columns.Remove("DetailAccount");
                }
                BrandID.DataPropertyName = "DetailAccountID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Sr"].Index + 1, BrandID);

                dgvDetail.Columns["Debit"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Debit"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Discount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Surplus"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["NetAmount"].DefaultCellStyle.Format = LocalData.IntegerFormat;


            }
            else if (LocalData.Menu == LocalData.myMenu.Journal)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, DetailAccountID, Account = A.Short + ' - ' + A.Name , SourceID, Description, Debit, Credit, ExgRate, MMKDebit, MMKCredit From IncomeExpenseDetail D Join AccountName A on DetailAccountID = A.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["DetailAccountID"].Visible = false;
                dgvDetail.Columns["SourceID"].Visible = false;
                dgvDetail.Columns["MMKDebit"].Visible = false;
                dgvDetail.Columns["MMKCredit"].Visible = false;

                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Account"].Width = 350;
                //dgvDetail.Columns["SourceID"].Width = 300;
                dgvDetail.Columns["Description"].Width = 300;
                dgvDetail.Columns["Debit"].Width = 120;
                dgvDetail.Columns["Credit"].Width = 120;
                dgvDetail.Columns["ExgRate"].Width = 100;
                dgvDetail.Columns["Debit"].HeaderText = "Debit";
                dgvDetail.Columns["Credit"].HeaderText = "Credit";
                dgvDetail.Columns["ExgRate"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["ExgRate"].DefaultCellStyle.Format = LocalData.IntegerFormat;

            }


            dgvDetail.Columns["Debit"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvDetail.Columns["Debit"].DefaultCellStyle.Format = LocalData.IntegerFormat;

            dgvDetail.Columns["Credit"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvDetail.Columns["Credit"].DefaultCellStyle.Format = LocalData.IntegerFormat;
        }
    }
}
