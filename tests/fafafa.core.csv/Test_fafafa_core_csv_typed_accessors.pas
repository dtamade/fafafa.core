unit Test_fafafa_core_csv_typed_accessors;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.math, fafafa.core.csv;

type
  TTestCSVTypedAccessors = class(TTestCase)
  published
    // AsInt 按索引
    procedure Test_AsInt_Index_ValidInteger;
    procedure Test_AsInt_Index_InvalidReturnsDefault;
    procedure Test_AsInt_Index_EmptyReturnsDefault;
    
    // AsInt 按列名
    procedure Test_AsInt_Name_ValidInteger;
    procedure Test_AsInt_Name_InvalidReturnsDefault;
    procedure Test_AsInt_Name_NotFoundReturnsDefault;
    
    // AsInt64
    procedure Test_AsInt64_LargeValue;
    
    // AsFloat
    procedure Test_AsFloat_Index_ValidFloat;
    procedure Test_AsFloat_Name_ValidFloat;
    procedure Test_AsFloat_InvalidReturnsDefault;
    
    // AsBool
    procedure Test_AsBool_True_Values;
    procedure Test_AsBool_False_Values;
    procedure Test_AsBool_InvalidReturnsDefault;
    
    // AsStr
    procedure Test_AsStr_Index;
    procedure Test_AsStr_Name;
  end;

implementation

procedure TTestCSVTypedAccessors.Test_AsInt_Index_ValidInteger;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('42,hello').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(42, Rec.AsInt(0));
end;

procedure TTestCSVTypedAccessors.Test_AsInt_Index_InvalidReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('hello,world').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(-1, Rec.AsInt(0, -1));
end;

procedure TTestCSVTypedAccessors.Test_AsInt_Index_EmptyReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString(',world').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(99, Rec.AsInt(0, 99));
end;

procedure TTestCSVTypedAccessors.Test_AsInt_Name_ValidInteger;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('name,age'#10'Alice,30').HasHeader(True).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(30, Rec.AsIntByName('age'));
end;

procedure TTestCSVTypedAccessors.Test_AsInt_Name_InvalidReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('name,age'#10'Alice,abc').HasHeader(True).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(-1, Rec.AsIntByName('age', -1));
end;

procedure TTestCSVTypedAccessors.Test_AsInt_Name_NotFoundReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('name,age'#10'Alice,30').HasHeader(True).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(0, Rec.AsIntByName('notexist', 0));
end;

procedure TTestCSVTypedAccessors.Test_AsInt64_LargeValue;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('9223372036854775807').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(Int64(9223372036854775807), Rec.AsInt64(0));
end;

procedure TTestCSVTypedAccessors.Test_AsFloat_Index_ValidFloat;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('3.14,hello').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertTrue(Abs(Rec.AsFloat(0) - 3.14) < 0.001);
end;

procedure TTestCSVTypedAccessors.Test_AsFloat_Name_ValidFloat;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('name,price'#10'item,99.99').HasHeader(True).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertTrue(Abs(Rec.AsFloatByName('price') - 99.99) < 0.001);
end;

procedure TTestCSVTypedAccessors.Test_AsFloat_InvalidReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('abc').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertTrue(Abs(Rec.AsFloat(0, -1.0) - (-1.0)) < 0.001);
end;

procedure TTestCSVTypedAccessors.Test_AsBool_True_Values;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // true, 1, yes, y, on
  R := CSVReaderBuilder.FromString('true,1,yes,Y,on').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertTrue(Rec.AsBool(0));
  AssertTrue(Rec.AsBool(1));
  AssertTrue(Rec.AsBool(2));
  AssertTrue(Rec.AsBool(3));
  AssertTrue(Rec.AsBool(4));
end;

procedure TTestCSVTypedAccessors.Test_AsBool_False_Values;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // false, 0, no, n, off
  R := CSVReaderBuilder.FromString('false,0,no,N,off').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertFalse(Rec.AsBool(0));
  AssertFalse(Rec.AsBool(1));
  AssertFalse(Rec.AsBool(2));
  AssertFalse(Rec.AsBool(3));
  AssertFalse(Rec.AsBool(4));
end;

procedure TTestCSVTypedAccessors.Test_AsBool_InvalidReturnsDefault;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('maybe').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertTrue(Rec.AsBool(0, True));
  AssertFalse(Rec.AsBool(0, False));
end;

procedure TTestCSVTypedAccessors.Test_AsStr_Index;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('hello,world').Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('hello', Rec.AsStr(0));
  AssertEquals('world', Rec.AsStr(1));
end;

procedure TTestCSVTypedAccessors.Test_AsStr_Name;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder.FromString('name,city'#10'Alice,Beijing').HasHeader(True).Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('Alice', Rec.AsStrByName('name'));
  AssertEquals('Beijing', Rec.AsStrByName('city'));
end;

initialization
  RegisterTest(TTestCSVTypedAccessors);

end.
