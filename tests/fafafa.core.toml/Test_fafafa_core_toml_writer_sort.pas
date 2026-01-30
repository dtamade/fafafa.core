{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_sort;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Sort = class(TTestCase)
  published
    procedure Test_Writer_SortKeys_Root_And_Subtables;
  end;

implementation

procedure TTestCase_Writer_Sort.Test_Writer_SortKeys_Root_And_Subtables;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
  Pb, Pz, Pab, Pad: SizeInt;
begin
  LErr.Clear;
  // 避免类型冲突：根级使用 b/z 作为标量键，a.* 作为子表
  AssertTrue(Parse(RawByteString('z = 0' + LineEnding + 'b = 1' + LineEnding + 'a.d.e = 2' + LineEnding + 'a.b.c = 3'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, [twfSortKeys]));
  // 根级 b 在 z 前
  Pb := Pos('b = 1', S);
  Pz := Pos('z = 0', S);
  AssertTrue((Pb > 0) and (Pz > 0) and (Pb < Pz));
  // 子表 [a.b] 在 [a.d] 前
  Pab := Pos('[a.b]', S);
  Pad := Pos('[a.d]', S);
  AssertTrue((Pab > 0) and (Pad > 0) and (Pab < Pad));
end;

initialization
  RegisterTest(TTestCase_Writer_Sort);
end.

