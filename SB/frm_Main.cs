using System;
using System.Data;
using System.Drawing;
using System.Windows.Forms;

namespace SB
{
    /// <summary>
    /// Recovered Main history ListView surface.
    /// The SB reference clone did not include frm_Main.cs or FastListViewHelper.cs.
    /// ERP menu code should call ShowHistory(menu, table) with the history DataTable.
    /// </summary>
    public partial class frm_Main : Form
    {
        private DataTable _boundTable;
        private string _layoutMenu;

        public frm_Main()
        {
            InitializeComponent();
            FastListViewHelper.Configure(dlvHistory);
            cboMenu.DropDownStyle = ComboBoxStyle.DropDown;
            cboFilter.DropDownStyle = ComboBoxStyle.DropDown;
            if (cboMenu.Items.Count == 0)
            {
                cboMenu.Items.Add("Sales");
                cboMenu.Items.Add("Cashbook");
                cboMenu.Items.Add("Balance");
            }
            cboMenu.SelectedIndex = 0;
            dlvHistory.SelectionChanged += dlvHistory_SelectionChanged;
            UpdateSelectionCommands();
        }

        public void ShowHistory(string menuName, DataTable table)
        {
            if (string.IsNullOrEmpty(menuName))
                menuName = "Sales";
            cboMenu.Text = menuName;
            FillListView(menuName, table);
        }

        private void frm_Main_Shown(object sender, EventArgs e)
        {
            FillListView(CurrentMenu(), null);
        }

        private void cboMenu_SelectionChangeCommitted(object sender, EventArgs e)
        {
            FillListView(CurrentMenu(), null);
        }

        private void cboMenu_Leave(object sender, EventArgs e)
        {
            FillListView(CurrentMenu(), null);
        }

        private void cboMenu_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.KeyCode == Keys.Enter)
            {
                FillListView(CurrentMenu(), null);
                e.Handled = true;
                e.SuppressKeyPress = true;
            }
        }

        private void cboFilter_TextChanged(object sender, EventArgs e)
        {
            // DropDown (not DropDownList) so typing filters without recreating columns.
            FillListView(CurrentMenu(), null);
        }

        private void btnReload_Click(object sender, EventArgs e)
        {
            FillListView(CurrentMenu(), null);
        }

        private void btnEdit_Click(object sender, EventArgs e)
        {
            int count = FastListViewHelper.SelectionCount(dlvHistory);
            object id;
            if (count == 0)
            {
                SetAction("Edit: select a row first.");
                return;
            }
            if (count > 1)
            {
                SetAction("Edit: select one row. " + count + " rows are selected.");
                return;
            }
            if (!FastListViewHelper.TryGetSelectedId(dlvHistory, out id))
            {
                SetAction("Edit: the selected row has no ID.");
                return;
            }
            SetAction("Edit row " + id + ".");
        }

        private void btnDelete_Click(object sender, EventArgs e)
        {
            int count = FastListViewHelper.SelectionCount(dlvHistory);
            if (count == 0)
            {
                SetAction("Delete: select one or more rows.");
                return;
            }

            System.Collections.Generic.IList<object> ids = FastListViewHelper.GetSelectedIds(dlvHistory, "ID");
            SetAction("Delete " + count + " row(s): " + string.Join(", ", ToStrings(ids)) + ".");
        }

        private void btnPrint_Click(object sender, EventArgs e)
        {
            int count = FastListViewHelper.SelectionCount(dlvHistory);
            if (count == 0)
            {
                SetAction("Print: select one or more rows.");
                return;
            }
            SetAction("Print " + count + " row(s).");
        }

        private void btnPopup_Click(object sender, EventArgs e)
        {
            frm_List.ShowPopup(this, CurrentMenu(), _boundTable);
        }

        private void dlvHistory_SelectionChanged(object sender, EventArgs e)
        {
            UpdateSelectionCommands();
        }

        private void FillListView(string menuName, DataTable explicitTable)
        {
            int generation = FastListViewHelper.PrepareForLayoutChange(dlvHistory);
            BeginHistoryLoadProgress();
            try
            {
                SetHistoryLoadProgress(20);
                DataTable source = explicitTable ?? SampleHistory(menuName);
                DataTable filtered = ApplyTextFilter(source, cboFilter.Text);
                if (FastListViewHelper.IsBalanceMenu(menuName))
                    filtered = FastListViewHelper.SortBalanceTable(filtered);
                if (!FastListViewHelper.IsCurrentGeneration(dlvHistory, generation))
                    return;

                SetHistoryLoadProgress(60);
                BindHistoryListView(menuName, filtered);
                if (!FastListViewHelper.IsCurrentGeneration(dlvHistory, generation))
                    return;

                SetHistoryLoadProgress(100);
                UpdateHistoryFooter(menuName, filtered);
                tslbMachine.Text = Environment.MachineName + "  " + menuName;
            }
            finally
            {
                if (FastListViewHelper.IsCurrentGeneration(dlvHistory, generation))
                    EndHistoryLoadProgress();
            }
        }

        private void BindHistoryListView(string menuName, DataTable table)
        {
            bool reuse = string.Equals(_layoutMenu, menuName, StringComparison.OrdinalIgnoreCase);
            System.Collections.Generic.IList<ListViewColumnSpec> columns = ReferenceDataCache.ListViewColumns(menuName, table);
            FastListViewHelper.BindObjectTable(dlvHistory, table, columns, reuse);
            _layoutMenu = menuName;
            _boundTable = table;
            ApplyMenuColumnDefaults(menuName);
            UpdateSelectionCommands();
        }

        private void ApplyMenuColumnDefaults(string menuName)
        {
            if (FastListViewHelper.IsSalesMenu(menuName))
                ApplySalesHistoryColumnWidths();
            else if (FastListViewHelper.IsCashbookMenu(menuName))
                FastListViewHelper.ApplyCashbookListDefaults(dlvHistory);
            else if (FastListViewHelper.IsBalanceMenu(menuName))
                FastListViewHelper.ApplyBalanceListDefaults(dlvHistory);
        }

        private void ApplySalesHistoryColumnWidths()
        {
            FastListViewHelper.ApplySalesHistoryColumnWidths(dlvHistory);
        }

        private void UpdateHistoryFooter(string menuName, DataTable table)
        {
            bool sales = FastListViewHelper.IsSalesMenu(menuName);
            bool cashbook = FastListViewHelper.IsCashbookMenu(menuName);
            bool balance = FastListViewHelper.IsBalanceMenu(menuName);

            SetFooter(tslbTotalAmount, sales, "Total Amount: " + FastListViewHelper.FormatNumber(SumFirst(table, "Amount")));
            SetFooter(tsLabelPaid, sales, "Paid: " + FastListViewHelper.FormatNumber(SumFirst(table, "Paid", "PaidAmount")));
            SetFooter(tsLablePK, sales, "PK: " + FastListViewHelper.FormatNumber(SumFirst(table, "PK")));
            SetFooter(tslbBankCharges, sales, "Bank Charges: " + FastListViewHelper.FormatNumber(SumFirst(table, "Charges")));
            SetFooter(tslbIncome, cashbook, "Income: " + FastListViewHelper.FormatNumber(SumFirst(table, "TotalIncome")));
            SetFooter(tslbExpense, cashbook, "Expense: " + FastListViewHelper.FormatNumber(SumFirst(table, "TotalExpense")));
            SetFooter(tslbClosing, balance, "Total Closing: " + FastListViewHelper.FormatNumber(SumFirst(table, "Closing", "ClosingBalance", "Balance")));
        }

        private static decimal SumFirst(DataTable table, params string[] columns)
        {
            foreach (string column in columns)
            {
                if (table != null && table.Columns.Contains(column))
                    return FastListViewHelper.SumNumericColumn(table, column);
            }
            return 0m;
        }

        private static void SetFooter(ToolStripItem item, bool visible, string text)
        {
            item.Visible = visible;
            item.Text = visible ? text : string.Empty;
        }

        private void BeginHistoryLoadProgress()
        {
            tspbHistoryLoad.Minimum = 0;
            tspbHistoryLoad.Maximum = 100;
            tspbHistoryLoad.Value = 0;
            tspbHistoryLoad.Style = ProgressBarStyle.Continuous;
            tspbHistoryLoad.Visible = true;
            statusStrip1.Refresh();
            // Sample binds finish in one turn. Let the bar paint before the fill continues.
            Application.DoEvents();
        }

        private void SetHistoryLoadProgress(int percent)
        {
            if (!tspbHistoryLoad.Visible)
                return;
            if (percent < tspbHistoryLoad.Minimum)
                percent = tspbHistoryLoad.Minimum;
            if (percent > tspbHistoryLoad.Maximum)
                percent = tspbHistoryLoad.Maximum;
            tspbHistoryLoad.Value = percent;
        }

        private void EndHistoryLoadProgress()
        {
            tspbHistoryLoad.Value = tspbHistoryLoad.Maximum;
            statusStrip1.Refresh();
            tspbHistoryLoad.Value = 0;
            tspbHistoryLoad.Visible = false;
            statusStrip1.Refresh();
        }

        private void UpdateSelectionCommands()
        {
            int count = FastListViewHelper.SelectionCount(dlvHistory);
            btnEdit.Enabled = count == 1;
            btnDelete.Enabled = count >= 1;
            btnPrint.Enabled = count >= 1;
        }

        private void SetAction(string text)
        {
            lblSelection.Text = text;
        }

        private string CurrentMenu()
        {
            string text = cboMenu.Text;
            if (string.IsNullOrEmpty(text) && cboMenu.SelectedItem != null)
                text = Convert.ToString(cboMenu.SelectedItem);
            return string.IsNullOrEmpty(text) ? "Sales" : text.Trim();
        }

        private static DataTable ApplyTextFilter(DataTable source, string text)
        {
            if (source == null)
                return new DataTable();
            if (string.IsNullOrWhiteSpace(text))
                return source.Copy();

            DataView view = new DataView(source);
            System.Collections.Generic.List<string> clauses = new System.Collections.Generic.List<string>();
            string escaped = text.Trim().Replace("'", "''").Replace("[", "[[]").Replace("%", "[%]").Replace("*", "[*]");
            foreach (DataColumn column in source.Columns)
            {
                if (column.DataType != typeof(string))
                    continue;
                clauses.Add("Convert([" + column.ColumnName.Replace("]", "]]") + "], 'System.String') LIKE '%" + escaped + "%'");
            }
            if (clauses.Count == 0)
                return source.Copy();
            try
            {
                view.RowFilter = string.Join(" OR ", clauses.ToArray());
                return view.ToTable();
            }
            catch (EvaluateException)
            {
                return source.Copy();
            }
            catch (SyntaxErrorException)
            {
                return source.Copy();
            }
        }

        private static string[] ToStrings(System.Collections.Generic.IList<object> values)
        {
            string[] texts = new string[values.Count];
            for (int i = 0; i < values.Count; i++)
                texts[i] = Convert.ToString(values[i]);
            return texts;
        }

        private static DataTable SampleHistory(string menuName)
        {
            if (FastListViewHelper.IsCashbookMenu(menuName))
                return SampleCashbook();
            if (FastListViewHelper.IsBalanceMenu(menuName))
                return SampleBalance();
            return SampleSales();
        }

        private static DataTable SampleSales()
        {
            DataTable table = new DataTable();
            table.Columns.Add("ID", typeof(int));
            table.Columns.Add("Date", typeof(DateTime));
            table.Columns.Add("Customer", typeof(string));
            table.Columns.Add("Car", typeof(string));
            table.Columns.Add("Discount", typeof(decimal));
            table.Columns.Add("Charges", typeof(decimal));
            table.Columns.Add("Paid", typeof(decimal));
            table.Columns.Add("PK", typeof(decimal));
            table.Columns.Add("Amount", typeof(decimal));
            table.Rows.Add(1, new DateTime(2026, 9, 1), "Aung", "Truck", 1000m, 301m, 50000m, 2m, 100000m);
            table.Rows.Add(2, new DateTime(2026, 9, 2), "Mya", "Car", 500m, 150m, 20000m, 1m, 40000m);
            table.Rows.Add(3, new DateTime(2026, 9, 3), "Hla", "Van", 0m, 0m, 0m, 4m, 25000m);
            return table;
        }

        private static DataTable SampleCashbook()
        {
            DataTable table = new DataTable();
            table.Columns.Add("ID", typeof(int));
            table.Columns.Add("Date", typeof(DateTime));
            table.Columns.Add("Account", typeof(string));
            table.Columns.Add("Remark", typeof(string));
            table.Columns.Add("Printed", typeof(bool));
            table.Columns.Add("PrintCheque", typeof(bool));
            table.Columns.Add("ExgRate", typeof(decimal));
            table.Columns.Add("TotalIncome", typeof(decimal));
            table.Columns.Add("TotalExpense", typeof(decimal));
            table.Rows.Add(11, new DateTime(2026, 9, 4), "Cash", "Receipt", false, false, 1m, 80000m, 0m);
            table.Rows.Add(12, new DateTime(2026, 9, 5), "Bank", "Payment", true, true, 1m, 0m, 15000m);
            return table;
        }

        private static DataTable SampleBalance()
        {
            DataTable table = new DataTable();
            table.Columns.Add("ID", typeof(int));
            table.Columns.Add("Name", typeof(string));
            table.Columns.Add("Opening", typeof(decimal));
            table.Columns.Add("Debit", typeof(decimal));
            table.Columns.Add("Credit", typeof(decimal));
            table.Columns.Add("Closing", typeof(decimal));
            table.Rows.Add(21, "Zeta", 1000m, 200m, 50m, 1150m);
            table.Rows.Add(22, "Alpha", 5000m, 0m, 1000m, 4000m);
            table.Rows.Add(23, "Mid", 250m, 250m, 0m, 500m);
            return table;
        }
    }
}
