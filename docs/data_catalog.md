# Gold Layer Data Catalogue

## Overview

The **Gold Layer** contains business-ready dimensional models designed for reporting, dashboarding, and analytical workloads. It transforms the cleaned data from the Silver Layer into a star schema consisting of dimension and fact views.

---

# 1. `gold.dim_customers`

### Description

The **Customer Dimension** provides a consolidated view of customer information by combining CRM customer records with ERP demographic and location data. It serves as the master customer dimension for analytical reporting.

### Data Source

| Source Table | Purpose |
|--------------|---------|
| `silver.crm_cust_info` | Primary customer information from the CRM system. |
| `silver.erp_CUST_AZ12` | Customer demographic information (gender and birth date). |
| `silver.erp_LOC_A101` | Customer location information (country). |

### Columns

| Column | Description |
|---------|-------------|
| Customer_Key | Surrogate key generated using `ROW_NUMBER()`. |
| Customer_Id | Original customer ID from the CRM system. |
| Customer_Number | Business customer identifier. |
| First_Name | Customer first name. |
| Last_Name | Customer last name. |
| Country | Customer country obtained from ERP location data. |
| Marital_Status | Customer marital status. |
| Gender | Customer gender. CRM data is prioritized over ERP data; if unavailable, ERP gender is used, otherwise `'n/a'`. |
| Birth_Date | Customer birth date. |
| Create_Date | Date the customer record was created in the CRM system. |

---

# 2. `gold.dim_products`

### Description

The **Product Dimension** contains the latest active product information enriched with category metadata. Historical product versions are excluded to ensure only current products are available for reporting.

### Data Source

| Source Table | Purpose |
|--------------|---------|
| `silver.crm_prd_info` | Product master information. |
| `silver.erp_PX_CAT_G1V2` | Product category and subcategory information. |

### Columns

| Column | Description |
|---------|-------------|
| Product_Key | Surrogate key generated using `ROW_NUMBER()`. |
| Product_id | Original product ID. |
| Product_number | Business product identifier. |
| Product_name | Product name. |
| Category_id | Product category identifier. |
| Category | Product category name. |
| Subcategory | Product subcategory. |
| MAINTENANCE | Product maintenance classification. |
| Product_Cost | Cost of the product. |
| Product_Line | Product line classification. |
| Start_Date | Product activation/start date. |

### Business Rule

| Rule | Description |
|------|-------------|
| Active Products Only | Only active products are included by filtering records where `prd_end_date IS NULL`. |

---

# 3. `gold.fact_sales`

### Description

The **Sales Fact** stores transactional sales data and connects customer and product dimensions to support business intelligence and analytical reporting.

### Data Source

| Source Table | Purpose |
|--------------|---------|
| `silver.crm_sales_details` | Sales transaction records. |
| `gold.dim_products` | Provides product dimension details. |
| `gold.dim_customers` | Provides customer dimension details. |

### Columns

| Column | Description |
|---------|-------------|
| Order_Number | Unique sales order number. |
| Product_number | Product identifier linked to the Product Dimension. |
| Customer_Key | Surrogate customer key linked to the Customer Dimension. |
| Order_Date | Date the order was placed. |
| Shipping_Date | Date the order was shipped. |
| Due_Date | Order due date. |
| sls_sales | Total sales amount. |
| sls_quantity | Quantity sold. |
| sls_price | Unit selling price. |

---

# Data Model Relationships

| Fact Table | Dimension Table | Join Key |
|------------|-----------------|----------|
| `fact_sales` | `dim_customers` | `Customer_Key` |
| `fact_sales` | `dim_products` | `Product_number` |

---

# Gold Layer Quality Checks

| Validation | Purpose |
|------------|---------|
| `SELECT * FROM gold.dim_customers` | Verify the Customer Dimension view. |
| `SELECT * FROM gold.dim_products` | Verify the Product Dimension view. |
| `SELECT * FROM gold.fact_sales` | Verify the Sales Fact view. |
| Customer Join Validation | Detect missing customer references from the fact table. |
| `SELECT DISTINCT Gender` | Validate customer gender values. |

---

## Purpose

The Gold Layer provides a business-friendly star schema that:

- Supports dashboards and reporting tools.
- Enables efficient analytical queries.
- Consolidates customer, product, and sales information.
- Provides consistent business definitions across reports.
- Serves as the final presentation layer of the data warehouse.
