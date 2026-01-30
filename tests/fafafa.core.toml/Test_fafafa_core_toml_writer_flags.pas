{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_writer_flags;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Writer_Flags = class(TTestCase)
  published
    procedure Test_Writer_Tight_Default_No_ExtraSpaces;
  end;

implementation

procedure TTestCase_Writer_Flags.Test_Writer_Tight_Default_No_ExtraSpaces;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('foo = 1' + LineEnding + 'a.b.c = "x"'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := ToToml(LDoc, []);
  AssertTrue(Pos('foo = 1', String(S)) > 0);
  AssertTrue(Pos('[a]' + LineEnding + 'b =', String(S)) = 0); // 默认不输出中间层键 b 的标量（作为表头）
  AssertTrue(Pos('[a.b]' + LineEnding + 'c = "x"', String(S)) > 0);
end;

initialization
  RegisterTest(TTestCase_Writer_Flags);
end.

