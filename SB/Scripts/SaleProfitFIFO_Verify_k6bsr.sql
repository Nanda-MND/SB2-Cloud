-- Redeploy SaleProfitFIFO.sql then:
EXEC dbo.SaleProfitFIFO_SP
    @UserID = 1,
    @FDate = '2026-06-01',
    @TDate = '2026-06-30',
    @Code = N'k6bsr',
    @GroupID = NULL,
    @TypeID = NULL,
    @Location = N'';

SELECT Qty, SalePrice, FIFOCost, SaleAmount, CostAmount, Profit
FROM dbo.SaleProfitFIFO WHERE UserID = 1
ORDER BY SalePrice, FIFOCost;
GO
