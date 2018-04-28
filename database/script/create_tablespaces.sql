/*
drop tablespace geolite2_users including contents and datafiles
/
drop tablespace geolite2_a including contents and datafiles
/
drop tablespace geolite2_b including contents and datafiles
/
*/

create tablespace geolite2_users datafile '/u01/app/oracle/oradata/XE/geolite2_users.dbf'
size 1M
autoextend on
next 1M maxsize 50m
extent management local
autoallocate segment
space management auto
/

create tablespace geolite2_a datafile '/u01/app/oracle/oradata/XE/geolite2_a.dbf'
size 500M
autoextend on
next 1M maxsize 1G
nologging
extent management local
autoallocate segment
space management auto
/

create tablespace geolite2_b datafile '/u01/app/oracle/oradata/XE/geolite2_b.dbf'
size 500M
autoextend on
next 1M maxsize 1G
nologging
extent management local
autoallocate segment
space management auto
/


