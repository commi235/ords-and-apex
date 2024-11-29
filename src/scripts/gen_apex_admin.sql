set serveroutput on size unlimited
set define '^'
set concat '.'
set verify off
set feedback off

alter session set container = cdb$root;

accept monitor_user char prompt 'Enter Monitoring User'
spool create_^monitor_user._global.sql

declare
  c_monitor_user constant varchar2(128) := upper('^monitor_user.');
  c_sql_stmt constant varchar2(23767) := q'[select count(*) from dba_users where username = :mon_user and exists ( select null from dba_registry where comp_id = 'APEX' )]';

  l_cursor_id  pls_integer;
  l_user_found pls_integer := 0;
  l_rows       pls_integer;
begin

  l_cursor_id := dbms_sql.open_cursor;
  for rec in (
      select dp.name as pdb_name
        from v$pdbs dp
       where dp.open_mode = 'READ WRITE'
         and (  dp.name like 'SEED\_APEX%' escape '\'
             or dp.name like 'MT\_%' escape '\'
             )
  ) loop
    dbms_output.put_line( 'PROMPT INFO >> PDB ' || rec.pdb_name );

    dbms_sql.parse
    (
      c             => l_cursor_id
    , statement     => c_sql_stmt
    , language_flag => dbms_sql.native
    , container     => rec.pdb_name
    );

    dbms_sql.define_column
    (
      c        => l_cursor_id
    , position => 1
    , column   => l_user_found
    );

    dbms_sql.bind_variable
    (
      c     => l_cursor_id
    , name  => ':mon_user'
    , value => c_monitor_user
    );

    l_rows := dbms_sql.execute_and_fetch( c => l_cursor_id, exact => true );

    dbms_sql.column_value
    (
      c        => l_cursor_id
    , position => 1
    , value    => l_user_found
    );

    if l_user_found = 0 then
      dbms_output.put_line( 'PROMPT INFO >> Switching to PDB ' || rec.pdb_name );
      dbms_output.put_line( 'alter session set container = ' || rec.pdb_name || ';' );
      dbms_output.put_line( 'PROMPT INFO >> Creating User ' || c_monitor_user );
      dbms_output.put_line( '' );
      dbms_output.put_line( 'create user ' || c_monitor_user || ' no authentication;' );
      dbms_output.put_line( 'grant create session, apex_administrator_read_role to ' || c_monitor_user || ';' );
      dbms_output.put_line( 'begin' );
      dbms_output.put_line( '  ords_admin.enable_schema( p_schema => ''' || c_monitor_user || ''' );' );
      dbms_output.put_line( 'end;' );
      dbms_output.put_line( '/' );
    else
      dbms_output.put_line( 'PROMPT INFO >> Skipping PDB ' || rec.pdb_name );
    end if;

    dbms_output.put_line( 'PROMPT ===============================' );
    dbms_output.put_line( '' );
  end loop;

  dbms_sql.close_cursor( c => l_cursor_id );

exception
  when others then
    dbms_sql.close_cursor( c => l_cursor_id );
    raise;
end;
/

spool off
