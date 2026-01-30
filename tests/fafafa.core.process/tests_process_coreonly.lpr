program tests_process_coreonly;

{$mode objfpc}{$H+}
{$WARN 5023 OFF}
{$HINTS OFF}
{$NOTES OFF}

uses
  Classes,
  consoletestrunner,
  // 核心用例（不包含 pipeline 系列）
  test_process,
  test_resource_cleanup,
  test_path_search,
  {$IFNDEF OMIT_SHELLEXECUTE_TESTS}test_useshellexecute,{$ENDIF}
  test_environment_block,
  test_builder_simple,
  test_utf8_builder,
  test_args_edgecases,
  test_args_edgecases_unix,
  test_args_edgecases_more,
  test_args_edgecases_final,
  test_combined_output,
  test_timeout_api,
  {$IFDEF WINDOWS}{$IFNDEF OMIT_SHELLEXECUTE_TESTS}test_shell_shellexecute_minimal,{$ENDIF}{$ENDIF}
  test_path_pathext_edgecases
  {$IFNDEF OMIT_PROCESS_GROUP_TESTS}
  , test_process_group_builder
  , test_process_group_exceptions
  , test_process_group_killtree
  , test_process_group_killtree_advanced
  {$IFDEF UNIX} , test_process_group_unix_basic {$ENDIF}
  {$IFDEF WINDOWS} , test_process_group_windows {$ENDIF}
  {$ENDIF}
  ;

var
  Application: TTestRunner;

begin
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.process Tests (Core Only)';
  Application.Run;
  Application.Free;
end.

