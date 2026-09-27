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
    public partial class frm_Transfer : Form
    {
        public static int PrintID = 0;
        int ID, codeid;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;
        Form frm;
        delegate void SetComboBoxCellType(int rIndex);
        bool isComboBox = false;
        public frm_Transfer(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void frm_StockOpening_Load(object sender, EventArgs e)
        {
            cbFromLoc.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cbFromLoc.DisplayMember = "Name";
            cbFromLoc.ValueMember = "ID";
            cbFromLoc.SelectedValue = 1;
            cbToLoc.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cbToLoc.DisplayMember = "Name";
            cbToLoc.ValueMember = "ID";
            cbToLoc.SelectedValue = 1;

            dtHead = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                this.Text = "Transfer Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, FromLocID, ToLocID, Remark, TotalAmount, TotalWeight, UserID, EditDate From TransferHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
            }
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
            {
                this.Text = "Adjustment Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, Remark, TotalAmount, UserID, EditDate From AdjustmentHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lbFromLoc.Visible = false;
                cbFromLoc.Visible = false;
            }

            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();

                if (LocalData.Menu == LocalData.myMenu.Transfer)
                {
                    dtHead.Rows[0]["FromLocID"] = 1;
                    dtHead.Rows[0]["ToLocID"] = 1;
                }
                else if (LocalData.Menu == LocalData.myMenu.Adjustment)
                {
                    dtHead.Rows[0]["LocationID"] = 1;
                }


                dtHead.Rows[0]["UserID"] = LocalData.UserID;

            }
            else
            {
                //int i, CustID;
                //int.TryParse(dtHead.Rows[0]["CustomerID"].ToString(), out CustID);
                //tbPhone.Text = DBConnection.rExecSQL("Select isnull(Info2,'') From Customer Where ID = " + CustID.ToString());
                //tbAddress.Text = DBConnection.rExecSQL("Select isnull(Address,'') From Customer Where ID = " + CustID.ToString());

                //int.TryParse(dtHead.Rows[0]["PaymentID"].ToString(), out i);
                //tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();

            }

            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                cbFromLoc.DataBindings.Add("SelectedValue", dtHead, "FromLocID");
                cbToLoc.DataBindings.Add("SelectedValue", dtHead, "ToLocID");
            }
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
            {
                cbToLoc.DataBindings.Add("SelectedValue", dtHead, "LocationID");
            }

            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbAmount.DataBindings.Add("Text", dtHead, "TotalAmount");

            FillDataGridView();

            cbFromLoc.Focus();

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
                SendKeys.Send("{TAB}");
                return true;
            }
            else if (keyData == Keys.F2)
            {

                return true;
            }
            else if (keyData == Keys.F3)
            {
 
                return true;
            }
            else if (keyData == Keys.Left)
            {
                SendKeys.Send("+{TAB}");
                return true;
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            int UnitID, Discount, Price, Qty1, Qty2;
            decimal Weight, Qty, TotalWeight;
            string Code;
            if (LocalData.Menu == LocalData.myMenu.Transfer)
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
                        decimal _qty;
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out _qty);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * _qty;
                        break;
                    case 9:
                    case 10:

                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        if (codeid > 0)
                        {
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        }

                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                        dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);

                        break;
                    case 11:
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        break;
                    default:
                        break;
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
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

                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);

                        break;
                    case 9:
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);
                        break;
                    default:
                        break;
                }
            }
            
        }

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            //if (e.ColumnIndex == 2 || e.ColumnIndex == 5 || e.ColumnIndex == 10 || e.ColumnIndex == 12)
            if (e.ColumnIndex == 2)
            {
                SendKeys.Send("{Tab}");
            }
            else if (e.ColumnIndex == 8 || e.ColumnIndex == 10)
            {
                int.TryParse(dgvDetail.Rows[e.RowIndex].Cells[3].Value.ToString(), out codeid);
                SetComboBoxCellType cct = new SetComboBoxCellType(ChangeCellToCombox);
                dgvDetail.BeginInvoke(cct, e.RowIndex);
                isComboBox = false;

            }
        }

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            CalculateNetAmount();
        }

        private void CalculateNetAmount()
        {
            decimal NetAmount, amount, discount, tax, charges, TotalAmount, TotalWeight, PaidAmount, BalanceAmount;
            int Qty;
            decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
            dtHead.Rows[0]["TotalAmount"] = amount;
            tbAmount.Text = amount.ToString("#,##0");
            //int.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out Qty);
            //tbTotalQty.Text = Qty.ToString("#,##0");
            //decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
            //tbTotalWeight.Text = TotalWeight.ToString("#.##0");
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

        private void cbFromLoc_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbFromLoc.DroppedDown = true;
            LocalData.AutoComplete(cbFromLoc, e, true);
        }

        private void cbToLoc_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbToLoc.DroppedDown = true;
            LocalData.AutoComplete(cbToLoc, e, true);
        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {
            Save();
            frm_StockOpening_Load(sender, e);
        }

        private void Save()
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }

            if (cbFromLoc.SelectedValue == null)
            {
                cbFromLoc.Focus();
                erptransaction.SetError(cbFromLoc, "Select Location!");
                return;
            }

            if (cbToLoc.SelectedValue == null)
            {
                cbToLoc.Focus();
                erptransaction.SetError(cbToLoc, "Select Location!");
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
                if (LocalData.Menu == LocalData.myMenu.Transfer)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from TransferHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.Transfer, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.Adjustment)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from AdjustmentHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.SaleOrder, dtpDate.Value);
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

            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty1, Qty2, Qty, Weight, Price, TotalWeight, Amount, Remark from TransferDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Price, Amount, AdjustTypeID from AdjustmentDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
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
            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                cbFromLoc.DataBindings.Clear();
            }

            cbToLoc.DataBindings.Clear();
            tbRemark.DataBindings.Clear();
            tbAmount.DataBindings.Clear();
            ID = 0;
        }

        private void btSave_Click(object sender, EventArgs e)
        {

        }

        private void btSave_Click_1(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click(sender, e);
        }

        private void btPrint_Click(object sender, EventArgs e)
        {
            Save();
            frm_StockOpening_Load(sender, e);
            frm = new frm_Preview(6);
            frm.ShowDialog();
        }

        private void FillDataGridView()
        {
            dtDetail = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark From TransferDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                //dgvDetail.Columns["Remark"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 130;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 250;
                dgvDetail.Columns["Qty1"].Width = 60;
                dgvDetail.Columns["Qty1"].HeaderText = "PK";
                dgvDetail.Columns["Qty2"].Width = 60;
                dgvDetail.Columns["Qty2"].HeaderText = "";
                dgvDetail.Columns["Qty"].Width = 80;
                dgvDetail.Columns["Price"].Width = 100;
                dgvDetail.Columns["Amount"].Width = 150;
                dgvDetail.Columns["Weight"].Width = 80;
                dgvDetail.Columns["TotalWeight"].Width = 120;
                dgvDetail.Columns["Remark"].Width = 150;


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
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty, UnitID , Price,  Amount, AdjustTypeID From AdjustmentDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                //dgvDetail.Columns["Remark"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 150;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 400;
                dgvDetail.Columns["Qty"].Width = 120;
                dgvDetail.Columns["Price"].Width = 150;
                dgvDetail.Columns["Amount"].Width = 150;

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

                DataGridViewComboBoxColumn TypeID = new DataGridViewComboBoxColumn();
                TypeID.Name = "AdjustType";
                TypeID.HeaderText = "AdjustType";
                TypeID.Width = 200 ;
                TypeID.DataSource = DBConnection.GetSQLTable("Select ID, Name From AdjustType");
                TypeID.ValueMember = "ID";
                TypeID.DisplayMember = "Name";
                TypeID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                if (dgvDetail.Columns.Contains("AdjustTypeID"))
                {
                    dgvDetail.Columns.Remove("AdjustTypeID");
                }
                else if (dgvDetail.Columns.Contains("AdjustType"))
                {
                    dgvDetail.Columns.Remove("AdjustType");
                }
                TypeID.DataPropertyName = "AdjustTypeID";
                dgvDetail.Columns.Insert(dgvDetail.Columns["Amount"].Index + 1, TypeID);


                //dgvDetail.Columns["Price"].ReadOnly = true;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;

            }
        }

        private void ChangeCellToCombox(int r_index)
        {
            if (LocalData.Menu == LocalData.myMenu.Transfer)
            {
                if (isComboBox == false)
                {
                    string str = string.Empty;
                    if (dgvDetail.CurrentCell.ColumnIndex == 8)
                    {
                        return;
                    }
                    else if (dgvDetail.CurrentCell.ColumnIndex == 10)
                    {
                        str = "dbo.GetStockUnit(" + codeid.ToString() + ")";
                    }
                    //else if (dgvDetail.CurrentCell.ColumnIndex == 6)
                    //{
                    //    str = "dbo.GetStockBrand(" + codeid.ToString() + ")";
                    //}
                    //int i;
                    //int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + codeid.ToString()).ToString(), out i);
                    DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                    combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                    combocell.DataSource = DBConnection.GetTable(str.ToString(), "");
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
            else if (LocalData.Menu == LocalData.myMenu.Adjustment)
            {
                if (isComboBox == false)
                {
                    string str = string.Empty;
                    if (dgvDetail.CurrentCell.ColumnIndex == 8)
                    {
                        str = "dbo.GetStockUnit(" + codeid.ToString() + ")";
                    }
                    else if (dgvDetail.CurrentCell.ColumnIndex == 6)
                    {
                        str = "dbo.GetStockBrand(" + codeid.ToString() + ")";
                    }
                    else if (dgvDetail.CurrentCell.ColumnIndex == 10)
                    {
                        return;
                    }
                    //int i;
                    //int.TryParse(DBConnection.roExecSQL("select StdUnitID from stock where ID = " + codeid.ToString()).ToString(), out i);
                    DataGridViewComboBoxCell combocell = new DataGridViewComboBoxCell();
                    combocell.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
                    combocell.DataSource = DBConnection.GetTable(str.ToString(), "");
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
        }

        private void btFill_Click(object sender, EventArgs e)
        {

        }
    }
}
