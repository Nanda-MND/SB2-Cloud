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
    public partial class frm_Users : Form
    {
        int ID, menuID;
        private SqlCommandBuilder scb;
        private SqlDataAdapter adp, adpSetup, adpEntry, adpReport, adpFilter;

        private void chkPassword_CheckedChanged(object sender, EventArgs e)
        {
            lbCurrent.Visible = chkPassword.Checked;
            tbCurrent.Visible = chkPassword.Checked;
            lbNew.Visible = chkPassword.Checked;
            tbNew.Visible = chkPassword.Checked;
            lbConfirm.Visible = chkPassword.Checked;
            tbConfirm.Visible = chkPassword.Checked;
        }

        private void btClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }

        private void btSave_Click(object sender, EventArgs e)
        {
            dt.Rows[0].EndEdit();
            dtSetup.Rows[0].EndEdit();
            dtEntry.Rows[0].EndEdit();
            dtReport.Rows[0].EndEdit();

            SqlCommandBuilder builder = new SqlCommandBuilder(adp);
            adp.Update(dt);

            adpSetup = new SqlDataAdapter("select ID, UserID, MenuID, MenusubID , AllowTransaction, AllowEdit, AllowDelete  from UserRights where  UserID = " + ID.ToString() + " and MenuID = 1", DBConnection.ActiveConnection);
            builder = new SqlCommandBuilder(adpSetup);
            adpSetup.Update(dtSetup);

            adpEntry = new SqlDataAdapter("select ID, UserID, MenuID, MenusubID , AllowTransaction, AllowEdit, AllowDelete  from UserRights where  UserID = " + ID.ToString() + " and MenuID = 2", DBConnection.ActiveConnection);
            builder = new SqlCommandBuilder(adpEntry);
            adpEntry.Update(dtEntry);

            adpReport = new SqlDataAdapter("select ID, UserID, MenuID, MenusubID , AllowTransaction from UserRights where  UserID = " + ID.ToString() + " and MenuID = 3", DBConnection.ActiveConnection);
            builder = new SqlCommandBuilder(adpReport);
            adpReport.Update(dtReport);

            if (chkPassword.Checked)
            {
                string pwd, opwd, LoggedOnName;
                int status;
                pwd = DBConnection.Encrypt(tbCurrent.Text);
                opwd = DBConnection.rExecSQL("select isnull(password,'') from [Users] where ID = " + ID.ToString());
                if (pwd == opwd)
                {
                    status = 1;
                }
                else
                {
                    status = 0;
                }
                if (status == 1)
                {
                    if (tbNew.Text != tbConfirm.Text)
                    {
                        MessageBox.Show("New Password and Confirm Password was not match!");
                    }
                    else
                    {
                        SqlCommand cmd;
                        cmd = new SqlCommand();
                        cmd.Connection = DBConnection.ActiveConnection;
                        cmd.CommandType = CommandType.StoredProcedure;
                        cmd.CommandText = "ChangePassword";
                        cmd.Parameters.Add("@UserID", SqlDbType.Int).Value = ID;
                        cmd.Parameters.Add("@User_Name", SqlDbType.NVarChar).Value = tbName.Text.ToString();
                        cmd.Parameters.Add("@Short", SqlDbType.NVarChar).Value = tbShort.Text.ToString();
                        cmd.Parameters.Add("@Password", SqlDbType.NVarChar).Value = DBConnection.Encrypt(tbNew.Text).ToString();
                        cmd.ExecuteNonQuery();
                    }
                }
                else
                {
                    MessageBox.Show("Current Password is incorrect!");
                }
            }
            MessageBox.Show("Update Successfully!");
            this.Close();
        }

        private void dgvSetup_Enter(object sender, EventArgs e)
        {
            menuID = 1;
        }

        private void dgvEntry_Enter(object sender, EventArgs e)
        {
            menuID = 2;
        }

        private void dgvReport_Enter(object sender, EventArgs e)
        {
            menuID = 3;
        }

        private void checkAllow_Click(object sender, EventArgs e)
        {
            CheckAll(menuID, 1);
        }

        private void checkEdit_Click(object sender, EventArgs e)
        {
            CheckAll(menuID, 2);
        }

        private void checkDelete_Click(object sender, EventArgs e)
        {
            CheckAll(menuID, 3);
        }

        private void uncheckAllow_Click(object sender, EventArgs e)
        {
            UnCheckAll(menuID, 1);
        }

        private void uncheckEdit_Click(object sender, EventArgs e)
        {
            UnCheckAll(menuID, 2);
        }

        private void uncheckDelete_Click(object sender, EventArgs e)
        {
            UnCheckAll(menuID, 3);
        }

        private DataTable dt, dtSetup, dtEntry, dtReport, dtLogin, dtFilter;

        public frm_Users(int uID)
        {
            ID = uID;
            InitializeComponent();
        }

        private void frm_Users_Load(object sender, EventArgs e)
        {
            adp = new SqlDataAdapter("Select ID, Short, Name From Users Where ID = " + ID.ToString(), DBConnection.ActiveConnection);
            dt = new DataTable();
            adp.Fill(dt);
            tbShort.DataBindings.Add("Text", dt, "Short");
            tbName.DataBindings.Add("Text", dt, "Name");

            adpSetup = new SqlDataAdapter("select UR.ID, UserID, UR.MenuID, MenusubID , Menu = M.Name, AllowTransaction, AllowEdit, AllowDelete  from menusub M  Join UserRights UR on M.MenuID = UR.MenuSubID and M.TypeID = UR.MenuID  where  UserID = " + ID.ToString() + " and M.TypeID = 1", DBConnection.ActiveConnection);
            dtSetup = new DataTable();
            adpSetup.Fill(dtSetup);

            dgvSetup.DataSource = dtSetup;
            dgvSetup.Columns["ID"].Visible = false;
            dgvSetup.Columns["UserID"].Visible = false;
            dgvSetup.Columns["MenuID"].Visible = false;
            dgvSetup.Columns["MenuSubID"].Visible = false;
            dgvSetup.Columns["Menu"].Width = 220;
            dgvSetup.Columns["AllowTransaction"].Width = 70;
            dgvSetup.Columns["AllowTransaction"].HeaderText = "Allow";
            dgvSetup.Columns["AllowEdit"].Width = 70;
            dgvSetup.Columns["AllowEdit"].HeaderText = "Edit";
            dgvSetup.Columns["AllowDelete"].Width = 70;
            dgvSetup.Columns["AllowDelete"].HeaderText = "Delete";


            adpEntry = new SqlDataAdapter("select UR.ID, UserID, UR.MenuID, MenusubID , Menu = M.Name, AllowTransaction, AllowEdit, AllowDelete  from menusub M  Join UserRights UR on M.MenuID = UR.MenuSubID and M.TypeID = UR.MenuID  where  UserID = " + ID.ToString() + " and M.TypeID = 2", DBConnection.ActiveConnection);
            dtEntry = new DataTable();
            adpEntry.Fill(dtEntry);

            dgvEntry.DataSource = dtEntry;
            dgvEntry.Columns["ID"].Visible = false;
            dgvEntry.Columns["UserID"].Visible = false;
            dgvEntry.Columns["MenuID"].Visible = false;
            dgvEntry.Columns["MenuSubID"].Visible = false;
            dgvEntry.Columns["Menu"].Width = 220;
            dgvEntry.Columns["AllowTransaction"].Width = 70;
            dgvEntry.Columns["AllowTransaction"].HeaderText = "Allow";
            dgvEntry.Columns["AllowEdit"].Width = 70;
            dgvEntry.Columns["AllowEdit"].HeaderText = "Edit";
            dgvEntry.Columns["AllowDelete"].Width = 70;
            dgvEntry.Columns["AllowDelete"].HeaderText = "Cancel";

            adpReport = new SqlDataAdapter("select UR.ID, UserID, UR.MenuID, MenusubID , Menu = M.Name, AllowTransaction from menusub M  Join UserRights UR on M.MenuID = UR.MenuSubID and M.TypeID = UR.MenuID  where  UserID = " + ID.ToString() + " and M.TypeID = 3 ", DBConnection.ActiveConnection);
            dtReport = new DataTable();
            adpReport.Fill(dtReport);

            dgvReport.DataSource = dtReport;
            dgvReport.Columns["ID"].Visible = false;
            dgvReport.Columns["UserID"].Visible = false;
            dgvReport.Columns["MenuID"].Visible = false;
            dgvReport.Columns["MenuSubID"].Visible = false;
            dgvReport.Columns["Menu"].Width = 220;
            dgvReport.Columns["AllowTransaction"].Width = 100;
            dgvReport.Columns["AllowTransaction"].HeaderText = "Allow";

            if (ID == 0)
            {
                tabControl1.TabPages.Remove(tpSetup);
                tabControl1.TabPages.Remove(tpEntry);
                tabControl1.TabPages.Remove(tpReports);

            }
        }

        private void CheckAll(int s_menu, int col)
        {
            if (s_menu == 1)
            {
                foreach (DataRow d_row in dtSetup.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = true;
                            break;
                        case 2:
                            d_row["AllowEdit"] = true;
                            break;
                        case 3:
                            d_row["AllowDelete"] = true;
                            break;

                        default:
                            break;
                    }

                }
            }
            else if (s_menu == 2)
            {
                foreach (DataRow d_row in dtEntry.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = true;
                            break;
                        case 2:
                            d_row["AllowEdit"] = true;
                            break;
                        case 3:
                            d_row["AllowDelete"] = true;
                            break;

                        default:
                            break;
                    }

                }

            }
            else if (s_menu == 3)
            {
                foreach (DataRow d_row in dtReport.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = true;
                            break;
                        default:
                            break;
                    }

                }

            }


        }

        private void UnCheckAll(int s_menu, int col)
        {
            if (s_menu == 1)
            {
                foreach (DataRow d_row in dtSetup.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = false;
                            break;
                        case 2:
                            d_row["AllowEdit"] = false;
                            break;
                        case 3:
                            d_row["AllowDelete"] = false;
                            break;

                        default:
                            break;
                    }

                }
            }
            else if (s_menu == 2)
            {
                foreach (DataRow d_row in dtEntry.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = false;
                            break;
                        case 2:
                            d_row["AllowEdit"] = false;
                            break;
                        case 3:
                            d_row["AllowDelete"] = false;
                            break;
                        default:
                            break;
                    }

                }

            }
            else if (s_menu == 3)
            {
                foreach (DataRow d_row in dtReport.Rows)
                {
                    switch (col)
                    {
                        case 1:
                            d_row["AllowTransaction"] = false;
                            break;
                        default:
                            break;
                    }

                }

            }


        }
    }
}
