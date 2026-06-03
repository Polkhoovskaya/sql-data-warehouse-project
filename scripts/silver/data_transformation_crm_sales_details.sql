SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details];
  


-- Check for unwanted Spaces (sls_ord_num)
-- Expectation: No Results

SELECT *
FROM [DataWarehouse].[bronze].[crm_sales_details]
WHERE TRIM(sls_ord_num) != sls_ord_num;

-- Result
-- No Result


---------------------------------------------------------------------------------------------------

-- Check that all sls_prd_key and sls_cust_id values exist in the tables with primary keys
-- Expectation: No Results

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_prd_key NOT IN (SELECT prd_key FROM silver.crm_prd_info);

  SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_cust_id NOT IN (SELECT cst_id FROM silver.crm_cust_info);

-- Result
-- No Result

---------------------------------------------------------------------------------------------------

-- Check for zeros (sls_order_dt)
-- Expectation: No Results


SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_order_dt <= 0;


-- Result
-- Dataset contains a large number of zero values

-- Solution
-- Replace with NULL

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,NULLIF(sls_order_dt,0) AS sls_order_dt
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details];


---------------------------------------------------------------------------------------------------
-- The length of the date must be 8

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE LEN(sls_order_dt) != 8;

  -- Result:
  -- 18 rows affected


  -- Check for outliers by validating the boundaries of the date range

  SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_order_dt > 20260101;

-- Result
-- No Result


-- Solution
-- Replace invalid values with NULL

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,NULLIF(sls_order_dt,0) AS sls_order_dt
      ,CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details];

---------------------------------------------------------------------------------------------------


-- Order Data must always be earlier that the Shipping Date or Due Date

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,NULLIF(sls_order_dt,0) AS sls_order_dt
      ,CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_order_dt > sls_ship_dt OR sls_ship_dt > sls_due_dt;

-- Result
-- No Result

---------------------------------------------------------------------------------------------------

-- Check if Sales = Quantity * Price
-- Negative, Zeros, Nulls are Not Allowed!

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,NULLIF(sls_order_dt,0) AS sls_order_dt
      ,CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
  FROM [DataWarehouse].[bronze].[crm_sales_details]
  WHERE sls_sales != sls_quantity * sls_price
  OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
  OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0;

-- Result:
-- 35 rows affected

-- Solution
-- 1 Solution: Data Issues will be fixed direct in source system
-- 2 Solution: Data Issues has to be fixed in data warehouse

-- Rules
-- If Sales is negative, zero, or NULL, derive it using Quantity and Price.
-- If Price is zero or NULL, calculate it using Sales and Quantity.
-- If Price is negative, convert it to a positive value.

SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,NULLIF(sls_order_dt,0) AS sls_order_dt
      ,CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales
       END AS sls_sales
      ,CASE WHEN sls_price <= 0 OR sls_price IS NULL
         THEN sls_sales / NULLIF(sls_quantity, 0)
         ELSE sls_price
       END AS sls_price
      ,sls_quantity
  FROM [DataWarehouse].[bronze].[crm_sales_details];

---------------------------------------------------------------------------------------------------

-- Load crm_sales_details to silver
PRINT '>> Truncating Table: silver.crm_sales_details';
TRUNCATE TABLE silver.crm_sales_details;
PRINT '>> Inserting Data Into: silver.crm_sales_details';
INSERT INTO silver.crm_sales_details (
		sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,sls_order_dt
      ,sls_ship_dt
      ,sls_due_dt
      ,sls_sales
      ,sls_quantity
      ,sls_price
)
SELECT sls_ord_num
      ,sls_prd_key
      ,sls_cust_id
      ,CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
      END AS sls_ship_dt
      ,CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
        ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
      END AS sls_order_dt
      ,CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
         THEN sls_quantity * ABS(sls_price)
         ELSE sls_sales
       END AS sls_sales
      ,CASE WHEN sls_price <= 0 OR sls_price IS NULL
         THEN sls_sales / NULLIF(sls_quantity, 0)
         ELSE sls_price
       END AS sls_price
      ,sls_quantity
  FROM [DataWarehouse].[bronze].[crm_sales_details];

-- Result:
-- 60398 rows added
