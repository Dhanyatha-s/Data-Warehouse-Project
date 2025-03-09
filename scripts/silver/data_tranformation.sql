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

INSERT INTO silver.crm_prd_info(
prd_id,
cat_id,
prd_key,
prd_nm,
prd_cost,
prd_line,
prd_start_dt,
prd_end_dt

)

select 
prd_id,
REPLACE(SUBSTRING(prd_key, 1, 5), '-','_') as cat_id,
SUBSTRING(prd_key, 7, LEN(prd_key) )AS prd_key,
prd_nm,
ISNULL(prd_cost, 0) as prd_cost,

CASE UPPER(TRIM(prd_line))
	 WHEN 'R' THEN 'Road'
	 WHEN 'S' THEN 'Other Sales'
	 WHEN 'M' THEN 'Mountain'
	 WHEN 'T' THEN 'Touring'
	 ELSE 'n/a'
END AS prd_line,
CAST(prd_start_dt AS DATE) AS prd_start_dt ,
CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) -1 AS DATE) AS prd_end_dt
from bronze.crm_prd_info



