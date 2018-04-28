--------------------------------------------------------
--  File created - Saturday-April-28-2018   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function IP_TO_DEC
--------------------------------------------------------

create or replace function ip_to_dec (
  p_ip in varchar2
) return number deterministic
authid current_user
as 
begin
  return ip_util.ip_to_dec(
    p_ip => p_ip
  );
end ip_to_dec;
/
