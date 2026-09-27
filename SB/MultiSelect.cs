using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace SB
{
    public partial class MultiSelect : UserControl
    {
        Boolean DropDown = false;
        string m_Selection;
        string SelectedList = string.Empty, SelectedName = string.Empty;
        int m_Count;
        public string ShowSelection
        {
            get { return m_Selection; }
            set { m_Selection = value; tbSelect.Text = string.Format("All {0}s Selected", value); }
        }

        public string GetSelection
        {
            get { return SelectedList; }
        }

        public string GetSelectionName
        {
            get { return SelectedName; }
        }
        public int SelectionCount
        {
            get { return m_Count; }
        }

        public DataTable DataSource
        {
            set
            {
                dgvSelection.DataSource = value;
                dgvSelection.Columns["ID"].Visible = false;
                dgvSelection.Columns["Name"].Width = 230;
                dgvSelection.Columns["Selected"].Width = 35;
                dgvSelection.Columns["Name"].ReadOnly = true;
            }
        }

        private void pbDropDown_Click(object sender, EventArgs e)
        {
            DropDown = !DropDown;
            if (DropDown)
            {
                pbDropDown.Image = Properties.Resources.down;
                splitContainer1.Panel2Collapsed = false;
                this.Height = 380;
                // Expanded list must paint over sibling filters below
                this.BringToFront();
                tbSearch.Focus();
            }
            else
            {
                pbDropDown.Image = Properties.Resources.down_arrow1;
                splitContainer1.Panel2Collapsed = true;
                this.Height = 40;

                tbSearch.Text = "";
                tbSearch_Validated(sender, e);
                bool chk, all;
                m_Count = 0;
                SelectedList = string.Empty;
                SelectedName = string.Empty;

                int id;
                int.TryParse(dgvSelection.Rows[0].Cells["ID"].Value.ToString(), out id);
                bool.TryParse(dgvSelection.Rows[0].Cells["Selected"].Value.ToString(), out all);
                if (id != -2 || !all)
                {
                    foreach (DataGridViewRow row in dgvSelection.Rows)
                    {
                        bool.TryParse(row.Cells["Selected"].Value.ToString(), out chk);
                        if (chk)
                        {
                            SelectedList = SelectedList + row.Cells["ID"].Value.ToString() + ",";
                            SelectedName = SelectedName + row.Cells["Name"].Value.ToString() + ",";
                            m_Count++;
                        }
                    }
                    if (m_Count > 0)
                    {
                        SelectedList = SelectedList.Substring(0, SelectedList.Length - 1);
                        SelectedName = SelectedName.Substring(0, SelectedName.Length - 1);
                        tbSelect.Text = string.Format("({0}) {1}s Selected", SelectionCount.ToString(), m_Selection);
                    }

                }
                else
                {

                }

            }
        }

        private void dgvSelection_CellEndEdit(object sender, DataGridViewCellEventArgs e)
        {
            int id;
            bool all;

            //SelectionCount = 0;


            int.TryParse(dgvSelection.Rows[e.RowIndex].Cells["ID"].Value.ToString(), out id);
            if (id == -2)
            {
                bool.TryParse(dgvSelection.Rows[e.RowIndex].Cells["Selected"].Value.ToString(), out all);
                tbSelect.Text = string.Format("All {0}s Selected", m_Selection);
                m_Count = 0;
                SelectedList = string.Empty;
                SelectedName = string.Empty;
                foreach (DataGridViewRow row in dgvSelection.Rows)
                {
                    row.Cells["Selected"].Value = all;
                }

                return;
            }
            else
            {
                //foreach (DataGridViewRow row in dgvSelection.Rows)
                //{
                //    bool.TryParse(row.Cells["Selected"].Value.ToString(), out chk);
                //    if (chk)
                //    {
                //        SelectedList = SelectedList + row.Cells["ID"].Value.ToString() + ",";
                //        SelectionCount++;
                //    }
                //}
                //if (SelectionCount > 0)
                //{
                //    SelectedList = SelectedList.Substring(0, SelectedList.Length - 1);
                //}
                //tbSelect.Text = string.Format("({0}) {1}s Selected", SelectionCount.ToString(), m_Selection);

            }
        }

        public void UnCheckAll()
        {
            tbSelect.Text = string.Format("All {0}s Selected", m_Selection);
            m_Count = 0;
            SelectedList = string.Empty;
            SelectedName = string.Empty;
            (dgvSelection.DataSource as DataTable).DefaultView.RowFilter = "Name like '%'";
            foreach (DataGridViewRow row in dgvSelection.Rows)
            {
                row.Cells["Selected"].Value = false;
            }
        }

        private void dgvSelection_CellEnter(object sender, DataGridViewCellEventArgs e)
        {
            if (e.ColumnIndex == 1)
            {
                SendKeys.Send("{Tab}");
            }
        }

        private void MultiSelect_EnabledChanged(object sender, EventArgs e)
        {
            pbDropDown.Visible = Enabled;
        }

        private void tbSelect_Validated(object sender, EventArgs e)
        {
            (dgvSelection.DataSource as DataTable).DefaultView.RowFilter = "Name like '" + tbSearch.Text.ToString() + "%'";
        }

        private void pbUncheck_Click(object sender, EventArgs e)
        {
            UnCheckAll();
            tbSearch.Focus();
        }

        private void tbSearch_Validated(object sender, EventArgs e)
        {
            (dgvSelection.DataSource as DataTable).DefaultView.RowFilter = "Name like '" + tbSearch.Text.ToString() + "%'";
        }

        public MultiSelect()
        {
            InitializeComponent();
        }
    }
}
