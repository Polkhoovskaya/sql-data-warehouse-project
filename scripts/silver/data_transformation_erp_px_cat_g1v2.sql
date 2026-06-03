SELECT
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
FROM bronze.erp_px_cat_g1v2;

-- Check that all id values exist in the tables with primary keys
-- Expectation: No Results

SELECT ID
FROM bronze.erp_px_cat_g1v2
WHERE ID NOT IN (SELECT cat_id FROM silver.crm_prd_info);

-- Result:
--  ID
--  CO_PD

---------------------------------------------------------------------------------------------------

-- Check for unwanted Spaces

SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance);

-- No Results

---------------------------------------------------------------------------------------------------

--  Data Standardization & Consistency

SELECT DISTINCT cat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT subcat
FROM bronze.erp_px_cat_g1v2;

SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2;

---------------------------------------------------------------------------------------------------

-- Load erp_px_cat_g1v2 to silver

INSERT INTO silver.erp_px_cat_g1v2 (
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
)
SELECT
    ID,
    CAT,
    SUBCAT,
    MAINTENANCE
FROM bronze.erp_px_cat_g1v2;
