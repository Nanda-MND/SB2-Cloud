using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using CrystalDecisions.CrystalReports.Engine;
using System.Data.SqlClient;

namespace SB
{
    public partial class frm_Preview : Form
    {
        int ReportID;
        ReportDocument rd = new ReportDocument();
        public frm_Preview(int p_ID)
        {
            ReportID = p_ID;
            InitializeComponent();
        }

        private void frm_Preview_Load(object sender, EventArgs e)
        {
            ReportDocument rd = new ReportDocument();
            switch (ReportID)
            {
                case 1:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Voucher.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Location = L.Short,Sr,  Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, D.Amount, Qty1 = isnull(Qty1,0), TotalWeight, AddAmount = ISNULL(H.AddAmount,0), TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), NetAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID   Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 2:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Invoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = Trim(S.Name), Brand = B.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, DtRemark = D.Remark, HAmount = H.Amount, Balance = isnull(Balance,0) - isnull(AdvBalance,0),  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark, Users = US.Short, PaymentID from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID Join Users US on UserID = US.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));
                    
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    DBConnection.ExecSQL("Update SaleHead Set Printed = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    break;
                case 3:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PanSar.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1, Info2, Gate = G.Name, Car = Cr.Name,GateID, Transport = T.Name, Qty = dbo.TransportQty(H.ID), MyanText = dbo.GetNumToMyan1(dbo.TransportQty(H.ID))  from SaleHead H Join Customer C on H.CustomerID = C.ID Left Join Gates G on  H.GateID = G.ID Left join Cars Cr on H.CarID = Cr.ID Join  Transport T on H.TransportID = T.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    DBConnection.ExecSQL("Update SaleHead Set PanSar = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    break;
                case 4:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\OrderInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, TotalMinQty, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark from SaleOrderHead H Join SaleOrderDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID    Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 5:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Issue_Voucher.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, DtRemark = D.Remark, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount,  TotalBalance, H.Remark, Users = US.Name, Township = Tsp.Name, Transport = TP.Name, PaymentID, QRID = 0 from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID Join Users US on UserID = US.ID Join Township Tsp on TownshipID = Tsp.ID Left Join Transport TP on H.TransportID = TP.ID Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;

                    break;
                case 6:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Transfer_Voucher.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, FromLoc = LL.Short,  Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty1, Qty2, Qty, DRemark = D.Remark,  H.Remark from TransferHead H Join TransferDetail D on H.ID = D.RefID Join Location LL  on H.FromLocID = LL.ID Join Location L on H.ToLocID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID  Where H.ID = " + frm_Transfer.PrintID.ToString()));

                    crvPreview.ReportSource = rd;

                    break;
                case 7:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PanSar_Logo.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1, Info2, Gate = G.Name, Car = Cr.Name,GateID, Transport = T.Name, Qty = dbo.TransportQty(H.ID), MyanText = dbo.GetNumToMyan1(dbo.TransportQty(H.ID))  from SaleHead H Join Customer C on H.CustomerID = C.ID Left Join Gates G on  H.GateID = G.ID Left join Cars Cr on H.CarID = Cr.ID Join  Transport T on H.TransportID = T.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    crvPreview.ReportSource = rd;
                    DBConnection.ExecSQL("Update SaleHead Set PanSar = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    break;
                case 8:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\CashReceipt.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select Top 1 H.ID, Date, DocumentID, AutoID, Account = AN.Name, Customer = C.Name, H.Remark, Debit = Cast(Round(D.Debit,0) as int), AmountText = dbo.GetNumToMyan2(D.Debit) + N' ကျပ်တိတိ' from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join AccountName AN on H.AccountID = AN.ID Join Customer C on SourceID = C.ID where CashbookTypeID = 3 and H.ID =  " + frm_IncomeExpense.PrintID.ToString()));

                    crvPreview.ReportSource = rd;
                    break;
                case 1001:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByCustSum.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select C.Name, Payment= P.Name, Type = (Case When H.PaymentID = 4 then A.Name Else P.Name End), TotalAmount = sum(TotalAmount), PaymentID from SaleHead  H Join PaymentType P on H.PaymentID = P.ID Join Customer C on H.CustomerID = C.ID Left Join AccountName A on H.AccountID = A.ID Join Township Tsp on C.TownshipID = Tsp.ID  ";
                    LocalData.GroupBy = " Group by C.Name, A.Name, P.Name, H.PaymentID ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Customer Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1003:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1004:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1, Qty2, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID Join Township Tsp on C.TownshipID = Tsp.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price, Qty1, Qty2 ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy ));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1005:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    //rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    //rd.SetParameterValue("Header", "Sales By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1006:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SalesByEachCustomer.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Township = Tsp.Name, Location = L.Short, Payment = P.Name, TotalAmount, PaidAmount, H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID  ";
                    LocalData.GroupBy = " group by H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Tsp.Name,  L.Short,  P.Name, TotalAmount, PaidAmount, H.Remark   ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Each Customer Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1008:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByCustSum.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select SG.Name ,Type = P.Name, TotalAmount = sum(D.Amount) from SaleHead  H Join PaymentType P on H.PaymentID = P.ID Join SaleDetail D on H.ID = D.RefID Join Stock S on CodeID = S.ID Join StockGroup SG on GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by SG.Name, P.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Category Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1009:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SalesByAmount.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date = dbo.CastDate(Date), P.Name, TotalAmount = sum(TotalAmount) from SaleHead  H Join PaymentType P on H.PaymentID = P.ID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID ";
                    LocalData.GroupBy = " Group By dbo.CastDate(Date),P.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Amount Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1010:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemMonthly.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select GroupName = SG.Name, Stock = S.Name,  Date = DATENAME(MM,Date), Sort =DATEPART(MM,Date), Qty = dbo.GetQtyinUnitRelation(CodeID, sum(dbo.GetMinQty(CodeID, UnitID, Qty))) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Stock S on CodeID = S.ID Join  StockGroup SG on  S.GroupID = SG.ID  ";
                    LocalData.GroupBy = " Group By SG.Name, S.Name, CodeID, DATENAME(MM, Date),DATEPART(MM, Date) ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and SG.ID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Item Monthly Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1011:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItem.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select GroupID = SG.Short + '-' +SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = dbo.GetQtyinUnitRelation(CodeID, sum(dbo.GetMinQty(CodeID, UnitID, Qty))),  Amount = sum( D.Amount ) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by  SG.Short, SG.Name, D.CodeID, S.Short, S.Name, B.Short ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Item Total Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1013:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseBySupplierSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by  C.Name, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1014:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseBySupplierDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Name, Date, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  C.Name, Date, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase By Supplier Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1015:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1016:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1, Qty2, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price, Qty1, Qty2 ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1017:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short, Payment = P.Name,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, H.Remark, DRemark = D.Remark from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID ";
                    LocalData.GroupBy = " Order by Sr ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1019:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum(D.Amount) from StockOpeningHead H Join StockOpeningDetail D on H.ID = D.RefID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by   S.Short, S.Name, B.Short, U.Name, Price";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Opening Stock By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1020:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseBySupplierSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = L.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from StockOpeningHead H Join StockOpeningDetail D on H.ID = D.RefID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID   ";
                    LocalData.GroupBy = " Group by  L.Name, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Opening Stock By Supplier Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1023:
                    SqlParameter[] COarg = new SqlParameter[6];
                    COarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); COarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    COarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); COarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    COarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); COarg[2].Value = frm_Reports.FilterDivision;
                    COarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); COarg[3].Value = frm_Reports.FilterTownship;
                    COarg[4] = new SqlParameter("@Customer", SqlDbType.NVarChar); COarg[4].Value = frm_Reports.FilterCustomer;
                    COarg[5] = new SqlParameter("@UserID", SqlDbType.Int); COarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("CustomerOutstand", COarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\CustomerOutstand.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select *, Type = 1 from dbo.CustomerOutstandHistory (" + LocalData.UserID.ToString() + ") Where Opening <> 0 or Closing <> 0  order by Closing desc";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query ));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Customer Outstand Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1024:
                    SqlParameter[] CBarg = new SqlParameter[6];
                    CBarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); CBarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    CBarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); CBarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    CBarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); CBarg[2].Value = frm_Reports.FilterDivision;
                    CBarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); CBarg[3].Value = frm_Reports.FilterTownship;
                    CBarg[4] = new SqlParameter("@Customer", SqlDbType.NVarChar); CBarg[4].Value = frm_Reports.FilterCustomer;
                    CBarg[5] = new SqlParameter("@UserID", SqlDbType.Int); CBarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("CustomerBalanceDetail", CBarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\CustomerBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Customer Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1026:
                    SqlParameter[] SOarg = new SqlParameter[6];
                    SOarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); SOarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    SOarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); SOarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    SOarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); SOarg[2].Value = frm_Reports.FilterDivision;
                    SOarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); SOarg[3].Value = frm_Reports.FilterTownship;
                    SOarg[4] = new SqlParameter("@Supplier", SqlDbType.NVarChar); SOarg[4].Value = frm_Reports.FilterSupplier;
                    SOarg[5] = new SqlParameter("@UserID", SqlDbType.Int); SOarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("SupplierOutstand", SOarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\CustomerOutstand.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LedgerName, Opening, Sales = Purchase, SaleReturn = PurchaseReturn, Payment, AcctTransfer, Closing, Type = 2 from dbo.SupplierOutstandHistory (" + LocalData.UserID.ToString() + ") Where Closing <> 0 order by Closing desc";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Supplier Outstand Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1028:
                    SqlParameter[] Suparg = new SqlParameter[4];
                    Suparg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); Suparg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    Suparg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); Suparg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    Suparg[2] = new SqlParameter("@Supplier", SqlDbType.NVarChar); Suparg[2].Value = frm_Reports.FilterSupplier;
                    Suparg[3] = new SqlParameter("@UserID", SqlDbType.Int); Suparg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("SupplierBalanceDetail", Suparg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\FactoryBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Supplier Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1029:
                    SqlParameter[] MOarg = new SqlParameter[6];
                    MOarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); MOarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    MOarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); MOarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    MOarg[2] = new SqlParameter("@Division", SqlDbType.NVarChar); MOarg[2].Value = frm_Reports.FilterDivision;
                    MOarg[3] = new SqlParameter("@Township", SqlDbType.NVarChar); MOarg[3].Value = frm_Reports.FilterTownship;
                    MOarg[4] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); MOarg[4].Value = frm_Reports.FilterManufacturer;
                    MOarg[5] = new SqlParameter("@UserID", SqlDbType.Int); MOarg[5].Value = LocalData.UserID;

                    DBConnection.ExecSp("ManufacturerOutstand", MOarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\CustomerOutstand.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LedgerName, Opening, Sales = FinishedGood, SaleReturn = 0, Payment, Closing, Type = 3 from dbo.ManufacturerOutstandHistory (" + LocalData.UserID.ToString() + ")";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Supplier Outstand Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1030:
                    SqlParameter[] Fctarg = new SqlParameter[4];
                    Fctarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); Fctarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    Fctarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); Fctarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    Fctarg[2] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); Fctarg[2].Value = frm_Reports.FilterManufacturer;
                    Fctarg[3] = new SqlParameter("@UserID", SqlDbType.Int); Fctarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("FactoryBalanceDetail", Fctarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\FactoryBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacturer Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1033:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\aparOpeningByID.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name,  Sr , D.Amount, TotalAmount = H.Amount, H.Remark from CustomerOpeningHead H Join CustomerOpeningDetail D on H.ID = D.RefID Join Customer C on D.CustomerID = C.ID  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query  + LocalData.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Customer Opening Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1034:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\aparOpeningByID.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name,  Sr , D.Amount, TotalAmount = H.Amount, H.Remark from SupplierOpeningHead H Join SupplierOpeningDetail D on H.ID = D.RefID Join Supplier C on D.SupplierID = C.ID  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + LocalData.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Supplier Opening Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1035:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\aparOpeningByID.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name,  Sr , D.Amount, TotalAmount = H.Amount, H.Remark from ManufacturerOpeningHead H Join ManufacturerOpeningDetail D on H.ID = D.RefID Join Manufacturer C on D.ManufacturerID = C.ID  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + LocalData.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacturer Opening Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1037:
                    SqlParameter[] argSB = new SqlParameter[7];
                    argSB[0] = new SqlParameter("@UserID", SqlDbType.Int); argSB[0].Value = LocalData.UserID;
                    argSB[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argSB[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argSB[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argSB[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argSB[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argSB[3].Value = frm_Reports.FilterStock;
                    argSB[4] = new SqlParameter("@GroupID", SqlDbType.Int); argSB[4].Value = -1;
                    argSB[5] = new SqlParameter("@TypeID", SqlDbType.Int); argSB[5].Value = -1;
                    argSB[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argSB[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockBalance", argSB);
                    SqlParameter[] tmp = new SqlParameter[1];
                    tmp[0] = new SqlParameter("@UserID", SqlDbType.Int); tmp[0].Value = LocalData.UserID;
                    DBConnection.ExecSp("UpdateStockStatusUnit", tmp);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockBalance.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select L.Short,Code = S.Short, Stock = S.Name, Brand = B.Name, Qty1, Unit1, Qty2, Unit2, Qty3, Unit3 from StockStatus SB Join Stock S on SB.CodeID = S.ID Join Location L on SB.LocationID = L.ID Left Join Brand B on SB.BrandID = B.ID ";
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock Balance Report");

                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1038:
                    SqlParameter[] argSVG = new SqlParameter[7];
                    argSVG[0] = new SqlParameter("@UserID", SqlDbType.Int); argSVG[0].Value = LocalData.UserID;
                    argSVG[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argSVG[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argSVG[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argSVG[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argSVG[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argSVG[3].Value = frm_Reports.FilterStock;
                    argSVG[4] = new SqlParameter("@GroupID", SqlDbType.Int); argSVG[4].Value = -1;
                    argSVG[5] = new SqlParameter("@TypeID", SqlDbType.Int); argSVG[5].Value = -1;
                    argSVG[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argSVG[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockValuationFIFO_Ground", argSVG);

                    SqlParameter[] argSVG1 = new SqlParameter[1];
                    argSVG1[0] = new SqlParameter("@UserID", SqlDbType.Int); argSVG1[0].Value = LocalData.UserID;
 
                    DBConnection.ExecSp("UpdateStockStatusUnit", argSVG1);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockValuation.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LocationID, Loc = '', Category = SG.Name, Code = S.Short, S.Name,Brand = '' , CodeID, BrandID, Qty , Qty1, Unit1, Qty2, Unit2, Qty3, Unit3, stdprice = dbo.GetSTDPurPrice(CodeID, Price), Amount = Price * Qty from StockStatus SS Join Stock S on CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock Valuation (Ground Stock) Report");

                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1039:
                    SqlParameter[] argSV = new SqlParameter[7];
                    argSV[0] = new SqlParameter("@UserID", SqlDbType.Int); argSV[0].Value = LocalData.UserID;
                    argSV[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argSV[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argSV[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argSV[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argSV[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argSV[3].Value = frm_Reports.FilterStock;
                    argSV[4] = new SqlParameter("@GroupID", SqlDbType.Int); argSV[4].Value = -1;
                    argSV[5] = new SqlParameter("@TypeID", SqlDbType.Int); argSV[5].Value = -1;
                    argSV[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argSV[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockValuationFIFO", argSV);

                    SqlParameter[] argSV1 = new SqlParameter[1];
                    argSV1[0] = new SqlParameter("@UserID", SqlDbType.Int); argSV1[0].Value = LocalData.UserID;

                    DBConnection.ExecSp("UpdateStockStatusUnit", argSV1);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockValuation.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LocationID, Loc = L.Short, Category = SG.Name, Code = S.Short, S.Name,Brand = (Case When isnull(SS.BrandID,-1) = -1 Then 'None' Else B.Name End) , CodeID, BrandID, Qty , Qty1, Unit1, Qty2, Unit2, Qty3, Unit3, stdprice = dbo.GetSTDPurPrice(CodeID, Price), Amount = Price * Qty from StockStatus SS Join Stock S on CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID Join Location L on LocationID = L.ID Left Join Brand B on BrandID = B.ID ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock Valuation (All Stocks) Report");

                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1040:
                    SqlParameter[] argSBWB = new SqlParameter[7];
                    argSBWB[0] = new SqlParameter("@UserID", SqlDbType.Int); argSBWB[0].Value = LocalData.UserID;
                    argSBWB[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argSBWB[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argSBWB[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argSBWB[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argSBWB[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argSBWB[3].Value = frm_Reports.FilterStock;
                    argSBWB[4] = new SqlParameter("@GroupID", SqlDbType.NVarChar); argSBWB[4].Value = frm_Reports.FilterStockGroup;
                    argSBWB[5] = new SqlParameter("@TypeID", SqlDbType.NVarChar); argSBWB[5].Value = frm_Reports.FilterStockType;
                    argSBWB[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argSBWB[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockBalance_WithoutBrand", argSBWB);
                    SqlParameter[] tmp1 = new SqlParameter[1];
                    tmp1[0] = new SqlParameter("@UserID", SqlDbType.Int); tmp1[0].Value = LocalData.UserID;
                    DBConnection.ExecSp("UpdateStockStatusUnit", tmp1);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockBalanceWithoutBrand.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Qty1, Unit1, Qty2, Unit2, Qty3, Unit3 from StockStatus SB Join Stock S on SB.CodeID = S.ID   ";
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock Balance (Without Brand) Report");

                    crvPreview.ReportSource = rd;
                    break;
                case 1046:
                    SqlParameter[] TTarg = new SqlParameter[2];
                    TTarg[0] = new SqlParameter("@ToDate", SqlDbType.DateTime); TTarg[0].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    TTarg[1] = new SqlParameter("@UserID", SqlDbType.Int); TTarg[1].Value = LocalData.UserID;

                    DBConnection.ExecSp("TitanBalance", TTarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\TitanBalance.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, AccountName, LedgerName,  Balance from GeneralLedgerDetail  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Titan Balance Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1049:
                    SqlParameter[] Rawarg = new SqlParameter[4];
                    Rawarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); Rawarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    Rawarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); Rawarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    Rawarg[2] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); Rawarg[2].Value = frm_Reports.FilterManufacturer;
                    Rawarg[3] = new SqlParameter("@UserID", SqlDbType.Int); Rawarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("RawBalanceDetail", Rawarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Raw Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1050:
                    SqlParameter[] argIO = new SqlParameter[7];
                    argIO[0] = new SqlParameter("@UserID", SqlDbType.Int); argIO[0].Value = LocalData.UserID;
                    argIO[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argIO[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argIO[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argIO[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argIO[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argIO[3].Value = frm_Reports.FilterStock;
                    argIO[4] = new SqlParameter("@GroupID", SqlDbType.Int); argIO[4].Value = -1;
                    argIO[5] = new SqlParameter("@TypeID", SqlDbType.Int); argIO[5].Value = -1;
                    argIO[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argIO[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockInOutSummary", argIO);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockInOutSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select L.Short, Stock = S.Name, Brand = isnull(B.Name, 'None'), Type, Trans, Qty = dbo.GetQtyinUnitRelation(CodeID, Qty)  from StockinoutBalance SB Join Stock S on SB.CodeID = S.ID Join Location L on SB.LocID = L.ID Left Join Brand B on SB.BrandID = B.ID ";
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock In/Out Summary Report");

                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;  
                case 1051:
                    SqlParameter[] argIOD = new SqlParameter[7];
                    argIOD[0] = new SqlParameter("@UserID", SqlDbType.Int); argIOD[0].Value = LocalData.UserID;
                    argIOD[1] = new SqlParameter("@FDate", SqlDbType.DateTime); argIOD[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argIOD[2] = new SqlParameter("@TDate", SqlDbType.DateTime); argIOD[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argIOD[3] = new SqlParameter("@Code", SqlDbType.NVarChar); argIOD[3].Value = frm_Reports.FilterStock;
                    argIOD[4] = new SqlParameter("@GroupID", SqlDbType.Int); argIOD[4].Value = -1;
                    argIOD[5] = new SqlParameter("@TypeID", SqlDbType.Int); argIOD[5].Value = -1;
                    argIOD[6] = new SqlParameter("@Location", SqlDbType.NVarChar); argIOD[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("StockInOutDetail", argIOD);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockInOutDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select L.Short, Date = dbo.CastDate(Date), Stock = S.Name, Brand = isnull(B.Name, 'None'), Type, Trans, Qty = dbo.GetQtyinUnitRelation(CodeID, Sum(Qty))  from StockinoutBalance SB Join Stock S on SB.CodeID = S.ID Join Location L on SB.LocID = L.ID Left Join Brand B on SB.BrandID = B.ID ";
                    LocalData.GroupBy = " Group by L.Short, dbo.CastDate(Date), S.Name, CodeID, B.Name, Type, Trans ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and UserID = " + LocalData.UserID.ToString() + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Stock In/Out Detail Report");

                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1053:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\TransferByLocationSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Short + ' --->> ' + L.Short, C.SortID, ToSortID = L.SortID, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from TransferHead H Join TransferDetail D on H.ID = D.RefID Join Location C on H.FromLocID = C.ID join Location L on H.ToLocID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  C.Short, L.Short, C.SortID, L.SortID, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Tranfer By Location Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1054:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\TransferByLocationDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Short + ' --->> ' + L.Short, C.SortID, ToSortID = L.SortID, Date, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from TransferHead H Join TransferDetail D on H.ID = D.RefID Join Location C on H.FromLocID = C.ID join Location L on H.ToLocID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  C.Short, L.Short, C.SortID, L.SortID, Date, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Tranfer By Location Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1057:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\TransferByEachInv.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, FromLocation= C.Name, ToLocation= L.Name, HRemark = H.remark, Sr, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty , Unit = U.Name, Price, D.Amount, D.remark from TransferHead H Join TransferDetail D on H.ID = D.RefID Join Location C on H.FromLocID = C.ID join Location L on H.ToLocID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by  H.ID, Date, AutoID, DocumentID, C.Name, L.Name, H.Remark, Sr, S.Short, S.Name, B.Short, U.Name, Qty, Price, D.Amount, D.Remark ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Tranfer By Location Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1062:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AdjustmentByLocationSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select L.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Type = T.Name, Price, Amount = sum( D.Amount )  from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join AdjustType T on D.AdjustTypeID = T.ID  ";
                    LocalData.GroupBy = " Group by  L.Name,  S.Short, S.Name, B.Short, U.Name, Price, T.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Adjustment By Location Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1063:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AdjustmentByLocationDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select L.Name, Code = S.Short, Date,  Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Type = T.Name, Price, Amount = sum( D.Amount )  from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join AdjustType T on D.AdjustTypeID = T.ID  ";
                    LocalData.GroupBy = " Group by  L.Name, Date, S.Short, S.Name, B.Short, U.Name, Price, T.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Adjustment By Location Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1064:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AdjustmentByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ), AdjType = AT.Name from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Left Join AdjustType AT on D.AdjustTypeID = AT.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price, AT.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Adjustment By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1065:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AdjustmentByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date,Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) , AdjType = AT.Name from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID  Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID Left Join AdjustType AT on D.AdjustTypeID = AT.ID ";
                    LocalData.GroupBy = " Group by Date,  L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price, AT.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Adjustment By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1066:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AdjustmentByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price,  D.Amount,  TotalAmount, H.Remark , AdjType = AT.Name from AdjustmentHead H Join AdjustmentDetail D on H.ID = D.RefID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Left Join AdjustType AT on D.AdjustTypeID = AT.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Adjustment By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1068:
                    SqlParameter[] arg = new SqlParameter[5];
                    arg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); arg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    arg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); arg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    arg[2] = new SqlParameter("@AccountID", SqlDbType.Int); arg[2].Value = frm_Reports.AcctiD;
                    arg[3] = new SqlParameter("@UserID", SqlDbType.Int); arg[3].Value = LocalData.UserID;
                    arg[4] = new SqlParameter("@CurrencyID", SqlDbType.Int); arg[4].Value = -1;

                    DBConnection.ExecSp("GeneralLedgerDetailReport", arg);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\GeneralLedgerDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select * from GeneralLedgerDetail Where UserID =  " + LocalData.UserID.ToString() + frm_Reports.GlAccountCodeFilterSql();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "General Ledger Detail Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1069:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\BankClosing.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select * from dbo.GetAcctClosingSummary('" + frm_Reports.TDate.ToString("yyyy-MM-dd") + "', 48, 0)"));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Banks Balance Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1070:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\DailyTranportCharges.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select  H.ID, Date, Customer = C.Name, Location = L.Name, DocumentID, H.Remark, Transport = T.Name, Gates = G.Name, Cars = Cr.Name, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Unit U on D.UnitID = U.ID Left Join Transport T on H.TransportID = T.ID Left Join Gates G on H.GateID = G.ID Left Join Cars Cr on H.CarID = Cr.ID ";
                    LocalData.GroupBy = " Group by H.ID, Date, C.Name, L.Name, DocumentID, H.Remark, T.Name, G.Name, Cr.Name, U.Name, Price ";
                    Transaction.GetFilter(ReportID);

                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " And CodeID = 9950 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Daily Transport Charges Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1071:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PkgSalesSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "Select * from dbo.TransportSummary('"+ frm_Reports.FDate.ToString("yyyy-MM-dd")+"', '" + frm_Reports.TDate.ToString("yyyy-MM-dd") + "') ";
                    //LocalData.GroupBy = " Group by H.ID, Date, C.Name, L.Name, H.Remark, T.Name, G.Name, Cr.Name, U.Name, Price ";
                    //Transaction.GetFilter(ReportID);
                    rd.Subreports[0].Database.Tables[0].SetDataSource(DBConnection.GetSQLTable("select TypeID, P.Name, Amount = Sum(D.Amount)  from SaleHead H Join SaleDetail D on H.ID = D.RefID Join PaymentType P on H.PaymentID = P.ID   Where isnull(H.Deleted,0)<>1 and dbo.CastDate(Date) Between '" + frm_Reports.FDate.ToString("yyyy-MM-dd") + "' and '" + frm_Reports.TDate.ToString("yyyy-MM-dd")+"' Group By TypeID, P.Name"));
                    rd.Database.Tables[0].SetDataSource(DBConnection.GetSQLTable(LocalData.Query ));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Daily Transport and Amount Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1073:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\FinishGoodByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short, Payment = P.Name,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, D.TotalWeight, D.Amount, WeightBalance , HTotalWeight =  H.TotalWeight, CurrentWeightBalance,  HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, H.Remark  from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Left Join PaymentType P on H.PaymentID = P.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1074:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1075:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, S.Short, S.Name, B.Short, U.Name, Price, SG.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1077:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Raw Issue By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1078:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, S.Short, S.Name, B.Short, U.Name, Price, SG.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Raw Issue By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1079:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\StockIssue.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    //rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    //rd.SetParameterValue("Header", "Sales By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1080:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByInvoiceA4.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1081:
                    SqlParameter[] RawSumarg = new SqlParameter[4];
                    RawSumarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); RawSumarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    RawSumarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); RawSumarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    RawSumarg[2] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); RawSumarg[2].Value = frm_Reports.FilterManufacturer;
                    RawSumarg[3] = new SqlParameter("@UserID", SqlDbType.Int); RawSumarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("RawBalanceSummary", RawSumarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Raw Balance Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1082:
                    SqlParameter[] TTSumarg = new SqlParameter[4];
                    TTSumarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); TTSumarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    TTSumarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); TTSumarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    TTSumarg[2] = new SqlParameter("@Location", SqlDbType.NVarChar); TTSumarg[2].Value = frm_Reports.FilterLocation;
                    TTSumarg[3] = new SqlParameter("@UserID", SqlDbType.Int); TTSumarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("TitanBalanceDetail", TTSumarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Titan Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1084:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID= '', C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark from SaleReturnHead H Join SaleReturnDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    //rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    //rd.SetParameterValue("Header", "Sales By Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1085:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from SaleReturnHead H Join SaleReturnDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales Return By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1086:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark,Sr, Category= SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1, Qty2, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from SaleReturnHead H Join SaleReturnDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark,Sr,SG.Name, S.Short, S.Name, B.Short, U.Name, Price, Qty1, Qty2 ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales Return By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;

                case 1087:
                    SqlParameter[] RCarg = new SqlParameter[5];
                    RCarg[0] = new SqlParameter("@ToDate", SqlDbType.DateTime); RCarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    RCarg[1] = new SqlParameter("@Division", SqlDbType.NVarChar); RCarg[1].Value = frm_Reports.FilterDivision;
                    RCarg[2] = new SqlParameter("@Township", SqlDbType.NVarChar); RCarg[2].Value = frm_Reports.FilterTownship;
                    RCarg[3] = new SqlParameter("@Supplier", SqlDbType.NVarChar); RCarg[3].Value = frm_Reports.FilterSupplier;
                    RCarg[4] = new SqlParameter("@UserID", SqlDbType.Int); RCarg[4].Value = LocalData.UserID;

                    DBConnection.ExecSp("ReceivableStockCal", RCarg);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ReceivableStockBySupplierSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, DocumentID, SP.Name, ExgRate, Code = S.Short, Stock = S.Name, Qty, Unit= U.Name, Price, Amount = Price * Qty, Qty1, Qty2 from StockStatus SS Join Supplier SP on LocationID = SP.ID Join Stock S on SS.CodeID = S.ID Join Unit U on UnitID = U.ID where UserID = " + LocalData.UserID.ToString();
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query ));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Receivable Purchased Stock By Supplier Summary Report");
                    ////rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1089:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ShipmentBySupplierSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Name, DocumentID= isnull(PH.DocumentID,PH.AutoID), Code = S.Short, Stock = S.Name, Qty1 = Sum(Qty1), Qty2 = Max(Qty2), Qty = Sum(Qty),  Unit = U.Name from  StockReceiveHead H Join StockReceiveDetail D on H.ID = D.refID Join PurchaseHead PH on D.PurchaseID = PH.ID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group By C.Name, PH.DocumentID, PH.AutoID, S.Short, S.Name, U.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Shipment By Supplier Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1090:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ShipmentBySupplierDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Name = C.Name, DocumentID= isnull(PH.DocumentID,PH.AutoID), H.Date, Code = S.Short, Stock = S.Name, Qty1 = Sum(Qty1), Qty2 = Max(Qty2), Qty = Sum(Qty),  Unit = U.Name from  StockReceiveHead H Join StockReceiveDetail D on H.ID = D.refID Join PurchaseHead PH on D.PurchaseID = PH.ID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID ";
                    LocalData.GroupBy = " Group By C.Name, PH.DocumentID, H.Date, PH.AutoID, S.Short, S.Name, U.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Shipment By Supplier Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1091:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ShipmentByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select  H.ID, Location = L.Name, Name = C.Name, DocumentID= isnull(H.DocumentID,H.AutoID), H.Date, H.Remark, Sr, Code = S.Short, Stock = S.Name, Qty1 = Sum(Qty1), Qty2 = Max(Qty2), Qty = Sum(Qty),  Unit = U.Name from  StockReceiveHead H Join StockReceiveDetail D on H.ID = D.refID Join PurchaseHead PH on D.PurchaseID = PH.ID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group By H.ID, L.Name, C.Name, H.DocumentID, H.Date, H.AutoID, H.Remark, S.Short, S.Name, U.Name, Sr Order by Sr ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Shipment By Each Invoice Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1093:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ExpenseDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select CurrencyID, Date, AcctGroup = AG.Name,  Account =  A.Name, Description, Amount= ( Case When CashbookTypeID = 1 Then Sum(isnull(D.Credit,0) - isnull(D.Debit,0)) Else Sum(isnull(D.Debit,0) - isnull(D.Credit,0)) End)  from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join AccountName A on D.DetailAccountID = A.ID Join AcctGroup AG on A.GroupID = AG.ID  Join AcctSubGroup ASG on AG.SubGroupID = ASG.ID ";
                    LocalData.GroupBy = " Group By CurrencyID, CashbookTypeID, Date, AG.Name, A.Name, Description ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and isnull(H.Deleted,0) <> 1 and CashbookTypeID in (1, 2) and ASG.MainGroupID = 6 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Expense Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1094:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ExpenseSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select CurrencyID, AcctGroup = AG.Name,  Account =  A.Name,  Amount= ( Case When CashbookTypeID = 1 Then Sum(isnull(D.Credit,0) - isnull(D.Debit,0)) Else Sum(isnull(D.Debit,0) - isnull(D.Credit,0)) End)  from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join AccountName A on D.DetailAccountID = A.ID Join AcctGroup AG on A.GroupID = AG.ID  Join AcctSubGroup ASG on AG.SubGroupID = ASG.ID ";
                    LocalData.GroupBy = " Group By CurrencyID, CashbookTypeID,  AG.Name, A.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and isnull(H.Deleted,0) <> 1 and CashbookTypeID in (1, 2) and ASG.MainGroupID = 6 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Expense Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1096:
                    SqlParameter[] PNLarg = new SqlParameter[3];
                    PNLarg[0] = new SqlParameter("@UserID", SqlDbType.Int); PNLarg[0].Value = LocalData.UserID;
                    PNLarg[1] = new SqlParameter("@FromDate", SqlDbType.DateTime); PNLarg[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    PNLarg[2] = new SqlParameter("@ToDate", SqlDbType.DateTime); PNLarg[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");          

                    DBConnection.ExecSp("PNL", PNLarg);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PNL.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LedgerName, AG.Name, Balance, CodeID from GeneralLedgerDetail GL Left Join AcctGroup AG on GL.GroupID = AG.ID where UserID =  " + LocalData.UserID.ToString();
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Profit and Loss Report");
                    ////rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1097:
                    // Balance Sheet — PNL-style sections via BalanceSheet SP + PNL.rpt
                    SqlParameter[] argBS = new SqlParameter[3];
                    argBS[0] = new SqlParameter("@UserID", SqlDbType.Int); argBS[0].Value = LocalData.UserID;
                    argBS[1] = new SqlParameter("@FromDate", SqlDbType.DateTime); argBS[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argBS[2] = new SqlParameter("@ToDate", SqlDbType.DateTime); argBS[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");

                    DBConnection.ExecSp("BalanceSheet", argBS);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PNL.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select LedgerName, Name = ISNULL(AG.Name, GL.AccountName), Balance, CodeID from GeneralLedgerDetail GL Left Join AcctGroup AG on GL.GroupID = AG.ID where UserID =  " + LocalData.UserID.ToString();
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Balance Sheet Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1099:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Code.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select G.Short, Category = G.Name, Code = S.Short, S.Name, Unit = dbo.GetUnitRelation(S.ID) from StockGroup G Join Stock S on G.ID = GroupID where isnull(S.Deleted, 0)<>1 order by G.Short, S.Short "));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Code Setup Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1100:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\COA.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select MainGroup = MG.Name, SubGroup = SG.Name, AcctGroup = AG.Name, A.short, AccountName = A.Name from AcctMainGroup MG Join AcctSubGroup SG on MG.ID = SG.MainGroupID Join AcctGroup AG on SG.ID = SubGroupID Join AccountName A on AG.ID = A.GroupID Where isnull(A.Deleted,0)<>1 order by MG.ID, SG.Name, AG.Name, A.Name "));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Account Setup Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1101:
                    SqlParameter[] argAD = new SqlParameter[5];
                    argAD[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argAD[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argAD[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argAD[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argAD[2] = new SqlParameter("@AccountID", SqlDbType.Int); argAD[2].Value = frm_Reports.AcctiD;
                    argAD[3] = new SqlParameter("@UserID", SqlDbType.Int); argAD[3].Value = LocalData.UserID;
                    argAD[4] = new SqlParameter("@CurrencyID", SqlDbType.Int); argAD[4].Value = -1;

                    DBConnection.ExecSp("GeneralLedgerDetailReport", argAD);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AccountDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select * from GeneralLedgerDetail Where UserID =  " + LocalData.UserID.ToString();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Account Detail Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1102:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Customer.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select G.Short, Category = G.Name, Code = S.Short, S.Name, Address, Info1, Info2, Div = D.Name from Township G Join Customer S on G.ID = TownshipID Left Join Division D on S.DivID = D.ID where isnull(S.Deleted, 0)<>1 order by G.Short, S.Short "));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Customer Setup Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1103:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Supplier.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select G.Short, Category = G.Name, Code = S.Short, S.Name, Address= Phone from Township G Join Supplier S on G.ID = TownshipID  where isnull(S.Deleted, 0)<>1 order by G.Short, S.Short "));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Supplier Setup Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1104:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Supplier.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select G.Short, Category = G.Name, Code = S.Short, S.Name, Address= Phone from Township G Join Manufacturer S on G.ID = TownshipID  where isnull(S.Deleted, 0)<>1 order by G.Short, S.Short "));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacturer Setup Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1105:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\DailySales.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr ,Code = S.Short, Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), PaidAmount, TotalBalance, H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Daily Sales Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1106:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ManufactureCostByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, PurchasePrice, Amount = sum( (isnull(D.Price,0) + ISNULL(PurchasePrice,0)) * Qty ) from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID   ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price, PurchasePrice ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture Cost By Item Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1107:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ManufactureCostByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1, Qty2, Qty = Sum(Qty), Unit = U.Name, Price, PurchasePrice, Amount = sum( (isnull(D.Price,0) + ISNULL(PurchasePrice,0)) * Qty ) from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price, PurchasePrice, Qty1, Qty2 ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture Cost By Item Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1108:
                    SqlParameter[] MKSarg = new SqlParameter[4];
                    MKSarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); MKSarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    MKSarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); MKSarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    MKSarg[2] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); MKSarg[2].Value = frm_Reports.FilterManufacturer;
                    MKSarg[3] = new SqlParameter("@UserID", SqlDbType.Int); MKSarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("MKBalanceSummary", MKSarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Tarpaulin Balance Summary Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1109:
                    SqlParameter[] MKDarg = new SqlParameter[4];
                    MKDarg[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); MKDarg[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    MKDarg[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); MKDarg[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    MKDarg[2] = new SqlParameter("@Manufacturer", SqlDbType.NVarChar); MKDarg[2].Value = frm_Reports.FilterManufacturer;
                    MKDarg[3] = new SqlParameter("@UserID", SqlDbType.Int); MKDarg[3].Value = LocalData.UserID;

                    DBConnection.ExecSp("MKBalanceDetail", MKDarg);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawBalanceDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, AccountHeader, Debit, Credit, Balance from GeneralLedgerDetail ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where UserID =  " + LocalData.UserID.ToString()));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Tarpaulin Balance Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1110:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name,   Location = L.Short, Payment = P.Name,  Sr , Code =S.Short,  Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, TotalAmount, PaidAmount, TotalBalance, H.Remark, Currency = CR.Name, ExgRate, StockReceived = Case When  StockReceived = 1 then 'Received' Else 'Not Received' End  from PurchaseHead H Join PurchaseDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Join Currency CR on H.CurrencyID = Cr.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1111:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ShipmentDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, H.Date, H.AutoID, H.DocumentID, C.Name,   Location = L.Short, PurchaseID = isnull(PH.DocumentID,PH.AutoID),  Sr , Code =S.Short,  Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Qty1, Qty2, H.Remark, H.ExgRate, Price, CostCon, CostTran, NetPrice from StockReceiveHead H Join StockReceiveDetail D on H.ID = D.RefID Left Join PurchaseHead PH on D.PurchaseID = PH.ID Join Supplier C on H.SupplierID = C.ID  Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Shipment Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1112:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ManufactureDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, H.Date, H.AutoID, H.DocumentID, C.Name,   Location = L.Short,  Sr , Code =S.Short,  Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Qty1, Qty2, D.TotalWeight, Price, PurchasePrice, H.Remark from FinishGoodsHead H Join FinishGoodsDetail D on H.ID = D.RefID  Join Manufacturer C on H.ManufacturerID = C.ID  Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID   ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Manufacture Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1113:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\RawIssueDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, H.Date, H.AutoID, H.DocumentID, C.Name,   Location = L.Short,  Sr , Code =S.Short,  Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Qty1, Qty2, D.TotalWeight, H.Remark from RawIssueHead H Join RawIssueDetail D on H.ID = D.RefID  Join Manufacturer C on H.ManufacturerID = C.ID  Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID    ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Raw Issue Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1128:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1, Qty2, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID Join Township Tsp on C.TownshipID = Tsp.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price, Qty1, Qty2 ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID = 100 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Charges Detail Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1130:
                    SqlParameter[] argBank = new SqlParameter[7];
                    argBank[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argBank[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argBank[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argBank[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argBank[2] = new SqlParameter("@AccountID", SqlDbType.Int); argBank[2].Value = frm_Reports.AcctiD;
                    argBank[3] = new SqlParameter("@CustID", SqlDbType.NVarChar); argBank[3].Value = frm_Reports.FilterCustomer;
                    argBank[4] = new SqlParameter("@SupID", SqlDbType.NVarChar); argBank[4].Value = frm_Reports.FilterSupplier;
                    argBank[5] = new SqlParameter("@ManID", SqlDbType.NVarChar); argBank[5].Value = frm_Reports.FilterManufacturer;
                    argBank[6] = new SqlParameter("@UserID", SqlDbType.Int); argBank[6].Value = LocalData.UserID;

                    DBConnection.ExecSp("GL", argBank);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\BankStatement.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, Debit, Credit, Remark, GroupID, Short from generalledgerdetail  Where UserID =  " + LocalData.UserID.ToString() + frm_Reports.GlAccountCodeFilterSql();
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Cash/ Bank Statement Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1132:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\AccountOpening.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select SubGroupCode = ASG.Short, SubGroupName = ASG.Name, GroupCode = AG.Short, GroupName = AG.Name, AN.AccountCode, AccountName = AN.Name, ExgRate, Debit = (ExgRate * Debit), Credit = (ExgRate * Credit), Remark = Description from AccountOpeningHead H Join AccountOpeningDetail D on H.ID = D.RefID Join AccountName AN on D.AccountID = AN.ID Join AcctGroup AG on AN.GroupID = AG.ID Join AcctSubGroup ASG on AG.SubGroupID = ASG.ID ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Account Opening Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1133:
                    SqlParameter[] argGL = new SqlParameter[7];
                    argGL[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argGL[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argGL[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argGL[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argGL[2] = new SqlParameter("@AccountID", SqlDbType.Int); argGL[2].Value = frm_Reports.AcctiD;
                    argGL[3] = new SqlParameter("@CustID", SqlDbType.NVarChar); argGL[3].Value = frm_Reports.FilterCustomer;
                    argGL[4] = new SqlParameter("@SupID", SqlDbType.NVarChar); argGL[4].Value = frm_Reports.FilterSupplier;
                    argGL[5] = new SqlParameter("@ManID", SqlDbType.NVarChar); argGL[5].Value = frm_Reports.FilterManufacturer;
                    argGL[6] = new SqlParameter("@UserID", SqlDbType.Int); argGL[6].Value = LocalData.UserID;


                    DBConnection.ExecSp("GL", argGL);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\GL_Detail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, LedgerName, AccountName, DocumentID, Debit, Credit, Remark, GroupID, Short from generalledgerdetail  Where UserID =  " + LocalData.UserID.ToString() + frm_Reports.GlAccountCodeFilterSql();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "General Ledger Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1134:
                    SqlParameter[] argTB = new SqlParameter[3];
                    argTB[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argTB[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argTB[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argTB[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argTB[2] = new SqlParameter("@UserID", SqlDbType.Int); argTB[2].Value = LocalData.UserID;


                    DBConnection.ExecSp("TrialBalance", argTB);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\TrialBalance.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select GL.*, MainGroupID from GeneralLedgerDetail GL Join AcctSubGroup ASG on GL.GroupID = ASG.ID  Where UserID =  " + LocalData.UserID.ToString();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Trial Balance Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1135:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ReturnStockByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, D.TotalWeight, H.Remark from ReturnStockHead H Join ReturnStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Stock By Invoice Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1136:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from ReturnStockHead H Join ReturnStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Stock By Item Summary Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1137:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from ReturnStockHead H Join ReturnStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, S.Short, S.Name, B.Short, U.Name, Price, SG.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Stock By Item Detail Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1138:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ReturnStockByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, D.TotalWeight, H.Remark from GetStockHead H Join GetStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Get Stock By Invoice Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1139:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from GetStockHead H Join GetStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Get Stock By Item Summary Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1140:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from GetStockHead H Join GetStockDetail D on H.ID = D.RefID Join Manufacturer C on H.ManufacturerID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, S.Short, S.Name, B.Short, U.Name, Price, SG.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Get Stock By Item Detail Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1141:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\BalanceByReturnStock.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Customer, Date = dbo.CastDate(Date), Code = S.Short, Stock = S.Name,  Qty = Sum(Qty),  Unit = U.Name  from dbo.GetReturnStockByGetStock(0) H Join Stock S on CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID Left Join Brand B on BrandID = B.ID Join Unit U on UnitID = U.ID ";
                    LocalData.GroupBy = " Group By Customer, dbo.CastDate(Date), S.Short, S.Name, U.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " and S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Receivable Return Stock Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1142:
                    SqlParameter[] argGLSum = new SqlParameter[4];
                    argGLSum[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argGLSum[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    argGLSum[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argGLSum[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    argGLSum[2] = new SqlParameter("@AccountID", SqlDbType.Int); argGLSum[2].Value = frm_Reports.AcctiD;
                    argGLSum[3] = new SqlParameter("@UserID", SqlDbType.Int); argGLSum[3].Value = LocalData.UserID;


                    DBConnection.ExecSp("GeneralLedgerSummary", argGLSum);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\GeneralLedgerSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Short, LedgerName, AccountName, Debit, Credit from generalledgerdetail  Where UserID =  " + LocalData.UserID.ToString() + frm_Reports.GlAccountCodeFilterSql();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "General Ledger Summary Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1143:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\BankClosing.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select * from dbo.GetAcctClosingSummary('" + frm_Reports.TDate.ToString("yyyy-MM-dd") + "', 0, 0)"));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Banks Balance Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1144:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Journal.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, DocumentID = isnull(DocumentID, AutoID), Remark, Short, A.Name, Description, Debit, Credit from IncomeExpenseHead H Join IncomeExpenseDetail D on H.ID = D.RefID Join AccountName A on D.DetailAccountID = A.ID  ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Journal Report");
                    //rd.PrintToPrinter(1, false, 0, 0);
                    crvPreview.ReportSource = rd;
                    break;
                case 1145:
                    SqlParameter[] gp = new SqlParameter[7];
                    gp[0] = new SqlParameter("@UserID", SqlDbType.Int); gp[0].Value = LocalData.UserID;
                    gp[1] = new SqlParameter("@FDate", SqlDbType.DateTime); gp[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    gp[2] = new SqlParameter("@TDate", SqlDbType.DateTime); gp[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    gp[3] = new SqlParameter("@Code", SqlDbType.NVarChar); gp[3].Value = frm_Reports.FilterStock;
                    gp[4] = new SqlParameter("@GroupID", SqlDbType.NVarChar); gp[4].Value = frm_Reports.FilterStockGroup;
                    gp[5] = new SqlParameter("@TypeID", SqlDbType.NVarChar); gp[5].Value = frm_Reports.FilterStockType;
                    gp[6] = new SqlParameter("@Location", SqlDbType.NVarChar); gp[6].Value = "";

                    DBConnection.ExecSp("SaleProfitFIFO_SP", gp);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseNSales.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select S.Short, S.Name, Qty = dbo.GetQtyinUnitRelation(CodeID, Qty) , PurPrice = FIFOCost, PurAmount = CostAmount, SaleAmount = SaleAmount, SalePrice, Profit  from SaleProfitFIFO gp Join Stock S on gp.CodeID = S.ID where UserID = " + LocalData.UserID.ToString();
                    //LocalData.GroupBy = " group By B.ID, B.Name, SS.Name,SD.Short, U.Short, D.CodeID, PurPrice ";
                    //LocalData.GetFilter(rptid);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Gross Profit Report");


                    crvPreview.ReportSource = rd;
                    //ReportFilterName = "";
                    break;
                case 1146:
                    SqlParameter[] spf = new SqlParameter[7];
                    spf[0] = new SqlParameter("@UserID", SqlDbType.Int); spf[0].Value = LocalData.UserID;
                    spf[1] = new SqlParameter("@FDate", SqlDbType.DateTime); spf[1].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                    spf[2] = new SqlParameter("@TDate", SqlDbType.DateTime); spf[2].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                    spf[3] = new SqlParameter("@Code", SqlDbType.NVarChar); spf[3].Value = frm_Reports.FilterStock;
                    spf[4] = new SqlParameter("@GroupID", SqlDbType.Int); spf[4].Value = -1;
                    spf[5] = new SqlParameter("@TypeID", SqlDbType.Int); spf[5].Value = -1;
                    spf[6] = new SqlParameter("@Location", SqlDbType.NVarChar); spf[6].Value = frm_Reports.FilterLocation;

                    DBConnection.ExecSp("SaleProfitFIFO_SP", spf);
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleProfitFIFO.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Qty = dbo.GetQtyinUnitRelation(SPF.CodeID, SPF.Qty), MinSalePrice = SPF.SalePrice, NetPurPrice = SPF.FIFOCost, SaleAmount = SPF.SaleAmount, PurAmount = SPF.CostAmount, ProfitMargin = SPF.Profit from SaleProfitFIFO SPF Join Stock S on SPF.CodeID = S.ID where SPF.UserID = " + LocalData.UserID.ToString() + " order by S.Short, SPF.SalePrice, SPF.FIFOCost";
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sales Profit Margin (FIFO) Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1151:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseReturnByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, D.TotalWeight, H.Remark, Payment = IIF(isnull(H.StockChange,0) = 1, 'Stock Change', PT.Name) from PurchaseReturnHead H Join PurchaseReturnDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Left Join PaymentType PT on H.PaymentID = PT.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase Return By Invoice Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1152:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from PurchaseReturnHead H Join PurchaseReturnDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase Return By Item Summary Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1153:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from PurchaseReturnHead H Join PurchaseReturnDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, S.Short, S.Name, B.Short, U.Name, Price, SG.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase Return By Item Detail Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1154:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\ReturnStockByInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select H.ID, Date, AutoID, DocumentID, C.Name, Location = L.Short,  Sr , Stock = S.Name, Brand = B.Short, Unit = U.Name, Qty, Price, Weight, D.TotalWeight, H.Remark from ReturnReceiveHead H Join ReturnReceiveDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID  ";
                    LocalData.GroupBy = "  ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Receive By Invoice Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1155:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\PurchaseByItemSummary.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Code = S.Short, Stock = S.Name, Brand = B.Short, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount ) from ReturnReceiveHead H Join ReturnReceiveDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID  ";
                    LocalData.GroupBy = " Group by  S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Receive By Item Summary Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1156:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\SaleByItemDetail.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Date, C.short, Customer = C.Name, Location = L.Name, H.Remark, Category = SG.Name, Code = S.Short, Stock = S.Name, Brand = B.Short, Qty1 = 0, Qty2 = 0, Qty = Sum(Qty), Unit = U.Name, Price, Amount = sum( D.Amount )  from ReturnReceiveHead H Join ReturnReceiveDetail D on H.ID = D.RefID Join Supplier C on H.SupplierID = C.ID Join Township Tsp on C.TownshipID = Tsp.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Left Join Brand B on D.BrandID = B.ID  Join Unit U on D.UnitID = U.ID Join StockGroup SG on S.GroupID = SG.ID ";
                    LocalData.GroupBy = " Group by Date, C.Short, C.Name, L.Name, H.Remark, SG.Name, S.Short, S.Name, B.Short, U.Name, Price ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Return Receive By Item Detail Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1157:
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\BalanceByReturnStock.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query = "select Customer, Date = dbo.CastDate(Date), Code = S.Short, Stock = S.Name,  Qty = Sum(Qty),  Unit = U.Name  from dbo.GetReturnBalReceive(" + (string.IsNullOrEmpty(frm_Reports.FilterSupplier) ? "0" : frm_Reports.FilterSupplier) + ") H Join Stock S on CodeID = S.ID Join StockGroup SG on S.GroupID = SG.ID Left Join Brand B on BrandID = B.ID Join Unit U on UnitID = U.ID ";
                    LocalData.GroupBy = " Group By Customer, dbo.CastDate(Date), S.Short, S.Name, U.Name ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + " where S.GroupID <> 51 " + LocalData.GroupBy));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Purchase Return Balance Report");
                    crvPreview.ReportSource = rd;
                    break;
                case 1161:
                    // Sale Edit/Delete Log — check path BEFORE assigning ReportDocument.FileName
                    // (Crystal rewrites FileName to rassdk://… which breaks File.Exists)
                    {
                        string rptPath = System.IO.Path.Combine(Environment.CurrentDirectory, "Reports", "SaleEditDeleteLog.rpt");
                        if (!System.IO.File.Exists(rptPath))
                        {
                            MessageBox.Show(
                                "Report file not found:\n" + rptPath +
                                "\n\nCopy SaleEditDeleteLog.rpt to the Reports folder next to SB.exe.",
                                "Sale Edit/Delete Log",
                                MessageBoxButtons.OK,
                                MessageBoxIcon.Warning);
                            return;
                        }
                        rd.FileName = rptPath;
                    }
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    LocalData.Query =
                        "select AuditID = H.ID, " +
                        "ActionDate = H.ActionDate, " +
                        "ActionName = CASE H.Action WHEN 'E' THEN N'Edit' WHEN 'D' THEN N'Delete' ELSE H.Action END, " +
                        "UserName = ISNULL(U.Short, ISNULL(U.Name, N'')), " +
                        "AutoID = ISNULL(H.AutoID, N''), " +
                        "DocumentID = ISNULL(CONVERT(nvarchar(50), H.DocumentID), N''), " +
                        "OldDate = ISNULL(H.OldDate, H.InvoiceDate), " +
                        "NewDate = ISNULL(H.NewDate, H.InvoiceDate), " +
                        "OldCustomer = ISNULL(OC.Name, N''), " +
                        "NewCustomer = ISNULL(NC.Name, N''), " +
                        "Customer = ISNULL(NC.Name, ISNULL(OC.Name, N'')), " +
                        "OldTotalAmount = ISNULL(H.OldTotalAmount, 0), " +
                        "NewTotalAmount = ISNULL(H.NewTotalAmount, 0), " +
                        "IsHeadOnly = CASE WHEN D.ID IS NULL THEN 1 ELSE 0 END, " +
                        "Sr = ISNULL(D.Sr, 0), " +
                        "LineActionName = CASE D.LineAction WHEN 'A' THEN N'Add' WHEN 'U' THEN N'Update' WHEN 'D' THEN N'Delete' ELSE N'' END, " +
                        "LineAction = CASE D.LineAction WHEN 'A' THEN N'Add' WHEN 'U' THEN N'Update' WHEN 'D' THEN N'Delete' ELSE N'' END, " +
                        "Code = ISNULL(S.Short, N''), " +
                        "Stock = ISNULL(S.Name, N''), " +
                        "Unit = ISNULL(UN.Name, N''), " +
                        "OldQty = D.OldQty, " +
                        "NewQty = D.NewQty, " +
                        "OldPrice = D.OldPrice, " +
                        "NewPrice = D.NewPrice, " +
                        "OldAmount = D.OldAmount, " +
                        "NewAmount = D.NewAmount, " +
                        "Amount = ISNULL(D.NewAmount, ISNULL(D.OldAmount, 0)) " +
                        "from SaleAuditHead H " +
                        "left join SaleAuditDetail D on D.AuditID = H.ID " +
                        "left join Customer OC on OC.ID = ISNULL(H.OldCustomerID, H.CustomerID) " +
                        "left join Customer NC on NC.ID = ISNULL(H.NewCustomerID, H.CustomerID) " +
                        "left join Users U on U.ID = H.UserID " +
                        "left join Stock S on S.ID = D.CodeID " +
                        "left join Unit UN on UN.ID = D.UnitID ";
                    LocalData.GroupBy = " ";
                    Transaction.GetFilter(ReportID);
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query + Transaction.Filter + " Order by H.ActionDate, H.ID, D.Sr"));
                    rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                    rd.SetParameterValue("Header", "Sale Edit/Delete Log");
                    crvPreview.ReportSource = rd;
                    break;
                case 1162:
                    // Foreign Currency Ledger — dbo.ForeignCurrencyLedger → GeneralLedgerDetail.rpt
                    // IE (1) + Supplier Payment (4), FC (no ExgRate), Opening/Closing like GL Detail
                    {
                        SqlParameter[] argFc = new SqlParameter[4];
                        argFc[0] = new SqlParameter("@FromDate", SqlDbType.DateTime); argFc[0].Value = frm_Reports.FDate.ToString("yyyy-MM-dd");
                        argFc[1] = new SqlParameter("@ToDate", SqlDbType.DateTime); argFc[1].Value = frm_Reports.TDate.ToString("yyyy-MM-dd");
                        argFc[2] = new SqlParameter("@AccountID", SqlDbType.Int); argFc[2].Value = frm_Reports.AcctiD;
                        argFc[3] = new SqlParameter("@UserID", SqlDbType.Int); argFc[3].Value = LocalData.UserID;

                        DBConnection.ExecSp("ForeignCurrencyLedger", argFc);

                        string rptPath = System.IO.Path.Combine(Environment.CurrentDirectory, "Reports", "GeneralLedgerDetail.rpt");
                        if (!System.IO.File.Exists(rptPath))
                        {
                            MessageBox.Show(
                                "Report file not found:\n" + rptPath,
                                "Foreign Currency Ledger",
                                MessageBoxButtons.OK,
                                MessageBoxIcon.Warning);
                            return;
                        }
                        rd.FileName = rptPath;
                        rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                        rd.SetDatabaseLogon("sa", "27042005@MND");
                        LocalData.Query = "select * from GeneralLedgerDetail Where UserID = " + LocalData.UserID.ToString();
                        rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("Select * From Setting"));
                        rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable(LocalData.Query));
                        rd.SetParameterValue("Filter", "From Date : " + frm_Reports.FDate.ToString("dd-MM-yyyy") + " >> To Date : " + frm_Reports.TDate.ToString("dd-MM-yyyy"));
                        rd.SetParameterValue("Header", "Foreign Currency Ledger");
                        crvPreview.ReportSource = rd;
                    }
                    break;
                default:
                    break;
            }

        }
    }
}
