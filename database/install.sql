Rem
Rem   NAME
Rem     install.sql
Rem
Rem   DESCRIPTION
Rem
Rem   NOTES
Rem     Assumes the SYS user is connected.
Rem
Rem   Arguments:
Rem     Position 1: Name of tablespace for geolite2_owner and geolite2_reader
Rem     Position 2: Name of tablespace for data schema A
Rem     Position 2: Name of tablespace for data schema B
Rem     Position 4: Name of temporary tablespace
Rem

-- Create users
@script/create_users.sql &1 &2 &3 &4
/

-- Create directories
@script/create_directories.sql
/

-- Create user GEOLITE2_A objects
alter session set current_schema=geolite2_a
/
@script/geolite_data_objects.sql
/

-- Creat user GEOLITE2_B objects
alter session set current_schema=geolite2_b
/
@script/geolite_data_objects.sql
/

-- Create user GEOLITE2_OWNER objects
alter session set current_schema=geolite2_owner
/
@script/IP_UTIL.sql
/
@script/IP_TO_DEC.sql
/
@script/geolite_owner_objects.sql
/
@script/ETL_LOAD_UTIL.sql
/
@script/ETL_UTIL.sql
/
@script/ETL_TBL_UTIL.sql
/

-- Create scheduled job
@script/scheduler_job.sql
/

-- Grants
grant execute on ip_to_dec to geolite2_reader with grant option
/
grant execute on etl_tbl_util to geolite2_a, geolite2_b
/

-- Create GEOLITE_A.ETL_TBL_PROXY package
alter session set current_schema=geolite2_a
/
@script/ETL_TBL_PROXY.sql
/
grant execute on etl_tbl_proxy to geolite2_owner
/

-- Create GEOLITE_B.ETL_TBL_PROXY package
alter session set current_schema=geolite2_b
/
@script/ETL_TBL_PROXY.sql
/
grant execute on etl_tbl_proxy to geolite2_owner
/

-- Create user GEOLITE2_READER objects
alter session set current_schema=geolite2_reader
/
@script/geolite_reader_objects.sql


exit

