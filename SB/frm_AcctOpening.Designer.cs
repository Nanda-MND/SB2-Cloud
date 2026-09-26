
namespace SB
{
    partial class frm_AcctOpening
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
            this.closeToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.printToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.codeListsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.filesToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.erptransaction = new System.Windows.Forms.ErrorProvider(this.components);
            this.tbExgRate = new System.Windows.Forms.TextBox();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.label1 = new System.Windows.Forms.Label();
            this.cbAccount = new System.Windows.Forms.ComboBox();
            this.lbAccount = new System.Windows.Forms.Label();
            this.cbType = new System.Windows.Forms.ComboBox();
            this.lbPayment = new System.Windows.Forms.Label();
            this.tbDocumentID = new System.Windows.Forms.TextBox();
            this.tbAutoID = new System.Windows.Forms.TextBox();
            this.lbDocID = new System.Windows.Forms.Label();
            this.lbAuto = new System.Windows.Forms.Label();
            this.lblDate = new System.Windows.Forms.Label();
            this.dtpDate = new System.Windows.Forms.DateTimePicker();
            this.tbRemark = new System.Windows.Forms.TextBox();
            this.lbRemark = new System.Windows.Forms.Label();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.dgvDetail = new System.Windows.Forms.DataGridView();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel1 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel4 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel6 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel7 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel8 = new System.Windows.Forms.ToolStripStatusLabel();
            this.tbExpAmount = new System.Windows.Forms.TextBox();
            this.lbExpAmount = new System.Windows.Forms.Label();
            this.tbInAmount = new System.Windows.Forms.TextBox();
            this.lbInAmount = new System.Windows.Forms.Label();
            this.btPrint = new System.Windows.Forms.Button();
            this.btSave = new System.Windows.Forms.Button();
            this.menuStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.erptransaction)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvDetail)).BeginInit();
            this.statusStrip1.SuspendLayout();
            this.SuspendLayout();
            // 
            // closeToolStripMenuItem
            // 
            this.closeToolStripMenuItem.Name = "closeToolStripMenuItem";
            this.closeToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F10;
            this.closeToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.closeToolStripMenuItem.Text = "Close";
            // 
            // printToolStripMenuItem
            // 
            this.printToolStripMenuItem.Name = "printToolStripMenuItem";
            this.printToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F4;
            this.printToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.printToolStripMenuItem.Text = "Print";
            // 
            // codeListsToolStripMenuItem
            // 
            this.codeListsToolStripMenuItem.Name = "codeListsToolStripMenuItem";
            this.codeListsToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F1;
            this.codeListsToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.codeListsToolStripMenuItem.Text = "Code Lists";
            // 
            // filesToolStripMenuItem
            // 
            this.filesToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.codeListsToolStripMenuItem,
            this.printToolStripMenuItem,
            this.saveToolStripMenuItem,
            this.closeToolStripMenuItem});
            this.filesToolStripMenuItem.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.filesToolStripMenuItem.Name = "filesToolStripMenuItem";
            this.filesToolStripMenuItem.Size = new System.Drawing.Size(56, 34);
            this.filesToolStripMenuItem.Text = "Files";
            // 
            // saveToolStripMenuItem
            // 
            this.saveToolStripMenuItem.Name = "saveToolStripMenuItem";
            this.saveToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F5;
            this.saveToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.saveToolStripMenuItem.Text = "Save";
            this.saveToolStripMenuItem.Click += new System.EventHandler(this.saveToolStripMenuItem_Click);
            // 
            // menuStrip1
            // 
            this.menuStrip1.BackColor = System.Drawing.Color.DodgerBlue;
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.filesToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(1904, 38);
            this.menuStrip1.TabIndex = 8;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // erptransaction
            // 
            this.erptransaction.ContainerControl = this;
            // 
            // tbExgRate
            // 
            this.tbExgRate.Location = new System.Drawing.Point(640, 141);
            this.tbExgRate.Name = "tbExgRate";
            this.tbExgRate.Size = new System.Drawing.Size(529, 37);
            this.tbExgRate.TabIndex = 11;
            this.tbExgRate.Text = "1";
            this.tbExgRate.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer1.Panel1.Controls.Add(this.btPrint);
            this.splitContainer1.Panel1.Controls.Add(this.btSave);
            this.splitContainer1.Panel1.Controls.Add(this.tbExgRate);
            this.splitContainer1.Panel1.Controls.Add(this.label1);
            this.splitContainer1.Panel1.Controls.Add(this.cbAccount);
            this.splitContainer1.Panel1.Controls.Add(this.lbAccount);
            this.splitContainer1.Panel1.Controls.Add(this.cbType);
            this.splitContainer1.Panel1.Controls.Add(this.lbPayment);
            this.splitContainer1.Panel1.Controls.Add(this.tbDocumentID);
            this.splitContainer1.Panel1.Controls.Add(this.tbAutoID);
            this.splitContainer1.Panel1.Controls.Add(this.lbDocID);
            this.splitContainer1.Panel1.Controls.Add(this.lbAuto);
            this.splitContainer1.Panel1.Controls.Add(this.lblDate);
            this.splitContainer1.Panel1.Controls.Add(this.dtpDate);
            this.splitContainer1.Panel1.Controls.Add(this.tbRemark);
            this.splitContainer1.Panel1.Controls.Add(this.lbRemark);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer2);
            this.splitContainer1.Size = new System.Drawing.Size(1904, 1041);
            this.splitContainer1.SplitterDistance = 213;
            this.splitContainer1.TabIndex = 7;
            this.splitContainer1.TabStop = false;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(505, 144);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(129, 30);
            this.label1.TabIndex = 10;
            this.label1.Text = "Exchange Rate :";
            // 
            // cbAccount
            // 
            this.cbAccount.FormattingEnabled = true;
            this.cbAccount.Location = new System.Drawing.Point(639, 96);
            this.cbAccount.Name = "cbAccount";
            this.cbAccount.Size = new System.Drawing.Size(530, 38);
            this.cbAccount.TabIndex = 9;
            this.cbAccount.Visible = false;
            // 
            // lbAccount
            // 
            this.lbAccount.AutoSize = true;
            this.lbAccount.Location = new System.Drawing.Point(549, 100);
            this.lbAccount.Name = "lbAccount";
            this.lbAccount.Size = new System.Drawing.Size(85, 30);
            this.lbAccount.TabIndex = 8;
            this.lbAccount.Text = "Account  :";
            this.lbAccount.Visible = false;
            // 
            // cbType
            // 
            this.cbType.Enabled = false;
            this.cbType.FormattingEnabled = true;
            this.cbType.Location = new System.Drawing.Point(639, 53);
            this.cbType.Name = "cbType";
            this.cbType.Size = new System.Drawing.Size(530, 38);
            this.cbType.TabIndex = 7;
            this.cbType.Visible = false;
            // 
            // lbPayment
            // 
            this.lbPayment.AutoSize = true;
            this.lbPayment.Location = new System.Drawing.Point(573, 57);
            this.lbPayment.Name = "lbPayment";
            this.lbPayment.Size = new System.Drawing.Size(61, 30);
            this.lbPayment.TabIndex = 6;
            this.lbPayment.Text = "Type  :";
            this.lbPayment.Visible = false;
            // 
            // tbDocumentID
            // 
            this.tbDocumentID.Location = new System.Drawing.Point(129, 137);
            this.tbDocumentID.Name = "tbDocumentID";
            this.tbDocumentID.Size = new System.Drawing.Size(310, 37);
            this.tbDocumentID.TabIndex = 5;
            // 
            // tbAutoID
            // 
            this.tbAutoID.BackColor = System.Drawing.Color.White;
            this.tbAutoID.Location = new System.Drawing.Point(129, 94);
            this.tbAutoID.Name = "tbAutoID";
            this.tbAutoID.ReadOnly = true;
            this.tbAutoID.Size = new System.Drawing.Size(310, 37);
            this.tbAutoID.TabIndex = 3;
            this.tbAutoID.TabStop = false;
            // 
            // lbDocID
            // 
            this.lbDocID.AutoSize = true;
            this.lbDocID.Location = new System.Drawing.Point(10, 140);
            this.lbDocID.Name = "lbDocID";
            this.lbDocID.Size = new System.Drawing.Size(114, 30);
            this.lbDocID.TabIndex = 4;
            this.lbDocID.Text = "Document ID :";
            // 
            // lbAuto
            // 
            this.lbAuto.AutoSize = true;
            this.lbAuto.Location = new System.Drawing.Point(50, 97);
            this.lbAuto.Name = "lbAuto";
            this.lbAuto.Size = new System.Drawing.Size(74, 30);
            this.lbAuto.TabIndex = 2;
            this.lbAuto.Text = "Auto ID :";
            // 
            // lblDate
            // 
            this.lblDate.AutoSize = true;
            this.lblDate.Location = new System.Drawing.Point(69, 54);
            this.lblDate.Name = "lblDate";
            this.lblDate.Size = new System.Drawing.Size(55, 30);
            this.lblDate.TabIndex = 0;
            this.lblDate.Text = "Date :";
            // 
            // dtpDate
            // 
            this.dtpDate.CustomFormat = "dd/MM/yyyy";
            this.dtpDate.Format = System.Windows.Forms.DateTimePickerFormat.Custom;
            this.dtpDate.Location = new System.Drawing.Point(129, 51);
            this.dtpDate.Name = "dtpDate";
            this.dtpDate.Size = new System.Drawing.Size(310, 37);
            this.dtpDate.TabIndex = 1;
            // 
            // tbRemark
            // 
            this.tbRemark.Location = new System.Drawing.Point(1333, 51);
            this.tbRemark.Multiline = true;
            this.tbRemark.Name = "tbRemark";
            this.tbRemark.Size = new System.Drawing.Size(559, 82);
            this.tbRemark.TabIndex = 13;
            // 
            // lbRemark
            // 
            this.lbRemark.AutoSize = true;
            this.lbRemark.Location = new System.Drawing.Point(1245, 51);
            this.lbRemark.Name = "lbRemark";
            this.lbRemark.Size = new System.Drawing.Size(82, 30);
            this.lbRemark.TabIndex = 12;
            this.lbRemark.Text = "Remark  :";
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.Location = new System.Drawing.Point(0, 0);
            this.splitContainer2.Name = "splitContainer2";
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer2.Panel1.Controls.Add(this.dgvDetail);
            this.splitContainer2.Panel1.Controls.Add(this.statusStrip1);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer2.Panel2.Controls.Add(this.tbExpAmount);
            this.splitContainer2.Panel2.Controls.Add(this.lbExpAmount);
            this.splitContainer2.Panel2.Controls.Add(this.tbInAmount);
            this.splitContainer2.Panel2.Controls.Add(this.lbInAmount);
            this.splitContainer2.Size = new System.Drawing.Size(1904, 824);
            this.splitContainer2.SplitterDistance = 1407;
            this.splitContainer2.TabIndex = 0;
            // 
            // dgvDetail
            // 
            this.dgvDetail.AllowUserToResizeColumns = false;
            this.dgvDetail.AllowUserToResizeRows = false;
            dataGridViewCellStyle1.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvDetail.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle1;
            this.dgvDetail.BackgroundColor = System.Drawing.Color.White;
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            dataGridViewCellStyle2.BackColor = System.Drawing.SystemColors.Control;
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle2.ForeColor = System.Drawing.SystemColors.WindowText;
            dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle2.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.dgvDetail.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle2;
            this.dgvDetail.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvDetail.GridColor = System.Drawing.Color.Black;
            this.dgvDetail.Location = new System.Drawing.Point(0, 0);
            this.dgvDetail.Name = "dgvDetail";
            this.dgvDetail.RowHeadersWidth = 20;
            this.dgvDetail.RowTemplate.Height = 35;
            this.dgvDetail.Size = new System.Drawing.Size(1404, 811);
            this.dgvDetail.TabIndex = 0;
            this.dgvDetail.CellEndEdit += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_CellEndEdit);
            this.dgvDetail.CellEnter += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_CellEnter);
            this.dgvDetail.EditingControlShowing += new System.Windows.Forms.DataGridViewEditingControlShowingEventHandler(this.dgvDetail_EditingControlShowing);
            this.dgvDetail.RowValidated += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_RowValidated);
            this.dgvDetail.UserAddedRow += new System.Windows.Forms.DataGridViewRowEventHandler(this.dgvDetail_UserAddedRow);
            this.dgvDetail.UserDeletedRow += new System.Windows.Forms.DataGridViewRowEventHandler(this.dgvDetail_UserDeletedRow);
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel1,
            this.toolStripStatusLabel4,
            this.toolStripStatusLabel6,
            this.toolStripStatusLabel7,
            this.toolStripStatusLabel8});
            this.statusStrip1.Location = new System.Drawing.Point(0, 789);
            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Size = new System.Drawing.Size(1407, 35);
            this.statusStrip1.TabIndex = 1;
            this.statusStrip1.Text = "statusStrip1";
            // 
            // toolStripStatusLabel1
            // 
            this.toolStripStatusLabel1.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel1.Name = "toolStripStatusLabel1";
            this.toolStripStatusLabel1.Size = new System.Drawing.Size(124, 30);
            this.toolStripStatusLabel1.Text = " Code List : F1  ";
            // 
            // toolStripStatusLabel4
            // 
            this.toolStripStatusLabel4.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel4.Name = "toolStripStatusLabel4";
            this.toolStripStatusLabel4.Size = new System.Drawing.Size(93, 30);
            this.toolStripStatusLabel4.Text = " Print : F4  ";
            // 
            // toolStripStatusLabel6
            // 
            this.toolStripStatusLabel6.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel6.Name = "toolStripStatusLabel6";
            this.toolStripStatusLabel6.Size = new System.Drawing.Size(92, 30);
            this.toolStripStatusLabel6.Text = " Save : F5  ";
            // 
            // toolStripStatusLabel7
            // 
            this.toolStripStatusLabel7.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel7.Name = "toolStripStatusLabel7";
            this.toolStripStatusLabel7.Size = new System.Drawing.Size(104, 30);
            this.toolStripStatusLabel7.Text = " Close : F10  ";
            // 
            // toolStripStatusLabel8
            // 
            this.toolStripStatusLabel8.AutoSize = false;
            this.toolStripStatusLabel8.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel8.Name = "toolStripStatusLabel8";
            this.toolStripStatusLabel8.Size = new System.Drawing.Size(980, 30);
            this.toolStripStatusLabel8.Text = "                                                                                 " +
    "                                     ";
            // 
            // tbExpAmount
            // 
            this.tbExpAmount.BackColor = System.Drawing.Color.White;
            this.tbExpAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbExpAmount.Location = new System.Drawing.Point(191, 91);
            this.tbExpAmount.Name = "tbExpAmount";
            this.tbExpAmount.ReadOnly = true;
            this.tbExpAmount.Size = new System.Drawing.Size(288, 44);
            this.tbExpAmount.TabIndex = 3;
            this.tbExpAmount.TabStop = false;
            this.tbExpAmount.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // lbExpAmount
            // 
            this.lbExpAmount.AutoSize = true;
            this.lbExpAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbExpAmount.Location = new System.Drawing.Point(18, 95);
            this.lbExpAmount.Name = "lbExpAmount";
            this.lbExpAmount.Size = new System.Drawing.Size(153, 36);
            this.lbExpAmount.TabIndex = 2;
            this.lbExpAmount.Text = "Credit Amount :";
            // 
            // tbInAmount
            // 
            this.tbInAmount.BackColor = System.Drawing.Color.White;
            this.tbInAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbInAmount.Location = new System.Drawing.Point(191, 30);
            this.tbInAmount.Name = "tbInAmount";
            this.tbInAmount.ReadOnly = true;
            this.tbInAmount.Size = new System.Drawing.Size(288, 44);
            this.tbInAmount.TabIndex = 1;
            this.tbInAmount.TabStop = false;
            this.tbInAmount.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // lbInAmount
            // 
            this.lbInAmount.AutoSize = true;
            this.lbInAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbInAmount.Location = new System.Drawing.Point(18, 34);
            this.lbInAmount.Name = "lbInAmount";
            this.lbInAmount.Size = new System.Drawing.Size(147, 36);
            this.lbInAmount.TabIndex = 0;
            this.lbInAmount.Text = "Debit Amount :";
            // 
            // btPrint
            // 
            this.btPrint.Location = new System.Drawing.Point(1515, 144);
            this.btPrint.Name = "btPrint";
            this.btPrint.Size = new System.Drawing.Size(152, 56);
            this.btPrint.TabIndex = 34;
            this.btPrint.Text = "Print [ F4 ]";
            this.btPrint.UseVisualStyleBackColor = true;
            // 
            // btSave
            // 
            this.btSave.Location = new System.Drawing.Point(1335, 144);
            this.btSave.Name = "btSave";
            this.btSave.Size = new System.Drawing.Size(152, 56);
            this.btSave.TabIndex = 33;
            this.btSave.Text = "Save [ F5 ]";
            this.btSave.UseVisualStyleBackColor = true;
            this.btSave.Click += new System.EventHandler(this.btSave_Click);
            // 
            // frm_AcctOpening
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(1904, 1041);
            this.Controls.Add(this.menuStrip1);
            this.Controls.Add(this.splitContainer1);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.Name = "frm_AcctOpening";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Account Opening Entry";
            this.Load += new System.EventHandler(this.frm_AcctOpening_Load);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.erptransaction)).EndInit();
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel1.PerformLayout();
            this.splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel1.PerformLayout();
            this.splitContainer2.Panel2.ResumeLayout(false);
            this.splitContainer2.Panel2.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.dgvDetail)).EndInit();
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.ToolStripMenuItem closeToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem printToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem codeListsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem filesToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveToolStripMenuItem;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ErrorProvider erptransaction;
        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.TextBox tbExgRate;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox cbAccount;
        private System.Windows.Forms.Label lbAccount;
        private System.Windows.Forms.ComboBox cbType;
        private System.Windows.Forms.Label lbPayment;
        private System.Windows.Forms.TextBox tbDocumentID;
        private System.Windows.Forms.TextBox tbAutoID;
        private System.Windows.Forms.Label lbDocID;
        private System.Windows.Forms.Label lbAuto;
        private System.Windows.Forms.Label lblDate;
        private System.Windows.Forms.DateTimePicker dtpDate;
        private System.Windows.Forms.TextBox tbRemark;
        private System.Windows.Forms.Label lbRemark;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.DataGridView dgvDetail;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel4;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel6;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel7;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel8;
        private System.Windows.Forms.TextBox tbExpAmount;
        private System.Windows.Forms.Label lbExpAmount;
        private System.Windows.Forms.TextBox tbInAmount;
        private System.Windows.Forms.Label lbInAmount;
        private System.Windows.Forms.Button btPrint;
        private System.Windows.Forms.Button btSave;
    }
}