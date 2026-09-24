/*

  Compare TVF definitions / versions between environments.

  Run on each server separately, compare modify_date and test counts.



  Dev / Local / Cloud should all return same modify_date after deploy.

*/



SET NOCOUNT ON;



PRINT '=== TVF modify dates ===';

SELECT

    o.name AS FunctionName,

    o.type_desc,

    o.create_date,

    o.modify_date

FROM sys.objects o

WHERE o.schema_id = SCHEMA_ID(N'dbo')

  AND o.name IN (

      N'GetSaleOrderBalSales',

      N'GetSaleOrderBalSalesList',

      N'GetSaleOrderBalSalesRpt'

  )

ORDER BY o.name;



PRINT '=== Test GetSaleOrderBalSales(2609) — pplplst ===';

IF OBJECT_ID(N'dbo.GetSaleOrderBalSales', N'TF') IS NOT NULL

BEGIN

    SELECT COUNT(*) AS RowCnt FROM dbo.GetSaleOrderBalSales(2609);



    SELECT Date, AutoID, Short, RefID, CodeID, UnitID, Qty, Sr, Remark

    FROM dbo.GetSaleOrderBalSales(2609)

    WHERE RefID IN (6481, 6517)

    ORDER BY RefID, Sr;

END

ELSE

    PRINT 'GetSaleOrderBalSales NOT FOUND';



PRINT '=== Test GetSaleOrderBalSales(3496) ===';

IF OBJECT_ID(N'dbo.GetSaleOrderBalSales', N'TF') IS NOT NULL

BEGIN

    SELECT COUNT(*) AS RowCnt FROM dbo.GetSaleOrderBalSales(3496);



    SELECT RefID, Sr, CodeID, UnitID, Qty, Price, Remark

    FROM dbo.GetSaleOrderBalSales(3496)

    WHERE CodeID = 570

    ORDER BY Sr;

END



PRINT '=== Test GetSaleOrderBalSalesList() ===';

IF OBJECT_ID(N'dbo.GetSaleOrderBalSalesList', N'TF') IS NOT NULL

BEGIN

    SELECT COUNT(*) AS RowCnt FROM dbo.GetSaleOrderBalSalesList();



    SELECT COUNT(*) AS PplplstRowCnt

    FROM dbo.GetSaleOrderBalSalesList()

    WHERE Short = 'pplplst';

END

ELSE

    PRINT 'GetSaleOrderBalSalesList NOT FOUND';



PRINT '=== Mismatch: List pplplst rows missing from GetSaleOrderBalSales(2609) ===';

IF OBJECT_ID(N'dbo.GetSaleOrderBalSales', N'TF') IS NOT NULL

 AND OBJECT_ID(N'dbo.GetSaleOrderBalSalesList', N'TF') IS NOT NULL

BEGIN

    SELECT L.*

    FROM dbo.GetSaleOrderBalSalesList() L

    WHERE L.Short = 'pplplst'

      AND NOT EXISTS (

          SELECT 1

          FROM dbo.GetSaleOrderBalSales(2609) B

          WHERE B.RefID  = L.RefID

            AND B.Sr     = L.Sr

            AND B.CodeID = L.CodeID

            AND B.UnitID = L.UnitID

      );

END

GO

