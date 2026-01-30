{$CODEPAGE UTF8}
unit Test_term_paste_storage_bytes;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_PasteStorageBytes = class(TTestCase)
  published
    procedure Test_MaxBytes_Trim_Oldest;
  end;

implementation

procedure TTestCase_PasteStorageBytes.Test_MaxBytes_Trim_Oldest;
var
  i: Integer;
  s: string;
begin
  term_paste_clear_all;
  term_paste_set_auto_keep_last(0);
  term_paste_set_max_bytes(5); // 最多 5 字节
  // 依次加入 'A','B','C'（各1字节，合计3），然后加入 'DE'（2字节，合计5），应无回收
  term_paste_store_text('A');
  term_paste_store_text('B');
  term_paste_store_text('C');
  term_paste_store_text('DE');
  AssertEquals(SizeUInt(4), term_paste_get_count());
  AssertEquals(SizeUInt(5), term_paste_get_total_bytes());

  // 再加入 'XYZ'（3字节），累计将达 8，需回收最旧直到 <=5
  term_paste_store_text('XYZ');
  // 当前应保留的是从队尾往回累计到不超过5的片段：'DE','XYZ'（2+3=5）
  AssertEquals(SizeUInt(2), term_paste_get_count());
  AssertEquals(SizeUInt(5), term_paste_get_total_bytes());
  AssertEquals('DE', term_paste_get_text(0));
  AssertEquals('XYZ', term_paste_get_text(1));

  // 清理：关闭字节限额
  term_paste_set_max_bytes(0);
end;

initialization
  RegisterTest(TTestCase_PasteStorageBytes);

end.

