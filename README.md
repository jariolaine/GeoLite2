# Maxmind GeoLite2 CSV to Oracle database
Scripts to setup Extrac, Transform and Load (ETL) process for [Maxmind](https://twitter.com/maxmind) [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) CSV files to Oracle database. 

## Description
Scripts creates totally four users to database.
+ _GEOLITE2_A_ and _GEOLITE2_B_ are owners of tables where CSV data is loaded
+ _GEOLITE2_OWNER_ owns object relating ETL logic
+ _GEOLITE2_READER_ is for accesing data

User _GEOLITE2_READER_ access active data schema 
### ETL Process
Data is loaded to user _GEOLITE2_A_ or _GEOLITE2_B_ tables depending which one isn't active.
Before data load target table is truncated, constraint and indexes are droped.
After succesful data load, synonyms are pointed to schema tables where data was loaded.

## Prerequisites
Oracle database on Linux server. 
*NOTE!* Scripts are tested only using 11G XE database.
## Installing
### Prepare server
Create directories to database server
```
mkdir -p /opt/geolite2/data
mkdir /opt/geolite2/log
mkdir /opt/geolite2/script
```
Give privileges to dba group to server directories
```
chgrp dba /opt/geolite2/data
chgrp dba /opt/geolite2/log
chmod g+w /opt/geolite2/data
chmod g+w /opt/geolite2/log
```
Create dummy files to server
```
touch /opt/geolite2/data/GeoLite2-ASN-CSV.zip
touch /opt/geolite2/data/GeoLite2-City-CSV.zip
```
Change oracle as owner of dummy files
```
chown oracle /opt/geolite2/data/GeoLite2-ASN-CSV.zip
chown oracle /opt/geolite2/data/GeoLite2-City-CSV.zip
```
Place script [download_data.sh](server/download_data.sh) to directory /opt/geolite2/script

Give execute privilege to dba group
```
chgrp dba /opt/geolite2/script/download_data.sh
chmod g+x /opt/geolite2/script/download_data.sh
```
### Database
*NOTE!*
Install script drops and recreates users _GEOLITE2_A_, _GEOLITE2_B_, _GEOLITE2_OWNER_ and _GEOLITE2_READER_ if exists. 
Database directories _GEOLITE2_SCRIPT_DIR_, _GEOLITE2_LOG_DIR_ and _GEOLITE2_DATA_DIR_ are dropped and recreated.

Script install.sql needs four arguments
1. Name of tablespace for GEOLITE2_OWNER and GEOLITE2_READER
2. Name of tablespace for data schema A
3. Name of tablespace for data schema B
4. Name of users temporary tablespace

Run install.sql script as SYS e.g.
```
@install.sql USERS USERS USERS TEMP
```
Change users _GEOLITE2_OWNER_ and _GEOLITE2_READER_ password
```
alter user geolite2_user identified by <password>
/
alter user geolite2_owner identified by <password>
/
```
Connect using user _GEOLITE2_OWNER_ and run ETL process to populated data
```
begin
  dbms_scheduler.run_job('RUN_ETL_FLOW_JOB');
end;
/
```
## Usage
Example query when connected using user _GEOLITE2_READER_
```
with src as (
  select '8.8.8.8' as ip
  from dual
)
, fn as (
  select ip_to_dec(ip) as ip_dec 
  from src
)
select src.ip
  ,t1.network_address as network
  ,(
    select autonomous_system_organization
    from asn_blocks x
    where 1 = 1
      and fn.ip_dec
    between x.network_start
      and x.network_end
  ) as autonomous_system_organization
  ,t2.continent_code
  ,t2.continent_name
  ,t2.country_iso_code as country_code
  ,t2.country_name
  ,t2.subdivision_1_iso_code as region_code
  ,t2.subdivision_1_name as region_name
  ,t2.city_name
  ,t1.postal_code as zip_code
  ,t1.latitude
  ,t1.longitude
  ,t2.metro_code
from city_blocks t1
join city_locations t2 on t1.geoname_id = t2.geoname_id
cross join src
cross join fn
where 1 = 1
  and fn.ip_dec
between t1.network_start
  and t1.network_end
;
```
## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

