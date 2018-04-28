/*
drop table city_locations purge
/
drop table asn_blocks purge
/
drop table city_blocks purge
/
*/

-- Tables
create table city_locations(
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
) nologging pctfree 0 enable row movement
/

create table asn_blocks(
  network_start number(38,0),
  network_end number(38,0),
	network_address varchar2(43 char),
	autonomous_system_number number(10,0),
  autonomous_system_organization varchar2(256 char)
) nologging pctfree 0 enable row movement
/

create table city_blocks(
  network_start number(38,0),
  network_end number(38,0),
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
) nologging pctfree 0 enable row movement
/

-- Object grants
grant select on city_locations to geolite2_owner, geolite2_reader with grant option
/
grant select on asn_blocks to geolite2_owner, geolite2_reader with grant option
/
grant select on city_blocks to geolite2_owner, geolite2_reader with grant option
/
grant insert on city_locations to geolite2_owner
/
grant insert on asn_blocks to geolite2_owner
/
grant insert on city_blocks to geolite2_owner
/

