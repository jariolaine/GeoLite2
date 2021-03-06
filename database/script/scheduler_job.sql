Rem
Rem   Name
Rem     scheduler_job.sql
Rem
Rem   Description
Rem     create scheduled job to run ETL proces
Rem
Rem   Change log
Rem     JLa 27.03.2018 / Created
Rem
Rem   Notes
Rem     Assumes the SYS user is connected
Rem

begin

  dbms_scheduler.create_job (
     job_name => 'GEOLITE2_OWNER.RUN_ETL_FLOW_JOB'
    ,job_type => 'STORED_PROCEDURE'
    ,job_action => 'GEOLITE2_OWNER.ETL_UTIL.RUN_ETL_FLOW'
    ,start_date => to_timestamp_tz('2018-03-28 00:36:00.000000000 EUROPE/HELSINKI','YYYY-MM-DD HH24:MI:SS.FF TZR')
    ,repeat_interval => 'FREQ=DAILY'
    ,end_date => null
    ,enabled => false
    ,auto_drop => false
    ,comments => 'Run ETL process for Maxmid Geolite2 CSV data'
  );

  dbms_scheduler.set_attribute( 
     name => 'GEOLITE2_OWNER.RUN_ETL_FLOW_JOB' 
    ,attribute => 'logging_level'
    ,value => dbms_scheduler.logging_off
  );

  dbms_scheduler.enable(
    name => 'GEOLITE2_OWNER.RUN_ETL_FLOW_JOB'
  );
  
end;
/
