/*
drop sequence sgid_seq
/
drop view etl_city_locations
/
drop view etl_asn_blocks
/
drop view etl_city_blocks
/
drop table ext_city_locations
/
drop table ext_asn_blocks
/
drop table ext_city_blocks
/
drop table ext_download
/
drop table etl_flow
/
*/

-- Create external source tables
create table ext_city_locations(
  geoname_id number(10,0),
  locale_code varchar2(5 char),
  continent_code varchar2(2 char),
  continent_name varchar2(256 char),
  country_iso_code varchar2(2 char),
  country_name varchar2(256 char),
  subdivision_1_iso_code varchar2(3 char),
  subdivision_1_name varchar2(256 char),
  subdivision_2_iso_code varchar2(3 char),
  subdivision_2_name varchar2(256 char),
  city_name varchar2(256 char),
  metro_code varchar2(3 char),
  time_zone_name varchar2(256 char),
  is_in_european_union number(1,0)
)
organization external (
  type oracle_loader
  default directory geolite2_data_dir
  access parameters (
    records delimited by newline
    characterset al32utf8
    skip 1
    load when geoname_id != 'geoname_id'
    nologfile
    nobadfile
    nodiscardfile
    fields terminated by ',' optionally enclosed by '"'
    missing field values are null
  )
  location (
    'GeoLite2-City-Locations-en.csv'
    -- Optionally other languages
    --,'GeoLite2-City-Locations-de.csv'
    --,'GeoLite2-City-Locations-es.csv'
    --,'GeoLite2-City-Locations-fr.csv'
    --,'GeoLite2-City-Locations-ja.csv'
    --,'GeoLite2-City-Locations-pt-BR.csv'
    --,'GeoLite2-City-Locations-ru.csv'
    --,'GeoLite2-City-Locations-zh-CN.csv'
  )
)
/

create table ext_asn_blocks(
	network_address varchar2(43 char),
	autonomous_system_number number(10,0),
  autonomous_system_organization varchar2(256 char)
)
organization external (
  type oracle_loader
  default directory geolite2_data_dir
  access parameters (
    records delimited by newline
    characterset al32utf8
	  skip 1
    load when network_address != 'network'
    nologfile
    nobadfile
    nodiscardfile
    fields terminated by ',' optionally enclosed by '"'
    missing field values are null
  )
  location (
     'GeoLite2-ASN-Blocks-IPv4.csv'
    ,'GeoLite2-ASN-Blocks-IPv6.csv'
  )
)
/

create table ext_city_blocks(
	network_address varchar2(43 char),
	geoname_id number(10,0),
	registered_country_geoname_id number(10,0),
	represented_country_geoname_id number(10,0),
	is_anonymous_proxy number(1,0),
  is_satellite_provider number(1,0),
  postal_code varchar2(20 char),
  latitude number(9,6),
  longitude number(9,6),
  accuracy_radius number(10,0)
)
organization external (
  type oracle_loader
  default directory geolite2_data_dir
  access parameters (
    records delimited by newline
    characterset al32utf8
    skip 1
    load when network_address != 'network'
    nologfile
    nobadfile
    nodiscardfile
    fields terminated by ',' optionally enclosed by '"'
    missing field values are null
  )
  location (
     'GeoLite2-City-Blocks-IPv4.csv'
    ,'GeoLite2-City-Blocks-IPv6.csv'
  )
)
/

create table ext_file_date(
  file_name varchar2(256 char),
  file_date timestamp (6) with local time zone
)
organization external (
  type oracle_loader
  default directory geolite2_data_dir
  access parameters (
    records delimited by newline
    preprocessor geolite2_script_dir:'download_data.sh'
    nologfile
    nobadfile
    nodiscardfile
    fields terminated by ',' optionally enclosed by '"'
    missing field values are null
    (
      file_name, 
      file_date char date_format timestamp with time zone mask 'yyyy-mm-dd hh24:mi:ss.ff9 tzhtzm'
    ) 
  )
  location (
     'GeoLite2-City-CSV.zip'
    ,'GeoLite2-ASN-CSV.zip'
  )
)
/

create table etl_control(
  sgid            number(38,0) not null,
  row_version     number(38,0) not null,
  created_on      timestamp (6) with local time zone not null,
  created_by      varchar2(80 char) not null,
  changed_on      timestamp (6) with local time zone not null,
  changed_by      varchar2(80 char) not null,
  src_schema      varchar2(40 char) not null,
  trg_schema      varchar2(40 char) not null, 
  table_name      varchar2(40 char) not null,
  last_source     varchar2(40 char) not null,
  last_row_cnt    number(38,0) not null,
  last_load_date  timestamp (6) with local time zone not null,
  last_file_date  timestamp (6) with local time zone not null,
  constraint etl_control_pk primary key ( sgid )
)
/

create table etl_metadata(
  sgid          number(38,0) not null,
  row_version   number(38,0) not null,
  created_on    timestamp (6) with local time zone not null,
  created_by    varchar2(80 char) not null,
  changed_on    timestamp (6) with local time zone not null,
  changed_by    varchar2(80 char) not null,
  sort_seq      number(10,0) not null,
  object_name   varchar2(80 char) not null,
  object_type   varchar2(40 char) not null,
  table_name    varchar2(40 char) not null,
  column_name   varchar2(40 char),
  constraint etl_metadata_pk primary key ( sgid )
)
/

-- Create ETL views
create or replace force view etl_city_locations
as
select
  0 as geoname_id,
  'en' as locale_code,
  'XX' as continent_code,
  '(Unknown)' as continent_name,
  'XX' as country_iso_code,
  '(Unknown)' as country_name,
  'XX' as subdivision_1_iso_code,
  '(Unknown)' as subdivision_1_name,
  'XX' as subdivision_2_iso_code,
  '(Unknown)' as subdivision_2_name,
  '(Unknown)' as city_name,
  null as metro_code,
  null as time_zone_name,
  0 as is_in_european_union
from dual
union all
-- Dimension data
select
  geoname_id,
  locale_code,
  coalesce( continent_code, 'XX' ) as continent_code,
  coalesce( continent_name, '(Unknown)' ) as continent_name,
  coalesce( country_iso_code, 'XX' ) as country_iso_code,
  coalesce( country_name, '(Unknown)' ) as country_name,
  coalesce( subdivision_1_iso_code, 'XX' ) as subdivision_1_iso_code,
  coalesce( subdivision_1_name, '(Unknown)' ) as subdivision_1_name,
  coalesce( subdivision_2_iso_code, 'XX' ) as subdivision_2_iso_code,
  coalesce( subdivision_2_name, '(Unknown)' ) as subdivision_2_name,
  coalesce( city_name, '(Unknown)' ) as city_name,
  metro_code,
  time_zone_name,
  is_in_european_union
from ext_city_locations
/

create or replace force view etl_asn_blocks
as
select
  ip_util.net_to_dec( network_address ) as network_start
 ,ip_util.net_to_dec( network_address, 'Y' ) as network_end
 ,network_address
 ,autonomous_system_number
 ,autonomous_system_organization
from ext_asn_blocks
/

create or replace force view etl_city_blocks
as
select
   ip_util.net_to_dec( network_address ) as network_start
  ,ip_util.net_to_dec( network_address, 'Y' ) as network_end
  ,network_address
  ,coalesce( geoname_id, 0 ) as geoname_id
  ,coalesce( registered_country_geoname_id, 0 ) as registered_country_geoname_id
  ,coalesce( represented_country_geoname_id, 0 ) as represented_country_geoname_id
  ,is_anonymous_proxy
  ,is_satellite_provider
  ,postal_code
  ,latitude
  ,longitude
  ,accuracy_radius
from ext_city_blocks
/

-- Sequence
create sequence sgid_seq
/

-- Triggers
create or replace trigger etl_control_biu
before
insert or
update on etl_control
for each row
begin

  if inserting then
    :new.sgid         := coalesce( :new.sgid, sgid_seq.nextval );
    :new.row_version  := coalesce( :new.row_version, 1 );
    :new.created_on   := coalesce( :new.created_on, localtimestamp );
    :new.created_by   := coalesce( :new.created_by, sys_context( 'APEX$SESSION', 'APP_USER' ), user );
    :new.changed_by   := coalesce( :new.changed_by, sys_context( 'APEX$SESSION', 'APP_USER' ), user );
    :new.changed_on   := coalesce( :new.changed_on, localtimestamp );
  elsif updating then
    :new.row_version  := :old.row_version + 1; 
    :new.changed_on   := localtimestamp;
    :new.changed_by   := coalesce( sys_context( 'APEX$SESSION', 'APP_USER' ), user );
  end if;

end;
/

create or replace trigger etl_metadata_biu
before
insert or
update on etl_metadata
for each row
begin

  if inserting then
    :new.sgid         := coalesce( :new.sgid, sgid_seq.nextval );
    :new.row_version  := coalesce( :new.row_version, 1 );
    :new.created_on   := coalesce( :new.created_on, localtimestamp );
    :new.created_by   := coalesce( :new.created_by, sys_context( 'APEX$SESSION', 'APP_USER' ), user );
    :new.changed_by   := coalesce( :new.changed_by, sys_context( 'APEX$SESSION', 'APP_USER' ), user );
    :new.changed_on   := coalesce( :new.changed_on, localtimestamp );
  elsif updating then
    :new.row_version  := :old.row_version + 1; 
    :new.changed_on   := localtimestamp;
    :new.changed_by   := coalesce( sys_context( 'APEX$SESSION', 'APP_USER' ), user );
  end if;

end;
/

-- Data
SET DEFINE OFF;
insert into etl_control (src_schema, trg_schema, table_name, last_source,last_row_cnt, last_load_date, last_file_date) values ('GEOLITE2_B', 'GEOLITE2_A' , 'ASN_BLOCKS', 'NOT_RUN', 0, localtimestamp - 3650, localtimestamp - 3650)
/
insert into etl_control (src_schema, trg_schema, table_name, last_source,last_row_cnt, last_load_date, last_file_date) values ('GEOLITE2_B', 'GEOLITE2_A' ,'CITY_BLOCKS',  'NOT_RUN', 0, localtimestamp - 3650, localtimestamp - 3650)
/
insert into etl_control (src_schema, trg_schema, table_name, last_source,last_row_cnt, last_load_date, last_file_date) values ('GEOLITE2_B', 'GEOLITE2_A' ,'CITY_LOCATIONS', 'NOT_RUN', 0, localtimestamp - 3650, localtimestamp - 3650)
/

insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('GeoLite2-ASN-CSV.zip','ETL_FLOW','ASN_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('GeoLite2-City-CSV.zip','ETL_FLOW','CITY_LOCATIONS',null,'2')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('GeoLite2-City-CSV.zip','ETL_FLOW','CITY_BLOCKS',null,'3')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('TARGET_CITY_LOCATIONS','TARGET_SYNONYM','CITY_LOCATIONS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('TARGET_ASN_BLOCKS','TARGET_SYNONYM','ASN_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('TARGET_CITY_BLOCKS','TARGET_SYNONYM','CITY_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SOURCE_CITY_LOCATIONS','SOURCE_SYNONYM','CITY_LOCATIONS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SOURCE_CITY_BLOCKS','SOURCE_SYNONYM','CITY_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SOURCE_ASN_BLOCKS','SOURCE_SYNONYM','ASN_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_EXT_ASN_BLOCKS','LOAD_FROM_FILE','ASN_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_EXT_CITY_BLOCKS','LOAD_FROM_FILE','CITY_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_EXT_CITY_LOCATIONS','LOAD_FROM_FILE','CITY_LOCATIONS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_SRC_ASN_BLOCKS','LOAD_FROM_SRC_TABLE','ASN_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_SRC_CITY_BLOCKS','LOAD_FROM_SRC_TABLE','CITY_BLOCKS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ETL_LOAD_UTIL.INSERT_SRC_CITY_LOCATIONS','LOAD_FROM_SRC_TABLE','CITY_LOCATIONS',null,'1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','ASN_BLOCKS','NETWORK_START','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','ASN_BLOCKS','NETWORK_END','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','ASN_BLOCKS','NETWORK_ADDRESS','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','ASN_BLOCKS','AUTONOMOUS_SYSTEM_NUMBER','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','NETWORK_START','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','NETWORK_END','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','NETWORK_ADDRESS','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','GEONAME_ID','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','REGISTERED_COUNTRY_GEONAME_ID','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','REPRESENTED_COUNTRY_GEONAME_ID','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','IS_ANONYMOUS_PROXY','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_BLOCKS','IS_SATELLITE_PROVIDER','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','GEONAME_ID','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','LOCALE_CODE','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','CONTINENT_CODE','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','CONTINENT_NAME','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','COUNTRY_ISO_CODE','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','COUNTRY_NAME','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','SUBDIVISION_1_ISO_CODE','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','SUBDIVISION_1_NAME','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','SUBDIVISION_2_ISO_CODE','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','SUBDIVISION_2_NAME','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','CITY_NAME','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('SYS_C','NOT_NULL','CITY_LOCATIONS','IS_IN_EUROPEAN_UNION','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ASN_BLOCKS_PK','PRIMARY_KEY','ASN_BLOCKS','NETWORK_START','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('ASN_BLOCKS_PK','PRIMARY_KEY','ASN_BLOCKS','NETWORK_END','2')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('CITY_LOCATIONS_PK','PRIMARY_KEY','CITY_LOCATIONS','GEONAME_ID','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('CITY_BLOCKS_PK','PRIMARY_KEY','CITY_BLOCKS','NETWORK_START','1')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('CITY_BLOCKS_PK','PRIMARY_KEY','CITY_BLOCKS','NETWORK_END','2')
/
insert into etl_metadata (object_name,object_type,table_name,column_name,sort_seq) values ('CITY_BLOCKS_IX1','INDEX','CITY_BLOCKS','GEONAME_ID','1')
/

commit
/


-- ETL Target synonyms
create or replace synonym target_city_locations for geolite2_a.city_locations
/
create or replace synonym target_city_blocks for geolite2_a.city_blocks
/
create or replace synonym target_asn_blocks for geolite2_a.asn_blocks
/

-- Data source synonyms
create or replace synonym source_city_locations for geolite2_b.city_locations
/
create or replace synonym source_city_blocks for geolite2_b.city_blocks
/
create or replace synonym source_asn_blocks for geolite2_b.asn_blocks
/


