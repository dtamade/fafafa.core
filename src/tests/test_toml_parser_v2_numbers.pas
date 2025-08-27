unit test_toml_parser_v2_numbers;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml, fafafa.core.toml.parser.v2;

procedure RegisterTomlParserV2NumberTests;

implementation

type
  TTomlParserV2NumberCase = class(TTestCase)
  published
    procedure Test_Int_PositiveCases;
    procedure Test_Int_NegativeCases;
    procedure Test_Float_PositiveCases;
    procedure Test_Float_NegativeCases;
    procedure Test_Temporal_PositiveCases;
  end;

procedure TTomlParserV2NumberCase.Test_Int_PositiveCases;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('a = 10' + LineEnding + 'b = 1_000' + LineEnding + 'c = 0xDEAD_beef' + LineEnding + 'd = 0o755' + LineEnding + 'e = 0b1010_0101');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('a = 10', String(S)) > 0);
  AssertTrue(Pos('b = 1000', String(S)) > 0);
  AssertTrue(Pos('c = 3735928559', String(S)) > 0);
  AssertTrue(Pos('d = 493', String(S)) > 0);
  AssertTrue(Pos('e = 165', String(S)) > 0);
end;

procedure TTomlParserV2NumberCase.Test_Int_NegativeCases;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('a = 00' + LineEnding + 'b = 1__0' + LineEnding + 'c = _10' + LineEnding + 'd = 10_');
  AssertFalse(TomlParseV2(Inp, Doc, Err));
end;

procedure TTomlParserV2NumberCase.Test_Float_PositiveCases;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('x = 3.14' + LineEnding + 'y = 1e6' + LineEnding + 'z = -inf' + LineEnding + 'w = nan');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('x = 3.14', String(S)) > 0);
  AssertTrue(Pos('y = 1000000', String(S)) > 0);
end;

procedure TTomlParserV2NumberCase.Test_Float_NegativeCases;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString;
begin
  Inp := RawByteString('a = 1._0' + LineEnding + 'b = 1e_10' + LineEnding + 'c = 0xG');
  AssertFalse(TomlParseV2(Inp, Doc, Err));
end;

procedure TTomlParserV2NumberCase.Test_Temporal_PositiveCases;
var Doc: ITomlDocument; Err: TTomlError; Inp: RawByteString; S: RawByteString;
begin
  Inp := RawByteString('d1 = 2021-09-01' + LineEnding + 't1 = 12:34:56' + LineEnding + 'dt = 2021-09-01T12:34:56Z');
  if not TomlParseV2(Inp, Doc, Err) then Fail('Parse failed: ' + String(Err.Message));
  S := ToToml(Doc, [twfSpacesAroundEquals]);
  AssertTrue(Pos('d1 = 2021-09-01', String(S)) > 0);
  AssertTrue(Pos('t1 = 12:34:56', String(S)) > 0);
  AssertTrue(Pos('dt = 2021-09-01T12:34:56Z', String(S)) > 0);
end;

procedure RegisterTomlParserV2NumberTests;
begin
  RegisterTest('toml-parser-v2-numbers', TTomlParserV2NumberCase);
end;

end.

