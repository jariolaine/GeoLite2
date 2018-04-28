CREATE OR REPLACE package "ETL_TBL_PROXY"
authid definer
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
end "ETL_TBL_PROXY";

/


CREATE OR REPLACE package body "ETL_TBL_PROXY"
as
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure initialize_table(
    p_table_name in varchar2
  )
  as
  begin
    geolite2_owner.etl_tbl_util.initialize_table(
      p_table_name => p_table_name
    );
  end initialize_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  procedure finalize_table(
    p_table_name in varchar2
  )
  as
  begin
    geolite2_owner.etl_tbl_util.finalize_table(
      p_table_name => p_table_name
    );
  end finalize_table;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
end "ETL_TBL_PROXY";
/
