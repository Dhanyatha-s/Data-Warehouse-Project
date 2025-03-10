/*
===============================================================================
	DATA TRANSFROMATIONS ON BRONZE TABLES AND LODING IT INTO SLVER TABLES
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
            DATA TRANSFROMATIONS ON CRM 
===============================================================================
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
            DATA TRANSFROMATIONS ON PRODUCT iNFO TABLE
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

IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
	DROP TABLE silver.crm_sales_details
CREATE TABLE silver.crm_sales_details (
    sls_ord_num     NVARCHAR(50),
    sls_prd_key     NVARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       INT,
    sls_quantity    INT,
    sls_price       INT,
    dwh_create_date DATETIME2 DEFAULT GETDATE()
);
/*

===============================================================================
            DATA TRANSFROMATIONS ON CRM SLAES DETAILS
===============================================================================
*/

INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)
		SELECT 
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			CASE 
				WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
			END AS sls_order_dt,
			CASE 
				WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
			END AS sls_ship_dt,
			CASE 
				WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
				ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
			END AS sls_due_dt,
			CASE 
				WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price) 
					THEN sls_quantity * ABS(sls_price)
				ELSE sls_sales
			END AS sls_sales, -- Recalculate sales if original value is missing or incorrect
			sls_quantity,
			CASE 
				WHEN sls_price IS NULL OR sls_price <= 0 
					THEN sls_sales / NULLIF(sls_quantity, 0)
				ELSE sls_price  -- Derive price if original value is invalid
			END AS sls_price
		FROM bronze.crm_sales_details;

	
/*
===============================================================================
            DATA TRANSFROMATIONS ON ERP 
===============================================================================
===============================================================================
            DATA TRANSFROMATIONS ON ERP CUSTOMERS
===============================================================================
*/
INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)
		SELECT
			CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid)) -- Remove 'NAS' prefix if present
				ELSE cid
			END AS cid, 
			CASE
				WHEN bdate > GETDATE() THEN NULL
				ELSE bdate
			END AS bdate, -- Set future birthdates to NULL
			CASE
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
				ELSE 'n/a'
			END AS gen -- Normalize gender values and handle unknown cases
		FROM bronze.erp_cust_az12;

/*

===============================================================================
            DATA TRANSFROMATIONS ON ERP CUSTOMERS LOCATONS
===============================================================================
*/
INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)
		SELECT
			REPLACE(cid, '-', '') AS cid, 
			CASE
				WHEN TRIM(cntry) = 'DE' THEN 'Germany'
				WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
				WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
				ELSE TRIM(cntry)
			END AS cntry -- Normalize and Handle missing or blank country codes
		FROM bronze.erp_loc_a101;

/*

===============================================================================
            DATA TRANSFROMATIONS ON ERP PRODCUT CATEGORIES
===============================================================================
*/
INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;

