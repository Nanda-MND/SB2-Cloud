
namespace SB
{
    partial class frm_PrintSelect
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
            this.groupBox1 = new System.Windows.Forms.GroupBox();
            this.rbPansar = new System.Windows.Forms.RadioButton();
            this.rbInvoice = new System.Windows.Forms.RadioButton();
            this.rbVoucher = new System.Windows.Forms.RadioButton();
            this.btPrint = new System.Windows.Forms.Button();
            this.rbLogo = new System.Windows.Forms.RadioButton();
            this.groupBox1.SuspendLayout();
            this.SuspendLayout();
            // 
            // groupBox1
            // 
            this.groupBox1.Controls.Add(this.rbLogo);
            this.groupBox1.Controls.Add(this.rbPansar);
            this.groupBox1.Controls.Add(this.rbInvoice);
            this.groupBox1.Controls.Add(this.rbVoucher);
            this.groupBox1.Location = new System.Drawing.Point(19, 9);
            this.groupBox1.Name = "groupBox1";
            this.groupBox1.Size = new System.Drawing.Size(525, 83);
            this.groupBox1.TabIndex = 1;
            this.groupBox1.TabStop = false;
            this.groupBox1.Text = "Print Selection";
            // 
            // rbPansar
            // 
            this.rbPansar.AutoSize = true;
            this.rbPansar.Location = new System.Drawing.Point(243, 36);
            this.rbPansar.Name = "rbPansar";
            this.rbPansar.Size = new System.Drawing.Size(97, 34);
            this.rbPansar.TabIndex = 2;
            this.rbPansar.Text = "Pann Sar";
            this.rbPansar.UseVisualStyleBackColor = true;
            // 
            // rbInvoice
            // 
            this.rbInvoice.AutoSize = true;
            this.rbInvoice.Location = new System.Drawing.Point(132, 36);
            this.rbInvoice.Name = "rbInvoice";
            this.rbInvoice.Size = new System.Drawing.Size(81, 34);
            this.rbInvoice.TabIndex = 1;
            this.rbInvoice.Text = "Invoice";
            this.rbInvoice.UseVisualStyleBackColor = true;
            // 
            // rbVoucher
            // 
            this.rbVoucher.AutoSize = true;
            this.rbVoucher.Checked = true;
            this.rbVoucher.Location = new System.Drawing.Point(17, 36);
            this.rbVoucher.Name = "rbVoucher";
            this.rbVoucher.Size = new System.Drawing.Size(89, 34);
            this.rbVoucher.TabIndex = 0;
            this.rbVoucher.TabStop = true;
            this.rbVoucher.Text = "Voucher";
            this.rbVoucher.UseVisualStyleBackColor = true;
            // 
            // btPrint
            // 
            this.btPrint.Location = new System.Drawing.Point(222, 98);
            this.btPrint.Name = "btPrint";
            this.btPrint.Size = new System.Drawing.Size(137, 44);
            this.btPrint.TabIndex = 0;
            this.btPrint.Text = "Print";
            this.btPrint.UseVisualStyleBackColor = true;
            this.btPrint.Click += new System.EventHandler(this.btPrint_Click);
            // 
            // rbLogo
            // 
            this.rbLogo.AutoSize = true;
            this.rbLogo.Location = new System.Drawing.Point(368, 36);
            this.rbLogo.Name = "rbLogo";
            this.rbLogo.Size = new System.Drawing.Size(144, 34);
            this.rbLogo.TabIndex = 3;
            this.rbLogo.Text = "Pann Sar(Logo)";
            this.rbLogo.UseVisualStyleBackColor = true;
            // 
            // frm_PrintSelect
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(192)))), ((int)(((byte)(192)))), ((int)(((byte)(255)))));
            this.ClientSize = new System.Drawing.Size(556, 153);
            this.Controls.Add(this.btPrint);
            this.Controls.Add(this.groupBox1);
            this.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.FormBorderStyle = System.Windows.Forms.FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "frm_PrintSelect";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterScreen;
            this.Text = "Print Selection";
            this.Load += new System.EventHandler(this.frm_PrintSelect_Load);
            this.groupBox1.ResumeLayout(false);
            this.groupBox1.PerformLayout();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.GroupBox groupBox1;
        private System.Windows.Forms.RadioButton rbPansar;
        private System.Windows.Forms.RadioButton rbInvoice;
        private System.Windows.Forms.RadioButton rbVoucher;
        private System.Windows.Forms.Button btPrint;
        private System.Windows.Forms.RadioButton rbLogo;
    }
}