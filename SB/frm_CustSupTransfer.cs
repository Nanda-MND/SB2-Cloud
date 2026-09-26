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
    public partial class frm_CustSupTransfer : Form
    {
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;

        int ID = 0;
        private void cbFromAcct_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbFromAcct.DroppedDown = true;
            LocalData.AutoComplete(cbFromAcct, e, true);
        }

        private void cbFromName_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbFromName.DroppedDown = true;
            LocalData.AutoComplete(cbFromName, e, true);
        }

        private void cbToAcct_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbToAcct.DroppedDown = true;
            LocalData.AutoComplete(cbToAcct, e, true);
        }

        private void cbToName_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbToName.DroppedDown = true;
            LocalData.AutoComplete(cbToName, e, true);
        }

        private void cbFromAcct_DropDownClosed(object sender, EventArgs e)
        {
            int i;
            int.TryParse(cbFromAcct.SelectedValue.ToString(), out i);
            if (i == 26)
            {
                cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                cbFromName.DisplayMember = "Name";
                cbFromName.ValueMember = "ID";
                cbFromName.SelectedValue = 1;
            }
            else if (i==289)
            {
                cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Customer where isnull(Deleted,0)<>1");
                cbFromName.DisplayMember = "Name";
                cbFromName.ValueMember = "ID";
                cbFromName.SelectedValue = 1;
            }
            else if (i == 1452)
            {
                cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Manufacturer where isnull(Deleted,0)<>1");
                cbFromName.DisplayMember = "Name";
                cbFromName.ValueMember = "ID";
                cbFromName.SelectedValue = 1;
            }
        }

        private void cbToAcct_DropDownClosed(object sender, EventArgs e)
        {
            int i;
            int.TryParse(cbToAcct.SelectedValue.ToString(), out i);
            if (i == 26)
            {
                cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                cbToName.DisplayMember = "Name";
                cbToName.ValueMember = "ID";
                cbToName.SelectedValue = 1;
            }
            else if (i == 289)
            {
                cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Customer where isnull(Deleted,0)<>1");
                cbToName.DisplayMember = "Name";
                cbToName.ValueMember = "ID";
                cbToName.SelectedValue = 1;
            }
            else if (i == 1452)
            {
                cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Manufacturer where isnull(Deleted,0)<>1");
                cbToName.DisplayMember = "Name";
                cbToName.ValueMember = "ID";
                cbToName.SelectedValue = 1;
            }
        }

        public frm_CustSupTransfer(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void btSave_Click(object sender, EventArgs e)
        {
            DateTime e_Date;

            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));
            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            scb = new SqlCommandBuilder(sdaHead);
            sdaHead.Update(dtHead);

            MessageBox.Show("Save Successfully");
            scb.Dispose();
            sdaHead.Dispose();
            dtHead.Dispose();



            dtpDate.DataBindings.Clear();
            tbAutoID.DataBindings.Clear();
            tbDocumentID.DataBindings.Clear();

            cbFromAcct.DataBindings.Clear();
            cbFromName.DataBindings.Clear();
            cbToAcct.DataBindings.Clear();
            cbToName.DataBindings.Clear();
            tbAmount.DataBindings.Clear();
            tbRemark.DataBindings.Clear();

            frm_CustSupTransfer_Load(sender, e);
        }

        private void btClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void frm_CustSupTransfer_Load(object sender, EventArgs e)
        {
            cbFromAcct.DataSource = DBConnection.GetSQLTable("select ID, Name from AccountName where ID in (26,289, 1452)");
            cbFromAcct.DisplayMember = "Name";
            cbFromAcct.ValueMember = "ID";
            cbFromAcct.SelectedValue = 26;


            cbToAcct.DataSource = DBConnection.GetSQLTable("select ID, Name from AccountName where ID in (26,289, 1452)");
            cbToAcct.DisplayMember = "Name";
            cbToAcct.ValueMember = "ID";
            cbToAcct.SelectedValue = 26;



            dtHead = new DataTable();

            sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, FromAcctID, FromSourceID, ToAcctID, ToSourceID, Amount, Remark,  UserID, EditDate From CustSupTransfer where ID = " + ID.ToString(), DBConnection.ActiveConnection);
            sdaHead.Fill(dtHead);
            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                dtHead.Rows[0]["FromAcctID"] = 26;
                dtHead.Rows[0]["ToAcctID"] = 26;
                dtHead.Rows[0]["FromSourceID"] = 1;
                dtHead.Rows[0]["Amount"] = 0;
                dtHead.Rows[0]["UserID"] = LocalData.UserID;

                cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                cbFromName.DisplayMember = "Name";
                cbFromName.ValueMember = "ID";
                cbFromName.SelectedValue = 1;

                cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                cbToName.DisplayMember = "Name";
                cbToName.ValueMember = "ID";
                cbToName.SelectedValue = 1;

            }
            else
            {
                //int i;
                //int.TryParse(cbFromAcct.SelectedValue.ToString(), out i);
                //if (i == 26)
                //{
                //    cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                //    cbFromName.DisplayMember = "Name";

                //}
                //else if (i == 289)
                //{
                //    cbFromName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Customer where isnull(Deleted,0)<>1");
                //    cbFromName.DisplayMember = "Name";
                //    cbFromName.ValueMember = "ID";
                //}


                //int.TryParse(cbToAcct.SelectedValue.ToString(), out i);
                //if (i == 26)
                //{
                //    cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Supplier where isnull(Deleted,0)<>1");
                //    cbToName.DisplayMember = "Name";
                //    cbToName.ValueMember = "ID";
                //}
                //else if (i == 289)
                //{
                //    cbToName.DataSource = DBConnection.GetSQLTable("select ID, Name = Short + '-' + Name from Customer where isnull(Deleted,0)<>1");
                //    cbToName.DisplayMember = "Name";
                //    cbToName.ValueMember = "ID";
                //}
            }


            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            cbFromAcct.DataBindings.Add("SelectedValue", dtHead, "FromAcctID");
            cbFromName.DataBindings.Add("SelectedValue", dtHead, "FromSourceID");
            cbToAcct.DataBindings.Add("SelectedValue", dtHead, "ToAcctID");
            cbToName.DataBindings.Add("SelectedValue", dtHead, "ToSourceID");
            tbAmount.DataBindings.Add("Text", dtHead, "Amount");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");


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
    }
}
