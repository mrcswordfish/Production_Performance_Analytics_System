# DAX Measures – Manufacturing Production Analytics

This file documents the DAX measures used in the **Production Performance Analytics System**  
(SQL Server → Power BI manufacturing dashboards).

> Notes:
> - Table names assume:
>   - `SalesOrders`
>   - `JobOrders`
>   - `Customers`
>   - `Parts`
>   - `Machines`
>   - `Date` (DAX calendar table)
> - Measures should be created in a logical “home” table (e.g. Sales KPIs in `SalesOrders`,
>   production KPIs in `JobOrders`, time-intel in `Date`).
> - Calculated columns are only used where row-level flags are needed.

---

## 1. Date Table (Calendar)

> Create this as a **calculated table** in Power BI: `Modeling → New table`.

```DAX
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
    "Year", YEAR ( [Date] ),
    "Month Number", MONTH ( [Date] ),
    "Month Name", FORMAT ( [Date], "MMM" ),
    "Year-Month", FORMAT ( [Date], "YYYY-MM" ),
    "Week", WEEKNUM ( [Date] )
)
