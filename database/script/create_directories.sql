
Rem
Rem   NAME
Rem     create_directories.sql
Rem
Rem   DESCRIPTION
Rem
Rem   NOTES
Rem     Assumes the SYS user is connected.
Rem

begin

  for c1 in(
    select directory_name
    from dba_directories
    where directory_name in(
       'GEOLITE2_SCRIPT_DIR'
      ,'GEOLITE2_LOG_DIR'
      ,'GEOLITE2_DATA_DIR'
    )
  )loop
    execute immediate 'drop directory ' || c1.directory_name;
  end loop;
  
end;
/


create directory geolite2_data_dir as '/opt/geolite2/data/'
/
create directory geolite2_log_dir as '/opt/geolite2/log/'
/
create directory geolite2_script_dir as '/opt/geolite2/script/'
/


grant read on directory geolite2_data_dir to geolite2_owner
/
grant read,write on directory geolite2_log_dir to geolite2_owner
/
grant read,execute on directory geolite2_script_dir to geolite2_owner
/

