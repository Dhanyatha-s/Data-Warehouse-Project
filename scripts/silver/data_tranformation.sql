/*
===============================================================================
            DATA TRANSFROMATIONS
===============================================================================
SCRIPTS:
         The data is Transfromed with the removal of duplicates, 
         removal of unnecessary spaces to ensure data consistency
         data normalization and standardizations
         handeling missing data 
================================================================================
*/
/*
===============================================================================
            DATA TRANSFROMATIONS ON CUSTOMER INFO TABLE
===============================================================================
*/
TRUNCATE TABLE silver.crm_cust_info
INSERT INTO silver.crm_cust_info(
cst_id,
cst_key,
cst_firstname,
cst_lastname,
cst_material_status,
cst_gndr,
cst_create_date
)

SELECT 
cst_id,
cst_key,
TRIM(cst_firstname) AS cst_firstname ,
TRIM(cst_lastname) AS cst_lastname,
CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
	 WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
	 ELSE 'n/a'
END cst_material_status,

CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
	 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
	 ELSE 'n/a'
END cst_gndr,
cst_create_date
FROM
(
SELECT 
* ,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
FROM bronze.crm_cust_info
where cst_id is not null
)t WHERE flag_last = 1

/*
===============================================================================
            DATA TRANSFROMATIONS ON pRODUCT iNFO TABLE
===============================================================================
*/
