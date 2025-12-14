unit Test_fafafa_core_csv_quote_nonnumeric;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv;

type
  TTestCSVQuoteNonNumeric = class(TTestCase)
  published
    // 测试 csvQuoteNonNumeric 模式下数字字段不加引号
    procedure Test_QuoteNonNumeric_Integer_NoQuote;
    procedure Test_QuoteNonNumeric_Float_NoQuote;
    procedure Test_QuoteNonNumeric_Negative_NoQuote;
    // 测试 csvQuoteNonNumeric 模式下非数字字段加引号
    procedure Test_QuoteNonNumeric_Text_Quoted;
    procedure Test_QuoteNonNumeric_Empty_NoQuote;
    // 测试混合字段
    procedure Test_QuoteNonNumeric_Mixed_Row;
  end;

implementation

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Integer_NoQuote;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['123']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 整数不应该被引号包裹
    AssertTrue('Integer should not be quoted', Pos('"', Result) = 0);
    AssertTrue('Should contain 123', Pos('123', Result) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Float_NoQuote;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['3.14']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 浮点数不应该被引号包裹
    AssertTrue('Float should not be quoted', Pos('"', Result) = 0);
    AssertTrue('Should contain 3.14', Pos('3.14', Result) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Negative_NoQuote;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['-42.5']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 负数不应该被引号包裹
    AssertTrue('Negative number should not be quoted', Pos('"', Result) = 0);
    AssertTrue('Should contain -42.5', Pos('-42.5', Result) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Text_Quoted;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['hello']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 文本字段应该被引号包裹
    AssertTrue('Text should be quoted', Pos('"hello"', Result) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Empty_NoQuote;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 空字段不应该被引号包裹
    AssertTrue('Empty field should not be quoted', Pos('"', Result) = 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCSVQuoteNonNumeric.Test_QuoteNonNumeric_Mixed_Row;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Result: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteNonNumeric)
      .Build;
    W.WriteRow(['Alice', '25', '3.5']);
    W.Flush;
    SetLength(Result, MS.Size);
    if MS.Size > 0 then
    begin
      MS.Position := 0;
      MS.ReadBuffer(Pointer(Result)^, MS.Size);
    end;
    // 文本字段被引号包裹，数字字段不被引号包裹
    AssertTrue('Text Alice should be quoted', Pos('"Alice"', Result) > 0);
    // 检查数字没有被引号包裹（在 Alice 后面应该是 ,25, 或 ,3.5）
    AssertTrue('Mixed row should have correct format', 
      (Pos('"Alice",25,3.5', Result) > 0) or (Pos('"Alice",25,3.5'#13#10, Result) > 0) or
      (Pos('"Alice",25,3.5'#10, Result) > 0));
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCSVQuoteNonNumeric);
end.
