unit Test_term_paste_ring_edgecases;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

procedure RegisterTests;

implementation

type
  TPasteRingEdgeTests = class(TTestCase)
  published
    procedure Test_KeepLast_GreaterThanCount_NoChange;
    procedure Test_SingleItem_ExceedsMax_ResultsEmpty;
    procedure Test_Combined_KeepLast_And_MaxBytes_TotalWithinCap;
  end;

procedure TPasteRingEdgeTests.Test_KeepLast_GreaterThanCount_NoChange;
var
  prev: string;
  beforeCount: SizeUInt;
begin
  prev := SysUtils.GetEnvironmentVariable('FAFAFA_TERM_PASTE_BACKEND');
  try
    term_paste_use_backend('ring');

    term_paste_clear_all;
    term_paste_store_text('a');
    term_paste_store_text('b');
    beforeCount := term_paste_get_count; // 2
    term_paste_trim_keep_last(10);
    AssertEquals('keep_last>count should not change count', beforeCount, term_paste_get_count);
  finally
    if prev<>'' then term_paste_use_backend(prev) else term_paste_use_backend('legacy');
  end;
end;

procedure TPasteRingEdgeTests.Test_SingleItem_ExceedsMax_ResultsEmpty;
var
  prev: string;
  big: string;
begin
  prev := SysUtils.GetEnvironmentVariable('FAFAFA_TERM_PASTE_BACKEND');
  try
    term_paste_use_backend('ring');

    term_paste_clear_all;
    term_paste_set_auto_keep_last(0);
    term_paste_set_max_bytes(4);

    big := '123456789';
    term_paste_store_text(big);

    // 当前实现：当单条超过 max 时会在修剪中移空（保持约束一致性）
    AssertEquals('single item exceeding max_bytes should be dropped', 0, term_paste_get_count);
    AssertEquals('total bytes should be 0 after drop', 0, term_paste_get_total_bytes);
  finally
    if prev<>'' then term_paste_use_backend(prev) else term_paste_use_backend('legacy');
  end;
end;

procedure TPasteRingEdgeTests.Test_Combined_KeepLast_And_MaxBytes_TotalWithinCap;
var
  prev: string;
  i: Integer;
  cap: SizeUInt;
begin
  prev := SysUtils.GetEnvironmentVariable('FAFAFA_TERM_PASTE_BACKEND');
  try
    term_paste_use_backend('ring');

    term_paste_clear_all;
    term_paste_set_auto_keep_last(1000);
    cap := 64;
    term_paste_set_max_bytes(cap);

    // 每条 8 字节，插入 100 条，最终应修剪到总字节 <= cap
    for i := 1 to 100 do
      term_paste_store_text('12345678');

    AssertTrue('total bytes within max cap', term_paste_get_total_bytes <= cap);
  finally
    if prev<>'' then term_paste_use_backend(prev) else term_paste_use_backend('legacy');
  end;
end;

procedure RegisterTests;
begin
  RegisterTest(TPasteRingEdgeTests);
end;

initialization
  RegisterTests;

end.

