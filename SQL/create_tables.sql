------------------------------------------------------------
-- create_tables.sql
-- ManufacturingDemo database schema for analytics
-- SQL Server (T-SQL)
------------------------------------------------------------

-- Create database if it does not exist
IF DB_ID('ManufacturingDemo') IS NULL
BEGIN
    CREATE DATABASE ManufacturingDemo;
END;
GO

USE ManufacturingDemo;
GO

------------------------------------------------------------
-- Drop existing tables (if rerunning script)
------------------------------------------------------------

IF OBJECT_ID('dbo.JobOrders', 'U') IS NOT NULL
    DROP TABLE dbo.JobOrders;
IF OBJECT_ID('dbo.SalesOrders', 'U') IS NOT NULL
    DROP TABLE dbo.SalesOrders;
IF OBJECT_ID('dbo.Machines', 'U') IS NOT NULL
    DROP TABLE dbo.Machines;
IF OBJECT_ID('dbo.Parts', 'U') IS NOT NULL
    DROP TABLE dbo.Parts;
IF OBJECT_ID('dbo.Customers', 'U') IS NOT NULL
    DROP TABLE dbo.Customers;
GO

------------------------------------------------------------
-- Master Tables
------------------------------------------------------------

-- Customers
CREATE TABLE dbo.Customers (
    CustomerID      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode    VARCHAR(10)  NOT NULL,
    CustomerName    VARCHAR(100) NOT NULL,
    Region          VARCHAR(50)  NULL
);
GO

-- Parts (manufactured items)
CREATE TABLE dbo.Parts (
    PartID              INT IDENTITY(1,1) PRIMARY KEY,
    PartNumber          VARCHAR(20)  NOT NULL,
    PartName            VARCHAR(100) NOT NULL,
    StdCostPerUnit      DECIMAL(18,2) NOT NULL,
    StdSellPricePerUnit DECIMAL(18,2) NOT NULL,
    StdHoursPerUnit     DECIMAL(18,2) NOT NULL
);
GO

-- Machines / Work Centers
CREATE TABLE dbo.Machines (
    MachineID    INT IDENTITY(1,1) PRIMARY KEY,
    MachineCode  VARCHAR(10)  NOT NULL,
    MachineName  VARCHAR(100) NOT NULL,
    MachineGroup VARCHAR(50)  NULL
);
GO

------------------------------------------------------------
-- Fact Tables
------------------------------------------------------------

-- Sales Orders (line-level)
CREATE TABLE dbo.SalesOrders (
    SalesOrderID        INT          NOT NULL,
    SalesOrderLineID    INT          NOT NULL,
    CustomerID          INT          NOT NULL,
    PartID              INT          NOT NULL,
    OrderDate           DATE         NOT NULL,
    PromiseDate         DATE         NOT NULL,
    ShipDate            DATE         NULL,
    OrderQty            INT          NOT NULL,
    ShipQty             INT          NULL,
    UnitPrice           DECIMAL(18,2) NOT NULL,
    CONSTRAINT PK_SalesOrders PRIMARY KEY (SalesOrderID, SalesOrderLineID),
    CONSTRAINT FK_SalesOrders_Customers FOREIGN KEY (CustomerID)
        REFERENCES dbo.Customers (CustomerID),
    CONSTRAINT FK_SalesOrders_Parts FOREIGN KEY (PartID)
        REFERENCES dbo.Parts (PartID)
);
GO

-- Job Orders (production)
CREATE TABLE dbo.JobOrders (
    JobOrderID      INT IDENTITY(1000,1) PRIMARY KEY,
    PartID          INT          NOT NULL,
    MachineID       INT          NOT NULL,
    SalesOrderID    INT          NULL,  -- optional link back to sales order header
    PlannedQty      INT          NOT NULL,
    CompletedQty    INT          NOT NULL,
    ScrapQty        INT          NOT NULL,
    StdHoursPerUnit DECIMAL(18,2) NOT NULL,
    ActualHours     DECIMAL(18,2) NOT NULL,
    DowntimeHours   DECIMAL(18,2) NULL,
    JobStartDate    DATETIME     NOT NULL,
    JobEndDate      DATETIME     NOT NULL,
    CONSTRAINT FK_JobOrders_Parts FOREIGN KEY (PartID)
        REFERENCES dbo.Parts (PartID),
    CONSTRAINT FK_JobOrders_Machines FOREIGN KEY (MachineID)
        REFERENCES dbo.Machines (MachineID),
    CONSTRAINT FK_JobOrders_SalesOrders FOREIGN KEY (SalesOrderID)
        REFERENCES dbo.SalesOrders (SalesOrderID)
);
GO
