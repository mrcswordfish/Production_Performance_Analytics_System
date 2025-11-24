# 🏭 Production Performance Analytics System  
### Epicor-style REST API → Python ETL → SQL Server → Power BI  
**By Marc Lomuntad**

This project demonstrates a complete, production-style analytics solution for a manufacturing environment.  
It combines:
- **Source**: SQL Server schema modeled after an ERP (Customers, Parts, SalesOrders, JobOrders, Machines)
- **Integration**: Python job that pulls data from an Epicor-like REST API pattern and loads SQL Server
- **Semantic Model**: Power BI with DAX measures for On-Time Delivery, margin, variance, yield, and OEE
- **Dashboards**: KPI views for leadership and operations (service, profitability, production efficiency) typically used in real engineered-wood, metal fabrication, and general manufacturing operations.

---

# 🏗️ Architecture Overview

```
This project simulates a realistic ERP → Analytics stack:

1. **Epicor-style ERP REST API (simulated)**  
   - Endpoints such as `/customers`, `/parts`, `/salesorders`, `/joborders`  
   - JSON responses, token-based auth, similar to Epicor Kinetic REST / BAQ patterns.

2. **Python Integration Job** (`/src/python/erp_to_sql_powerbi.py`)  
   - Calls the ERP-like API on a schedule  
   - Performs basic transformations and incremental loading  
   - Writes into the `ManufacturingDemo` database in SQL Server

3. **SQL Server Data Model** (`/src/sql`)  
   - Tables: `Customers`, `Parts`, `Machines`, `SalesOrders`, `JobOrders`  
   - Clean relational structure suitable for analytics  
   - Seed data to make the dashboards immediately usable

4. **Power BI Semantic Model & DAX** (`/src/dax/DAX_Measures_Script.md`)  
   - Date table & relationships  
   - Service KPIs: On-Time Delivery % (OrderDate and ShipDate via USERELATIONSHIP)  
   - Financial KPIs: Revenue, Std Cost, Margin, Margin %  
   - Production KPIs: Std vs Actual Hours, Hours Variance %  
   - OEE: Availability, Performance, Quality, and OEE %

5. **Dashboards & Portfolio Website** (`/website/index.html`)  
   - Static case-study site with screenshots and narrative  
   - Dashboard screenshots for OTD, Margin, Variance, and OEE views
```

---

# 🔗 Portfolio Website  
A dedicated case-study website is included (`/website/index.html`) featuring:

- Project summary
- Data model
- KPIs
- **Interactive Power BI screenshots**
- Integration & Automation section (Epicor-style REST → SQL → Power BI)

---

# 🧩 1. SQL Server Data Model

### Tables Created  
- **Customers**  
- **Parts**  
- **Machines**  
- **SalesOrders** *(fact)*  
- **JobOrders** *(fact)*  

These mirror ERP structures found in systems like **Epicor Kinetic** and **IFS**, manufacturing modules.

### Use Cases Enabled  
- Late vs on-time shipments  
- Margin & profitability tracking  
- Standard vs actual hours variance  
- Scrap, yield, and downtime efficiency  
- OEE: Availability, Performance, Quality  

SQL scripts located at:  
`/src/sql/create_tables.sql`  
`/src/sql/seed_data.sql`

---

# ⚙️ 2. Integrations & Automation (Epicor-style REST → SQL Server → Power BI)

This solution includes a **Python ETL job** simulating how a real ERP integration behaves.

📄 Full documentation: `/INTEGRATIONS.md`  
📄 Script: `/src/python/erp_to_sql_powerbi.py`

### ✔ Features  
- Calls **Epicor-inspired REST endpoints**:
  - `/v1/customers`
  - `/v1/parts`
  - `/v1/salesorders?modifiedSince=...`
  - `/v1/joborders?modifiedSince=...`
- Bearer-token authentication  
- Incremental loading by last-modified date  
- Dimension loads: truncate + reload  
- Fact loads: delete & reinsert (simple MERGE pattern)  
- Logs progress & errors  
- Designed for SQL Agent / Task Scheduler / cron  

### ✔ Why this matters  
Manufacturing organizations depend on:

- Timely ERP data
- Clean dimensional models
- Automated refresh pipelines
- Governed KPI dashboards

This project demonstrates the full workflow expected of a modern **ERP Business Analyst**.

---

# 📈 3. Power BI Semantic Model

### Star Schema  
**Fact tables:**  
- `SalesOrders`
- `JobOrders`

**Dimensions:**  
- `Customers`  
- `Parts`  
- `Machines`  
- `Date` (generated in DAX)

### Core Relationships  
- CustomerID → SalesOrders  
- PartID → SalesOrders, JobOrders  
- MachineID → JobOrders  
- SalesOrderID → JobOrders  
- Active: Date → OrderDate  
- Inactive: Date → ShipDate *(used via `USERELATIONSHIP`)*

---

# 🧠 4. DAX KPI Library

All measures consolidated in:  
`/src/PowerBI/DAX_Measures_Script.md`

Includes:

### 📦 Service KPIs  
- On-Time Delivery %  
- Ship-date OTD using `USERELATIONSHIP`  
- Late Delivery %  

### 💰 Margin KPIs  
- Revenue  
- Standard Cost  
- Margin ($ and %)  

### ⚙️ Production KPIs  
- Standard vs Actual Hours  
- Hours Variance %  
- Scrap %  
- Yield %  

### 🏭 OEE KPIs  
- Availability  
- Performance  
- Quality  
- OEE %  

Each metric is modeled exactly as used in real manufacturing plants.

---

# 📊 5. Dashboards Delivered

Screenshots: `/docs/PowerBI_Screenshots/`

- **On-Time Delivery Performance**
- **Sales & Margin Analysis**
- **Production Variance (Std vs Actual Hours)**
- **Machine Efficiency & OEE**

All visuals are clickable on the portfolio website thanks to a custom lightbox script.

---

# 🧠 Skills Demonstrated

### ERP & Data  
- Epicor Kinetic–style REST patterns  
- SQL Server modeling (dimensions & facts)  
- Manufacturing concepts: OTD, costing, variance, scrap, OEE  

### Analytics & Engineering  
- Python ETL development  
- REST API consumption  
- Incremental load logic  
- DAX semantic modeling  
- Star schema design  
- Power BI dashboarding  

### Professional Capability  
- Documentation  
- Architecture diagrams  
- Analyst-style communication  
- Production-minded design patterns  

---

# 📬 Contact

**Marc Lomuntad**  
📧 marc.lomuntad24@gmail.com  
🔗 LinkedIn: (insert your LinkedIn URL here)

---

# 🎯 Summary  
This repository showcases a complete ERP-style analytics project that includes:

✔ Data modeling  
✔ Integrations & automation  
✔ Semantic modeling  
✔ Manufacturing KPI dashboards  
✔ A professional portfolio website  

It demonstrates the technical depth and workflow expected of a **Modern ERP Business Analyst / Power BI Analyst / Data Analyst with manufacturing domain expertise**.
