unit Test_term_last_error_injection;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term
  {$IFDEF MSWINDOWS}, Windows{$ENDIF};

procedure RegisterTests;

implementation

type
  TTermLastErrorInjectTest = class(TTestCase)
  published
    procedure Test_PlatformCreate_Failure_Injection_Sets_LastError;
  end;

procedure TTermLastErrorInjectTest.Test_PlatformCreate_Failure_Injection_Sets_LastError;
var
  ok: Boolean;
  prev: String;
begin
  // 保存旧值
  prev := SysUtils.GetEnvironmentVariable('FAFAFA_TERM_FORCE_PLATFORM_FAIL');
  try
    // 打开失败注入
    {$IFDEF MSWINDOWS}
    Windows.SetEnvironmentVariable('FAFAFA_TERM_FORCE_PLATFORM_FAIL', '1');
    {$ELSE}
    fpSetEnv(PChar('FAFAFA_TERM_FORCE_PLATFORM_FAIL=1'));
    {$ENDIF}

    // 初始化应失败，last_error 非空
    ok := term_init;
    try
      AssertFalse('term_init should fail when platform creation is forced to fail', ok);
      AssertTrue('term_last_error should be non-empty after forced failure', term_last_error <> '');
    finally
      // 即便失败，调用 term_done 也应安全
      term_done;
    end;
  finally
    // 恢复环境变量
    {$IFDEF MSWINDOWS}
    if prev<>'' then Windows.SetEnvironmentVariable('FAFAFA_TERM_FORCE_PLATFORM_FAIL', PChar(prev))
    else Windows.SetEnvironmentVariable('FAFAFA_TERM_FORCE_PLATFORM_FAIL', nil);
    {$ELSE}
    if prev<>'' then fpSetEnv(PChar('FAFAFA_TERM_FORCE_PLATFORM_FAIL='+prev))
    else fpUnsetEnv('FAFAFA_TERM_FORCE_PLATFORM_FAIL');
    {$ENDIF}
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TTermLastErrorInjectTest);
end;

initialization
  RegisterTests;

end.

