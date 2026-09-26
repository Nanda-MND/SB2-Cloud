using System.Collections.Generic;
using System.Data;

namespace SB
{
    /// <summary>
    /// ListviewItem column source for the history list.
    /// Call SetListViewItems with dbo.ListviewItem when the ERP cache is loaded.
    /// </summary>
    public static class ReferenceDataCache
    {
        private static DataTable _listViewItems;

        public static void SetListViewItems(DataTable listviewItem)
        {
            _listViewItems = listviewItem;
        }

        public static IList<ListViewColumnSpec> ListViewColumns(string menuName, DataTable boundTable)
        {
            return FastListViewHelper.BuildColumns(menuName, boundTable, _listViewItems);
        }
    }
}
