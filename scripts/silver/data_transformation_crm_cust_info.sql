-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT
	cst_id,
	COUNT(*) duplicates
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- Result
--  cst_id duplicates
--  29449	    2
--  29473	    2
--  29433	    2
--  NULL	    3
--  29483	    2
--  29466	    3


-- Solution
-- Keep the most recent records using the information from the cst_create_date parameter column

SELECT *
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;

---------------------------------------------------------------------------------------------------
-- Check for unwanted Spaces (all the string values)
-- Expectation: No Results

SELECT cst_firstname
FROM bronze.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);

-- Result
--  cst_firstname
--   Jon
--   Elizabeth
--    Lauren
--   Ian 
--  ...

-- Solution
-- Trim off any unwanted spaces

SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS sct_firstname,
	TRIM(cst_lastname) AS sct_last_name,
	cst_marital_status,
	cst_gndr,
	cst_create_date
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;


---------------------------------------------------------------------------------------------------
-- Data Standardization & Consistency

SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info;

-- Result
-- cst_gndr
--  NULL
--  F
--  M

-- Solution
-- Add friendly full names instead of having abbreviations

SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS sct_firstname,
	TRIM(cst_lastname) AS sct_last_name,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
  	WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
  	ELSE 'n/a'
  END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Femail'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;


---------------------------------------------------------------------------------------------------
-- Checking the data type in a date column

SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze'
	AND TABLE_NAME = 'crm_cust_info' 
	AND COLUMN_NAME = 'cst_create_date';

-- Result
-- DATA_TYPE
--  date

---------------------------------------------------------------------------------------------------
-- Load crm_cust_info to silver

PRINT '>> Truncation Table: silver.crm_cust_info';
TRUNCATE TABLE silver.crm_cust_info;
PRINT '>> Inserting Data Into: silver.crm_cust_info';
INSERT INTO silver.crm_cust_info (
	cst_id,
	cst_key,
	cst_firstname,
	cst_lastname,
	cst_marital_status,
	cst_gndr,
	cst_create_date
)
SELECT 
	cst_id,
	cst_key,
	TRIM(cst_firstname) AS cst_firstname,
	TRIM(cst_lastname) AS cst_lastname,
	CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
		WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
		ELSE 'n/a'
	END cst_marital_status,
	CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Femail'
		WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
		ELSE 'n/a'
	END cst_gndr,
	cst_create_date
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
	FROM bronze.crm_cust_info
	WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1;
