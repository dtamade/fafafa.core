{$CODEPAGE UTF8}
unit Test_term_paste_storage_defaults;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

type
  TTestCase_PasteStorageDefaults = class(TTestCase)
  published
    procedure Test_Defaults_Helper;
  end;

implementation

procedure TTestCase_PasteStorageDefaults.Test_Defaults_Helper;
begin
  term_paste_clear_all;
  term_paste_defaults(3, 4);
  term_paste_store_text('AB'); // 2 bytes
  term_paste_store_text('CD'); // 2 bytes, total=4 <= max
  term_paste_store_text('EFG'); // 3 bytes, total=7>4, trim oldest until <=4, expect ['EFG']
  AssertEquals(SizeUInt(1), term_paste_get_count());
  AssertEquals('EFG', term_paste_get_text(0));

  // also keep-last=3，继续追加，仍需满足两种约束
  term_paste_store_text('H'); // would be ['EFG','H'] total=4
  term_paste_store_text('IJK'); // +3 => 7>4, trim to last bytes => keep ['IJK']
  AssertEquals('IJK', term_paste_get_text(0));

  term_paste_set_max_bytes(0);
  term_paste_set_auto_keep_last(0);
end;

initialization
  RegisterTest(TTestCase_PasteStorageDefaults);

end.

