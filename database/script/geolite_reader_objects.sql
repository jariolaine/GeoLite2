Rem
Rem   Name
Rem     geolite_reader_objects.sql
Rem
Rem   Description
Rem     create needed objects to user GEOLITE2_READER
Rem
Rem   Change log
Rem     JLa 27.03.2018 / Created
Rem
Rem   Notes
Rem     Assumes the SYS user is connected and current_schema is set to GEOLITE2_READER
Rem

-- Data source synonyms
create or replace synonym city_locations for geolite2_owner.source_city_locations
/
create or replace synonym city_blocks for geolite2_owner.source_city_blocks
/
create or replace synonym asn_blocks for geolite2_owner.source_asn_blocks
/
-- IP_TO_DEC function synonym
create or replace synonym ip_to_dec for geolite2_owner.ip_to_dec
/

