{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_trimmode;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCase_TrimMode = class(TTestCase)
  published
    // TECSVTrimMode enum tests
    procedure Test_TrimMode_None_No_Trim;
    procedure Test_TrimMode_Headers_Only_Trim_Headers;
    procedure Test_TrimMode_Fields_Only_Trim_Data;
    procedure Test_TrimMode_All_Trim_Both;
    // Backward compat: TrimSpaces Boolean maps to csvTrimFields
    procedure Test_TrimSpaces_True_Maps_To_TrimFields;
    procedure Test_TrimSpaces_False_Maps_To_TrimNone;
    // ReadAll path tests
    procedure Test_ReadAll_TrimSpaces_Works;
    procedure Test_ReadAll_TrimMode_Fields_Works;
    // Quoted fields should preserve spaces
    procedure Test_TrimMode_Quoted_Fields_Preserve_Spaces;
  end;

  TTestCase_Aliases = class(TTestCase)
  published
    // Builder alias tests
    procedure Test_ReaderBuilder_Flexible_Alias;
    procedure Test_ReaderBuilder_LazyQuotes_Alias;
  end;

implementation

{ TTestCase_TrimMode }

procedure TTestCase_TrimMode.Test_TrimMode_None_No_Trim;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimNone;
  D.HasHeader := True;
  // Header line has spaces, data line has spaces
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // Headers should NOT be trimmed
  AssertEquals(' Name ', R.Headers[0]);
  AssertEquals(' Age ', R.Headers[1]);
  // Fields should NOT be trimmed
  AssertEquals(' Alice ', Rec.Field(0));
  AssertEquals(' 30 ', Rec.Field(1));
end;

procedure TTestCase_TrimMode.Test_TrimMode_Headers_Only_Trim_Headers;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimHeaders;
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // Headers SHOULD be trimmed
  AssertEquals('Name', R.Headers[0]);
  AssertEquals('Age', R.Headers[1]);
  // Fields should NOT be trimmed
  AssertEquals(' Alice ', Rec.Field(0));
  AssertEquals(' 30 ', Rec.Field(1));
end;

procedure TTestCase_TrimMode.Test_TrimMode_Fields_Only_Trim_Data;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimFields;
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // Headers should NOT be trimmed (TrimFields = only data)
  AssertEquals(' Name ', R.Headers[0]);
  AssertEquals(' Age ', R.Headers[1]);
  // Fields SHOULD be trimmed
  AssertEquals('Alice', Rec.Field(0));
  AssertEquals('30', Rec.Field(1));
end;

procedure TTestCase_TrimMode.Test_TrimMode_All_Trim_Both;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimAll;
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // Both should be trimmed
  AssertEquals('Name', R.Headers[0]);
  AssertEquals('Age', R.Headers[1]);
  AssertEquals('Alice', Rec.Field(0));
  AssertEquals('30', Rec.Field(1));
end;

procedure TTestCase_TrimMode.Test_TrimSpaces_True_Maps_To_TrimFields;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimSpaces := True; // backward compat
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // TrimSpaces=True maps to csvTrimFields: only data trimmed
  AssertEquals(' Name ', R.Headers[0]); // headers NOT trimmed
  AssertEquals('Alice', Rec.Field(0));   // data trimmed
end;

procedure TTestCase_TrimMode.Test_TrimSpaces_False_Maps_To_TrimNone;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimSpaces := False;
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  // Nothing trimmed
  AssertEquals(' Name ', R.Headers[0]);
  AssertEquals(' Alice ', Rec.Field(0));
end;

procedure TTestCase_TrimMode.Test_ReadAll_TrimSpaces_Works;
var
  D: TCSVDialect;
  R: ICSVReader;
  Tbl: TCSVTable;
begin
  D := DefaultRFC4180;
  D.TrimSpaces := True;
  D.HasHeader := False;
  R := CSVReaderBuilder.FromString(' a , b '#10' c , d ').Dialect(D).Build;
  Tbl := R.ReadAll;
  AssertEquals(2, Length(Tbl));
  // All unquoted fields should be trimmed
  AssertEquals('a', Tbl[0][0]);
  AssertEquals('b', Tbl[0][1]);
  AssertEquals('c', Tbl[1][0]);
  AssertEquals('d', Tbl[1][1]);
end;

procedure TTestCase_TrimMode.Test_ReadAll_TrimMode_Fields_Works;
var
  D: TCSVDialect;
  R: ICSVReader;
  Tbl: TCSVTable;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimFields;
  D.HasHeader := True;
  R := CSVReaderBuilder.FromString(' Name , Age '#10' Alice , 30 ').Dialect(D).Build;
  Tbl := R.ReadAll;
  AssertEquals(1, Length(Tbl)); // 1 data row
  // Headers should NOT be trimmed (accessed via Headers property)
  AssertEquals(' Name ', R.Headers[0]);
  // Data fields SHOULD be trimmed
  AssertEquals('Alice', Tbl[0][0]);
  AssertEquals('30', Tbl[0][1]);
end;

procedure TTestCase_TrimMode.Test_TrimMode_Quoted_Fields_Preserve_Spaces;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  D := DefaultRFC4180;
  D.TrimMode := csvTrimAll;
  D.HasHeader := False;
  // First field quoted (spaces preserved), second field unquoted (trimmed)
  R := CSVReaderBuilder.FromString('"  quoted  ",  unquoted  ').Dialect(D).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('  quoted  ', Rec.Field(0)); // quoted: spaces preserved
  AssertEquals('unquoted', Rec.Field(1));   // unquoted: trimmed
end;

{ TTestCase_Aliases }

procedure TTestCase_Aliases.Test_ReaderBuilder_Flexible_Alias;
var
  D: TCSVDialect;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // Flexible is alias for AllowVariableFields
  R := CSVReaderBuilder
    .FromString('a,b,c'#10'1,2'#10'x,y,z,w')
    .Flexible(True) // should allow variable field count
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(3, Rec.Count); // a,b,c
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(2, Rec.Count); // 1,2 - only 2 fields, no error
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(4, Rec.Count); // x,y,z,w - 4 fields, no error
end;

procedure TTestCase_Aliases.Test_ReaderBuilder_LazyQuotes_Alias;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // LazyQuotes is alias for AllowLazyQuotes
  // Test: unescaped quote in middle of field should be allowed
  R := CSVReaderBuilder
    .FromString('a"b,c')
    .LazyQuotes(True)
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('a"b', Rec.Field(0));
  AssertEquals('c', Rec.Field(1));
end;

initialization
  RegisterTest(TTestCase_TrimMode);
  RegisterTest(TTestCase_Aliases);

end.
