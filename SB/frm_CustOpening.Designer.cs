
namespace SB
{
    partial class frm_CustOpening
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
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle4 = new System.Windows.Forms.DataGridViewCellStyle();
            this.tbRemark = new System.Windows.Forms.TextBox();
            this.menuStrip1 = new System.Windows.Forms.MenuStrip();
            this.filesToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.codeListsToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.discountToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.paidToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.printToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.saveToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.deleteToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.closeToolStripMenuItem = new System.Windows.Forms.ToolStripMenuItem();
            this.tbAutoID = new System.Windows.Forms.TextBox();
            this.lbDocID = new System.Windows.Forms.Label();
            this.tbAmount = new System.Windows.Forms.TextBox();
            this.lbAmount = new System.Windows.Forms.Label();
            this.tbDocumentID = new System.Windows.Forms.TextBox();
            this.lbAuto = new System.Windows.Forms.Label();
            this.dgvDetail = new System.Windows.Forms.DataGridView();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.btPrint = new System.Windows.Forms.Button();
            this.btSave = new System.Windows.Forms.Button();
            this.tbExgRate = new System.Windows.Forms.TextBox();
            this.lbExgRate = new System.Windows.Forms.Label();
            this.btFill = new System.Windows.Forms.Button();
            this.tbCode = new System.Windows.Forms.TextBox();
            this.lbCode = new System.Windows.Forms.Label();
            this.cbCurrency = new System.Windows.Forms.ComboBox();
            this.lbLocation = new System.Windows.Forms.Label();
            this.lbRemark = new System.Windows.Forms.Label();
            this.lblDate = new System.Windows.Forms.Label();
            this.dtpDate = new System.Windows.Forms.DateTimePicker();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.statusStrip1 = new System.Windows.Forms.StatusStrip();
            this.toolStripStatusLabel1 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel2 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel3 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel4 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel6 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel5 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel7 = new System.Windows.Forms.ToolStripStatusLabel();
            this.toolStripStatusLabel8 = new System.Windows.Forms.ToolStripStatusLabel();
            this.erptransaction = new System.Windows.Forms.ErrorProvider(this.components);
            this.btBalance = new System.Windows.Forms.Button();
            this.gbOpening = new System.Windows.Forms.GroupBox();
            this.rbAdvance = new System.Windows.Forms.RadioButton();
            this.rbOpening = new System.Windows.Forms.RadioButton();
            this.menuStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvDetail)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            this.statusStrip1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.erptransaction)).BeginInit();
            this.gbOpening.SuspendLayout();
            this.SuspendLayout();
            // 
            // tbRemark
            // 
            this.tbRemark.Location = new System.Drawing.Point(127, 142);
            this.tbRemark.Multiline = true;
            this.tbRemark.Name = "tbRemark";
            this.tbRemark.Size = new System.Drawing.Size(394, 82);
            this.tbRemark.TabIndex = 29;
            // 
            // menuStrip1
            // 
            this.menuStrip1.BackColor = System.Drawing.Color.DodgerBlue;
            this.menuStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.filesToolStripMenuItem});
            this.menuStrip1.Location = new System.Drawing.Point(0, 0);
            this.menuStrip1.Name = "menuStrip1";
            this.menuStrip1.Size = new System.Drawing.Size(1904, 38);
            this.menuStrip1.TabIndex = 4;
            this.menuStrip1.Text = "menuStrip1";
            // 
            // filesToolStripMenuItem
            // 
            this.filesToolStripMenuItem.DropDownItems.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.codeListsToolStripMenuItem,
            this.discountToolStripMenuItem,
            this.paidToolStripMenuItem,
            this.printToolStripMenuItem,
            this.saveToolStripMenuItem,
            this.deleteToolStripMenuItem,
            this.closeToolStripMenuItem});
            this.filesToolStripMenuItem.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.filesToolStripMenuItem.Name = "filesToolStripMenuItem";
            this.filesToolStripMenuItem.Size = new System.Drawing.Size(56, 34);
            this.filesToolStripMenuItem.Text = "Files";
            // 
            // codeListsToolStripMenuItem
            // 
            this.codeListsToolStripMenuItem.Name = "codeListsToolStripMenuItem";
            this.codeListsToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F1;
            this.codeListsToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.codeListsToolStripMenuItem.Text = "Code Lists";
            // 
            // discountToolStripMenuItem
            // 
            this.discountToolStripMenuItem.Name = "discountToolStripMenuItem";
            this.discountToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F2;
            this.discountToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.discountToolStripMenuItem.Text = "Discount";
            // 
            // paidToolStripMenuItem
            // 
            this.paidToolStripMenuItem.Name = "paidToolStripMenuItem";
            this.paidToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F3;
            this.paidToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.paidToolStripMenuItem.Text = "Paid";
            this.paidToolStripMenuItem.Click += new System.EventHandler(this.paidToolStripMenuItem_Click);
            // 
            // printToolStripMenuItem
            // 
            this.printToolStripMenuItem.Name = "printToolStripMenuItem";
            this.printToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F4;
            this.printToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.printToolStripMenuItem.Text = "Print";
            // 
            // saveToolStripMenuItem
            // 
            this.saveToolStripMenuItem.Name = "saveToolStripMenuItem";
            this.saveToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F5;
            this.saveToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.saveToolStripMenuItem.Text = "Save";
            this.saveToolStripMenuItem.Click += new System.EventHandler(this.saveToolStripMenuItem_Click_1);
            // 
            // deleteToolStripMenuItem
            // 
            this.deleteToolStripMenuItem.Name = "deleteToolStripMenuItem";
            this.deleteToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F8;
            this.deleteToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.deleteToolStripMenuItem.Text = "Delete";
            // 
            // closeToolStripMenuItem
            // 
            this.closeToolStripMenuItem.Name = "closeToolStripMenuItem";
            this.closeToolStripMenuItem.ShortcutKeys = System.Windows.Forms.Keys.F10;
            this.closeToolStripMenuItem.Size = new System.Drawing.Size(188, 34);
            this.closeToolStripMenuItem.Text = "Close";
            // 
            // tbAutoID
            // 
            this.tbAutoID.BackColor = System.Drawing.Color.White;
            this.tbAutoID.Location = new System.Drawing.Point(127, 56);
            this.tbAutoID.Name = "tbAutoID";
            this.tbAutoID.ReadOnly = true;
            this.tbAutoID.Size = new System.Drawing.Size(256, 37);
            this.tbAutoID.TabIndex = 3;
            this.tbAutoID.TabStop = false;
            // 
            // lbDocID
            // 
            this.lbDocID.AutoSize = true;
            this.lbDocID.Location = new System.Drawing.Point(8, 102);
            this.lbDocID.Name = "lbDocID";
            this.lbDocID.Size = new System.Drawing.Size(114, 30);
            this.lbDocID.TabIndex = 4;
            this.lbDocID.Text = "Document ID :";
            // 
            // tbAmount
            // 
            this.tbAmount.BackColor = System.Drawing.Color.White;
            this.tbAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbAmount.Location = new System.Drawing.Point(151, 30);
            this.tbAmount.Name = "tbAmount";
            this.tbAmount.ReadOnly = true;
            this.tbAmount.Size = new System.Drawing.Size(311, 44);
            this.tbAmount.TabIndex = 9;
            this.tbAmount.TabStop = false;
            this.tbAmount.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            // 
            // lbAmount
            // 
            this.lbAmount.AutoSize = true;
            this.lbAmount.Font = new System.Drawing.Font("Pyidaungsu", 15.75F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.lbAmount.Location = new System.Drawing.Point(51, 34);
            this.lbAmount.Name = "lbAmount";
            this.lbAmount.Size = new System.Drawing.Size(94, 36);
            this.lbAmount.TabIndex = 8;
            this.lbAmount.Text = "Amount :";
            // 
            // tbDocumentID
            // 
            this.tbDocumentID.Location = new System.Drawing.Point(127, 99);
            this.tbDocumentID.Name = "tbDocumentID";
            this.tbDocumentID.Size = new System.Drawing.Size(256, 37);
            this.tbDocumentID.TabIndex = 5;
            // 
            // lbAuto
            // 
            this.lbAuto.AutoSize = true;
            this.lbAuto.Location = new System.Drawing.Point(48, 59);
            this.lbAuto.Name = "lbAuto";
            this.lbAuto.Size = new System.Drawing.Size(74, 30);
            this.lbAuto.TabIndex = 2;
            this.lbAuto.Text = "Auto ID :";
            // 
            // dgvDetail
            // 
            dataGridViewCellStyle3.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvDetail.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle3;
            this.dgvDetail.BackgroundColor = System.Drawing.Color.White;
            dataGridViewCellStyle4.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            dataGridViewCellStyle4.BackColor = System.Drawing.SystemColors.Control;
            dataGridViewCellStyle4.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle4.ForeColor = System.Drawing.SystemColors.WindowText;
            dataGridViewCellStyle4.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle4.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle4.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.dgvDetail.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle4;
            this.dgvDetail.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.dgvDetail.GridColor = System.Drawing.Color.Black;
            this.dgvDetail.Location = new System.Drawing.Point(0, 0);
            this.dgvDetail.Name = "dgvDetail";
            this.dgvDetail.RowHeadersWidth = 20;
            this.dgvDetail.RowTemplate.Height = 35;
            this.dgvDetail.Size = new System.Drawing.Size(1404, 717);
            this.dgvDetail.TabIndex = 0;
            this.dgvDetail.CellEndEdit += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_CellEndEdit);
            this.dgvDetail.CellEnter += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_CellEnter);
            this.dgvDetail.EditingControlShowing += new System.Windows.Forms.DataGridViewEditingControlShowingEventHandler(this.dgvDetail_EditingControlShowing);
            this.dgvDetail.RowValidated += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvDetail_RowValidated);
            this.dgvDetail.UserAddedRow += new System.Windows.Forms.DataGridViewRowEventHandler(this.dgvDetail_UserAddedRow);
            this.dgvDetail.UserDeletedRow += new System.Windows.Forms.DataGridViewRowEventHandler(this.dgvDetail_UserDeletedRow);
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.Location = new System.Drawing.Point(0, 38);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer1.Panel1.Controls.Add(this.btBalance);
            this.splitContainer1.Panel1.Controls.Add(this.gbOpening);
            this.splitContainer1.Panel1.Controls.Add(this.btPrint);
            this.splitContainer1.Panel1.Controls.Add(this.btSave);
            this.splitContainer1.Panel1.Controls.Add(this.tbExgRate);
            this.splitContainer1.Panel1.Controls.Add(this.lbExgRate);
            this.splitContainer1.Panel1.Controls.Add(this.btFill);
            this.splitContainer1.Panel1.Controls.Add(this.tbCode);
            this.splitContainer1.Panel1.Controls.Add(this.lbCode);
            this.splitContainer1.Panel1.Controls.Add(this.cbCurrency);
            this.splitContainer1.Panel1.Controls.Add(this.lbLocation);
            this.splitContainer1.Panel1.Controls.Add(this.tbRemark);
            this.splitContainer1.Panel1.Controls.Add(this.lbRemark);
            this.splitContainer1.Panel1.Controls.Add(this.tbDocumentID);
            this.splitContainer1.Panel1.Controls.Add(this.tbAutoID);
            this.splitContainer1.Panel1.Controls.Add(this.lbDocID);
            this.splitContainer1.Panel1.Controls.Add(this.lbAuto);
            this.splitContainer1.Panel1.Controls.Add(this.lblDate);
            this.splitContainer1.Panel1.Controls.Add(this.dtpDate);
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer2);
            this.splitContainer1.Size = new System.Drawing.Size(1904, 1003);
            this.splitContainer1.SplitterDistance = 244;
            this.splitContainer1.TabIndex = 3;
            this.splitContainer1.TabStop = false;
            // 
            // btPrint
            // 
            this.btPrint.Location = new System.Drawing.Point(1623, 168);
            this.btPrint.Name = "btPrint";
            this.btPrint.Size = new System.Drawing.Size(152, 56);
            this.btPrint.TabIndex = 38;
            this.btPrint.Text = "Print [ F4 ]";
            this.btPrint.UseVisualStyleBackColor = true;
            // 
            // btSave
            // 
            this.btSave.Location = new System.Drawing.Point(1443, 168);
            this.btSave.Name = "btSave";
            this.btSave.Size = new System.Drawing.Size(152, 56);
            this.btSave.TabIndex = 37;
            this.btSave.Text = "Save [ F5 ]";
            this.btSave.UseVisualStyleBackColor = true;
            this.btSave.Click += new System.EventHandler(this.btSave_Click);
            // 
            // tbExgRate
            // 
            this.tbExgRate.Location = new System.Drawing.Point(680, 60);
            this.tbExgRate.Name = "tbExgRate";
            this.tbExgRate.Size = new System.Drawing.Size(256, 37);
            this.tbExgRate.TabIndex = 36;
            this.tbExgRate.Text = "1";
            this.tbExgRate.TextAlign = System.Windows.Forms.HorizontalAlignment.Right;
            this.tbExgRate.Visible = false;
            // 
            // lbExgRate
            // 
            this.lbExgRate.AutoSize = true;
            this.lbExgRate.Location = new System.Drawing.Point(583, 66);
            this.lbExgRate.Name = "lbExgRate";
            this.lbExgRate.Size = new System.Drawing.Size(91, 30);
            this.lbExgRate.TabIndex = 35;
            this.lbExgRate.Text = "Exg Rate  :";
            this.lbExgRate.Visible = false;
            // 
            // btFill
            // 
            this.btFill.Location = new System.Drawing.Point(959, 135);
            this.btFill.Name = "btFill";
            this.btFill.Size = new System.Drawing.Size(127, 35);
            this.btFill.TabIndex = 34;
            this.btFill.Text = "Fill";
            this.btFill.UseVisualStyleBackColor = true;
            this.btFill.Visible = false;
            this.btFill.Click += new System.EventHandler(this.btFill_Click);
            // 
            // tbCode
            // 
            this.tbCode.Location = new System.Drawing.Point(680, 135);
            this.tbCode.Name = "tbCode";
            this.tbCode.Size = new System.Drawing.Size(256, 37);
            this.tbCode.TabIndex = 33;
            this.tbCode.Visible = false;
            // 
            // lbCode
            // 
            this.lbCode.AutoSize = true;
            this.lbCode.Location = new System.Drawing.Point(616, 141);
            this.lbCode.Name = "lbCode";
            this.lbCode.Size = new System.Drawing.Size(58, 30);
            this.lbCode.TabIndex = 32;
            this.lbCode.Text = "Code :";
            this.lbCode.Visible = false;
            // 
            // cbCurrency
            // 
            this.cbCurrency.FormattingEnabled = true;
            this.cbCurrency.Location = new System.Drawing.Point(680, 16);
            this.cbCurrency.Name = "cbCurrency";
            this.cbCurrency.Size = new System.Drawing.Size(256, 38);
            this.cbCurrency.TabIndex = 31;
            this.cbCurrency.Visible = false;
            this.cbCurrency.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbLocation_KeyPress);
            // 
            // lbLocation
            // 
            this.lbLocation.AutoSize = true;
            this.lbLocation.Location = new System.Drawing.Point(583, 20);
            this.lbLocation.Name = "lbLocation";
            this.lbLocation.Size = new System.Drawing.Size(91, 30);
            this.lbLocation.TabIndex = 30;
            this.lbLocation.Text = "Currency  :";
            this.lbLocation.Visible = false;
            // 
            // lbRemark
            // 
            this.lbRemark.AutoSize = true;
            this.lbRemark.Location = new System.Drawing.Point(39, 142);
            this.lbRemark.Name = "lbRemark";
            this.lbRemark.Size = new System.Drawing.Size(82, 30);
            this.lbRemark.TabIndex = 28;
            this.lbRemark.Text = "Remark  :";
            // 
            // lblDate
            // 
            this.lblDate.AutoSize = true;
            this.lblDate.Location = new System.Drawing.Point(67, 16);
            this.lblDate.Name = "lblDate";
            this.lblDate.Size = new System.Drawing.Size(55, 30);
            this.lblDate.TabIndex = 0;
            this.lblDate.Text = "Date :";
            // 
            // dtpDate
            // 
            this.dtpDate.CustomFormat = "dd/MM/yyyy";
            this.dtpDate.Format = System.Windows.Forms.DateTimePickerFormat.Custom;
            this.dtpDate.Location = new System.Drawing.Point(127, 13);
            this.dtpDate.Name = "dtpDate";
            this.dtpDate.Size = new System.Drawing.Size(256, 37);
            this.dtpDate.TabIndex = 1;
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
            this.splitContainer2.Panel1.Controls.Add(this.statusStrip1);
            this.splitContainer2.Panel1.Controls.Add(this.dgvDetail);
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.splitContainer2.Panel2.Controls.Add(this.tbAmount);
            this.splitContainer2.Panel2.Controls.Add(this.lbAmount);
            this.splitContainer2.Size = new System.Drawing.Size(1904, 755);
            this.splitContainer2.SplitterDistance = 1407;
            this.splitContainer2.TabIndex = 0;
            // 
            // statusStrip1
            // 
            this.statusStrip1.Items.AddRange(new System.Windows.Forms.ToolStripItem[] {
            this.toolStripStatusLabel1,
            this.toolStripStatusLabel2,
            this.toolStripStatusLabel3,
            this.toolStripStatusLabel4,
            this.toolStripStatusLabel6,
            this.toolStripStatusLabel5,
            this.toolStripStatusLabel7,
            this.toolStripStatusLabel8});
            this.statusStrip1.Location = new System.Drawing.Point(0, 720);
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
            // toolStripStatusLabel2
            // 
            this.toolStripStatusLabel2.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel2.Name = "toolStripStatusLabel2";
            this.toolStripStatusLabel2.Size = new System.Drawing.Size(120, 30);
            this.toolStripStatusLabel2.Text = " Discount : F2  ";
            // 
            // toolStripStatusLabel3
            // 
            this.toolStripStatusLabel3.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel3.Name = "toolStripStatusLabel3";
            this.toolStripStatusLabel3.Size = new System.Drawing.Size(155, 30);
            this.toolStripStatusLabel3.Text = " Advance Paid : F3  ";
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
            // toolStripStatusLabel5
            // 
            this.toolStripStatusLabel5.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel5.Name = "toolStripStatusLabel5";
            this.toolStripStatusLabel5.Size = new System.Drawing.Size(102, 30);
            this.toolStripStatusLabel5.Text = " Delete : F8  ";
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
            this.toolStripStatusLabel8.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.toolStripStatusLabel8.Name = "toolStripStatusLabel8";
            this.toolStripStatusLabel8.Size = new System.Drawing.Size(603, 30);
            this.toolStripStatusLabel8.Text = "                                                                                 " +
    "                                     ";
            // 
            // erptransaction
            // 
            this.erptransaction.ContainerControl = this;
            // 
            // btBalance
            // 
            this.btBalance.Location = new System.Drawing.Point(957, 189);
            this.btBalance.Name = "btBalance";
            this.btBalance.Size = new System.Drawing.Size(179, 35);
            this.btBalance.TabIndex = 40;
            this.btBalance.Text = "Get Current  Balance";
            this.btBalance.UseVisualStyleBackColor = true;
            this.btBalance.Visible = false;
            this.btBalance.Click += new System.EventHandler(this.btBalance_Click);
            // 
            // gbOpening
            // 
            this.gbOpening.Controls.Add(this.rbAdvance);
            this.gbOpening.Controls.Add(this.rbOpening);
            this.gbOpening.Location = new System.Drawing.Point(1196, 16);
            this.gbOpening.Name = "gbOpening";
            this.gbOpening.Size = new System.Drawing.Size(324, 85);
            this.gbOpening.TabIndex = 39;
            this.gbOpening.TabStop = false;
            this.gbOpening.Text = "Opening/ Advance";
            this.gbOpening.Visible = false;
            // 
            // rbAdvance
            // 
            this.rbAdvance.AutoSize = true;
            this.rbAdvance.Location = new System.Drawing.Point(172, 36);
            this.rbAdvance.Name = "rbAdvance";
            this.rbAdvance.Size = new System.Drawing.Size(91, 34);
            this.rbAdvance.TabIndex = 1;
            this.rbAdvance.Text = "Advance";
            this.rbAdvance.UseVisualStyleBackColor = true;
            // 
            // rbOpening
            // 
            this.rbOpening.AutoSize = true;
            this.rbOpening.Checked = true;
            this.rbOpening.Location = new System.Drawing.Point(42, 37);
            this.rbOpening.Name = "rbOpening";
            this.rbOpening.Size = new System.Drawing.Size(90, 34);
            this.rbOpening.TabIndex = 0;
            this.rbOpening.TabStop = true;
            this.rbOpening.Text = "Opening";
            this.rbOpening.UseVisualStyleBackColor = true;
            // 
            // frm_CustOpening
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.ClientSize = new System.Drawing.Size(1904, 1041);
            this.Controls.Add(this.splitContainer1);
            this.Controls.Add(this.menuStrip1);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frm_CustOpening";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Customer Opeing";
            this.Load += new System.EventHandler(this.frm_CustOpening_Load);
            this.menuStrip1.ResumeLayout(false);
            this.menuStrip1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dgvDetail)).EndInit();
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
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.erptransaction)).EndInit();
            this.gbOpening.ResumeLayout(false);
            this.gbOpening.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox tbRemark;
        private System.Windows.Forms.MenuStrip menuStrip1;
        private System.Windows.Forms.ToolStripMenuItem filesToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem codeListsToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem discountToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem paidToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem printToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem saveToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem deleteToolStripMenuItem;
        private System.Windows.Forms.ToolStripMenuItem closeToolStripMenuItem;
        private System.Windows.Forms.TextBox tbAutoID;
        private System.Windows.Forms.Label lbDocID;
        private System.Windows.Forms.TextBox tbAmount;
        private System.Windows.Forms.Label lbAmount;
        private System.Windows.Forms.TextBox tbDocumentID;
        private System.Windows.Forms.Label lbAuto;
        private System.Windows.Forms.DataGridView dgvDetail;
        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.Label lbRemark;
        private System.Windows.Forms.Label lblDate;
        private System.Windows.Forms.DateTimePicker dtpDate;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.StatusStrip statusStrip1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel1;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel2;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel3;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel4;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel6;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel5;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel7;
        private System.Windows.Forms.ToolStripStatusLabel toolStripStatusLabel8;
        private System.Windows.Forms.ErrorProvider erptransaction;
        private System.Windows.Forms.ComboBox cbCurrency;
        private System.Windows.Forms.Label lbLocation;
        private System.Windows.Forms.Button btFill;
        private System.Windows.Forms.TextBox tbCode;
        private System.Windows.Forms.Label lbCode;
        private System.Windows.Forms.TextBox tbExgRate;
        private System.Windows.Forms.Label lbExgRate;
        private System.Windows.Forms.Button btPrint;
        private System.Windows.Forms.Button btSave;
        private System.Windows.Forms.Button btBalance;
        private System.Windows.Forms.GroupBox gbOpening;
        private System.Windows.Forms.RadioButton rbAdvance;
        private System.Windows.Forms.RadioButton rbOpening;
    }
}