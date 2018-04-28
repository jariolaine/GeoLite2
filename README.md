# GeoLite2
Setup Extrac, Transform and Load (ETL) process for [Maxmind](https://twitter.com/maxmind) [GeoLite2](https://dev.maxmind.com/geoip/geoip2/geolite2/) CSV files to Oracle database.

Scripts creates needed database users, objects and set scheduled job to execute ETL process once a day. 

Scripts are tested only using 11G XE database.
## Prerequisites
Oracle database on Linux server
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
Place script [download_data.sh](server/download_data.sh) to directory /opt/geolite2/script.

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
## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details

