{$CODEPAGE UTF8}
unit Test_term_paste_storage;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_PasteStorage = class(TTestCase)
  published
    procedure Test_Trim_Keep_Last;
    procedure Test_Clear_All;
    procedure Test_Auto_Keep_Last_On_Parse;
  end;

implementation

procedure TTestCase_PasteStorage.Test_Trim_Keep_Last;
var
  i: Integer;
  ids: array of SizeUInt;
begin
  term_paste_clear_all;
  // 确保该用例与其它用例隔离：关闭全局治理参数
  term_paste_set_auto_keep_last(0);
  term_paste_set_max_bytes(0);
  SetLength(ids, 10);
  for i := 0 to 9 do
    ids[i] := term_paste_store_text('S' + IntToStr(i));
  // 仅保留最后 3 条，应为 S7,S8,S9
  term_paste_trim_keep_last(3);
  AssertEquals(SizeUInt(3), term_paste_get_count());
  AssertEquals('S7', term_paste_get_text(0));
  AssertEquals('S8', term_paste_get_text(1));
  AssertEquals('S9', term_paste_get_text(2));
  AssertEquals('', term_paste_get_text(3));
end;

procedure TTestCase_PasteStorage.Test_Clear_All;
begin
  term_paste_clear_all;
  AssertEquals('', term_paste_get_text(0));
  AssertEquals('', term_paste_get_text(1));
end;

procedure TTestCase_PasteStorage.Test_Auto_Keep_Last_On_Parse;
var
  Ev: term_event_t;
begin
  {$IFDEF UNIX}
  term_paste_clear_all;
  term_paste_set_auto_keep_last(1);
  term_init;
  try
    // 推入两段粘贴，最终仅保留最近一条
    // ESC[200~A ESC[201~
    term_evnet_push(term_event_key(KEY_UNKOWN, #27, False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '[', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '2', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '~', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, 'A', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, #27, False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '[', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '2', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '1', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '~', False, False, False));
    CheckTrue(term_event_poll(Ev, 0)); // 第一个 paste

    // 第二段：ESC[200~B ESC[201~
    term_evnet_push(term_event_key(KEY_UNKOWN, #27, False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '[', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '2', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '~', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, 'B', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, #27, False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '[', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '2', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '0', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '1', False, False, False));
    term_evnet_push(term_event_key(KEY_UNKOWN, '~', False, False, False));
    CheckTrue(term_event_poll(Ev, 0)); // 第二个 paste

    // 应仅保留最近一条 B
    AssertEquals('B', term_paste_get_text(0));
    AssertEquals('', term_paste_get_text(1));
  finally
    term_paste_set_auto_keep_last(0);
    term_done;
  end;
  {$ELSE}
  CheckTrue(True, 'not unix, skip');
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_PasteStorage);

end.

