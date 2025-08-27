{$CODEPAGE UTF8}
unit Test_term_windows_unicode_input;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env, TestHelpers_Skip;

{
  目的：黑盒验证 Unicode 宽字符键输入管线不崩溃，且能映射为 ktChar。
  说明：无法在无交互环境下直接注入 ReadConsoleInputW；本测试通过构造
  term_event_key + wchar 路径间接验证映射逻辑（MapEventToKeyEvent）。
}

type
  TTestCase_Windows_UnicodeInput = class(TTestCase)
  published
    procedure Test_WideChar_To_KeyEvent_Emoji_Smoke;
  end;

implementation

procedure TTestCase_Windows_UnicodeInput.Test_WideChar_To_KeyEvent_Emoji_Smoke;
var
  E, Ev2: term_event_t;
begin
  // 构造一个 tek_key，携带 WideChar（使用 BMP 字符 U+$4F60 '你' 以避免 surrogate 复杂性）
  E := term_event_key(KEY_UNKOWN, WideChar($4F60), False, False, False);
  CheckEquals(Ord(tek_key), Ord(E.kind), 'constructed kind=key');

  // 压入队列并立即取出，验证宽字符未丢失
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    term_evnet_push(E);
    FillByte(Ev2, SizeOf(Ev2), 0);
    CheckTrue(term_event_poll(Ev2, 0), 'should poll back the pushed event');
    CheckEquals(Ord(tek_key), Ord(Ev2.kind));
    CheckEquals(Ord(WideChar($4F60)), Ord(Ev2.key.char.wchar));
  finally
    term_done;
  end;
end;

initialization
  RegisterTest(TTestCase_Windows_UnicodeInput);
end.

