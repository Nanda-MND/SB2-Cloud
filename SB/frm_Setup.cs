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
    public partial class frm_Setup : Form
    {
        int m_ID = 0;
        int SelNodeID = 0;
        SqlDataAdapter sda;
        SqlCommandBuilder scb;
        DataTable dtHead, dtTreeView1, dtTreeView2, dtTreeView3;
        Form frm;
        string SelTag = "R";

        public frm_Setup()
        {
            InitializeComponent();
        }

        private void LeftMenuDefault()
        {
            foreach (PageMenu pm in tlpLeft.Controls)
            {
                pm.BackColor = Color.Transparent;
                pm.TextColor = Color.Black;
                //pm.Margin.Left = 4;
            }
        }
        private void frm_Setup_Load(object sender, EventArgs e)
        {
            FillTreeView();
            FillListView();
        }

        private void pmStock_Click(object sender, EventArgs e)
        {

        }

        private void pmBranch_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmBranch.BackColor = Color.Red;
            pmBranch.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Location;
            lbSetup.Text = "Setup Branch / Locations";
            FillTreeView();
            FillListView();
        }

        private void pmStock_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmStock.BackColor = Color.Red;
            pmStock.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Code;
            lbSetup.Text = "Setup Stocks";
            FillTreeView();
            FillListView();
        }

        private void pmDivision_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmDivision.BackColor = Color.Red;
            pmDivision.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Township;
            lbSetup.Text = "Setup Division / Townships";
            FillTreeView();
            FillListView();
        }

        private void pmCustomer_MouseMove(object sender, MouseEventArgs e)
        {

        }

        private void pmCustomer_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmCustomer.BackColor = Color.Red;
            pmCustomer.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Customer;
            lbSetup.Text = "Setup Customers";
            FillTreeView();
            FillListView();
        }

        private void pmSuppliers_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmSuppliers.BackColor = Color.Red;
            pmSuppliers.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Supplier;
            lbSetup.Text = "Setup Suppliers";
            FillTreeView();
            FillListView();
        }

        private void pmManufacturer_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmManufacturer.BackColor = Color.Red;
            pmManufacturer.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Manufacturer;
            lbSetup.Text = "Setup Manufacturers";
            FillTreeView();
            FillListView();
        }

        private void pmTransport_MouseSelected(object sender, EventArgs e)
        {

        }

        private void pmAccount_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmAccount.BackColor = Color.Red;
            pmAccount.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Account;
            lbSetup.Text = "Setup Accounts";
            FillTreeView();
            FillListView();
        }

        private void pmUnit_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmUnit.BackColor = Color.Red;
            pmUnit.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Unit;
            lbSetup.Text = "Setup Units";
            //FillTreeView();
            FillListView();
        }

        private void pmUser_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmUser.BackColor = Color.Red;
            pmUser.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Users;
            lbSetup.Text = "Setup Users";
            FillTreeView();
            FillListView();
        }

        private void newToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Category)
            {
                LocalData.Setup = LocalData.mySetup.Code;
            }
            else if (LocalData.Setup == LocalData.mySetup.Brand)
            {
                LocalData.Setup = LocalData.mySetup.BrandNStock;
            }
            if (LocalData.Setup == LocalData.mySetup.Users)
            {
                frm = new frm_Users(0);
                frm.ShowDialog();
            }
            else
            {
                frm = new frm_SetupDetail(0);
                frm.ShowDialog();
            }

            FillTreeView();
            FillListView();
        }

        private void pmBranch_Load(object sender, EventArgs e)
        {

        }

        private void editToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Category)
            {
                LocalData.Setup = LocalData.mySetup.Code;
            }
            else if (LocalData.Setup == LocalData.mySetup.Brand || LocalData.Setup == LocalData.mySetup.BrandNStock)
            {
                LocalData.Setup = LocalData.mySetup.BrandNStock;
            }
            if (dlvHistory.SelectedItems.Count <= 0)
            {
                MessageBox.Show("Select item");
                return;
            }
            int i;
            int.TryParse(dlvHistory.SelectedItem.SubItems[1].Text.ToString(), out m_ID);

            if (LocalData.Setup == LocalData.mySetup.Users)
            {
                frm = new frm_Users(m_ID);
                frm.ShowDialog();
            }
            else
            {
                frm = new frm_SetupDetail(m_ID);
                frm.ShowDialog();
            }
            //FillTreeView();
            //FillListView();
        }

        private void tvSetup_AfterSelect(object sender, TreeViewEventArgs e)
        {
            SelNodeID = 0;
            if (tvSetup.SelectedNode != null && tvSetup.SelectedNode.Tag != null)
            {
                string tag = tvSetup.SelectedNode.Tag.ToString();
                SelTag = tag;
                if (tag.StartsWith("A") || tag.StartsWith("B"))
                    int.TryParse(tag.Substring(1), out SelNodeID);
                else
                    int.TryParse(tag, out SelNodeID);
            }
            else
                SelTag = "R";

            FillListView();
        }

        /// <summary>Right-click must select the node under the cursor before context menu runs.</summary>
        private void tvSetup_MouseDown(object sender, MouseEventArgs e)
        {
            if (e.Button != MouseButtons.Right)
                return;
            TreeNode node = tvSetup.GetNodeAt(e.X, e.Y);
            if (node != null)
                tvSetup.SelectedNode = node;
        }

        private void cmsTreeView_Opening(object sender, CancelEventArgs e)
        {
            bool acct = LocalData.Setup == LocalData.mySetup.Account || LocalData.Setup == LocalData.mySetup.AcctGroup;
            bool isSubGroup = acct
                && tvSetup.SelectedNode != null
                && tvSetup.SelectedNode.Tag != null
                && tvSetup.SelectedNode.Tag.ToString().StartsWith("B");

            // Account tree: New always (under Main/Sub); Edit/Delete only on SubGroup (B*)
            if (acct)
            {
                newToolStripMenuItem1.Enabled = true;
                editToolStripMenuItem1.Enabled = isSubGroup;
                deleteToolStripMenuItem1.Enabled = isSubGroup;
            }
            else
            {
                newToolStripMenuItem1.Enabled = true;
                editToolStripMenuItem1.Enabled = true;
                deleteToolStripMenuItem1.Enabled = true;
            }
        }

        private int ResolveAcctMainGroupIdFromTree()
        {
            if (tvSetup.SelectedNode == null || tvSetup.SelectedNode.Tag == null)
                return 0;

            string tag = tvSetup.SelectedNode.Tag.ToString();
            int mainId = 0;

            // MainGroup A*
            if (tag.StartsWith("A"))
            {
                int.TryParse(tag.Substring(1), out mainId);
                return mainId;
            }

            // SubGroup B* → parent MainGroup A*
            if (tag.StartsWith("B") && tvSetup.SelectedNode.Parent != null && tvSetup.SelectedNode.Parent.Tag != null)
            {
                string p = tvSetup.SelectedNode.Parent.Tag.ToString();
                if (p.StartsWith("A"))
                    int.TryParse(p.Substring(1), out mainId);
                return mainId;
            }

            // AcctGroup leaf → parent B* → grandparent A*
            TreeNode parent = tvSetup.SelectedNode.Parent;
            if (parent != null && parent.Tag != null && parent.Tag.ToString().StartsWith("B")
                && parent.Parent != null && parent.Parent.Tag != null)
            {
                string gp = parent.Parent.Tag.ToString();
                if (gp.StartsWith("A"))
                    int.TryParse(gp.Substring(1), out mainId);
            }
            return mainId;
        }

        private void pmDivision_Load(object sender, EventArgs e)
        {

        }

        private void pmSuppliers_Load(object sender, EventArgs e)
        {

        }

        private void pmDivision_Click(object sender, EventArgs e)
        {
            FillTreeView();
            FillListView();

        }

        private void pmCustomer_Load(object sender, EventArgs e)
        {

        }

        private void pmAccount_MouseUp(object sender, MouseEventArgs e)
        {

        }

        private void newToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Township)
            {
                LocalData.Setup = LocalData.mySetup.Division;
                frm = new frm_SetupDetail(0);
                frm.ShowDialog();
                FillTreeView();
                LocalData.Setup = LocalData.mySetup.Township;
            }
            else if (LocalData.Setup == LocalData.mySetup.Code)
            {
                LocalData.Setup = LocalData.mySetup.Category;
                frm = new frm_SetupDetail(0);
                frm.ShowDialog();
                FillTreeView();
            }
            else if (LocalData.Setup == LocalData.mySetup.Brand || LocalData.Setup == LocalData.mySetup.BrandNStock)
            {
                if (LocalData.Setup == LocalData.mySetup.BrandNStock)
                {
                    LocalData.Setup = LocalData.mySetup.Brand;
                }
                frm = new frm_SetupDetail(0);
                frm.ShowDialog();
                FillTreeView();
            }
            else if (LocalData.Setup == LocalData.mySetup.Account || LocalData.Setup == LocalData.mySetup.AcctGroup)
            {
                // New Account SubGroup under selected Main Group (tag A*) / parent of B*
                LocalData.mySetup prev = LocalData.Setup;
                LocalData.PrefillMainGroupID = ResolveAcctMainGroupIdFromTree();
                LocalData.Setup = LocalData.mySetup.AcctSubGroup;
                frm = new frm_SetupDetail(0);
                frm.ShowDialog();
                LocalData.Setup = prev;
                LocalData.PrefillMainGroupID = 0;
                FillTreeView();
                FillListView();
            }
        }

        private void pmBrand_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmBranch.BackColor = Color.Red;
            pmBranch.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Brand;
            lbSetup.Text = "Setup Brand";
            FillTreeView();
            FillListView();
        }

        private void deleteToolStripMenuItem_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Category)
            {
                LocalData.Setup = LocalData.mySetup.Code;
            }
            if (dlvHistory.SelectedItems.Count <= 0)
            {
                MessageBox.Show("Select Voucher!");
                return;
            }
            int i;
            int.TryParse(dlvHistory.SelectedItem.SubItems[1].Text.ToString(), out i);
            if (MessageBox.Show("Are you sure want to delete '" + dlvHistory.SelectedItem.SubItems[4].Text.ToString() + "' ?", "Transaction", MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) == DialogResult.Yes)
            {
                Boolean tranexist = false;
                Boolean.TryParse(DBConnection.roExecSQL("select dbo.CheckTranExist(" + ((int)LocalData.Setup).ToString() + "," + i.ToString() + ")").ToString(), out tranexist);
                if (tranexist)
                {
                    MessageBox.Show("Transaction Exist! Cannot Delete.");
                }
                else
                {
                    switch (LocalData.Setup)
                    {
                        case LocalData.mySetup.Branch:
                            break;
                        case LocalData.mySetup.Location:
                            break;
                        case LocalData.mySetup.Class:
                            break;
                        case LocalData.mySetup.Category:
                            break;
                        case LocalData.mySetup.Code:
                            DBConnection.ExecSQL("Update Stock Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Division:
                            break;
                        case LocalData.mySetup.Township:
                            break;
                        case LocalData.mySetup.Customer:
                            DBConnection.ExecSQL("Update Customer Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Supplier:
                            DBConnection.ExecSQL("Update Supplier Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Manufacturer:
                            DBConnection.ExecSQL("Update Manufacturer Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Transport:
                            DBConnection.ExecSQL("Update Transport Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Gate:
                            break;
                        case LocalData.mySetup.Account:
                            DBConnection.ExecSQL("Update AccountName Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.AcctGroup:
                            DBConnection.ExecSQL("Update AcctGroup Set Deleted = 1 Where ID = " + i.ToString());
                            break;
                        case LocalData.mySetup.Unit:
                            break;
                        case LocalData.mySetup.Users:
                            break;
                        case LocalData.mySetup.Brand:
                        case LocalData.mySetup.BrandNStock:
                            DBConnection.ExecSQL("Delete From BrandNStockGroup Where ID = " + i.ToString());
                            break;
                        default:
                            break;
                    }
                }
                //FillListView();
            }
        }

        private void deleteToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Code)
            {
                //LocalData.Setup = LocalData.mySetup.Category;
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString(), out SelNodeID);
                DBConnection.ExecSQL("Delete From StockGroup Where ID = " + SelNodeID.ToString());
                FillTreeView();
            }
            else if (LocalData.Setup == LocalData.mySetup.Township)
            {
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString(), out SelNodeID);

                DBConnection.ExecSQL("Delete From Division Where ID = " + SelNodeID.ToString());
                FillTreeView();
            }
            else if ((LocalData.Setup == LocalData.mySetup.Account || LocalData.Setup == LocalData.mySetup.AcctGroup)
                && tvSetup.SelectedNode != null
                && tvSetup.SelectedNode.Tag != null
                && tvSetup.SelectedNode.Tag.ToString().StartsWith("B"))
            {
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString().Substring(1), out SelNodeID);
                if (SelNodeID <= 0)
                {
                    MessageBox.Show("Select Account Sub Group.", "Setup", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }

                // Block delete when child Account Groups still exist
                int childGroups = 0;
                try
                {
                    int.TryParse(DBConnection.roExecSQL(
                        "Select Count(*) From AcctGroup Where SubGroupID = " + SelNodeID.ToString()
                        + " And ISNULL(Deleted,0)<>1").ToString(), out childGroups);
                }
                catch
                {
                    int.TryParse(DBConnection.roExecSQL(
                        "Select Count(*) From AcctGroup Where SubGroupID = " + SelNodeID.ToString()).ToString(), out childGroups);
                }

                if (childGroups > 0)
                {
                    MessageBox.Show(
                        "Cannot delete. This Sub Group still has " + childGroups.ToString()
                        + " Account Group(s).\nDelete or move child groups first.",
                        "Setup",
                        MessageBoxButtons.OK,
                        MessageBoxIcon.Warning);
                    return;
                }

                string subName = tvSetup.SelectedNode.Text;
                if (MessageBox.Show("Delete Account Sub Group '" + subName + "' ?", "Setup",
                    MessageBoxButtons.YesNo, MessageBoxIcon.Question, MessageBoxDefaultButton.Button2) != DialogResult.Yes)
                    return;

                try
                {
                    DBConnection.ExecSQL("Update AcctSubGroup Set Deleted = 1 Where ID = " + SelNodeID.ToString());
                }
                catch
                {
                    DBConnection.ExecSQL("Delete From AcctSubGroup Where ID = " + SelNodeID.ToString());
                }
                FillTreeView();
                FillListView();
            }
        }

        private void editToolStripMenuItem1_Click(object sender, EventArgs e)
        {
            if (LocalData.Setup == LocalData.mySetup.Township)
            {
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString(), out SelNodeID);
                LocalData.Setup = LocalData.mySetup.Division;
                frm = new frm_SetupDetail(SelNodeID);
                frm.ShowDialog();
                FillTreeView();
                LocalData.Setup = LocalData.mySetup.Township;
            }
            else if (LocalData.Setup == LocalData.mySetup.Code)
            {
                LocalData.Setup = LocalData.mySetup.Category;
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString(), out SelNodeID);
                frm = new frm_SetupDetail(SelNodeID);
                frm.ShowDialog();
                FillTreeView();
            }
            else if (LocalData.Setup == LocalData.mySetup.BrandNStock || LocalData.Setup == LocalData.mySetup.Brand)
            {
                if (LocalData.Setup == LocalData.mySetup.BrandNStock)
                {
                    LocalData.Setup = LocalData.mySetup.Brand;
                }

                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString(), out SelNodeID);
                frm = new frm_SetupDetail(SelNodeID);
                frm.ShowDialog();
                FillTreeView();
            }
            else if ((LocalData.Setup == LocalData.mySetup.Account || LocalData.Setup == LocalData.mySetup.AcctGroup)
                && tvSetup.SelectedNode != null
                && tvSetup.SelectedNode.Tag != null
                && tvSetup.SelectedNode.Tag.ToString().StartsWith("B"))
            {
                LocalData.mySetup prev = LocalData.Setup;
                LocalData.Setup = LocalData.mySetup.AcctSubGroup;
                SelNodeID = 0;
                int.TryParse(tvSetup.SelectedNode.Tag.ToString().Substring(1), out SelNodeID);
                if (SelNodeID <= 0)
                {
                    LocalData.Setup = prev;
                    MessageBox.Show("Select Account Sub Group.", "Setup", MessageBoxButtons.OK, MessageBoxIcon.Information);
                    return;
                }
                frm = new frm_SetupDetail(SelNodeID);
                frm.ShowDialog();
                LocalData.Setup = prev;
                FillTreeView();
                FillListView();
            }
        }

        private void tlpLeft_Paint(object sender, PaintEventArgs e)
        {

        }

        private void pmGates_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmGates.BackColor = Color.Red;
            pmGates.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Gate;
            lbSetup.Text = "Setup Gates";
            //FillTreeView();
            FillListView();
        }

        private void pmCars_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmCars.BackColor = Color.Red;
            pmCars.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Cars;
            lbSetup.Text = "Setup Cars";
            //FillTreeView();
            FillListView();
        }

        private void pmAcctGroup_MouseSelected(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmAcctGroup.BackColor = Color.Red;
            pmAcctGroup.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.AcctGroup;
            lbSetup.Text = "Setup Account Group";
            FillTreeView();
            FillListView();
        }

        private void cmsListView_Opening(object sender, CancelEventArgs e)
        {
            if (LocalData.UserID == 1 || LocalData.UserID == 2 || LocalData.UserID == 3 || LocalData.UserID == 4 || LocalData.UserID == 5)
            {
                deleteToolStripMenuItem.Visible = true;
                editToolStripMenuItem.Visible = true;
            }
            else
            {
                deleteToolStripMenuItem.Visible = false;
                editToolStripMenuItem.Visible = false;
            }
        }

        private void pmTransport_MouseSelected_1(object sender, EventArgs e)
        {
            LeftMenuDefault();
            pmTransport.BackColor = Color.Red;
            pmTransport.TextColor = Color.White;
            LocalData.Setup = LocalData.mySetup.Transport;
            lbSetup.Text = "Setup Transport";
            //FillTreeView();
            FillListView();
        }

        private void pmBranch_Click(object sender, EventArgs e)
        {


        }

        private void FillTreeView()
        {
            int iMenuSub = 0;
            tvSetup.BeginUpdate();
            tvSetup.Nodes.Clear();


            tvSetup.Nodes.Add(LocalData.CompanyName.ToString());
            tvSetup.Nodes[0].Tag = "R";
            tvSetup.Nodes[0].ImageIndex = 0;
            tvSetup.Nodes[0].SelectedImageIndex = 0;

            switch (LocalData.Setup)
            {
                case LocalData.mySetup.Branch:
                case LocalData.mySetup.Location:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From LocationType order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = caRow["ID"].ToString();
                        tnMenu.ImageIndex = 4;
                        tnMenu.SelectedImageIndex = 4;
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);
                    }
                    break;
                case LocalData.mySetup.Class:
                case LocalData.mySetup.Category:
                case LocalData.mySetup.Code:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From StockType Where isnull(Deleted,0)<>1 order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = "A" + caRow["ID"].ToString();
                        tnMenu.ImageIndex = 1;
                        tnMenu.SelectedImageIndex = 1;
                        int.TryParse(caRow["ID"].ToString(), out iMenuSub);
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);

                        dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From StockGroup WHERE TypeID =  " + iMenuSub + " and isnull(Deleted,0)<>1 order by ID");
                        foreach (DataRow crow in dtTreeView2.Rows)
                        {
                            TreeNode tnMenu_Sub = new TreeNode();
                            tnMenu_Sub.Text = crow["Name"].ToString();
                            tnMenu_Sub.Tag = crow["ID"].ToString();
                            tnMenu_Sub.ImageIndex = 2;
                            tnMenu_Sub.SelectedImageIndex = 2;
                            tnMenu.Nodes.Add(tnMenu_Sub);

                            //dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Category WHERE Class =  " + iMenuSub + " and isnull(Deleted,0)<>1 order by ID");
                            //foreach (DataRow crow in dtTreeView2.Rows)
                            //{
                            //    TreeNode tnMenu_Sub = new TreeNode();
                            //    tnMenu_Sub.Text = crow["Name"].ToString();
                            //    tnMenu_Sub.Tag = crow["ID"].ToString();
                            //    tnMenu_Sub.ImageIndex = 1;
                            //    tnMenu_Sub.SelectedImageIndex = 1;
                            //    tnMenu.Nodes.Add(tnMenu_Sub);
                            //}
                        }
                    }
                    break;
                case LocalData.mySetup.Division:
                case LocalData.mySetup.Township:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Division Where isnull(Deleted,0)<>1 order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = caRow["ID"].ToString();
                        tnMenu.ImageIndex = 5;
                        tnMenu.SelectedImageIndex = 5;
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);
                    }
                    break;
                case LocalData.mySetup.Customer:
                case LocalData.mySetup.Supplier:
                case LocalData.mySetup.Manufacturer:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Division Where isnull(Deleted,0)<>1 order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = "A" + caRow["ID"].ToString();
                        tnMenu.ImageIndex = 5;
                        tnMenu.SelectedImageIndex = 5;
                        int.TryParse(caRow["ID"].ToString(), out iMenuSub);
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);

                        dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Township WHERE DivisionID =  " + iMenuSub + " and isnull(Deleted,0)<>1 order by ID");
                        foreach (DataRow crow in dtTreeView2.Rows)
                        {
                            TreeNode tnMenu_Sub = new TreeNode();
                            tnMenu_Sub.Text = crow["Name"].ToString();
                            tnMenu_Sub.Tag = crow["ID"].ToString();
                            tnMenu_Sub.ImageIndex = 6;
                            tnMenu_Sub.SelectedImageIndex = 6;
                            tnMenu.Nodes.Add(tnMenu_Sub);

                            //dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Category WHERE Class =  " + iMenuSub + " and isnull(Deleted,0)<>1 order by ID");
                            //foreach (DataRow crow in dtTreeView2.Rows)
                            //{
                            //    TreeNode tnMenu_Sub = new TreeNode();
                            //    tnMenu_Sub.Text = crow["Name"].ToString();
                            //    tnMenu_Sub.Tag = crow["ID"].ToString();
                            //    tnMenu_Sub.ImageIndex = 1;
                            //    tnMenu_Sub.SelectedImageIndex = 1;
                            //    tnMenu.Nodes.Add(tnMenu_Sub);
                            //}
                        }
                    }
                    break;
                case LocalData.mySetup.Transport:
                case LocalData.mySetup.Gate:
                    break;
                case LocalData.mySetup.Account:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From AcctMainGroup order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = "A" + caRow["ID"].ToString();
                        tnMenu.ImageIndex = 7;
                        tnMenu.SelectedImageIndex = 7;
                        int.TryParse(caRow["ID"].ToString(), out iMenuSub);
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);

                        try
                        {
                            dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']-' + ISNULL(NULLIF(SubGroupCode,''), Short) From AcctSubGroup WHERE isnull(Deleted,0)<>1 and MainGroupID =  " + iMenuSub + " order by ID");
                        }
                        catch
                        {
                            dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From AcctSubGroup WHERE isnull(Deleted,0)<>1 and MainGroupID =  " + iMenuSub + " order by ID");
                        }
                        foreach (DataRow crow in dtTreeView2.Rows)
                        {
                            TreeNode tnMenu_Sub = new TreeNode();
                            int GroupID;
                            tnMenu_Sub.Text = crow["Name"].ToString();
                            tnMenu_Sub.Tag = "B" + crow["ID"].ToString();
                            int.TryParse(crow["ID"].ToString(), out GroupID);
                            tnMenu_Sub.ImageIndex = 8;
                            tnMenu_Sub.SelectedImageIndex = 8;
                            tnMenu.Nodes.Add(tnMenu_Sub);


                            dtTreeView3 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From AcctGroup WHERE isnull(Deleted,0)<>1 and SubGroupID =  " + GroupID + " order by ID");
                            foreach (DataRow cr in dtTreeView3.Rows)
                            {
                                TreeNode tnSub = new TreeNode();
                                tnSub.Text = cr["Name"].ToString();
                                tnSub.Tag = cr["ID"].ToString();
                                tnSub.ImageIndex = 9;
                                tnSub.SelectedImageIndex = 9;
                                tnMenu_Sub.Nodes.Add(tnSub);
                            }
                        }
                    }
                    break;
                case LocalData.mySetup.AcctGroup:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From AcctMainGroup order by ID ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = "A" + caRow["ID"].ToString();
                        tnMenu.ImageIndex = 7;
                        tnMenu.SelectedImageIndex = 7;
                        int.TryParse(caRow["ID"].ToString(), out iMenuSub);
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);

                        try
                        {
                            dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']-' + ISNULL(NULLIF(SubGroupCode,''), Short) From AcctSubGroup WHERE MainGroupID =  " + iMenuSub + " order by ID");
                        }
                        catch
                        {
                            dtTreeView2 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From AcctSubGroup WHERE MainGroupID =  " + iMenuSub + " order by ID");
                        }
                        foreach (DataRow crow in dtTreeView2.Rows)
                        {
                            TreeNode tnMenu_Sub = new TreeNode();
                            int GroupID;
                            tnMenu_Sub.Text = crow["Name"].ToString();
                            tnMenu_Sub.Tag = "B" + crow["ID"].ToString();
                            int.TryParse(crow["ID"].ToString(), out GroupID);
                            tnMenu_Sub.ImageIndex = 8;
                            tnMenu_Sub.SelectedImageIndex = 8;
                            tnMenu.Nodes.Add(tnMenu_Sub);

                        }
                    }
                    break;
                case LocalData.mySetup.Unit:
                    break;
                case LocalData.mySetup.Users:
                    break;
                case LocalData.mySetup.Brand:
                    dtTreeView1 = DBConnection.GetSQLTable("SELECT ID, Name = Name + ' - [' + Short + ']' From Brand Where isnull(Deleted,0)<>1  order by Short ");
                    foreach (DataRow caRow in dtTreeView1.Rows)
                    {
                        TreeNode tnMenu = new TreeNode();
                        tnMenu.Text = caRow["Name"].ToString();
                        tnMenu.Tag = caRow["ID"].ToString();
                        tnMenu.ImageIndex = 5;
                        tnMenu.SelectedImageIndex = 5;
                        tvSetup.Nodes[0].Nodes.Add(tnMenu);
                    }
                    break;
                default:
                    break;
            }

            

            tvSetup.Nodes[0].Expand();
            tvSetup.EndUpdate();
            SelNodeID = 0;
        }

        private void FillListView()
        {

            string m_name, st_group, st_detail, gcol, gtable, gwh, dcol, dtable, wh1, wh2, dwh;
            int count = 0;
            ListViewItem lvitem;
            ColumnHeader header;

            DataTable dt, dtcol;
            int col_count, col_width, width;

            m_name = string.Empty;
            st_group = string.Empty;
            st_detail = string.Empty;
            gcol = string.Empty;
            gtable = string.Empty;
            gwh = string.Empty;
            dcol = string.Empty;
            dtable = string.Empty;
            dwh = string.Empty;
            wh1 = string.Empty;
            wh2 = string.Empty;


            this.Cursor = Cursors.WaitCursor;
            dwh = " 1 = 1";
            //GetFilter();


            switch (LocalData.Setup)
            {
                case LocalData.mySetup.Branch:
                case LocalData.mySetup.Location:
                    m_name = "Location";
                    dcol = "A.ID, A.Short, A.Name, Type = B.Name";
                    dtable = " Location A Join LocationType B on A.TypeID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.TypeID = IIF(" + SelNodeID.ToString()+ " = 0, A.TypeID,"+ SelNodeID.ToString()+")";
                    break;
                case LocalData.mySetup.Class:
                case LocalData.mySetup.Category:
                case LocalData.mySetup.Code:
                    m_name = "Stock";
                    dcol = "A.ID, A.Short, A.Name, StockGroup = B.Name";
                    dtable = " Stock A Join StockGroup B on A.GroupID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.GroupID = IIF(" + SelNodeID.ToString() + " = 0, A.GroupID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Division:
                case LocalData.mySetup.Township:
                    m_name = "Township";
                    dcol = "A.ID, A.Short, A.Name, Division = B.Name";
                    dtable = " Township A Join Division B on A.DivisionID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.DivisionID = IIF(" + SelNodeID.ToString() + " = 0, A.DivisionID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Customer:
                    m_name = "Customer";
                    dcol = "A.ID, A.Short, A.Name, Address, Division = DV.Name, Township = B.Name";
                    dtable = " Customer A Join Township B on A.TownshipID = B.ID left Join Division DV on A.DivID = DV.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.TownshipID = IIF(" + SelNodeID.ToString() + " = 0, A.TownshipID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Supplier:
                    m_name = "Supplier";
                    dcol = "A.ID, A.Short, A.Name, A.Phone, Township = B.Name";
                    dtable = " Supplier A Join Township B on A.TownshipID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.TownshipID = IIF(" + SelNodeID.ToString() + " = 0, A.TownshipID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Manufacturer:
                    m_name = "Manufacturer";
                    dcol = "A.ID, A.Short, A.Name, A.Phone, Township = B.Name";
                    dtable = " Manufacturer A Join Township B on A.TownshipID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1 and A.TownshipID = IIF(" + SelNodeID.ToString() + " = 0, A.TownshipID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Transport:
                    m_name = "Gates";
                    dcol = "A.ID, A.Short, A.Name ";
                    dtable = " Transport A";
                    dwh = dwh + " And isnull(Deleted,0)<>1 ";
                    break;
                case LocalData.mySetup.Account:
                    m_name = "Account";
                    try
                    {
                        // AccountCode + Short as separate columns (no Short fallback — both visible)
                        dcol = "A.ID, AccountCode = ISNULL(A.AccountCode, N''), A.Short, A.Name, AcctGroup = B.Name";
                        DBConnection.GetSQLTable("Select TOP 0 AccountCode From AccountName");
                    }
                    catch
                    {
                        dcol = "A.ID, AccountCode = N'', A.Short, A.Name, AcctGroup = B.Name";
                    }
                    dtable = " AccountName A Join AcctGroup B on A.GroupID = B.ID Join AcctSubGroup C on B.SubGroupID = C.ID ";

                    if (SelTag.Substring(0, 1) == "A")
                    {
                        dwh = dwh + " And isnull(A.Deleted,0)<>1  And MainGroupID = IIF(" + SelTag.ToString().Substring(1, SelTag.ToString().Length - 1) + " = 0, MainGroupID," + SelTag.ToString().Substring(1, SelTag.ToString().Length - 1).ToString() + ")";
                    }
                    else if (SelTag.Substring(0, 1) == "B")
                    {
                        dwh = dwh + " And isnull(A.Deleted,0)<>1  And SubGroupID = IIF(" + SelTag.ToString().Substring(1, SelTag.ToString().Length - 1) + " = 0, SubGroupID," + SelTag.ToString().Substring(1, SelTag.ToString().Length - 1).ToString() + ")";
                    }
                    else
                    {
                        dwh = dwh + " And isnull(A.Deleted,0)<>1  And A.GroupID = IIF(" + SelNodeID.ToString() + " = 0, A.GroupID," + SelNodeID.ToString() + ")";
                    }
                    break;
                case LocalData.mySetup.AcctGroup:
                    m_name = "Account";
                    try
                    {
                        DBConnection.GetSQLTable("Select TOP 0 GroupCode From AcctGroup");
                        dcol = "A.ID, AccountCode = ISNULL(A.GroupCode, N''), A.Short, A.Name, AcctGroup = B.Name";
                    }
                    catch
                    {
                        dcol = "A.ID, AccountCode = N'', A.Short, A.Name, AcctGroup = B.Name";
                    }
                    dtable = " AcctGroup A Join AcctSubGroup B on A.SubGroupID = B.ID ";
                    dwh = dwh + " And isnull(A.Deleted,0)<>1  And A.SubGroupID = IIF(" + SelNodeID.ToString() + " = 0, A.SubGroupID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Unit:
                    m_name = "Gates";
                    dcol = "A.ID, A.Short, A.Name ";
                    dtable = " Unit A ";
                    dwh = dwh + " And isnull(Deleted,0)<>1 ";
                    break;
                case LocalData.mySetup.Users:
                    m_name = "Gates";
                    dcol = "A.ID, A.Short, A.Name ";
                    dtable = " Users A ";
                    dwh = dwh + " And isnull(Deleted,0)<>1 ";
                    break;

                case LocalData.mySetup.Brand:
                    m_name = "Brand";
                    dcol = "G.ID, A.Short, A.Name, StockGroup = B.Name";
                    dtable = " BrandNStockGroup G Join  Brand A on G.BrandID = A.ID Join StockGroup B on G.StockGroupID = B.ID ";
                    dwh = dwh + " And G.BrandID = IIF(" + SelNodeID.ToString() + " = 0, G.BrandID," + SelNodeID.ToString() + ")";
                    break;
                case LocalData.mySetup.Gate:
                    m_name = "Gates";
                    dcol = "A.ID, A.Short, A.Name ";
                    dtable = " Gates A ";
                    dwh = dwh + " And isnull(Deleted,0)<>1 ";
                    break;
                case LocalData.mySetup.Cars:
                    m_name = "Gates";
                    dcol = "A.ID, A.Short, A.Name ";
                    dtable = " Cars A";
                    dwh = dwh + " And isnull(Deleted,0)<>1 ";
                    break;
                default:
                    break;
            }

            st_detail = string.Format("Select {0} From {1} Where {2} ", dcol, dtable, dwh);
            //dt = new DataTable();
            //dt = DBConnection.GetSQLTable("Select ColumnHeader, ColumnWidth From ListviewItem Where MenuName = '" + m_name + "' and ColumnName <> 'ID' ");
            //col_count = dt.Rows.Count;
            //col_width = (lvHistory.Width - 500) / col_count;

            //foreach (DataRow drow in dt.Rows)
            //{
            //    //header = new ColumnHeader();
            //    //header.Text = drow["ColumnHeader"].ToString();
            //    //int.TryParse(drow["ColumnWidth"].ToString(), out width);
            //    //header.Width = col_width + width;
            //    //lvHistory.Columns.Add(header);
            //}

            dt = new DataTable();
            DataColumn AutoNumberColumn = new DataColumn();
            AutoNumberColumn.ColumnName = "Sr";
            AutoNumberColumn.DataType = typeof(int);
            AutoNumberColumn.AutoIncrement = true;
            AutoNumberColumn.AutoIncrementSeed = 1;
            AutoNumberColumn.AutoIncrementStep = 1;
            dt.Columns.Add(AutoNumberColumn);
            DateTime date;
            decimal amount;
            SqlDataAdapter adp = new SqlDataAdapter(st_detail, DBConnection.ActiveConnection);
            adp.Fill(dt);
            //dt = DBConnection.GetSQLTable(st_detail);

            dlvHistory.Clear();
            dlvHistory.AllColumns.Clear();
            dlvHistory.DataSource = dt;
            dlvHistory.View = View.Details;
            dlvHistory.Columns["Sr"].Width = 80;
            dlvHistory.Columns["ID"].Width = 0;
            dlvHistory.HeaderFont = new System.Drawing.Font("Pyidaungsu", 13F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));


            dtcol = DBConnection.GetSQLTable("Select ColumnName, ColumnWidth, ColumnHeader From ListviewItem Where MenuName = '" + m_name + "'");
            foreach (DataRow crow in dtcol.Rows)
            {
                string colName = crow["ColumnName"].ToString();
                try
                {
                    if (dlvHistory.Columns[colName] == null)
                        continue;
                    dlvHistory.Columns[colName].Width = (int)crow["ColumnWidth"];
                    dlvHistory.Columns[colName].Text = crow["ColumnHeader"].ToString();
                }
                catch
                {
                    // column missing in this result set — skip
                }
            }

            // Setup Accounts / Account Group: show BOTH
            //   Account Code  = AccountCode (or GroupCode)
            //   Code          = Short
            if (LocalData.Setup == LocalData.mySetup.Account || LocalData.Setup == LocalData.mySetup.AcctGroup)
            {
                try
                {
                    if (dlvHistory.Columns["AccountCode"] != null)
                    {
                        dlvHistory.Columns["AccountCode"].Text = "Account Code";
                        if (dlvHistory.Columns["AccountCode"].Width < 140)
                            dlvHistory.Columns["AccountCode"].Width = 140;
                    }
                }
                catch { /* AccountCode column not in grid */ }

                try
                {
                    if (dlvHistory.Columns["Short"] != null)
                    {
                        dlvHistory.Columns["Short"].Text = "Code";
                        if (dlvHistory.Columns["Short"].Width < 100)
                            dlvHistory.Columns["Short"].Width = 100;
                    }
                }
                catch { /* Short column not in grid */ }
            }

            this.Cursor = Cursors.Default;
        }


    }
}
