import streamlit as st
import pandas as pd
from sqlalchemy import create_engine, text

# --- Configuration ---
DATABASE_URL = "postgresql://postgres:password@localhost:5432/postgres"


@st.cache_resource
def get_engine():
    """
    Return a cached SQLAlchemy engine for reuse across runs.
    """
    return create_engine(DATABASE_URL)


@st.cache_data
def run_query(sql: str) -> pd.DataFrame:
    """
    Execute the given SQL and return a DataFrame.
    """
    engine = get_engine()
    return pd.read_sql_query(text(sql), engine)


# --- Define all reports with questions and SQL queries ---
REPORTS = [
    (
        "What products are sold most often?",
        """
     SELECT
       customerorderitem.prodid,
       product.prodname,
       SUM(customerorderitem.quantity) AS times_sold
     FROM customerorderitem
     JOIN product ON customerorderitem.prodid = product.prodid
     GROUP BY customerorderitem.prodid, product.prodname
     ORDER BY times_sold DESC;
     """,
    ),
    (
        "How lucrative are these sales (total revenue per product)?",
        """
     SELECT
       customerorderitem.prodid,
       product.prodname,
       SUM(customerorderitem.quantity * product.prodlistprice) AS total_revenue
     FROM customerorderitem
     JOIN product ON customerorderitem.prodid = product.prodid
     GROUP BY customerorderitem.prodid, product.prodname
     ORDER BY total_revenue DESC;
     """,
    ),
    (
        "Are there differences between customers in how long they take to pay their bills?",
        """
     SELECT
       customerorder.custid,
       customer.custfname || ' ' || customer.custlname AS customer_name,
       AVG(customerorder.custorderpaymentrecd - customerorder.custorderrecddate) AS avg_days_to_pay
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customerorder.custid, customer_name
     ORDER BY avg_days_to_pay DESC;
     """,
    ),
    (
        "Are there differences between suppliers in how long they take to fill orders?",
        """
     SELECT
       supplierorder.supplierid,
       supplier.suppliername,
       AVG(supplierorder.suporderrecddate - supplierorder.supordersenddate) AS avg_delivery_time
     FROM supplierorder
     JOIN supplier ON supplierorder.supplierid = supplier.supplierid
     GROUP BY supplierorder.supplierid, supplier.suppliername
     ORDER BY avg_delivery_time DESC;
     """,
    ),
    (
        "Does this differ by region (supplier delivery times by state)?",
        """
     SELECT
       supplier.supplierstate,
       AVG(supplierorder.suporderrecddate - supplierorder.supordersenddate) AS avg_delivery_time
     FROM supplierorder
     JOIN supplier ON supplierorder.supplierid = supplier.supplierid
     GROUP BY supplier.supplierstate
     ORDER BY avg_delivery_time DESC;
     """,
    ),
    (
        "Which products have the highest markup (profit margin)?",
        """
     SELECT
       prodid,
       prodname,
       prodlistprice - prodcostprice AS profit_margin
     FROM product
     ORDER BY profit_margin DESC;
     """,
    ),
    (
        "Which products are currently below their reorder threshold?",
        """
     SELECT
       prodid,
       prodname,
       prodonhand,
       prodreorder
     FROM product
     WHERE prodonhand < prodreorder
     ORDER BY prodname;
     """,
    ),
    (
        "What is the average customer order value and payment delay overall?",
        """
     SELECT
       AVG(custorderpayment) AS avg_order_value,
       AVG(custorderpaymentrecd - custorderrecddate) AS avg_days_to_pay
     FROM customerorder;
     """,
    ),
    (
        "Are there regional differences in customer payment delays?",
        """
     SELECT
       customer.custstate,
       AVG(customerorder.custorderpaymentrecd - customerorder.custorderrecddate) AS avg_days_to_pay
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customer.custstate
     ORDER BY avg_days_to_pay DESC;
     """,
    ),
    (
        "How much revenue does SLF receive from customer orders each month?",
        """
     SELECT
       to_char(custorderrecddate, 'YYYY-MM') AS month,
       SUM(custorderpayment) AS total_revenue
     FROM customerorder
     GROUP BY month
     ORDER BY month;
     """,
    ),
    (
        "Which months generate the highest total revenue?",
        """
     SELECT
       to_char(custorderrecddate, 'YYYY-MM') AS month,
       SUM(custorderpayment) AS total_revenue
     FROM customerorder
     GROUP BY month
     ORDER BY total_revenue DESC;
     """,
    ),
    (
        "Which suppliers consistently deliver late (more than 7 days)?",
        """
     SELECT
       supplierorder.supplierid,
       supplier.suppliername,
       COUNT(*) AS late_orders
     FROM supplierorder
     JOIN supplier ON supplierorder.supplierid = supplier.supplierid
     WHERE (supplierorder.suporderrecddate - supplierorder.supordersenddate) > 7
     GROUP BY supplierorder.supplierid, supplier.suppliername
     ORDER BY late_orders DESC;
     """,
    ),
    (
        "Which suppliers receive the highest total dollar value of orders?",
        """
     SELECT
       supplierorder.supplierid,
       supplier.suppliername,
       SUM(supplierorder.suporderamount) AS total_spent
     FROM supplierorder
     JOIN supplier ON supplierorder.supplierid = supplier.supplierid
     GROUP BY supplierorder.supplierid, supplier.suppliername
     ORDER BY total_spent DESC;
     """,
    ),
    (
        "Which suppliers have the most reliable delivery times?",
        """
     SELECT
       supplierorder.supplierid,
       supplier.suppliername,
       STDDEV(supplierorder.suporderrecddate - supplierorder.supordersenddate) AS delivery_variance
     FROM supplierorder
     JOIN supplier ON supplierorder.supplierid = supplier.supplierid
     GROUP BY supplierorder.supplierid, supplier.suppliername
     ORDER BY delivery_variance ASC;
     """,
    ),
    (
        "Which employees placed the most supplier orders?",
        """
     SELECT
       supplierorder.empid,
       employee.empfname || ' ' || employee.emplname AS employee_name,
       COUNT(supplierorder.suporderid) AS orders_placed
     FROM supplierorder
     JOIN employee ON supplierorder.empid = employee.empid
     GROUP BY supplierorder.empid, employee_name
     ORDER BY orders_placed DESC;
     """,
    ),
    (
        "What is the average supplier order value placed by each employee?",
        """
     SELECT
       supplierorder.empid,
       employee.empfname || ' ' || employee.emplname AS employee_name,
       AVG(supplierorder.suporderamount) AS avg_order_amount
     FROM supplierorder
     JOIN employee ON supplierorder.empid = employee.empid
     GROUP BY supplierorder.empid, employee_name
     ORDER BY avg_order_amount DESC;
     """,
    ),
    (
        "What is the average time to fulfill customer orders (receipt to shipment)?",
        """
     SELECT
       AVG(custordershipdate - custorderrecddate) AS avg_fulfillment_time
     FROM customerorder;
     """,
    ),
    (
        "Which customer state has the highest number of orders?",
        """
     SELECT
       customer.custstate,
       COUNT(customerorder.custorderid) AS num_orders
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customer.custstate
     ORDER BY num_orders DESC;
     """,
    ),
    (
        "Which customers are the slowest to pay?",
        """
     SELECT
       customerorder.custid,
       customer.custfname || ' ' || customer.custlname AS customer_name,
       AVG(customerorder.custorderpaymentrecd - customerorder.custorderrecddate) AS avg_days_to_pay
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customerorder.custid, customer_name
     ORDER BY avg_days_to_pay DESC;
     """,
    ),
    (
        "Are there differences in payment delay by customer state?",
        """
     SELECT
       customer.custstate,
       AVG(customerorder.custorderpaymentrecd - customerorder.custorderrecddate) AS avg_days_to_pay
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customer.custstate
     ORDER BY avg_days_to_pay DESC;
     """,
    ),
    (
        "Which customers generate the most total revenue?",
        """
     SELECT
       customerorder.custid,
       customer.custfname || ' ' || customer.custlname AS customer_name,
       SUM(customerorder.custorderpayment) AS total_revenue
     FROM customerorder
     JOIN customer ON customerorder.custid = customer.custid
     GROUP BY customerorder.custid, customer_name
     ORDER BY total_revenue DESC;
     """,
    ),
]


def main():
    st.title("📊 Database Report Dashboard")
    st.markdown("---")

    # Display all reports
    for i, (question, sql) in enumerate(REPORTS, 1):
        st.header(f"Question {i}")
        st.subheader(question)

        # Show SQL query in an expandable section
        with st.expander("Show SQL Query"):
            st.code(sql, language="sql")

        try:
            # Execute query and display results
            df = run_query(sql)
            if df.empty:
                st.warning("No rows returned for this query.")
            else:
                st.dataframe(df)
        except Exception as e:
            st.error(f"Error executing query: {str(e)}")

        st.markdown("---")


if __name__ == "__main__":
    main()
# import streamlit as st
# import pandas as pd
# from sqlalchemy import create_engine, text

# # --- Configuration ---
# DATABASE_URL = "postgresql://postgres:password@localhost:5432/postgres"


# @st.cache_resource
# def get_engine():
#     """
#     Return a cached SQLAlchemy engine for reuse across runs.
#     """
#     return create_engine(DATABASE_URL)


# @st.cache_data
# def run_query(sql: str) -> pd.DataFrame:
#     """
#     Execute the given SQL and return a DataFrame.
#     """
#     engine = get_engine()
#     return pd.read_sql_query(text(sql), engine)


# # --- Define all reports with questions and SQL queries ---
# REPORTS = [
#     (
#         "What products are sold most often?",
#         """
#      SELECT
#        coi.prodid,
#        p.prodname,
#        SUM(coi.quantity) AS times_sold
#      FROM customerorderitem coi
#      JOIN product p ON coi.prodid = p.prodid
#      GROUP BY coi.prodid, p.prodname
#      ORDER BY times_sold DESC;
#      """,
#     ),
#     (
#         "How lucrative are these sales (total revenue per product)?",
#         """
#      SELECT
#        coi.prodid,
#        p.prodname,
#        SUM(coi.quantity * p.prodlistprice) AS total_revenue
#      FROM customerorderitem coi
#      JOIN product p ON coi.prodid = p.prodid
#      GROUP BY coi.prodid, p.prodname
#      ORDER BY total_revenue DESC;
#      """,
#     ),
#     (
#         "Are there differences between customers in how long they take to pay their bills?",
#         """
#      SELECT
#        co.custid,
#        c.custfname || ' ' || c.custlname AS customer_name,
#        AVG(co.custorderpaymentrecd - co.custorderrecddate) AS avg_days_to_pay
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY co.custid, customer_name
#      ORDER BY avg_days_to_pay DESC;
#      """,
#     ),
#     (
#         "Are there differences between suppliers in how long they take to fill orders?",
#         """
#      SELECT
#        so.supplierid,
#        s.suppliername,
#        AVG(so.suporderrecddate - so.supordersenddate) AS avg_delivery_time
#      FROM supplierorder so
#      JOIN supplier s ON so.supplierid = s.supplierid
#      GROUP BY so.supplierid, s.suppliername
#      ORDER BY avg_delivery_time DESC;
#      """,
#     ),
#     (
#         "Does this differ by region (supplier delivery times by state)?",
#         """
#      SELECT
#        s.supplierstate,
#        AVG(so.suporderrecddate - so.supordersenddate) AS avg_delivery_time
#      FROM supplierorder so
#      JOIN supplier s ON so.supplierid = s.supplierid
#      GROUP BY s.supplierstate
#      ORDER BY avg_delivery_time DESC;
#      """,
#     ),
#     (
#         "Which products have the highest markup (profit margin)?",
#         """
#      SELECT
#        prodid,
#        prodname,
#        prodlistprice - prodcostprice AS profit_margin
#      FROM product
#      ORDER BY profit_margin DESC;
#      """,
#     ),
#     (
#         "Which products are currently below their reorder threshold?",
#         """
#      SELECT
#        prodid,
#        prodname,
#        prodonhand,
#        prodreorder
#      FROM product
#      WHERE prodonhand < prodreorder
#      ORDER BY prodname;
#      """,
#     ),
#     (
#         "What is the average customer order value and payment delay overall?",
#         """
#      SELECT
#        AVG(custorderpayment) AS avg_order_value,
#        AVG(custorderpaymentrecd - custorderrecddate) AS avg_days_to_pay
#      FROM customerorder;
#      """,
#     ),
#     (
#         "Are there regional differences in customer payment delays?",
#         """
#      SELECT
#        c.custstate,
#        AVG(co.custorderpaymentrecd - co.custorderrecddate) AS avg_days_to_pay
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY c.custstate
#      ORDER BY avg_days_to_pay DESC;
#      """,
#     ),
#     (
#         "How much revenue does SLF receive from customer orders each month?",
#         """
#      SELECT
#        to_char(custorderrecddate, 'YYYY-MM') AS month,
#        SUM(custorderpayment) AS total_revenue
#      FROM customerorder
#      GROUP BY month
#      ORDER BY month;
#      """,
#     ),
#     (
#         "Which months generate the highest total revenue?",
#         """
#      SELECT
#        to_char(custorderrecddate, 'YYYY-MM') AS month,
#        SUM(custorderpayment) AS total_revenue
#      FROM customerorder
#      GROUP BY month
#      ORDER BY total_revenue DESC;
#      """,
#     ),
#     (
#         "Which suppliers consistently deliver late (more than 7 days)?",
#         """
#      SELECT
#        so.supplierid,
#        s.suppliername,
#        COUNT(*) AS late_orders
#      FROM supplierorder so
#      JOIN supplier s ON so.supplierid = s.supplierid
#      WHERE (so.suporderrecddate - so.supordersenddate) > 7
#      GROUP BY so.supplierid, s.suppliername
#      ORDER BY late_orders DESC;
#      """,
#     ),
#     (
#         "Which suppliers receive the highest total dollar value of orders?",
#         """
#      SELECT
#        so.supplierid,
#        s.suppliername,
#        SUM(so.suporderamount) AS total_spent
#      FROM supplierorder so
#      JOIN supplier s ON so.supplierid = s.supplierid
#      GROUP BY so.supplierid, s.suppliername
#      ORDER BY total_spent DESC;
#      """,
#     ),
#     (
#         "Which suppliers have the most reliable delivery times?",
#         """
#      SELECT
#        so.supplierid,
#        s.suppliername,
#        STDDEV(so.suporderrecddate - so.supordersenddate) AS delivery_variance
#      FROM supplierorder so
#      JOIN supplier s ON so.supplierid = s.supplierid
#      GROUP BY so.supplierid, s.suppliername
#      ORDER BY delivery_variance ASC;
#      """,
#     ),
#     (
#         "Which employees placed the most supplier orders?",
#         """
#      SELECT
#        so.empid,
#        e.empfname || ' ' || e.emplname AS employee_name,
#        COUNT(so.suporderid) AS orders_placed
#      FROM supplierorder so
#      JOIN employee e ON so.empid = e.empid
#      GROUP BY so.empid, employee_name
#      ORDER BY orders_placed DESC;
#      """,
#     ),
#     (
#         "What is the average supplier order value placed by each employee?",
#         """
#      SELECT
#        so.empid,
#        e.empfname || ' ' || e.emplname AS employee_name,
#        AVG(so.suporderamount) AS avg_order_amount
#      FROM supplierorder so
#      JOIN employee e ON so.empid = e.empid
#      GROUP BY so.empid, employee_name
#      ORDER BY avg_order_amount DESC;
#      """,
#     ),
#     (
#         "What is the average time to fulfill customer orders (receipt to shipment)?",
#         """
#      SELECT
#        AVG(custordershipdate - custorderrecddate) AS avg_fulfillment_time
#      FROM customerorder;
#      """,
#     ),
#     (
#         "Which customer state has the highest number of orders?",
#         """
#      SELECT
#        c.custstate,
#        COUNT(co.custorderid) AS num_orders
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY c.custstate
#      ORDER BY num_orders DESC;
#      """,
#     ),
#     (
#         "Which customers are the slowest to pay?",
#         """
#      SELECT
#        co.custid,
#        c.custfname || ' ' || c.custlname AS customer_name,
#        AVG(co.custorderpaymentrecd - co.custorderrecddate) AS avg_days_to_pay
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY co.custid, customer_name
#      ORDER BY avg_days_to_pay DESC;
#      """,
#     ),
#     (
#         "Are there differences in payment delay by customer state?",
#         """
#      SELECT
#        c.custstate,
#        AVG(co.custorderpaymentrecd - co.custorderrecddate) AS avg_days_to_pay
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY c.custstate
#      ORDER BY avg_days_to_pay DESC;
#      """,
#     ),
#     (
#         "Which customers generate the most total revenue?",
#         """
#      SELECT
#        co.custid,
#        c.custfname || ' ' || c.custlname AS customer_name,
#        SUM(co.custorderpayment) AS total_revenue
#      FROM customerorder co
#      JOIN customer c ON co.custid = c.custid
#      GROUP BY co.custid, customer_name
#      ORDER BY total_revenue DESC;
#      """,
#     ),
# ]


# def main():
#     st.title("📊 Database Report Dashboard")
#     st.markdown("---")

#     # Display all reports
#     for i, (question, sql) in enumerate(REPORTS, 1):
#         st.header(f"Question {i}")
#         st.subheader(question)

#         # Show SQL query in an expandable section
#         with st.expander("Show SQL Query"):
#             st.code(sql, language="sql")

#         try:
#             # Execute query and display results
#             df = run_query(sql)
#             if df.empty:
#                 st.warning("No rows returned for this query.")
#             else:
#                 st.dataframe(df)
#         except Exception as e:
#             st.error(f"Error executing query: {str(e)}")

#         st.markdown("---")


# if __name__ == "__main__":
#     main()
