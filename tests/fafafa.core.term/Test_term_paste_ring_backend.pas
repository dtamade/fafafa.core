unit Test_term_paste_ring_backend;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

procedure RegisterTests;

implementation

type
  TPasteRingBackendTest = class(TTestCase)
  published
    procedure Test_RingBackend_BasicStoreTrim;
  end;

procedure TPasteRingBackendTest.Test_RingBackend_BasicStoreTrim;
var
  prev: String;
  i: Integer;
  cnt: SizeUInt;
  total: SizeUInt;
begin
  prev := SysUtils.GetEnvironmentVariable('FAFAFA_TERM_PASTE_BACKEND');
  try
    term_paste_use_backend('ring');

    term_paste_clear_all;
    term_paste_set_max_bytes(0);
    term_paste_set_auto_keep_last(0);

    // 追加 1000 条，验证计数与取回
    for i := 1 to 1000 do
      term_paste_store_text('x');
    cnt := term_paste_get_count;
    total := term_paste_get_total_bytes;
    AssertEquals('count should be 1000', 1000, cnt);
    AssertEquals('total bytes should be 1000', 1000, total);

    // 设置 keep_last=10 并裁剪
    term_paste_trim_keep_last(10);
    AssertEquals('count after trim_keep_last(10)', 10, term_paste_get_count);

    // 设置上限 5 字节，追加一条 3 字符文本，触发按总字节裁剪
    term_paste_set_max_bytes(5);
    term_paste_store_text('abc');
    AssertTrue('total bytes <= 5', term_paste_get_total_bytes <= 5);
  finally
    if prev<>'' then term_paste_use_backend(prev) else term_paste_use_backend('legacy');
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TPasteRingBackendTest);
end;

initialization
  RegisterTests;

end.

