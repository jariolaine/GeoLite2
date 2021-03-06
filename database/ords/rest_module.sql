-- Generated by Oracle SQL Developer REST Data Services 18.1.0.095.1630
-- Exported REST Definitions from ORDS Schema Version 18.1.1.95.1251
-- Schema: GEOLITE2_READER   Date: Sat Apr 28 12:19:00 EEST 2018
--
BEGIN
  ORDS.ENABLE_SCHEMA(
      p_enabled             => TRUE,
      p_schema              => 'GEOLITE2_READER',
      p_url_mapping_type    => 'BASE_PATH',
      p_url_mapping_pattern => 'geolite2',
      p_auto_rest_auth      => TRUE);    

  ORDS.DEFINE_MODULE(
      p_module_name    => 'Maxmind_Geolite2',
      p_base_path      => '/api/',
      p_items_per_page =>  25,
      p_status         => 'PUBLISHED',
      p_comments       => NULL);      
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'Maxmind_Geolite2',
      p_pattern        => 'json/:ip_address',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'Maxmind_Geolite2',
      p_pattern        => 'json/:ip_address',
      p_method         => 'GET',
      p_source_type    => 'json/query;type=single',
      p_items_per_page =>  0,
      p_mimes_allowed  => '',
      p_comments       => NULL,
      p_source         => 
'with src as (
  select :ip_address as ip
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
  and t1.network_end'
      );
  ORDS.DEFINE_TEMPLATE(
      p_module_name    => 'Maxmind_Geolite2',
      p_pattern        => 'myip',
      p_priority       => 0,
      p_etag_type      => 'HASH',
      p_etag_query     => NULL,
      p_comments       => NULL);
  ORDS.DEFINE_HANDLER(
      p_module_name    => 'Maxmind_Geolite2',
      p_pattern        => 'myip',
      p_method         => 'GET',
      p_source_type    => 'plsql/block',
      p_items_per_page =>  25,
      p_mimes_allowed  => '',
      p_comments       => NULL,
      p_source         => 
'begin
  htp.p( owa_util.get_cgi_env( ''REMOTE_ADDR'' ) );
end;'
      );


  COMMIT; 
END;