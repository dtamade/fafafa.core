unit Test_fafafa_core_fs_bufio;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.fs.std,
  fafafa.core.fs.bufio,
  fafafa.core.fs.fileobj;

type
  TTestFsBufio = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFsBufReader 测试
    procedure Test_BufReader_ReadLine_LF;
    procedure Test_BufReader_ReadLine_CRLF;
    procedure Test_BufReader_ReadLine_CR;
    procedure Test_BufReader_ReadLine_Mixed;
    procedure Test_BufReader_ReadLine_Empty;
    procedure Test_BufReader_ReadLine_LastLineNoNewline;
    procedure Test_BufReader_ReadBytes;
    procedure Test_BufReader_ReadByte;
    procedure Test_BufReader_ReadAll;
    procedure Test_BufReader_BufferSize;
    procedure Test_BufReader_IsEof;

    // TFsBufWriter 测试
    procedure Test_BufWriter_WriteString;
    procedure Test_BufWriter_WriteLn;
    procedure Test_BufWriter_WriteByte;
    procedure Test_BufWriter_WriteBytes;
    procedure Test_BufWriter_Flush;
    procedure Test_BufWriter_AutoFlushOnDestroy;
    procedure Test_BufWriter_LargeWrite;

    // 便捷函数测试
    procedure Test_FsBufReader_Convenience;
    procedure Test_FsBufWriter_Convenience;
    procedure Test_FsForEachLine;

    // 集成测试
    procedure Test_RoundTrip_TextFile;
    procedure Test_RoundTrip_BinaryData;
  end;

implementation

{ TTestFsBufio }

procedure TTestFsBufio.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_bufio_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsBufio.TearDownTestDir;
var
  SR: TSearchRec;
begin
  // 清理测试文件
  if FindFirst(FTestDir + '*', faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Name <> '.') and (SR.Name <> '..') then
        DeleteFile(FTestDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  RemoveDir(FTestDir);
end;

procedure TTestFsBufio.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsBufio.TearDown;
begin
  TearDownTestDir;
end;

// ============================================================================
// TFsBufReader 测试
// ============================================================================

procedure TTestFsBufio.Test_BufReader_ReadLine_LF;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'lf.txt';
  FsWriteString(Path, 'Line1'#10'Line2'#10'Line3');

  Reader := FsBufReader(Path);
  try
    AssertTrue('Should read first line', Reader.ReadLine(Line));
    AssertEquals('First line', 'Line1', Line);

    AssertTrue('Should read second line', Reader.ReadLine(Line));
    AssertEquals('Second line', 'Line2', Line);

    AssertTrue('Should read third line', Reader.ReadLine(Line));
    AssertEquals('Third line', 'Line3', Line);

    AssertFalse('Should not read more', Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadLine_CRLF;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'crlf.txt';
  FsWriteString(Path, 'Line1'#13#10'Line2'#13#10'Line3');

  Reader := FsBufReader(Path);
  try
    AssertTrue('Should read first line', Reader.ReadLine(Line));
    AssertEquals('First line', 'Line1', Line);

    AssertTrue('Should read second line', Reader.ReadLine(Line));
    AssertEquals('Second line', 'Line2', Line);

    AssertTrue('Should read third line', Reader.ReadLine(Line));
    AssertEquals('Third line', 'Line3', Line);

    AssertFalse('Should not read more', Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadLine_CR;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'cr.txt';
  FsWriteString(Path, 'Line1'#13'Line2'#13'Line3');

  Reader := FsBufReader(Path);
  try
    AssertTrue('Should read first line', Reader.ReadLine(Line));
    AssertEquals('First line', 'Line1', Line);

    AssertTrue('Should read second line', Reader.ReadLine(Line));
    AssertEquals('Second line', 'Line2', Line);

    AssertTrue('Should read third line', Reader.ReadLine(Line));
    AssertEquals('Third line', 'Line3', Line);

    AssertFalse('Should not read more', Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadLine_Mixed;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'mixed.txt';
  FsWriteString(Path, 'Line1'#10'Line2'#13#10'Line3'#13'Line4');

  Reader := FsBufReader(Path);
  try
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Line1', Line);

    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Line2', Line);

    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Line3', Line);

    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Line4', Line);

    AssertFalse(Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadLine_Empty;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'empty.txt';
  FsWriteString(Path, '');

  Reader := FsBufReader(Path);
  try
    AssertFalse('Empty file should return False', Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadLine_LastLineNoNewline;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'no_newline.txt';
  FsWriteString(Path, 'Line1'#10'Line2');

  Reader := FsBufReader(Path);
  try
    AssertTrue(Reader.ReadLine(Line));
    AssertEquals('Line1', Line);

    AssertTrue('Last line without newline should still be read', Reader.ReadLine(Line));
    AssertEquals('Line2', Line);

    AssertFalse(Reader.ReadLine(Line));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadBytes;
var
  Path: string;
  Reader: TFsBufReader;
  Data: TBytes;
begin
  Path := FTestDir + 'bytes.bin';
  FsWriteString(Path, 'ABCDEFGHIJ');

  Reader := FsBufReader(Path);
  try
    Data := Reader.ReadBytes(5);
    AssertEquals('Should read 5 bytes', 5, Length(Data));
    AssertEquals(Ord('A'), Data[0]);
    AssertEquals(Ord('E'), Data[4]);

    Data := Reader.ReadBytes(5);
    AssertEquals('Should read 5 bytes', 5, Length(Data));
    AssertEquals(Ord('F'), Data[0]);
    AssertEquals(Ord('J'), Data[4]);

    Data := Reader.ReadBytes(5);
    AssertEquals('Should read 0 bytes at EOF', 0, Length(Data));
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadByte;
var
  Path: string;
  Reader: TFsBufReader;
begin
  Path := FTestDir + 'byte.bin';
  FsWriteString(Path, 'ABC');

  Reader := FsBufReader(Path);
  try
    AssertEquals(Ord('A'), Reader.ReadByte);
    AssertEquals(Ord('B'), Reader.ReadByte);
    AssertEquals(Ord('C'), Reader.ReadByte);
    AssertEquals('Should return -1 at EOF', -1, Reader.ReadByte);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_ReadAll;
var
  Path: string;
  Reader: TFsBufReader;
  Content: string;
begin
  Path := FTestDir + 'all.txt';
  FsWriteString(Path, 'Line1'#10'Line2'#10'Line3');

  Reader := FsBufReader(Path);
  try
    Content := Reader.ReadAllText;  // 使用 ReadAllText 返回字符串
    AssertEquals('Line1'#10'Line2'#10'Line3', Content);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_BufferSize;
var
  Path: string;
  Reader: TFsBufReader;
begin
  Path := FTestDir + 'buffer.txt';
  FsWriteString(Path, 'test');

  Reader := FsBufReader(Path, 4096);
  try
    AssertEquals('Buffer size should be 4096', 4096, Reader.BufferSize);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_BufReader_IsEof;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'eof.txt';
  FsWriteString(Path, 'test');

  Reader := FsBufReader(Path);
  try
    AssertFalse('Should not be EOF initially', Reader.IsEof);
    Reader.ReadLine(Line);
    AssertTrue('Should be EOF after reading all', Reader.IsEof);
  finally
    Reader.Free;
  end;
end;

// ============================================================================
// TFsBufWriter 测试
// ============================================================================

procedure TTestFsBufio.Test_BufWriter_WriteString;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'write_string.txt';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteString('Hello');
    Writer.WriteString(' World');
  finally
    Writer.Free;
  end;

  AssertEquals('Hello World', FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_WriteLn;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'write_ln.txt';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteLn('Line1');
    Writer.WriteLn('Line2');
    Writer.WriteLn;  // Empty line
  finally
    Writer.Free;
  end;

  AssertEquals('Line1'#10'Line2'#10#10, FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_WriteByte;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'write_byte.bin';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteByte(65);  // 'A'
    Writer.WriteByte(66);  // 'B'
    Writer.WriteByte(67);  // 'C'
  finally
    Writer.Free;
  end;

  AssertEquals('ABC', FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_WriteBytes;
var
  Path: string;
  Writer: TFsBufWriter;
  Data: TBytes;
begin
  Path := FTestDir + 'write_bytes.bin';
  SetLength(Data, 5);
  Data[0] := Ord('H');
  Data[1] := Ord('e');
  Data[2] := Ord('l');
  Data[3] := Ord('l');
  Data[4] := Ord('o');

  Writer := FsBufWriter(Path);
  try
    Writer.WriteBytes(Data);
  finally
    Writer.Free;
  end;

  AssertEquals('Hello', FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_Flush;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'flush.txt';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteString('Before flush');
    Writer.Flush;
    // 验证数据已写入
    AssertEquals('Before flush', FsReadToString(Path));
    Writer.WriteString(' After');
  finally
    Writer.Free;
  end;

  AssertEquals('Before flush After', FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_AutoFlushOnDestroy;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'auto_flush.txt';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteString('Auto flushed');
    // 不手动 Flush
  finally
    Writer.Free;
  end;

  AssertEquals('Auto flushed', FsReadToString(Path));
end;

procedure TTestFsBufio.Test_BufWriter_LargeWrite;
var
  Path: string;
  Writer: TFsBufWriter;
  Data: string;
  I: Integer;
begin
  Path := FTestDir + 'large.txt';

  // 创建大于缓冲区的数据
  Data := '';
  for I := 1 to 10000 do
    Data := Data + 'X';

  Writer := FsBufWriter(Path, 1024);  // 1KB 缓冲区
  try
    Writer.WriteString(Data);
  finally
    Writer.Free;
  end;

  AssertEquals(10000, Length(FsReadToString(Path)));
end;

// ============================================================================
// 便捷函数测试
// ============================================================================

procedure TTestFsBufio.Test_FsBufReader_Convenience;
var
  Path: string;
  Reader: TFsBufReader;
  Line: string;
begin
  Path := FTestDir + 'conv_reader.txt';
  FsWriteString(Path, 'Convenience test');

  Reader := FsBufReader(Path);
  try
    Reader.ReadLine(Line);
    AssertEquals('Convenience test', Line);
  finally
    Reader.Free;
  end;
end;

procedure TTestFsBufio.Test_FsBufWriter_Convenience;
var
  Path: string;
  Writer: TFsBufWriter;
begin
  Path := FTestDir + 'conv_writer.txt';

  Writer := FsBufWriter(Path);
  try
    Writer.WriteString('Convenience test');
  finally
    Writer.Free;
  end;

  AssertEquals('Convenience test', FsReadToString(Path));
end;

var
  GForEachLineResult: TStringList;

procedure TestLineCallback(const ALine: string);
begin
  GForEachLineResult.Add(ALine);
end;

procedure TTestFsBufio.Test_FsForEachLine;
var
  Path: string;
begin
  Path := FTestDir + 'foreach.txt';
  FsWriteString(Path, 'Line1'#10'Line2'#10'Line3');

  GForEachLineResult := TStringList.Create;
  try
    FsForEachLine(Path, @TestLineCallback);
    AssertEquals(3, GForEachLineResult.Count);
    AssertEquals('Line1', GForEachLineResult[0]);
    AssertEquals('Line2', GForEachLineResult[1]);
    AssertEquals('Line3', GForEachLineResult[2]);
  finally
    GForEachLineResult.Free;
  end;
end;

// ============================================================================
// 集成测试
// ============================================================================

procedure TTestFsBufio.Test_RoundTrip_TextFile;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  Line: string;
  Lines: TStringList;
begin
  Path := FTestDir + 'roundtrip.txt';

  // 写入
  Writer := FsBufWriter(Path);
  try
    Writer.WriteLn('First line');
    Writer.WriteLn('Second line');
    Writer.WriteLn('Third line');
  finally
    Writer.Free;
  end;

  // 读取并验证
  Lines := TStringList.Create;
  Reader := FsBufReader(Path);
  try
    while Reader.ReadLine(Line) do
      Lines.Add(Line);

    AssertEquals(3, Lines.Count);
    AssertEquals('First line', Lines[0]);
    AssertEquals('Second line', Lines[1]);
    AssertEquals('Third line', Lines[2]);
  finally
    Reader.Free;
    Lines.Free;
  end;
end;

procedure TTestFsBufio.Test_RoundTrip_BinaryData;
var
  Path: string;
  Writer: TFsBufWriter;
  Reader: TFsBufReader;
  WriteData, ReadData: TBytes;
  I: Integer;
begin
  Path := FTestDir + 'roundtrip.bin';

  // 创建二进制数据
  SetLength(WriteData, 256);
  for I := 0 to 255 do
    WriteData[I] := I;

  // 写入
  Writer := FsBufWriter(Path);
  try
    Writer.WriteBytes(WriteData);
  finally
    Writer.Free;
  end;

  // 读取并验证
  Reader := FsBufReader(Path);
  try
    ReadData := Reader.ReadBytes(256);
    AssertEquals(256, Length(ReadData));
    for I := 0 to 255 do
      AssertEquals(I, ReadData[I]);
  finally
    Reader.Free;
  end;
end;

initialization
  RegisterTest(TTestFsBufio);

end.
