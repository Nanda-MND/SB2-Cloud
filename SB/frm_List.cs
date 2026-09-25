using System;
using System.Data;
using System.Windows.Forms;

namespace SB
{
    /// <summary>
    /// Popup list. Uses the same FastListViewHelper as Main history.
    /// </summary>
    public partial class frm_List : Form
    {
        public frm_List()
        {
            InitializeComponent();
            FastListViewHelper.Configure(dlvPopup);
        }

        public static void ShowPopup(IWin32Window owner, string title, DataTable table)
        {
            using (frm_List form = new frm_List())
            {
                form.Text = string.IsNullOrEmpty(title) ? "List" : title;
                form.Bind(table);
                form.ShowDialog(owner);
            }
        }

        public void Bind(DataTable table)
        {
            FastListViewHelper.BindObjectTable(
                dlvPopup,
                table,
                ReferenceDataCache.ListViewColumns(Text, table),
                false);
        }
    }
}
