{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_reader_dotted_extras;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Reader_Dotted_Extras = class(TTestCase)
  published
    procedure Test_Dotted_With_Spaces_And_Comments;
    procedure Test_Mixed_Simple_And_Dotted_Keys;
    procedure Test_LineEndings_CRLF_LF_CR;
    procedure Test_MultiLevel_Nesting_CrossReferences;
    procedure Test_Error_Duplicate_On_Same_Table;
    procedure Test_Error_Type_Mismatch_In_Path;
    procedure Test_Error_Empty_Segment; // a..b = 1 should be invalid
    procedure Test_Error_Invalid_Bare_Key_With_Space; // bare key with space is invalid
    procedure Test_Quoted_Key_With_Space_Should_Pass; // "in valid".b = 1 is valid
  end;

implementation

procedure TTestCase_Reader_Dotted_Extras.Test_Dotted_With_Spaces_And_Comments;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString(' a . b . c  =  "x"  # comment'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('a'));
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Mixed_Simple_And_Dotted_Keys;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('foo = 1' + LineEnding + 'a.b.c = "x"' + LineEnding + 'bar = true'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('foo'));
  AssertTrue(LDoc.Root.Contains('a'));
  AssertTrue(LDoc.Root.Contains('bar'));
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Error_Duplicate_On_Same_Table;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  // duplicate same key in same table
  AssertFalse(Parse(RawByteString('a.b = 1' + LineEnding + 'a.b = 2'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Error_Type_Mismatch_In_Path;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  // a is scalar, then a.b should be invalid (path segment not a table)
  AssertFalse(Parse(RawByteString('a = 1' + LineEnding + 'a.b = 2'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Reader_Dotted_Extras.Test_LineEndings_CRLF_LF_CR;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: RawByteString;
begin
  LErr.Clear;
  // CRLF
  S := RawByteString('a.b = 1' + #13#10 + 'a.c = 2');
  AssertTrue(Parse(S, LDoc, LErr));
  AssertFalse(LErr.HasError);
  // LF
  S := RawByteString('x.y = 3' + #10 + 'x.z = 4');
  AssertTrue(Parse(S, LDoc, LErr));
  AssertFalse(LErr.HasError);
  // CR
  S := RawByteString('m.n = 5' + #13 + 'm.o = 6');
  AssertTrue(Parse(S, LDoc, LErr));
  AssertFalse(LErr.HasError);
end;

procedure TTestCase_Reader_Dotted_Extras.Test_MultiLevel_Nesting_CrossReferences;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('a.b.c = 1' + LineEnding + 'a.d = 2' + LineEnding + 'a.b.e = 3'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  AssertTrue(LDoc.Root.Contains('a'));
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Error_Empty_Segment;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('a..b = 1'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Error_Invalid_Bare_Key_With_Space;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
begin
  LErr.Clear;
  AssertFalse(Parse(RawByteString('in valid = 1'), LDoc, LErr));
  AssertTrue(LErr.HasError);
end;

procedure TTestCase_Reader_Dotted_Extras.Test_Quoted_Key_With_Space_Should_Pass;
var
  LDoc: ITomlDocument;
  LErr: TTomlError;
  S: String;
begin
  LErr.Clear;
  AssertTrue(Parse(RawByteString('"in valid".b = 1'), LDoc, LErr));
  AssertFalse(LErr.HasError);
  S := String(ToToml(LDoc, [twfSortKeys]));
  AssertTrue(Pos('"in valid"', S) > 0);
  AssertTrue(Pos('b = 1', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Reader_Dotted_Extras);
end.

