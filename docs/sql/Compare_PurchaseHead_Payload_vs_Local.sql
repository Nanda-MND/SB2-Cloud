/*
  LOCAL — compare PurchaseHead columns vs Cloud C2L payload keys,
  then force-apply (paste FULL PayloadJson from Cloud).
*/

SET NOCOUNT ON;

-- 1) Local NOT NULL columns without default (must be in payload or insert fails)
SELECT c.name AS Col, t.name AS TypeName, c.is_nullable,
       dc.name AS DefaultName
FROM sys.columns c
INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
  ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.PurchaseHead')
  AND c.is_identity = 0
  AND c.is_computed = 0
  AND c.is_nullable = 0
  AND dc.object_id IS NULL
ORDER BY c.column_id;

PRINT 'If a NOT NULL column above is missing from PayloadJson → C2L insert fails.';
GO

-- 2) Force apply — paste COMPLETE PayloadJson from Cloud (copy cell, not truncated grid)
/*
DECLARE @j nvarchar(max) = N'PASTE_FULL_PAYLOAD_HERE';

DECLARE @c bit, @a bit;
BEGIN TRY
    EXEC dbo.SyncApply_Generic
        @Source = N'Cloud',
        @TableName = N'PurchaseHead',
        @PayloadJson = @j,
        @PrimaryKeyJson = N'{"ID":2000000000}',
        @RemoteModifiedAt = SYSUTCDATETIME(),
        @Operation = N'I',
        @OutboxID = NULL,
        @ConflictLogged = @c OUTPUT,
        @Applied = @a OUTPUT;
    SELECT Applied = @a, Conflict = @c;
END TRY
BEGIN CATCH
    SELECT Err = ERROR_MESSAGE(), Number = ERROR_NUMBER();
END CATCH

SELECT ID, AutoID, SyncOrigin, Remark FROM dbo.PurchaseHead WHERE ID = 2000000000;
*/
GO
