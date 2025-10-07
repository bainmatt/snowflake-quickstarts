"""
Snowflake quickstart: Getting Started with Python.

Adapted from:
https://quickstarts.snowflake.com/guide/getting_started_with_python/#0
"""

# import sys
# if str("src") not in sys.path:
#     sys.path.insert(0, str("src"))

import os
import snowflake.connector
from dotenv import load_dotenv

load_dotenv()
USER = os.getenv('SNOWSQL_USER')
ACCOUNT = os.getenv('SNOWSQL_ACCOUNT')
PASSWORD = os.getenv('SNOWSQL_PWD')


# 3. Test your installation
def check_installation() -> None:
    ctx = snowflake.connector.connect(
        user=USER,
        password=PASSWORD,
        account=ACCOUNT
    )
    cs = ctx.cursor()
    try:
        cs.execute("SELECT current_version()")
        one_row = cs.fetchone()
        assert one_row
        print(one_row[0])
    finally:
        cs.close()
    ctx.close()


# 5. Set session parameters
def open_connection():
    conn = snowflake.connector.connect(
        user=USER,
        password=PASSWORD,
        account=ACCOUNT,
        session_parameters={
            'QUERY_TAG': 'EndOfMonthFinancials',
        }
    )
    # Alternative: connect and then alter session:
    # conn.cursor().execute(
    #     "ALTER SESSION SET QUERY_TAG = 'EndOfMonthFinancials'"
    # )
    return conn


# 6. Create a Warehouse
def create_warehouse(conn, warehouse_name: str) -> None:
    # Implicitly sets new warehouse as the active one
    conn.cursor().execute(f"CREATE WAREHOUSE IF NOT EXISTS {warehouse_name}")
    conn.cursor().execute(f"USE WAREHOUSE {warehouse_name}")


# 7. Create a database
def create_database(conn, db_name: str) -> None:
    # Implicitly sets new database as the active one
    conn.cursor().execute(f"CREATE DATABASE IF NOT EXISTS {db_name}")
    conn.cursor().execute(f"USE DATABASE {db_name}")


# 8. Create a schema
def create_schema(conn, schema_name: str) -> None:
    # Implicitly uses the new schema in the active database
    conn.cursor().execute(f"CREATE SCHEMA IF NOT EXISTS {schema_name}")
    conn.cursor().execute(f"USE SCHEMA {schema_name}")

    # Use schema in another database:
    # conn.cursor().execute(f"USE SCHEMA otherdb.{schema_name}")


# 9. Create a table
def create_table(conn, table_name: str) -> None:
    conn.cursor().execute(
        "CREATE OR REPLACE TABLE "
        f"{table_name}(col1 integer, col2 string)"
    )


# 10. Insert data into the table
def insert_data(conn, table_name: str) -> None:
    conn.cursor().execute(
        f"INSERT INTO {table_name}(col1, col2) "
        "VALUES(123, 'test string1'),(456, 'test string2')"
    )

    # Alternative: load data from an external file (PUT stage, COPY INTO load):
    # conn.cursor().execute("PUT file:///tmp/data/file* @%test_table")
    # conn.cursor().execute("COPY INTO test_table")


# 11. Query data in the table
def query_data(conn) -> None:
    col1, col2 = conn.cursor().execute(
        "SELECT col1, col2 FROM test_table"
    ).fetchone()
    print('{0}, {1}'.format(col1, col2))

    # To print entire columns:
    for (col1, col2) in conn.cursor().execute(
        "SELECT col1, col2 FROM test_table"
    ):
        print('{0}, {1}'.format(col1, col2))


def close_connection(conn) -> None:
    conn.close()


if __name__ == "__main__":
    conn = open_connection()

    create_warehouse(conn, 'tiny_warehouse_mg')
    create_database(conn, 'testdb')
    create_schema(conn, 'testschema')
    create_table(conn, 'test_table')
    insert_data(conn, 'test_table')
    query_data(conn)

    close_connection(conn)
