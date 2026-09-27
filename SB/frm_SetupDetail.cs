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
    public partial class frm_SetupDetail : Form
    {
        int ID;
        private SqlDataAdapter sda, sdaDetail;
        private SqlCommandBuilder scb;
        private DataTable dt, dtDetail;
        public frm_SetupDetail(int sID)
        {
            ID = sID;
            InitializeComponent();
        }

        private void frm_SetupDetail_Load(object sender, EventArgs e)
        {
            string table = string.Empty;

            switch (LocalData.Setup)
            {
                case LocalData.mySetup.Branch:
                //    table = "Select ID, Short, Name From Branch Where isnull(Deleted,0)<>1";
                //    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                //    dt = new DataTable();
                //    dt.Rows.Clear();
                //    sda.Fill(dt);

                //    if (ID <= 0)
                //    {
                //        dt.Rows.Add(dt.NewRow());
                //    }
                //    tbShort.DataBindings.Add("Text", dt, "Short");
                //    tbName.DataBindings.Add("Text", dt, "Name");

                //    this.Height = 300;
                //    lbGroup.Visible = false;
                //    cbGroup.Visible = false;
                //    lbPhone.Visible = false;
                //    tbPhone.Visible = false;
                //    lbAddress.Visible = false;
                //    tbAddress.Visible = false;
                //    break;
                case LocalData.mySetup.Location:
                    table = "Select ID, Short, Name, TypeID From Location Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From LocationType order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "TypeID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Class:
                    break;
                case LocalData.mySetup.Category:
                    table = "Select ID, Short, Name, TypeID From StockGroup Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From StockType order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "TypeID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Code:
                    table = "Select ID, Short, Name, GroupID, StdUnitID From Stock Where ID =" + ID.ToString();
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short + ' - ' + Name From StockGroup Where isnull(Deleted,0)<>1 order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    cbUnit.DataSource = DBConnection.GetSQLTable("Select ID, Name From Unit Where isnull(Deleted,0)<>1 order by Name".ToString());
                    cbUnit.DisplayMember = "Name";
                    cbUnit.ValueMember = "ID";
                    cbUnit.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "GroupID");
                    cbUnit.DataBindings.Add("SelectedValue", dt, "StdUnitID");
                    FillStockDetailInfo();

                    this.Height = 600;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbPansar.Visible = false;
                    tbPansar.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    break;
                case LocalData.mySetup.Division:
                    table = "Select ID, Short, Name From Division Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);


                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    break;
                    
                case LocalData.mySetup.Township:
                    table = "Select ID, Short, Name, DivisionID From Township Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From Division order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "DivisionID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Customer:
                    Boolean credit;
                    table = "Select ID, Short, Name, TownshipID, Address, Info1, Info2, AllowCredit, DivID From Customer Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From Township order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    cbDivision.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short + '-' + Name From Division order by Name".ToString());
                    cbDivision.DisplayMember = "Name";
                    cbDivision.ValueMember = "ID";
                    cbDivision.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                        dt.Rows[0]["AllowCredit"] = 1;
                        chkCredit.Checked = true;
                    }
                    Boolean.TryParse(dt.Rows[0]["AllowCredit"].ToString(), out credit);
                    chkCredit.Checked = credit;
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "TownshipID");
                    tbAddress.DataBindings.Add("Text", dt, "Address");
                    tbPhone.DataBindings.Add("Text", dt, "Info1");
                    tbPansar.DataBindings.Add("Text", dt, "Info2");
                    cbDivision.DataBindings.Add("SelectedValue", dt, "DivID");

                    this.Height = 600;
                    lbPhone.Visible = true;
                    tbPhone.Visible = true;
                    lbAddress.Visible = true;
                    tbAddress.Visible = true;
                    lbPansar.Visible = true;
                    tbPansar.Visible = true;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    chkCredit.Visible = true;
                    lbDivision.Visible = true;
                    cbDivision.Visible = true;
                    break;
                case LocalData.mySetup.Supplier:
                    table = "Select ID, Short, Name, TownshipID From Supplier Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From Township order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "TownshipID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Manufacturer:
                    table = "Select ID, Short, Name, TownshipID From Manufacturer Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From Township order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "TownshipID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Transport:
                    table = "Select ID, Short, Name  From Transport Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");

                    this.Height = 350;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Gate:
                    table = "Select ID, Short, Name, Charges  From Gates Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    tbCharges.DataBindings.Add("Text", dt, "Charges");

                    this.Height = 380;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    lbCharges.Visible = true;
                    tbCharges.Visible = true;
                    lbCharges.Text = "Charges :";
                    break;
                case LocalData.mySetup.Cars:
                    table = "Select ID, Short, Name  From Cars Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");

                    this.Height = 350;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Account:
                    table = "Select ID, Short, Name, GroupID, SysAcctID, BankCharges, AccountCode  From AccountName Where ID =" + ID.ToString();
                    try
                    {
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                    }
                    catch
                    {
                        table = "Select ID, Short, Name, GroupID, SysAcctID, BankCharges  From AccountName Where ID =" + ID.ToString();
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                        if (!dt.Columns.Contains("AccountCode"))
                            dt.Columns.Add("AccountCode", typeof(string));
                    }

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From AcctGroup Where isnull(Deleted,0)<>1 order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    cbUnit.DataSource = DBConnection.GetSQLTable("Select ID, Name From SysAccount Where isnull(Deleted,0)<>1 order by Name".ToString());
                    cbUnit.DisplayMember = "Name";
                    cbUnit.ValueMember = "ID";
                    cbUnit.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    ShowAccountCodeRow();
                    if (dt.Columns.Contains("AccountCode"))
                        tbAccountCode.DataBindings.Add("Text", dt, "AccountCode");
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "GroupID");
                    cbUnit.DataBindings.Add("SelectedValue", dt, "SysAcctID");
                    tbCharges.DataBindings.Add("Text", dt, "BankCharges");

                    this.Height = 640;
                    dgvUnit.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbPansar.Visible = false;
                    tbPansar.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    tbCharges.Visible = true;
                    lbCharges.Visible = true;
                    // Charges below Group (after Account Code row shift)
                    tbCharges.Location = new System.Drawing.Point(117, 241);
                    lbCharges.Location = new System.Drawing.Point(12, 244);
                    break;
                case LocalData.mySetup.AcctGroup:
                    table = "Select ID, Short, Name, SubGroupID, GroupCode From AcctGroup Where ID = " + ID.ToString();
                    try
                    {
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                    }
                    catch
                    {
                        table = "Select ID, Short, Name, SubGroupID From AcctGroup Where ID = " + ID.ToString();
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                        if (!dt.Columns.Contains("GroupCode"))
                            dt.Columns.Add("GroupCode", typeof(string));
                    }

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From AcctSubGroup order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    ShowAccountCodeRow();
                    if (dt.Columns.Contains("GroupCode"))
                        tbAccountCode.DataBindings.Add("Text", dt, "GroupCode");
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "SubGroupID");

                    this.Height = 400;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.AcctSubGroup:
                    table = "Select ID, Short, Name, MainGroupID, SubGroupCode From AcctSubGroup Where ID = " + ID.ToString();
                    try
                    {
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                    }
                    catch
                    {
                        table = "Select ID, Short, Name, MainGroupID From AcctSubGroup Where ID = " + ID.ToString();
                        sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                        dt = new DataTable();
                        dt.Rows.Clear();
                        sda.Fill(dt);
                        if (!dt.Columns.Contains("SubGroupCode"))
                            dt.Columns.Add("SubGroupCode", typeof(string));
                    }

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name From AcctMainGroup order by Name".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;
                    lbGroup.Text = "Main Group : ";

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                        if (LocalData.PrefillMainGroupID > 0)
                            dt.Rows[0]["MainGroupID"] = LocalData.PrefillMainGroupID;
                    }
                    ShowAccountCodeRow();
                    if (dt.Columns.Contains("SubGroupCode"))
                        tbAccountCode.DataBindings.Add("Text", dt, "SubGroupCode");
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "MainGroupID");
                    if (ID <= 0 && LocalData.PrefillMainGroupID > 0)
                        cbGroup.SelectedValue = LocalData.PrefillMainGroupID;

                    this.Height = 400;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Unit:
                    table = "Select ID, Short, Name  From Unit Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");

                    this.Height = 350;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.Users:
                    break;
                case LocalData.mySetup.Brand:
                    table = "Select ID, Short, Name  From Brand Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    tbShort.DataBindings.Add("Text", dt, "Short");
                    tbName.DataBindings.Add("Text", dt, "Name");

                    this.Height = 350;
                    lbGroup.Visible = false;
                    cbGroup.Visible = false;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    break;
                case LocalData.mySetup.BrandNStock:
                    table = "Select ID, BrandID, StockGroupID From BrandNStockGroup Where ID = " + ID.ToString(); ;
                    sda = new SqlDataAdapter(table, DBConnection.ActiveConnection);
                    dt = new DataTable();
                    dt.Rows.Clear();
                    sda.Fill(dt);

                    cbGroup.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short + '-' + Name From StockGroup Where isnull(Deleted,0)<>1 order by Short".ToString());
                    cbGroup.DisplayMember = "Name";
                    cbGroup.ValueMember = "ID";
                    cbGroup.SelectedValue = 1;

                    cbBrand.DataSource = DBConnection.GetSQLTable("Select ID, Name = Short + '-' + Name From Brand Where isnull(Deleted,0)<>1 order by Short".ToString());
                    cbBrand.DisplayMember = "Name";
                    cbBrand.ValueMember = "ID";
                    cbBrand.SelectedValue = 1;

                    if (ID <= 0)
                    {
                        dt.Rows.Add(dt.NewRow());
                    }
                    cbBrand.DataBindings.Add("SelectedValue", dt, "BrandID");
                    cbGroup.DataBindings.Add("SelectedValue", dt, "SubGroupID");

                    this.Height = 350;
                    lbPhone.Visible = false;
                    tbPhone.Visible = false;
                    lbAddress.Visible = false;
                    tbAddress.Visible = false;
                    lbUnit.Visible = false;
                    cbUnit.Visible = false;
                    dgvUnit.Visible = false;
                    lbShort.Visible = false;
                    tbShort.Visible = false;
                    lbName.Visible = false;
                    tbName.Visible = false;
                    lbBrand.Visible = true;
                    cbBrand.Visible = true;
                    break;
                default:
                    break;
            }

        }

        private void FillStockDetailInfo()
        {
            sdaDetail = new SqlDataAdapter("select d.ID, StockID, UnitID, Qty, PurPrice, SalePrice, Weight from StockDetail d  where StockID = " + ID, DBConnection.ActiveConnection);
            dtDetail = new DataTable();
            sdaDetail.Fill(dtDetail);
            dgvUnit.DataSource = dtDetail;
            dgvUnit.Columns["ID"].Visible = false;
            dgvUnit.Columns["StockID"].Visible = false;
            //dgvUnit.Columns["UnitID"].Visible = false;
            dgvUnit.Columns["PurPrice"].Width = 100;
            dgvUnit.Columns["PurPrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvUnit.Columns["PurPrice"].DefaultCellStyle.Format = "#,##0";
            dgvUnit.Columns["PurPrice"].HeaderText = "Pur. Price";
            dgvUnit.Columns["SalePrice"].Width = 100;
            dgvUnit.Columns["SalePrice"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvUnit.Columns["SalePrice"].DefaultCellStyle.Format = "#,##0";
            dgvUnit.Columns["SalePrice"].HeaderText = "Sales Price";
            dgvUnit.Columns["Qty"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvUnit.Columns["Qty"].Width = 70;
            dgvUnit.Columns["Weight"].Width = 100;
            dgvUnit.Columns["Weight"].DefaultCellStyle.Alignment = DataGridViewContentAlignment.MiddleRight;
            dgvUnit.Columns["Weight"].DefaultCellStyle.Format = "#,##0.000";
            dgvUnit.Columns["Weight"].HeaderText = "Weight(lb)";


            DataGridViewComboBoxColumn UnitID = new DataGridViewComboBoxColumn();
            UnitID.Name = "Unit";
            UnitID.HeaderText = "Unit";
            UnitID.DataSource = DBConnection.GetSQLTable("Select ID, Name From unit");
            UnitID.ValueMember = "ID";
            UnitID.DisplayMember = "Name";
            UnitID.Width = 110;
            UnitID.DisplayStyle = DataGridViewComboBoxDisplayStyle.Nothing;
            if (dgvUnit.Columns.Contains("UnitID"))
            {
                dgvUnit.Columns.Remove("UnitID");
            }
            else if (dgvUnit.Columns.Contains("Unit"))
            {
                dgvUnit.Columns.Remove("Unit");
            }
            UnitID.DataPropertyName = "UnitID";
            dgvUnit.Columns.Insert(dgvUnit.Columns["Qty"].Index -1 , UnitID);



        }

        private void btClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void cbGroup_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbGroup.DroppedDown = true;
            LocalData.AutoComplete(cbGroup, e, true);
        }

        private void chkCredit_CheckedChanged(object sender, EventArgs e)
        {
            dt.Rows[0]["AllowCredit"] = chkCredit.Checked;
        }

        private void cbDivision_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbDivision.DroppedDown = true;
            LocalData.AutoComplete(cbDivision, e, true);
        }

        private void cbUnit_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbUnit.DroppedDown = true;
            LocalData.AutoComplete(cbUnit, e, true);
        }

        private void btSave_Click(object sender, EventArgs e)
        {

            string Code;
            if (ID <= 0)
            {
                Code = tbShort.Text.ToString();
                if (CheckCodeExist(Code))
                {
                    MessageBox.Show("Code Already Exist. Cannot Save!");
                    return;
                }
            }

            int gID;
            if (LocalData.Setup == LocalData.mySetup.Customer || LocalData.Setup == LocalData.mySetup.Code
                || LocalData.Setup == LocalData.mySetup.AcctSubGroup)
            {
                int.TryParse(cbGroup.SelectedValue == null ? "0" : cbGroup.SelectedValue.ToString(), out gID);
                if (gID == 0)
                {
                    MessageBox.Show("Important Data Missing. Cannot Save.");
                    return;
                }
            }
            dt.Rows[0].EndEdit();

            SqlCommandBuilder builder = new SqlCommandBuilder(sda);
            sda.Update(dt);

            if (LocalData.Setup == LocalData.mySetup.Code)
            {
                if (ID <= 0)
                {
                    int.TryParse(DBConnection.roExecSQL("Select Max(ID) from Stock").ToString(), out ID);
                }

                foreach (DataRow row in dtDetail.Rows)
                {
                    switch (row.RowState)
                    {
                        case DataRowState.Added:
                            row["StockID"] = ID;
                            break;
                        case DataRowState.Deleted:
                        case DataRowState.Detached:
                        case DataRowState.Modified:
                        case DataRowState.Unchanged:
                            continue;
                        default:
                            break;
                    }
                }
                
                sdaDetail = new SqlDataAdapter("select ID, StockID, UnitID, Qty, PurPrice, SalePrice, Weight from StockDetail where StockID = " + ID, DBConnection.ActiveConnection);
                builder = new SqlCommandBuilder(sdaDetail);
                sdaDetail.Update(dtDetail); 
            }
            

            if (ID <= 0)
            {
                MessageBox.Show("Save Successfully !!! ");
            }
            else
            {
                MessageBox.Show("Update Successfully !!! ");
            }


            builder.Dispose();
            this.DialogResult = DialogResult.OK;
            this.Close();
        }

        private Boolean CheckCodeExist(string code)
        {

            int ct = 0;
            if (LocalData.Setup == LocalData.mySetup.Code)
            {
                int.TryParse(DBConnection.roExecSQL("Select Count(*) From Stock Where isnull(Deleted,0)<>1 and Short = '" + code.ToString() + "'").ToString(), out ct);
            }
            else if (LocalData.Setup == LocalData.mySetup.Customer)
            {
                int.TryParse(DBConnection.roExecSQL("Select Count(*) From Customer Where isnull(Deleted,0)<>1 and Short = '" + code.ToString() + "'").ToString(), out ct);
            }
            else if (LocalData.Setup == LocalData.mySetup.Supplier)
            {
                int.TryParse(DBConnection.roExecSQL("Select Count(*) From Supplier Where isnull(Deleted,0)<>1 and Short = '" + code.ToString() + "'").ToString(), out ct);
            }
            else if (LocalData.Setup == LocalData.mySetup.Manufacturer)
            {
                int.TryParse(DBConnection.roExecSQL("Select Count(*) From Manufacturer Where isnull(Deleted,0)<>1 and Short = '" + code.ToString() + "'").ToString(), out ct);
            }

            return ct > 0 ? true : false;
        }
        private void ShowAccountCodeRow()
        {
            const int dy = 43;
            lbAccountCode.Visible = true;
            tbAccountCode.Visible = true;
            lbAccountCode.Location = new System.Drawing.Point(8, 28);
            tbAccountCode.Location = new System.Drawing.Point(117, 25);
            lbShort.Location = new System.Drawing.Point(8, 28 + dy);
            tbShort.Location = new System.Drawing.Point(117, 25 + dy);
            lbName.Location = new System.Drawing.Point(8, 71 + dy);
            tbName.Location = new System.Drawing.Point(117, 68 + dy);
            lbGroup.Location = new System.Drawing.Point(8, 114 + dy);
            cbGroup.Location = new System.Drawing.Point(117, 111 + dy);
            lbAddress.Location = new System.Drawing.Point(8, 158 + dy);
            tbAddress.Location = new System.Drawing.Point(117, 155 + dy);
            lbPhone.Location = new System.Drawing.Point(8, 248 + dy);
            tbPhone.Location = new System.Drawing.Point(117, 245 + dy);
            lbPansar.Location = new System.Drawing.Point(8, 291 + dy);
            tbPansar.Location = new System.Drawing.Point(117, 288 + dy);
            lbUnit.Location = new System.Drawing.Point(8, 331 + dy);
            cbUnit.Location = new System.Drawing.Point(117, 328 + dy);
        }


    }
}
