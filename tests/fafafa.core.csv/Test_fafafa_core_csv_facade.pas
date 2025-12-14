{$CODEPAGE UTF8}
unit Test_fafafa_core_csv_facade;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, fafafa.core.csv, Test_CSV_Utils;

type
  { 门面/快速 API 测试 }
  TTestCase_FacadeAPI = class(TTestCase)
  published
    // ReadCSVFile 测试
    procedure Test_ReadCSVFile_Basic;
    procedure Test_ReadCSVFile_WithDialect;
    procedure Test_ReadCSVFile_Empty;
    // WriteCSVFile 测试
    procedure Test_WriteCSVFile_Basic;
    procedure Test_WriteCSVFile_WithDialect;
    // ParseCSVString 测试
    procedure Test_ParseCSVString_Basic;
    procedure Test_ParseCSVString_WithDialect;
    procedure Test_ParseCSVString_Empty;
    procedure Test_ParseCSVString_Multiline;
    // ToCSVString 测试
    procedure Test_ToCSVString_Basic;
    procedure Test_ToCSVString_WithDialect;
    procedure Test_ToCSVString_Empty;
    procedure Test_ToCSVString_NeedsQuoting;
  end;

  { 预设方言测试 }
  TTestCase_PresetDialects = class(TTestCase)
  published
    procedure Test_TSVDialect_Defaults;
    procedure Test_PipeDialect_Defaults;
  end;

  { Builder 快捷方法测试 }
  TTestCase_BuilderShortcuts = class(TTestCase)
  published
    // ReaderBuilder
    procedure Test_ReaderBuilder_Delimiter_Tab;
    procedure Test_ReaderBuilder_HasHeader;
    procedure Test_ReaderBuilder_Flexible;
    procedure Test_ReaderBuilder_TrimSpaces;
    procedure Test_ReaderBuilder_Comment;
    procedure Test_ReaderBuilder_FromString;
    // WriterBuilder
    procedure Test_WriterBuilder_Delimiter_Tab;
    procedure Test_WriterBuilder_UseCRLF_False;
    procedure Test_WriterBuilder_QuoteMode_All;
  end;

implementation

{ TTestCase_FacadeAPI }

procedure TTestCase_FacadeAPI.Test_ReadCSVFile_Basic;
var
  TmpFile: string;
  Table: TCSVTable;
begin
  TmpFile := CreateTempCSVFile('facade_read', 'a,b,c'#13#10'd,e,f');
  try
    Table := ReadCSVFile(TmpFile);
    AssertEquals('Row count', 2, Length(Table));
    AssertEquals('Col count row 0', 3, Length(Table[0]));
    AssertEquals('Field 0,0', 'a', Table[0][0]);
    AssertEquals('Field 0,1', 'b', Table[0][1]);
    AssertEquals('Field 0,2', 'c', Table[0][2]);
    AssertEquals('Field 1,0', 'd', Table[1][0]);
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_FacadeAPI.Test_ReadCSVFile_WithDialect;
var
  TmpFile: string;
  Table: TCSVTable;
  D: TCSVDialect;
begin
  TmpFile := CreateTempCSVFile('facade_read_d', 'a;b;c'#10'd;e;f');
  try
    D := DefaultRFC4180;
    D.Delimiter := ';';
    D.UseCRLF := False;
    Table := ReadCSVFile(TmpFile, D);
    AssertEquals('Row count', 2, Length(Table));
    AssertEquals('Field 0,0', 'a', Table[0][0]);
    AssertEquals('Field 1,2', 'f', Table[1][2]);
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_FacadeAPI.Test_ReadCSVFile_Empty;
var
  TmpFile: string;
  Table: TCSVTable;
begin
  TmpFile := CreateTempCSVFile('facade_read_empty', '');
  try
    Table := ReadCSVFile(TmpFile);
    AssertEquals('Empty file should return 0 rows', 0, Length(Table));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_FacadeAPI.Test_WriteCSVFile_Basic;
var
  TmpFile: string;
  Table: TCSVTable;
  ReadBack: TCSVTable;
begin
  TmpFile := GetTempFileName('', 'facade_write');
  SetLength(Table, 2);
  SetLength(Table[0], 2);
  SetLength(Table[1], 2);
  Table[0][0] := 'x'; Table[0][1] := 'y';
  Table[1][0] := '1'; Table[1][1] := '2';
  try
    WriteCSVFile(TmpFile, Table);
    // 读回验证
    ReadBack := ReadCSVFile(TmpFile);
    AssertEquals('Row count', 2, Length(ReadBack));
    AssertEquals('Field 0,0', 'x', ReadBack[0][0]);
    AssertEquals('Field 1,1', '2', ReadBack[1][1]);
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_FacadeAPI.Test_WriteCSVFile_WithDialect;
var
  TmpFile: string;
  Table: TCSVTable;
  D: TCSVDialect;
  Content: string;
  FS: TFileStream;
  Buf: RawByteString;
begin
  TmpFile := GetTempFileName('', 'facade_write_d');
  SetLength(Table, 1);
  SetLength(Table[0], 2);
  Table[0][0] := 'a'; Table[0][1] := 'b';
  D := DefaultRFC4180;
  D.Delimiter := #9; // Tab
  D.UseCRLF := False;
  try
    WriteCSVFile(TmpFile, Table, D);
    // 读取原始内容验证分隔符
    FS := TFileStream.Create(TmpFile, fmOpenRead);
    try
      SetLength(Buf, FS.Size);
      FS.ReadBuffer(Pointer(Buf)^, FS.Size);
      Content := string(Buf);
      AssertTrue('Should contain tab', Pos(#9, Content) > 0);
      AssertTrue('Should not contain comma', Pos(',', Content) = 0);
    finally
      FS.Free;
    end;
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_FacadeAPI.Test_ParseCSVString_Basic;
var
  Table: TCSVTable;
begin
  Table := ParseCSVString('a,b'#13#10'c,d');
  AssertEquals('Row count', 2, Length(Table));
  AssertEquals('Field 0,0', 'a', Table[0][0]);
  AssertEquals('Field 1,1', 'd', Table[1][1]);
end;

procedure TTestCase_FacadeAPI.Test_ParseCSVString_WithDialect;
var
  Table: TCSVTable;
  D: TCSVDialect;
begin
  D := DefaultRFC4180;
  D.Delimiter := '|';
  Table := ParseCSVString('x|y'#13#10'1|2', D);
  AssertEquals('Row count', 2, Length(Table));
  AssertEquals('Field 0,0', 'x', Table[0][0]);
  AssertEquals('Field 0,1', 'y', Table[0][1]);
end;

procedure TTestCase_FacadeAPI.Test_ParseCSVString_Empty;
var
  Table: TCSVTable;
begin
  Table := ParseCSVString('');
  AssertEquals('Empty string should return 0 rows', 0, Length(Table));
end;

procedure TTestCase_FacadeAPI.Test_ParseCSVString_Multiline;
var
  Table: TCSVTable;
begin
  Table := ParseCSVString('"line1'#13#10'line2",b');
  AssertEquals('Row count', 1, Length(Table));
  AssertEquals('Field with newline', 'line1'#13#10'line2', Table[0][0]);
end;

procedure TTestCase_FacadeAPI.Test_ToCSVString_Basic;
var
  Table: TCSVTable;
  S: string;
begin
  SetLength(Table, 2);
  SetLength(Table[0], 2);
  SetLength(Table[1], 2);
  Table[0][0] := 'a'; Table[0][1] := 'b';
  Table[1][0] := 'c'; Table[1][1] := 'd';
  S := ToCSVString(Table);
  // 默认 CRLF
  AssertTrue('Should contain CRLF', Pos(#13#10, S) > 0);
  AssertTrue('Should contain a,b', Pos('a,b', S) > 0);
  AssertTrue('Should contain c,d', Pos('c,d', S) > 0);
end;

procedure TTestCase_FacadeAPI.Test_ToCSVString_WithDialect;
var
  Table: TCSVTable;
  D: TCSVDialect;
  S: string;
begin
  SetLength(Table, 1);
  SetLength(Table[0], 2);
  Table[0][0] := 'x'; Table[0][1] := 'y';
  D := UnixDialect;
  D.Delimiter := ';';
  S := ToCSVString(Table, D);
  AssertTrue('Should contain semicolon', Pos(';', S) > 0);
  AssertTrue('Should use LF only', (Pos(#10, S) > 0) or (Length(S) = 3)); // x;y or x;y\n
end;

procedure TTestCase_FacadeAPI.Test_ToCSVString_Empty;
var
  Table: TCSVTable;
  S: string;
begin
  SetLength(Table, 0);
  S := ToCSVString(Table);
  AssertEquals('Empty table should return empty string', '', S);
end;

procedure TTestCase_FacadeAPI.Test_ToCSVString_NeedsQuoting;
var
  Table: TCSVTable;
  S: string;
begin
  SetLength(Table, 1);
  SetLength(Table[0], 1);
  Table[0][0] := 'hello,world';
  S := ToCSVString(Table);
  AssertTrue('Should quote field with comma', Pos('"hello,world"', S) > 0);
end;

{ TTestCase_PresetDialects }

procedure TTestCase_PresetDialects.Test_TSVDialect_Defaults;
var
  D: TCSVDialect;
begin
  D := TSVDialect;
  AssertEquals('Delimiter should be Tab', #9, Char(D.Delimiter));
  AssertEquals('Quote should be double quote', '"', Char(D.Quote));
end;

procedure TTestCase_PresetDialects.Test_PipeDialect_Defaults;
var
  D: TCSVDialect;
begin
  D := PipeDialect;
  AssertEquals('Delimiter should be pipe', '|', Char(D.Delimiter));
end;

{ TTestCase_BuilderShortcuts }

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_Delimiter_Tab;
var
  TmpFile: string;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  TmpFile := CreateTempCSVFile('builder_delim', 'a'#9'b'#13#10'c'#9'd');
  try
    R := CSVReaderBuilder
      .FromFile(TmpFile)
      .Delimiter(#9)
      .Build;
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0));
    AssertEquals('b', Rec.Field(1));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_HasHeader;
var
  TmpFile: string;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  TmpFile := CreateTempCSVFile('builder_header', 'col1,col2'#13#10'a,b');
  try
    R := CSVReaderBuilder
      .FromFile(TmpFile)
      .HasHeader(True)
      .Build;
    AssertEquals('Header count', 2, Length(R.Headers));
    AssertEquals('Header 0', 'col1', R.Headers[0]);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_Flexible;
var
  TmpFile: string;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  // 第一行 2 字段，第二行 3 字段
  TmpFile := CreateTempCSVFile('builder_flex', 'a,b'#13#10'c,d,e');
  try
    R := CSVReaderBuilder
      .FromFile(TmpFile)
      .Flexible(True)
      .Build;
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(2, Rec.Count);
    AssertTrue(R.ReadNext(Rec));
    AssertEquals(3, Rec.Count);
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_TrimSpaces;
var
  TmpFile: string;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  TmpFile := CreateTempCSVFile('builder_trim', '  a  ,  b  ');
  try
    R := CSVReaderBuilder
      .FromFile(TmpFile)
      .TrimSpaces(True)
      .Build;
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0));
    AssertEquals('b', Rec.Field(1));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_Comment;
var
  TmpFile: string;
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  TmpFile := CreateTempCSVFile('builder_comment', '# this is comment'#13#10'a,b');
  try
    R := CSVReaderBuilder
      .FromFile(TmpFile)
      .Comment('#')
      .Build;
    AssertTrue(R.ReadNext(Rec));
    AssertEquals('a', Rec.Field(0));
    AssertFalse('No more records after comment line skipped', R.ReadNext(Rec));
  finally
    CleanupTempFile(TmpFile);
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_ReaderBuilder_FromString;
var
  R: ICSVReader;
  Rec: ICSVRecord;
begin
  R := CSVReaderBuilder
    .FromString('x,y'#13#10'1,2')
    .Build;
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('x', Rec.Field(0));
  AssertEquals('y', Rec.Field(1));
  AssertTrue(R.ReadNext(Rec));
  AssertEquals('1', Rec.Field(0));
end;

procedure TTestCase_BuilderShortcuts.Test_WriterBuilder_Delimiter_Tab;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Content: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .Delimiter(#9)
      .Build;
    W.WriteRow(['a', 'b']);
    W.Flush;
    SetLength(Content, MS.Size);
    MS.Position := 0;
    MS.ReadBuffer(Pointer(Content)^, MS.Size);
    AssertTrue('Should contain tab', Pos(#9, Content) > 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_WriterBuilder_UseCRLF_False;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Content: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .UseCRLF(False)
      .Build;
    W.WriteRow(['a', 'b']);
    W.Flush;
    SetLength(Content, MS.Size);
    MS.Position := 0;
    MS.ReadBuffer(Pointer(Content)^, MS.Size);
    AssertTrue('Should contain LF', Pos(#10, Content) > 0);
    AssertTrue('Should not contain CR before LF', Pos(#13#10, Content) = 0);
  finally
    MS.Free;
  end;
end;

procedure TTestCase_BuilderShortcuts.Test_WriterBuilder_QuoteMode_All;
var
  MS: TMemoryStream;
  W: ICSVWriter;
  Content: string;
begin
  MS := TMemoryStream.Create;
  try
    W := CSVWriterBuilder
      .ToStream(MS)
      .QuoteMode(csvQuoteAll)
      .Build;
    W.WriteRow(['a', 'b']);
    W.Flush;
    SetLength(Content, MS.Size);
    MS.Position := 0;
    MS.ReadBuffer(Pointer(Content)^, MS.Size);
    // QuoteAll 应该给所有字段加引号
    AssertTrue('Should quote all fields', Pos('"a"', Content) > 0);
  finally
    MS.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_FacadeAPI);
  RegisterTest(TTestCase_PresetDialects);
  RegisterTest(TTestCase_BuilderShortcuts);

end.
