unit Test_fafafa_core_csv_quoting_disabled;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCSVQuotingDisabled = class(TTestCase)
  published
    // Quoting(False) 时，引号被视为普通字符
    procedure Test_Quoting_Disabled_QuoteAsLiteral;
    procedure Test_Quoting_Disabled_DoubleQuoteAsLiteral;
    procedure Test_Quoting_Enabled_Default;
  end;

implementation

procedure TTestCSVQuotingDisabled.Test_Quoting_Disabled_QuoteAsLiteral;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // 当 Quoting=False 时，引号不再有特殊含义，被当作普通字符
  R := CSVReaderBuilder
    .FromString('"hello",world')
    .Quoting(False)
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(2, Rec.Count);
  AssertEquals('"hello"', Rec.AsStr(0)); // 引号被保留
  AssertEquals('world', Rec.AsStr(1));
end;

procedure TTestCSVQuotingDisabled.Test_Quoting_Disabled_DoubleQuoteAsLiteral;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // 双引号也被当作普通字符
  R := CSVReaderBuilder
    .FromString('a""b,c')
    .Quoting(False)
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(2, Rec.Count);
  AssertEquals('a""b', Rec.AsStr(0)); // 双引号保留
  AssertEquals('c', Rec.AsStr(1));
end;

procedure TTestCSVQuotingDisabled.Test_Quoting_Enabled_Default;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // 默认 Quoting=True，引号有特殊含义
  R := CSVReaderBuilder
    .FromString('"hello",world')
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals(2, Rec.Count);
  AssertEquals('hello', Rec.AsStr(0)); // 引号被剥离
  AssertEquals('world', Rec.AsStr(1));
end;

initialization
  RegisterTest(TTestCSVQuotingDisabled);

end.
