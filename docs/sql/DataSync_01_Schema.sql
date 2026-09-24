/*

  Data Sync - Core schema

  Run on BOTH Local (primary) and Cloud (secondary) databases.

  Idempotent: safe to re-run.

*/



SET NOCOUNT ON;

SET QUOTED_IDENTIFIER ON;

SET ANSI_NULLS ON;

GO



-- ============================================================

-- SyncConfig

-- ============================================================

IF OBJECT_ID('dbo.SyncConfig', 'U') IS NULL

BEGIN

    CREATE TABLE dbo.SyncConfig (

        TableName           sysname       NOT NULL PRIMARY KEY,

        IsEnabled           bit           NOT NULL CONSTRAINT DF_SyncConfig_IsEnabled DEFAULT (1),

        CaptureLocal        bit           NOT NULL CONSTRAINT DF_SyncConfig_CaptureLocal DEFAULT (1),

        CaptureCloud        bit           NOT NULL CONSTRAINT DF_SyncConfig_CaptureCloud DEFAULT (0),

        PrimaryKeyColumns   nvarchar(500) NOT NULL,

        BatchSize           int           NOT NULL CONSTRAINT DF_SyncConfig_BatchSize DEFAULT (100),

        Priority            tinyint       NOT NULL CONSTRAINT DF_SyncConfig_Priority DEFAULT (100),

        Notes               nvarchar(500) NULL

    );

END

GO



MERGE dbo.SyncConfig AS t

USING (VALUES

    (N'Customer',       1, 1, 0, N'ID', 100, 10, N'Master data pilot'),

    (N'Location',       1, 1, 0, N'ID', 100, 10, N'Master data'),

    (N'SaleHead',       0, 1, 0, N'ID',  50,  20, N'Enable after master data stable'),

    (N'SaleDetail',     0, 1, 0, N'ID', 100, 21, N'Enable with SaleHead')

) AS s(TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)

ON t.TableName = s.TableName

WHEN NOT MATCHED BY TARGET THEN

    INSERT (TableName, IsEnabled, CaptureLocal, CaptureCloud, PrimaryKeyColumns, BatchSize, Priority, Notes)

    VALUES (s.TableName, s.IsEnabled, s.CaptureLocal, s.CaptureCloud, s.PrimaryKeyColumns, s.BatchSize, s.Priority, s.Notes);

GO



-- ============================================================

-- SyncOutbox

-- ============================================================

IF OBJECT_ID('dbo.SyncOutbox', 'U') IS NULL

BEGIN

    CREATE TABLE dbo.SyncOutbox (

        OutboxID            bigint        IDENTITY(1,1) NOT NULL PRIMARY KEY,

        Direction           char(3)       NOT NULL,

        TableName           sysname       NOT NULL,

        PrimaryKeyJson      nvarchar(500) NOT NULL,

        Operation           char(1)       NOT NULL,

        PayloadJson         nvarchar(max) NULL,

        RowVersionSnapshot  binary(8)     NULL,

        SyncModifiedAt      datetime2(3)  NOT NULL CONSTRAINT DF_SyncOutbox_ModAt DEFAULT (sysutcdatetime()),

        CreatedAt           datetime2(3)  NOT NULL CONSTRAINT DF_SyncOutbox_Created DEFAULT (sysutcdatetime()),

        Status              varchar(20)   NOT NULL CONSTRAINT DF_SyncOutbox_Status DEFAULT ('Pending'),

        AttemptCount        int           NOT NULL CONSTRAINT DF_SyncOutbox_Attempts DEFAULT (0),

        LastError           nvarchar(max) NULL,

        SyncedAt            datetime2(3)  NULL,

        CONSTRAINT CK_SyncOutbox_Direction CHECK (Direction IN ('L2C','C2L')),

        CONSTRAINT CK_SyncOutbox_Operation CHECK (Operation IN ('I','U','D')),

        CONSTRAINT CK_SyncOutbox_Status CHECK (Status IN ('Pending','Syncing','Synced','Conflict','DeadLetter'))

    );

END

GO



IF OBJECT_ID('dbo.SyncOutbox', 'U') IS NOT NULL

   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.SyncOutbox') AND name = 'IX_SyncOutbox_Pending')

    CREATE INDEX IX_SyncOutbox_Pending ON dbo.SyncOutbox (Direction, Status, CreatedAt);

GO



-- ============================================================

-- SyncState

-- ============================================================

IF OBJECT_ID('dbo.SyncState', 'U') IS NULL

BEGIN

    CREATE TABLE dbo.SyncState (

        StateKey            varchar(50)   NOT NULL PRIMARY KEY,

        StateValue          nvarchar(max) NULL,

        UpdatedAt           datetime2(3)  NOT NULL CONSTRAINT DF_SyncState_Updated DEFAULT (sysutcdatetime())

    );



    INSERT INTO dbo.SyncState (StateKey, StateValue) VALUES

        (N'CloudOnline', N'0'),

        (N'LastPushUtc', NULL),

        (N'LastPullUtc', NULL),

        (N'AgentInstance', NULL);

END

GO



-- ============================================================

-- SyncConflictLog

-- ============================================================

IF OBJECT_ID('dbo.SyncConflictLog', 'U') IS NULL

BEGIN

    CREATE TABLE dbo.SyncConflictLog (

        ConflictID          bigint        IDENTITY(1,1) NOT NULL PRIMARY KEY,

        DetectedAt          datetime2(3)  NOT NULL CONSTRAINT DF_SyncConflict_Detected DEFAULT (sysutcdatetime()),

        Direction           char(3)       NOT NULL,

        TableName           sysname       NOT NULL,

        PrimaryKeyJson      nvarchar(500) NOT NULL,

        Resolution          varchar(30)   NOT NULL,

        LocalPayloadJson    nvarchar(max) NULL,

        RemotePayloadJson   nvarchar(max) NULL,

        LocalModifiedAt     datetime2(3)  NULL,

        RemoteModifiedAt    datetime2(3)  NULL,

        Message             nvarchar(1000) NULL,

        Reviewed            bit           NOT NULL CONSTRAINT DF_SyncConflict_Reviewed DEFAULT (0),

        ReviewedBy          int           NULL,

        ReviewedAt          datetime2(3)  NULL,

        ReviewNotes         nvarchar(1000) NULL

    );

END

GO



IF OBJECT_ID('dbo.SyncConflictLog', 'U') IS NOT NULL

   AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.SyncConflictLog') AND name = 'IX_SyncConflict_Unreviewed')

    CREATE INDEX IX_SyncConflict_Unreviewed ON dbo.SyncConflictLog (Reviewed, DetectedAt DESC);

GO



-- ============================================================

-- SyncDeadLetter

-- ============================================================

IF OBJECT_ID('dbo.SyncDeadLetter', 'U') IS NULL

BEGIN

    CREATE TABLE dbo.SyncDeadLetter (

        DeadLetterID        bigint        IDENTITY(1,1) NOT NULL PRIMARY KEY,

        OutboxID            bigint        NOT NULL,

        FailedAt            datetime2(3)  NOT NULL CONSTRAINT DF_SyncDeadLetter_Failed DEFAULT (sysutcdatetime()),

        TableName           sysname       NOT NULL,

        PrimaryKeyJson      nvarchar(500) NOT NULL,

        PayloadJson         nvarchar(max) NULL,

        LastError           nvarchar(max) NOT NULL

    );

END

GO



PRINT 'DataSync_01_Schema.sql completed.';

GO


