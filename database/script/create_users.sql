Rem
Rem   Name
Rem     create_users.sql
Rem
Rem   Description
Rem     create needed database users
Rem
Rem   Change log
Rem     JLa 27.03.2018 / Created
Rem
Rem   Notes
Rem     Assumes the SYS user is connected.
Rem
Rem   Arguments:
Rem     Position 1: Name of tablespace for GEOLITE2_OWNER and GEOLITE2_READER
Rem     Position 2: Name of tablespace for data schema GEOLITE2_A
Rem     Position 2: Name of tablespace for data schema GEOLITE2_B
Rem     Position 4: Name of temporary tablespace
Rem

-- Drop users
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

-- Create users
create user geolite2_reader identified by geolite2 default tablespace &1 temporary tablespace &4
/
create user geolite2_owner identified by geolite2 default tablespace &1 temporary tablespace &4
/
create user geolite2_a identified by geolite2 default tablespace &2 temporary tablespace &4
/
create user geolite2_b identified by geolite2 default tablespace &3 temporary tablespace &4
/

-- Quota to tablespaces
alter user geolite2_owner quota unlimited on &1
/
alter user geolite2_a quota unlimited on &2
/
alter user geolite2_b quota unlimited on &3
/

-- Lock data users
alter user geolite2_b password expire account lock
/
alter user geolite2_a password expire account lock
/

-- Grants to users
grant create session to geolite2_owner, geolite2_reader
/
grant create synonym to geolite2_owner
/
