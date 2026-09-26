using System.Drawing;
using System.Windows.Forms;
using BrightIdeasSoftware;

namespace SB
{
    partial class frm_Main
    {
        private System.ComponentModel.IContainer components = null;
        private Panel panelTop;
        private Label lblMenu;
        private ComboBox cboMenu;
        private Label lblFilter;
        private ComboBox cboFilter;
        private Button btnReload;
        private Button btnEdit;
        private Button btnDelete;
        private Button btnPrint;
        private Button btnPopup;
        private Label lblSelection;
        private FastObjectListView dlvHistory;
        private StatusStrip statusStrip1;
        private ToolStripStatusLabel tslbMachine;
        private ToolStripProgressBar tspbHistoryLoad;
        private ToolStripStatusLabel tsslSpring;
        private ToolStripStatusLabel tslbTotalAmount;
        private ToolStripStatusLabel tsLabelPaid;
        private ToolStripStatusLabel tsLablePK;
        private ToolStripStatusLabel tslbBankCharges;
        private ToolStripStatusLabel tslbIncome;
        private ToolStripStatusLabel tslbExpense;
        private ToolStripStatusLabel tslbClosing;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
                components.Dispose();
            base.Dispose(disposing);
        }

        private void InitializeComponent()
        {
            this.panelTop = new Panel();
            this.lblMenu = new Label();
            this.cboMenu = new ComboBox();
            this.lblFilter = new Label();
            this.cboFilter = new ComboBox();
            this.btnReload = new Button();
            this.btnEdit = new Button();
            this.btnDelete = new Button();
            this.btnPrint = new Button();
            this.btnPopup = new Button();
            this.lblSelection = new Label();
            this.dlvHistory = new FastObjectListView();
            this.statusStrip1 = new StatusStrip();
            this.tslbMachine = new ToolStripStatusLabel();
            this.tspbHistoryLoad = new ToolStripProgressBar();
            this.tsslSpring = new ToolStripStatusLabel();
            this.tslbTotalAmount = new ToolStripStatusLabel();
            this.tsLabelPaid = new ToolStripStatusLabel();
            this.tsLablePK = new ToolStripStatusLabel();
            this.tslbBankCharges = new ToolStripStatusLabel();
            this.tslbIncome = new ToolStripStatusLabel();
            this.tslbExpense = new ToolStripStatusLabel();
            this.tslbClosing = new ToolStripStatusLabel();
            this.panelTop.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dlvHistory)).BeginInit();
            this.statusStrip1.SuspendLayout();
            this.SuspendLayout();

            this.panelTop.Dock = DockStyle.Top;
            this.panelTop.Height = 72;
            this.panelTop.Padding = new Padding(8);

            this.lblMenu.AutoSize = true;
            this.lblMenu.Location = new Point(8, 12);
            this.lblMenu.Text = "Menu";

            this.cboMenu.DropDownStyle = ComboBoxStyle.DropDown;
            this.cboMenu.Location = new Point(52, 8);
            this.cboMenu.Width = 160;
            this.cboMenu.SelectionChangeCommitted += cboMenu_SelectionChangeCommitted;
            this.cboMenu.Leave += cboMenu_Leave;
            this.cboMenu.KeyDown += cboMenu_KeyDown;

            this.lblFilter.AutoSize = true;
            this.lblFilter.Location = new Point(228, 12);
            this.lblFilter.Text = "Filter";

            this.cboFilter.DropDownStyle = ComboBoxStyle.DropDown;
            this.cboFilter.Location = new Point(268, 8);
            this.cboFilter.Width = 220;
            this.cboFilter.TextChanged += cboFilter_TextChanged;

            this.btnReload.Location = new Point(500, 7);
            this.btnReload.Width = 72;
            this.btnReload.Text = "Reload";
            this.btnReload.Click += btnReload_Click;

            this.btnEdit.Location = new Point(580, 7);
            this.btnEdit.Width = 72;
            this.btnEdit.Text = "Edit";
            this.btnEdit.Click += btnEdit_Click;

            this.btnDelete.Location = new Point(658, 7);
            this.btnDelete.Width = 72;
            this.btnDelete.Text = "Delete";
            this.btnDelete.Click += btnDelete_Click;

            this.btnPrint.Location = new Point(736, 7);
            this.btnPrint.Width = 72;
            this.btnPrint.Text = "Print";
            this.btnPrint.Click += btnPrint_Click;

            this.btnPopup.Location = new Point(814, 7);
            this.btnPopup.Width = 72;
            this.btnPopup.Text = "List";
            this.btnPopup.Click += btnPopup_Click;

            this.lblSelection.AutoSize = true;
            this.lblSelection.Location = new Point(8, 42);
            this.lblSelection.Text = "Select history rows.";

            this.panelTop.Controls.Add(this.lblMenu);
            this.panelTop.Controls.Add(this.cboMenu);
            this.panelTop.Controls.Add(this.lblFilter);
            this.panelTop.Controls.Add(this.cboFilter);
            this.panelTop.Controls.Add(this.btnReload);
            this.panelTop.Controls.Add(this.btnEdit);
            this.panelTop.Controls.Add(this.btnDelete);
            this.panelTop.Controls.Add(this.btnPrint);
            this.panelTop.Controls.Add(this.btnPopup);
            this.panelTop.Controls.Add(this.lblSelection);

            this.dlvHistory.Dock = DockStyle.Fill;
            this.dlvHistory.FullRowSelect = true;
            this.dlvHistory.GridLines = true;
            this.dlvHistory.HideSelection = false;
            this.dlvHistory.MultiSelect = true;
            this.dlvHistory.View = View.Details;
            this.dlvHistory.Name = "dlvHistory";

            this.tslbMachine.Name = "tslbMachine";
            this.tslbMachine.Text = "Dev";

            this.tspbHistoryLoad.Name = "tspbHistoryLoad";
            this.tspbHistoryLoad.Width = 140;
            this.tspbHistoryLoad.Minimum = 0;
            this.tspbHistoryLoad.Maximum = 100;
            this.tspbHistoryLoad.Style = ProgressBarStyle.Continuous;
            this.tspbHistoryLoad.Visible = false;

            this.tsslSpring.Name = "tsslSpring";
            this.tsslSpring.Spring = true;
            this.tsslSpring.AutoSize = false;
            this.tsslSpring.Text = string.Empty;

            this.tslbTotalAmount.Name = "tslbTotalAmount";
            this.tslbTotalAmount.Text = "Total Amount";
            this.tsLabelPaid.Name = "tsLabelPaid";
            this.tsLabelPaid.Text = "Paid";
            this.tsLablePK.Name = "tsLablePK";
            this.tsLablePK.Text = "PK";
            this.tslbBankCharges.Name = "tslbBankCharges";
            this.tslbBankCharges.Text = "Bank Charges";
            this.tslbIncome.Name = "tslbIncome";
            this.tslbIncome.Text = "Income";
            this.tslbIncome.Visible = false;
            this.tslbExpense.Name = "tslbExpense";
            this.tslbExpense.Text = "Expense";
            this.tslbExpense.Visible = false;
            this.tslbClosing.Name = "tslbClosing";
            this.tslbClosing.Text = "Total Closing";
            this.tslbClosing.Visible = false;

            this.statusStrip1.Name = "statusStrip1";
            this.statusStrip1.Dock = DockStyle.Bottom;
            this.statusStrip1.Items.AddRange(new ToolStripItem[] {
                this.tslbMachine,
                this.tspbHistoryLoad,
                this.tsslSpring,
                this.tslbTotalAmount,
                this.tsLabelPaid,
                this.tsLablePK,
                this.tslbBankCharges,
                this.tslbIncome,
                this.tslbExpense,
                this.tslbClosing
            });

            this.AutoScaleMode = AutoScaleMode.Font;
            this.ClientSize = new Size(1280, 720);
            this.MinimumSize = new Size(1024, 600);
            this.Name = "frm_Main";
            this.StartPosition = FormStartPosition.CenterScreen;
            this.Text = "SB";
            this.Shown += frm_Main_Shown;
            this.Controls.Add(this.dlvHistory);
            this.Controls.Add(this.panelTop);
            this.Controls.Add(this.statusStrip1);

            this.panelTop.ResumeLayout(false);
            this.panelTop.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.dlvHistory)).EndInit();
            this.statusStrip1.ResumeLayout(false);
            this.statusStrip1.PerformLayout();
            this.ResumeLayout(false);
            this.PerformLayout();
        }
    }
}
