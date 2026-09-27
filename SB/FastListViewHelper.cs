using System;
using System.Collections;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Runtime.CompilerServices;
using System.Windows.Forms;
using BrightIdeasSoftware;

namespace SB
{
    public sealed class ListViewColumnSpec
    {
        public string MenuName { get; set; }
        public string ColumnName { get; set; }
        public string Header { get; set; }
        public int Width { get; set; }
        public bool Numeric { get; set; }
        public bool Date { get; set; }
        public bool Hidden { get; set; }
    }

    /// <summary>
    /// Recovered history-list helper. The SB reference clone did not contain this file.
    /// </summary>
    public static class FastListViewHelper
    {
        public const int SalesCarWidth = 55;
        public const int SalesDiscountWidth = 70;
        public const int SalesChargesWidth = 70;
        public const int SalesPaidWidth = 70;
        public const int SalesPkWidth = 40;
        public const string NumericFormat = "#,#00";
        public const string DateFormat = "dd/MM/yyyy";

        private static readonly ConditionalWeakTable<ObjectListView, GenerationBox> Generations =
            new ConditionalWeakTable<ObjectListView, GenerationBox>();

        private sealed class GenerationBox
        {
            public int Value;
        }

        public static void Configure(ObjectListView list)
        {
            if (list == null)
                throw new ArgumentNullException("list");

            list.View = View.Details;
            list.FullRowSelect = true;
            list.GridLines = true;
            list.HideSelection = false;
            list.MultiSelect = true;
            list.ShowGroups = false;
            list.HeaderStyle = ColumnHeaderStyle.Clickable;
            list.UseCompatibleStateImageBehavior = false;
        }

        public static int PrepareForLayoutChange(ObjectListView list)
        {
            if (list == null)
                throw new ArgumentNullException("list");

            GenerationBox box = Generations.GetOrCreateValue(list);
            box.Value = box.Value + 1;
            return box.Value;
        }

        public static bool IsCurrentGeneration(ObjectListView list, int generation)
        {
            if (list == null)
                return false;

            GenerationBox box;
            if (!Generations.TryGetValue(list, out box))
                return false;
            return box.Value == generation;
        }

        public static void BindObjectTable(ObjectListView list, DataTable table, IList<ListViewColumnSpec> columns, bool reuseColumns)
        {
            if (list == null)
                throw new ArgumentNullException("list");
            if (table == null)
                table = new DataTable();
            if (columns == null)
                columns = BuildColumns(null, table, null);

            Configure(list);
            int signature = LayoutSignature(columns);
            bool sameLayout = reuseColumns && Equals(list.Tag, signature) && list.AllColumns != null && list.AllColumns.Count > 0;
            list.BeginUpdate();
            try
            {
                if (!sameLayout)
                {
                    list.AllColumns.Clear();
                    foreach (ListViewColumnSpec spec in columns)
                    {
                        OLVColumn column = CreateColumn(spec);
                        list.AllColumns.Add(column);
                    }
                    list.RebuildColumns();
                    list.Tag = signature;
                }

                list.SetObjects(RowsOf(table));
            }
            finally
            {
                list.EndUpdate();
            }
        }

        public static void BindObjectTable(ObjectListView list, DataTable table, IList<ListViewColumnSpec> columns)
        {
            BindObjectTable(list, table, columns, false);
        }

        public static decimal SumNumericColumn(DataTable table, string columnName)
        {
            if (table == null || string.IsNullOrEmpty(columnName) || !table.Columns.Contains(columnName))
                return 0m;

            decimal sum = 0m;
            foreach (DataRow row in table.Rows)
            {
                if (row.RowState == DataRowState.Deleted || row.RowState == DataRowState.Detached)
                    continue;
                object value = row[columnName];
                if (value == null || value == DBNull.Value)
                    continue;
                decimal parsed;
                if (decimal.TryParse(Convert.ToString(value, CultureInfo.InvariantCulture), NumberStyles.Any, CultureInfo.InvariantCulture, out parsed)
                    || decimal.TryParse(Convert.ToString(value, CultureInfo.CurrentCulture), NumberStyles.Any, CultureInfo.CurrentCulture, out parsed))
                {
                    sum += parsed;
                }
            }
            return sum;
        }

        public static string FormatNumber(decimal value)
        {
            return value.ToString(NumericFormat, CultureInfo.CurrentCulture);
        }

        public static bool HasSelection(ObjectListView list)
        {
            return list != null && list.SelectedObjects != null && list.SelectedObjects.Count > 0;
        }

        public static int SelectionCount(ObjectListView list)
        {
            if (list == null || list.SelectedObjects == null)
                return 0;
            return list.SelectedObjects.Count;
        }

        public static bool TryGetSelectedId(ObjectListView list, out object id)
        {
            return TryGetSelectedId(list, "ID", out id);
        }

        public static bool TryGetSelectedId(ObjectListView list, string idColumn, out object id)
        {
            id = null;
            if (SelectionCount(list) != 1)
                return false;

            DataRow row = list.SelectedObject as DataRow;
            if (row == null || row.RowState == DataRowState.Deleted || row.RowState == DataRowState.Detached)
                return false;
            if (row.Table == null || !row.Table.Columns.Contains(idColumn))
                return false;

            object value = row[idColumn];
            if (value == null || value == DBNull.Value)
                return false;
            id = value;
            return true;
        }

        public static IList<object> GetSelectedIds(ObjectListView list, string idColumn)
        {
            List<object> ids = new List<object>();
            if (list == null || list.SelectedObjects == null || string.IsNullOrEmpty(idColumn))
                return ids;

            foreach (object item in list.SelectedObjects)
            {
                DataRow row = item as DataRow;
                if (row == null || row.RowState == DataRowState.Deleted || row.Table == null)
                    continue;
                if (!row.Table.Columns.Contains(idColumn) || row[idColumn] == DBNull.Value)
                    continue;
                ids.Add(row[idColumn]);
            }
            return ids;
        }

        public static DataTable SortBalanceTable(DataTable table)
        {
            if (table == null)
                return new DataTable();

            DataView view = table.DefaultView;
            List<string> parts = new List<string>();
            if (table.Columns.Contains("Name"))
                parts.Add("[Name] ASC");
            else if (table.Columns.Contains("Account"))
                parts.Add("[Account] ASC");

            string closing = FirstExisting(table, "Closing", "ClosingBalance", "Balance");
            if (closing != null)
                parts.Add("[" + closing.Replace("]", "]]") + "] DESC");

            if (parts.Count == 0)
                return table.Copy();

            view.Sort = string.Join(", ", parts.ToArray());
            return view.ToTable();
        }

        public static void ApplySalesHistoryColumnWidths(ObjectListView list)
        {
            if (list == null)
                return;

            EnsureColumn(list, "Charges", "Charges", SalesChargesWidth, "Discount");
            SetColumnWidth(list, "Car", SalesCarWidth);
            SetColumnWidth(list, "Discount", SalesDiscountWidth);
            SetColumnWidth(list, "Charges", SalesChargesWidth);
            SetColumnWidth(list, "Paid", SalesPaidWidth);
            SetColumnWidth(list, "PaidAmount", SalesPaidWidth);
            SetColumnWidth(list, "PK", SalesPkWidth);
            SetColumnWidth(list, "Amount", 110);
        }

        public static void ApplyCashbookListDefaults(ObjectListView list)
        {
            if (list == null)
                return;

            SetColumnWidth(list, "Date", 90);
            SetColumnWidth(list, "Printed", 55);
            SetColumnWidth(list, "PrintCheque", 70);
            SetColumnWidth(list, "ExgRate", 60);
            SetColumnWidth(list, "TotalIncome", 90);
            SetColumnWidth(list, "TotalExpense", 90);
            SetColumnWidth(list, "Remark", 160);
            ApplyNumericFormat(list, "TotalIncome", "TotalExpense", "ExgRate");
        }

        public static void ApplyBalanceListDefaults(ObjectListView list)
        {
            if (list == null)
                return;

            SetColumnWidth(list, "Opening", 90);
            SetColumnWidth(list, "Debit", 90);
            SetColumnWidth(list, "Credit", 90);
            SetColumnWidth(list, "Closing", 100);
            SetColumnWidth(list, "ClosingBalance", 110);
            SetColumnWidth(list, "Balance", 100);
            SetColumnWidth(list, "InQty", 70);
            SetColumnWidth(list, "OutQty", 70);
            ApplyNumericFormat(list, "Opening", "Debit", "Credit", "Closing", "ClosingBalance", "Balance", "InQty", "OutQty", "Amount");
        }

        public static IList<ListViewColumnSpec> BuildColumns(string menuName, DataTable table, DataTable listviewItems)
        {
            List<ListViewColumnSpec> specs = new List<ListViewColumnSpec>();
            if (listviewItems != null
                && listviewItems.Columns.Contains("ColumnName")
                && listviewItems.Columns.Contains("MenuName"))
            {
                foreach (DataRow row in listviewItems.Rows)
                {
                    if (!MenuEquals(row["MenuName"], menuName))
                        continue;
                    string name = Convert.ToString(row["ColumnName"]);
                    if (string.IsNullOrEmpty(name))
                        continue;
                    ListViewColumnSpec spec = new ListViewColumnSpec();
                    spec.MenuName = menuName;
                    spec.ColumnName = name;
                    spec.Header = listviewItems.Columns.Contains("ColumnHeader") && row["ColumnHeader"] != DBNull.Value
                        ? Convert.ToString(row["ColumnHeader"])
                        : name;
                    spec.Width = 100;
                    if (listviewItems.Columns.Contains("ColumnWidth") && row["ColumnWidth"] != DBNull.Value)
                    {
                        int width;
                        if (int.TryParse(Convert.ToString(row["ColumnWidth"]), out width) && width > 0)
                            spec.Width = width;
                    }
                    spec.Numeric = IsNumericName(name);
                    spec.Date = IsDateName(name);
                    spec.Hidden = string.Equals(name, "ID", StringComparison.OrdinalIgnoreCase);
                    specs.Add(spec);
                }
            }

            if (specs.Count == 0 && table != null)
            {
                foreach (DataColumn column in table.Columns)
                {
                    ListViewColumnSpec spec = new ListViewColumnSpec();
                    spec.MenuName = menuName;
                    spec.ColumnName = column.ColumnName;
                    spec.Header = column.ColumnName;
                    spec.Width = DefaultWidth(column.ColumnName);
                    spec.Numeric = IsNumericType(column.DataType) || IsNumericName(column.ColumnName);
                    spec.Date = column.DataType == typeof(DateTime) || IsDateName(column.ColumnName);
                    spec.Hidden = string.Equals(column.ColumnName, "ID", StringComparison.OrdinalIgnoreCase);
                    specs.Add(spec);
                }
            }

            if (IsSalesMenu(menuName))
                specs = EnsureSalesChargesColumn(specs);

            return specs;
        }

        public static List<ListViewColumnSpec> EnsureSalesChargesColumn(List<ListViewColumnSpec> specs)
        {
            if (specs == null)
                specs = new List<ListViewColumnSpec>();

            bool hasCharges = false;
            int discountIndex = -1;
            int amountIndex = -1;
            for (int i = 0; i < specs.Count; i++)
            {
                if (string.Equals(specs[i].ColumnName, "Charges", StringComparison.OrdinalIgnoreCase))
                    hasCharges = true;
                if (string.Equals(specs[i].ColumnName, "Discount", StringComparison.OrdinalIgnoreCase))
                    discountIndex = i;
                if (string.Equals(specs[i].ColumnName, "Amount", StringComparison.OrdinalIgnoreCase))
                    amountIndex = i;
            }

            if (!hasCharges)
            {
                ListViewColumnSpec charges = new ListViewColumnSpec();
                charges.MenuName = "Sales";
                charges.ColumnName = "Charges";
                charges.Header = "Charges";
                charges.Width = SalesChargesWidth;
                charges.Numeric = true;
                int insertAt = specs.Count;
                if (discountIndex >= 0)
                    insertAt = discountIndex + 1;
                else if (amountIndex >= 0)
                    insertAt = amountIndex;
                specs.Insert(insertAt, charges);
            }

            ApplySalesWidths(specs);
            return specs;
        }

        public static int LayoutSignature(IList<ListViewColumnSpec> columns)
        {
            int hash = 17;
            if (columns == null)
                return hash;
            foreach (ListViewColumnSpec spec in columns)
            {
                hash = unchecked(hash * 31 + (spec.ColumnName == null ? 0 : spec.ColumnName.GetHashCode()));
                hash = unchecked(hash * 31 + spec.Width);
            }
            return hash;
        }

        public static bool IsSalesMenu(string menuName)
        {
            return ContainsText(menuName, "sale");
        }

        public static bool IsCashbookMenu(string menuName)
        {
            return ContainsText(menuName, "cash");
        }

        public static bool IsBalanceMenu(string menuName)
        {
            return ContainsText(menuName, "balance");
        }

        public static void SetColumnWidth(ObjectListView list, string columnName, int width)
        {
            OLVColumn column = FindColumn(list, columnName);
            if (column == null)
                return;
            column.Width = width;
            column.MinimumWidth = width;
        }

        public static void EnsureColumn(ObjectListView list, string columnName, string header, int width, string afterColumn)
        {
            if (list == null)
                return;
            if (FindColumn(list, columnName) != null)
            {
                SetColumnWidth(list, columnName, width);
                return;
            }

            OLVColumn created = new OLVColumn(header, columnName);
            created.Width = width;
            created.AspectGetter = delegate(object model) { return ReadAspect(model, columnName); };
            created.AspectToStringFormat = "{0:" + NumericFormat + "}";
            created.TextAlign = HorizontalAlignment.Right;
            created.IsVisible = true;

            int insertAt = list.AllColumns.Count;
            OLVColumn after = FindColumn(list, afterColumn);
            if (after != null)
                insertAt = list.AllColumns.IndexOf(after) + 1;
            list.AllColumns.Insert(insertAt, created);
            list.RebuildColumns();
        }

        private static void ApplySalesWidths(List<ListViewColumnSpec> specs)
        {
            foreach (ListViewColumnSpec spec in specs)
            {
                if (string.Equals(spec.ColumnName, "Car", StringComparison.OrdinalIgnoreCase))
                    spec.Width = SalesCarWidth;
                else if (string.Equals(spec.ColumnName, "Discount", StringComparison.OrdinalIgnoreCase))
                    spec.Width = SalesDiscountWidth;
                else if (string.Equals(spec.ColumnName, "Charges", StringComparison.OrdinalIgnoreCase))
                    spec.Width = SalesChargesWidth;
                else if (string.Equals(spec.ColumnName, "Paid", StringComparison.OrdinalIgnoreCase)
                    || string.Equals(spec.ColumnName, "PaidAmount", StringComparison.OrdinalIgnoreCase))
                    spec.Width = SalesPaidWidth;
                else if (string.Equals(spec.ColumnName, "PK", StringComparison.OrdinalIgnoreCase))
                    spec.Width = SalesPkWidth;
            }
        }

        private static OLVColumn CreateColumn(ListViewColumnSpec spec)
        {
            string header = string.IsNullOrEmpty(spec.Header) ? spec.ColumnName : spec.Header;
            OLVColumn column = new OLVColumn(header, spec.ColumnName);
            column.Width = spec.Width <= 0 ? 80 : spec.Width;
            column.IsVisible = !spec.Hidden;
            column.AspectGetter = delegate(object model) { return ReadAspect(model, spec.ColumnName); };
            if (spec.Numeric)
            {
                column.AspectToStringFormat = "{0:" + NumericFormat + "}";
                column.TextAlign = HorizontalAlignment.Right;
            }
            else if (spec.Date)
            {
                column.AspectToStringFormat = "{0:" + DateFormat + "}";
            }
            return column;
        }

        private static object ReadAspect(object model, string columnName)
        {
            DataRow row = model as DataRow;
            if (row == null || row.RowState == DataRowState.Deleted || row.RowState == DataRowState.Detached)
                return null;
            if (row.Table == null || !row.Table.Columns.Contains(columnName))
                return null;
            object value = row[columnName];
            if (value == null || value == DBNull.Value)
                return null;
            return value;
        }

        private static IEnumerable RowsOf(DataTable table)
        {
            List<DataRow> rows = new List<DataRow>();
            foreach (DataRow row in table.Rows)
            {
                if (row.RowState == DataRowState.Deleted)
                    continue;
                rows.Add(row);
            }
            return rows;
        }

        private static OLVColumn FindColumn(ObjectListView list, string columnName)
        {
            if (list == null || list.AllColumns == null || string.IsNullOrEmpty(columnName))
                return null;
            foreach (OLVColumn column in list.AllColumns)
            {
                if (column != null && string.Equals(column.AspectName, columnName, StringComparison.OrdinalIgnoreCase))
                    return column;
            }
            return null;
        }

        private static void ApplyNumericFormat(ObjectListView list, params string[] names)
        {
            foreach (string name in names)
            {
                OLVColumn column = FindColumn(list, name);
                if (column == null)
                    continue;
                column.AspectToStringFormat = "{0:" + NumericFormat + "}";
                column.TextAlign = HorizontalAlignment.Right;
            }
        }

        private static int DefaultWidth(string columnName)
        {
            if (string.Equals(columnName, "Car", StringComparison.OrdinalIgnoreCase))
                return SalesCarWidth;
            if (string.Equals(columnName, "Discount", StringComparison.OrdinalIgnoreCase))
                return SalesDiscountWidth;
            if (string.Equals(columnName, "Charges", StringComparison.OrdinalIgnoreCase))
                return SalesChargesWidth;
            if (string.Equals(columnName, "Paid", StringComparison.OrdinalIgnoreCase) || string.Equals(columnName, "PaidAmount", StringComparison.OrdinalIgnoreCase))
                return SalesPaidWidth;
            if (string.Equals(columnName, "PK", StringComparison.OrdinalIgnoreCase))
                return SalesPkWidth;
            if (string.Equals(columnName, "Remark", StringComparison.OrdinalIgnoreCase))
                return 160;
            if (IsDateName(columnName))
                return 90;
            return 100;
        }

        private static bool IsNumericName(string name)
        {
            if (string.IsNullOrEmpty(name))
                return false;
            string[] names = { "Amount", "Paid", "PaidAmount", "Discount", "Charges", "PK", "TotalIncome", "TotalExpense", "ExgRate", "Opening", "Debit", "Credit", "Closing", "ClosingBalance", "Balance", "InQty", "OutQty" };
            foreach (string candidate in names)
            {
                if (string.Equals(candidate, name, StringComparison.OrdinalIgnoreCase))
                    return true;
            }
            return false;
        }

        private static bool IsDateName(string name)
        {
            return string.Equals(name, "Date", StringComparison.OrdinalIgnoreCase);
        }

        private static bool IsNumericType(Type type)
        {
            return type == typeof(decimal) || type == typeof(double) || type == typeof(float)
                || type == typeof(int) || type == typeof(long) || type == typeof(short)
                || type == typeof(byte);
        }

        private static bool MenuEquals(object menuValue, string menuName)
        {
            if (menuValue == null || menuValue == DBNull.Value || string.IsNullOrEmpty(menuName))
                return false;
            return string.Equals(Convert.ToString(menuValue), menuName, StringComparison.OrdinalIgnoreCase);
        }

        private static bool ContainsText(string value, string token)
        {
            if (string.IsNullOrEmpty(value) || string.IsNullOrEmpty(token))
                return false;
            return value.IndexOf(token, StringComparison.OrdinalIgnoreCase) >= 0;
        }

        private static string FirstExisting(DataTable table, params string[] names)
        {
            foreach (string name in names)
            {
                if (table.Columns.Contains(name))
                    return name;
            }
            return null;
        }
    }
}
