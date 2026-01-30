unit Test_core_test_tempfile;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.utils, fafafa.core.fs;

type
  TTestCase_CoreTest_TempFile = class(TTestCase)
  published
    procedure Test_CreateTempFile_Returns_Valid_Path_And_Writable;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_TempFile.Test_CreateTempFile_Returns_Valid_Path_And_Writable;
var
  Path: string;
  F: TextFile;
begin
  Path := CreateTempFile('coretest_tmp_');
  AssertTrue('Temp file path should not be empty', Path <> '');
  // 文件应该存在（CreateTempFile 创建并立即关闭）
  AssertTrue('Temp file should exist', FileExists(Path));
  // 尝试写入内容
  AssignFile(F, Path);
  try
    Append(F);
  except
    on E: EInOutError do
    begin
      // 如果 Append 失败（例如文件刚创建为空且 Append 要求存在），回退 Rewrite
      Rewrite(F);
    end;
  end;
  try
    WriteLn(F, 'hello');
  finally
    CloseFile(F);
  end;
  // 清理
  DeleteFile(Path);
  AssertFalse('Temp file should be deleted', FileExists(Path));
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_TempFile);
end;

end.

