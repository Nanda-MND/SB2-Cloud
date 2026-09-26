using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Drawing.Printing;
using CrystalDecisions.CrystalReports.Engine;

namespace SB
{
    public partial class frm_PrintSelect : Form
    {
        ReportDocument rd;
        Form frm;

        public frm_PrintSelect()
        {
            InitializeComponent();
        }

        private void btPrint_Click(object sender, EventArgs e)
        {
            rd = new ReportDocument();
            PrintDocument localPrinter = new PrintDocument();
            //rd.PrintOptions.PrinterName = "EPSON TM-U220 ReceiptE4";
            rd.PrintOptions.PrinterName = localPrinter.PrinterSettings.PrinterName;


            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                if (rbVoucher.Checked)
                {
                    PrinterSettings PrnSetting = new PrinterSettings();
                    PageSettings PgSetting = new PageSettings();
                    string prnName = string.Empty;

                    prnName = DBConnection.rExecSQL("Select Voucher From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    PrnSetting.PrinterName = prnName;
                    //PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                    PrnSetting.Copies = 1;
                    PgSetting.PaperSize = new PaperSize("Custom", 479, 1684);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\Voucher.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");

                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Location = L.Short, Sr,  Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, D.Amount, Qty1 = isnull(Qty1,0), TotalWeight, AddAmount = ISNULL(H.AddAmount,0), TotalAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), NetAmount = ISNULL(H.TotalAmount,0) + ISNULL(H.AddAmount,0), H.Remark from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID   Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    rd.PrintToPrinter(PrnSetting, PgSetting, false);
                    //frm = new frm_Preview(1);
                    //frm.ShowDialog();

                }
                else if (rbInvoice.Checked)
                {
                    ////prnName = DBConnection.rExecSQL("Select Invoice From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    ////PrnSetting.PrinterName = prnName;
                    //////PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                    ////PrnSetting.Copies = 1;

                    ////PgSetting.PaperSize = new PaperSize("A5", 600,827);

                    //rd.FileName = Environment.CurrentDirectory + @"\Reports\Invoice.rpt";
                    //rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    //rd.SetDatabaseLogon("sa", "27042005@MND");
                    //rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    //rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, DtRemark = D.Remark, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, H.Remark, Users = US.Short from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID Join Users US on UserID = US.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(3, false, 0, 0);
                    ////rd.PrintToPrinter(PrnSetting, PgSetting, false);
                    //DBConnection.ExecSQL("Update SaleHead Set Printed = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    frm = new frm_Preview(2);
                    frm.ShowDialog();

                    frm = new frm_Preview(5);
                    frm.ShowDialog();
                }
                else if (rbPansar.Checked)
                {
                    ////prnName = DBConnection.rExecSQL("Select PannSar From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    ////PrnSetting.PrinterName = prnName;
                    //////PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                    ////PrnSetting.Copies = 1;

                    ////PgSetting.PaperSize = new PaperSize();

                    //rd.FileName = Environment.CurrentDirectory + @"\Reports\PanSar.rpt";
                    //rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    //rd.SetDatabaseLogon("sa", "27042005@MND");
                    //rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    //rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1, Info2, Gate = G.Name, Car = Cr.Name,GateID  from SaleHead H Join Customer C on H.CustomerID = C.ID Left Join Gates G on  H.GateID = G.ID Left join Cars Cr on H.CarID = Cr.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(1, false, 0, 0);
                    ////rd.PrintToPrinter(PrnSetting, PgSetting, false);
                    //DBConnection.ExecSQL("Update SaleHead Set PanSar = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    frm = new frm_Preview(3);
                    frm.ShowDialog();
                }
                else if (rbLogo.Checked)
                {
                    frm = new frm_Preview(7);
                    frm.ShowDialog();
                }
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                if (rbVoucher.Checked)
                {
                    PrinterSettings PrnSetting = new PrinterSettings();
                    PageSettings PgSetting = new PageSettings();
                    string prnName = string.Empty;

                    prnName = DBConnection.rExecSQL("Select Voucher From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    PrnSetting.PrinterName = prnName;
                    //PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                    PrnSetting.Copies = 1;
                    PgSetting.PaperSize = new PaperSize("Custom", 479, 1684);

                    rd.FileName = Environment.CurrentDirectory + @"\Reports\OrderVoucher.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");

                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select * From Setting"));
                    rd.Database.Tables["Head"].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID = isnull(Cast(DocumentID as nvarchar(10)), AutoID), SaleID, C.Name, Location = L.Short, Sr,  Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, D.Amount, Qty1 = isnull(Qty1,0), Qty2 = isnull(Qty2,0), TotalWeight, NetAmount = isnull(NetAmount,H.Amount), H.Remark from SaleOrderHead H Join SaleOrderDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID   Where H.ID = " + frm_SalesOrder.PrintID.ToString()));
                    rd.SetParameterValue("Header", "Sales Order");
                    rd.PrintToPrinter(PrnSetting, PgSetting, false);
                    //frm = new frm_Preview(1);
                    //frm.ShowDialog();

                }
                else if (rbInvoice.Checked)
                {
                    ////prnName = DBConnection.rExecSQL("Select Invoice From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    ////PrnSetting.PrinterName = prnName;
                    //////PrnSetting.PrinterName = @"\\Server\EPSON TM-U220 Receipt";
                    ////PrnSetting.Copies = 1;

                    ////PgSetting.PaperSize = new PaperSize("A5", 600,827);

                    //rd.FileName = Environment.CurrentDirectory + @"\Reports\Invoice.rpt";
                    //rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    //rd.SetDatabaseLogon("sa", "27042005@MND");
                    //rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    //rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Payment = P.Name, Gates = G.Name, Cars = Cr.Name, Sr , Stock = S.Name, Brand = B.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, D.Amount, DtRemark = D.Remark, HAmount = H.Amount, Balance,  Discount, NetAmount, TaxAmount, AddAmount, TotalAmount, PaidAmount, TotalBalance, H.Remark, Users = US.Short from SaleHead H Join SaleDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Left Join Brand B on D.BrandID = B.ID Join PaymentType P on H.PaymentID = P.ID Left Join Gates G on GateID = G.ID Left Join Cars Cr on CarID = Cr.ID Join Users US on UserID = US.ID  Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    //rd.PrintToPrinter(3, false, 0, 0);
                    ////rd.PrintToPrinter(PrnSetting, PgSetting, false);
                    //DBConnection.ExecSQL("Update SaleHead Set Printed = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());
                    //frm = new frm_Preview(2);
                    //frm.ShowDialog();
                    PrinterSettings PrnSetting = new PrinterSettings();
                    PageSettings PgSetting = new PageSettings();
                    string prnName = string.Empty;
                    prnName = DBConnection.rExecSQL("Select Invoice From LogInClient Where ID = " + LocalData.LoginID).ToString();
                    PrnSetting.PrinterName = prnName;
                    rd.PrintOptions.PrinterName = localPrinter.PrinterSettings.PrinterName;
                    rd.FileName = Environment.CurrentDirectory + @"\Reports\OrderInvoice.rpt";
                    rd.DataSourceConnections[0].SetConnection(DBConnection.ActiveConnection.DataSource.ToString(), DBConnection.ActiveConnection.Database.ToString(), false);
                    rd.SetDatabaseLogon("sa", "27042005@MND");
                    rd.Database.Tables["Setting"].SetDataSource(DBConnection.GetSQLTable("select CName = Name, Bussiness, Address, PhoneNo, ViberNo, Logo  From Setting Where ID = 1"));
                    rd.Database.Tables[1].SetDataSource(DBConnection.GetSQLTable("select H.ID, Date, AutoID, DocumentID, SaleID, C.Name, Address, Info1,  Location = L.Short, Sr , Stock = S.Name, Unit = U.Name, Qty, Price, Weight, TotalWeight, D.Amount, Qty1, Qty2, TotalWeight, TotalMinQty, DRemark = D.Remark, D.Amount, HAmount = H.Amount, H.Remark, Users = US.Name, AdvAmount = Cast(Round(AdvAmount ,0) as int), AmountText = dbo.GetNumToMyan2(AdvAmount) + N' ကျပ်တိတိ' from SaleOrderHead H Join SaleOrderDetail D on H.ID = D.RefID Join Customer C on H.CustomerID = C.ID Join Location L on H.LocationID = L.ID Join Stock S on D.CodeID = S.ID Join Unit U on U.ID = D.UnitID Join Users US on UserID = US.ID   Where H.ID = " + frm_SalesOrder.PrintID.ToString()));

                    rd.PrintToPrinter(2, false, 0, 0);
                }
                DBConnection.ExecSQL("Update SaleOrderHead Set Printed = 1 Where ID = " + frm_SalesOrder.PrintID.ToString());

            }
            

            this.Close();
            this.DialogResult = DialogResult.OK;
        }

        private void frm_PrintSelect_Load(object sender, EventArgs e)
        {
            if (LocalData.Menu == LocalData.myMenu.Sale)
            {
                rbPansar.Visible = true;
                rbLogo.Visible = true;
            }
            else if (LocalData.Menu == LocalData.myMenu.SaleOrder)
            {
                rbPansar.Visible = false;
                rbLogo.Visible = false;
            }
            btPrint.Focus();
        }
    }
}
