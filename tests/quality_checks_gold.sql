/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs quality checks to validate the integrity, consistency, 
    and accuracy of the Gold Layer. These checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- ==========================================================================
-- Checking "gold.dim_customers"
-- ==========================================================================
-- Check for uniqueness in customer key in gold.dim_customers
-- Expectation: No Results

SELECT
      customer_key,
COUNT(*) as duplicate_count 
FROM gold.dim_customers 
GROUP BY Customer_Key
HAVING COUNT(*) > 1;



-- ==========================================================================
-- Checking "gold.dim_products"
-- ==========================================================================
-- Check for uniqueness in customer key in gold.dim_customers
-- Expectation: No Results

SELECT
      Product_Key,
COUNT(*) as duplicate_count 
FROM gold.dim_products 
GROUP BY Product_Key
HAVING COUNT(*) > 1;



-- ==========================================================================
-- Checking "gold.facts_sales"
-- ==========================================================================
-- Check the data model connectivity between facts and dimensions

SELECT *
FROM gold.fact_sales AS f

LEFT JOIN gold.dim_customers AS c
    ON c.Customer_Key = f.Customer_Key

LEFT JOIN gold.dim_products AS p
    ON p.Product_Key = f.Product_Key

    WHERE p.Product_Key IS NULL OR  c.Customer_Key IS NULL;



