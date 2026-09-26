using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SB
{
    class Transaction
    {
        private static string m_Location = string.Empty, m_Division = string.Empty, m_Township = string.Empty, m_Customer = string.Empty, m_MainGroup = string.Empty, m_Group = string.Empty, m_Stock = string.Empty;
        private static DateTime m_MaxDate, m_MinDate;
        private static int m_MinAmount = 0, m_MaxAmount = 0;
        public static string Location { get { return m_Location; } set { m_Location = value; } }
        public static string Division { get { return m_Division; } set { m_Division = value; } }
        public static string Township { get { return m_Township; } set { m_Township = value; } }
        public static string Customer { get { return m_Customer; } set { m_Customer = value; } }
        public static string MainGroup { get { return m_MainGroup; } set { m_MainGroup = value; } }
        public static string SubGroup { get { return m_Group; } set { m_Group = value; } }
        public static string Stock { get { return m_Stock; } set { m_Stock = value; } }

        public static DateTime MaxDate { get { return m_MaxDate; } set { m_MaxDate = value; } }

        public static DateTime MinDate { get { return m_MinDate; } set { m_MinDate = value; } }

        public static int MinAmount { get { return m_MinAmount; } set { m_MinAmount = value; } }

        public static int MaxAmount { get { return m_MaxAmount; } set { m_MaxAmount = value; } }

        public static string Filter, ReportFilterName;
        public static void GetFilter(int ReportID)
        {
            string DateFormat = "yyyy-MM-dd";
            ReportFilterName = string.Empty;

            if (ReportID == 1070)
            {
                DateFormat = "yyyy-MM-dd hh:mm:ss tt";
                Filter = " Where ISNULL(H.Deleted,0)<>1 and H.Date between '" + frm_Reports.FDate.ToString(DateFormat) + "' and '" + frm_Reports.TDate.ToString(DateFormat) + "'";
            }
            else if (ReportID == 1161)
            {
                // Sale audit log — filter on ActionDate; no SaleHead.Deleted
                DateFormat = "yyyy-MM-dd";
                Filter = " Where dbo.CastDate(H.ActionDate) between '" + frm_Reports.FDate.ToString(DateFormat) + "' and '" + frm_Reports.TDate.ToString(DateFormat) + "'";
                if (frm_Reports.FilterCustomer != string.Empty)
                    Filter = Filter + " And H.CustomerID in (" + frm_Reports.FilterCustomer.ToString() + ") ";
                if (frm_Reports.FilterLocation != string.Empty)
                    Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                if (frm_Reports.DocumentID != string.Empty)
                    Filter = Filter + " And H.DocumentID = " + frm_Reports.DocumentID.ToString();
                if (frm_Reports.AutoID != string.Empty)
                    Filter = Filter + " And H.AutoID Like '%" + frm_Reports.AutoID.ToString() + "%'";
                return;
            }
            else
            {
                DateFormat = "yyyy-MM-dd";
                Filter = " Where ISNULL(H.Deleted,0)<>1 and dbo.CastDate(H.Date) between '" + frm_Reports.FDate.ToString(DateFormat) + "' and '" + frm_Reports.TDate.ToString(DateFormat) + "'";
            }

            switch (ReportID)
            {
                case 1001:
                case 1002:
                case 1003:
                case 1004:
                case 1006:
                case 1007:
                case 1008:
                case 1009:
                case 1010:
                case 1011:
                case 1070:
                case 1105:
                    #region SalesFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterPayment != string.Empty)
                    {
                        Filter = Filter + " And H.PaymentID in (" + frm_Reports.FilterPayment.ToString() + ") ";
                    }
                    if (frm_Reports.FilterTransport != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.TransportID,-1) in (" + frm_Reports.FilterTransport.ToString() + ") ";
                    }
                    if (frm_Reports.FilterGate != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.GateID,-1) in (" + frm_Reports.FilterGate.ToString() + ") ";
                    }
                    if (frm_Reports.FilterCar != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.CarID,-1) in (" + frm_Reports.FilterCar.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1)  in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterCustomer != string.Empty)
                    {
                        Filter = Filter + " And H.CustomerID in (" + frm_Reports.FilterCustomer.ToString() + ") ";

                    }
                    if (frm_Reports.DocumentID != string.Empty)
                    {
                        Filter = Filter + " And H.DocumentID = " + frm_Reports.DocumentID.ToString();
                    }
                    if (frm_Reports.AutoID != string.Empty)
                    {
                        Filter = Filter + " And H.AutoID Like '%" + frm_Reports.AutoID.ToString() + "%'";
                    }
                    #endregion
                    break;
                case 1005:
                case 1079:
                case 1080:
                    #region InvoiceFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterPayment != string.Empty)
                    {
                        Filter = Filter + " And H.PaymentID in (" + frm_Reports.FilterPayment.ToString() + ") ";
                    }
                    if (frm_Reports.FilterTransport != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.TransportID,-1) in (" + frm_Reports.FilterTransport.ToString() + ") ";
                    }
                    if (frm_Reports.FilterGate != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.GateID,-1) in (" + frm_Reports.FilterGate.ToString() + ") ";
                    }
                    if (frm_Reports.FilterCar != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.CarID,-1) in (" + frm_Reports.FilterCar.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    //if (frm_Reports.FilterStockGroup != string.Empty)
                    //{
                    //    Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    //}
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And H.ID in (Select RefID From SaleDetail D Join Stock S on D.CodeID = S.ID Where S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' )";
                    }
                    //if (frm_Reports.FilterUnit != string.Empty)
                    //{
                    //    Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    //}
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterCustomer != string.Empty)
                    {
                        Filter = Filter + " And H.CustomerID in (" + frm_Reports.FilterCustomer.ToString() + ") ";

                    }
                    if (frm_Reports.DocumentID != string.Empty)
                    {
                        Filter = Filter + " And H.DocumentID = " + frm_Reports.DocumentID.ToString();
                    }
                    if (frm_Reports.AutoID != string.Empty)
                    {
                        Filter = Filter + " And H.AutoID Like '%" + frm_Reports.AutoID.ToString() + "%'";
                    }
                    #endregion
                    break;
                case 1013:
                case 1014:
                case 1015:
                case 1016:
                case 1017:
                case 1110:
                case 1111:
                case 1151:
                case 1152:
                case 1153:
                case 1154:
                case 1155:
                case 1156:
                case 1157:
                    #region PurchaseFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterPayment != string.Empty)
                    {
                        Filter = Filter + " And H.PaymentID in (" + frm_Reports.FilterPayment.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterSupplier != string.Empty)
                    {
                        Filter = Filter + " And H.SupplierID in (" + frm_Reports.FilterSupplier.ToString() + ") ";

                    }
                    if (frm_Reports.DocumentID != string.Empty)
                    {
                        Filter = Filter + " And H.DocumentID like '" + frm_Reports.DocumentID.ToString() + "%'";
                    }
                    if (frm_Reports.AutoID != string.Empty)
                    {
                        Filter = Filter + " And H.AutoID Like '%" + frm_Reports.AutoID.ToString() + "%'";
                    }
                    if (frm_Reports.FilterPurchaseTypeID == 1)
                    {
                        Filter = Filter + " And StockReceived = 1 ";
                    }
                    else if (frm_Reports.FilterPurchaseTypeID == 2)
                    {
                        Filter = Filter + " And StockReceived = 0 ";
                    }
                    #endregion
                    break;
                case 1089:
                case 1090:
                case 1091:
                    #region shipment
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterSupplier != string.Empty)
                    {
                        Filter = Filter + " And H.SupplierID in (" + frm_Reports.FilterSupplier.ToString() + ") ";

                    }
                    if (frm_Reports.DocumentID != string.Empty)
                    {
                        Filter = Filter + " And PH.DocumentID Like '" + frm_Reports.DocumentID.ToString() + "%'";
                    }
                    if (frm_Reports.AutoID != string.Empty)
                    {
                        Filter = Filter + " And PH.AutoID Like '%" + frm_Reports.AutoID.ToString() + "%'";
                    }
                    #endregion

                    break;
                case 1019:
                case 1020:
                    #region StockOpeningFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    #endregion
                    break;
                case 1022:
                case 1023:
                case 1024:
                case 1033:
                    #region CustomerOutstandFilter
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterCustomer != string.Empty)
                    {
                        Filter = Filter + " And H.CustomerID in (" + frm_Reports.FilterCustomer.ToString() + ") ";

                    }
                    #endregion
                    break;
                case 1026:
                case 1027:
                case 1028:
                case 1034:
                    #region SupplierOutstandFilter
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterSupplier != string.Empty)
                    {
                        Filter = Filter + " And H.SupplierID in (" + frm_Reports.FilterSupplier.ToString() + ") ";

                    }
                    #endregion
                    break;
                case 1029:
                case 1030:
                case 1031:
                case 1035:
                case 1081:

                    #region ManufacturerOutstandFilter
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterManufacturer != string.Empty)
                    {
                        Filter = Filter + " And H.ManufacturerID in (" + frm_Reports.FilterManufacturer.ToString() + ") ";

                    }
                    #endregion
                    break;
                case 1073:
                case 1074:
                case 1075:
                case 1076:
                case 1077:
                case 1078:
                case 1106:
                case 1107:
                case 1135:
                case 1136:
                case 1137:
                case 1138:
                case 1139:
                case 1140:
                case 1141:
                    #region Raw/FinishedFilter
                    if (frm_Reports.FilterDivision != string.Empty)
                    {
                        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                    }
                    if (frm_Reports.FilterTownship != string.Empty)
                    {
                        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                    }
                    if (frm_Reports.FilterManufacturer != string.Empty)
                    {
                        Filter = Filter + " And H.ManufacturerID in (" + frm_Reports.FilterManufacturer.ToString() + ") ";

                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    #endregion
                    break;
                //case 1033:
                //case 1034:
                //case 1035:
                //    #region AP/AROpeningFilter
                //    if (frm_Reports.FilterDivision != string.Empty)
                //    {
                //        Filter = Filter + " And Tsp.DivisionID in (" + frm_Reports.FilterDivision.ToString() + ") ";

                //    }
                //    if (frm_Reports.FilterTownship != string.Empty)
                //    {
                //        Filter = Filter + " And Tsp.ID in (" + frm_Reports.FilterTownship.ToString() + ") ";

                //    }
                //    if (frm_Reports.FilterManufacturer != string.Empty)
                //    {
                //        Filter = Filter + " And H.ManufacturerID in (" + frm_Reports.FilterManufacturer.ToString() + ") ";

                //    }
                //    #endregion
                //    break;
                case 1041:
                case 1042:
                case 1043:
                case 1044:
                case 1045:
                case 1046:
                case 1047:
                case 1048:
                case 1049:
                case 1058:
                case 1059:
                case 1060:
                case 1061:
                case 1062:
                case 1063:
                case 1064:
                case 1065:
                case 1066:
                    #region StockFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.LocationID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterPayment != string.Empty)
                    {
                        Filter = Filter + " And H.PaymentID in (" + frm_Reports.FilterPayment.ToString() + ") ";
                    }
                    if (frm_Reports.FilterTransport != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.TransportID,-1) in (" + frm_Reports.FilterTransport.ToString() + ") ";
                    }
                    if (frm_Reports.FilterGate != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.GateID,-1) in (" + frm_Reports.FilterGate.ToString() + ") ";
                    }
                    if (frm_Reports.FilterCar != string.Empty)
                    {
                        Filter = Filter + " And isnull(H.CarID,-1) in (" + frm_Reports.FilterCar.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    #endregion
                    break;
                case 1052:
                case 1053:
                case 1054:
                case 1055:
                case 1056:
                case 1057:
                    #region StockTransferFilter
                    if (frm_Reports.FilterLocation != string.Empty)
                    {
                        Filter = Filter + " And H.FromLocID in (" + frm_Reports.FilterLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterToLocation != string.Empty)
                    {
                        Filter = Filter + " And H.ToLocID in (" + frm_Reports.FilterToLocation.ToString() + ")";
                    }
                    if (frm_Reports.FilterStockType != string.Empty)
                    {
                        Filter = Filter + " And SG.TypeID in (" + frm_Reports.FilterStockType.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStockGroup != string.Empty)
                    {
                        Filter = Filter + " And S.GroupID in (" + frm_Reports.FilterStockGroup.ToString() + ") ";
                    }
                    if (frm_Reports.FilterStock != string.Empty)
                    {
                        Filter = Filter + " And S.Short Like '" + frm_Reports.FilterStock.ToString() + "%' ";
                    }
                    if (frm_Reports.FilterUnit != string.Empty)
                    {
                        Filter = Filter + " And D.UnitID in (" + frm_Reports.FilterUnit.ToString() + ") ";

                    }
                    if (frm_Reports.FilterBrand != string.Empty)
                    {
                        Filter = Filter + " And isnull(D.BrandID,-1) in (" + frm_Reports.FilterBrand.ToString() + ") ";
                    }
                    #endregion
                    break;
                case 1037:
                case 1038:
                case 1039:
                case 1040:
                    if (frm_Reports.FilterSign != "All")
                    {
                        decimal Qty;
                        decimal.TryParse(frm_Reports.FilterQty.ToString(), out Qty);
                        Filter = " Where (isnull(Qty1,0)  " + frm_Reports.FilterSign.ToString() + Qty.ToString() + " or isnull(Qty2, 0)  " + frm_Reports.FilterSign.ToString() + Qty.ToString() + " or isnull(Qty3, 0)  " + frm_Reports.FilterSign.ToString() + Qty.ToString() + ") ";
                    }
                    else
                    {
                        Filter = " Where 1 = 1 ";
                    }
                    break;
                case 1050:
                case 1051:
                    if (frm_Reports.FilterSign != "All")
                    {
                        decimal Qty;
                        decimal.TryParse(frm_Reports.FilterQty.ToString(), out Qty);
                        Filter = " Where Type ='4.Closing' and isnull(Qty,0) " + frm_Reports.FilterSign.ToString() + Qty.ToString();
                    }
                    else
                    {
                        Filter = " Where 1 = 1 ";
                    }
                    break;
                case 1144:
                    DateFormat = "yyyy-MM-dd";
                    Filter = " Where ISNULL(H.Deleted,0)<>1 and CashbookTypeID = 2  and dbo.CastDate(H.Date) between '" + frm_Reports.FDate.ToString(DateFormat) + "' and '" + frm_Reports.TDate.ToString(DateFormat) + "'";
                    if (frm_Reports.AcctiD != -1)
                    {
                        Filter = Filter + " and H.ID in ( Select RefID From IncomeExpenseDetail Where DetailAccountID = " + frm_Reports.AcctiD.ToString() + ")";
                    }
                    break;
                case 1162:
                    // Foreign Currency Ledger — IncomeExpense (IE / Journal / Supplier Payment / …)
                    DateFormat = "yyyy-MM-dd";
                    Filter = " Where ISNULL(H.Deleted,0)<>1 and dbo.CastDate(H.Date) between '" + frm_Reports.FDate.ToString(DateFormat) + "' and '" + frm_Reports.TDate.ToString(DateFormat) + "'";
                    break;
                default:
                    break;
            }




        }

        public static Boolean CheckLogDay( DateTime date)
        {

            Boolean valid = false;

            if (date> MaxDate || date<MinDate)
            {
                valid = false;
            }
            else
            {
                valid = true;
            }
            return valid;
        
        }
    }
}
