/*======================================================================
    DATA WAREHOUSE PROJECT
    LAYER      : BRONZE
    SCRIPT     : ddl_bronze_tables.sql

    PURPOSE:
    Create all CRM and ERP source tables required for raw data
    ingestion into the Bronze Layer.

    OBJECTS:
      - bronze.crm_cust_info
      - bronze.crm_prd_info
      - bronze.crm_sales_details
      - bronze.erp_CUST_AZ12
      - bronze.erp_LOC_A101
      - bronze.erp_PX_CAT_G1V2

    PROCESS:
      1. Check for existing tables
      2. Drop existing tables if found
      3. Recreate tables with defined schema

    AUTHOR : Roman Simkhada
======================================================================*/

/*==============================================================
  TABLE: bronze.crm_cust_info
  PURPOSE: Store customer master information from CRM system
==============================================================*/
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info(
    cst_id INT,
    cst_key NVARCHAR(50),
    cst_firstname NVARCHAR(50),
    cst_lastname NVARCHAR(50),
    cst_marital_status NVARCHAR(50),
    cst_gendr NVARCHAR(50),
    cst_create_date DATE
);


/*==============================================================
  TABLE: bronze.crm_prd_info
  PURPOSE: Store product master information from CRM system
==============================================================*/
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info(
    prd_id INT,
    prd_key NVARCHAR(50),
    prd_nm NVARCHAR(50),
    prd_cost INT,
    prd_line NVARCHAR(50),
    prd_start_date DATE,
    prd_end_date DATE
);


/*==============================================================
  TABLE: bronze.crm_sales_details
  PURPOSE: Store sales transaction details from CRM system
==============================================================*/
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details(
    sls_ord_num NVARCHAR(50),
    sls_prd_key NVARCHAR(50),
    sls_cust_id INT,
    sls_order_dt INT,
    sls_ship_dt INT,
    sls_due_dt INT,
    sls_sales INT,
    sls_quantity INT,
    sls_price INT
);


/*==============================================================
  TABLE: bronze.erp_CUST_AZ12
  PURPOSE: Store customer demographic information from ERP
==============================================================*/
IF OBJECT_ID('bronze.erp_CUST_AZ12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_CUST_AZ12;

CREATE TABLE bronze.erp_CUST_AZ12(
    CID NVARCHAR(50),
    BDATE DATE,
    GEN NVARCHAR(50)
);


/*==============================================================
  TABLE: bronze.erp_LOC_A101
  PURPOSE: Store customer location information from ERP
==============================================================*/
IF OBJECT_ID('bronze.erp_LOC_A101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_LOC_A101;

CREATE TABLE bronze.erp_LOC_A101(
    CID NVARCHAR(50),
    CNTRY NVARCHAR(50)
);


/*==============================================================
  TABLE: bronze.erp_PX_CAT_G1V2
  PURPOSE: Store product category and maintenance information
==============================================================*/
IF OBJECT_ID('bronze.erp_PX_CAT_G1V2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_PX_CAT_G1V2;

CREATE TABLE bronze.erp_PX_CAT_G1V2(
    ID NVARCHAR(50),
    CAT NVARCHAR(50),
    SUBCAT NVARCHAR(50),
    MAINTENANCE NVARCHAR(50)
);
