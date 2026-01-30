{$CODEPAGE UTF8}
unit test_path_search_unix_ext;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  {$IFDEF UNIX}BaseUnix, {$ENDIF}
  fafafa.core.process;

{$IFDEF UNIX}

Type
  TTestCase_PathSearch_Unix_Ext = class(TTestCase)
  private
    function MakeTempDir: string;
    procedure WriteTextFile(const APath, AText: string);
    procedure MakeExecutable(const APath: string);
    procedure MakeNonExecutable(const APath: string);
  published
    procedure Test_PathSearch_Respects_ExecutableBit;
    procedure Test_PathSearch_DoesNot_Search_CurrentDir;
    procedure Test_PathSearch_Uses_ProcessEnv_PATH;
  end;

{$ENDIF}

implementation

{$IFDEF UNIX}

function TTestCase_PathSearch_Unix_Ext.MakeTempDir: string;
var
  Base: string;
begin
  Base := GetTempDir(False);
  Result := IncludeTrailingPathDelimiter(Base) + 'fafafa_proc_ut_' + IntToStr(Random(1000000));
  if not CreateDir(Result) then
    raise Exception.Create('failed to create temp dir: ' + Result);
end;

procedure TTestCase_PathSearch_Unix_Ext.WriteTextFile(const APath, AText: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := AText;
    SL.SaveToFile(APath);
  finally
    SL.Free;
  end;
end;

procedure TTestCase_PathSearch_Unix_Ext.MakeExecutable(const APath: string);
const
  MODE_0755 = 493; // Octal 0755
begin
  if fpChmod(PChar(APath), MODE_0755) <> 0 then
    raise Exception.Create('fpChmod 0755 failed: ' + APath);
end;

procedure TTestCase_PathSearch_Unix_Ext.MakeNonExecutable(const APath: string);
const
  MODE_0644 = 420; // Octal 0644
begin
  if fpChmod(PChar(APath), MODE_0644) <> 0 then
    raise Exception.Create('fpChmod 0644 failed: ' + APath);
end;

procedure TTestCase_PathSearch_Unix_Ext.Test_PathSearch_Respects_ExecutableBit;
var
  TD, ExePath: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxdummy';
    WriteTextFile(ExePath, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
    MakeExecutable(ExePath);

    // 设置 PATH 仅包含临时目录
    if fpSetEnv(PChar('PATH=' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxdummy';
    SI.SetUsePathSearch(True);
    // 应能通过 Validate（可执行位满足）
    SI.Validate;
  finally
    // 清理：尽力删除
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Ext.Test_PathSearch_DoesNot_Search_CurrentDir;
var
  CWDFile: string;
  SI: IProcessStartInfo;
begin
  // 在当前目录创建一个可执行，但 PATH 不包含 '.'，应验证失败
  CWDFile := GetCurrentDir + DirectorySeparator + 'ux_here_dummy';
  WriteTextFile(CWDFile, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
  MakeExecutable(CWDFile);
  try
    if fpSetEnv(PChar('PATH=/usr/bin:/bin')) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'ux_here_dummy';
    SI.SetUsePathSearch(True);
    try
      SI.Validate;
      Fail('Validate should fail when only current dir has the file');
    except
      on E: EProcessStartError do CheckTrue(True);
    end;
  finally
    try DeleteFile(CWDFile); except end;
  end;
end;

procedure TTestCase_PathSearch_Unix_Ext.Test_PathSearch_Uses_ProcessEnv_PATH;
var
  TD, ExePath: string;
  SI: IProcessStartInfo;
begin
  TD := MakeTempDir;
  try
    ExePath := IncludeTrailingPathDelimiter(TD) + 'uxenv';
    WriteTextFile(ExePath, '#!/bin/sh' + LineEnding + 'exit 0' + LineEnding);
    MakeExecutable(ExePath);

    // 覆盖进程 PATH，让 Validate 使用新的 PATH
    if fpSetEnv(PChar('PATH=' + TD)) <> 0 then
      raise Exception.Create('fpSetEnv PATH failed');

    SI := TProcessStartInfo.Create;
    SI.FileName := 'uxenv';
    SI.SetUsePathSearch(True);
    SI.Validate; // 应通过，因为我们修改了进程 PATH
  finally
    try DeleteFile(ExePath); except end;
    try RemoveDir(TD); except end;
  end;
end;

{$ENDIF}

initialization
{$IFDEF UNIX}
  RegisterTest(TTestCase_PathSearch_Unix_Ext);
{$ENDIF}

end.

