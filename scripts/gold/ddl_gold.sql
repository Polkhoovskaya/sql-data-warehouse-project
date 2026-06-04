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

SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	ci.cst_gndr,
	ci.cst_create_date,
	ca.bdate,
	ca.gen,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;


-- The Master Source of Customer Data is CRM!
-- Correct gender data (gen or cst_gndr)

SELECT 
	ci.cst_id,
	ci.cst_key,
	ci.cst_firstname,
	ci.cst_lastname,
	ci.cst_marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gen,
	ci.cst_create_date,
	ca.bdate,
	la.cntry
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;

-- Rename columns to friendly, meaningful names

SELECT 
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ci.cst_create_date AS created_date,
	ca.bdate AS birthdate,
	la.cntry AS country
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;


-- Sort the columns into logical groups to improve readability

SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS created_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;

-- Create view

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry AS country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END AS gender,
	ca.bdate AS birthdate,
	ci.cst_create_date AS created_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON  ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid;

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

SELECT 
	pr.prd_id,
	pr.prd_key,
	pr.prd_nm,
	pr.prd_cost,
	pr.prd_line,
	pr.prd_start_dt,
	pr.prd_end_dt
FROM silver.crm_prd_info pr;

-- If End Date is Null then it's Currend Info of the Product

SELECT 
	pr.prd_id,
	pr.prd_key,
	pr.prd_nm,
	pr.prd_cost,
	pr.prd_line,
	pr.prd_start_dt,
	pr.prd_end_dt,
	pc.cat,
	pc.subcat,
	pc.maintenance
FROM silver.crm_prd_info pr
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pr.cat_id = pc.id
WHERE pr.prd_end_dt IS NULL; -- Filter out all historical data


-- Check the uniqueness
SELECT prd_key, COUNT(*)
FROM (
	SELECT 
		pr.prd_id,
		pr.prd_key,
		pr.prd_nm,
		pr.prd_cost,
		pr.prd_line,
		pr.prd_start_dt,
		pr.prd_end_dt,
		pc.cat,
		pc.subcat,
		pc.maintenance
	FROM silver.crm_prd_info pr
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pr.cat_id = pc.id
	WHERE pr.prd_end_dt IS NULL) t
GROUP BY prd_key
HAVING COUNT(*) > 1;

-- No Results

-- Sort the columns into logical groups to improve readability

	SELECT 
		pr.prd_id,
		pr.prd_key,
		pr.prd_nm,

		pr.cat_id,
		pc.cat,
		pc.subcat,
		pc.maintenance,

		pr.prd_cost,
		pr.prd_line,
		pr.prd_start_dt
	FROM silver.crm_prd_info pr
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pr.cat_id = pc.id
	WHERE pr.prd_end_dt IS NULL;


-- Rename columns to friendly, meaningful names

	SELECT 
		ROW_NUMBER() OVER (ORDER BY pr.prd_start_dt, pr.prd_key) AS product_key,
		pr.prd_id AS product_id,
		pr.prd_key AS product_number,
		pr.prd_nm AS product_name,

		pr.cat_id AS category_id,
		pc.cat AS category,
		pc.subcat AS subcategory,
		pc.maintenance,

		pr.prd_cost AS cost,
		pr.prd_line AS product_line,
		pr.prd_start_dt AS start_date 
	FROM silver.crm_prd_info pr
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pr.cat_id = pc.id
	WHERE pr.prd_end_dt IS NULL;


-- Create view

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
CREATE VIEW gold.dim_products AS
SELECT 
		ROW_NUMBER() OVER (ORDER BY pr.prd_start_dt, pr.prd_key) AS product_key,
		pr.prd_id AS product_id,
		pr.prd_key AS product_number,
		pr.prd_nm AS product_name,

		pr.cat_id AS category_id,
		pc.cat AS category,
		pc.subcat AS subcategory,
		pc.maintenance,

		pr.prd_cost AS cost,
		pr.prd_line AS product_line,
		pr.prd_start_dt AS start_date 
	FROM silver.crm_prd_info pr
	LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pr.cat_id = pc.id
	WHERE pr.prd_end_dt IS NULL;

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================

SELECT 
	sd.sls_ord_num,
	sd.sls_prd_key,
	sd.sls_cust_id,
	sd.sls_order_dt,
	sd.sls_ship_dt,
	sd.sls_due_dt,
	sd.sls_sales,
	sd.sls_quantity,
	sd.sls_price
FROM silver.crm_sales_details sd;

-- Building Fact
-- Use the dimensions's surrogate keys instead of IDs
-- to easily connect facts with dimensions

SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
ON sd.sls_cust_id = cu.customer_id;


-- Create view

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sls_ord_num AS order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt AS order_date,
	sd.sls_ship_dt AS shipping_date,
	sd.sls_due_dt AS due_date,
	sd.sls_sales AS sales_amount,
	sd.sls_quantity AS quantity,
	sd.sls_price AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
  ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
  ON sd.sls_cust_id = cu.customer_id;
