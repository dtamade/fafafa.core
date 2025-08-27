{$CODEPAGE UTF8}
program tests_json;
{$APPTYPE CONSOLE}


{$mode objfpc}{$H+}

uses
  SysUtils, consoletestrunner,
  Test_fafafa_core_json,
  Test_fafafa_core_json_reader_flags,
  Test_fafafa_core_json_reader_details,
  Test_fafafa_core_json_writer,
  Test_fafafa_core_json_writer_equiv,
  Test_fafafa_core_json_mutable,
  Test_fafafa_core_json_incr_reader,
  Test_fafafa_core_json_incr_reader_edges,
  Test_fafafa_core_json_pointer_modes,
  Test_fafafa_core_json_pointer,
  Test_fafafa_core_json_pointer_edges,
  Test_fafafa_core_json_patch,
  Test_fafafa_core_json_patch_edges,
  Test_fafafa_core_json_patch_more,
  Test_fafafa_core_json_fluent,
  Test_fafafa_core_json_fluent_nesting,
  Test_fafafa_core_json_facade,
  Test_fafafa_core_json_writer_facade,
  Test_fafafa_core_json_patch_helpers,
  Test_fafafa_core_json_patch_helpers_edges,
  Test_fafafa_core_json_patch_helpers_more_edges,
  Test_fafafa_core_json_pointer_object_value_arrays,
  Test_fafafa_core_json_pointer_nested_arrays,
  Test_fafafa_core_json_pointer_nested_flags,
  Test_fafafa_core_json_pointer_mixed_trailing,
  Test_fafafa_core_json_pointer_root_trailing_flags,
  Test_fafafa_core_json_pointer_escape_edges,
  Test_fafafa_core_json_pointer_bom_comments_trailing,
  Test_fafafa_core_json_pointer_bom_comments_trailing_root_array,
  Test_fafafa_core_json_pointer_empty_token_and_double_slash,
  Test_fafafa_core_json_noexcept,
  test_json_core,
  Test_fafafa_core_json_encoding_flags;

var
  Application: TTestRunner;
  LogPath: String;
  F: TextFile;
begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Title := 'FPCUnit Console test runner for fafafa.core.json';
  Application.Initialize;
  // 将结果也写入到同目录日志文件，避免控制台输出被抑制
  LogPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'tests_json.out.txt';
  AssignFile(F, LogPath);
  try
    Rewrite(F);
    Writeln(F, '=== fafafa.core.json tests run ===');
    Writeln(F, 'Start: ', DateTimeToStr(Now));
    try
      Application.Run;
      Writeln('--- Tests Completed ---');
      Writeln(F, 'Completed: ', DateTimeToStr(Now));
      Writeln(F, 'Status: completed (see console for details)');
      Halt(0);
    except
      on E: Exception do begin
        Writeln(F, 'Exception: ', E.ClassName, ': ', E.Message);
        Writeln(F, 'Status: failed');
        Halt(1);
      end;
    end;
  finally
    CloseFile(F);
    Application.Free;
  end;
end.

