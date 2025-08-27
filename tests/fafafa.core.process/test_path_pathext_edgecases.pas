{$CODEPAGE UTF8}
unit test_path_pathext_edgecases;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  fafafa.core.process;

type
  TTestCase_PathPathext_Edge = class(TTestCase)
  published
    {$IFDEF WINDOWS}
    procedure TestWindows_PathExt_Empty_UsesDefault;
    procedure TestWindows_PathExt_Custom_List;
    procedure TestWindows_PathExt_NoMatch_Fails;
    procedure TestWindows_FileName_NoExt_CaseInsensitive;
    {$ENDIF}
  end;

implementation

{$IFDEF WINDOWS}

procedure SetEnvPathext(const AValue: string);
begin
  Windows.SetEnvironmentVariable(PChar('PATHEXT'), PChar(AValue));
end;

procedure TTestCase_PathPathext_Edge.TestWindows_PathExt_Empty_UsesDefault;
var
  OldExt: string;
  SI: IProcessStartInfo;
begin
  OldExt := SysUtils.GetEnvironmentVariable('PATHEXT');
  try
    // 清空 PATHEXT，代码应回退到默认值 .COM;.EXE;.BAT;.CMD
    SetEnvPathext('');
    SI := TProcessStartInfo.Create;
    SI.FileName := 'cmd'; // 无扩展名
    // 不应抛出异常
    SI.Validate;
    AssertTrue(True);
  finally
    SetEnvPathext(OldExt);
  end;
end;

procedure TTestCase_PathPathext_Edge.TestWindows_PathExt_Custom_List;
var
  OldExt: string;
  SI: IProcessStartInfo;
begin
  OldExt := SysUtils.GetEnvironmentVariable('PATHEXT');
  try
    // 自定义顺序，仍应能找到 .EXE 可执行
    SetEnvPathext('.BAT;.EXE');
    SI := TProcessStartInfo.Create;
    SI.FileName := 'notepad'; // 通过 PATHEXT 找 notepad.exe
    SI.Validate;
    AssertTrue(True);
  finally
    SetEnvPathext(OldExt);
  end;
end;

procedure TTestCase_PathPathext_Edge.TestWindows_PathExt_NoMatch_Fails;
var
  OldExt: string;
  SI: IProcessStartInfo;
begin
  OldExt := SysUtils.GetEnvironmentVariable('PATHEXT');
  try
    // 无匹配扩展名，验证应失败
    SetEnvPathext('.XYZ');
    SI := TProcessStartInfo.Create;
    SI.FileName := 'cmd';
    try
      SI.Validate;
      Fail('Expected EProcessStartError when PATHEXT has no matching extension');
    except
      on E: EProcessStartError do AssertTrue(True);
    end;
  finally
    SetEnvPathext(OldExt);
  end;
end;

procedure TTestCase_PathPathext_Edge.TestWindows_FileName_NoExt_CaseInsensitive;
var
  SI: IProcessStartInfo;
begin
  // 文件名大小写不敏感，且可无扩展名
  SI := TProcessStartInfo.Create;
  SI.FileName := 'NOTEPAD';
  SI.Validate;
  AssertTrue(True);
end;

{$ENDIF}

initialization
  RegisterTest(TTestCase_PathPathext_Edge);

end.

