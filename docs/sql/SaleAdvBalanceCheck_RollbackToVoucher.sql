-- Rollback SaleAdvBalanceCheck to voucher-by-voucher mode.
-- Requires SaleAdvBalanceCheck_ByVoucher.sql already deployed.
--
-- Deploy: sqlcmd -i SaleAdvBalanceCheck_RollbackToVoucher.sql
-- After rollback, EXEC dbo.SaleAdvBalanceCheck behaves like ByVoucher again.

CREATE OR ALTER PROCEDURE dbo.SaleAdvBalanceCheck
(
    @FromDate  datetime,
    @ToDate    datetime,
    @Division  nvarchar(1024) = NULL,
    @Township  nvarchar(1024) = NULL,
    @Customer  nvarchar(1024) = NULL,
    @UserID    int,
    @OnlyIssue bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    EXEC dbo.SaleAdvBalanceCheck_ByVoucher
        @FromDate  = @FromDate,
        @ToDate    = @ToDate,
        @Division  = @Division,
        @Township  = @Township,
        @Customer  = @Customer,
        @UserID    = @UserID,
        @OnlyIssue = @OnlyIssue;
END
GO
