Rem
Rem   NAME
Rem     create_users.sql
Rem
Rem   DESCRIPTION
Rem
Rem   NOTES
Rem     Assumes the SYS user is connected.
Rem
Rem   Arguments:
Rem     Position 1: Name of tablespace for geolite2_owner and geolite2_reader
Rem     Position 2: Name of tablespace for data schema A
Rem     Position 2: Name of tablespace for data schema B
Rem     Position 4: Name of temporary tablespace
Rem

begin
  for c1 in(
    select username
    from dba_users
    where 1 = 1
    and username in(
       'GEOLITE2_A'
      ,'GEOLITE2_B'
      ,'GEOLITE2_OWNER'
      ,'GEOLITE2_READER'
    )
  )loop
    execute immediate 'drop user ' || c1.username || ' cascade';
  end loop;
end;
/

create user geolite2_reader identified by geolite2 default tablespace &1 temporary tablespace &4
/

create user geolite2_owner identified by geolite2 default tablespace geolite2_users temporary tablespace temp
/
alter user geolite2_owner quota unlimited on &1
/

create user geolite2_a identified by geolite2 default tablespace geolite2_a temporary tablespace temp
/
alter user geolite2_a quota unlimited on &2
/
alter user geolite2_a password expire account lock
/

create user geolite2_b identified by geolite2 default tablespace geolite2_b temporary tablespace temp
/
alter user geolite2_b quota unlimited on &3
/
alter user geolite2_b password expire account lock
/

-- Grants to users
grant create session to geolite2_owner, geolite2_reader
/
grant create synonym to geolite2_owner
/
