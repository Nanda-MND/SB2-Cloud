-- Customer.TransportCharges — Sales Entry ပို့ခ allow/lock (1=allow, 0=lock price=0)
-- Run on CLOUD (and Local if missing). Fixes: Invalid column name 'TransportCharges'

IF COL_LENGTH(N'dbo.Customer', N'TransportCharges') IS NULL
BEGIN
    ALTER TABLE dbo.Customer ADD TransportCharges bit NOT NULL
        CONSTRAINT DF_Customer_TransportCharges DEFAULT (1);
    PRINT 'Added Customer.TransportCharges NOT NULL DEFAULT 1';
END
ELSE
    PRINT 'Customer.TransportCharges already exists';
GO

SELECT c.name, t.name AS TypeName, c.is_nullable, dc.name AS DefaultConstraint
FROM sys.columns c
INNER JOIN sys.types t ON t.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints dc
    ON dc.parent_object_id = c.object_id AND dc.parent_column_id = c.column_id
WHERE c.object_id = OBJECT_ID(N'dbo.Customer') AND c.name = N'TransportCharges';
GO
