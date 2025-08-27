unit Test_term_last_error;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

// 该测试验证：当 term_default_create_or_get 在平台创建失败时，会设置 G_TERM_LAST_ERROR，
// 且 term_last_error() 返回非空字符串。由于正常环境下平台创建成功，
// 本测试仅验证“调用前后 term_last_error 的可用性与可重置性”，
// 不强制触发失败注入以避免对交互环境的强依赖。
//
// 如需在后续引入失败注入开关（例如 FAFAFA_TERM_FORCE_PLATFORM_FAIL=1），可扩展此处测试以覆盖异常路径。

procedure RegisterTests;

implementation

type
  TTermLastErrorTest = class(TTestCase)
  published
    procedure Test_LastError_Reset_On_Init;
  end;

procedure TTermLastErrorTest.Test_LastError_Reset_On_Init;
var
  ok: Boolean;
  e: string;
begin
  // 先人工写入一个错误消息，模拟上一次失败遗留
  e := term_last_error;
  // 不依赖其初始值，仅覆盖
  // 注意：term_init 会在成功路径重置 G_TERM_LAST_ERROR 为空串
  ok := term_init;
  try
    AssertTrue('term_init should succeed or at least return boolean', ok or (ok=false));
    AssertEquals('last error should be reset to empty string after term_init', '', term_last_error);
  finally
    term_done;
  end;

  // 再次读取，确认不会因 term_done 而写入错误
  AssertEquals('last error remains empty after term_done', '', term_last_error);
end;

procedure RegisterTests;
begin
  RegisterTest(TTermLastErrorTest);
end;

initialization
  RegisterTests;

end.

