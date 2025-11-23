# 🏭 Production Performance Analytics System  
### SQL Server → Power BI | Manufacturing Analytics Case Study  
**By Marc Lomuntad**

---

## 📌 Overview
This project demonstrates a complete manufacturing analytics workflow:

- Designed and built a **SQL Server** relational database
- Imported data directly into **Power BI**
- Constructed a **star schema model**
- Developed a full library of **DAX KPIs**
- Created dashboards for On-Time Delivery, Margin, Production Variance, and OEE

The system simulates a real production environment similar to an engineered wood manufacturer (e.g., laminated beams, CLT panels).

---

## 🏗️ Architecture Diagram

```text
SQL Server → Power BI Data Model → DAX Measures → Dashboards (OTD, Margin, Variance, OEE)
```

---

## 📊 Dashboards Delivered
- **On-Time Delivery Performance**
- **Sales Margin Analysis**
- **Production Variance (Std vs Actual Hours)**
- **Machine Efficiency & OEE Metrics**

---

## 🗄️ 1. SQL Server Database

### Tables Created
- `Customers`
- `Parts`
- `Machines`
- `SalesOrders` (Fact)
- `JobOrders` (Fact)

These tables mirror standard ERP structures found in manufacturing systems such as Epicor Kinetic or IFS.

### Example Outputs
- Late vs on-time shipments  
- Scrap & yield  
- Standard vs actual hours  
- Downtime-driven efficiency metrics  

> In the actual implementation, data is created and stored in SQL Server, then consumed directly by Power BI through a SQL Server connection.

---

## 📈 2. Power BI Data Model
### Star Schema
- Fact Tables:
  - `SalesOrders`
  - `JobOrders`
- Dimensions:
  - `Customers`
  - `Parts`
  - `Machines`
  - `Date` (created in DAX)

### Key Relationships
- CustomerID → SalesOrders  
- PartID → SalesOrders & JobOrders  
- MachineID → JobOrders  
- SalesOrderID → JobOrders  

---

## 📐 3. DAX Measures

### Delivery KPIs
```DAX
OnTimeFlag =
IF ( SalesOrders[ShipDate] <= SalesOrders[PromiseDate], 1, 0 )

OnTime Shipments =
SUM ( SalesOrders[OnTimeFlag] )

Total Shipments =
COUNTROWS ( SalesOrders )

OnTime Delivery % =
DIVIDE ( [OnTime Shipments], [Total Shipments] )
```

### Margin KPIs
```DAX
Revenue =
SUMX (
    SalesOrders,
    SalesOrders[ShipQty] * SalesOrders[UnitPrice]
)

Std Cost =
SUMX (
    SalesOrders,
    SalesOrders[ShipQty] * RELATED ( Parts[StdCostPerUnit] )
)

Sales Margin =
[Revenue] - [Std Cost]

Sales Margin % =
DIVIDE ( [Sales Margin], [Revenue] )
```

### OEE KPIs (Availability, Performance, Quality)
```DAX
Good Units =
SUM ( JobOrders[CompletedQty] )

Total Units =
SUM ( JobOrders[CompletedQty] ) + SUM ( JobOrders[ScrapQty] )

Downtime Hours =
SUM ( JobOrders[DowntimeHours] )

Actual Hours =
SUM ( JobOrders[ActualHours] )

Run Time (Hours) =
[Actual Hours] - [Downtime Hours]

Ideal Time (Hours) =
SUMX (
    JobOrders,
    JobOrders[CompletedQty] * JobOrders[StdHoursPerUnit]
)

Availability % =
DIVIDE ( [Run Time (Hours)], [Actual Hours] )

Performance % =
DIVIDE ( [Ideal Time (Hours)], [Run Time (Hours)] )

Quality % =
DIVIDE ( [Good Units], [Total Units] )

OEE % =
[Availability %] * [Performance %] * [Quality %]
```

Full DAX library, including production variance and yield KPIs, can be defined in the Power BI model.

---

## 🧩 Skills Demonstrated
- SQL Server relational modeling  
- Power BI star schema design  
- DAX measure development  
- Manufacturing KPI reporting (OTD, margin, variance, OEE)  
- Understanding of shop-floor concepts: scrap, yield, standard vs actual hours  
- Documentation and presentation  

---

## 📬 Contact

**Marc Lomuntad**  
📧 marc.lomuntad24@gmail.com  
🔗 LinkedIn: [Your LinkedIn URL]

