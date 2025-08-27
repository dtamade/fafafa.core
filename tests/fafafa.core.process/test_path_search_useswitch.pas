{$CODEPAGE UTF8}
unit test_path_search_useswitch;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_PathSearch_UseSwitch = class(TTestCase)
  published
    procedure Test_UsePathSearch_Disabled_ShouldFail_On_Relative_NoExt;
    procedure Test_UsePathSearch_Disabled_ShouldFail_On_NameOnly;
  end;

implementation

procedure TTestCase_PathSearch_UseSwitch.Test_UsePathSearch_Disabled_ShouldFail_On_Relative_NoExt;
var
  S: IProcessStartInfo;
begin
  S := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  S.FileName := 'cmd';
  {$ELSE}
  S.FileName := 'ls';
  {$ENDIF}
  // 显式关闭 PATH 搜索
  S.SetUsePathSearch(False);
  try
    S.Validate;
    Fail('UsePathSearch(False) 时，名称仅为可执行名应失败');
  except
    on E: EProcessStartError do ; // 期望
  end;
end;

procedure TTestCase_PathSearch_UseSwitch.Test_UsePathSearch_Disabled_ShouldFail_On_NameOnly;
var
  S: IProcessStartInfo;
begin
  S := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  S.FileName := 'notepad';
  {$ELSE}
  S.FileName := 'sh';
  {$ENDIF}
  // 默认行为是 True，这里明确关闭以测试负路径
  S.SetUsePathSearch(False);
  try
    S.Validate;
    Fail('UsePathSearch(False) 时，名称仅为可执行名应失败');
  except
    on E: EProcessStartError do ;
  end;
end;

initialization
  RegisterTest(TTestCase_PathSearch_UseSwitch);
end.

