{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_traits;

{$mode objfpc}{$H+}

{!
  fafafa.core.fs.traits 测试用例

  测试 IFsRead, IFsWrite, IFsSeek 接口的正确性
}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs.traits,
  fafafa.core.fs.fileobj,
  fafafa.core.fs.bufio,
  fafafa.core.fs.std;

type
  // ============================================================================
  // 接口测试：IFsRead
  // ============================================================================
  TTestFsTraitsRead = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFile 作为 IFsRead
    procedure Test_TFile_AsIFsRead;
    procedure Test_TFile_IFsRead_ReadBytes;
    procedure Test_TFile_IFsRead_ReadAll;
    procedure Test_TFile_IFsRead_ReadString;

    // TFsBufReader 作为 IFsRead
    procedure Test_TFsBufReader_AsIFsRead;
    procedure Test_TFsBufReader_AsIFsBufRead;

    // 接口多态性
    procedure Test_Polymorphism_ReadFromAny;
  end;

  // ============================================================================
  // 接口测试：IFsWrite
  // ============================================================================
  TTestFsTraitsWrite = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFile 作为 IFsWrite
    procedure Test_TFile_AsIFsWrite;
    procedure Test_TFile_IFsWrite_WriteBytes;
    procedure Test_TFile_IFsWrite_WriteString;
    procedure Test_TFile_IFsWrite_Flush;

    // TFsBufWriter 作为 IFsWrite
    procedure Test_TFsBufWriter_AsIFsWrite;

    // 接口多态性
    procedure Test_Polymorphism_WriteToAny;
  end;

  // ============================================================================
  // 接口测试：IFsSeek
  // ============================================================================
  TTestFsTraitsSeek = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFile 作为 IFsSeek
    procedure Test_TFile_AsIFsSeek;
    procedure Test_TFile_IFsSeek_Position;
    procedure Test_TFile_IFsSeek_Rewind;
    procedure Test_TFile_IFsSeek_SeekEnd;
  end;

  // ============================================================================
  // 接口测试：IFsReadWrite
  // ============================================================================
  TTestFsTraitsReadWrite = class(TTestCase)
  private
    FTestDir: string;
    procedure SetUpTestDir;
    procedure TearDownTestDir;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // TFile 作为 IFsReadWrite
    procedure Test_TFile_AsIFsReadWrite;
    procedure Test_TFile_IFsReadWrite_ReadWrite;
  end;

implementation

// ============================================================================
// TTestFsTraitsRead
// ============================================================================

procedure TTestFsTraitsRead.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_traits_read_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsTraitsRead.TearDownTestDir;
var
  SR: TSearchRec;
begin
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

procedure TTestFsTraitsRead.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsTraitsRead.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsTraitsRead.Test_TFile_AsIFsRead;
var
  F: TFile;
  R: IFsRead;
  Path: string;
  Buf: array[0..9] of Byte;
  N: Integer;
begin
  Path := FTestDir + 'read_test.txt';
  FsWriteString(Path, 'Hello');

  F := TFile.Open(Path);
  try
    // TFile 可以赋值给 IFsRead
    AssertTrue('TFile should implement IFsRead', Supports(F, IFsRead, R));

    N := R.Read(Buf, 5);
    AssertEquals('Should read 5 bytes', 5, N);
    AssertEquals('H', Chr(Buf[0]));
    AssertEquals('o', Chr(Buf[4]));
  finally
    R := nil;  // 必须先释放接口引用
    F.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_TFile_IFsRead_ReadBytes;
var
  F: TFile;
  R: IFsRead;
  Path: string;
  Data: TBytes;
begin
  Path := FTestDir + 'readbytes_test.txt';
  FsWriteString(Path, 'Test Data');

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsRead', Supports(F, IFsRead, R));
    Data := R.ReadBytes(4);
    AssertEquals(4, Length(Data));
    AssertEquals(Ord('T'), Data[0]);
    AssertEquals(Ord('e'), Data[1]);
  finally
    R := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_TFile_IFsRead_ReadAll;
var
  F: TFile;
  R: IFsRead;
  Path: string;
  Data: TBytes;
begin
  Path := FTestDir + 'readall_test.txt';
  FsWriteString(Path, 'All Content');

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsRead', Supports(F, IFsRead, R));
    Data := R.ReadAll;
    AssertEquals(11, Length(Data));
  finally
    R := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_TFile_IFsRead_ReadString;
var
  F: TFile;
  R: IFsRead;
  Path: string;
  S: string;
begin
  Path := FTestDir + 'readstring_test.txt';
  FsWriteString(Path, 'String Content');

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsRead', Supports(F, IFsRead, R));
    S := R.ReadString;
    AssertEquals('String Content', S);
  finally
    R := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_TFsBufReader_AsIFsRead;
var
  Reader: TFsBufReader;
  R: IFsRead;
  Path: string;
  Data: TBytes;
begin
  Path := FTestDir + 'bufreader_test.txt';
  FsWriteString(Path, 'Buffered Read');

  Reader := FsBufReader(Path);
  try
    // TFsBufReader 可以赋值给 IFsRead
    AssertTrue('TFsBufReader should implement IFsRead', Supports(Reader, IFsRead, R));

    Data := R.ReadBytes(8);
    AssertEquals(8, Length(Data));
  finally
    R := nil;
    Reader.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_TFsBufReader_AsIFsBufRead;
var
  Reader: TFsBufReader;
  BR: IFsBufRead;
  Path: string;
  Line: string;
begin
  Path := FTestDir + 'bufread_test.txt';
  FsWriteString(Path, 'Line1'#10'Line2');

  Reader := FsBufReader(Path);
  try
    // TFsBufReader 可以赋值给 IFsBufRead
    AssertTrue('TFsBufReader should implement IFsBufRead', Supports(Reader, IFsBufRead, BR));

    AssertTrue('Should read first line', BR.ReadLine(Line));
    AssertEquals('Line1', Line);
    AssertFalse('Should not be EOF yet', BR.IsEof);
  finally
    BR := nil;
    Reader.Free;
  end;
end;

procedure TTestFsTraitsRead.Test_Polymorphism_ReadFromAny;
  // 通用读取函数，接受任意 IFsRead 实现
  function ReadFirstByte(AReader: IFsRead): Byte;
  var
    B: Byte;
  begin
    AReader.Read(B, 1);
    Result := B;
  end;

var
  F: TFile;
  Reader: TFsBufReader;
  R: IFsRead;
  Path1, Path2: string;
  B: Byte;
begin
  Path1 := FTestDir + 'poly1.txt';
  Path2 := FTestDir + 'poly2.txt';
  FsWriteString(Path1, 'A');
  FsWriteString(Path2, 'B');

  // 使用 TFile
  F := TFile.Open(Path1);
  try
    AssertTrue('TFile should implement IFsRead', Supports(F, IFsRead, R));
    B := ReadFirstByte(R);
    AssertEquals(Ord('A'), B);
  finally
    R := nil;
    F.Free;
  end;

  // 使用 TFsBufReader
  Reader := FsBufReader(Path2);
  try
    AssertTrue('TFsBufReader should implement IFsRead', Supports(Reader, IFsRead, R));
    B := ReadFirstByte(R);
    AssertEquals(Ord('B'), B);
  finally
    R := nil;
    Reader.Free;
  end;
end;

// ============================================================================
// TTestFsTraitsWrite
// ============================================================================

procedure TTestFsTraitsWrite.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_traits_write_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsTraitsWrite.TearDownTestDir;
var
  SR: TSearchRec;
begin
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

procedure TTestFsTraitsWrite.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsTraitsWrite.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsTraitsWrite.Test_TFile_AsIFsWrite;
var
  F: TFile;
  W: IFsWrite;
  Path: string;
  Buf: array[0..4] of AnsiChar;
  N: Integer;
begin
  Path := FTestDir + 'write_test.txt';
  Buf := 'Hello';

  F := TFile.Create_(Path);
  try
    // TFile 可以赋值给 IFsWrite
    AssertTrue('TFile should implement IFsWrite', Supports(F, IFsWrite, W));

    N := W.Write(Buf, 5);
    AssertEquals('Should write 5 bytes', 5, N);
  finally
    W := nil;
    F.Free;
  end;

  AssertEquals('Hello', FsReadToString(Path));
end;

procedure TTestFsTraitsWrite.Test_TFile_IFsWrite_WriteBytes;
var
  F: TFile;
  W: IFsWrite;
  Path: string;
  Data: TBytes;
begin
  Path := FTestDir + 'writebytes_test.txt';
  SetLength(Data, 4);
  Data[0] := Ord('T');
  Data[1] := Ord('e');
  Data[2] := Ord('s');
  Data[3] := Ord('t');

  F := TFile.Create_(Path);
  try
    AssertTrue('TFile should implement IFsWrite', Supports(F, IFsWrite, W));
    W.WriteBytes(Data);
  finally
    W := nil;
    F.Free;
  end;

  AssertEquals('Test', FsReadToString(Path));
end;

procedure TTestFsTraitsWrite.Test_TFile_IFsWrite_WriteString;
var
  F: TFile;
  W: IFsWrite;
  Path: string;
begin
  Path := FTestDir + 'writestring_test.txt';

  F := TFile.Create_(Path);
  try
    AssertTrue('TFile should implement IFsWrite', Supports(F, IFsWrite, W));
    W.WriteString('Hello World');
  finally
    W := nil;
    F.Free;
  end;

  AssertEquals('Hello World', FsReadToString(Path));
end;

procedure TTestFsTraitsWrite.Test_TFile_IFsWrite_Flush;
var
  F: TFile;
  W: IFsWrite;
  Path: string;
begin
  Path := FTestDir + 'flush_test.txt';

  F := TFile.Create_(Path);
  try
    AssertTrue('TFile should implement IFsWrite', Supports(F, IFsWrite, W));
    W.WriteString('Flushed');
    W.Flush;  // 应该不抛异常
  finally
    W := nil;
    F.Free;
  end;

  AssertEquals('Flushed', FsReadToString(Path));
end;

procedure TTestFsTraitsWrite.Test_TFsBufWriter_AsIFsWrite;
var
  Writer: TFsBufWriter;
  W: IFsWrite;
  Path: string;
begin
  Path := FTestDir + 'bufwriter_test.txt';

  Writer := FsBufWriter(Path);
  try
    // TFsBufWriter 可以赋值给 IFsWrite
    AssertTrue('TFsBufWriter should implement IFsWrite', Supports(Writer, IFsWrite, W));

    W.WriteString('Buffered Write');
  finally
    W := nil;
    Writer.Free;
  end;

  AssertEquals('Buffered Write', FsReadToString(Path));
end;

procedure TTestFsTraitsWrite.Test_Polymorphism_WriteToAny;
  // 通用写入函数，接受任意 IFsWrite 实现
  procedure WriteHello(AWriter: IFsWrite);
  begin
    AWriter.WriteString('Hello');
  end;

var
  F: TFile;
  Writer: TFsBufWriter;
  W: IFsWrite;
  Path1, Path2: string;
begin
  Path1 := FTestDir + 'poly_write1.txt';
  Path2 := FTestDir + 'poly_write2.txt';

  // 使用 TFile
  F := TFile.Create_(Path1);
  try
    AssertTrue('TFile should implement IFsWrite', Supports(F, IFsWrite, W));
    WriteHello(W);
  finally
    W := nil;
    F.Free;
  end;
  AssertEquals('Hello', FsReadToString(Path1));

  // 使用 TFsBufWriter
  Writer := FsBufWriter(Path2);
  try
    AssertTrue('TFsBufWriter should implement IFsWrite', Supports(Writer, IFsWrite, W));
    WriteHello(W);
  finally
    W := nil;
    Writer.Free;
  end;
  AssertEquals('Hello', FsReadToString(Path2));
end;

// ============================================================================
// TTestFsTraitsSeek
// ============================================================================

procedure TTestFsTraitsSeek.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_traits_seek_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsTraitsSeek.TearDownTestDir;
var
  SR: TSearchRec;
begin
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

procedure TTestFsTraitsSeek.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsTraitsSeek.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsTraitsSeek.Test_TFile_AsIFsSeek;
var
  F: TFile;
  S: IFsSeek;
  Path: string;
begin
  Path := FTestDir + 'seek_test.txt';
  FsWriteString(Path, '0123456789');

  F := TFile.Open(Path);
  try
    // TFile 可以赋值给 IFsSeek
    AssertTrue('TFile should implement IFsSeek', Supports(F, IFsSeek, S));

    AssertEquals(10, S.Size);
    AssertEquals(0, S.Position);

    S.Seek(5, FS_SEEK_SET);
    AssertEquals(5, S.Position);
  finally
    S := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsSeek.Test_TFile_IFsSeek_Position;
var
  F: TFile;
  S: IFsSeek;
  Path: string;
begin
  Path := FTestDir + 'position_test.txt';
  FsWriteString(Path, 'Position Test');

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsSeek', Supports(F, IFsSeek, S));

    AssertEquals('Initial position should be 0', 0, S.Position);

    S.Seek(5, FS_SEEK_SET);
    AssertEquals('Position after seek', 5, S.Position);

    S.Seek(3, FS_SEEK_CUR);
    AssertEquals('Position after relative seek', 8, S.Position);
  finally
    S := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsSeek.Test_TFile_IFsSeek_Rewind;
var
  F: TFile;
  S: IFsSeek;
  Path: string;
begin
  Path := FTestDir + 'rewind_test.txt';
  FsWriteString(Path, 'Rewind Test');

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsSeek', Supports(F, IFsSeek, S));

    S.Seek(5, FS_SEEK_SET);
    AssertEquals(5, S.Position);

    S.Rewind;
    AssertEquals('Position after rewind should be 0', 0, S.Position);
  finally
    S := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsSeek.Test_TFile_IFsSeek_SeekEnd;
var
  F: TFile;
  S: IFsSeek;
  Path: string;
  EndPos: Int64;
begin
  Path := FTestDir + 'seekend_test.txt';
  FsWriteString(Path, '12345');  // 5 bytes

  F := TFile.Open(Path);
  try
    AssertTrue('TFile should implement IFsSeek', Supports(F, IFsSeek, S));

    EndPos := S.SeekEnd;
    AssertEquals('SeekEnd should return file size', 5, EndPos);
    AssertEquals('Position should be at end', 5, S.Position);
  finally
    S := nil;
    F.Free;
  end;
end;

// ============================================================================
// TTestFsTraitsReadWrite
// ============================================================================

procedure TTestFsTraitsReadWrite.SetUpTestDir;
begin
  FTestDir := GetTempDir(False) + 'fafafa_test_traits_rw_' + IntToStr(GetProcessID) + PathDelim;
  if not DirectoryExists(FTestDir) then
    CreateDir(FTestDir);
end;

procedure TTestFsTraitsReadWrite.TearDownTestDir;
var
  SR: TSearchRec;
begin
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

procedure TTestFsTraitsReadWrite.SetUp;
begin
  SetUpTestDir;
end;

procedure TTestFsTraitsReadWrite.TearDown;
begin
  TearDownTestDir;
end;

procedure TTestFsTraitsReadWrite.Test_TFile_AsIFsReadWrite;
var
  F: TFile;
  RW: IFsReadWrite;
  Path: string;
begin
  Path := FTestDir + 'readwrite_test.txt';
  FsWriteString(Path, 'Initial');

  F := TFile.OpenReadWrite(Path);
  try
    // TFile 可以赋值给 IFsReadWrite
    AssertTrue('TFile should implement IFsReadWrite', Supports(F, IFsReadWrite, RW));
  finally
    RW := nil;
    F.Free;
  end;
end;

procedure TTestFsTraitsReadWrite.Test_TFile_IFsReadWrite_ReadWrite;
var
  F: TFile;
  RW: IFsReadWrite;
  Path: string;
  Data: TBytes;
begin
  Path := FTestDir + 'rw_test.txt';
  FsWriteString(Path, 'AAAA');

  F := TFile.OpenReadWrite(Path);
  try
    AssertTrue('TFile should implement IFsReadWrite', Supports(F, IFsReadWrite, RW));

    // 读取
    Data := RW.ReadBytes(2);
    AssertEquals(2, Length(Data));
    AssertEquals(Ord('A'), Data[0]);

    // 定位到开头
    RW.Rewind;

    // 写入
    RW.WriteString('BB');

    // 验证
    RW.Rewind;
    Data := RW.ReadAll;
    AssertEquals(4, Length(Data));
    // 前两个字节被覆盖
    AssertEquals(Ord('B'), Data[0]);
    AssertEquals(Ord('B'), Data[1]);
    AssertEquals(Ord('A'), Data[2]);
    AssertEquals(Ord('A'), Data[3]);
  finally
    RW := nil;
    F.Free;
  end;
end;

initialization
  RegisterTest(TTestFsTraitsRead);
  RegisterTest(TTestFsTraitsWrite);
  RegisterTest(TTestFsTraitsSeek);
  RegisterTest(TTestFsTraitsReadWrite);

end.
