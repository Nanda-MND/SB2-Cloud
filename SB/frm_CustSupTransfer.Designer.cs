
namespace SB
{
    partial class frm_CustSupTransfer
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
            this.tbDocumentID = new System.Windows.Forms.TextBox();
            this.tbAutoID = new System.Windows.Forms.TextBox();
            this.lbDocID = new System.Windows.Forms.Label();
            this.lbAuto = new System.Windows.Forms.Label();
            this.lblDate = new System.Windows.Forms.Label();
            this.dtpDate = new System.Windows.Forms.DateTimePicker();
            this.gbFrom = new System.Windows.Forms.GroupBox();
            this.cbFromName = new System.Windows.Forms.ComboBox();
            this.lbFromName = new System.Windows.Forms.Label();
            this.cbFromAcct = new System.Windows.Forms.ComboBox();
            this.lbFromAcct = new System.Windows.Forms.Label();
            this.gbToAcct = new System.Windows.Forms.GroupBox();
            this.cbToName = new System.Windows.Forms.ComboBox();
            this.label1 = new System.Windows.Forms.Label();
            this.cbToAcct = new System.Windows.Forms.ComboBox();
            this.label2 = new System.Windows.Forms.Label();
            this.tbAmount = new System.Windows.Forms.TextBox();
            this.label3 = new System.Windows.Forms.Label();
            this.tbRemark = new System.Windows.Forms.TextBox();
            this.label4 = new System.Windows.Forms.Label();
            this.btSave = new System.Windows.Forms.Button();
            this.btClose = new System.Windows.Forms.Button();
            this.gbFrom.SuspendLayout();
            this.gbToAcct.SuspendLayout();
            this.SuspendLayout();
            // 
            // tbDocumentID
            // 
            this.tbDocumentID.Location = new System.Drawing.Point(186, 110);
            this.tbDocumentID.Name = "tbDocumentID";
            this.tbDocumentID.Size = new System.Drawing.Size(310, 37);
            this.tbDocumentID.TabIndex = 5;
            // 
            // tbAutoID
            // 
            this.tbAutoID.BackColor = System.Drawing.Color.White;
            this.tbAutoID.Location = new System.Drawing.Point(186, 67);
            this.tbAutoID.Name = "tbAutoID";
            this.tbAutoID.ReadOnly = true;
            this.tbAutoID.Size = new System.Drawing.Size(310, 37);
            this.tbAutoID.TabIndex = 3;
            this.tbAutoID.TabStop = false;
            // 
            // lbDocID
            // 
            this.lbDocID.AutoSize = true;
            this.lbDocID.Location = new System.Drawing.Point(67, 113);
            this.lbDocID.Name = "lbDocID";
            this.lbDocID.Size = new System.Drawing.Size(114, 30);
            this.lbDocID.TabIndex = 4;
            this.lbDocID.Text = "Document ID :";
            // 
            // lbAuto
            // 
            this.lbAuto.AutoSize = true;
            this.lbAuto.Location = new System.Drawing.Point(107, 70);
            this.lbAuto.Name = "lbAuto";
            this.lbAuto.Size = new System.Drawing.Size(74, 30);
            this.lbAuto.TabIndex = 2;
            this.lbAuto.Text = "Auto ID :";
            // 
            // lblDate
            // 
            this.lblDate.AutoSize = true;
            this.lblDate.Location = new System.Drawing.Point(126, 27);
            this.lblDate.Name = "lblDate";
            this.lblDate.Size = new System.Drawing.Size(55, 30);
            this.lblDate.TabIndex = 0;
            this.lblDate.Text = "Date :";
            // 
            // dtpDate
            // 
            this.dtpDate.CustomFormat = "dd/MM/yyyy";
            this.dtpDate.Format = System.Windows.Forms.DateTimePickerFormat.Custom;
            this.dtpDate.Location = new System.Drawing.Point(186, 24);
            this.dtpDate.Name = "dtpDate";
            this.dtpDate.Size = new System.Drawing.Size(310, 37);
            this.dtpDate.TabIndex = 1;
            // 
            // gbFrom
            // 
            this.gbFrom.Controls.Add(this.cbFromName);
            this.gbFrom.Controls.Add(this.lbFromName);
            this.gbFrom.Controls.Add(this.cbFromAcct);
            this.gbFrom.Controls.Add(this.lbFromAcct);
            this.gbFrom.Location = new System.Drawing.Point(24, 162);
            this.gbFrom.Name = "gbFrom";
            this.gbFrom.Size = new System.Drawing.Size(566, 138);
            this.gbFrom.TabIndex = 6;
            this.gbFrom.TabStop = false;
            this.gbFrom.Text = "From Account";
            // 
            // cbFromName
            // 
            this.cbFromName.FormattingEnabled = true;
            this.cbFromName.Location = new System.Drawing.Point(162, 80);
            this.cbFromName.Name = "cbFromName";
            this.cbFromName.Size = new System.Drawing.Size(374, 38);
            this.cbFromName.TabIndex = 3;
            this.cbFromName.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbFromName_KeyPress);
            // 
            // lbFromName
            // 
            this.lbFromName.AutoSize = true;
            this.lbFromName.Location = new System.Drawing.Point(92, 83);
            this.lbFromName.Name = "lbFromName";
            this.lbFromName.Size = new System.Drawing.Size(64, 30);
            this.lbFromName.TabIndex = 2;
            this.lbFromName.Text = "Name :";
            // 
            // cbFromAcct
            // 
            this.cbFromAcct.FormattingEnabled = true;
            this.cbFromAcct.Location = new System.Drawing.Point(162, 37);
            this.cbFromAcct.Name = "cbFromAcct";
            this.cbFromAcct.Size = new System.Drawing.Size(374, 38);
            this.cbFromAcct.TabIndex = 1;
            this.cbFromAcct.SelectionChangeCommitted += new System.EventHandler(this.cbFromAcct_DropDownClosed);
            this.cbFromAcct.DropDownClosed += new System.EventHandler(this.cbFromAcct_DropDownClosed);
            this.cbFromAcct.SelectedValueChanged += new System.EventHandler(this.cbFromAcct_DropDownClosed);
            this.cbFromAcct.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbFromAcct_KeyPress);
            // 
            // lbFromAcct
            // 
            this.lbFromAcct.AutoSize = true;
            this.lbFromAcct.Location = new System.Drawing.Point(29, 40);
            this.lbFromAcct.Name = "lbFromAcct";
            this.lbFromAcct.Size = new System.Drawing.Size(127, 30);
            this.lbFromAcct.TabIndex = 0;
            this.lbFromAcct.Text = "From Account  :";
            // 
            // gbToAcct
            // 
            this.gbToAcct.Controls.Add(this.cbToName);
            this.gbToAcct.Controls.Add(this.label1);
            this.gbToAcct.Controls.Add(this.cbToAcct);
            this.gbToAcct.Controls.Add(this.label2);
            this.gbToAcct.Location = new System.Drawing.Point(24, 314);
            this.gbToAcct.Name = "gbToAcct";
            this.gbToAcct.Size = new System.Drawing.Size(566, 143);
            this.gbToAcct.TabIndex = 7;
            this.gbToAcct.TabStop = false;
            this.gbToAcct.Text = "To Account";
            // 
            // cbToName
            // 
            this.cbToName.FormattingEnabled = true;
            this.cbToName.Location = new System.Drawing.Point(162, 80);
            this.cbToName.Name = "cbToName";
            this.cbToName.Size = new System.Drawing.Size(374, 38);
            this.cbToName.TabIndex = 3;
            this.cbToName.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbToName_KeyPress);
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(92, 83);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(64, 30);
            this.label1.TabIndex = 2;
            this.label1.Text = "Name :";
            // 
            // cbToAcct
            // 
            this.cbToAcct.FormattingEnabled = true;
            this.cbToAcct.Location = new System.Drawing.Point(162, 37);
            this.cbToAcct.Name = "cbToAcct";
            this.cbToAcct.Size = new System.Drawing.Size(374, 38);
            this.cbToAcct.TabIndex = 1;
            this.cbToAcct.SelectionChangeCommitted += new System.EventHandler(this.cbToAcct_DropDownClosed);
            this.cbToAcct.DropDownClosed += new System.EventHandler(this.cbToAcct_DropDownClosed);
            this.cbToAcct.SelectedValueChanged += new System.EventHandler(this.cbToAcct_DropDownClosed);
            this.cbToAcct.KeyPress += new System.Windows.Forms.KeyPressEventHandler(this.cbToAcct_KeyPress);
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(49, 40);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(108, 30);
            this.label2.TabIndex = 0;
            this.label2.Text = "To Account  :";
            // 
            // tbAmount
            // 
            this.tbAmount.Location = new System.Drawing.Point(186, 477);
            this.tbAmount.Name = "tbAmount";
            this.tbAmount.Size = new System.Drawing.Size(374, 37);
            this.tbAmount.TabIndex = 9;
            // 
            // label3
            // 
            this.label3.AutoSize = true;
            this.label3.Location = new System.Drawing.Point(102, 480);
            this.label3.Name = "label3";
            this.label3.Size = new System.Drawing.Size(78, 30);
            this.label3.TabIndex = 8;
            this.label3.Text = "Amount :";
            // 
            // tbRemark
            // 
            this.tbRemark.Location = new System.Drawing.Point(186, 530);
            this.tbRemark.Multiline = true;
            this.tbRemark.Name = "tbRemark";
            this.tbRemark.Size = new System.Drawing.Size(374, 103);
            this.tbRemark.TabIndex = 11;
            // 
            // label4
            // 
            this.label4.AutoSize = true;
            this.label4.Location = new System.Drawing.Point(102, 533);
            this.label4.Name = "label4";
            this.label4.Size = new System.Drawing.Size(77, 30);
            this.label4.TabIndex = 10;
            this.label4.Text = "Remark :";
            // 
            // btSave
            // 
            this.btSave.Location = new System.Drawing.Point(219, 657);
            this.btSave.Name = "btSave";
            this.btSave.Size = new System.Drawing.Size(120, 57);
            this.btSave.TabIndex = 12;
            this.btSave.Text = "Save";
            this.btSave.UseVisualStyleBackColor = true;
            this.btSave.Click += new System.EventHandler(this.btSave_Click);
            // 
            // btClose
            // 
            this.btClose.Location = new System.Drawing.Point(376, 657);
            this.btClose.Name = "btClose";
            this.btClose.Size = new System.Drawing.Size(120, 57);
            this.btClose.TabIndex = 13;
            this.btClose.Text = "Close";
            this.btClose.UseVisualStyleBackColor = true;
            this.btClose.Click += new System.EventHandler(this.btClose_Click);
            // 
            // frm_CustSupTransfer
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.ClientSize = new System.Drawing.Size(621, 740);
            this.Controls.Add(this.btClose);
            this.Controls.Add(this.btSave);
            this.Controls.Add(this.tbRemark);
            this.Controls.Add(this.label4);
            this.Controls.Add(this.tbAmount);
            this.Controls.Add(this.label3);
            this.Controls.Add(this.gbToAcct);
            this.Controls.Add(this.gbFrom);
            this.Controls.Add(this.tbDocumentID);
            this.Controls.Add(this.tbAutoID);
            this.Controls.Add(this.lbDocID);
            this.Controls.Add(this.lbAuto);
            this.Controls.Add(this.lblDate);
            this.Controls.Add(this.dtpDate);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frm_CustSupTransfer";
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Customer/Supplier Account Transfer";
            this.Load += new System.EventHandler(this.frm_CustSupTransfer_Load);
            this.gbFrom.ResumeLayout(false);
            this.gbFrom.PerformLayout();
            this.gbToAcct.ResumeLayout(false);
            this.gbToAcct.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.TextBox tbDocumentID;
        private System.Windows.Forms.TextBox tbAutoID;
        private System.Windows.Forms.Label lbDocID;
        private System.Windows.Forms.Label lbAuto;
        private System.Windows.Forms.Label lblDate;
        private System.Windows.Forms.DateTimePicker dtpDate;
        private System.Windows.Forms.GroupBox gbFrom;
        private System.Windows.Forms.ComboBox cbFromName;
        private System.Windows.Forms.Label lbFromName;
        private System.Windows.Forms.ComboBox cbFromAcct;
        private System.Windows.Forms.Label lbFromAcct;
        private System.Windows.Forms.GroupBox gbToAcct;
        private System.Windows.Forms.ComboBox cbToName;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.ComboBox cbToAcct;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox tbAmount;
        private System.Windows.Forms.Label label3;
        private System.Windows.Forms.TextBox tbRemark;
        private System.Windows.Forms.Label label4;
        private System.Windows.Forms.Button btSave;
        private System.Windows.Forms.Button btClose;
    }
}