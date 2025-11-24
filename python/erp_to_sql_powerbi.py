"""
Nightly integration job:
- Pulls data from an ERP-style REST API (Customers, Parts, SalesOrders, JobOrders)
- Loads/refreshes tables in SQL Server [ManufacturingDemo]
- Power BI reports are built on top of this SQL model
"""

import os
import sys
import logging
from datetime import datetime, timedelta

import requests
import pandas as pd
from sqlalchemy import create_engine, text

# -----------------------------------------------------------------------------
# Configuration (use environment variables in real deployment)
# -----------------------------------------------------------------------------

ERP_BASE_URL = os.getenv("ERP_BASE_URL", "https://api.example-erp.com")
ERP_API_KEY = os.getenv("ERP_API_KEY", "REPLACE_WITH_SECURE_KEY")

SQL_SERVER = os.getenv("SQL_SERVER", "localhost")
SQL_DATABASE = os.getenv("SQL_DATABASE", "ManufacturingDemo")
SQL_USER = os.getenv("SQL_USER", "sa")
SQL_PASSWORD = os.getenv("SQL_PASSWORD", "YourStrong!Passw0rd")

# SQLAlchemy connection string (ODBC Driver may vary by system)
SQL_CONN_STR = (
    f"mssql+pyodbc://{SQL_USER}:{SQL_PASSWORD}"
    f"@{SQL_SERVER}/{SQL_DATABASE}"
    "?driver=ODBC+Driver+17+for+SQL+Server"
)

# For incremental loads (example: pull last 7 days)
LOOKBACK_DAYS = int(os.getenv("ERP_LOOKBACK_DAYS", "7"))

# -----------------------------------------------------------------------------
# Logging setup
# -----------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)],
)

logger = logging.getLogger(__name__)

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

def erp_get(endpoint: str, params: dict = None) -> pd.DataFrame:
    """
    Call ERP REST API and return a DataFrame.
    """
    url = f"{ERP_BASE_URL.rstrip('/')}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"Bearer {ERP_API_KEY}",
        "Accept": "application/json",
    }
    logger.info(f"Requesting ERP endpoint: {url}")
    resp = requests.get(url, headers=headers, params=params, timeout=30)

    if resp.status_code != 200:
        logger.error("ERP API error %s: %s", resp.status_code, resp.text)
        resp.raise_for_status()

    data = resp.json()
    if isinstance(data, dict) and "items" in data:
        data = data["items"]

    df = pd.DataFrame(data)
    logger.info("Received %d rows from %s", len(df), endpoint)
    return df


def load_dimension(df: pd.DataFrame, table_name: str, engine):
    """
    Dimension-style load: truncate and reload (for small reference tables).
    """
    if df.empty:
        logger.warning("No data to load into %s", table_name)
        return

    with engine.begin() as conn:
        logger.info("Truncating table %s", table_name)
        conn.execute(text(f"TRUNCATE TABLE dbo.{table_name}"))

        logger.info("Loading %d rows into %s", len(df), table_name)
        df.to_sql(
            name=table_name,
            con=conn,
            schema="dbo",
            if_exists="append",
            index=False,
        )


def load_fact_incremental(df: pd.DataFrame, table_name: str, pk_columns, engine):
    """
    Simple incremental pattern:
    - Delete existing rows for primary keys found in df
    - Insert new rows

    In real life you'd use MERGE/upsert; this is good enough for portfolio.
    """
    if df.empty:
        logger.warning("No data to load into %s", table_name)
        return

    with engine.begin() as conn:
        # Build key-based delete
        temp_pk_values = df[pk_columns].drop_duplicates()

        # Create a temporary table to hold keys (for efficient delete)
        temp_table = f"#{table_name}_keys"
        logger.info("Creating temp table %s for incremental delete", temp_table)

        cols_def = ", ".join([f"{col} NVARCHAR(100)" for col in pk_columns])
        conn.execute(text(f"CREATE TABLE {temp_table} ({cols_def})"))

        temp_pk_values.to_sql(
            name=temp_table.replace("#", ""),
            con=conn,
            if_exists="append",
            index=False,
        )

        # Delete matching rows
        join_cond = " AND ".join(
            [f"t.{col} = k.{col}" for col in pk_columns]
        )
        delete_sql = text(
            f"DELETE t FROM dbo.{table_name} t "
            f"INNER JOIN {temp_table} k ON {join_cond}"
        )
        logger.info("Deleting existing rows from %s", table_name)
        conn.execute(delete_sql)

        # Insert new data
        logger.info("Loading %d rows into %s", len(df), table_name)
        df.to_sql(
            name=table_name,
            con=conn,
            schema="dbo",
            if_exists="append",
            index=False,
        )


# -----------------------------------------------------------------------------
# Main ETL flow
# -----------------------------------------------------------------------------

def main():
    logger.info("Starting ERP → SQL → Power BI integration job")
    engine = create_engine(SQL_CONN_STR)

    # 1) Dimensions: Customers, Parts, Machines
    customers_df = erp_get("/v1/customers")
    parts_df = erp_get("/v1/parts")
    machines_df = erp_get("/v1/machines")

    # Map ERP field names to your SQL schema columns if needed
    customers_df = customers_df.rename(
        columns={
            "id": "CustomerID",
            "code": "CustomerCode",
            "name": "CustomerName",
            "region": "Region",
        }
    )[["CustomerCode", "CustomerName", "Region"]]

    parts_df = parts_df.rename(
        columns={
            "id": "PartID",
            "number": "PartNumber",
            "name": "PartName",
            "stdCost": "StdCostPerUnit",
            "stdPrice": "StdSellPricePerUnit",
            "stdHours": "StdHoursPerUnit",
        }
    )[["PartNumber", "PartName", "StdCostPerUnit", "StdSellPricePerUnit", "StdHoursPerUnit"]]

    machines_df = machines_df.rename(
        columns={
            "id": "MachineID",
            "code": "MachineCode",
            "name": "MachineName",
            "group": "MachineGroup",
        }
    )[["MachineCode", "MachineName", "MachineGroup"]]

    load_dimension(customers_df, "Customers", engine)
    load_dimension(parts_df, "Parts", engine)
    load_dimension(machines_df, "Machines", engine)

    # 2) Facts: incremental pull of SalesOrders, JobOrders by last-modified date
    since_date = (datetime.utcnow() - timedelta(days=LOOKBACK_DAYS)).strftime("%Y-%m-%dT%H:%M:%SZ")
    params = {"modifiedSince": since_date}

    sales_df = erp_get("/v1/salesorders", params=params)
    jobs_df = erp_get("/v1/joborders", params=params)

    # Map ERP JSON to your SQL schema
    if not sales_df.empty:
        sales_df = sales_df.rename(
            columns={
                "salesOrderId": "SalesOrderID",
                "lineId": "SalesOrderLineID",
                "customerCode": "CustomerCode",
                "partNumber": "PartNumber",
                "orderDate": "OrderDate",
                "promiseDate": "PromiseDate",
                "shipDate": "ShipDate",
                "orderQty": "OrderQty",
                "shipQty": "ShipQty",
                "unitPrice": "UnitPrice",
            }
        )

        # Join to dimension keys if needed (this assumes FK resolved in ERP already)
        load_fact_incremental(
            sales_df[
                [
                    "SalesOrderID",
                    "SalesOrderLineID",
                    "CustomerID",
                    "PartID",
                    "OrderDate",
                    "PromiseDate",
                    "ShipDate",
                    "OrderQty",
                    "ShipQty",
                    "UnitPrice",
                ]
            ],
            table_name="SalesOrders",
            pk_columns=["SalesOrderID", "SalesOrderLineID"],
            engine=engine,
        )

    if not jobs_df.empty:
        jobs_df = jobs_df.rename(
            columns={
                "jobId": "JobOrderID",
                "partNumber": "PartNumber",
                "machineCode": "MachineCode",
                "salesOrderId": "SalesOrderID",
                "plannedQty": "PlannedQty",
                "completedQty": "CompletedQty",
                "scrapQty": "ScrapQty",
                "stdHoursPerUnit": "StdHoursPerUnit",
                "actualHours": "ActualHours",
                "downtimeHours": "DowntimeHours",
                "start": "JobStartDate",
                "end": "JobEndDate",
            }
        )

        load_fact_incremental(
            jobs_df[
                [
                    "JobOrderID",
                    "PartID",
                    "MachineID",
                    "SalesOrderID",
                    "PlannedQty",
                    "CompletedQty",
                    "ScrapQty",
                    "StdHoursPerUnit",
                    "ActualHours",
                    "DowntimeHours",
                    "JobStartDate",
                    "JobEndDate",
                ]
            ],
            table_name="JobOrders",
            pk_columns=["JobOrderID"],
            engine=engine,
        )

    logger.info("ERP → SQL → Power BI integration job completed successfully")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logger.exception("Integration job failed: %s", e)
        sys.exit(1)
