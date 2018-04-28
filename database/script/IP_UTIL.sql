CREATE OR REPLACE package "IP_UTIL"
authid definer
as
---------------------------------------------------------------------
/*
  References:
    https://github.com/krisrice/maxmind-oracledb
    https://connor-mcdonald.com/2018/01/23/dealing-with-ip-addresses/
    https://stackoverflow.com/questions/6470244/oracle-pl-sql-versions-of-inet6-aton-and-ntoa-functions
*/
---------------------------------------------------------------------
  function ip_to_dec(
    p_ip      in varchar2
  ) return number deterministic;
---------------------------------------------------------------------
  function net_to_dec(
    p_net     in varchar2,
    p_end     in varchar2 default 'N'
  ) return number deterministic;
---------------------------------------------------------------------
end "IP_UTIL";
/


CREATE OR REPLACE package body "IP_UTIL"
as
---------------------------------------------------------------------
---------------------------------------------------------------------
  function ip_guess(
    p_ip      in varchar2
  ) return pls_integer
  as
    l_ip_type pls_integer;
  begin
    -- Short-circuit the most popular, and also catch the special case of IPv4 addresses in IPv6
    if regexp_like( p_ip, '\d{1,3}(\.\d{1,3}){3}' ) then
      l_ip_type := 4;
    elsif regexp_like( p_ip, '[[:xdigit:]]{0,4}(\:[[:xdigit:]]{0,4}){0,7}' ) then
      l_ip_type := 6;
    end if;
    return l_ip_type;
  end ip_guess;
---------------------------------------------------------------------
---------------------------------------------------------------------
  function ip_to_hex(
    p_ip      in varchar2
  ) return varchar2
  as
    l_ip_type   number;
    l_ip        varchar2(32);
    l_temp      varchar2(64);
    l_ipv4_dot  pls_integer;
    l_ipv4_part varchar2(3);
  begin

    l_ip_type := ip_util.ip_guess( p_ip );

    if l_ip_type = 4 then

      -- Sanity check
      l_temp := regexp_substr( p_ip, '\d{1,3}(\.\d{1,3}){3}' );

      if l_temp is not null then 

        -- Starting prefix
        -- NOTE: 2^48 - 2^32 = 281470681743360 = ::ffff:0.0.0.0
        -- (for compatibility with IPv4 addresses in IPv6)
        l_ip := '00000000000000000000ffff';

        -- Parse the input
        while length( l_temp ) is not null
        loop
          -- find the dot
          l_ipv4_dot := instr( l_temp, '.');

          -- isolate the decimal octet
          if l_ipv4_dot > 0 then
            l_ipv4_part    := substr( l_temp, 1, l_ipv4_dot - 1);
            l_temp := substr( l_temp, l_ipv4_dot + 1);
          else
            l_ipv4_part    := l_temp;
            l_temp := null;
          end if;

          -- convert to a hex string
          l_ip := l_ip || to_char( to_number( l_ipv4_part ), 'FM0x' );

        end loop;

      end if;

    elsif l_ip_type = 6 then

      -- Short-circuit "::" = 0
      if p_ip = '::' then
        l_ip := lpad( '0', 32, '0' );
      else

        -- Sanity check
        l_temp := regexp_substr( p_ip, '[[:xdigit:]]{0,4}(\:[[:xdigit:]]{0,4}){0,7}' );
        if l_temp is not null then

          -- Replace leading zeros
          -- (add a bunch to all of the pairs, then remove only the required ones)
          l_temp := regexp_replace( l_temp, '(^|\:)([[:xdigit:]]{1,4})', '\1000\2' );
          l_temp := regexp_replace( l_temp, '(^|\:)0+([[:xdigit:]]{4})', '\1\2' );

          -- Groups of zeroes
          -- (total length should be 32+Z, so the gap would be the zeroes)
          l_temp := replace( l_temp, '::', 'Z' );
          l_temp := replace( l_temp, ':' );
          l_temp := replace( l_temp, 'Z', lpad( '0', 33 - length( l_temp), '0' ) );
          l_ip     := lower(l_temp);
        end if;

      end if;

    end if;

    return l_ip;

  end ip_to_hex;
---------------------------------------------------------------------
---------------------------------------------------------------------
  function net_to_hex(
    p_ip      in varchar2,
    p_cidr    in pls_integer
  ) return varchar2
  as
    l_ip_type   pls_integer;
    l_ip_hex    varchar2(32);
    l_ip_half1  varchar2(16);
    l_ip_half2  varchar2(16);
    l_temp      varchar2(16);
    l_cidr_exp  integer;  
    l_ip_int    integer;
    l_subnet    integer;
    l_is_end    pls_integer;
    l_is_big    pls_integer;
  begin

    l_is_big := 0;
    l_is_end := 1;

    l_ip_type   := ip_util.ip_guess( p_ip );
    l_cidr_exp  := 2 ** (l_ip_type + 1) - p_cidr;

    l_ip_hex    := ip_util.ip_to_hex( p_ip );
    l_ip_half1  := substr( l_ip_hex, 1, 16 );
    l_ip_half2  := substr( l_ip_hex, 17 );
    l_temp      := l_ip_half2;

    -- Sanity checks
    if l_ip_type is null
    or l_ip_hex is null
    or l_cidr_exp <  0 
    or l_cidr_exp >  128
    then 
      return null;
    end if;

    if l_cidr_exp = 0 then
      -- the exact IP, such as /32 on IPv4
      return l_ip_hex;
    elsif l_cidr_exp >= 64  then 
      l_is_big := 1;
    end if;

    -- Change some variables around if we are working with the first/largest half
    if l_is_big = 1 then
      l_temp := l_ip_half1;
      -- either all 0 or all F
      l_ip_half2 := to_char( ( 2 ** 64 - 1 ) * l_is_end, 'FM0xxxxxxxxxxxxxxx' );
      l_cidr_exp := l_cidr_exp - 64;
    end if;

    -- Normalize IP to divisions of CIDR
    l_subnet := 2 ** l_cidr_exp;
    l_ip_int := to_number( l_temp , 'FM0xxxxxxxxxxxxxxx' );

    -- if l_is_end = 1 then add one net range (then subtract one IP) to get the ending range
    l_temp := to_char( floor( l_ip_int / l_subnet + l_is_end) * l_subnet - l_is_end, 'FM0xxxxxxxxxxxxxxx' );

    -- Re-integrate
    if l_is_big = 0 then
      l_ip_half2 := l_temp ;
    else
      l_ip_half1 := l_temp ;
    end if;

    return substr( l_ip_half1 || l_ip_half2, 1, 32 );

  end net_to_hex;
---------------------------------------------------------------------
---------------------------------------------------------------------
  function ip_to_dec(
    p_ip      in varchar2
  ) return number deterministic
  as
  begin
    return to_number( ip_util.ip_to_hex( p_ip ) , lpad( 'x', 32, 'x' ) );
  end ip_to_dec;
---------------------------------------------------------------------
---------------------------------------------------------------------
  function net_to_dec(
    p_net     in varchar2,
    p_end     in varchar2 default 'N'
  ) return number deterministic
  as
    l_cidr  pls_integer;
    l_pos   pls_integer;
    l_ip    varchar2(39);
    l_hex   varchar2(32);
  begin
    l_pos   := instr( p_net, '/' );
    l_ip    := substr( p_net, 1,  l_pos - 1 );
    l_cidr  := substr( p_net, l_pos + 1 );
    if p_end = 'Y' then
      l_hex := ip_util.net_to_hex( l_ip, l_cidr );
    else 
      l_hex := ip_util.ip_to_hex( l_ip );
    end if;
    return to_number( l_hex, lpad( 'x', 32, 'x' ) );
  end net_to_dec;
---------------------------------------------------------------------
---------------------------------------------------------------------
end "IP_UTIL";
/
