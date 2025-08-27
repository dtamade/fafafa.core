{$CODEPAGE UTF8}
unit Test_term_windows_modifiers;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term, fafafa.core.term.windows;

type
  TTestCase_Windows_Modifiers = class(TTestCase)
  published
    procedure Test_Key_Modifiers;
  end;

implementation

procedure TTestCase_Windows_Modifiers.Test_Key_Modifiers;
var
  E: term_event_t;
begin
  // 构造包含 SHIFT/CTRL/ALT 的键盘事件
  E := term_event_key(KEY_A, #0, True, True, True);
  // 使用显式数值断言，避免布尔表达式在部分编译器/单元测试版本下的解析问题
  CheckEquals(Ord(tek_key), Ord(E.kind), 'kind should be tek_key');
  CheckEquals(1, E.key.shift, 'shift should be 1');
  CheckEquals(1, E.key.ctrl,  'ctrl should be 1');
  CheckEquals(1, E.key.alt,   'alt should be 1');
end;

initialization
  RegisterTest(TTestCase_Windows_Modifiers);
end.

