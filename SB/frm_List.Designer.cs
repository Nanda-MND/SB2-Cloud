using System.Drawing;
using System.Windows.Forms;
using BrightIdeasSoftware;

namespace SB
{
    partial class frm_List
    {
        private System.ComponentModel.IContainer components = null;
        private FastObjectListView dlvPopup;
        private Button btnClose;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
                components.Dispose();
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.dlvPopup = new FastObjectListView();
            this.btnClose = new Button();
            ((System.ComponentModel.ISupportInitialize)(this.dlvPopup)).BeginInit();
            this.SuspendLayout();

            this.btnClose.Dock = DockStyle.Bottom;
            this.btnClose.Height = 32;
            this.btnClose.Text = "Close";
            this.btnClose.DialogResult = DialogResult.OK;

            this.dlvPopup.Dock = DockStyle.Fill;
            this.dlvPopup.FullRowSelect = true;
            this.dlvPopup.GridLines = true;
            this.dlvPopup.HideSelection = false;
            this.dlvPopup.MultiSelect = true;
            this.dlvPopup.View = View.Details;
            this.dlvPopup.Name = "dlvPopup";

            this.AcceptButton = this.btnClose;
            this.ClientSize = new Size(900, 480);
            this.StartPosition = FormStartPosition.CenterParent;
            this.Text = "List";
            this.Controls.Add(this.dlvPopup);
            this.Controls.Add(this.btnClose);

            ((System.ComponentModel.ISupportInitialize)(this.dlvPopup)).EndInit();
            this.ResumeLayout(false);
        }
    }
}
