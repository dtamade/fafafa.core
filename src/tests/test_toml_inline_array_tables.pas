unit test_toml_inline_array_tables;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

procedure RegisterTomlInlineArrayTableTests;

implementation

type
  TTomlInlineArrayCase = class(TTestCase)
  private
    function GetValueByPath(const Doc: ITomlDocument; const Path: String): ITomlValue;
  published
    procedure Test_Inline_Table_Scalars;
    procedure Test_Array_Of_Tables_Append;
    procedure Test_Array_Of_Tables_Conflict_With_NonArray;
  end;

function TTomlInlineArrayCase.GetValueByPath(const Doc: ITomlDocument; const Path: String): ITomlValue;
var
  T: ITomlTable; V: ITomlValue; Seg: String; P, PEnd: PChar;
begin
  Result := nil;
  if (Doc = nil) or (Doc.GetRoot = nil) then Exit;
  T := Doc.GetRoot;
  P := PChar(Path); PEnd := P + Length(Path); Seg := '';
  while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  while (P < PEnd) do
  begin
    V := T.GetValue(Seg);
    if (V = nil) or (V.GetType <> tvtTable) then Exit(nil);
    T := (V as ITomlTable);
    Inc(P); Seg := '';
    while (P < PEnd) and (P^ <> '.') do begin Seg := Seg + P^; Inc(P); end;
  end;
  Result := T.GetValue(Seg);
end;

procedure TTomlInlineArrayCase.Test_Inline_Table_Scalars;
var
  Doc: ITomlDocument; Err: TTomlError;
  V: ITomlValue; T1: ITomlTable;
  S: String; I: Int64; B: Boolean;
  Txt: RawByteString;
begin
  Txt := 'cfg = { a = 1, b = "x", c = true }';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  V := GetValueByPath(Doc, 'cfg');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtTable), Ord(V.GetType));
  T1 := V as ITomlTable;
  V := T1.GetValue('a'); AssertTrue(V.TryGetInteger(I)); AssertEquals(Int64(1), I);
  V := T1.GetValue('b'); AssertTrue(V.TryGetString(S));  AssertEquals('x', S);
  V := T1.GetValue('c'); AssertTrue(V.TryGetBoolean(B)); AssertTrue(B);
end;

procedure TTomlInlineArrayCase.Test_Array_Of_Tables_Append;
var
  Doc: ITomlDocument; Err: TTomlError;
  A: ITomlArray; V: ITomlValue; T0: ITomlTable; S: String;
  Txt: RawByteString;
begin
  Txt := '[[fruit]]' + LineEnding + 'name = "apple"' + LineEnding +
         '[[fruit]]' + LineEnding + 'name = "banana"';
  FillChar(Err, SizeOf(Err), 0);
  AssertTrue(Parse(Txt, Doc, Err));
  V := GetValueByPath(Doc, 'fruit');
  AssertTrue(V <> nil);
  AssertEquals(Ord(tvtArray), Ord(V.GetType));
  A := V as ITomlArray;
  AssertEquals(2, A.Count);
  T0 := A.Item(0) as ITomlTable; V := T0.GetValue('name'); AssertTrue(V.TryGetString(S)); AssertEquals('apple', S);
  T0 := A.Item(1) as ITomlTable; V := T0.GetValue('name'); AssertTrue(V.TryGetString(S)); AssertEquals('banana', S);
end;

procedure TTomlInlineArrayCase.Test_Array_Of_Tables_Conflict_With_NonArray;
var
  Doc: ITomlDocument; Err: TTomlError;
  Txt: RawByteString;
begin
  // conflict: fruit is scalar before array-of-tables header
  Txt := 'fruit = 1' + LineEnding + '[[fruit]]' + LineEnding + 'name = "apple"';
  FillChar(Err, SizeOf(Err), 0);
  AssertFalse(Parse(Txt, Doc, Err));
  AssertTrue(Err.HasError);
end;

procedure RegisterTomlInlineArrayTableTests;
begin
  RegisterTest('toml-inline-array', TTomlInlineArrayCase);
end;

end.

