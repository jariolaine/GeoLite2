CREATE OR REPLACE package "ETL_UTIL"
authid definer
as
--------------------------------------------------------------------------------

  -- Global constants
  g_load_from_file            constant varchar2(40) := 'LOAD_FROM_FILE';
  g_load_from_src_tbl         constant varchar2(40) := 'LOAD_FROM_SRC_TABLE';

  g_etl_flow_all              constant varchar2(40) := 'ALL';
  g_etl_flow_new              constant varchar2(40) := 'NEW';
  g_etl_flow_asn              constant varchar2(40) := 'GeoLite2-ASN-CSV.zip';
  g_etl_flow_city             constant varchar2(40) := 'GeoLite2-City-CSV.zip';

  g_object_type_index         constant varchar2(40) := 'INDEX';
  g_object_type_not_null      constant varchar2(40) := 'NOT_NULL';
  g_object_type_primary_key   constant varchar2(40) := 'PRIMARY_KEY';

--------------------------------------------------------------------------------

  -- Global variables
  type vc2_arr is table of varchar2(4000) index by binary_integer;

--------------------------------------------------------------------------------
  procedure swap_synonym(
    p_table_name            in varchar2 default null,
    p_update_control_table  in boolean default true
  );
--------------------------------------------------------------------------------
  function load_data(
    p_table_name  in varchar2,
    p_load_type   in varchar2 default etl_util.g_load_from_file
  ) return number;
--------------------------------------------------------------------------------
  function get_not_null_constraint(
    p_table_name  in varchar2
  ) return etl_util.vc2_arr;
--------------------------------------------------------------------------------
  function get_primary_key(
    p_table_name  in varchar2
  ) return etl_util.vc2_arr;
--------------------------------------------------------------------------------
  function get_index(
    p_table_name  in varchar2
  ) return etl_util.vc2_arr;
--------------------------------------------------------------------------------
  procedure sync_schema(
    p_last_load_date in timestamp with local time zone default localtimestamp
  );
--------------------------------------------------------------------------------
  procedure run_etl_flow(
    p_flow_name in varchar2 default etl_util.g_etl_flow_new
  );
--------------------------------------------------------------------------------
end "ETL_UTIL";


/


CREATE OR REPLACE package body                "ETL_UTIL"
as
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  -- Private constants
  c_object_type_etl_flow      constant varchar2(40) := 'ETL_FLOW';

  c_object_type_src_synonym   constant varchar2(40) := 'SOURCE_SYNONYM';
  c_object_type_trg_synonym   constant varchar2(40) := 'TARGET_SYNONYM';

  c_load_source_sync          constant varchar2(40) := 'SYNC';
  c_load_source_file          constant varchar2(40) := 'FILE';
  
  c_initialize_table_prog     constant varchar2(40) := 'INITIALIZE_TABLE';
  c_finalize_table_prog       constant varchar2(40) := 'FINALIZE_TABLE';

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  -- Private procedures and functions
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure call_etl_tbl_proxy(
    p_owner      in varchar2,
    p_program    in varchar2,
    p_table_name in varchar2
  )
  as
    l_sql varchar2(32700);
  begin
    l_sql := 'begin '
      || p_owner
      || '.ETL_TBL_PROXY.'
      || p_program
      || '(:p_table_name); '
      || 'end;'
    ;
    execute immediate l_sql
    using p_table_name
    ;
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end call_etl_tbl_proxy;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  
  procedure update_etl_control(
    p_table_name in varchar2,
    p_source     in varchar2,
    p_row_cnt    in number,
    p_file_date  in timestamp with local time zone
  )
  as
  begin
    update etl_control set
       last_load_date = localtimestamp
      ,last_source = p_source
      ,last_row_cnt = p_row_cnt
      ,last_file_date = p_file_date
    where 1 = 1
    and table_name = p_table_name
    ;
  end update_etl_control;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  -- Global procedures and functions
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure swap_synonym(
    p_table_name            in varchar2 default null,
    p_update_control_table  in boolean default true
  )
  as
    l_sql varchar2(32700);
  begin

    for c1 in(
      select t1.object_name
        ,t1.object_type
        ,t1.table_name
        ,case
          when t1.object_type = etl_util.c_object_type_trg_synonym
          then t2.src_schema
          when object_type = etl_util.c_object_type_src_synonym
          then t2.trg_schema
         end as table_owner
      from etl_metadata t1
      join etl_control t2 on t1.table_name = t2.table_name
      where 1 = 1
      and ( t1.table_name = p_table_name or p_table_name is null )
      and t1.object_type in(etl_util.c_object_type_src_synonym, etl_util.c_object_type_trg_synonym)
    )loop      
      l_sql := 'create or replace synonym '
        || c1.object_name
        || ' for '
        || c1.table_owner
        || '.'
        || c1.table_name
      ;
      execute immediate l_sql;

      if  p_update_control_table
      then 
        update etl_control
        set src_schema = case 
            when c1.object_type = etl_util.c_object_type_src_synonym
            then c1.table_owner
            else src_schema
            end
          ,trg_schema  = case 
            when c1.object_type = etl_util.c_object_type_trg_synonym
            then c1.table_owner
            else trg_schema
            end
        where 1 = 1
        and table_name = c1.table_name
        ;
      end if;
    end loop;

  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end swap_synonym;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function load_data(
    p_table_name  in varchar2,
    p_load_type   in varchar2 default etl_util.g_load_from_file
  ) return number
  as
    l_row_cnt number;
    l_sql     varchar2(32700);
  begin
    for c1 in(
      select object_name
      from etl_metadata
      where 1 = 1
      and object_type = p_load_type
      and table_name = p_table_name
    )loop
      l_sql := 'begin :l_row_cont := ' || c1.object_name || '; end;';
      execute immediate l_sql
      using out l_row_cnt
      ;
    end loop;
    return coalesce( l_row_cnt, 0 );
  exception when others then
    dbms_output.put_line(l_sql);
    raise;
  end load_data;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function get_not_null_constraint(
    p_table_name in varchar2
  ) return etl_util.vc2_arr
  as
    l_sql_arr etl_util.vc2_arr;
    i pls_integer := 0;
  begin
    for c1 in(
      select table_name
        ,column_name
      from etl_metadata
      where 1 = 1
      and object_type = etl_util.g_object_type_not_null
      and table_name = p_table_name
    )loop
      i := i + 1;
      l_sql_arr(i) := 'alter table '
        || c1.table_name
        || ' modify(' 
        || c1.column_name
        || ' not null)'
      ;
    end loop;
    return l_sql_arr;
  end get_not_null_constraint;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function get_primary_key(
    p_table_name in varchar2
  ) return etl_util.vc2_arr
  as
    l_sql_arr etl_util.vc2_arr;
    i pls_integer := 0;
  begin
    for c1 in(
      select object_name
        ,table_name
        ,listagg(column_name,',') within group (order by sort_seq) as column_name
      from etl_metadata
      where 1 = 1
      and object_type = etl_util.g_object_type_primary_key
      and table_name = p_table_name
      group by object_name
        ,table_name
    )loop
      i := i + 1;
      l_sql_arr(i) := 'alter table '
        || c1.table_name
        || ' add constraint '
        || c1.object_name
        || ' primary key(' 
        || c1.column_name
        || ')'
        || ' using index'
        || ' nologging pctfree 0'
      ;
    end loop;
    return l_sql_arr;
  end get_primary_key;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  function get_index(
    p_table_name in varchar2
  ) return etl_util.vc2_arr
  as
    l_sql_arr etl_util.vc2_arr;
    i pls_integer := 0;
  begin
    for c1 in(
      select object_name
        ,table_name
        ,listagg(column_name,',') within group (order by sort_seq) as column_name
      from etl_metadata
      where 1 = 1
      and object_type = etl_util.g_object_type_index
      and table_name = p_table_name
      group by object_name
        ,table_name
    )loop
      i := i + 1;
      l_sql_arr(i) := 'create index '
        || c1.object_name
        || ' on '
        || c1.table_name
        || '('
        || c1.column_name
        || ')'
        || ' nologging pctfree 0'
      ;
    end loop;
    return l_sql_arr;
  end get_index;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure sync_schema(
    p_last_load_date in timestamp with local time zone default localtimestamp
  )
  as
    l_row_cnt   number;
  begin

    for c1 in(
      select t1.table_name
        ,t2.trg_schema
        ,t2.last_file_date
      from etl_metadata t1
      join etl_control t2 on t1.table_name = t2.table_name
      where 1 = 1
        and t1.object_type = etl_util.c_object_type_etl_flow
        and t2.last_source = etl_util.c_load_source_file
        and t2.last_load_date < p_last_load_date
      order by t1.sort_seq
    )loop

      -- Initiliaze table for ETL (truncate table, drop constraints and indexes)
      etl_util.call_etl_tbl_proxy(
         p_owner => c1.trg_schema
        ,p_program => etl_util.c_initialize_table_prog
        ,p_table_name => c1.table_name
      );
      -- Load data
      l_row_cnt := etl_util.load_data(
         p_table_name => c1.table_name
        ,p_load_type  => etl_util.g_load_from_src_tbl
      );
      -- Finalize load (create constraints and indexes)
      etl_util.call_etl_tbl_proxy(
         p_owner => c1.trg_schema
        ,p_program => etl_util.c_finalize_table_prog
        ,p_table_name => c1.table_name
      );
      -- Update etl end to control table        
      etl_util.update_etl_control(
         p_table_name => c1.table_name
        ,p_source     => etl_util.c_load_source_sync
        ,p_row_cnt    => l_row_cnt
        ,p_file_date  => c1.last_file_date
      );

    end loop;
  end sync_schema;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure run_etl_flow(
    p_flow_name in varchar2 default etl_util.g_etl_flow_new
  )
  as
    l_row_cnt   number;
    l_etl_start timestamp with local time zone;
  begin

    l_etl_start := localtimestamp;
    
    for c1 in(
      select t1.table_name
        ,t2.trg_schema
        ,t3.file_date
      from etl_metadata t1
      join etl_control t2 on t1.table_name = t2.table_name
      join ext_file_date t3 on t1.object_name = t3.file_name
      where 1 = 1
      and t1.object_type = etl_util.c_object_type_etl_flow
      and (
        ( t1.object_name = p_flow_name or p_flow_name = etl_util.g_etl_flow_all )
        or
        ( t2.last_file_date < t3.file_date and p_flow_name = etl_util.g_etl_flow_new )
      )
      order by t1.sort_seq
    )loop

      -- Initiliaze table for ETL
      -- (truncate table, drop constraints and indexes)
      etl_util.call_etl_tbl_proxy(
         p_owner => c1.trg_schema
        ,p_program => etl_util.c_initialize_table_prog
        ,p_table_name => c1.table_name
      );
      -- Load data
      l_row_cnt := etl_util.load_data(
         p_table_name => c1.table_name
      );
      -- Finalize load (create constraints and indexes)
      etl_util.call_etl_tbl_proxy(
         p_owner => c1.trg_schema
        ,p_program => etl_util.c_finalize_table_prog
        ,p_table_name => c1.table_name
      );
      -- Update etl end to control table        
      etl_util.update_etl_control(
         p_table_name => c1.table_name
        ,p_source     => etl_util.c_load_source_file
        ,p_row_cnt    => l_row_cnt
        ,p_file_date  => c1.file_date
      );

    end loop;

    -- Refresh inactive schema tables from active schema
    etl_util.sync_schema(
      p_last_load_date => l_etl_start
    );
    -- Swap synonyms
    etl_util.swap_synonym;

  end run_etl_flow;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end "ETL_UTIL";
/
