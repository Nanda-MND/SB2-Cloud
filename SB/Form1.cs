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
    public partial class frm_Amount : Form
    {
        public frm_Amount()
        {
            InitializeComponent();
        }

        private void btFind_Click(object sender, EventArgs e)
        {
            int amt;
            int.TryParse(tbMin.Text.ToString(), out amt);
            Transaction.MinAmount = amt;
            int.TryParse(tbMax.Text.ToString(), out amt);
            Transaction.MaxAmount = amt;
            this.Close();
            this.DialogResult = DialogResult.OK;
        }

        private void frm_Amount_Load(object sender, EventArgs e)
        {

        }
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            if (keyData == Keys.F1)
            {
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
            else if (keyData == Keys.F10)
            {
                return true;
            }

            return base.ProcessCmdKey(ref msg, keyData);
        }
    }
}
