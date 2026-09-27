
namespace SB
{
    partial class frm_Users
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
            this.components = new System.ComponentModel.Container();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle4 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle5 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle6 = new System.Windows.Forms.DataGridViewCellStyle();
            this.dgvEntry = new System.Windows.Forms.DataGridView();
            this.cmsuserright = new System.Windows.Forms.ContextMenuStrip(this.components);
            this.allowCheckAllToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.checkAllow = new System.Windows.Forms.ToolStripMenuItem();
            this.checkEdit = new System.Windows.Forms.ToolStripMenuItem();
            this.checkDelete = new System.Windows.Forms.ToolStripMenuItem();
            this.alowToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.uncheckAllow = new System.Windows.Forms.ToolStripMenuItem();
            this.uncheckEdit = new System.Windows.Forms.ToolStripMenuItem();
            this.uncheckDelete = new System.Windows.Forms.ToolStripMenuItem();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.label3 = new System.Windows.Forms.Label();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.tabControl1 = new System.Windows.Forms.TabControl();
            this.tpProfile = new System.Windows.Forms.TabPage();
            this.chkPassword = new System.Windows.Forms.CheckBox();
            this.tbConfirm = new System.Windows.Forms.TextBox();
            this.lbConfirm = new System.Windows.Forms.Label();
            this.tbNew = new System.Windows.Forms.TextBox();
            this.lbNew = new System.Windows.Forms.Label();
            this.tbCurrent = new System.Windows.Forms.TextBox();
            this.lbCurrent = new System.Windows.Forms.Label();
            this.tbName = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.tbShort = new System.Windows.Forms.TextBox();
            this.lbShort = new System.Windows.Forms.Label();
            this.tpSetup = new System.Windows.Forms.TabPage();
            this.dgvSetup = new System.Windows.Forms.DataGridView();
            this.tpEntry = new System.Windows.Forms.TabPage();
            this.tpReports = new System.Windows.Forms.TabPage();
            this.dgvReport = new System.Windows.Forms.DataGridView();
            this.btClose = new System.Windows.Forms.Button();
            this.btSave = new System.Windows.Forms.Button();
            ((System.ComponentModel.ISupportInitialize)(this.dgvEntry)).BeginInit();
            this.cmsuserright.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            this.tabControl1.SuspendLayout();
            this.tpProfile.SuspendLayout();
            this.tpSetup.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvSetup)).BeginInit();
            this.tpEntry.SuspendLayout();
            this.tpReports.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvReport)).BeginInit();
            this.SuspendLayout();
            // 
            // dgvEntry
            // 
            this.dgvEntry.AllowUserToAddRows = false;
            this.dgvEntry.AllowUserToDeleteRows = false;
            dataGridViewCellStyle1.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvEntry.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle1;
            this.dgvEntry.BackgroundColor = System.Drawing.Color.White;
            this.dgvEntry.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvEntry.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvEntry.ContextMenuStrip = this.cmsuserright;
            this.dgvEntry.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvEntry.Location = new System.Drawing.Point(3, 3);
            this.dgvEntry.Name = "dgvEntry";
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvEntry.RowsDefaultCellStyle = dataGridViewCellStyle2;
            this.dgvEntry.RowTemplate.DefaultCellStyle.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvEntry.RowTemplate.Height = 30;
            this.dgvEntry.Size = new System.Drawing.Size(719, 668);
            this.dgvEntry.TabIndex = 18;
            this.dgvEntry.Enter += new System.EventHandler(this.dgvEntry_Enter);
            // 
            // cmsuserright
            // 
            this.cmsuserright.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.cmsuserright.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.allowCheckAllToolStripMenuItem,
            this.alowToolStripMenuItem});
            this.cmsuserright.Name = "cmsuserright";
            this.cmsuserright.Size = new System.Drawing.Size(181, 86);
            // 
            // allowCheckAllToolStripMenuItem
            // 
            this.allowCheckAllToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.checkAllow,
            this.checkEdit,
            this.checkDelete});
            this.allowCheckAllToolStripMenuItem.Name = "allowCheckAllToolStripMenuItem";
            this.allowCheckAllToolStripMenuItem.Size = new System.Drawing.Size(180, 30);
            this.allowCheckAllToolStripMenuItem.Text = "Check All";
            // 
            // checkAllow
            // 
            this.checkAllow.Name = "checkAllow";
            this.checkAllow.Size = new System.Drawing.Size(180, 30);
            this.checkAllow.Text = "Allow";
            this.checkAllow.Click += new System.EventHandler(this.checkAllow_Click);
            // 
            // checkEdit
            // 
            this.checkEdit.Name = "checkEdit";
            this.checkEdit.Size = new System.Drawing.Size(180, 30);
            this.checkEdit.Text = "Edit";
            this.checkEdit.Click += new System.EventHandler(this.checkEdit_Click);
            // 
            // checkDelete
            // 
            this.checkDelete.Name = "checkDelete";
            this.checkDelete.Size = new System.Drawing.Size(180, 30);
            this.checkDelete.Text = "Delete";
            this.checkDelete.Click += new System.EventHandler(this.checkDelete_Click);
            // 
            // alowToolStripMenuItem
            // 
            this.alowToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.uncheckAllow,
            this.uncheckEdit,
            this.uncheckDelete});
            this.alowToolStripMenuItem.Name = "alowToolStripMenuItem";
            this.alowToolStripMenuItem.Size = new System.Drawing.Size(180, 30);
            this.alowToolStripMenuItem.Text = "Uncheck All";
            // 
            // uncheckAllow
            // 
            this.uncheckAllow.Name = "uncheckAllow";
            this.uncheckAllow.Size = new System.Drawing.Size(180, 30);
            this.uncheckAllow.Text = "Allow";
            this.uncheckAllow.Click += new System.EventHandler(this.uncheckAllow_Click);
            // 
            // uncheckEdit
            // 
            this.uncheckEdit.Name = "uncheckEdit";
            this.uncheckEdit.Size = new System.Drawing.Size(180, 30);
            this.uncheckEdit.Text = "Edit";
            this.uncheckEdit.Click += new System.EventHandler(this.uncheckEdit_Click);
            // 
            // uncheckDelete
            // 
            this.uncheckDelete.Name = "uncheckDelete";
            this.uncheckDelete.Size = new System.Drawing.Size(180, 30);
            this.uncheckDelete.Text = "Delete";
            this.uncheckDelete.Click += new System.EventHandler(this.uncheckDelete_Click);
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.FixedPanel = System.Windows.Forms.FixedPanel.Panel1;
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.BackColor = System.Drawing.Color.Red;
            this.splitContainer1.Panel1.Controls.Add(this.label3);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer2);
            this.splitContainer1.Size = new System.Drawing.Size(733, 850);
            this.splitContainer1.TabIndex = 2;
            this.splitContainer1.TabStop = false;
            // 
            // label3
            // 
            this.label3.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.label3.ForeColor = System.Drawing.Color.White;
            this.label3.Location = new System.Drawing.Point(3, 5);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(730, 43);
            this.label3.TabIndex = 1;
            this.label3.Text = "Setup Detail";
            this.label3.TextAlign = System.Drawing.ContentAlignment.MiddleCenter;
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.FixedPanel = System.Windows.Forms.FixedPanel.Panel2;
            this.splitContainer2.Location = new System.Drawing.Point(0, 0);
            this.splitContainer2.Name = "splitContainer2";
            this.splitContainer2.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.tabControl1);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this.btClose);
            this.splitContainer2.Panel2.Controls.Add(this.btSave);
            this.splitContainer2.Size = new System.Drawing.Size(733, 796);
            this.splitContainer2.SplitterDistance = 717;
            this.splitContainer2.TabIndex = 0;
            this.splitContainer2.TabStop = false;
            // 
            // tabControl1
            // 
            this.tabControl1.Controls.Add(this.tpProfile);
            this.tabControl1.Controls.Add(this.tpSetup);
            this.tabControl1.Controls.Add(this.tpEntry);
            this.tabControl1.Controls.Add(this.tpReports);
            this.tabControl1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.tabControl1.Location = new System.Drawing.Point(0, 0);
            this.tabControl1.Name = "tabControl1";
            this.tabControl1.SelectedIndex = 0;
            this.tabControl1.Size = new System.Drawing.Size(733, 717);
            this.tabControl1.TabIndex = 0;
            // 
            // tpProfile
            // 
            this.tpProfile.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.tpProfile.Controls.Add(this.chkPassword);
            this.tpProfile.Controls.Add(this.tbConfirm);
            this.tpProfile.Controls.Add(this.lbConfirm);
            this.tpProfile.Controls.Add(this.tbNew);
            this.tpProfile.Controls.Add(this.lbNew);
            this.tpProfile.Controls.Add(this.tbCurrent);
            this.tpProfile.Controls.Add(this.lbCurrent);
            this.tpProfile.Controls.Add(this.tbName);
            this.tpProfile.Controls.Add(this.label1);
            this.tpProfile.Controls.Add(this.tbShort);
            this.tpProfile.Controls.Add(this.lbShort);
            this.tpProfile.Location = new System.Drawing.Point(4, 39);
            this.tpProfile.Name = "tpProfile";
            this.tpProfile.Padding = new System.Windows.Forms.Padding(3);
            this.tpProfile.Size = new System.Drawing.Size(725, 674);
            this.tpProfile.TabIndex = 0;
            this.tpProfile.Text = "Profile";
            // 
            // chkPassword
            // 
            this.chkPassword.AutoSize = true;
            this.chkPassword.Location = new System.Drawing.Point(181, 133);
            this.chkPassword.Name = "chkPassword";
            this.chkPassword.Size = new System.Drawing.Size(160, 34);
            this.chkPassword.TabIndex = 16;
            this.chkPassword.Text = "Change Password";
            this.chkPassword.UseVisualStyleBackColor = true;
            this.chkPassword.CheckedChanged += new System.EventHandler(this.chkPassword_CheckedChanged);
            // 
            // tbConfirm
            // 
            this.tbConfirm.Location = new System.Drawing.Point(181, 259);
            this.tbConfirm.Name = "tbConfirm";
            this.tbConfirm.PasswordChar = '*';
            this.tbConfirm.Size = new System.Drawing.Size(427, 37);
            this.tbConfirm.TabIndex = 13;
            this.tbConfirm.Visible = false;
            // 
            // lbConfirm
            // 
            this.lbConfirm.Location = new System.Drawing.Point(11, 262);
            this.lbConfirm.Name = "lbConfirm";
            this.lbConfirm.Size = new System.Drawing.Size(169, 33);
            this.lbConfirm.TabIndex = 12;
            this.lbConfirm.Text = "Confirm Password : ";
            this.lbConfirm.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            this.lbConfirm.Visible = false;
            // 
            // tbNew
            // 
            this.tbNew.Location = new System.Drawing.Point(181, 216);
            this.tbNew.Name = "tbNew";
            this.tbNew.PasswordChar = '*';
            this.tbNew.Size = new System.Drawing.Size(427, 37);
            this.tbNew.TabIndex = 11;
            this.tbNew.Visible = false;
            // 
            // lbNew
            // 
            this.lbNew.Location = new System.Drawing.Point(11, 219);
            this.lbNew.Name = "lbNew";
            this.lbNew.Size = new System.Drawing.Size(169, 30);
            this.lbNew.TabIndex = 10;
            this.lbNew.Text = "New Password : ";
            this.lbNew.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            this.lbNew.Visible = false;
            // 
            // tbCurrent
            // 
            this.tbCurrent.Location = new System.Drawing.Point(181, 173);
            this.tbCurrent.Name = "tbCurrent";
            this.tbCurrent.PasswordChar = '*';
            this.tbCurrent.Size = new System.Drawing.Size(427, 37);
            this.tbCurrent.TabIndex = 9;
            this.tbCurrent.Visible = false;
            // 
            // lbCurrent
            // 
            this.lbCurrent.Location = new System.Drawing.Point(11, 176);
            this.lbCurrent.Name = "lbCurrent";
            this.lbCurrent.Size = new System.Drawing.Size(169, 33);
            this.lbCurrent.TabIndex = 8;
            this.lbCurrent.Text = "Current Password : ";
            this.lbCurrent.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            this.lbCurrent.Visible = false;
            // 
            // tbName
            // 
            this.tbName.Location = new System.Drawing.Point(181, 82);
            this.tbName.Name = "tbName";
            this.tbName.Size = new System.Drawing.Size(427, 37);
            this.tbName.TabIndex = 7;
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(11, 85);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(169, 30);
            this.label1.TabIndex = 6;
            this.label1.Text = "Name : ";
            this.label1.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // tbShort
            // 
            this.tbShort.Location = new System.Drawing.Point(181, 39);
            this.tbShort.Name = "tbShort";
            this.tbShort.Size = new System.Drawing.Size(427, 37);
            this.tbShort.TabIndex = 5;
            // 
            // lbShort
            // 
            this.lbShort.Location = new System.Drawing.Point(11, 42);
            this.lbShort.Name = "lbShort";
            this.lbShort.Size = new System.Drawing.Size(169, 33);
            this.lbShort.TabIndex = 4;
            this.lbShort.Text = "Short : ";
            this.lbShort.TextAlign = System.Drawing.ContentAlignment.MiddleRight;
            // 
            // tpSetup
            // 
            this.tpSetup.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.tpSetup.Controls.Add(this.dgvSetup);
            this.tpSetup.Location = new System.Drawing.Point(4, 39);
            this.tpSetup.Name = "tpSetup";
            this.tpSetup.Padding = new System.Windows.Forms.Padding(3);
            this.tpSetup.Size = new System.Drawing.Size(725, 674);
            this.tpSetup.TabIndex = 1;
            this.tpSetup.Text = "Setup";
            // 
            // dgvSetup
            // 
            this.dgvSetup.AllowUserToAddRows = false;
            this.dgvSetup.AllowUserToDeleteRows = false;
            dataGridViewCellStyle3.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSetup.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle3;
            this.dgvSetup.BackgroundColor = System.Drawing.Color.White;
            this.dgvSetup.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvSetup.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvSetup.ContextMenuStrip = this.cmsuserright;
            this.dgvSetup.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvSetup.Location = new System.Drawing.Point(3, 3);
            this.dgvSetup.Name = "dgvSetup";
            dataGridViewCellStyle4.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSetup.RowsDefaultCellStyle = dataGridViewCellStyle4;
            this.dgvSetup.RowTemplate.DefaultCellStyle.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSetup.RowTemplate.Height = 30;
            this.dgvSetup.Size = new System.Drawing.Size(719, 668);
            this.dgvSetup.TabIndex = 17;
            this.dgvSetup.Enter += new System.EventHandler(this.dgvSetup_Enter);
            // 
            // tpEntry
            // 
            this.tpEntry.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.tpEntry.Controls.Add(this.dgvEntry);
            this.tpEntry.Location = new System.Drawing.Point(4, 39);
            this.tpEntry.Name = "tpEntry";
            this.tpEntry.Padding = new System.Windows.Forms.Padding(3);
            this.tpEntry.Size = new System.Drawing.Size(725, 674);
            this.tpEntry.TabIndex = 3;
            this.tpEntry.Text = "Entry";
            // 
            // tpReports
            // 
            this.tpReports.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.tpReports.Controls.Add(this.dgvReport);
            this.tpReports.Location = new System.Drawing.Point(4, 39);
            this.tpReports.Name = "tpReports";
            this.tpReports.Padding = new System.Windows.Forms.Padding(3);
            this.tpReports.Size = new System.Drawing.Size(725, 674);
            this.tpReports.TabIndex = 4;
            this.tpReports.Text = "Reports";
            // 
            // dgvReport
            // 
            this.dgvReport.AllowUserToAddRows = false;
            this.dgvReport.AllowUserToDeleteRows = false;
            dataGridViewCellStyle5.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvReport.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle5;
            this.dgvReport.BackgroundColor = System.Drawing.Color.White;
            this.dgvReport.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.dgvReport.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvReport.ContextMenuStrip = this.cmsuserright;
            this.dgvReport.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvReport.Location = new System.Drawing.Point(3, 3);
            this.dgvReport.Name = "dgvReport";
            dataGridViewCellStyle6.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvReport.RowsDefaultCellStyle = dataGridViewCellStyle6;
            this.dgvReport.RowTemplate.DefaultCellStyle.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvReport.RowTemplate.Height = 30;
            this.dgvReport.Size = new System.Drawing.Size(719, 668);
            this.dgvReport.TabIndex = 18;
            this.dgvReport.Enter += new System.EventHandler(this.dgvReport_Enter);
            // 
            // btClose
            // 
            this.btClose.Location = new System.Drawing.Point(383, 10);
            this.btClose.Name = "btClose";
            this.btClose.Size = new System.Drawing.Size(120, 53);
            this.btClose.TabIndex = 1;
            this.btClose.Text = "Close";
            this.btClose.UseVisualStyleBackColor = true;
            this.btClose.Click += new System.EventHandler(this.btClose_Click);
            // 
            // btSave
            // 
            this.btSave.Location = new System.Drawing.Point(220, 10);
            this.btSave.Name = "btSave";
            this.btSave.Size = new System.Drawing.Size(120, 53);
            this.btSave.TabIndex = 0;
            this.btSave.Text = "Save";
            this.btSave.UseVisualStyleBackColor = true;
            this.btSave.Click += new System.EventHandler(this.btSave_Click);
            // 
            // frm_Users
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.ClientSize = new System.Drawing.Size(733, 850);
            this.Controls.Add(this.splitContainer1);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frm_Users";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "User Setup";
            this.Load += new System.EventHandler(this.frm_Users_Load);
            ((System.ComponentModel.ISupportInitialize)(this.dgvEntry)).EndInit();
            this.cmsuserright.ResumeLayout(false);
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            this.tabControl1.ResumeLayout(false);
            this.tpProfile.ResumeLayout(false);
            this.tpProfile.PerformLayout();
            this.tpSetup.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvSetup)).EndInit();
            this.tpEntry.ResumeLayout(false);
            this.tpReports.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvReport)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.DataGridView dgvEntry;
        private System.Windows.Forms.ContextMenuStrip cmsuserright;
        private System.Windows.Forms.ToolStripMenuItem allowCheckAllToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem checkAllow;
        private System.Windows.Forms.ToolStripMenuItem checkEdit;
        private System.Windows.Forms.ToolStripMenuItem checkDelete;
        private System.Windows.Forms.ToolStripMenuItem alowToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem uncheckAllow;
        private System.Windows.Forms.ToolStripMenuItem uncheckEdit;
        private System.Windows.Forms.ToolStripMenuItem uncheckDelete;
        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.TabControl tabControl1;
        private System.Windows.Forms.TabPage tpProfile;
        private System.Windows.Forms.CheckBox chkPassword;
        private System.Windows.Forms.TextBox tbConfirm;
        private System.Windows.Forms.Label lbConfirm;
        private System.Windows.Forms.TextBox tbNew;
        private System.Windows.Forms.Label lbNew;
        private System.Windows.Forms.TextBox tbCurrent;
        private System.Windows.Forms.Label lbCurrent;
        private System.Windows.Forms.TextBox tbName;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.TextBox tbShort;
        private System.Windows.Forms.Label lbShort;
        private System.Windows.Forms.TabPage tpSetup;
        private System.Windows.Forms.DataGridView dgvSetup;
        private System.Windows.Forms.TabPage tpEntry;
        private System.Windows.Forms.TabPage tpReports;
        private System.Windows.Forms.DataGridView dgvReport;
        private System.Windows.Forms.Button btClose;
        private System.Windows.Forms.Button btSave;
    }
}