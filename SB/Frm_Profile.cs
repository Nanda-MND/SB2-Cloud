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
using System.IO;
namespace SB
{
    public partial class Frm_Profile : Form
    {
        int ID;
        byte[] img;
        public static DataTable dt;
        public SqlDataAdapter adp;
        Image OrginalImage;

        public Frm_Profile(int c_ID)
        {
            ID = c_ID;
            InitializeComponent();
        }

        private void Frm_Profile_Load(object sender, EventArgs e)
        {
            adp = new SqlDataAdapter("Select ID, Name , Bussiness, Address, PhoneNo, ViberNo, Logo, LogDay  From Setting Where ID = " + ID, DBConnection.ActiveConnection);
            dt = new DataTable();
            adp.Fill(dt);
            if (ID <= 0)
            {
                dt.Rows.Add(dt.NewRow());
                OrginalImage = pbLogo.Image;
            }
            LocalData.image = dt.Rows[0]["Logo"].ToString();
            try
            {
                Binding image = new Binding("Image", dt, "logo");
                image.Format += new ConvertEventHandler(image_Format);

                if (LocalData.image.ToString() == null)
                {
                    pbLogo.DataBindings.Add(img.ToString(), dt, "Logo");
                }
                else
                {
                    pbLogo.DataBindings.Add(image);
                    pbLogo.SizeMode = PictureBoxSizeMode.Zoom;
                }
            }
            catch
            { }

            tbName.DataBindings.Add("Text", dt, "Name");
            tbBussiness.DataBindings.Add("Text", dt, "Bussiness");
            tbAddress.DataBindings.Add("Text", dt, "Address");
            tbPhone.DataBindings.Add("Text", dt, "PhoneNo");
            tbPhone1.DataBindings.Add("Text", dt, "ViberNo");
            tbLogDay.DataBindings.Add("Text", dt, "LogDay");
        }

        private void image_Format(object sender, ConvertEventArgs e)
        {
            try
            {
                byte[] image = (byte[])e.Value;
                MemoryStream ms = new MemoryStream(image);
                Bitmap bmp = new Bitmap(ms);
                ms.Close();
                e.Value = bmp;
            }
            catch { }
        }

        private void btnSave_Click(object sender, EventArgs e)
        {
            dt.Rows[0].EndEdit();

            try
            {
                SqlCommandBuilder builder = new SqlCommandBuilder(adp);
                adp.Update(dt);
                MessageBox.Show("Save Successfully !!! ");
                this.Close();
                dt.Dispose();
                adp.Dispose();
                builder.Dispose();
                tbName.DataBindings.Clear();
                tbBussiness.DataBindings.Clear();
                tbAddress.DataBindings.Clear();
                tbPhone.DataBindings.Clear();
                tbPhone1.DataBindings.Clear();
                tbLogDay.DataBindings.Clear();
                pbLogo.Image = OrginalImage;
                ID = 0;

            }
            catch
            {

                return;
            }
        }

        private void btnLogo_Click(object sender, EventArgs e)
        {
            OFGDialog = new OpenFileDialog();
            OFGDialog.InitialDirectory = @"C:\";
            OFGDialog.Filter = "ImageFiles(*.jpg;*.jpeg;*.png;*.bmp;*.gif)| *.jpg;*.jpeg;*.png;*.bmp;*.gif";
            if (OFGDialog.ShowDialog() == DialogResult.OK)
            {
                FileStream fs = new FileStream(OFGDialog.FileName, FileMode.Open, FileAccess.Read);
                img = new byte[fs.Length];
                fs.Read(img, 0, Convert.ToInt32(fs.Length));
                LocalData.image = img.ToString();
                dt.Rows[0]["Logo"] = img;
                pbLogo.Image = new Bitmap(OFGDialog.FileName);
                pbLogo.SizeMode = PictureBoxSizeMode.StretchImage;
            }
            else
            {
                MessageBox.Show("Please Select a Image to save!!", "Information", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            this.Close();
        }
    }
}
