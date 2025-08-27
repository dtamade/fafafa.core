unit Test_core_test_snapshot_diff;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.snapshot;

type
  TTestCase_CoreTest_SnapshotDiff = class(TTestCase)
  published
    procedure Test_TextSnapshot_Generates_Diff_And_Cleanup_On_Update;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_CoreTest_SnapshotDiff.Test_TextSnapshot_Generates_Diff_And_Cleanup_On_Update;
var
  Dir, Name, BasePath, DiffPath: string;
  ok: boolean;
begin
  Dir := GetTempDir(False) + 'snap_diff_case';
  ForceDirectories(Dir);
  Name := 'text_simple';
  BasePath := IncludeTrailingPathDelimiter(Dir) + Name + '.snap.txt';
  DiffPath := IncludeTrailingPathDelimiter(Dir) + Name + '.snap.diff.txt';
  // 清理遗留
  if FileExists(BasePath) then DeleteFile(BasePath);
  if FileExists(DiffPath) then DeleteFile(DiffPath);

  // 1) 建立基线
  ok := CompareTextSnapshot(Dir, Name, 'hello', True);
  AssertTrue('baseline create', ok);
  AssertTrue('baseline exists', FileExists(BasePath));
  AssertFalse('diff not exist initially', FileExists(DiffPath));

  // 2) 内容变化但未更新 -> 生成 diff 文件，返回 False
  ok := CompareTextSnapshot(Dir, Name, 'hello world', False);
  AssertFalse('should not match', ok);
  AssertTrue('diff generated', FileExists(DiffPath));

  // 3) 选择更新基线 -> 清理 diff 文件
  ok := CompareTextSnapshot(Dir, Name, 'hello world', True);
  AssertTrue('update baseline', ok);
  AssertFalse('diff cleaned after update', FileExists(DiffPath));
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_SnapshotDiff);
end;

end.

