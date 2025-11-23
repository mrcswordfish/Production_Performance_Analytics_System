------------------------------------------------------------
-- seed_data.sql
-- Seed data for ManufacturingDemo database
-- SQL Server (T-SQL)
------------------------------------------------------------

USE ManufacturingDemo;
GO

------------------------------------------------------------
-- Seed Master Data
------------------------------------------------------------

INSERT INTO dbo.Customers (CustomerCode, CustomerName, Region)
VALUES
 ('CUST01', 'Kootenay Builders Ltd.',    'BC Interior'),
 ('CUST02', 'Pacific Timber Homes',      'Lower Mainland'),
 ('CUST03', 'Rocky Mountain Structures', 'Alberta'),
 ('CUST04', 'Frontier Woodworks',        'US Northwest');
GO

INSERT INTO dbo.Parts (PartNumber, PartName, StdCostPerUnit, StdSellPricePerUnit, StdHoursPerUnit)
VALUES
 ('P-GLB100', 'GLB Beam 100x300', 150.00, 230.00, 0.8),
 ('P-GLB200', 'GLB Beam 200x400', 260.00, 380.00, 1.2),
 ('P-CLT100', 'CLT Panel 100mm',  300.00, 450.00, 1.5),
 ('P-CLT150', 'CLT Panel 150mm',  380.00, 560.00, 1.9);
GO

INSERT INTO dbo.Machines (MachineCode, MachineName, MachineGroup)
VALUES
 ('M1', 'Press Line 1',      'Press'),
 ('M2', 'Press Line 2',      'Press'),
 ('M3', 'Finishing Line 1',  'Finishing'),
 ('M4', 'CNC Router 1',      'Machining');
GO

------------------------------------------------------------
-- Seed Sales Orders
-- Sample month of mixed on-time, late, and partial shipments
------------------------------------------------------------

INSERT INTO dbo.SalesOrders
    (SalesOrderID, SalesOrderLineID, CustomerID, PartID,
     OrderDate, PromiseDate, ShipDate,
     OrderQty, ShipQty, UnitPrice)
VALUES
 -- SO 1001: On time, good margin
 (1001, 1, 1, 1, '2025-10-01', '2025-10-10', '2025-10-09', 50, 50, 235.00),
 (1001, 2, 1, 2, '2025-10-01', '2025-10-12', '2025-10-11', 20, 20, 390.00),

 -- SO 1002: Late shipment
 (1002, 1, 2, 3, '2025-10-03', '2025-10-15', '2025-10-18', 30, 30, 460.00),

 -- SO 1003: Late, partial ship
 (1003, 1, 3, 4, '2025-10-05', '2025-10-20', '2025-10-23', 25, 24, 570.00),

 -- SO 1004: Partial, but on time
 (1004, 1, 2, 1, '2025-10-07', '2025-10-18', '2025-10-17', 60, 55, 232.00),

 -- SO 1005: On time
 (1005, 1, 4, 3, '2025-10-10', '2025-10-22', '2025-10-21', 40, 40, 455.00),

 -- SO 1006: On time
 (1006, 1, 1, 4, '2025-10-12', '2025-10-25', '2025-10-24', 15, 15, 565.00),

 -- SO 1007: Late, slight short ship
 (1007, 1, 3, 2, '2025-10-15', '2025-10-28', '2025-10-30', 35, 34, 385.00);
GO

------------------------------------------------------------
-- Seed Job Orders
-- Includes variances, scrap, and downtime for OEE
------------------------------------------------------------

INSERT INTO dbo.JobOrders
    (PartID, MachineID, SalesOrderID,
     PlannedQty, CompletedQty, ScrapQty,
     StdHoursPerUnit, ActualHours, DowntimeHours,
     JobStartDate, JobEndDate)
VALUES
 -- Jobs for SO 1001 (on time, near standard)
 (1, 1, 1001, 50, 50, 1, 0.8,  42.0, 2.0, '2025-10-03 08:00', '2025-10-07 16:00'),
 (2, 2, 1001, 20, 20, 0, 1.2,  24.5, 1.0, '2025-10-05 08:00', '2025-10-09 12:00'),

 -- Job for SO 1002 (late, over hours, more downtime)
 (3, 1, 1002, 30, 30, 2, 1.5,  50.0, 6.0, '2025-10-06 08:00', '2025-10-15 18:00'),

 -- Job for SO 1003 (late, scrap + variance)
 (4, 3, 1003, 25, 24, 3, 1.9,  52.0, 5.0, '2025-10-10 08:00', '2025-10-21 16:00'),

 -- Job for SO 1004 (partial, some scrap but relatively efficient)
 (1, 1, 1004, 60, 55, 2, 0.8,  43.0, 3.0, '2025-10-09 08:00', '2025-10-16 14:00'),

 -- Job for SO 1005
 (3, 1, 1005, 40, 40, 1, 1.5,  61.0, 4.0, '2025-10-12 08:00', '2025-10-21 10:00'),

 -- Job for SO 1006
 (4, 3, 1006, 15, 15, 0, 1.9,  28.0, 1.5, '2025-10-14 08:00', '2025-10-22 12:00'),

 -- Job for SO 1007
 (2, 2, 1007, 35, 34, 1, 1.2,  47.0, 3.5, '2025-10-18 08:00', '2025-10-29 15:00');
GO
