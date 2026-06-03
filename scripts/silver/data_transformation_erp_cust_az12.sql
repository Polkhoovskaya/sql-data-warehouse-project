SELECT 
	cid,
	bdate,
	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12];

-- Check that all cid values exist in the tables with primary keys
-- Expectation: No Results

SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
		ELSE cid
	END AS cid,
	bdate,
	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12]
WHERE CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
		ELSE cid
	END NOT IN (SELECT cst_key	FROM silver.crm_cust_info);
---------------------------------------------------------------------------------------------------

-- Check for very old customers
-- Check for birthdays in the future

SELECT 
	cid,
	bdate,
	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12]
WHERE bdate < '1926-01-01' OR bdate > GETDATE();

-- Result:
-- 23 rowse affected

-- Solution
-- Set all future values to NULL

SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS	bdate,
	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12];


---------------------------------------------------------------------------------------------------

-- Date Standardization & Consolidation

SELECT DISTINCT
gen
from [DataWarehouse].[bronze].[erp_cust_az12];

-- Result:
--	gen
--	NULL
--	F
--	 
--	Male
--	Female
--	M 



-- Solution
-- Leave only Male, Female and n/a


SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS	bdate,
	CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		ELSE 'n/a'
	END AS	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12];


---------------------------------------------------------------------------------------------------

-- Load erp_cust_az12 to silver

PRINT '>> Truncating Table: silver.erp_cust_az12';
TRUNCATE TABLE silver.erp_cust_az12;
PRINT '>> Inserting Data Into: silver.erp_cust_az12';
INSERT INTO silver.erp_cust_az12 (
	cid,
	bdate,
	gen
)
SELECT 
	CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4)
		ELSE cid
	END AS cid,
	CASE WHEN bdate > GETDATE() THEN NULL
		ELSE bdate
	END AS	bdate,
	CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
		WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
		ELSE 'n/a'
	END AS	gen
FROM [DataWarehouse].[bronze].[erp_cust_az12];
