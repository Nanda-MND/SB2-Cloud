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
    public partial class frm_AcctOpening : Form
    {
        int ID;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;
        public frm_AcctOpening(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void dgvDetail_EditingControlShowing(object sender, DataGridViewEditingControlShowingEventArgs e)
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

        private AutoCompleteStringCollection GetAutoCompleteCode()
        {
            AutoCompleteStringCollection collection = new AutoCompleteStringCollection();
            DataTable dt = new DataTable();
            dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name  From AccountName Where isnull(Deleted,0)<>1 ");

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

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            string cust, code;
            int index, custid;
            if (e.ColumnIndex == 4)
            {
                cust = dgvDetail.Rows[e.RowIndex].Cells["Name"].EditedFormattedValue.ToString();
                index = cust.IndexOf(" - ");
                code = cust.Substring(0, index);

                int.TryParse(DBConnection.roExecSQL("Select ID From AccountName Where Short = '" + code.ToString() + "'").ToString(), out custid);
                dgvDetail.CurrentRow.Cells["AccountID"].Value = custid;

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
            frm_AcctOpening_Load(sender, e);
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
                int.TryParse(DBConnection.roExecSQL("Select Max(ID) from AccountOpeningHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
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

            sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, AccountID, Description, Debit, Credit from AccountOpeningDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            scb = new SqlCommandBuilder(sdaDetail);
            sdaDetail.Update(dtDetail);

            MessageBox.Show("Save Successfully");
            //PrintID = ID;

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
            //cbType.DataBindings.Clear();
            //cbAccount.DataBindings.Clear();
            tbInAmount.DataBindings.Clear();
            tbExpAmount.DataBindings.Clear();

            ID = 0;

        }

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex == 2)
            {
                SendKeys.Send("{Tab}");
            }
        }

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            decimal amount;
            decimal.TryParse(dtDetail.Compute("Sum(Debit)", "").ToString(), out amount);
            dtHead.Rows[0]["TotalDebit"] = amount;
            tbInAmount.Text = amount.ToString("#,##0");
            decimal.TryParse(dtDetail.Compute("Sum(Credit)", "").ToString(), out amount);
            dtHead.Rows[0]["TotalCredit"] = amount;
            tbExpAmount.Text = amount.ToString("#,##0");
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

        private void btSave_Click(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click(sender, e);
        }

        private void frm_AcctOpening_Load(object sender, EventArgs e)
        {
            dtHead = new DataTable();
            this.Text = "Income/Expense Entry";
            sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, CurrencyID, ExgRate, Remark, TotalDebit, TotalCredit, UserID, EditDate From AccountOpeningHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
            sdaHead.Fill(dtHead);

            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                dtHead.Rows[0]["ExgRate"] = 1;

            }
            else
            {
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();

            }

            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            //cbType.DataBindings.Add("SelectedValue", dtHead, "CurrencyID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
            tbInAmount.DataBindings.Add("Text", dtHead, "TotalDebit");
            tbExpAmount.DataBindings.Add("Text", dtHead, "TotalCredit");

            FillDataGridView();

            tbDocumentID.Focus();


        }

        private void FillDataGridView()
        {
            dtDetail = new DataTable();

            sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, AccountID, Name = Short + ' - ' + Name,  Description, Debit, Credit From AccountOpeningDetail D Join AccountName C on D.AccountID = C.ID  Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
            sdaDetail.Fill(dtDetail);

            dgvDetail.DataSource = dtDetail;
            dgvDetail.Columns["ID"].Visible = false;
            dgvDetail.Columns["RefID"].Visible = false;
            dgvDetail.Columns["AccountID"].Visible = false;

            dgvDetail.Columns["Sr"].ReadOnly = true;
            dgvDetail.Columns["Sr"].Width = 50;
            dgvDetail.Columns["Name"].Width = 500 ;
            dgvDetail.Columns["Description"].Width = 300;
            dgvDetail.Columns["Debit"].Width = 150;
            dgvDetail.Columns["Credit"].Width = 150;
            dgvDetail.Columns["Debit"].HeaderText = "Debit";
            dgvDetail.Columns["Credit"].HeaderText = "Credit";

            //DataGridViewComboBoxColumn AccountID = new DataGridViewComboBoxColumn();
            //AccountID.Name = "Account";
            //AccountID.HeaderText = "Account";
            //AccountID.Width = 350;
            //AccountID.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short + ' - '+ Name From AccountName Where isnull(Deleted,0)<>1");
            //AccountID.ValueMember = "ID";
            //AccountID.DisplayMember = "Name";

            //AccountID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
            //if (dgvDetail.Columns.Contains("AccountID"))
            //{
            //    dgvDetail.Columns.Remove("AccountID");
            //}
            //else if (dgvDetail.Columns.Contains("Account"))
            //{
            //    dgvDetail.Columns.Remove("Account");
            //}
            //AccountID.DataPropertyName = "AccountID";
            //dgvDetail.Columns.Insert(dgvDetail.Columns["Sr"].Index + 1, AccountID);
        }
    }
}
