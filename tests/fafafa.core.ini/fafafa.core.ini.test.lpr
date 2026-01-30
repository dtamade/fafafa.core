{$CODEPAGE UTF8}
program fafafa.core.ini.test;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}cthreads,{$ENDIF}{$ENDIF}
  SysUtils, Classes,
  fpcunit, testregistry, consoletestrunner,
  fafafa.core.ini,
  fafafa.core.ini.testcase,
  Test_fafafa_core_ini_roundtrip_comments,
  Test_fafafa_core_ini_roundtrip_exact,
  Test_fafafa_core_ini_roundtrip_various,
  Test_fafafa_core_ini_write_flags,
  Test_fafafa_core_ini_entries_dirty_behavior,
  Test_fafafa_core_ini_entries_cases,
  Test_fafafa_core_ini_edge_cases,
  Test_fafafa_core_ini_inline_comment,
  Test_fafafa_core_ini_inline_comment_quotes,
  Test_fafafa_core_ini_unclosed_quotes,
  Test_fafafa_core_ini_utf16_bom,
  Test_fafafa_core_ini_default_prelude,
  Test_fafafa_core_ini_header_and_whitespace,
  Test_fafafa_core_ini_error_positions,
  Test_fafafa_core_ini_api_extras,
  Test_fafafa_core_ini_toFile_parseFileEx,
  Test_fafafa_core_ini_write_flags_extras,
  Test_fafafa_core_ini_trailing_newline,
  Test_fafafa_core_ini_read_flags_extras,
  Test_fafafa_core_ini_encoding_heuristic;

begin
  WriteLn('=== fafafa.core.ini 测试套件 ===');
  with TTestRunner.Create(nil) do
  begin
    Initialize;
    Run;
    Free;
  end;
end.

