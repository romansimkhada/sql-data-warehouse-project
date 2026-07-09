/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/

-- ====================================================================
-- Checking 'silver.crm_cust_info'
-- ====================================================================
-- Check for NULLs or Duplicates in Primary Key
-- Expectation: No Results



/*==========================================
      CHECKING "silver.crm_cust_info"
 ===========================================*/


/*==============================================================================
    CHECK DATA STANDARDIZATION & CONSISTENCY
==============================================================================*/

SELECT DISTINCT
    cst_gendr
FROM silver.crm_cust_info;



/*==============================================================================
    VERIFY DATA STANDARDIZATION
    EXPECTATION:
        • Male
        • Female
        • n/a
==============================================================================*/

SELECT DISTINCT
    cst_gendr
FROM silver.crm_cust_info;



/*==============================================================================
    VERIFY PRIMARY KEY QUALITY
    EXPECTATION:
        • No duplicate customer IDs
        • No NULL customer IDs
==============================================================================*/

SELECT *
FROM silver.crm_cust_info;

SELECT
    cst_id,
    COUNT(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1
    OR cst_id IS NULL;





/*================================================
            CHECKING silver.crm_prd_info
 =================================================*/


  /*==============================================================================
     VALIDATE SILVER LAYER
==============================================================================*/

SELECT *
FROM silver.crm_prd_info;



/*------------------------------------------------------------------------------
    Verify Primary Key Quality
    Expectation:
        • No duplicate Product IDs
        • No NULL Product IDs
------------------------------------------------------------------------------*/

SELECT
    prd_id,
    COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1
    OR prd_id IS NULL;



/*------------------------------------------------------------------------------
    Verify Product Names
    Expectation:
        • No leading or trailing spaces
------------------------------------------------------------------------------*/

SELECT
    prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm);



/*------------------------------------------------------------------------------
    Verify Product Cost
    Expectation:
        • No NULL values
        • No negative values
------------------------------------------------------------------------------*/

SELECT
    prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0
   OR prd_cost IS NULL;



/*------------------------------------------------------------------------------
    Verify Product Line Standardization
------------------------------------------------------------------------------*/

SELECT DISTINCT
    prd_line
FROM silver.crm_prd_info;



/*------------------------------------------------------------------------------
    Verify Date Order
    Expectation:
        • End Date should never be before Start Date
------------------------------------------------------------------------------*/

SELECT *
FROM silver.crm_prd_info
WHERE prd_end_date < prd_start_date;








/*==============================================
      CHECKING "silver.crm_sales_details"
================================================*/

/*******************************************

 Checking for silver.crm_sales_details Tables

 ********************************************/

    SELECT DISTINCT
        sls_sales ,
        sls_quantity,
        sls_price

    FROM silver.crm_sales_details
    WHERE
            sls_sales != sls_quantity * sls_price
            OR sls_sales IS NULL
            OR sls_quantity IS NULL
            OR sls_price IS NULL
            OR sls_sales <= 0
            OR sls_quantity <= 0
            OR sls_price <= 0
    ORDER BY sls_sales,sls_quantity,sls_price;

 /*==============================================================================
                     CHECK FOR INVALID ORDER DATES
==============================================================================*/

SELECT
    sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0;

SELECT
    NULLIF(sls_order_dt, 0) AS sls_order_dt
FROM silver.crm_sales_details
WHERE
    -- sls_order_dt <= 0
    -- OR LEN(sls_order_dt) != 8
    sls_order_dt > 20500101
    OR sls_order_dt < 19000101;







/*==============================================================================
                  CHECK FOR INVALID SHIP DATES
==============================================================================*/

SELECT
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_ship_dt <= 0;

SELECT
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt
FROM silver.crm_sales_details
WHERE
    -- sls_ship_dt <= 0
    -- OR LEN(sls_ship_dt) != 8
    sls_ship_dt > 20500101
    OR sls_ship_dt < 19000101;


/*==============================================================================
    CHECK FOR INVALID DUE DATES
==============================================================================*/

SELECT
    sls_due_dt
FROM silver.crm_sales_details
WHERE sls_due_dt <= 0;

SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt
FROM silver.crm_sales_details
WHERE
    -- sls_due_dt <= 0
    -- OR LEN(sls_due_dt) != 8
    sls_due_dt > 20500101
    OR sls_due_dt < 19000101;
 

/*==============================================================================
    CHECK DATE CONSISTENCY
    Order Date should not be later than Ship Date or Due Date
==============================================================================*/

SELECT *
FROM silver.crm_sales_details
WHERE
    sls_order_dt > sls_ship_dt
    OR sls_order_dt > sls_due_dt;


/*==============================================================================
    CHECK SALES CONSISTENCY

    Expected:
        Sales = Quantity × Price

    Also Check:
        • NULL values
        • Negative values
        • Zero values
==============================================================================*/

SELECT DISTINCT
    sls_sales AS old_sls_sales,
    sls_quantity,
    sls_price AS old_sls_price,
    CASE WHEN sls_sales IS NULL OR sls_sales < = 0 OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales
     END AS sls_sales,

     CASE WHEN sls_price IS NULL OR sls_price < =0
          THEN sls_sales / NULLIF(sls_quantity, 0)
          ELSE sls_price
     END AS sls_price

FROM silver.crm_sales_details
WHERE
    sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0
    ORDER BY sls_sales,sls_quantity,sls_price;


    /*=================================================
              CHECKING silver.erp_CUST_AZ12
    ==================================================*/

/*==============================================================================
              CUSTOMER ID VALIDATION
    PURPOSE  : Check whether ERP Customer IDs exist in CRM Customer table.
==============================================================================*/

SELECT

    cid,

    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END AS cid,

    bdate,
    gen

FROM bronze.erp_CUST_AZ12

WHERE
    CASE
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
        ELSE cid
    END NOT IN
    (
        SELECT DISTINCT cst_key
        FROM silver.crm_cust_info
    );



/*==============================================================================
              IDENTIFY OUT-OF-RANGE BIRTH DATES
    PURPOSE  : Detect invalid Birth Dates.
==============================================================================*/

SELECT DISTINCT

    bdate


FROM silver.erp_CUST_AZ12

WHERE
      bdate < '1924-01-01'
   OR bdate > GETDATE();



/*==============================================================================
              DATA STANDARDIZATION & CONSISTENCY CHECK
    PURPOSE  : Verify standardized Gender values.
==============================================================================*/

SELECT DISTINCT

    gen,

    CASE
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')   THEN 'Male'
        ELSE 'n/a'
    END AS gen

FROM silver.erp_CUST_AZ12;






/*=====================================================
              CHECKING "silver.erp_LOC_A101"
=======================================================*/


/*==============================================================================
    DATA STANDARDIZATION & CONSISTENCY CHECK
==============================================================================*/

SELECT DISTINCT
    cntry

FROM silver.erp_LOC_A101

ORDER BY cntry;





/*================================================================================
                     CHECKING"silver.erp_PX_CAT_G1V2"
=================================================================================*/



/*==============================================================================
                   CHECK FOR UNWANTED SPACES
==============================================================================*/

SELECT *
FROM silver.erp_PX_CAT_G1V2
WHERE cat ! = TRIM(cat)
   OR subcat ! = TRIM(subcat)
   OR maintenance ! = TRIM(maintenance);



/*==============================================================================
                  DATA STANDARDIZATION & CONSISTENCY CHECKS
==============================================================================*/

SELECT DISTINCT
    cat
FROM silver.erp_PX_CAT_G1V2;

SELECT DISTINCT
    subcat
FROM silver.erp_PX_CAT_G1V2;

SELECT DISTINCT
    maintenance
FROM silver.erp_PX_CAT_G1V2;







