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
Rem   Arguments:
Rem     Position 1: Email recipients
Rem     Position 2: Email sender
Rem
Rem   Notes
Rem     Assumes the SYS user is connected
Rem

begin
  dbms_scheduler.add_job_email_notification(    
    job_name          => 'GEOLITE2_OWNER.RUN_ETL_FLOW_JOB',
    events            => 'job_broken, job_chain_stalled, job_failed, job_over_max_dur, job_sch_lim_reached',
    filter_condition  => null,
    recipients        => &1,
    sender            => &2,
    subject           => 'Oracle Scheduler Job Notification - %job_owner%.%job_name%.%job_subname% %event_type%',
    body              => '
Job: %job_owner%.%job_name%.%job_subname%
Event: %event_type%
Date: %event_timestamp%
Log id: %log_id%
Job class: %job_class_name%
Run count: %run_count%
Failure count: %failure_count%
Retry count: %retry_count%
Error code: %error_code%
Error message: %error_message%
' 
  );

  commit;
end;
/

