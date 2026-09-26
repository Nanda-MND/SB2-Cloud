
namespace SB
{
    partial class MultiSelect
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

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle1 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle2 = new System.Windows.Forms.DataGridViewCellStyle();
            System.Windows.Forms.DataGridViewCellStyle dataGridViewCellStyle3 = new System.Windows.Forms.DataGridViewCellStyle();
            this.splitContainer1 = new System.Windows.Forms.SplitContainer();
            this.pbDropDown = new System.Windows.Forms.PictureBox();
            this.tbSelect = new System.Windows.Forms.TextBox();
            this.splitContainer2 = new System.Windows.Forms.SplitContainer();
            this.pbUncheck = new System.Windows.Forms.PictureBox();
            this.tbSearch = new System.Windows.Forms.TextBox();
            this.dgvSelection = new System.Windows.Forms.DataGridView();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).BeginInit();
            this.splitContainer1.Panel1.SuspendLayout();
            this.splitContainer1.Panel2.SuspendLayout();
            this.splitContainer1.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbDropDown)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).BeginInit();
            this.splitContainer2.Panel1.SuspendLayout();
            this.splitContainer2.Panel2.SuspendLayout();
            this.splitContainer2.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.pbUncheck)).BeginInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvSelection)).BeginInit();
            this.SuspendLayout();
            // 
            // splitContainer1
            // 
            this.splitContainer1.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer1.FixedPanel = System.Windows.Forms.FixedPanel.Panel1;
            this.splitContainer1.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.splitContainer1.Location = new System.Drawing.Point(0, 0);
            this.splitContainer1.Name = "splitContainer1";
            this.splitContainer1.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer1.Panel1
            // 
            this.splitContainer1.Panel1.Controls.Add(this.pbDropDown);
            this.splitContainer1.Panel1.Controls.Add(this.tbSelect);
            this.splitContainer1.Panel1.Font = new System.Drawing.Font("Pyidaungsu", 9.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.splitContainer1.Panel1MinSize = 40;
            // 
            // splitContainer1.Panel2
            // 
            this.splitContainer1.Panel2.Controls.Add(this.splitContainer2);
            this.splitContainer1.Panel2MinSize = 0;
            this.splitContainer1.Size = new System.Drawing.Size(283, 320);
            this.splitContainer1.SplitterDistance = 40;
            this.splitContainer1.SplitterWidth = 1;
            this.splitContainer1.TabIndex = 1;
            this.splitContainer1.TabStop = false;
            // 
            // pbDropDown
            // 
            this.pbDropDown.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pbDropDown.Image = global::SB.Properties.Resources.down_arrow1;
            this.pbDropDown.Location = new System.Drawing.Point(245, 1);
            this.pbDropDown.Name = "pbDropDown";
            this.pbDropDown.Size = new System.Drawing.Size(35, 35);
            this.pbDropDown.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pbDropDown.TabIndex = 1;
            this.pbDropDown.TabStop = false;
            this.pbDropDown.Click += new System.EventHandler(this.pbDropDown_Click);
            // 
            // tbSelect
            // 
            this.tbSelect.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.tbSelect.BackColor = System.Drawing.Color.White;
            this.tbSelect.Enabled = false;
            this.tbSelect.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbSelect.ForeColor = System.Drawing.Color.Black;
            this.tbSelect.Location = new System.Drawing.Point(3, 2);
            this.tbSelect.Name = "tbSelect";
            this.tbSelect.ReadOnly = true;
            this.tbSelect.Size = new System.Drawing.Size(242, 37);
            this.tbSelect.TabIndex = 0;
            this.tbSelect.TabStop = false;
            this.tbSelect.Validated += new System.EventHandler(this.tbSelect_Validated);
            // 
            // splitContainer2
            // 
            this.splitContainer2.Dock = System.Windows.Forms.DockStyle.Fill;
            this.splitContainer2.FixedPanel = System.Windows.Forms.FixedPanel.Panel1;
            this.splitContainer2.Location = new System.Drawing.Point(0, 0);
            this.splitContainer2.Name = "splitContainer2";
            this.splitContainer2.Orientation = System.Windows.Forms.Orientation.Horizontal;
            // 
            // splitContainer2.Panel1
            // 
            this.splitContainer2.Panel1.Controls.Add(this.pbUncheck);
            this.splitContainer2.Panel1.Controls.Add(this.tbSearch);
            this.splitContainer2.Panel1MinSize = 40;
            // 
            // splitContainer2.Panel2
            // 
            this.splitContainer2.Panel2.Controls.Add(this.dgvSelection);
            this.splitContainer2.Size = new System.Drawing.Size(283, 279);
            this.splitContainer2.SplitterDistance = 40;
            this.splitContainer2.SplitterWidth = 1;
            this.splitContainer2.TabIndex = 4;
            this.splitContainer2.TabStop = false;
            // 
            // pbUncheck
            // 
            this.pbUncheck.Anchor = ((System.Windows.Forms.AnchorStyles)(((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.pbUncheck.BorderStyle = System.Windows.Forms.BorderStyle.Fixed3D;
            this.pbUncheck.Image = global::SB.Properties.Resources.delete__5_;
            this.pbUncheck.Location = new System.Drawing.Point(245, 1);
            this.pbUncheck.Name = "pbUncheck";
            this.pbUncheck.Size = new System.Drawing.Size(34, 36);
            this.pbUncheck.SizeMode = System.Windows.Forms.PictureBoxSizeMode.Zoom;
            this.pbUncheck.TabIndex = 2;
            this.pbUncheck.TabStop = false;
            this.pbUncheck.Click += new System.EventHandler(this.pbUncheck_Click);
            // 
            // tbSearch
            // 
            this.tbSearch.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.tbSearch.Location = new System.Drawing.Point(3, 3);
            this.tbSearch.Name = "tbSearch";
            this.tbSearch.Size = new System.Drawing.Size(242, 37);
            this.tbSearch.TabIndex = 0;
            this.tbSearch.Validated += new System.EventHandler(this.tbSearch_Validated);
            // 
            // dgvSelection
            // 
            this.dgvSelection.AllowUserToAddRows = false;
            this.dgvSelection.AllowUserToDeleteRows = false;
            this.dgvSelection.AllowUserToResizeColumns = false;
            this.dgvSelection.AllowUserToResizeRows = false;
            dataGridViewCellStyle1.Font = new System.Drawing.Font("Pyidaungsu", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSelection.AlternatingRowsDefaultCellStyle = dataGridViewCellStyle1;
            this.dgvSelection.BackgroundColor = System.Drawing.Color.WhiteSmoke;
            this.dgvSelection.CellBorderStyle = System.Windows.Forms.DataGridViewCellBorderStyle.Raised;
            dataGridViewCellStyle2.Alignment = System.Windows.Forms.DataGridViewContentAlignment.MiddleCenter;
            dataGridViewCellStyle2.BackColor = System.Drawing.SystemColors.Control;
            dataGridViewCellStyle2.Font = new System.Drawing.Font("Pyidaungsu", 12.75F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            dataGridViewCellStyle2.ForeColor = System.Drawing.SystemColors.WindowText;
            dataGridViewCellStyle2.SelectionBackColor = System.Drawing.SystemColors.Highlight;
            dataGridViewCellStyle2.SelectionForeColor = System.Drawing.SystemColors.HighlightText;
            dataGridViewCellStyle2.WrapMode = System.Windows.Forms.DataGridViewTriState.True;
            this.dgvSelection.ColumnHeadersDefaultCellStyle = dataGridViewCellStyle2;
            this.dgvSelection.ColumnHeadersHeight = 30;
            this.dgvSelection.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.DisableResizing;
            this.dgvSelection.ColumnHeadersVisible = false;
            this.dgvSelection.Dock = System.Windows.Forms.DockStyle.Fill;
            this.dgvSelection.GridColor = System.Drawing.Color.Black;
            this.dgvSelection.Location = new System.Drawing.Point(0, 0);
            this.dgvSelection.Name = "dgvSelection";
            this.dgvSelection.RowHeadersVisible = false;
            dataGridViewCellStyle3.Font = new System.Drawing.Font("Pyidaungsu", 12F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSelection.RowsDefaultCellStyle = dataGridViewCellStyle3;
            this.dgvSelection.RowTemplate.DefaultCellStyle.Font = new System.Drawing.Font("Pyidaungsu", 11.25F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(0)));
            this.dgvSelection.RowTemplate.Height = 35;
            this.dgvSelection.SelectionMode = System.Windows.Forms.DataGridViewSelectionMode.FullRowSelect;
            this.dgvSelection.Size = new System.Drawing.Size(283, 238);
            this.dgvSelection.TabIndex = 0;
            this.dgvSelection.CellEndEdit += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvSelection_CellEndEdit);
            this.dgvSelection.CellEnter += new System.Windows.Forms.DataGridViewCellEventHandler(this.dgvSelection_CellEnter);
            // 
            // MultiSelect
            // 
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.None;
            this.Controls.Add(this.splitContainer1);
            this.Name = "MultiSelect";
            this.Size = new System.Drawing.Size(283, 320);
            this.EnabledChanged += new System.EventHandler(this.MultiSelect_EnabledChanged);
            this.splitContainer1.Panel1.ResumeLayout(false);
            this.splitContainer1.Panel1.PerformLayout();
            this.splitContainer1.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer1)).EndInit();
            this.splitContainer1.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pbDropDown)).EndInit();
            this.splitContainer2.Panel1.ResumeLayout(false);
            this.splitContainer2.Panel1.PerformLayout();
            this.splitContainer2.Panel2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.splitContainer2)).EndInit();
            this.splitContainer2.ResumeLayout(false);
            ((System.ComponentModel.ISupportInitialize)(this.pbUncheck)).EndInit();
            ((System.ComponentModel.ISupportInitialize)(this.dgvSelection)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.SplitContainer splitContainer1;
        private System.Windows.Forms.PictureBox pbDropDown;
        private System.Windows.Forms.TextBox tbSelect;
        private System.Windows.Forms.SplitContainer splitContainer2;
        private System.Windows.Forms.PictureBox pbUncheck;
        private System.Windows.Forms.TextBox tbSearch;
        private System.Windows.Forms.DataGridView dgvSelection;
    }
}
