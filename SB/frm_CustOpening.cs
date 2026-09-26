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
    public partial class frm_CustOpening : Form
    {
        int ID;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;

        public frm_CustOpening(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        private void saveToolStripMenuItem_Click(object sender, EventArgs e)
        {

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

            if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Customer Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Supplier Where isnull(Deleted,0)<>1 ");
            }
            else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                dt = DBConnection.GetSQLTable("Select Short = Short + ' - ' + Name From Manufacturer Where isnull(Deleted,0)<>1 ");
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
            decimal amount;
            decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
            dtHead.Rows[0]["Amount"] = amount;
            tbAmount.Text = amount.ToString("#,##0");
        }

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex == 2 )
            {
                SendKeys.Send("{Tab}");
            }
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

        private void paidToolStripMenuItem_Click(object sender, EventArgs e)
        {

        }

        private void saveToolStripMenuItem_Click_1(object sender, EventArgs e)
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }
            Save();
            frm_CustOpening_Load(sender, e);
        }

        private void Save()
        {
            if (dtDetail.Rows.Count <= 0)
            {
                MessageBox.Show("No Item(s)");
                return;
            }


            DateTime e_Date;
            Boolean opn;
            opn = rbOpening.Checked;
            if (LocalData.Menu == LocalData.myMenu.SupplierOpening || LocalData.Menu == LocalData.myMenu.CustomerOpening || LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                dtHead.Rows[0]["isOpening"] = opn;
            }

            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));
            //dtHead.Rows[0]["Date"] = dtpDate.Value.Date + e_Date.TimeOfDay;
            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                scb = new SqlCommandBuilder(sdaHead);
                sdaHead.Update(dtHead);


                if (ID <= 0)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from CustomerOpeningHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
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

                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CustomerID, Amount from CustomerOpeningDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
                scb = new SqlCommandBuilder(sdaDetail);
                sdaDetail.Update(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                scb = new SqlCommandBuilder(sdaHead);
                sdaHead.Update(dtHead);


                if (ID <= 0)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from SupplierOpeningHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.SupplierOpening, dtpDate.Value);

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

                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, SupplierID, Amount from SupplierOpeningDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
                scb = new SqlCommandBuilder(sdaDetail);
                sdaDetail.Update(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                scb = new SqlCommandBuilder(sdaHead);
                sdaHead.Update(dtHead);


                if (ID <= 0)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from ManufacturerOpeningHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.ManufacturerOpening, dtpDate.Value);

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

                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, ManufacturerID, Amount from ManufacturerOpeningDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
                scb = new SqlCommandBuilder(sdaDetail);
                sdaDetail.Update(dtDetail);
            }
            else if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                scb = new SqlCommandBuilder(sdaHead);
                sdaHead.Update(dtHead);


                if (ID <= 0)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from StockOpeningHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.ManufacturerOpening, dtpDate.Value);

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

                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Price, Amount from StockOpeningDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
                scb = new SqlCommandBuilder(sdaDetail);
                sdaDetail.Update(dtDetail);
            }

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
            tbAmount.DataBindings.Clear();
            if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                cbCurrency.DataBindings.Clear();
            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                cbCurrency.DataBindings.Clear();
                tbExgRate.DataBindings.Clear();
            }

            ID = 0;

        }

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            string cust, code;
            int index, custid;
            if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                if (e.ColumnIndex == 4)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Customer"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);
                    //code = code.Substring(1, code.Length - 2);
                    //Code = Code.Substring(0, index - 1);
                    //dgvDetail.CurrentRow.Cells["Code"].Value = Code.ToString();

                    int.TryParse(DBConnection.roExecSQL("Select ID From Customer Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["CustomerID"].Value = custid;
                }

            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                if (e.ColumnIndex == 4)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Supplier"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);
                    //code = code.Substring(1, code.Length - 2);
                    //Code = Code.Substring(0, index - 1);
                    //dgvDetail.CurrentRow.Cells["Code"].Value = Code.ToString();

                    int.TryParse(DBConnection.roExecSQL("Select ID From Supplier Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["SupplierID"].Value = custid;
                }

            }
            else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                if (e.ColumnIndex == 4)
                {
                    cust = dgvDetail.Rows[e.RowIndex].Cells["Manufacturer"].EditedFormattedValue.ToString();
                    index = cust.IndexOf(" - ");
                    code = cust.Substring(0, index);
                    //code = code.Substring(1, code.Length - 2);
                    //Code = Code.Substring(0, index - 1);
                    //dgvDetail.CurrentRow.Cells["Code"].Value = Code.ToString();

                    int.TryParse(DBConnection.roExecSQL("Select ID From Manufacturer Where Short = '" + code.ToString() + "'").ToString(), out custid);
                    dgvDetail.CurrentRow.Cells["ManufacturerID"].Value = custid;
                }

            }
            else if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                int codeid, UnitID, Discount, Qty1, Qty2;
                decimal Weight, Qty,  TotalWeight, Price;
                string Code;

                    switch (e.ColumnIndex)
                {
                    case 7:
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(PurPrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        //dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);

                        break;
                    case 8:
                    case 9:
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                        Decimal.TryParse(dgvDetail.CurrentRow.Cells["Price"].Value.ToString(), out Price);
                        dgvDetail.CurrentRow.Cells["Amount"].Value = (Price * Qty);

                        break;
                    default:
                        break;
                }
            }
        }

        private void btFill_Click(object sender, EventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {

                DataTable dt;
                sdaDetail = new SqlDataAdapter("select ID, Short, Name, UnitID, Unit, BrandID, Brand, Qty = 0 from dbo.FillStockNBrandUnit('"+tbCode.Text.ToString()+"%') order by Short, Brand", DBConnection.ActiveConnection);
                dt = new DataTable();
                sdaDetail.Fill(dt);

                dtDetail.Rows.Clear();
                DataRow dtNrow;
                int i = 0;
                foreach (DataRow row in dt.Rows)
                {
                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["CodeID"] = row["ID"];
                    dtNrow["Code"] = row["Short"];
                    dtNrow["Name"] = row["Name"];
                    dtNrow["BrandID"] = row["BrandID"];
                    dtNrow["UnitID"] = row["UnitID"];
                    dtNrow["Qty"] = 0;
                    //dtNrow["Date"] = row["Date"];
                    //dtNrow["DocumentID"] = row["DocumentID"];
                    //dtNrow["Amount"] = row["Amount"];
                    //dtNrow["Confirm"] = row["Confirm"];
                    //dtNrow["TranType"] = row["TranType"];
                    dtDetail.Rows.Add(dtNrow);

                }
                //tbTotalVoucher.Text = dtinvoice.Compute("Count(DocumentID)", "TranType = 1 and Confirm = 1").ToString();
                //decimal.TryParse(dtinvoice.Compute("sum(Amount)", "").ToString(), out vAmount);
                //tbVoucherAmount.Text = vAmount.ToString("#,##0");

            }
        }

        private void cbLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbCurrency.DroppedDown = true;
            LocalData.AutoComplete(cbCurrency, e, true);
        }

        private void btSave_Click(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click_1(sender, e);
        }

        private void btBalance_Click(object sender, EventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                SqlParameter[] argSB = new SqlParameter[7];
                argSB[0] = new SqlParameter("@UserID", SqlDbType.Int); argSB[0].Value = LocalData.UserID;
                argSB[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argSB[1].Value = dtpDate.Value.ToString("yyyy-MM-dd");
                argSB[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argSB[2].Value = dtpDate.Value.ToString("yyyy-MM-dd");
                argSB[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argSB[3].Value = tbCode.Text;
                argSB[4] = new SqlParameter("@GroupID", SqlDbType.NVarChar); argSB[4].Value = "";
                argSB[5] = new SqlParameter("@TypeID", SqlDbType.NVarChar); argSB[5].Value = "";
                argSB[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argSB[6].Value = cbCurrency.SelectedValue.ToString();

                    DBConnection.ExecSp("StockBalance", argSB);
                SqlParameter[] tmp = new SqlParameter[1];
                tmp[0] = new SqlParameter("@UserID", SqlDbType.Int); tmp[0].Value = LocalData.UserID;
                DBConnection.ExecSp("UpdateStockStatusUnit_Opn", tmp);

                DataTable dt;
                sdaDetail = new SqlDataAdapter("select Op.CodeID, S.Short, Name = S.Name, Op.UnitID, Op.Qty, PurchasePrice = Pl.PurPrice  from tmp_stockopening op Join StockDetail Pl on op.CodeID = Pl.StockID and op.UnitID = pl.UnitID Join Stock S on Op.CodeID = S.ID Join Unit U on Op.UnitID = U.ID Where UserID = " + LocalData.UserID.ToString() + " order by Short, op.ID ", DBConnection.ActiveConnection);
                dt = new DataTable();
                sdaDetail.Fill(dt);

                dtDetail.Rows.Clear();
                DataRow dtNrow;
                int i = 0;
                int qty, price;
                foreach (DataRow row in dt.Rows)
                {
                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["CodeID"] = row["CodeID"];
                    dtNrow["Code"] = row["Short"];
                    dtNrow["Name"] = row["Name"];
                    dtNrow["UnitID"] = row["UnitID"];
                    dtNrow["Qty"] = row["Qty"];
                    dtNrow["Price"] = row["PurchasePrice"];
                    int.TryParse(row["Qty"].ToString(), out qty);
                    int.TryParse(row["PurchasePrice"].ToString(), out price);
                    //dtNrow["DocumentID"] = row["DocumentID"];
                    dtNrow["Amount"] = qty * price;
                    //dtNrow["Confirm"] = row["Confirm"];
                    //dtNrow["TranType"] = row["TranType"];
                    dtDetail.Rows.Add(dtNrow);

                }
                //tbTotalVoucher.Text = dtinvoice.Compute("Count(DocumentID)", "TranType = 1 and Confirm = 1").ToString();
                //decimal.TryParse(dtinvoice.Compute("sum(Amount)", "").ToString(), out vAmount);
                //tbVoucherAmount.Text = vAmount.ToString("#,##0");

            }
            else if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                SqlParameter[] COarg = new SqlParameter[6];
                COarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); COarg[0].Value = dtpDate.Value.ToString("yyyy-MM-dd");
                COarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); COarg[1].Value = dtpDate.Value.ToString("yyyy-MM-dd");
                COarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); COarg[2].Value = "";
                COarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); COarg[3].Value = "";
                COarg[4] = new SqlParameter("@Customer", SqlDbType.NVarChar); COarg[4].Value = "";
                COarg[5] = new SqlParameter("@UserID", SqlDbType.Int); COarg[5].Value = LocalData.UserID;

                DBConnection.ExecSp("CustomerOutstand", COarg);

                DataTable dt;
                sdaDetail = new SqlDataAdapter("select C.ID, Balance from GeneralLedgerDetail GL Join Customer C on GL.Short = C.Short Where UserID = " + LocalData.UserID.ToString() + " and AccountName = 'Closing' and Balance > 0 order by GL.Short ", DBConnection.ActiveConnection);
                dt = new DataTable();
                sdaDetail.Fill(dt);

                dtDetail.Rows.Clear();
                DataRow dtNrow;
                int i = 0;
                int qty, price;
                foreach (DataRow row in dt.Rows)
                {
                    dtNrow = dtDetail.NewRow();
                    dtNrow["Sr"] = ++i;
                    dtNrow["CustomerID"] = row["ID"];
                    dtNrow["Amount"] = row["Balance"];
                    //dtNrow["Confirm"] = row["Confirm"];
                    //dtNrow["TranType"] = row["TranType"];
                    dtDetail.Rows.Add(dtNrow);

                }
            }
        }

        private void frm_CustOpening_Load(object sender, EventArgs e)
        {
            Boolean opn = true;
            dtHead = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                this.Text = "Customer Opening Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, Remark, Amount, UserID, EditDate, isOpening From CustomerOpeningHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                gbOpening.Visible = true;
                btBalance.Visible = true;
            }
            if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                lbLocation.Text = "Currency :";
                cbCurrency.DataSource = DBConnection.GetSQLTable("Select ID,Name From Currency  order by Name");
                cbCurrency.DisplayMember = "Name";
                cbCurrency.ValueMember = "ID";
                cbCurrency.SelectedValue = 1;

                this.Text = "Supplier Opening Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, CurrencyID, ExgRate, Remark, Amount, UserID, EditDate, isOpening From SupplierOpeningHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                gbOpening.Visible = true;
            }
            else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                this.Text = "Manufacturer Opening Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, Remark, Amount, UserID, EditDate, isOpening From ManufacturerOpeningHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                gbOpening.Visible = true;
            }
            else if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                lbLocation.Text = "Location :";
                cbCurrency.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
                cbCurrency.DisplayMember = "Name";
                cbCurrency.ValueMember = "ID";
                cbCurrency.SelectedValue = 1;

                this.Text = "Stock Opening Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, Remark, Amount, UserID, EditDate From StockOpeningHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lbLocation.Visible = true;
                cbCurrency.Visible = true;
                lbCode.Visible = true;
                tbCode.Visible = true;
                btFill.Visible = true;
                btBalance.Visible = true;
            }

            if (ID <= 0)
            {
                dtHead.Rows.Add(dtHead.NewRow());
                dtHead.Rows[0]["Date"] = LocalData.SettingDate.Date;
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
                {
                    dtHead.Rows[0]["CurrencyID"] = 1;
                    dtHead.Rows[0]["ExgRate"] = 1;
                }
            }
            else
            {
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();
                if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
                {
                    Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isOpening,1) from SupplierOpeningHead Where ID = " + ID.ToString()).ToString(), out opn);
                    rbOpening.Checked = opn;
                }
                else if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
                {
                    Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isOpening,1) from CustomerOpeningHead Where ID = " + ID.ToString()).ToString(), out opn);
                    rbOpening.Checked = opn;

                }
                else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
                {
                    Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isOpening,1) from ManufacturerOpeningHead Where ID = " + ID.ToString()).ToString(), out opn);
                    rbOpening.Checked = opn;

                }
            }

            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbAmount.DataBindings.Add("Text", dtHead, "Amount");
            if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                cbCurrency.DataBindings.Add("SelectedValue", dtHead, "LocationID");
            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                cbCurrency.DataBindings.Add("SelectedValue", dtHead, "CurrencyID");
                tbExgRate.DataBindings.Add("Text", dtHead, "ExgRate");
            }

            FillDataGridView();

            tbDocumentID.Focus();
        }

        private void FillDataGridView()
        {

            //int.TryParse(cbSaleType.SelectedValue.ToString(),out SaleTypeID);

            dtDetail = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.CustomerOpening)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CustomerID, Customer = C.Short + ' - '+ C.Name,  Amount From CustomerOpeningDetail D Join Customer C on D.CustomerID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CustomerID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Customer"].Width = 600;
                dgvDetail.Columns["Amount"].Width = 250;
            }
            else if (LocalData.Menu == LocalData.myMenu.SupplierOpening)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, SupplierID, Supplier = C.Short + ' - '+ C.Name,  Amount From SupplierOpeningDetail D Join Supplier C on D.SupplierID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["SupplierID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Supplier"].Width = 600;
                dgvDetail.Columns["Amount"].Width = 250;
            }
            else if (LocalData.Menu == LocalData.myMenu.ManufacturerOpening)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, ManufacturerID, Manufacturer = C.Short + ' - '+ C.Name,  Amount From ManufacturerOpeningDetail D Join Manufacturer C on D.ManufacturerID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["ManufacturerID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Manufacturer"].Width = 600;
                dgvDetail.Columns["Amount"].Width = 250;
            }
            else if (LocalData.Menu == LocalData.myMenu.StockOpening)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID, Code = S.Short, Name = S.Name, BrandID, UnitID, Qty, Price,  Amount From StockOpeningDetail D Join Stock S on D.CodeID = S.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["BrandID"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 50;
                dgvDetail.Columns["Code"].Width = 200;
                dgvDetail.Columns["Name"].Width = 400;
                dgvDetail.Columns["Amount"].Width = 250;


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

            dgvDetail.Columns["Amount"].ReadOnly = false;
            dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;


        }
    }
}
