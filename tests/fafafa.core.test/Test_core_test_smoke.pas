unit Test_core_test_smoke;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8} // 测试/示例可含中文输出

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test, fafafa.core.test.utils, fafafa.core.test.snapshot,
  fafafa.core.fs;

type
  TTestCase_CoreTest_Smoke = class(TTestCase)
  published
    procedure Test_TempDir_Create_Works;
    procedure Test_Snapshot_Text_Basic;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_Smoke.Test_TempDir_Create_Works;
var
  P: string;
begin
  P := CreateTempDir('coretest_');
  AssertTrue('Temp dir should exist', DirectoryExists(P));
end;

procedure TTestCase_CoreTest_Smoke.Test_Snapshot_Text_Basic;
var
  Ok: boolean;
  SnapDir: string;
begin
  SnapDir := IncludeTrailingPathDelimiter('snapshots');
  Ok := CompareTextSnapshot(SnapDir, 'hello', 'Hello\n', True {initial update});
  AssertTrue('Snapshot compare expected true', Ok);
  // compare same again without update flag
  Ok := CompareTextSnapshot(SnapDir, 'hello', 'Hello\n', False);
  AssertTrue('Snapshot compare expected equal', Ok);
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_Smoke);
end;

end.

