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

    public partial class frm_Manufacture : Form
    {
        public static int PrintID = 0;
        int ID, codeid;
        private SqlDataAdapter sdaHead, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dtHead, dtDetail;
        Form frm;
        delegate void SetComboBoxCellType(int rIndex);
        bool isComboBox = false, isFactory = true;
        ReportDocument rd;

        private void dgvDetail_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            int UnitID, Discount, Qty1, Qty2;
            decimal Weight, Qty, TotalWeight, Price;
            string Code;

            if (LocalData.Menu == LocalData.myMenu.RawIssue)
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
                        dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

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
                        if (codeid > 0)
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
            else if (LocalData.Menu == LocalData.myMenu.ReturnStock || LocalData.Menu == LocalData.myMenu.GetStock)
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
                        }
                        else
                        {
                            MessageBox.Show("Please Check your Code !!!");
                            return;
                        }
                        break;
                    case 7:
                    case 8:
                        decimal _qtyRs;
                        dgvDetail.EndEdit();
                        int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                        decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out _qtyRs);
                        dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * _qtyRs;
                        int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                        int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                        dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(PurPrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                        dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

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

            else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
            {
                if (isFactory)
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
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

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
                            dgvDetail.CurrentRow.Cells["Price"].Value = DBConnection.rExecSQL("select isnull(SalePrice,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);

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
                        case 9:
                        case 10:
                            dgvDetail.EndEdit();
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
            else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
            {
                if (isFactory)
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
                            }
                            else
                            {
                                MessageBox.Show("Please Check your Code !!!");
                                return;
                            }
                            break;
                        case 7:
                        case 8:

                            decimal _qtyGr;
                            dgvDetail.EndEdit();
                            int.TryParse(dgvDetail.CurrentRow.Cells["Qty1"].Value.ToString(), out Qty1);
                            decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty2"].Value.ToString(), out _qtyGr);
                            dgvDetail.CurrentRow.Cells["Qty"].Value = Qty1 * _qtyGr;
                            int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                            int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                            dgvDetail.CurrentRow.Cells["Weight"].Value = DBConnection.rExecSQL("select isnull(Weight,0) From StockDetail where StockID = " + codeid + " and UnitID = " + UnitID);
                            Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                            decimal.TryParse(dgvDetail.CurrentRow.Cells["Weight"].Value.ToString(), out Weight);
                            dgvDetail.CurrentRow.Cells["TotalWeight"].Value = (Weight * Qty);
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
                                dgvDetail.CurrentRow.Cells["Brand"].Value = -1;
                            }
                            else
                            {
                                MessageBox.Show("Please Check your Code !!!");
                                return;
                            }
                            break;
                        case 9:
                        case 10:
                            dgvDetail.EndEdit();
                            int.TryParse(dgvDetail.CurrentRow.Cells["CodeID"].Value.ToString(), out codeid);
                            int.TryParse(dgvDetail.CurrentRow.Cells["Unit"].Value.ToString(), out UnitID);
                            Decimal.TryParse(dgvDetail.CurrentRow.Cells["Qty"].Value.ToString(), out Qty);
                            decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetMinQty(" + codeid.ToString() + "," + UnitID.ToString() + ",1)").ToString(), out Weight);
                            dgvDetail.CurrentRow.Cells["MinQty"].Value = Weight;
                            dgvDetail.CurrentRow.Cells["TotalMinQty"].Value = Weight * Qty;
                            dgvDetail.CurrentRow.Cells["Remark"].Value = DBConnection.rExecSQL("Select dbo.GetOrderDetailRemark(" + codeid.ToString() + "," + UnitID.ToString() + "," + Qty.ToString() + ")");

                            break;

                        default:
                            break;
                    }
                }

            }
        }

        private void dgvDetail_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            //if (e.ColumnIndex == 2 || e.ColumnIndex == 5 || e.ColumnIndex == 12 || e.ColumnIndex == 14)
            if (e.ColumnIndex == 2 )
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

        private void cbSupplier_DropDownClosed(object sender, EventArgs e)
        {
            Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isFactory,0) From Manufacturer Where ID = " + cbSupplier.SelectedValue.ToString()).ToString(), out isFactory);
            if (LocalData.Menu == LocalData.myMenu.GetStock)
            {
                lbOrder.Visible = false;
                cbOrder.Visible = false;
                if (ID <= 0)
                {
                    FillReturnStock();
                }
                else
                {
                    FillDataGridView();
                }
            }
            else
            {
                if (!isFactory)
                {
                    lbOrder.Visible = true;
                    cbOrder.Visible = true;
                }
                else
                {
                    lbOrder.Visible = false;
                    cbOrder.Visible = false;
                }


                cbOrder.DataSource = DBConnection.GetSQLTable("Select ID = RefID, Name = Short + '-' + Customer + '  ['+ Format(Date,'dd/MM/yyyy') + ']'  From dbo.GetSaleOrderBalManu() Group By RefID, Short, Customer, Date order by Short");
                cbOrder.DisplayMember = "Name";
                cbOrder.ValueMember = "ID";
                cbOrder.SelectedValue = 17;

                if (ID > 0)
                {
                    FillDataGridView();
                }
            }

            GetBalance();

        }

        private void GetBalance()
        {
            decimal Opn;
            dtHead.Rows[0]["ManufacturerID"] = cbSupplier.SelectedValue;

            bool.TryParse(DBConnection.roExecSQL("Select isnull(isFactory,0) From Manufacturer Where ID = " + cbSupplier.SelectedValue.ToString()).ToString(), out isFactory);

            tbPhone.Text = DBConnection.rExecSQL("Select Phone From Manufacturer Where ID = " + cbSupplier.SelectedValue.ToString());
            //tbAddress.Text = DBConnection.rExecSQL("Select Address From Customer Where ID = " + cbCustomer.SelectedValue.ToString());

            decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetManufacturerBalance( " + cbSupplier.SelectedValue.ToString() + ")").ToString(), out Opn);
            tbCreditBalance.Text = Opn.ToString("#,##0");
            decimal.TryParse(DBConnection.rExecSQL("Select dbo.GetReceivableStock( " + cbSupplier.SelectedValue.ToString() + ")").ToString(), out Opn);
            tbWBalance.Text = Opn.ToString("#,##0");
        }

        private void cbSupplier_SelectionChangeCommitted(object sender, EventArgs e)
        {
            Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isFactory,0) From Manufacturer Where ID = " + cbSupplier.SelectedValue.ToString()).ToString(), out isFactory);
            if (LocalData.Menu == LocalData.myMenu.GetStock)
            {
                lbOrder.Visible = false;
                cbOrder.Visible = false;
                if (ID <= 0)
                {
                    FillReturnStock();
                }
                else
                {
                    FillDataGridView();
                }
            }
            else
            {
                if (!isFactory)
                {
                    lbOrder.Visible = true;
                    cbOrder.Visible = true;
                }
                else
                {
                    lbOrder.Visible = false;
                    cbOrder.Visible = false;
                }

                cbOrder.DataSource = DBConnection.GetSQLTable("Select ID = RefID, Name = Short + '-' + Customer + '  ['+ Format(Date,'dd/MM/yyyy') + ']'  From dbo.GetSaleOrderBalManu() Group By RefID, Short, Customer, Date order by Short");
                cbOrder.DisplayMember = "Name";
                cbOrder.ValueMember = "ID";
                cbOrder.SelectedValue = 17;

                FillDataGridView();
            }
            GetBalance();
        }

        private void cbSupplier_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbSupplier.DroppedDown = true;
            LocalData.AutoComplete(cbSupplier, e, true);
        }

        private void cbLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbLocation.DroppedDown = true;
            LocalData.AutoComplete(cbLocation, e, true);
        }

        private void dgvDetail_RowValidated(object sender, DataGridViewCellEventArgs e)
        {
            CalculateNetAmount();
        }
        private void CalculateNetAmount()
        {
            decimal NetAmount, amount, discount, tax, charges, TotalAmount, TotalWeight, PaidAmount, BalanceAmount, WeightBalance, CurWeightBalance;
            int Qty;

            if (LocalData.Menu != LocalData.myMenu.GoodsRecieveManu)
            {
                decimal.TryParse(dtDetail.Compute("Sum(Amount)", "").ToString(), out amount);
                dtHead.Rows[0]["Amount"] = amount;
                tbAmount.Text = amount.ToString("#,##0");
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
                //dtHead.Rows[0]["AddAmount"] = charges;
                dtHead.Rows[0]["PaidAmount"] = PaidAmount;
                tbTotalAmount.Text = (amount - discount + tax + charges).ToString("#,##0");
                tbNetBalance.Text = (BalanceAmount + amount - discount + tax + charges - PaidAmount).ToString("#,##0");
                dtHead.Rows[0]["TotalAmount"] = amount - discount + tax + charges;
                dtHead.Rows[0]["TotalBalance"] = BalanceAmount + amount - discount + tax + charges - PaidAmount;
            }

            if (LocalData.Menu == LocalData.myMenu.RawIssue
                || LocalData.Menu == LocalData.myMenu.ReturnStock
                || LocalData.Menu == LocalData.myMenu.GetStock)
            {
                decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
                tbTotalWeight.Text = TotalWeight.ToString("#.##0");
                dtHead.Rows[0]["TotalWeight"] = TotalWeight;
                decimal.TryParse(tbWBalance.Text.ToString(), out WeightBalance);
                dtHead.Rows[0]["WeightBalance"] = WeightBalance;
                tbTotalWBalance.Text = (WeightBalance - TotalWeight).ToString("#.##0");
                dtHead.Rows[0]["CurrentWeightBalance"] = WeightBalance - TotalWeight;
                int totalqty;
                int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out totalqty);
                tbTotalQty.Text = totalqty.ToString();
            }
            else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
            {
                if (isFactory)
                {
                    decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
                    tbTotalWeight.Text = TotalWeight.ToString("#.##0");
                    dtHead.Rows[0]["TotalWeight"] = TotalWeight;
                    decimal.TryParse(tbWBalance.Text.ToString(), out WeightBalance);
                    dtHead.Rows[0]["WeightBalance"] = WeightBalance;
                    tbTotalWBalance.Text = (WeightBalance - TotalWeight).ToString("#.##0");
                    dtHead.Rows[0]["CurrentWeightBalance"] = WeightBalance - TotalWeight;
                    int totalqty;
                    int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out totalqty);
                    tbTotalQty.Text = totalqty.ToString();
                }
                else
                {
                    decimal.TryParse(dtDetail.Compute("Sum(TotalMinQty)", "").ToString(), out TotalWeight);
                    tbTotalWeight.Text = TotalWeight.ToString("#.##0");
                    dtHead.Rows[0]["TotalWeight"] = TotalWeight;
                    decimal.TryParse(tbWBalance.Text.ToString(), out WeightBalance);
                    dtHead.Rows[0]["WeightBalance"] = WeightBalance;
                    tbTotalWBalance.Text = (WeightBalance - TotalWeight).ToString("#.##0");
                    dtHead.Rows[0]["CurrentWeightBalance"] = WeightBalance - TotalWeight;
                    int totalqty;
                    int.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out totalqty);
                    tbTotalQty.Text = totalqty.ToString();
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
            {
                if (isFactory)
                {
                    decimal.TryParse(dtDetail.Compute("Sum(TotalWeight)", "").ToString(), out TotalWeight);
                    tbTotalWeight.Text = TotalWeight.ToString("#.##0");
                    dtHead.Rows[0]["TotalWeight"] = TotalWeight;
                    decimal.TryParse(tbWBalance.Text.ToString(), out WeightBalance);
                    dtHead.Rows[0]["WeightBalance"] = WeightBalance;
                    tbTotalWBalance.Text = (WeightBalance - TotalWeight).ToString("#.##0");
                    dtHead.Rows[0]["CurrentWeightBalance"] = WeightBalance - TotalWeight;
                    int totalqty;
                    int.TryParse(dtDetail.Compute("Sum(Qty1)", "").ToString(), out totalqty);
                    tbTotalQty.Text = totalqty.ToString();
                }
                else
                {
                    decimal.TryParse(dtDetail.Compute("Sum(TotalMinQty)", "").ToString(), out TotalWeight);
                    tbTotalWeight.Text = TotalWeight.ToString("#.##0");
                    dtHead.Rows[0]["TotalWeight"] = TotalWeight;
                    decimal.TryParse(tbWBalance.Text.ToString(), out WeightBalance);
                    dtHead.Rows[0]["WeightBalance"] = WeightBalance;
                    tbTotalWBalance.Text = (WeightBalance - TotalWeight).ToString("#.##0");
                    dtHead.Rows[0]["CurrentWeightBalance"] = WeightBalance - TotalWeight;
                    int totalqty;
                    int.TryParse(dtDetail.Compute("Sum(Qty)", "").ToString(), out totalqty);
                    tbTotalQty.Text = totalqty.ToString();
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
            frm_Manufacture_Load(sender, e);
        }

        private void cbOrder_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbOrder.DroppedDown = true;
            LocalData.AutoComplete(cbOrder, e, true);
        }

        private void cbOrder_DropDownClosed(object sender, EventArgs e)
        {
            FillOrder();
        }

        private void FillOrder()
        {
            dtDetail.Rows.Clear();
            DataTable dtfill;
            dtfill = new DataTable();
            dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, S.Short, S.Name, Remark From dbo.GetSaleOrderBalManu() B Join Stock S on B.CodeID = S.ID Where RefID = " + cbOrder.SelectedValue.ToString());
            DataRow dtNrow;
            int i = 0;
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
                dtNrow["Remark"] = row["Remark"];

                dtDetail.Rows.Add(dtNrow);

            }

        }

        private void FillReturnStock()
        {
            int manuID;
            int.TryParse(cbSupplier.SelectedValue.ToString(), out manuID);
            dtDetail.Rows.Clear();
            DataTable dtfill;
            dtfill = new DataTable();
            dtfill = DBConnection.GetSQLTable("Select B.RefID, B.CodeID, B.BrandID, B.UnitID, B.Qty, S.Short, S.Name  From dbo.GetReturnStockByGetStock(" + manuID.ToString() + ") B Join Stock S on B.CodeID = S.ID ");
            DataRow dtNrow;
            int i = 0;
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

                dtDetail.Rows.Add(dtNrow);

            }

        }

        private void cbOrder_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillOrder();
        }

        private void dgvDetail_CellLeave(object sender, DataGridViewCellEventArgs e)
        {
            //if (e.ColumnIndex == 7 || e.ColumnIndex == 8)
            //{
            //    dgvDetail_CellEndEdit(sender, e);
            //}
            
        }

        private void label4_Click(object sender, EventArgs e)
        {

        }

        private void btSave_Click(object sender, EventArgs e)
        {
            saveToolStripMenuItem_Click(sender, e);
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
                erptransaction.SetError(cbSupplier, "Select Manufacturer!");
                return;
            }




            //dgvDetail.RefreshEdit();
            //dgvDetail.CurrentCell = dgvDetail.Rows[dgvDetail.NewRowIndex].Cells["Code"];


            DateTime e_Date;
            Boolean Receive;

            Receive = chkReceive.Checked;
            e_Date = Convert.ToDateTime(DBConnection.rExecSQL("select Getdate()"));
            //dtHead.Rows[0]["Date"] = dtpDate.Value.Date + e_Date.TimeOfDay;
            //dtHead.Rows[0]["StockReceived"] = Receive;
            dtHead.Rows[0]["UserID"] = LocalData.UserID;
            dtHead.Rows[0]["EditDate"] = e_Date;
            //dtHead.Rows[0]["LoginID"] = LocalData.LoginID;
            dtHead.Rows[0].EndEdit();

            scb = new SqlCommandBuilder(sdaHead);
            sdaHead.Update(dtHead);


            if (ID <= 0)
            {
                if (LocalData.Menu == LocalData.myMenu.RawIssue)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from RawIssueHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.RawIssue, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.ReturnStock)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from ReturnStockHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    LocalData.SetAutoID(LocalData.myMenu.ReturnStock, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from FinishGoodsHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    //int.TryParse(DBConnection.roExecSQL("Select Max(Invoiceno) from SaleHead Where isnull(Deleted,0)<> 1 and FromBranchID =" + LocalData.LogInBranchID.ToString()).ToString(), out Invoiceno);
                    LocalData.SetAutoID(LocalData.myMenu.FinishGoods, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.GetStock)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from GetStockHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    LocalData.SetAutoID(LocalData.myMenu.GetStock, dtpDate.Value);
                }
                else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from FinishGoodsHead Where isnull(Deleted,0)<> 1 ").ToString(), out ID);
                    LocalData.SetAutoID(LocalData.myMenu.FinishGoods, dtpDate.Value);
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

            if (LocalData.Menu == LocalData.myMenu.RawIssue)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Weight, Price, TotalWeight, Amount, Remark from RawIssueDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnStock)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Weight, Price, TotalWeight, Amount, Remark from ReturnStockDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Weight, Price, TotalWeight, Amount, Remark, MinQty, TotalMinQty, OrderRefID, PurchasePrice from FinishGoodsDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.GetStock)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Weight, Price, TotalWeight, Amount, Remark, OrderRefID from GetStockDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
            {
                sdaDetail = new SqlDataAdapter("Select ID, RefID, Sr, CodeID, BrandID, UnitID, Qty, Qty1, Qty2, Weight, TotalWeight, Remark, MinQty, TotalMinQty, OrderRefID from FinishGoodsDetail where refID = " + ID.ToString(), DBConnection.ActiveConnection);
            }

            scb = new SqlCommandBuilder(sdaDetail);
            sdaDetail.Update(dtDetail);

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
            cbPayment.DataBindings.Clear();
            cbSupplier.DataBindings.Clear();
            cbOrder.DataBindings.Clear();
            cbAccount.DataBindings.Clear();
            tbRemark.DataBindings.Clear();
            tbCreditBalance.DataBindings.Clear();
            tbAmount.DataBindings.Clear();
            tbDiscount.DataBindings.Clear();
            tbNetAmount.DataBindings.Clear();
            tbTax.DataBindings.Clear();
            //tbCharges.DataBindings.Clear();
            tbTotalAmount.DataBindings.Clear();
            tbPaidAmount.DataBindings.Clear();
            tbNetBalance.DataBindings.Clear();

            tbWBalance.DataBindings.Clear();
            tbTotalWeight.DataBindings.Clear();
            tbTotalWBalance.DataBindings.Clear();

            ID = 0;

        }

        private void btPrint_Click(object sender, EventArgs e)
        {
            printToolStripMenuItem_Click(sender, e);
        }

        private void printToolStripMenuItem_Click(object sender, EventArgs e)
        {
            rd = new ReportDocument();
            PrintDocument localPrinter = new PrintDocument();
            rd.PrintOptions.PrinterName = localPrinter.PrinterSettings.PrinterName;

            if (LocalData.Menu == LocalData.myMenu.RawIssue)
            {
                Save();
                rd.FileName = Environment.CurrentDirectory + @"\Reports\RawInvoice.rpt";
                rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                rd.SetDatabaseLogon("sa", "27042005@MND");

                rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID,  C.Name, Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, D.Amount, Qty1, Qty2, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID   Where H.ID = " + frm_Manufacture.PrintID.ToString()));

                rd.PrintToPrinter(2, false, 0, 0);
                frm_Manufacture_Load(sender, e);
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnStock)
            {
                Save();
                rd.FileName = Environment.CurrentDirectory + @"\Reports\RawInvoice.rpt";
                rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                rd.SetDatabaseLogon("sa", "27042005@MND");

                rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID,  C.Name, Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, D.Amount, Qty1, Qty2, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark from ReturnStockHead H Join ReturnStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID   Where H.ID = " + frm_Manufacture.PrintID.ToString()));

                rd.PrintToPrinter(2, false, 0, 0);
                frm_Manufacture_Load(sender, e);
            }
        }

        public frm_Manufacture(int m_ID)
        {
            ID = m_ID;
            InitializeComponent();
        }

        private void frm_Manufacture_Load(object sender, EventArgs e)
        {
            cbLocation.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Location where isnull(Deleted,0) <> 1 order by Name");
            cbLocation.DisplayMember = "Name";
            cbLocation.ValueMember = "ID";
            cbLocation.SelectedValue = 1;

            cbPayment.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From PaymentType where isnull(Deleted,0) <> 1 order by Name");
            cbPayment.DisplayMember = "Name";
            cbPayment.ValueMember = "ID";
            cbPayment.SelectedValue = 2;

            cbSupplier.DataSource = DBConnection.GetSQLTable("Select ID,Name = Short + ' - '+ Name From Manufacturer where isnull(Deleted,0) <> 1 order by Short");
            cbSupplier.DisplayMember = "Name";
            cbSupplier.ValueMember = "ID";
            cbSupplier.SelectedValue = 17;

            dtHead = new DataTable();

            if (LocalData.Menu == LocalData.myMenu.RawIssue || LocalData.Menu == LocalData.myMenu.ReturnStock || LocalData.Menu == LocalData.myMenu.GetStock)
            {
                if (LocalData.Menu == LocalData.myMenu.RawIssue)
                {
                    this.Text = "Raw Issue Entry";
                    sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, ManufacturerID,  PaymentID, AccountID, Remark, Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, WeightBalance, TotalWeight, CurrentWeightBalance, UserID, EditDate From RawIssueHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                    sdaHead.Fill(dtHead);
                }
                else if (LocalData.Menu == LocalData.myMenu.ReturnStock)
                {
                    this.Text = "Return Stock Entry";
                    sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, ManufacturerID,  PaymentID, AccountID, Remark, Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, WeightBalance, TotalWeight, CurrentWeightBalance, UserID, EditDate From ReturnStockHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                    sdaHead.Fill(dtHead);
                }
                else if (LocalData.Menu == LocalData.myMenu.GetStock)
                {
                    this.Text = "Get Stock Entry";
                    sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, ManufacturerID,  PaymentID, AccountID, Remark, Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, WeightBalance, TotalWeight, CurrentWeightBalance, UserID, EditDate From GetStockHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                    sdaHead.Fill(dtHead);
                }

                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbAmount.Visible = false;
                tbAmount.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
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
            else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
            {
                this.Text = "Finished Goods Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, ManufacturerID, SaleOrderID,  PaymentID, AccountID, Remark, Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, WeightBalance, TotalWeight, CurrentWeightBalance, UserID, EditDate From FinishGoodsHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
            {
                this.Text = "Goods Receive Entry";
                sdaHead = new SqlDataAdapter("Select ID, Date, AutoID, DocumentID, LocationID, ManufacturerID, SaleOrderID,  PaymentID, AccountID, Remark, Balance, Amount, Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, WeightBalance, TotalWeight, CurrentWeightBalance, UserID, EditDate From FinishGoodsHead where ID = " + ID.ToString(), DBConnection.ActiveConnection);
                sdaHead.Fill(dtHead);
                lbCreditBalance.Visible = false;
                tbCreditBalance.Visible = false;
                lbAmount.Visible = false;
                tbAmount.Visible = false;
                lbDiscount.Visible = false;
                tbDiscount.Visible = false;
                lbNetAmount.Visible = false;
                tbNetAmount.Visible = false;
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
                dtHead.Rows[0]["AutoID"] = DBConnection.rExecSQL("Select dbo.GetAutoID(" + LocalData.UserID.ToString() + ", '" + dtpDate.Value.ToString("yyyy-MM-dd") + "'," + ((int)LocalData.Menu).ToString() + ")").ToString();
                dtHead.Rows[0]["ManufacturerID"] = 1;
                dtHead.Rows[0]["LocationID"] = 1;
                //dtHead.Rows[0]["PaymentID"] = 1;
                //dtHead.Rows[0]["AccountID"] = 1;
                dtHead.Rows[0]["Amount"] = 0;
                dtHead.Rows[0]["UserID"] = LocalData.UserID;

            }
            else
            {
                int i, CustID;
                int.TryParse(dtHead.Rows[0]["ManufacturerID"].ToString(), out CustID);
                tbPhone.Text = DBConnection.rExecSQL("Select isnull(Phone,'') From Manufacturer Where ID = " + CustID.ToString());

                int.TryParse(dtHead.Rows[0]["PaymentID"].ToString(), out i);
                tbDocumentID.Text = dtHead.Rows[0]["DocumentID"].ToString();

            }

            dtpDate.DataBindings.Add("Value", dtHead, "Date");
            tbAutoID.DataBindings.Add("Text", dtHead, "AutoID");
            tbDocumentID.DataBindings.Add("Text", dtHead, "DocumentID");
            cbLocation.DataBindings.Add("SelectedValue", dtHead, "LocationID");
            cbPayment.DataBindings.Add("SelectedValue", dtHead, "PaymentID");
            cbSupplier.DataBindings.Add("SelectedValue", dtHead, "ManufacturerID");
            //cbAccount.DataBindings.Add("SelectedValue", dtHead, "AccountID");
            tbRemark.DataBindings.Add("Text", dtHead, "Remark");
            tbCreditBalance.DataBindings.Add("Text", dtHead, "Balance");
            tbAmount.DataBindings.Add("Text", dtHead, "Amount");
            tbDiscount.DataBindings.Add("Text", dtHead, "Discount");
            tbNetAmount.DataBindings.Add("Text", dtHead, "NetAmount");
            tbTax.DataBindings.Add("Text", dtHead, "TaxAmount");
            //tbCharges.DataBindings.Add("Text", dtHead, "AddAmount");
            tbTotalAmount.DataBindings.Add("Text", dtHead, "TotalAmount");
            tbPaidAmount.DataBindings.Add("Text", dtHead, "PaidAmount");
            tbNetBalance.DataBindings.Add("Text", dtHead, "TotalBalance");

            tbWBalance.DataBindings.Add("Text", dtHead, "WeightBalance");
            tbTotalWeight.DataBindings.Add("Text", dtHead, "TotalWeight");
            tbTotalWBalance.DataBindings.Add("Text", dtHead, "CurrentWeightBalance");

            FillDataGridView();

            cbSupplier.Focus();

        }

        private void FillDataGridView()
        {
            
            Boolean.TryParse(DBConnection.roExecSQL("Select isnull(isFactory,0) From Manufacturer Where ID = " + cbSupplier.SelectedValue.ToString()).ToString(), out isFactory);

            dtDetail = new DataTable();
            if (LocalData.Menu == LocalData.myMenu.RawIssue)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark From RawIssueDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Price"].Visible = false;
                dgvDetail.Columns["Amount"].Visible = false;
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
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.ReturnStock)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark From ReturnStockDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Price"].Visible = false;
                dgvDetail.Columns["Amount"].Visible = false;
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

                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.FinishGoods)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, MinQty, TotalMinQty, PurchasePrice, Remark, OrderRefID From FinishGoodsDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;

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

                ChangeGridView();
            }
            else if (LocalData.Menu == LocalData.myMenu.GetStock)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Price,  Amount, Weight, TotalWeight, Remark, OrderRefID From GetStockDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Price"].Visible = false;
                dgvDetail.Columns["Amount"].Visible = false;
                dgvDetail.Columns["OrderRefID"].Visible = false;
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

                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Price"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Amount"].ReadOnly = true;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Amount"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
            }
            else if (LocalData.Menu == LocalData.myMenu.GoodsRecieveManu)
            {
                sdaDetail = new SqlDataAdapter("select D.ID, RefID, Sr, CodeID,Code = C.Short, Name = C.Name, BrandID, Qty1, Qty2, Qty, UnitID , Weight, TotalWeight, MinQty, TotalMinQty, Remark, OrderRefID From FinishGoodsDetail D Join Stock C on CodeID = C.ID Where RefID = " + ID.ToString() + " Order by Sr", DBConnection.ActiveConnection);
                sdaDetail.Fill(dtDetail);

                dgvDetail.DataSource = dtDetail;

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

                ChangeGridView();
            }


        }

        private void ChangeGridView()
        {
            if (isFactory)
            {
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["TotalMinQty"].Visible = false;
                dgvDetail.Columns["MinQty"].Visible = false;
                dgvDetail.Columns["OrderRefID"].Visible = false;
                dgvDetail.Columns["Remark"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 150;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 300;
                dgvDetail.Columns["Qty"].Width = 80;
                dgvDetail.Columns["Qty1"].Width = 50;
                dgvDetail.Columns["Qty1"].HeaderText = "PK";
                dgvDetail.Columns["Qty2"].Width = 50;
                dgvDetail.Columns["Qty2"].HeaderText = "";
                dgvDetail.Columns["Weight"].Width = 80;
                dgvDetail.Columns["TotalWeight"].Width = 120;

                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["Weight"].ReadOnly = true;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Weight"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalWeight"].ReadOnly = true;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalWeight"].DefaultCellStyle.Format = "#.###";
                if (LocalData.Menu != LocalData.myMenu.GoodsRecieveManu)
                {
                    dgvDetail.Columns["Price"].Width = 100;
                    dgvDetail.Columns["Amount"].Width = 130;
                    dgvDetail.Columns["PurchasePrice"].Width = 130;
                    dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["Price"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                    dgvDetail.Columns["PurchasePrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["PurchasePrice"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                    dgvDetail.Columns["Amount"].ReadOnly = true;
                    dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                }

            }
            else
            {
                dgvDetail.Columns["ID"].Visible = false;
                dgvDetail.Columns["RefID"].Visible = false;
                dgvDetail.Columns["CodeID"].Visible = false;
                dgvDetail.Columns["Weight"].Visible = false;
                dgvDetail.Columns["TotalWeight"].Visible = false;
                dgvDetail.Columns["MinQty"].Visible = false;
                dgvDetail.Columns["TotalMinQty"].Visible = true;
                dgvDetail.Columns["OrderRefID"].Visible = false;
                dgvDetail.Columns["Qty1"].Visible = false;
                dgvDetail.Columns["Qty2"].Visible = false;
                dgvDetail.Columns["Sr"].ReadOnly = true;
                dgvDetail.Columns["Sr"].Width = 40;
                dgvDetail.Columns["Code"].Width = 150;
                dgvDetail.Columns["Name"].HeaderText = "Description";
                dgvDetail.Columns["Name"].ReadOnly = true;
                dgvDetail.Columns["Name"].Width = 250;
                dgvDetail.Columns["Qty"].Width = 80;
                dgvDetail.Columns["TotalMinQty"].Width = 120;
                dgvDetail.Columns["TotalMinQty"].HeaderText = "Total Qty";
                dgvDetail.Columns["Remark"].Width = 150;

                dgvDetail.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["Qty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["MinQty"].ReadOnly = true;
                dgvDetail.Columns["MinQty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["MinQty"].DefaultCellStyle.Format = "#.###";
                dgvDetail.Columns["TotalMinQty"].ReadOnly = true;
                dgvDetail.Columns["TotalMinQty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                dgvDetail.Columns["TotalMinQty"].DefaultCellStyle.Format = "#.###";

                if (LocalData.Menu != LocalData.myMenu.GoodsRecieveManu)
                {
                    dgvDetail.Columns["Price"].Width = 100;
                    dgvDetail.Columns["Amount"].Width = 150;
                    dgvDetail.Columns["PurchasePrice"].Width = 150;
                    dgvDetail.Columns["Price"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["Price"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                    dgvDetail.Columns["PurchasePrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["PurchasePrice"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                    dgvDetail.Columns["Amount"].ReadOnly = true;
                    dgvDetail.Columns["Amount"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
                    dgvDetail.Columns["Amount"].DefaultCellStyle.Format = LocalData.IntegerFormat;
                }
            }
        }
    }
}
