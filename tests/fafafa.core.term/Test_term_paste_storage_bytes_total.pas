{$CODEPAGE UTF8}
unit Test_term_paste_storage_bytes_total;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_PasteStorageBytesTotal = class(TTestCase)
  published
    procedure Test_Clear_All_Resets_TotalBytes;
    procedure Test_Trim_Keep_Last_Updates_TotalBytes;
  end;

implementation

procedure TTestCase_PasteStorageBytesTotal.Test_Clear_All_Resets_TotalBytes;
begin
  term_paste_clear_all;
  term_paste_set_max_bytes(0);
  term_paste_store_text('ABC');
  CheckEquals(SizeUInt(3), term_paste_get_total_bytes());
  term_paste_clear_all;
  CheckEquals(SizeUInt(0), term_paste_get_total_bytes());
end;

procedure TTestCase_PasteStorageBytesTotal.Test_Trim_Keep_Last_Updates_TotalBytes;
begin
  term_paste_clear_all;
  term_paste_store_text('AA');
  term_paste_store_text('BBB');
  term_paste_store_text('C');
  // 当前总字节 2+3+1=6
  CheckEquals(SizeUInt(6), term_paste_get_total_bytes());
  term_paste_trim_keep_last(2); // 应保留 'BBB','C' => 3+1=4
  CheckEquals(SizeUInt(2), term_paste_get_count());
  CheckEquals(SizeUInt(4), term_paste_get_total_bytes());
end;

initialization
  RegisterTest(TTestCase_PasteStorageBytesTotal);

end.

