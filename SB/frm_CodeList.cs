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
    public partial class frm_CodeList : Form
    {
        DataTable dt;

        private static int m_CodeID, UnitID = 0, Qty;
        private static string m_Code, m_Description;
        public static int CodeID { get { return m_CodeID; } }
        public static string Code { get { return m_Code; } }
        public static string Description { get { return m_Description; } }
        public static int TotalQty { get { return Qty; } }

        private void olvCode_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter && olvCode.Items.Count > 0)
            {
                int.TryParse(olvCode.SelectedItem.SubItems[0].Text.ToString(), out m_CodeID);
                m_Code = olvCode.SelectedItem.SubItems[1].Text.ToString();
                m_Description = olvCode.SelectedItem.SubItems[2].Text.ToString();
                this.Close();
                this.DialogResult = DialogResult.OK;
            }
            else if(e.KeyCode == Keys.Escape)
            {
                this.Close();
            }
        }

        private void cbLocation_DropDownClosed(object sender, EventArgs e)
        {
            FillListview();
        }

        private void tbCode_TextChanged(object sender, EventArgs e)
        {
            FillListview();
        }

        private void cbLocation_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbLocation.DroppedDown = true;
            LocalData.AutoComplete(cbLocation, e, true);
        }

        public frm_CodeList(string code)
        {
            m_Code = code;
            InitializeComponent();
        }

        private void frm_CodeList_Load(object sender, EventArgs e)
        {
            //cbLocation.DataSource = DBConnection.GetSQLTable(" Select ID = -1, Name = ' All Locations' Union All Select ID,Name = Short + '-' + Name From Location where isnull(Deleted,0) <> 1  order by Name");
            //cbLocation.DisplayMember = "Name";
            //cbLocation.ValueMember = "ID";
            //cbLocation.SelectedValue = -1;

            if (m_Code!=string.Empty)
            {
                tbCode.Text = m_Code;
            }


            FillListview();
            tbCode.Focus();
        }

        private void FillListview()
        {
            SqlParameter[] arg = new SqlParameter[7];
            arg[0] = new SqlParameter("@UserID", SqlDbType.Int); arg[0].Value = LocalData.UserID;
            arg[1] = new SqlParameter("@FDate", SqlDbType.DateTime); arg[1].Value = LocalData.SettingDate.ToString("yyyy-MM-dd");
            arg[2] = new SqlParameter("@TDate", SqlDbType.DateTime); arg[2].Value = LocalData.SettingDate.ToString("yyyy-MM-dd");
            arg[3] = new SqlParameter("@Code", SqlDbType.NVarChar); arg[3].Value = tbCode.Text.ToString();
            arg[4] = new SqlParameter("@GroupID", SqlDbType.Int); arg[4].Value = 0;
            arg[5] = new SqlParameter("@TypeID", SqlDbType.Int); arg[5].Value = 0;
            arg[6] = new SqlParameter("@Location", SqlDbType.NVarChar); arg[6].Value = "";
            DBConnection.ExecSp("StockBalance", arg);

            string col, sql, filter, filter1;
            filter = " Where UserID = " + LocalData.UserID.ToString() ;

            int rowcount;
            int.TryParse(DBConnection.roExecSQL("Select count(*) From StockStatus " + filter.ToString()).ToString(), out rowcount);
            //filter1 = " Where UserID = " + LocalData.UserID.ToString() + " and LocationID = (Case When " + cbLocation.SelectedValue.ToString() + " = -1 Then LocationID Else " + cbLocation.SelectedValue.ToString() + " end ) and Code like ''%" + tbCode.Text.ToString() + "%'' and isnull(Qty,0)>0 ";
            if (rowcount > 0)
            {
                col = DBConnection.rExecSQL("DECLARE @Cols  AS NVARCHAR(MAX);SELECT @Cols = CONCAT(@Cols + ', ', QUOTENAME(Short)) FROM Location Where isnull(Deleted,0)<>1  ORDER BY SortID, Short; Select @cols").ToString();
                sql = DBConnection.rExecSQL("DECLARE @DynSql AS NVARCHAR(MAX); SET @DynSql = N'SELECT * FROM( SELECT ID =CodeID, Short = Code, Name, Brand, Qty = dbo.GetQtyinUnitRelation(CodeID, Qty), Loc = Short FROM StockStatus " + filter.ToString() + " ) src PIVOT ( MAX(Qty) FOR Loc IN( " + col.ToString() + " ) ) pvt ORDER BY Short'; Select @DynSql;").ToString();
                //dt = DBConnection.GetSQLTable("select ID, Short, Name, Qty = 0 from Stock Where Short Like N'%" + tbCode.Text.ToString() + "%'");
                dt = DBConnection.GetSQLTable(sql.ToString());

                olvCode.DataSource = dt;
                int count = dt.Columns.Count;
                for (int i = 0; i < count; i++)
                {
                    olvCode.Columns[i].Width = 160;
                }
                olvCode.Columns["ID"].Width = 0;
                olvCode.Columns["Short"].Width = 120;
                olvCode.Columns["Name"].Width = 200;
                olvCode.Columns["Brand"].Width = 100;
            }
            else
            {
                olvCode.Clear();
                return;
            }




        }
    }
}
