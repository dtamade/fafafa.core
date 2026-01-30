{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_walk_windows_fileindex;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.options;

type
  { TTestCase_Walk_Windows_FileIndex }
  TTestCase_Walk_Windows_FileIndex = class(TTestCase)
  private
    FCount: Integer;
    function VisitMethod(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
  published
    procedure Test_Walk_FollowSymlinks_NoLoop_Windows;
  end;

implementation

function TTestCase_Walk_Windows_FileIndex.VisitMethod(const aPath: string; const aStat: TfsStat; aDepth: Integer): Boolean;
begin
  Inc(FCount);
  Result := True;
end;

procedure TTestCase_Walk_Windows_FileIndex.Test_Walk_FollowSymlinks_NoLoop_Windows;
var
  Root, DirA, DirB, LinkAtoB, LinkBtoA: string;
  Opts: TFsWalkOptions;
begin
  {$IFDEF WINDOWS}
  // 构造互相指向的符号链接（若权限不足，测试自动跳过）
  Root := 'walk_loop_root_' + IntToStr(Random(1000000));
  DirA := JoinPath(Root, 'A');
  DirB := JoinPath(Root, 'B');
  LinkAtoB := JoinPath(DirA, 'to_B');
  LinkBtoA := JoinPath(DirB, 'to_A');
  try
    CreateDirectory(DirA, True);
    CreateDirectory(DirB, True);
    // 可能因权限失败：若 fs_symlink 返回权限错误，视为跳过
    if fs_symlink(DirB, LinkAtoB) <> 0 then exit;
    if fs_symlink(DirA, LinkBtoA) <> 0 then exit;

    FCount := 0;
    Opts := FsDefaultWalkOptions;
    Opts.FollowSymlinks := True;
    Opts.IncludeFiles := False;
    Opts.IncludeDirs := True;
    AssertEquals(0, WalkDir(Root, Opts, @Self.VisitMethod));
    AssertTrue('跟随链接时应无无限递归（有 visited 防护），且至少访问根与两个子目录', FCount >= 3);
  finally
    DeleteDirectory(Root, True);
  end;
  {$ELSE}
  AssertTrue(True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Walk_Windows_FileIndex);
end.

