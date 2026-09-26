
namespace SB
{
    partial class frm_CodeList
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
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.cbLocation = new System.Windows.Forms.ComboBox();
            this.tbCode = new System.Windows.Forms.TextBox();
            this.olvCode = new BrightIdeasSoftware.DataListView();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.olvCode)).BeginInit();
            this.SuspendLayout();
            // 
            // splitContainer1
            // 
            this.splitContainer1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.Controls.Add(this.cbLocation);
            this.splitContainer1.Panel1.Controls.Add(this.tbCode);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.olvCode);
            this.splitContainer1.Size = new System.Drawing.Size(1012, 736);
            this.splitContainer1.SplitterDistance = 51;
            this.splitContainer1.TabIndex = 0;
            this.splitContainer1.TabStop = false;
            // 
            // cbLocation
            // 
            this.cbLocation.FormattingEnabled = true;
            this.cbLocation.Location = new System.Drawing.Point(576, 6);
            this.cbLocation.Name = "cbLocation";
            this.cbLocation.Size = new System.Drawing.Size(431, 38);
            this.cbLocation.TabIndex = 3;
            this.cbLocation.Visible = false;
            this.cbLocation.DropDownClosed += new System.EventHandler(this.cbLocation_DropDownClosed);
            this.cbLocation.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbLocation_KeyPress);
            // 
            // tbCode
            // 
            this.tbCode.Location = new System.Drawing.Point(6, 7);
            this.tbCode.Name = "tbCode";
            this.tbCode.Size = new System.Drawing.Size(567, 37);
            this.tbCode.TabIndex = 2;
            this.tbCode.Text = "Type here to Search Code";
            this.tbCode.Visible = false;
            this.tbCode.TextChanged += new System.EventHandler(this.tbCode_TextChanged);
            // 
            // olvCode
            // 
            this.olvCode.AlternateRowBackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.olvCode.BackColor = System.Drawing.Color.White;
            this.olvCode.CellEditUseWholeCell = false;
            this.olvCode.DataSource = null;
            this.olvCode.Dock = System.Windows.Forms.DockStyle.Fill;
            this.olvCode.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.olvCode.FullRowSelect = true;
            this.olvCode.GridLines = true;
            this.olvCode.HideSelection = false;
            this.olvCode.Location = new System.Drawing.Point(0, 0);
            this.olvCode.Name = "olvCode";
            this.olvCode.ShowGroups = false;
            this.olvCode.Size = new System.Drawing.Size(1012, 681);
            this.olvCode.TabIndex = 1;
            this.olvCode.UseCellFormatEvents = true;
            this.olvCode.UseCompatibleStateImageBehavior = false;
            this.olvCode.View = System.Windows.Forms.View.Details;
            this.olvCode.KeyDown += new System.Windows.Forms.KeyEventHandler(this.olvCode_KeyDown);
            // 
            // frm_CodeList
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(1012, 736);
            this.Controls.Add(this.splitContainer1);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.Name = "frm_CodeList";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Code List";
            this.Load += new System.EventHandler(this.frm_CodeList_Load);
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel1.PerformLayout();
            this.splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.olvCode)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.ComboBox cbLocation;
        private System.Windows.Forms.TextBox tbCode;
        private BrightIdeasSoftware.DataListView olvCode;
    }
}