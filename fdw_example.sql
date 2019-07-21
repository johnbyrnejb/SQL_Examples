/* 
Example of a Foreign Data Wrapper in Postgres
*/

----------------------------------------------
-- 1. Create a new schema to hold the foreign tables
----------------------------------------------

CREATE SCHEMA <schema_name> AUTHORIZATION <user>;

COMMENT ON SCHEMA <schema_name> is 'Selected Foreign tables from...';

-- The following steps should be run from the "client" database

----------------------------------------------
-- 2. Make sure FDW extension is installed
----------------------------------------------

CREATE EXTENSION IF NOT EXISTS postgres_fdw SCHEMA public;

----------------------------------------------
-- 3. Create foreign server link to Dev.  
----------------------------------------------

-- Create temporary function for creating the server so that it can discover
-- the appropriate port for itself
CREATE OR REPLACE FUNCTION <schema_name>.create_foreign_server()
  RETURNS VOID AS
$$
DECLARE
	v_port character varying = '5432';
BEGIN

	SELECT inet_server_port() into v_port;
	
	EXECUTE format('CREATE SERVER <server_name>
		FOREIGN DATA WRAPPER postgres_fdw
		OPTIONS (host ''localhost'', dbname ''<dbName>'', port ''%s'', use_remote_estimate ''true'')', v_port);

END;
$$
language plpgsql;

-- Run function to create foreign server
SELECT <schema_name>.create_foreign_server();

-- Drop function again now
DROP FUNCTION IF EXISTS <schema_name>.create_foreign_server();

-- permissions
ALTER SERVER <server_name> OWNER TO <user>;

-- Allow a user to access the foreign server if required
GRANT USAGE ON FOREIGN SERVER <server_name> to <user>;

----------------------------------------------
-- 4. Create foreign user mapping.  
--     Here mapping the <user> on local to user on remote
----------------------------------------------
  
-- User mapping <user> local -> analytics_writer
CREATE USER MAPPING FOR <user> SERVER <server_name> OPTIONS ( USER '<user>', PASSWORD '<password>');
CREATE USER MAPPING FOR analytics_writer SERVER <server_name> OPTIONS ( USER '<user>', PASSWORD '<password>'); 

----------------------------------------------
-- 5. Create foreign table  
--     Here creating foreign tables which links to source schema on remote, build only the tables required
----------------------------------------------
     
  IMPORT FOREIGN SCHEMA <schema> LIMIT TO 
  								(<table_1>, <table_2>, <table_3> )
    FROM SERVER <server_name> INTO <schema_name>;

----------------------------------------------
