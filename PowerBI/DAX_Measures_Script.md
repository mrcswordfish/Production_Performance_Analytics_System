# DAX Measures Script – Manufacturing Production Analytics

This file consolidates the key DAX objects used in the **Production Performance Analytics System** (SQL Server → Power BI).

> Note: Power BI still requires you to create tables, columns, and measures individually; this script is a single reference you can copy from.

---

## A. Date Table (Calculated Table)

Create via **Modeling → New table**:

```DAX
// ==============================
// Date Table
// ==============================
Date =
VAR MinDate =
    MINX (
        UNION (
            SELECTCOLUMNS ( SalesOrders, "D", SalesOrders[OrderDate] ),
            SELECTCOLUMNS ( SalesOrders, "D", SalesOrders[ShipDate] ),
            SELECTCOLUMNS ( JobOrders,   "D", JobOrders[JobStartDate] ),
            SELECTCOLUMNS ( JobOrders,   "D", JobOrders[JobEndDate] )
        ),
        [D]
    )
VAR MaxDate =
    MAXX (
        UNION (
            SELECTCOLUMNS ( SalesOrders, "D", SalesOrders[OrderDate] ),
            SELECTCOLUMNS ( SalesOrders, "D", SalesOrders[ShipDate] ),
            SELECTCOLUMNS ( JobOrders,   "D", JobOrders[JobStartDate] ),
            SELECTCOLUMNS ( JobOrders,   "D", JobOrders[JobEndDate] )
        ),
        [D]
    )
RETURN
ADDCOLUMNS (
    CALENDAR ( MinDate, MaxDate ),
    "Year",         YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month Name",   FORMAT ( [Date], "MMM" ),
    "Year-Month",   FORMAT ( [Date], "YYYY-MM" ),
    "Week",         WEEKNUM ( [Date] )
)
```

Then mark `Date[Date]` as the **date table**.

---

## B. Calculated Column – On-Time Flag (SalesOrders)

Create via **New column** in `SalesOrders`:

```DAX
// ==============================
// Calculated Column: OTD flag
// ==============================
OnTimeFlag =
VAR ShipDate  = SalesOrders[ShipDate]
VAR Promise   = SalesOrders[PromiseDate]
RETURN
IF (
    NOT ISBLANK ( ShipDate ) && ShipDate <= Promise,
    1,
    0
)
```

---

## C. Sales Orders – Core Measures

Create as **measures** (recommended home table: `SalesOrders`).

```DAX
// ==============================
// Sales Orders – Core Measures
// ==============================

// Shipment counts
Total Shipments :=
COUNTROWS ( SalesOrders )

OnTime Shipments :=
SUM ( SalesOrders[OnTimeFlag] )

Late Shipments :=
[Total Shipments] - [OnTime Shipments]

// OTD %
OnTime Delivery % :=
DIVIDE ( [OnTime Shipments], [Total Shipments] )

Late Delivery % :=
DIVIDE ( [Late Shipments], [Total Shipments] )

// Volume metrics
Total Ordered Qty :=
SUM ( SalesOrders[OrderQty] )

Total Shipped Qty :=
SUM ( SalesOrders[ShipQty] )

// Revenue & Cost
Revenue :=
SUMX (
    SalesOrders,
    SalesOrders[ShipQty] * SalesOrders[UnitPrice]
)

Std Cost :=
SUMX (
    SalesOrders,
    SalesOrders[ShipQty] * RELATED ( Parts[StdCostPerUnit] )
)

// Margin
Sales Margin :=
[Revenue] - [Std Cost]

Sales Margin % :=
DIVIDE ( [Sales Margin], [Revenue] )
```

---

## D. Sales Orders – Ship-Date-Based OTD (USERELATIONSHIP)

Assumes:
- Active relationship: `Date[Date]` → `SalesOrders[OrderDate]`
- Inactive relationship: `Date[Date]` → `SalesOrders[ShipDate]`

```DAX
// ==============================
// OTD by Ship Date
// ==============================
OnTime Delivery % (Ship Date) :=
VAR OnTime_ShipDate =
    CALCULATE (
        [OnTime Shipments],
        USERELATIONSHIP ( 'Date'[Date], SalesOrders[ShipDate] )
    )
VAR Total_ShipDate =
    CALCULATE (
        [Total Shipments],
        USERELATIONSHIP ( 'Date'[Date], SalesOrders[ShipDate] )
    )
RETURN
DIVIDE ( OnTime_ShipDate, Total_ShipDate )
```

---

## E. Job Orders – Hours & Variance

Create as **measures** in `JobOrders`:

```DAX
// ==============================
// Job Orders – Hours & Variance
// ==============================

// Core hours
Std Hours :=
SUMX (
    JobOrders,
    JobOrders[PlannedQty] * JobOrders[StdHoursPerUnit]
)

Actual Hours :=
SUM ( JobOrders[ActualHours] )

Hours Variance :=
[Actual Hours] - [Std Hours]

Hours Variance % :=
DIVIDE ( [Hours Variance], [Std Hours] )
```

---

## F. Job Orders – Quantities, Yield, Scrap

```DAX
// ==============================
// Job Orders – Quantities, Yield, Scrap
// ==============================
Planned Qty :=
SUM ( JobOrders[PlannedQty] )

Completed Qty :=
SUM ( JobOrders[CompletedQty] )

Scrap Qty :=
SUM ( JobOrders[ScrapQty] )

Yield % :=
DIVIDE ( [Completed Qty], [Planned Qty] )

Scrap % :=
DIVIDE ( [Scrap Qty], [Planned Qty] )
```

---

## G. Job Orders – OEE & Components

```DAX
// ==============================
// Job Orders – OEE
// ==============================

// Units
Good Units :=
[Completed Qty]

Total Units :=
[Completed Qty] + [Scrap Qty]

// Time components
Downtime Hours :=
SUM ( JobOrders[DowntimeHours] )

Total Actual Hours :=
[Actual Hours]

Run Time (Hours) :=
[Total Actual Hours] - [Downtime Hours]

Ideal Time (Hours) :=
SUMX (
    JobOrders,
    JobOrders[CompletedQty] * JobOrders[StdHoursPerUnit]
)

// OEE components
Availability % :=
DIVIDE ( [Run Time (Hours)], [Total Actual Hours] )

Performance % :=
DIVIDE ( [Ideal Time (Hours)], [Run Time (Hours)] )

Quality % :=
DIVIDE ( [Good Units], [Total Units] )

// Overall OEE
OEE % :=
[Availability %] * [Performance %] * [Quality %]
```

---

## H. Utility / Debug Measures

```DAX
// ==============================
// Utility / Debug Measures
// ==============================
Row Count – SalesOrders :=
COUNTROWS ( SalesOrders )

Row Count – JobOrders :=
COUNTROWS ( JobOrders )

Distinct Customers :=
DISTINCTCOUNT ( Customers[CustomerID] )

Distinct Parts :=
DISTINCTCOUNT ( Parts[PartID] )

Distinct Machines :=
DISTINCTCOUNT ( Machines[MachineID] )
```

Use these to sanity-check filters and relationships while you build and debug the model.
