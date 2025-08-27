{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_trailing_newline;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_TrailingNewline = class(TTestCase)
  published
    procedure Test_TrailingNewline_Added_When_Missing;
    procedure Test_TrailingNewline_Not_Added_When_Exists;
  end;

implementation

procedure TTestCase_TrailingNewline.Test_TrailingNewline_Added_When_Missing;
var Doc: IIniDocument; Err: TIniError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[s]'#10'a=1'), Doc, Err)); // 源串无末尾换行
  S := ToIni(Doc, [iwfForceLF, iwfStableKeyOrder, iwfTrailingNewline]);
  AssertTrue(Length(S)>0);
  AssertTrue(S[Length(S)] = #10);
end;

procedure TTestCase_TrailingNewline.Test_TrailingNewline_Not_Added_When_Exists;
var Doc: IIniDocument; Err: TIniError; S: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString('[s]'#10'a=1'#10), Doc, Err)); // 源串已有换行
  S := ToIni(Doc, [iwfForceLF, iwfTrailingNewline]);
  AssertTrue(Length(S)>0);
  AssertTrue(S[Length(S)] = #10);
end;

initialization
  RegisterTest(TTestCase_TrailingNewline);
end.

