{$CODEPAGE UTF8}
unit TestHelpers_Env;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Skip;

// 返回 True 表示可交互（优先快速检测 IsATTY，其次校验 term_init，再验证 size/name）；
// 返回 False 表示不可交互，调用方应当调用 TestSkip(Self, '...') 并 Exit。
function TestEnv_AssumeInteractive(const aTestCase: TTestCase): Boolean;

implementation

function TestEnv_AssumeInteractive(const aTestCase: TTestCase): Boolean;
var
  ok: Boolean;
  Info: ITerminalInfo;
  w,h: term_size_t;
  name: string;
begin
  // 1) 先用无副作用的 IsATTY 快速判断
  Info := TTerminalInfo.Create;
  if (Info <> nil) and (not Info.IsATTY) then
  begin
    TestSkip(aTestCase, 'Non-interactive TTY');
    Exit(False);
  end;

  // 2) 再以 term_init 做最终确认
  ok := term_init;
  if not ok then
  begin
    TestSkip(aTestCase, 'term_init failed');
    Exit(False);
  end;

  // 3) 辅助判据：尺寸与名称
  w := 0; h := 0; name := term_name;
  if (not term_size(w,h)) or (w<=0) or (h<=0) or (name='') or (LowerCase(name)='unknown') then
  begin
    term_done;
    TestSkip(aTestCase, 'terminal not ready (size/name invalid)');
    Exit(False);
  end;

  term_done;
  Result := True;
end;

end.

