/*
==================================================================================================================
                              CREATE DATABASE AND SCHEMAS
==================================================================================================================
SCRIPTS
  creating the database 'DataWarehouse' and by using medallion archtecture schema and creating 'bronze', 'silver', 'gold' schemas
*/
use master
 -- DROP AND RECREATE 'DataWarehouse' DATABASE
IF EXISTS ( SELECT 1 FROM sys.database WHERE NAME = 'DataWarehouse')
BEGIN
ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE DataWarehouse;
END
GO

-- CREATE DATABASE 'DataWarehouse'
CREATE DATABASE DataWarehouse
GO

-- USE DATABASE 'DataWarehouse'
USE DataWarehouse
  
-- CREATE SCHEMAS :- BRONZE, SILVER, GOLD AS WE ARE USING MEDALLION ARCHITECTURE OF SCHEMA MODEL
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;


