SELECT  *
  FROM [DataWarehouse].[bronze].[crm_prd_info];


-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result

SELECT prd_id, COUNT(*)
FROM [DataWarehouse].[bronze].[crm_prd_info]
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL;

-- Result
-- No Result


---------------------------------------------------------------------------------------------------

-- Split prd_key into cat_id and prd_key
-- Replace "-" with "_" in cat_id

SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,prd_cost
      ,prd_line
      ,prd_start_dt
      ,prd_end_dt
  FROM [DataWarehouse].[bronze].[crm_prd_info];


---------------------------------------------------------------------------------------------------

-- Check for unwanted Spaces (prd_name)
-- Expectation: No Results


SELECT * 
FROM [DataWarehouse].[bronze].[crm_prd_info]
WHERE TRIM(prd_nm) != prd_nm;


-- Result
-- No Result

---------------------------------------------------------------------------------------------------


-- Check for NULLs or Negative Numbers
-- Expectation: No Results

SELECT prd_id, prd_cost
FROM [DataWarehouse].[bronze].[crm_prd_info]
WHERE prd_cost IS NULL OR prd_cost < 0;

-- Result
--  prd_id  prd_key 
--  210     NULL
--  211     NULL

-- Solution
-- Replace NULL values with a specified replacement value


SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,prd_line
      ,prd_start_dt
      ,prd_end_dt
FROM [DataWarehouse].[bronze].[crm_prd_info];

---------------------------------------------------------------------------------------------------

-- Data Standardization & Consistency (prd_line table)

SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
       END AS prd_line
      ,prd_start_dt
      ,prd_end_dt
FROM [DataWarehouse].[bronze].[crm_prd_info];


---------------------------------------------------------------------------------------------------


-- Check for Invalid Date Orders
-- Expectation: No Results

SELECT *
FROM [DataWarehouse].[bronze].[crm_prd_info]
WHERE prd_start_dt > prd_end_dt;


-- Result
-- All data: the start is always like after the end which makes no sense at all

-- Solution
-- 1 Solution: Switch End Date and Start Date
-- 2 Solution: Derive the End Date from the Start Date; End Date = Start Date of the 'Next' Record - 1

-- TEST

SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,prd_start_dt
      ,LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS prd_end_dt
FROM [DataWarehouse].[bronze].[crm_prd_info]
WHERE prd_key IN ('AC-HE-HL-U509-R', 'AC-HE-HL-U509');

-- 2 Solution

SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
       END AS prd_line
      ,prd_start_dt
      ,CAST(prd_end_dt AS DATE) prd_end_dt
      ,CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
FROM [DataWarehouse].[bronze].[crm_prd_info];



-- Load crm_prd_info to silver
PRINT '>> Truncating Table: silver.crm_prd_info';
TRUNCATE TABLE silver.crm_prd_info;
PRINT '>> Inserting Data Into: silver.crm_prd_info';
INSERT INTO silver.crm_prd_info ( 
       prd_id
      ,cat_id
      ,prd_key
      ,prd_nm
      ,prd_cost
      ,prd_line
      ,prd_start_dt
      ,prd_end_dt
      ,dwh_create_date
    )
SELECT prd_id
      ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
      ,SUBSTRING(prd_key, 7) AS prd_key
      ,prd_nm
      ,ISNULL(prd_cost, 0) AS prd_cost
      ,CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
       END AS prd_line
      ,prd_start_dt
      ,CAST(prd_end_dt AS DATE) prd_end_dt
      ,CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
FROM [DataWarehouse].[bronze].[crm_prd_info];
