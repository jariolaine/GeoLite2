CREATE OR REPLACE package "ETL_LOAD_UTIL"
authid definer
as 
--------------------------------------------------------------------------------
  function insert_ext_asn_blocks return number;
--------------------------------------------------------------------------------
  function insert_ext_city_blocks return number;
--------------------------------------------------------------------------------
  function insert_ext_city_locations return number;
--------------------------------------------------------------------------------
  function insert_src_asn_blocks return number;
--------------------------------------------------------------------------------
  function insert_src_city_blocks return number;
--------------------------------------------------------------------------------
  function insert_src_city_locations return number;
--------------------------------------------------------------------------------
end "ETL_LOAD_UTIL";
/


CREATE OR REPLACE package body "ETL_LOAD_UTIL"
as
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_ext_asn_blocks return number
  as 
  begin
    insert /*+ append */
    into target_asn_blocks(
       network_start
      ,network_end
      ,network_address
      ,autonomous_system_number
      ,autonomous_system_organization
    )
    select
       network_start
      ,network_end
      ,network_address
      ,autonomous_system_number
      ,autonomous_system_organization
    from etl_asn_blocks
    ;
    return sql%rowcount;
  end insert_ext_asn_blocks;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_ext_city_blocks return number
  as
  begin
    insert /*+ append */
    into target_city_blocks(
       network_start
      ,network_end
      ,network_address
      ,geoname_id
      ,registered_country_geoname_id
      ,represented_country_geoname_id
      ,is_anonymous_proxy
      ,is_satellite_provider
      ,postal_code
      ,latitude
      ,longitude
      ,accuracy_radius
    )
    select
       network_start
      ,network_end
      ,network_address
      ,geoname_id
      ,registered_country_geoname_id
      ,represented_country_geoname_id
      ,is_anonymous_proxy
      ,is_satellite_provider
      ,postal_code
      ,latitude
      ,longitude
      ,accuracy_radius
    from etl_city_blocks
    ;
    return sql%rowcount;
  end insert_ext_city_blocks;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_ext_city_locations return number
  as
  begin
    insert /*+ append */
    into target_city_locations(
       geoname_id
      ,locale_code
      ,continent_code
      ,continent_name
      ,country_iso_code
      ,country_name
      ,subdivision_1_iso_code
      ,subdivision_1_name
      ,subdivision_2_iso_code
      ,subdivision_2_name
      ,city_name
      ,metro_code
      ,time_zone_name
      ,is_in_european_union
    )
    select
       geoname_id
      ,locale_code
      ,continent_code
      ,continent_name
      ,country_iso_code
      ,country_name
      ,subdivision_1_iso_code
      ,subdivision_1_name
      ,subdivision_2_iso_code
      ,subdivision_2_name
      ,city_name
      ,metro_code
      ,time_zone_name
      ,is_in_european_union
    from etl_city_locations
    ;
    return sql%rowcount;
  end insert_ext_city_locations;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_src_asn_blocks return number
  as
  begin
    insert /*+ append */
    into target_asn_blocks(
       network_start
      ,network_end
      ,network_address
      ,autonomous_system_number
      ,autonomous_system_organization
    )
    select
       network_start
      ,network_end
      ,network_address
      ,autonomous_system_number
      ,autonomous_system_organization
    from source_asn_blocks
    ;
    return sql%rowcount;
  end insert_src_asn_blocks;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_src_city_blocks return number
  as
  begin
    insert /*+ append */
    into target_city_blocks(
       network_start
      ,network_end
      ,network_address
      ,geoname_id
      ,registered_country_geoname_id
      ,represented_country_geoname_id
      ,is_anonymous_proxy
      ,is_satellite_provider
      ,postal_code
      ,latitude
      ,longitude
      ,accuracy_radius
    )
    select
       network_start
      ,network_end
      ,network_address
      ,geoname_id
      ,registered_country_geoname_id
      ,represented_country_geoname_id
      ,is_anonymous_proxy
      ,is_satellite_provider
      ,postal_code
      ,latitude
      ,longitude
      ,accuracy_radius
    from source_city_blocks
    ;
    return sql%rowcount;
  end insert_src_city_blocks;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function insert_src_city_locations return number
  as
  begin
    insert /*+ append */
    into target_city_locations(
       geoname_id
      ,locale_code
      ,continent_code
      ,continent_name
      ,country_iso_code
      ,country_name
      ,subdivision_1_iso_code
      ,subdivision_1_name
      ,subdivision_2_iso_code
      ,subdivision_2_name
      ,city_name
      ,metro_code
      ,time_zone_name
      ,is_in_european_union
    )
    select
       geoname_id
      ,locale_code
      ,continent_code
      ,continent_name
      ,country_iso_code
      ,country_name
      ,subdivision_1_iso_code
      ,subdivision_1_name
      ,subdivision_2_iso_code
      ,subdivision_2_name
      ,city_name
      ,metro_code
      ,time_zone_name
      ,is_in_european_union
    from source_city_locations
    ;
    return sql%rowcount;
  end insert_src_city_locations;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end "ETL_LOAD_UTIL";
/
