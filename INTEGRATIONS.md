
---
# Integrations & Automation  
Epicor-style REST API → Python → SQL Server → Power BI

This project includes a lightweight but realistic integration pipeline inspired by how Epicor Kinetic exposes data through its REST / BAQ services.

The integration job (`src/python/erp_to_sql_powerbi.py`) performs the following steps:

## 1. Pulls data from an Epicor-style ERP REST API

- Calls endpoints such as `/v1/customers`, `/v1/parts`, `/v1/salesorders`, `/v1/joborders`
- Uses token-based authentication via `Authorization: Bearer <token>`
- Supports incremental loading using a `modifiedSince` query parameter, mimicking common ERP integration patterns

The API shape is intentionally Epicor-like (JSON, entity-based, suitable for BAQ-style queries), but implemented as a simulated endpoint for portfolio purposes.

## 2. Loads and refreshes SQL Server tables

Data is written into the `ManufacturingDemo` database, which underpins the Power BI model:

- **Dimensions** (`Customers`, `Parts`, `Machines`)
  - Loaded via truncate + full reload (simple and robust for small reference tables)
- **Fact tables** (`SalesOrders`, `JobOrders`)
  - Loaded incrementally:
    - Identify keys present in the incoming batch
    - Delete matching rows from the target table
    - Insert the new version of those rows

This pattern is intentionally similar to a basic MERGE/upsert without requiring complex T-SQL.

## 3. Keeps the Power BI semantic model current

Because Power BI connects directly to SQL Server, refreshing the dataset will automatically:

- Update On-Time Delivery metrics (by order and ship date)
- Refresh margin, variance, and OEE KPIs
- Keep customer, part, and machine dimensions in sync with the ERP

In a real deployment, this job would be scheduled via SQL Agent, Windows Task Scheduler, or cron to run nightly (or more frequently for near real-time reporting).

## 4. Configuration & Operations

- Environment variables control connection details:
  - `ERP_BASE_URL`, `ERP_API_KEY`
  - `SQL_SERVER`, `SQL_DATABASE`, `SQL_USER`, `SQL_PASSWORD`
  - `ERP_LOOKBACK_DAYS` for incremental time window
- Logging is written to STDOUT, making it observable under a scheduler
- The code is deliberately kept small and readable, so it can be adapted to a real Epicor REST / BAQ endpoint with minimal changes

This integration demonstrates the ability to design and implement a full data pipeline:
**ERP REST API → Python ETL → SQL Server → Power BI dashboards.**
