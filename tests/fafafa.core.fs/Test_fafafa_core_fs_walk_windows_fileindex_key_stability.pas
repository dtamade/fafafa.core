{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_walk_windows_fileindex_key_stability;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.highlevel;

type
  { TTestCase_Walk_Windows_FileIndexKey }
  TTestCase_Walk_Windows_FileIndexKey = class(TTestCase)
  published
    procedure Test_FileIndex_Key_Stable_On_Same_Dir;
  end;

implementation

{$IFDEF WINDOWS}
uses Windows;
{$ENDIF}

procedure TTestCase_Walk_Windows_FileIndexKey.Test_FileIndex_Key_Stable_On_Same_Dir;
{$IFDEF WINDOWS}
var
  Dir: string;
  Opts: TFsWalkOptions;
  Count1, Count2: Integer;
  procedure CountVisit(const APath: string; const AStat: TfsStat; ADepth: Integer; out C: Integer);
  begin
    Inc(C);
  end;
begin
  Dir := 'key_stability_root_' + IntToStr(Random(1000000));
  try
    CreateDirectory(Dir, True);

    Opts := FsDefaultWalkOptions;
    Opts.FollowSymlinks := True;
    Opts.IncludeDirs := True;
    Opts.IncludeFiles := False;

    Count1 := 0;
    AssertEquals(0, WalkDir(Dir, Opts,
      function(const P: string; const S: TfsStat; D: Integer): Boolean
      begin
        Inc(Count1); Result := True;
      end));

    Count2 := 0;
    AssertEquals(0, WalkDir(Dir, Opts,
      function(const P: string; const S: TfsStat; D: Integer): Boolean
      begin
        Inc(Count2); Result := True;
      end));

    // 两次遍历计数应相等，间接验证 visited key 的稳定性（同一目录）
    AssertEquals(Count1, Count2);
  finally
    DeleteDirectory(Dir, True);
  end;
end;
{$ELSE}
begin
  // 非 Windows 平台跳过
  AssertTrue(True);
end;
{$ENDIF}

initialization
  RegisterTest(TTestCase_Walk_Windows_FileIndexKey);
end.

