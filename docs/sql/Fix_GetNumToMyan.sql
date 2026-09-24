/*
  GetNumToMyan1 / GetNumToMyan2 — bigint division fix (no wrap spaces).

  NOTE: Does NOT alter base dbo.GetNumToMyan (digit words). Only 1 and 2.
  Check-CloudSchemaRemaining should treat GetNumToMyan as OK if present.

  Run on CLOUD (db_abbe78_warehouse) and Local if needed.
  After run, verify modify_date is TODAY for GetNumToMyan1 / GetNumToMyan2.
*/

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

PRINT 'DB = ' + DB_NAME();
GO

CREATE OR ALTER FUNCTION dbo.GetNumToMyan1 (@Num money)
RETURNS nvarchar(500)
AS
BEGIN
    DECLARE @Myan nvarchar(500) = N'';
    DECLARE @n bigint = CAST(ROUND(ABS(ISNULL(@Num, 0)), 0) AS bigint);
    DECLARE @Ans int;

    -- သောင်း / ထောင် / ရာ / ဆယ်  (no trailing space)
    DECLARE @Thou nvarchar(10) = NCHAR(0x101E)+NCHAR(0x1031)+NCHAR(0x102C)+NCHAR(0x1004)+NCHAR(0x103A)+NCHAR(0x1038);
    DECLARE @Hthou nvarchar(10) = NCHAR(0x1011)+NCHAR(0x1031)+NCHAR(0x102C)+NCHAR(0x1004)+NCHAR(0x103A);
    DECLARE @Hund nvarchar(10) = NCHAR(0x101B)+NCHAR(0x102C);
    DECLARE @Ten nvarchar(10) = NCHAR(0x1006)+NCHAR(0x1031)+NCHAR(0x101C)+NCHAR(0x103A);

    IF @n >= 100000
        RETURN N'Error';

    IF @n = 0
        RETURN dbo.GetNumToMyan(0);

    IF @n / 10000 > 0
    BEGIN
        SET @Ans = CAST(@n / 10000 AS int);
        SET @n = @n % 10000;
        SET @Myan = @Myan + dbo.GetNumToMyan(@Ans) + @Thou;
    END

    IF @n / 1000 > 0
    BEGIN
        SET @Ans = CAST(@n / 1000 AS int);
        SET @n = @n % 1000;
        SET @Myan = @Myan + dbo.GetNumToMyan(@Ans) + @Hthou;
    END

    IF @n / 100 > 0
    BEGIN
        SET @Ans = CAST(@n / 100 AS int);
        SET @n = @n % 100;
        SET @Myan = @Myan + dbo.GetNumToMyan(@Ans) + @Hund;
    END

    IF @n / 10 > 0
    BEGIN
        SET @Ans = CAST(@n / 10 AS int);
        SET @n = @n % 10;
        SET @Myan = @Myan + dbo.GetNumToMyan(@Ans) + @Ten;
    END

    IF @n > 0
        SET @Myan = @Myan + dbo.GetNumToMyan(CAST(@n AS int));

    RETURN @Myan;
END
GO

CREATE OR ALTER FUNCTION dbo.GetNumToMyan2 (@Num money)
RETURNS nvarchar(500)
AS
BEGIN
    DECLARE @Myan nvarchar(500) = N'';
    DECLARE @n bigint = CAST(ROUND(ABS(ISNULL(@Num, 0)), 0) AS bigint);
    DECLARE @Ans bigint;
    DECLARE @Rem bigint;
    -- သိန်း (no trailing space)
    DECLARE @Lakh nvarchar(10) = NCHAR(0x101E)+NCHAR(0x102D)+NCHAR(0x1014)+NCHAR(0x103A)+NCHAR(0x1038);

    SET @Ans = @n / 100000;
    SET @Rem = @n % 100000;

    IF @Ans > 0
        SET @Myan = @Myan + dbo.GetNumToMyan1(@Ans) + @Lakh;

    IF @Rem > 0
        SET @Myan = @Myan + dbo.GetNumToMyan1(@Rem);

    IF @Myan = N''
        SET @Myan = dbo.GetNumToMyan(0);

    RETURN @Myan;
END
GO

PRINT '=== modify_date (expect today for 1 and 2) ===';
SELECT name, modify_date
FROM sys.objects
WHERE name IN (N'GetNumToMyan', N'GetNumToMyan1', N'GetNumToMyan2')
ORDER BY name;

PRINT '=== Verify output ===';
SELECT
    dbo.GetNumToMyan1(63566) AS N63566,
    dbo.GetNumToMyan2(254358285) AS N254358285,
    dbo.GetNumToMyan2(175463566) AS N175463566,
    CHARINDEX(N' ', dbo.GetNumToMyan2(254358285)) AS SpacePos; -- expect 0
GO

PRINT 'Fix_GetNumToMyan.sql completed on ' + DB_NAME();
GO
