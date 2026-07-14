/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
CREATE VIEW gold.dim_customers AS

SELECT
    ROW_NUMBER() OVER (ORDER BY cst_id) AS Customer_Key,
    ci.cst_id                           AS Customer_Id,
    ci.cst_key                          AS Customer_Number,
    ci.cst_firstname                    AS First_Name,
    ci.cst_lastname                     AS Last_Name,
    la.CNTRY                            AS Country,
    ci.cst_marital_status               AS Marital_Status,

    CASE
        WHEN ci.cst_gendr != 'n/a' THEN ci.cst_gendr      -- CRM is the Master for Gender Info
        ELSE COALESCE(ca.GEN, 'n/a')
    END AS Gender,

    ca.BDATE                            AS Birth_Date,
    ci.cst_create_date                  AS Create_Date

FROM silver.crm_cust_info AS ci

LEFT JOIN silver.erp_CUST_AZ12 AS ca
    ON ci.cst_key = ca.CID

LEFT JOIN silver.erp_LOC_A101 AS la
    ON ci.cst_key = la.CID;

-- ============================================================
-- Create Product Dimension View (Gold Layer)
-- ============================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_products AS

SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_date, pn.prd_key) AS Product_Key,
    pn.prd_id                                                  AS Product_id,
    pn.prd_key                                                 AS Product_number,
    pn.prd_nm                                                  AS Product_name,
    pn.cat_id                                                  AS Category_id,
    pc.cat                                                     AS Category,
    pc.subcat                                                  AS Subcategory,
    pc.MAINTENANCE,
    pn.prd_cost                                                AS Product_Cost,
    pn.prd_line                                                AS Product_Line,
    pn.prd_start_date                                          AS Start_Date

FROM silver.crm_prd_info AS pn

LEFT JOIN silver.erp_PX_CAT_G1V2 AS pc
    ON pn.cat_id = pc.ID

WHERE prd_end_date IS NULL    -- Filter Out All Hisorical Data


-- ============================================================
-- Create Sales Fact View (Gold Layer)
-- ============================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS

SELECT
    sd.sls_ord_num     AS Order_Number,
    --sd.sls_prd_key,
    pr.Product_Key,
    --sd.sls_cust_id,
    cu.Customer_Key,
    sd.sls_order_dt    AS Order_Date,
    sd.sls_ship_dt     AS Shipping_Date,
    sd.sls_due_dt      AS Due_Date,
    sd.sls_sales,
    sd.sls_quantity,
    sd.sls_price

FROM silver.crm_sales_details AS sd

LEFT JOIN gold.dim_products AS pr
    ON sd.sls_prd_key = pr.Product_number

LEFT JOIN gold.dim_customers AS cu
    ON sd.sls_cust_id = cu.Customer_Id;


