/*==============================================================================
                            SILVER LAYER ETL PROCEDURE
==============================================================================

DESCRIPTION
-----------
This stored procedure loads data from the Bronze Layer into the Silver Layer.
It performs data cleaning, standardization, validation, and transformation
to prepare reliable datasets for analytical processing in the Gold Layer.

OBJECTIVES
----------
• Remove duplicate records
• Standardize inconsistent values
• Clean and validate source data
• Transform raw data into business-ready tables
• Log execution time for monitoring
• Handle runtime errors gracefully

SOURCE LAYER
------------
Bronze Layer (Raw Data)

TARGET LAYER
------------
Silver Layer (Clean & Standardized Data)

LOADED TABLES
-------------
• silver.crm_cust_info
• silver.crm_prd_info
• silver.crm_sales_details
• silver.erp_CUST_AZ12
• silver.erp_LOC_A101
• silver.erp_PX_CAT_G1V2

EXECUTION
---------
EXEC silver.load_silver;

==============================================================================*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	 DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	 BEGIN TRY
			 SET @batch_start_time = GETDATE();
			/*====================================================================
			SILVER LAYER DATA LOAD
			PURPOSE : Load CRM and ERP source files into Silver tables
			====================================================================*/

			/*********************************************************************
			STEP 1 : LOAD CUSTOMER DATA
			TABLE    : silver.crm_cust_info
			SOURCE   : cust_info.csv
			*********************************************************************/

			PRINT'===============================================================';
			PRINT' Loading Silver Layer ';
			PRINT'===============================================================';

			PRINT'---------------------------------------------------------------';
			PRINT' Loading CRM Tables ';
			PRINT'---------------------------------------------------------------';

			SET @start_time = GETDATE();
			PRINT'>> Truncating Table: silver.crm_cust_info ';
			TRUNCATE TABLE silver.crm_cust_info;
			INSERT INTO silver.crm_cust_info
            (
                cst_id,
                cst_key,
                cst_firstname,
                cst_lastname,
                cst_marital_status,
                cst_gendr,
                cst_create_date
            )

            SELECT
                cst_id,
                cst_key,

                TRIM(cst_firstname) AS cst_firstname,
                TRIM(cst_lastname)  AS cst_lastname,

                CASE
                    WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                    WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                    ELSE 'n/a'
                END AS cst_marital_status,

                CASE
                    WHEN UPPER(TRIM(cst_gendr)) = 'M' THEN 'Male'
                    WHEN UPPER(TRIM(cst_gendr)) = 'F' THEN 'Female'
                    ELSE 'n/a'
                END AS cst_gendr,

                cst_create_date

            FROM
            (
                SELECT *,
                       ROW_NUMBER() OVER
                       (
                           PARTITION BY cst_id
                           ORDER BY cst_create_date DESC
                       ) AS Flag_Last

                FROM bronze.crm_cust_info

            ) AS Last_Record

            WHERE Flag_Last = 1

            SET @end_time = GETDATE();
			PRINT'>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT'>>-----------------------------';


            /*********************************************************************
			STEP 2 : LOAD PRODUCT DATA
			TABLE    : silver.crm_prd_info
			SOURCE   : prd_info.csv
			*********************************************************************/
			SET @start_time = GETDATE();
			PRINT'>> Truncating Table: silver.crm_prd_info ';
			TRUNCATE TABLE silver.crm_prd_info;

            PRINT '>> Inserting Data Into: silver.crm_prd_info';

            INSERT INTO silver.crm_prd_info
            (
                prd_id,
                cat_id,
                prd_key,
                prd_nm,
                prd_cost,
                prd_line,
                prd_start_date,
                prd_end_date
            )

            SELECT
                prd_id,

                REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,

                SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,

                prd_nm,

                ISNULL(prd_cost, 0) AS prd_cost,

                CASE
                    WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                    WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                    WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                    WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                    ELSE 'n/a'
                END AS prd_line,

                prd_start_date,

                DATEADD
                (
                    DAY,
                    -1,
                    LEAD(prd_start_date)
                    OVER
                    (
                        PARTITION BY prd_key
                        ORDER BY prd_start_date
                    )
                ) AS prd_end_date

            FROM bronze.crm_prd_info;


            /*********************************************************************
			STEP 3 : LOAD SALES DATA
			TABLE    : silver.crm_sales_details
			SOURCE   : sales_details.csv
			*********************************************************************/
			SET @start_time = GETDATE();
			PRINT'>> Truncating Table: silver.crm_sales_details ';
			TRUNCATE TABLE silver.crm_sales_details;

            INSERT INTO silver.crm_sales_details
            (
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,
                sls_order_dt,
                sls_ship_dt,
                sls_due_dt,
                sls_sales,
                sls_quantity,
                sls_price
            )

            SELECT
                sls_ord_num,
                sls_prd_key,
                sls_cust_id,

                CASE
                    WHEN sls_order_dt = 0
                      OR LEN(sls_order_dt) != 8
                    THEN NULL
                    ELSE CAST(CAST(sls_order_dt AS NVARCHAR) AS DATE)
                END AS sls_order_dt,

                CASE
                    WHEN sls_ship_dt = 0
                      OR LEN(sls_ship_dt) != 8
                    THEN NULL
                    ELSE CAST(CAST(sls_ship_dt AS NVARCHAR) AS DATE)
                END AS sls_ship_dt,

                CASE
                    WHEN sls_due_dt = 0
                      OR LEN(sls_due_dt) != 8
                    THEN NULL
                    ELSE CAST(CAST(sls_due_dt AS NVARCHAR) AS DATE)
                END AS sls_due_dt,

                CASE
                    WHEN sls_sales IS NULL
                      OR sls_sales <= 0
                      OR sls_sales <> sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                    ELSE sls_sales
                END AS sls_sales,

                sls_quantity,

                CASE
                    WHEN sls_price IS NULL
                      OR sls_price <= 0
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                    ELSE sls_price
                END AS sls_price

            FROM bronze.crm_sales_details;


            
			/*********************************************************************
			STEP 4 : LOAD ERP CUSTOMER DATA
			TABLE    : silver.erp_CUST_AZ12
			SOURCE   : CUST_AZ12.csv
			*********************************************************************/

			SET @start_time = GETDATE();
			PRINT'---------------------------------------------------------------';
			PRINT' Loading ERP Tables ';
			PRINT'---------------------------------------------------------------';

			PRINT'>> Truncating Table: silver.erp_CUST_AZ12 ';
			TRUNCATE TABLE silver.erp_CUST_AZ12;

            INSERT INTO silver.erp_CUST_AZ12
            (
                cid,
                bdate,
                gen
            )

            SELECT
                CASE
                    WHEN cid LIKE 'NAS%'
                    THEN SUBSTRING(cid, 4, LEN(cid))
                    ELSE cid
                END AS cid,

                CASE
                    WHEN bdate > GETDATE()
                    THEN NULL
                    ELSE bdate
                END AS bdate,

                CASE
                    WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')
                        THEN 'Female'
                    WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')
                        THEN 'Male'
                    ELSE 'n/a'
                END AS gen

            FROM bronze.erp_CUST_AZ12;


            /*********************************************************************
			STEP 5 : LOAD ERP LOCATION DATA
			TABLE    : silver.erp_LOC_A101
			SOURCE   : LOC_A101.csv
			*********************************************************************/
			SET @start_time = GETDATE();
			PRINT'>> Truncating Table: silver.erp_LOC_A101 ';
			TRUNCATE TABLE silver.erp_LOC_A101;

            PRINT '>> Inserting Data Into: silver.erp_LOC_A101';

            INSERT INTO silver.erp_LOC_A101
            (
                cid,
                cntry
            )

            SELECT
                REPLACE(cid, '-', '') AS cid,

                CASE
                    WHEN TRIM(cntry) IN ('US', 'USA')
                        THEN 'United States'

                    WHEN TRIM(cntry) = 'DE'
                        THEN 'Germany'

                    WHEN TRIM(cntry) = ''
                      OR cntry IS NULL
                        THEN 'n/a'

                    ELSE TRIM(cntry)
                END AS cntry

            FROM bronze.erp_LOC_A101;


            /*********************************************************************
			STEP 6 : LOAD ERP PRODUCT CATEGORY DATA
			TABLE    : silver.erp_PX_CAT_G1V2
			SOURCE   : PX_CAT_G1V2.csv
			*********************************************************************/
			SET @start_time = GETDATE();
			PRINT'>> Truncating Table: silver.erp_PX_CAT_G1V2 ';
			TRUNCATE TABLE silver.erp_PX_CAT_G1V2;

            INSERT INTO silver.erp_PX_CAT_G1V2
            (
                id,
                cat,
                subcat,
                maintenance
            )

            SELECT
                id,
                cat,
                subcat,
                maintenance

            FROM bronze.erp_PX_CAT_G1V2;


            SET @end_time = GETDATE();
			PRINT'>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';
			PRINT'>>-----------------------------';
			SET @batch_end_time = GETDATE();
			PRINT'========================================================';
			PRINT'Loading Silver Layer is completed';
			print'   - Total Load Duration: ' + CAST(DATEDIFF(Second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' '+ 'Seconds';

		END TRY
		BEGIN CATCH
		PRINT'============================================================';
		PRINT'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT'Error Message' + ERROR_MESSAGE();
		PRINT'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT'============================================================';
		END CATCH
END
GO

/*====================================================================
EXECUTE SILVER LAYER LOAD PROCEDURE
PURPOSE : Load all CRM and ERP source files into Bronze tables
ACTION  : Truncates existing data and reloads fresh data from CSV files
====================================================================*/

EXEC silver.load_silver;
GO

--DROP PROCEDURE silver.load_silver
