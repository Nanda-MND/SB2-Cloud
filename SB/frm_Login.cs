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
    public partial class frm_Login : Form
    {
        public frm_Login()
        {
            InitializeComponent();
        }

        private void frm_Login_Load(object sender, EventArgs e)
        {
            int i;

            int.TryParse(DBConnection.rExecSQL("Select Count(*) From LoginClient where Name = '" + Environment.MachineName.ToString() + "'").ToString(), out i);


            if (i == 0)
            {
                MessageBox.Show("Unregistered Computer Name!", "Invalid Log on", MessageBoxButtons.OK, MessageBoxIcon.Error);
                Application.Exit();
            }
            else
            {
                int.TryParse(DBConnection.rExecSQL("Select isnull(ID,0) From LoginClient where Name = '" + Environment.MachineName.ToString() + "'").ToString(), out i);
                LocalData.LoginID = i;
                cbUser.DataSource = DBConnection.GetSQLTable("SELECT U.ID, U.Name FROM Users U Join UserLoginInfo F on U.ID = F.UserID Join LogInClient L on F.LoginID = L.ID where ISNULL(InActive,0)<>1  and isnull(isAllow,0) = 1 and L.Name = '" + Environment.MachineName.ToString() + "' Order by Name ");

                cbUser.DisplayMember = "Name";
                cbUser.ValueMember = "ID";
                cbUser.SelectedValue = 1;
            }
        }

        private void btLogin_Click(object sender, EventArgs e)
        {
            LocalData.SettingDate = Convert.ToDateTime(DBConnection.rExecSQL("Select  Date From Setting "));
            LocalData.SettingStartDate = Convert.ToDateTime(DBConnection.rExecSQL("Select StartDate =DateAdd( Day,- LogDay,Date)  From Setting "));
            Transaction.MaxDate = Convert.ToDateTime(DBConnection.rExecSQL("Select StartDate =DateAdd( Day, LogDay,Date)  From Setting "));
            Transaction.MinDate = Convert.ToDateTime(DBConnection.rExecSQL("Select StartDate =DateAdd( Day, -LogDay,Date)  From Setting "));

            LocalData.AlloranceUser = Convert.ToInt32(DBConnection.rExecSQL("Select Count(*) From UserStatus "));

            string pwd, LoggedOnName;
            int status;
            SqlCommand cmd = new SqlCommand();
            cmd.Connection = DBConnection.ActiveConnection;
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.CommandText = "CheckPassword";
            cmd.Parameters.Add("@UserID", SqlDbType.Int).Value = cbUser.SelectedValue == null ? 0 : cbUser.SelectedValue;
            pwd = DBConnection.Encrypt(tbPassword.Text);
            cmd.Parameters.Add("@Password", SqlDbType.NVarChar).Value = pwd;
            cmd.Parameters.Add("@Status", SqlDbType.Int);
            cmd.Parameters.Add("@HostName", SqlDbType.NVarChar);
            cmd.Parameters["@Status"].Direction = ParameterDirection.Output;
            cmd.Parameters["@HostName"].Direction = ParameterDirection.Output;
            cmd.Parameters["@HostName"].Size = 1024;
            cmd.ExecuteNonQuery();
            status = Convert.ToInt32(cmd.Parameters["@Status"].Value);
            LoggedOnName = cmd.Parameters["@HostName"].Value.ToString();


            if (status == 1)
            {
                int DateAdd;
                LocalData.UserID = Convert.ToInt32(cbUser.SelectedValue);
                LocalData.UserName = cbUser.Text.ToString();
                LocalData.Login = Environment.MachineName.ToString();
                tbPassword.Text = string.Empty;
                try
                {
                    //Boolean.TryParse(DBConnection.roExecSQL("Select HidePurPrice From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.HidePurPrice);
                    //Boolean.TryParse(DBConnection.roExecSQL("Select AllowDateChange From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.AllowDateChange);
                    //Boolean.TryParse(DBConnection.roExecSQL("Select AllowAllData From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.AllowAll);
                    //Boolean.TryParse(DBConnection.roExecSQL("Select ShowTime From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.ShowTime);
                    //Boolean.TryParse(DBConnection.roExecSQL("Select CheckVr From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.CheckVr);
                    Boolean.TryParse(DBConnection.roExecSQL("Select AllowBackDate From Users Where ID = " + LocalData.UserID.ToString()).ToString(), out LocalData.AllowBackDate);
                    //int.TryParse(DBConnection.rExecSQL("Select logDay From Setting Where isnull(Deleted,0)<>1"), out DateAdd);
                    //LocalData.LogDate = DateAdd;

                    Form mf = new frm_Main();
                    this.Hide();
                    mf.ShowDialog();
                    try
                    {
                        this.Show();
                    }
                    catch { }
                }
                catch
                {

                }
            }
            else if (status == -1)
            {
                MessageBox.Show(" This user is logged on by " + LoggedOnName, "Logged on", MessageBoxButtons.OK, MessageBoxIcon.Error);
                DBConnection.Close();
                SqlConnection.ClearPool(DBConnection.ActiveConnection);
            }
            else if (status == 0)
            {
                MessageBox.Show("Incorrect password or user name.", "Password", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }

        }

        private void btLogin_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbUser.DroppedDown = true;
            LocalData.AutoComplete(cbUser, e, true);
        }

        private void btExit_Click(object sender, EventArgs e)
        {
            Application.Exit();
        }

        private void cbUser_KeyPress(object sender, KeyPressEventArgs e)
        {
            cbUser.DroppedDown = true;
            LocalData.AutoComplete(cbUser, e, true);
        }
    }
}
