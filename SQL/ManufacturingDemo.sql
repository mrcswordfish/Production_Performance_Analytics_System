-- Create demo database
CREATE DATABASE ManufacturingDemo;
GO
USE ManufacturingDemo;
GO

-------------------------
-- 1. MASTER TABLES
-------------------------

-- Customers
CREATE TABLE Customers (
    CustomerID      INT IDENTITY(1,1) PRIMARY KEY,
    CustomerCode    VARCHAR(10) NOT NULL,
    CustomerName    VARCHAR(100) NOT NULL,
    Region          VARCHAR(50)  NULL
);

-- Parts
CREATE TABLE Parts (
    PartID              INT IDENTITY(1,1) PRIMARY KEY,
    PartNumber          VARCHAR(20) NOT NULL,
    PartName            VARCHAR(100) NOT NULL,
    StdCostPerUnit      DECIMAL(18,2) NOT NULL,
    StdSellPricePerUnit DECIMAL(18,2) NOT NULL,
    StdHoursPerUnit     DECIMAL(18,2) NOT NULL
);

-- Machines
CREATE TABLE Machines (
    MachineID           INT IDENTITY(1,1) PRIMARY KEY,
    MachineCode         VARCHAR(10) NOT NULL,
    MachineName         VARCHAR(100) NOT NULL,
    MachineGroup        VARCHAR(50)  NULL
);

-------------------------
-- 2. FACT TABLES
-------------------------

-- Sales Orders (line level)
CREATE TABLE SalesOrders (
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
    PRIMARY KEY (SalesOrderID, SalesOrderLineID),
    CONSTRAINT FK_SalesOrders_Customers FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT FK_SalesOrders_Parts     FOREIGN KEY (PartID)     REFERENCES Parts(PartID)
);

-- Job Orders (production)
CREATE TABLE JobOrders (
    JobOrderID          INT IDENTITY(1000,1) PRIMARY KEY,
    PartID              INT          NOT NULL,
    MachineID           INT          NOT NULL,
    SalesOrderID        INT          NULL, -- optional link back to SO header
    PlannedQty          INT          NOT NULL,
    CompletedQty        INT          NOT NULL,
    ScrapQty            INT          NOT NULL,
    StdHoursPerUnit     DECIMAL(18,2) NOT NULL,
    ActualHours         DECIMAL(18,2) NOT NULL,
    JobStartDate        DATETIME     NOT NULL,
    JobEndDate          DATETIME     NOT NULL,
    CONSTRAINT FK_JobOrders_Parts    FOREIGN KEY (PartID)    REFERENCES Parts(PartID),
    CONSTRAINT FK_JobOrders_Machines FOREIGN KEY (MachineID) REFERENCES Machines(MachineID)
);
GO

-------------------------
-- 3. SEED MASTER DATA
-------------------------

INSERT INTO Customers (CustomerCode, CustomerName, Region)
VALUES
 ('CUST01', 'Kootenay Builders Ltd.',   'BC Interior'),
 ('CUST02', 'Pacific Timber Homes',     'Lower Mainland'),
 ('CUST03', 'Rocky Mountain Structures','Alberta'),
 ('CUST04', 'Frontier Woodworks',       'US Northwest');

INSERT INTO Parts (PartNumber, PartName, StdCostPerUnit, StdSellPricePerUnit, StdHoursPerUnit)
VALUES
 ('P-GLB100', 'GLB Beam 100x300',  150.00, 230.00, 0.8),
 ('P-GLB200', 'GLB Beam 200x400',  260.00, 380.00, 1.2),
 ('P-CLT100', 'CLT Panel 100mm',   300.00, 450.00, 1.5),
 ('P-CLT150', 'CLT Panel 150mm',   380.00, 560.00, 1.9);

INSERT INTO Machines (MachineCode, MachineName, MachineGroup)
VALUES
 ('M1', 'Press Line 1',       'Press'),
 ('M2', 'Press Line 2',       'Press'),
 ('M3', 'Finishing Line 1',   'Finishing'),
 ('M4', 'CNC Router 1',       'Machining');
GO

-------------------------
-- 4. SEED SALES ORDERS
-------------------------
-- Assume a sample month (Oct 2025) with mixed OTD and margins

INSERT INTO SalesOrders
(SalesOrderID, SalesOrderLineID, CustomerID, PartID, OrderDate, PromiseDate, ShipDate, OrderQty, ShipQty, UnitPrice)
VALUES
 -- On time, good margin
 (1001, 1, 1, 1, '2025-10-01', '2025-10-10', '2025-10-09', 50, 50, 235.00),
 (1001, 2, 1, 2, '2025-10-01', '2025-10-12', '2025-10-11', 20, 20, 390.00),

 -- Late shipments
 (1002, 1, 2, 3, '2025-10-03', '2025-10-15', '2025-10-18', 30, 30, 460.00),
 (1003, 1, 3, 4, '2025-10-05', '2025-10-20', '2025-10-23', 25, 24, 570.00),

 -- Partial and early
 (1004, 1, 2, 1, '2025-10-07', '2025-10-18', '2025-10-17', 60, 55, 232.00),
 (1005, 1, 4, 3, '2025-10-10', '2025-10-22', '2025-10-21', 40, 40, 455.00),

 -- Mix of on-time and late
 (1006, 1, 1, 4, '2025-10-12', '2025-10-25', '2025-10-24', 15, 15, 565.00),
 (1007, 1, 3, 2, '2025-10-15', '2025-10-28', '2025-10-30', 35, 34, 385.00);
GO

-------------------------
-- 5. SEED JOB ORDERS
-------------------------
-- Assume each job produces 1 sales line or internal stock; include variances.

INSERT INTO JobOrders
(PartID, MachineID, SalesOrderID, PlannedQty, CompletedQty, ScrapQty, StdHoursPerUnit, ActualHours, JobStartDate, JobEndDate)
VALUES
 -- Jobs for SO 1001 (on time, near standard)
 (1, 1, 1001, 50, 50, 1, 0.8,  42.0, '2025-10-03 08:00', '2025-10-07 16:00'),
 (2, 2, 1001, 20, 20, 0, 1.2,  24.5, '2025-10-05 08:00', '2025-10-09 12:00'),

 -- Jobs for SO 1002 (late, over hours)
 (3, 1, 1002, 30, 30, 2, 1.5,  50.0, '2025-10-06 08:00', '2025-10-15 18:00'),

 -- Jobs for SO 1003 (late, scrap + variance)
 (4, 3, 1003, 25, 24, 3, 1.9,  52.0, '2025-10-10 08:00', '2025-10-21 16:00'),

 -- Jobs for SO 1004 (partial, some scrap but efficient)
 (1, 1, 1004, 60, 55, 2, 0.8,  43.0, '2025-10-09 08:00', '2025-10-16 14:00'),

 -- Jobs for SO 1005
 (3, 1, 1005, 40, 40, 1, 1.5,  61.0, '2025-10-12 08:00', '2025-10-21 10:00'),

 -- Jobs for SO 1006
 (4, 3, 1006, 15, 15, 0, 1.9,  28.0, '2025-10-14 08:00', '2025-10-22 12:00'),

 -- Jobs for SO 1007
 (2, 2, 1007, 35, 34, 1, 1.2,  47.0, '2025-10-18 08:00', '2025-10-29 15:00');
GO
