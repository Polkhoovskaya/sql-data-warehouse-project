SELECT CID, CNTRY
FROM bronze.erp_loc_a101;

-- Check that all cid values exist in the tables with primary keys
-- Expectation: No Results

SELECT REPLACE(CID, '-', '') CID
FROM bronze.erp_loc_a101
WHERE REPLACE(CID, '-', '') NOT IN ( SELECT cst_key
FROM silver.crm_cust_info);

-- No Results

---------------------------------------------------------------------------------------------------

-- Data Standardization & Consistency

SELECT DISTINCT CNTRY
FROM bronze.erp_loc_a101
ORDER BY CNTRY;

-- Result:
--	CNTRY
--	NULL
--	  
--	Australia
--	Canada
--	DE
--	France
--	Germany
--	United Kingdom
--	United States
--	US
--	USA

SELECT REPLACE(CID, '-', '') CID,
CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
	 WHEN CNTRY IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
	 ELSE TRIM(CNTRY)
END AS CNTRY
FROM bronze.erp_loc_a101;

---------------------------------------------------------------------------------------------------

-- Load erp_loc_a101 to silver

PRINT '>> Truncating Table: silver.erp_loc_a101';
TRUNCATE TABLE silver.erp_loc_a101;
PRINT '>> Inserting Data Into: silver.erp_loc_a101';
INSERT INTO silver.erp_loc_a101 (
	CID, 
	CNTRY
)
SELECT REPLACE(CID, '-', '') CID,
CASE WHEN TRIM(CNTRY) = 'DE' THEN 'Germany'
	 WHEN TRIM(CNTRY) IN ('US', 'USA') THEN 'United States'
	 WHEN CNTRY IS NULL OR TRIM(CNTRY) = '' THEN 'n/a'
	 ELSE TRIM(CNTRY)
END AS CNTRY
FROM bronze.erp_loc_a101;
