unit test_toml_writer_nested_arrays_tables;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlWriterNestedArrayTableTests;

implementation

type
  TTomlWriterNestedArrayTableCase = class(TTestCase)
  private
    function NEOL(const S: String): String;
  published
    procedure Test_Writer_ArrayOfTables_Pretty_Sorted;
  end;

function TTomlWriterNestedArrayTableCase.NEOL(const S: String): String;
var R: String;
begin
  R := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  R := StringReplace(R, #13, #10, [rfReplaceAll]);
  Result := R;
end;

procedure TTomlWriterNestedArrayTableCase.Test_Writer_ArrayOfTables_Pretty_Sorted;
var
  Txt: RawByteString; Doc: ITomlDocument; Err: TTomlError; S, Exp, LE: String;
begin
  LE := LineEnding;
  Txt := '[[fruit]]' + #10 +
         'name = "apple"' + #10 +
         '[[fruit]]' + #10 +
         'name = "banana"' + #10 +
         '' + #10 +
         '[fruit.info]' + #10 +
         'colors = ["red","green"]' + #10;
  Err.Clear; AssertTrue(Parse(Txt, Doc, Err));
  S := String(ToToml(Doc, [twfPretty, twfSortKeys, twfSpacesAroundEquals]));
  Exp := '[[fruit]]' + LE +
         'name = "apple"' + LE + LE +
         '[[fruit]]' + LE +
         'name = "banana"' + LE + LE +
         '[fruit.info]' + LE +
         'colors = ["red", "green"]';
  if NEOL(Exp) <> NEOL(S) then
  begin
    Writeln('---EXPECT---');
    Writeln(NEOL(Exp));
    Writeln('---ACTUAL---');
    Writeln(NEOL(S));
    Fail('Mismatch');
  end;
end;

procedure RegisterTomlWriterNestedArrayTableTests;
begin
  RegisterTest('toml-writer-nested-arrays-tables', TTomlWriterNestedArrayTableCase);
end;

end.

