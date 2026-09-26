
namespace SB
{
    partial class frm_Preview
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.crvPreview = new CrystalDecisions.Windows.Forms.CrystalReportViewer();
            this.SuspendLayout();
            // 
            // crvPreview
            // 
            this.crvPreview.ActiveViewIndex = -1;
            this.crvPreview.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.crvPreview.Cursor = System.Windows.Forms.Cursors.Default;
            this.crvPreview.DisplayBackgroundEdge = false;
            this.crvPreview.DisplayStatusBar = false;
            this.crvPreview.Dock = System.Windows.Forms.DockStyle.Fill;
            this.crvPreview.EnableDrillDown = false;
            this.crvPreview.EnableRefresh = false;
            this.crvPreview.Location = new System.Drawing.Point(0, 0);
            this.crvPreview.Name = "crvPreview";
            this.crvPreview.ShowCloseButton = false;
            this.crvPreview.ShowCopyButton = false;
            this.crvPreview.ShowGroupTreeButton = false;
            this.crvPreview.ShowLogo = false;
            this.crvPreview.ShowParameterPanelButton = false;
            this.crvPreview.ShowRefreshButton = false;
            this.crvPreview.Size = new System.Drawing.Size(1904, 1041);
            this.crvPreview.TabIndex = 1;
            this.crvPreview.TabStop = false;
            this.crvPreview.ToolPanelView = CrystalDecisions.Windows.Forms.ToolPanelViewType.None;
            this.crvPreview.ToolPanelWidth = 100;
            // 
            // frm_Preview
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(1904, 1041);
            this.Controls.Add(this.crvPreview);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frm_Preview";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "frm_Preview";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.Load += new System.EventHandler(this.frm_Preview_Load);
            this.ResumeLayout(false);

        }

        #endregion

        private CrystalDecisions.Windows.Forms.CrystalReportViewer crvPreview;
    }
}