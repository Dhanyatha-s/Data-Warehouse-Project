-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO
-- create view
create view gold.dim_customers as
select 
ROW_NUMBER () over (order by cst_id) as customer_key,
ci.cst_id as customer_id,
ci.cst_key as customer_number,
ci.cst_firstname as first_name,
ci.cst_lastname as last_name,
la.cntry as country,
ci.cst_material_status as marital_status,
case when ci.cst_gndr != 'n/a' then ci.cst_gndr
	else coalesce(ca.cid, 'n/a')
end as gender,
ca.bdate as birthdate,
ci.cst_create_date as create_date

from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on		ci.cst_key = ca.cid
left join silver.erp_loc_a101 la
on		ci.cst_key = la.cid

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO
-- Create  view
CREATE VIEW gold.dim_products AS 
    SELECT 
        ROW_NUMBER() OVER (ORDER BY pd.prd_start_dt, pd.prd_key, pd.prd_id) AS product_key,
        pd.prd_id AS product_id,  -- Keeping product_id in the 2nd column
        cast(pd.prd_key  as nvarchar(50) ) AS product_number,  -- Moving prd_key to 3rd column
        pd.prd_nm AS product_name,
        pd.cat_id AS category_id,
        pc.cat AS category,
        pc.subcat AS subcategory,
        pc.maintenance,
        pd.prd_cost AS cost,
        pd.prd_line AS product_line,
        pd.prd_start_dt AS start_date
    FROM (
        SELECT DISTINCT prd_key, prd_id, prd_nm, cat_id, prd_cost, prd_line, prd_start_dt, prd_end_dt -- removing the duplicates 
        FROM silver.crm_prd_info
        WHERE prd_end_dt IS NULL  
    ) pd
    LEFT JOIN silver.erp_px_cat_g1v2 pc 
        ON pd.cat_id = pc.id;
GO
  
-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO
-- create view
CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO

select * from gold.fact_sales
