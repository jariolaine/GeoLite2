CREATE OR REPLACE package "ETL_TBL_UTIL"
authid current_user
as
--------------------------------------------------------------------------------
  procedure initialize_table(
    p_table_name in varchar2
  );
--------------------------------------------------------------------------------
  procedure finalize_table(
    p_table_name in varchar2
  );
--------------------------------------------------------------------------------
end "ETL_TBL_UTIL";

/


CREATE OR REPLACE package body "ETL_TBL_UTIL"
as
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure truncate_table(
    p_table_name in varchar2
  )
  as
    l_sql varchar2(32700);
  begin
    l_sql := 'truncate table ' || p_table_name; 
    execute immediate l_sql;
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end truncate_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure drop_constraints(
    p_table_name in varchar2
  ) 
  as
    l_sql varchar2(32700);
  begin
    for c1 in(
      select constraint_name
      from user_constraints
      where 1 = 1
      and table_name = p_table_name
    )loop
      l_sql := 'alter table '
        || p_table_name 
        || ' drop constraint '
        || c1.constraint_name
      ;
      execute immediate l_sql;
    end loop;
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end drop_constraints;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure drop_indexes(
    p_table_name in varchar2
  ) 
  as
    l_sql varchar2(32700);
  begin
    for c1 in(
      select index_name
      from user_indexes
      where 1 = 1
      and table_name = p_table_name
    )loop
      l_sql := 'drop index '
        || c1.index_name
      ;
      execute immediate l_sql;
    end loop;
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end drop_indexes;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure set_logging(
    p_table_name in varchar2,
    p_logging in varchar2 
  )
  as
    l_sql varchar2(32700);
  begin
    l_sql := 'alter table '
      || p_table_name
      || case 
        when p_logging = 'N'
        then ' nologging'
        else ' logging'
        end
    ;
    execute immediate l_sql;
  exception when others then
    dbms_output.put_line( l_sql );
    raise;
  end set_logging;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure modify_table(
    p_table_name  in varchar2,
    p_object_type in varchar2
  )
  as
    l_sql_arr etl_util.vc2_arr;
    l_sql varchar2(32700);
  begin

    l_sql_arr := case 
      when p_object_type = etl_util.g_object_type_index
      then etl_util.get_index(
          p_table_name => p_table_name
        )
      when p_object_type = etl_util.g_object_type_not_null
      then etl_util.get_not_null_constraint(
          p_table_name => p_table_name
        )
      when p_object_type = etl_util.g_object_type_primary_key
      then etl_util.get_primary_key(
          p_table_name => p_table_name
        )
      end
    ;
    
    for i in 1 .. l_sql_arr.count
    loop
      l_sql := l_sql_arr(i);
      execute immediate l_sql;
    end loop;
    
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end modify_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure gather_table_stats(
    p_table_name in varchar2
  )
  as
  begin 
    dbms_stats.gather_table_stats (
       ownname => sys_context( 'USERENV', 'PROXY_USER' )
      ,tabname => p_table_name
      ,cascade => true
    );
  end;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure initialize_table(
    p_table_name in varchar2
  )
  as
  begin
    -- Truncate table
    etl_tbl_util.truncate_table(
      p_table_name => p_table_name
    );
    -- Drop all constraints
    etl_tbl_util.drop_constraints(
      p_table_name => p_table_name
    );
    -- Drop indexes
    etl_tbl_util.drop_indexes(
      p_table_name => p_table_name
    );
    -- Set logging off
    etl_tbl_util.set_logging(
       p_table_name => p_table_name
      ,p_logging => 'N' 
    );
  end initialize_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure finalize_table(
    p_table_name in varchar2
  )
  as
    l_sql_arr etl_util.vc2_arr;
    l_sql varchar2(32700);
  begin
    -- Create not null constraints
    etl_tbl_util.modify_table(
       p_table_name   => p_table_name
      ,p_object_type  => etl_util.g_object_type_not_null
    );
    -- Create primary key
    etl_tbl_util.modify_table(
       p_table_name   => p_table_name 
      ,p_object_type  => etl_util.g_object_type_primary_key
    );
    -- Create indexes
    etl_tbl_util.modify_table(
       p_table_name => p_table_name
      ,p_object_type  => etl_util.g_object_type_index
    );
/*
    -- Set logging on
    etl_tbl_util.set_logging(
       p_table_name => p_table_name
      ,p_logging => 'Y' 
    );
*/
    -- Gather statistics
    etl_tbl_util.gather_table_stats(
      p_table_name => p_table_name
    );
  end finalize_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end "ETL_TBL_UTIL";
/
