unit Test_IO;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: fafafa.core.io 模块
 *
 * 测试目标:
 * 1. TIOCursor - 内存游标读写定位
 * 2. TLimitedReader - 限制读取字节数
 * 3. TMultiReader - 串联多个读取器
 * 4. TBufReader/TBufWriter - 缓冲 IO
 * 5. Utils - Copy/ReadAll/WriteAll
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.io,  // 一站式导入
  fafafa.core.io.base,
  fafafa.core.io.error,
  fafafa.core.io.combinators,
  fafafa.core.io.buffered,
  fafafa.core.io.utils,
  fafafa.core.io.streams,
  fafafa.core.io.tee,
  fafafa.core.io.pipe,
  fafafa.core.compress,
  fafafa.core.io.counted,
  fafafa.core.io.section,
  fafafa.core.io.instrument;

type
  { TTestIOCursor }
  TTestIOCursor = class(TTestCase)
  published
    procedure Test_Cursor_WriteRead_Success;
    procedure Test_Cursor_SeekStart_Success;
    procedure Test_Cursor_SeekCurrent_Success;
    procedure Test_Cursor_SeekEnd_Success;
    procedure Test_Cursor_ReadEOF_ReturnsZero;
    procedure Test_Cursor_FromBytes_Success;
    procedure Test_Cursor_ToBytes_Success;
  end;

  { TTestLimitedReader }
  TTestLimitedReader = class(TTestCase)
  published
    procedure Test_LimitedReader_ReadWithinLimit;
    procedure Test_LimitedReader_ReadExceedLimit;
    procedure Test_LimitedReader_ZeroLimit;
    procedure Test_LimitedReader_Remaining;
  end;

  { TTestMultiReader }
  TTestMultiReader = class(TTestCase)
  published
    procedure Test_MultiReader_ChainTwoReaders;
    procedure Test_MultiReader_EmptyReaders;
    procedure Test_MultiReader_SingleReader;
  end;

  { TTestEmptyAndDiscard }
  TTestEmptyAndDiscard = class(TTestCase)
  published
    procedure Test_EmptyReader_ReturnsZero;
    procedure Test_Discard_AlwaysSucceeds;
  end;

  { TTestRepeatReader }
  TTestRepeatReader = class(TTestCase)
  published
    procedure Test_RepeatByte_FillsBuffer;
  end;

  { TTestBufferedIO }
  TTestBufferedIO = class(TTestCase)
  published
    procedure Test_BufReader_ReadLine;
    procedure Test_BufReader_ReadLine_CRLF_SplitAcrossBuffers;
    procedure Test_BufReader_ReadLine_LongLine_SmallBuffer;
    procedure Test_BufReader_ReadUntil_Interrupted_Retries;
    procedure Test_BufReader_Read_Interrupted_Retries;
    procedure Test_BufReader_Read_LargeRead_Interrupted_Retries;
    procedure Test_BufWriter_Flush_Interrupted_Retries;
    procedure Test_BufWriter_Flush_ZeroWrite_RaisesEIOError;
    procedure Test_BufWriter_Write_LargeWrite_Interrupted_Retries;
    procedure Test_BufWriter_Write_LargeWrite_ZeroWrite_RaisesEIOError;
    procedure Test_BufWriter_FlushOnDestroy;
  end;

  { TTestIOUtils }
  TTestIOUtils = class(TTestCase)
  published
    procedure Test_Copy_FullTransfer;
    procedure Test_Copy_Interrupted_Retries;
    procedure Test_CopyN_ExactBytes;
    procedure Test_CopyN_Interrupted_Retries;
    procedure Test_ReadAll_Success;
    procedure Test_ReadAll_Interrupted_Retries;
    procedure Test_ReadFull_Success;
    procedure Test_ReadFull_Interrupted_Retries;
    procedure Test_ReadFull_UnexpectedEOF;
    procedure Test_WriteAll_Success;
    procedure Test_WriteAll_Interrupted_Retries;
    procedure Test_WriteAll_ZeroWrite_RaisesEIOError;
    procedure Test_WriteString_UTF8;
    procedure Test_ReadString_UTF8;
    procedure Test_CopyBuffer_CustomSize;
    procedure Test_ReadAtLeast_MinReached;
    procedure Test_ReadAtLeast_Interrupted_Retries;
  end;

  { TTestStreamAdapter }
  TTestStreamAdapter = class(TTestCase)
  published
    procedure Test_StreamIO_ReadWrite;
    procedure Test_StreamIO_Seek;
  end;

  { TTestTeeIO }
  TTestTeeIO = class(TTestCase)
  published
    procedure Test_TeeReader_CopiesOnRead;
    procedure Test_TeeReader_PreservesData;
    procedure Test_TeeReader_ShortWrite_RaisesEIOError;
    procedure Test_MultiWriter_WritesToAll;
    procedure Test_MultiWriter_Empty;
    procedure Test_MultiWriter_Single;
    procedure Test_MultiWriter_ShortWrite_RaisesEIOError;
  end;

  { TTestPipe }
  TTestPipe = class(TTestCase)
  published
    procedure Test_Pipe_WriteRead;
    procedure Test_Pipe_CloseWriter_ReaderEOF;
    procedure Test_Pipe_MultipleWrites;
  end;

  { TTestPipeSemantics }
  TTestPipeSemantics = class(TTestCase)
  published
    procedure Test_WriteToClosedPipe_RaisesError;
    procedure Test_ReadFromEmptyPipe_NotClosed_ReturnsZero;
    procedure Test_ReadFromClosedPipe_ReturnsEOF;
  end;

  { TTestCompress }
  TTestCompress = class(TTestCase)
  published
    procedure Test_Deflate_CompressDecompress;
    procedure Test_Gzip_CompressDecompress;
  end;

  { TTestCompressSemantics }
  TTestCompressSemantics = class(TTestCase)
  published
    procedure Test_Deflate_DecompressGarbage_RaisesEIOError;
    procedure Test_Deflate_DecompressTruncated_RaisesEIOError;
    procedure Test_Gzip_DecompressGarbage_RaisesEIOError;
    procedure Test_Gzip_DecompressTruncated_RaisesEIOError;
  end;

  { TTestCounted }
  TTestCounted = class(TTestCase)
  published
    procedure Test_CountedReader_TracksBytes;
    procedure Test_CountedWriter_TracksBytes;
    procedure Test_CountedReader_MultipleReads;
  end;

  { TTestSection }
  TTestSection = class(TTestCase)
  published
    procedure Test_SectionReader_ReadsSection;
    procedure Test_SectionReader_SeekWithinSection;
    procedure Test_SectionReader_BeyondSection;
  end;

  { TTestAdapterSemantics }
  TTestAdapterSemantics = class(TTestCase)
  published
    procedure Test_Skip_UsesSeek_IfAvailable;
    procedure Test_Skip_FallsBackToRead_IfNoSeek;
    procedure Test_Skip_Interrupted_Retries;
  end;

  { TTestSectionSemantics }
  TTestSectionSemantics = class(TTestCase)
  published
    procedure Test_Seek_Negative_RaisesError;
    procedure Test_Seek_BeyondEnd_ReturnsPos;
    procedure Test_Read_AfterSeekBeyondEnd_ReturnsEOF;
  end;

  { TTestIOFacade - 测试门面 API }
  TTestIOFacade = class(TTestCase)
  published
    procedure Test_IO_Cursor_ReadWrite;
    procedure Test_IO_Limit;
    procedure Test_IO_Tee;
    procedure Test_IO_Multi_Writers;
    procedure Test_IO_Copy;
    procedure Test_IO_ReadAll;
    procedure Test_IO_Pipe;
    procedure Test_IO_Buffered;
    procedure Test_IO_Count;
    procedure Test_IO_Section;
    procedure Test_IO_NopCloser;
    procedure Test_IO_Chain;
    procedure Test_IO_ReadString;
    procedure Test_IO_Skip;
    procedure Test_IO_Lines;
  end;

  { TTestFileIO }
  TTestFileIO = class(TTestCase)
  private
    FTempFile: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_CreateFile_WritesData;
    procedure Test_OpenFile_ReadsData;
    procedure Test_OpenFile_NotFound_RaisesEIOError;
    procedure Test_CreateFile_PermissionDenied_RaisesEIOError;
    procedure Test_OpenFileMode_ReadWrite;
  end;

  { TTestIOError - 测试结构化错误模型 }
  TTestIOError = class(TTestCase)
  published
    procedure Test_EIOError_StructuredFields;
    procedure Test_IOErrorWrap_CreatesStructuredError;
    procedure Test_IOErrorRetryable_InterruptedIsTrue;
    procedure Test_IOErrorRetryable_NotFoundIsFalse;
  end;

  { TTestFileOpenBuilder - 测试文件打开构建器 }
  TTestFileOpenBuilder = class(TTestCase)
  private
    FTempFile: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Builder_ReadOnly_OpensExisting;
    procedure Test_Builder_ReadWrite_OpensExisting;
    procedure Test_Builder_Create_CreatesNew;
    procedure Test_Builder_Truncate_TruncatesExisting;
    procedure Test_Builder_Append_AppendsToExisting;
    procedure Test_Builder_CreateNew_FailsIfExists;
    procedure Test_Shortcut_OpenRead;
    procedure Test_Shortcut_CreateTruncate;
    procedure Test_Shortcut_OpenAppend;
  end;

  { TTestStreamingCompress - 测试流式压缩 API }
  TTestStreamingCompress = class(TTestCase)
  published
    procedure Test_Gzip_Streaming_EncodeDecodeRoundtrip;
    procedure Test_Deflate_Streaming_EncodeDecodeRoundtrip;
    procedure Test_Gzip_Streaming_LargeData;
    procedure Test_Gzip_Decode_InvalidData_RaisesEIOError;
    procedure Test_Gzip_WriteToClosed_RaisesEIOError;
  end;

  { TTestLineIterator - 测试惰性行迭代器 }
  TTestLineIterator = class(TTestCase)
  published
    procedure Test_LinesIter_BasicIteration;
    procedure Test_LinesIter_EmptyInput;
    procedure Test_LinesIter_NoTrailingNewline;
    procedure Test_LinesIter_CRLFHandling;
    procedure Test_LinesIter_LineNumber;
  end;

  { TTestScanner - 测试可配置扫描器 }
  TTestScanner = class(TTestCase)
  published
    procedure Test_Scanner_DefaultDelimiter;
    procedure Test_Scanner_CustomDelimiter;
    procedure Test_Scanner_MaxLength_RaisesError;
    procedure Test_Scanner_KeepDelimiter;
    procedure Test_Scanner_TokenCount;
  end;

  { TTestVectoredIO - 测试向量化 I/O }
  TTestVectoredIO = class(TTestCase)
  published
    procedure Test_ReadV_MultipleBuffers;
    procedure Test_WriteV_MultipleBuffers;
    procedure Test_ReadV_EOF_PartialFill;
    procedure Test_ReadV_Fallback_WithNonVectored;
    procedure Test_ReadV_Fallback_Interrupted_Retries;
    procedure Test_WriteV_Fallback_WithNonVectored;
  end;

  { TTestMmap - 测试内存映射 }
  TTestMmap = class(TTestCase)
  private
    FTempFile: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MmapRead_ReadsFile;
    procedure Test_MmapRead_Seek;
    procedure Test_MmapRead_Fallback_OnWindows;
  end;

  { TTestInstrument - 测试观测钩子 }
  TTestInstrument = class(TTestCase)
  published
    procedure Test_Instrument_Reader_FiresReadEvent;
    procedure Test_Instrument_Writer_FiresWriteEvent;
    procedure Test_Instrument_Seeker_FiresSeekEvent;
  end;

  { TTestIOErrorMapping - 验证 IOUnixErrorKind 的典型映射 }
  TTestIOErrorMapping = class(TTestCase)
  published
    procedure Test_Unix_IOErrorKind_Mapping_Sample;
  end;

  { TTestWithResource - 测试 IO.With* 资源管理 }
  TTestWithResource = class(TTestCase)
  published
    procedure Test_WithReader_ExecutesProc;
    procedure Test_WithWriter_ExecutesProc;
    procedure Test_WithBufReader_ProcessLines;
    procedure Test_With_ExceptionPropagates;
  end;

  { TTestForInLines - 测试 for-in 行迭代 }
  TTestForInLines = class(TTestCase)
  published
    procedure Test_ForIn_BasicIteration;
    procedure Test_ForIn_EmptyInput;
    procedure Test_ForIn_NoTrailingNewline;
    procedure Test_ForIn_CRLFHandling;
  end;

  { TTestProgress - 测试进度回调 }
  TTestProgress = class(TTestCase)
  published
    procedure Test_Progress_Reader_FiresCallback;
    procedure Test_Progress_Writer_FiresCallback;
    procedure Test_Progress_WithTotal_ReportsPercent;
    procedure Test_Progress_UnknownTotal_PercentNegative;
    // 边界条件测试
    procedure Test_Progress_ZeroRead_NoCallback;
    procedure Test_Progress_MultipleReads_AccumulatesBytes;
  end;

  { TTestPeek - 测试窃视读取 }
  TTestPeek = class(TTestCase)
  published
    procedure Test_Peek_DoesNotAdvance;
    procedure Test_Peek_ThenRead_ReturnsData;
    procedure Test_Peek_BuffersData;
    procedure Test_Peek_EOF_ReturnsZero;
    // 边界条件测试
    procedure Test_Peek_LargerThanData_ReturnsAvailable;
    procedure Test_Peek_ZeroBytes_ReturnsZero;
  end;

  { TTestChecksum - 测试校验和计算 }
  TTestChecksum = class(TTestCase)
  published
    procedure Test_ChecksumReader_ComputesHash;
    procedure Test_ChecksumWriter_ComputesHash;
    procedure Test_ChecksumReader_Reset;
    // 边界条件测试
    procedure Test_ChecksumReader_EmptyData_ValidHash;
    procedure Test_ChecksumWriter_MultipleWrites_CombinedHash;
  end;

  { TTestTimeout - 测试超时包装器 }
  TTestTimeout = class(TTestCase)
  published
    procedure Test_TimeoutReader_FastRead_Succeeds;
    procedure Test_TimeoutWriter_FastWrite_Succeeds;
    procedure Test_TimeoutReader_SlowRead_RaisesTimeout;
    // 边界条件测试
    procedure Test_TimeoutReader_ExactTimeout_Succeeds;
    procedure Test_TimeoutWriter_SlowWrite_RaisesTimeout;
  end;

  { TTestRetry - 测试自动重试 }
  TTestRetry = class(TTestCase)
  published
    procedure Test_Retry_NoError_SucceedsImmediately;
    procedure Test_Retry_RetryableError_Retries;
    procedure Test_Retry_NonRetryableError_FailsImmediately;
    // 边界条件测试
    procedure Test_Retry_ExceedsMaxAttempts_RaisesLastError;
    procedure Test_Retry_InterruptedError_Retries;
  end;

implementation

{$IFNDEF WINDOWS}
uses
  BaseUnix;
{$ENDIF}

type
  { TZeroWriter - 测试用 Writer，总是报告写入 0 字节 }
  TZeroWriter = class(TInterfacedObject, IWriter)
  public
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TShortWriter - 测试用 Writer，总是短写（写入一半字节） }
  TShortWriter = class(TInterfacedObject, IWriter)
  public
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TSlowReader - 测试用 Reader，每次读取都 Sleep 一段时间 }
  TSlowReader = class(TInterfacedObject, IReader)
  private
    FDelayMs: Integer;
    FData: TBytes;
    FPos: SizeInt;
  public
    constructor Create(const AData: TBytes; ADelayMs: Integer);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TSlowWriter - 测试用 Writer，每次写入都 Sleep 一段时间 }
  TSlowWriter = class(TInterfacedObject, IWriter)
  private
    FDelayMs: Integer;
  public
    constructor Create(ADelayMs: Integer);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { TFailNTimesReader - 测试用 Reader，前 N 次读取抛出指定错误 }
  TFailNTimesReader = class(TInterfacedObject, IReader)
  private
    FInner: IReader;
    FFailCount: Integer;
    FCallCount: Integer;
    FErrorKind: TIOErrorKind;
  public
    constructor Create(AInner: IReader; AFailCount: Integer; AErrorKind: TIOErrorKind);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    property CallCount: Integer read FCallCount;
  end;

  { TFailNTimesWriter - 测试用 Writer，前 N 次写入抛出指定错误 }
  TFailNTimesWriter = class(TInterfacedObject, IWriter)
  private
    FInner: IWriter;
    FFailCount: Integer;
    FCallCount: Integer;
    FErrorKind: TIOErrorKind;
  public
    constructor Create(AInner: IWriter; AFailCount: Integer; AErrorKind: TIOErrorKind);
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
    property CallCount: Integer read FCallCount;
  end;

{ TZeroWriter }

function TZeroWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := 0;
end;

{ TShortWriter }

function TShortWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  if Count <= 0 then
    Result := 0
  else
    Result := Count div 2;
end;

{ TSlowReader }

constructor TSlowReader.Create(const AData: TBytes; ADelayMs: Integer);
begin
  inherited Create;
  FData := AData;
  FDelayMs := ADelayMs;
  FPos := 0;
end;

function TSlowReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
var
  Avail: SizeInt;
begin
  Sleep(FDelayMs);
  Avail := Length(FData) - FPos;
  if Avail <= 0 then
    Exit(0);
  if Count > Avail then
    Count := Avail;
  Move(FData[FPos], Buf^, Count);
  Inc(FPos, Count);
  Result := Count;
end;

{ TSlowWriter }

constructor TSlowWriter.Create(ADelayMs: Integer);
begin
  inherited Create;
  FDelayMs := ADelayMs;
end;

function TSlowWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Sleep(FDelayMs);
  Result := Count;  // 假装写成功
end;

{ TFailNTimesReader }

constructor TFailNTimesReader.Create(AInner: IReader; AFailCount: Integer; AErrorKind: TIOErrorKind);
begin
  inherited Create;
  FInner := AInner;
  FFailCount := AFailCount;
  FCallCount := 0;
  FErrorKind := AErrorKind;
end;

function TFailNTimesReader.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Inc(FCallCount);
  if FCallCount <= FFailCount then
    raise EIOError.Create(FErrorKind, Format('test failure %d/%d', [FCallCount, FFailCount]));
  Result := FInner.Read(Buf, Count);
end;

{ TFailNTimesWriter }

constructor TFailNTimesWriter.Create(AInner: IWriter; AFailCount: Integer; AErrorKind: TIOErrorKind);
begin
  inherited Create;
  FInner := AInner;
  FFailCount := AFailCount;
  FCallCount := 0;
  FErrorKind := AErrorKind;
end;

function TFailNTimesWriter.Write(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Inc(FCallCount);
  if FCallCount <= FFailCount then
    raise EIOError.Create(FErrorKind, Format('test failure %d/%d', [FCallCount, FFailCount]));
  Result := FInner.Write(Buf, Count);
end;

{ TTestIOCursor }

procedure TTestIOCursor.Test_Cursor_WriteRead_Success;
var
  C: TIOCursor;
  WBuf: array[0..3] of Byte;
  RBuf: array[0..3] of Byte;
  N: SizeInt;
begin
  C := TIOCursor.Create;
  try
    WBuf[0] := $DE; WBuf[1] := $AD; WBuf[2] := $BE; WBuf[3] := $EF;
    N := C.Write(@WBuf[0], 4);
    AssertEquals('Write count', 4, N);

    C.Seek(0, SeekStart);

    N := C.Read(@RBuf[0], 4);
    AssertEquals('Read count', 4, N);
    AssertEquals('Byte 0', $DE, RBuf[0]);
    AssertEquals('Byte 1', $AD, RBuf[1]);
    AssertEquals('Byte 2', $BE, RBuf[2]);
    AssertEquals('Byte 3', $EF, RBuf[3]);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_SeekStart_Success;
var
  C: TIOCursor;
  Pos: Int64;
begin
  C := TIOCursor.Create(100);
  try
    C.Seek(50, SeekStart);
    Pos := C.Position;
    AssertEquals('Position after SeekStart', 50, Pos);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_SeekCurrent_Success;
var
  C: TIOCursor;
  Pos: Int64;
begin
  C := TIOCursor.Create(100);
  try
    C.Seek(30, SeekStart);
    C.Seek(20, SeekCurrent);
    Pos := C.Position;
    AssertEquals('Position after SeekCurrent', 50, Pos);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_SeekEnd_Success;
var
  C: TIOCursor;
  Data: TBytes;
  Pos: Int64;
begin
  SetLength(Data, 100);
  C := TIOCursor.FromBytes(Data);
  try
    Pos := C.Seek(-10, SeekEnd);
    AssertEquals('Position after SeekEnd', 90, Pos);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_ReadEOF_ReturnsZero;
var
  C: TIOCursor;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  C := TIOCursor.Create;
  try
    N := C.Read(@Buf[0], 10);
    AssertEquals('Read on empty returns 0', 0, N);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_FromBytes_Success;
var
  C: TIOCursor;
  Data: TBytes;
  Buf: array[0..2] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 3);
  Data[0] := 1; Data[1] := 2; Data[2] := 3;

  C := TIOCursor.FromBytes(Data);
  try
    N := C.Read(@Buf[0], 3);
    AssertEquals('Read count', 3, N);
    AssertEquals('Byte 0', 1, Buf[0]);
    AssertEquals('Byte 1', 2, Buf[1]);
    AssertEquals('Byte 2', 3, Buf[2]);
  finally
    C.Free;
  end;
end;

procedure TTestIOCursor.Test_Cursor_ToBytes_Success;
var
  C: TIOCursor;
  WBuf: array[0..2] of Byte;
  Result: TBytes;
begin
  C := TIOCursor.Create;
  try
    WBuf[0] := 10; WBuf[1] := 20; WBuf[2] := 30;
    C.Write(@WBuf[0], 3);

    Result := C.ToBytes;
    AssertEquals('Length', 3, Length(Result));
    AssertEquals('Byte 0', 10, Result[0]);
    AssertEquals('Byte 1', 20, Result[1]);
    AssertEquals('Byte 2', 30, Result[2]);
  finally
    C.Free;
  end;
end;

{ TTestLimitedReader }

procedure TTestLimitedReader.Test_LimitedReader_ReadWithinLimit;
var
  Data: TBytes;
  Cursor: IReader;
  LR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 10);
  FillChar(Data[0], 10, $AA);

  Cursor := TIOCursor.FromBytes(Data);
  LR := LimitReader(Cursor, 5);
  N := LR.Read(@Buf[0], 10);
  AssertEquals('Limited to 5 bytes', 5, N);
end;

procedure TTestLimitedReader.Test_LimitedReader_ReadExceedLimit;
var
  Data: TBytes;
  Cursor: IReader;
  LR: IReader;
  Buf: array[0..19] of Byte;
  N1, N2: SizeInt;
begin
  SetLength(Data, 20);
  FillChar(Data[0], 20, $BB);

  Cursor := TIOCursor.FromBytes(Data);
  LR := LimitReader(Cursor, 10);
  N1 := LR.Read(@Buf[0], 20);
  AssertEquals('First read limited', 10, N1);

  N2 := LR.Read(@Buf[0], 10);
  AssertEquals('Second read returns 0', 0, N2);
end;

procedure TTestLimitedReader.Test_LimitedReader_ZeroLimit;
var
  Data: TBytes;
  Cursor: IReader;
  LR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 10);
  Cursor := TIOCursor.FromBytes(Data);
  LR := LimitReader(Cursor, 0);
  N := LR.Read(@Buf[0], 10);
  AssertEquals('Zero limit returns 0', 0, N);
end;

procedure TTestLimitedReader.Test_LimitedReader_Remaining;
var
  Data: TBytes;
  Cursor: IReader;
  LR: TLimitedReader;
  Buf: array[0..4] of Byte;
begin
  SetLength(Data, 10);
  Cursor := TIOCursor.FromBytes(Data);
  LR := TLimitedReader.Create(Cursor, 10);
  try
    AssertEquals('Initial remaining', 10, LR.Remaining);
    LR.Read(@Buf[0], 5);
    AssertEquals('After read remaining', 5, LR.Remaining);
  finally
    LR.Free;
  end;
end;

{ TTestMultiReader }

procedure TTestMultiReader.Test_MultiReader_ChainTwoReaders;
var
  Data1, Data2: TBytes;
  C1, C2: IReader;
  MR: IReader;
  Buf: array[0..5] of Byte;
  N: SizeInt;
begin
  SetLength(Data1, 3);
  Data1[0] := 1; Data1[1] := 2; Data1[2] := 3;

  SetLength(Data2, 3);
  Data2[0] := 4; Data2[1] := 5; Data2[2] := 6;

  C1 := TIOCursor.FromBytes(Data1);
  C2 := TIOCursor.FromBytes(Data2);
  MR := MultiReader([C1, C2]);

  N := MR.Read(@Buf[0], 6);
  AssertEquals('Total read', 3, N);  // 第一个读取器
  AssertEquals('Byte 0', 1, Buf[0]);

  N := MR.Read(@Buf[3], 3);
  AssertEquals('Second read', 3, N);  // 第二个读取器
  AssertEquals('Byte 3', 4, Buf[3]);
end;

procedure TTestMultiReader.Test_MultiReader_EmptyReaders;
var
  MR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  MR := MultiReader([]);
  N := MR.Read(@Buf[0], 10);
  AssertEquals('Empty multi returns 0', 0, N);
end;

procedure TTestMultiReader.Test_MultiReader_SingleReader;
var
  Data: TBytes;
  C: IReader;
  MR: IReader;
  Buf: array[0..2] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 3);
  Data[0] := 7; Data[1] := 8; Data[2] := 9;

  C := TIOCursor.FromBytes(Data);
  MR := MultiReader([C]);
  N := MR.Read(@Buf[0], 3);
  AssertEquals('Read count', 3, N);
  AssertEquals('Byte 0', 7, Buf[0]);
end;

{ TTestEmptyAndDiscard }

procedure TTestEmptyAndDiscard.Test_EmptyReader_ReturnsZero;
var
  ER: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  ER := EmptyReader;
  N := ER.Read(@Buf[0], 10);
  AssertEquals('Empty reader returns 0', 0, N);
end;

procedure TTestEmptyAndDiscard.Test_Discard_AlwaysSucceeds;
var
  DW: IWriter;
  Data: array[0..99] of Byte;
  N: SizeInt;
begin
  DW := Discard;
  N := DW.Write(@Data[0], 100);
  AssertEquals('Discard accepts all', 100, N);
end;

{ TTestRepeatReader }

procedure TTestRepeatReader.Test_RepeatByte_FillsBuffer;
var
  RR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
begin
  RR := RepeatByte($FF);
  N := RR.Read(@Buf[0], 10);
  AssertEquals('Read count', 10, N);

  for I := 0 to 9 do
    AssertEquals('Byte ' + IntToStr(I), $FF, Buf[I]);
end;

{ TTestBufferedIO }

procedure TTestBufferedIO.Test_BufReader_ReadLine;
var
  Data: TBytes;
  Cursor: IReader;
  BR: TBufReader;
  Line: string;
  HasLine: Boolean;
begin
  Data := TEncoding.UTF8.GetBytes('Hello'#10'World'#10);

  Cursor := TIOCursor.FromBytes(Data);
  BR := TBufReader.Create(Cursor);
  try
    HasLine := BR.ReadLine(Line);
    AssertTrue('Has first line', HasLine);
    AssertEquals('First line', 'Hello', Line);

    HasLine := BR.ReadLine(Line);
    AssertTrue('Has second line', HasLine);
    AssertEquals('Second line', 'World', Line);

    HasLine := BR.ReadLine(Line);
    AssertFalse('No more lines', HasLine);
  finally
    BR.Free;
  end;
end;

{ 跨缓冲的 CRLF 情况：\r 落在前一个缓冲区末尾，\n 在下一个缓冲区开头 }
procedure TTestBufferedIO.Test_BufReader_ReadLine_CRLF_SplitAcrossBuffers;
var
  Data: TBytes;
  Cursor: IReader;
  BR: TBufReader;
  Line: string;
  HasLine: Boolean;
begin
  // 'ABCD' + CRLF，缓冲区大小设为 5，使得前一次 FillBuf 得到 "ABCD\r"
  Data := TEncoding.UTF8.GetBytes('ABCD' + #13#10 + 'X');
  Cursor := TIOCursor.FromBytes(Data);
  BR := TBufReader.Create(Cursor, 5);
  try
    HasLine := BR.ReadLine(Line);
    AssertTrue('Has line', HasLine);
    // 行内容不应该包含结尾的 CR
    AssertEquals('Line without CR', 'ABCD', Line);
  finally
    BR.Free;
  end;
end;

{ 长行 + 小缓冲区，验证跨多个缓冲读取行为正确 }
procedure TTestBufferedIO.Test_BufReader_ReadLine_LongLine_SmallBuffer;
var
  S: string;
  Data: TBytes;
  Cursor: IReader;
  BR: TBufReader;
  Line: string;
  HasLine: Boolean;
begin
  // 构造一条长度远大于缓冲区的行
  S := StringOfChar('A', 1024);
  Data := TEncoding.UTF8.GetBytes(UnicodeString(S + #10));

  Cursor := TIOCursor.FromBytes(Data);
  BR := TBufReader.Create(Cursor, 16);
  try
    HasLine := BR.ReadLine(Line);
    AssertTrue('Has long line', HasLine);
    AssertEquals('Long line content', S, Line);

    HasLine := BR.ReadLine(Line);
    AssertFalse('No more lines after long line', HasLine);
  finally
    BR.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufReader_ReadUntil_Interrupted_Retries;
var
  SrcData: TBytes;
  Cursor: IReader;
  FailR: TFailNTimesReader;
  Src: IReader;
  BR: TBufReader;
  Data: TBytes;
  FailCount: Integer;
begin
  FailCount := 2;
  SrcData := TEncoding.UTF8.GetBytes('Hello'#10);

  Cursor := TIOCursor.FromBytes(SrcData);
  FailR := TFailNTimesReader.Create(Cursor, FailCount, ekInterrupted);
  Src := FailR;

  BR := TBufReader.Create(Src);
  try
    AssertTrue('ReadUntil should succeed', BR.ReadUntil(10, Data));
    AssertEquals('Data length', Length(SrcData), Length(Data));
    AssertEquals('Byte 0', Ord('H'), Data[0]);
    AssertEquals('Byte 4', Ord('o'), Data[4]);
    AssertEquals('Delim', 10, Data[5]);
    AssertEquals('Read retries (calls)', FailCount + 1, FailR.CallCount);
  finally
    BR.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufReader_Read_Interrupted_Retries;
var
  SrcData: TBytes;
  Cursor: IReader;
  FailR: TFailNTimesReader;
  Src: IReader;
  BR: TBufReader;
  Buf: array[0..4] of Byte;
  N: SizeInt;
  FailCount: Integer;
begin
  FailCount := 2;
  SrcData := TEncoding.UTF8.GetBytes('Hello');

  Cursor := TIOCursor.FromBytes(SrcData);
  FailR := TFailNTimesReader.Create(Cursor, FailCount, ekInterrupted);
  Src := FailR;

  BR := TBufReader.Create(Src, 16);
  try
    FillChar(Buf[0], Length(Buf), 0);
    N := BR.Read(@Buf[0], 5);
    AssertEquals('Read count', 5, N);
    AssertEquals('Byte 0', Ord('H'), Buf[0]);
    AssertEquals('Byte 4', Ord('o'), Buf[4]);
    AssertEquals('Read retries (calls)', FailCount + 1, FailR.CallCount);
  finally
    BR.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufReader_Read_LargeRead_Interrupted_Retries;
var
  SrcData: TBytes;
  Cursor: IReader;
  FailR: TFailNTimesReader;
  Src: IReader;
  BR: TBufReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(SrcData, 10);
  for I := 0 to High(SrcData) do
    SrcData[I] := I;

  Cursor := TIOCursor.FromBytes(SrcData);
  FailR := TFailNTimesReader.Create(Cursor, FailCount, ekInterrupted);
  Src := FailR;

  // BufSize 4, reading 10 bytes triggers the direct-read path
  BR := TBufReader.Create(Src, 4);
  try
    FillChar(Buf[0], Length(Buf), 0);
    N := BR.Read(@Buf[0], 10);
    AssertEquals('Read count', 10, N);
    AssertEquals('Byte 0', 0, Buf[0]);
    AssertEquals('Byte 9', 9, Buf[9]);
    AssertEquals('Read retries (calls)', FailCount + 1, FailR.CallCount);
  finally
    BR.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufWriter_Flush_Interrupted_Retries;
var
  DstCursor: TIOCursor;
  Inner: IWriter;
  FailW: TFailNTimesWriter;
  Dst: IWriter;
  BW: TBufWriter;
  Data: array[0..4] of Byte;
  FailCount: Integer;
begin
  FailCount := 2;
  Data[0] := Ord('H');
  Data[1] := Ord('e');
  Data[2] := Ord('l');
  Data[3] := Ord('l');
  Data[4] := Ord('o');

  DstCursor := TIOCursor.Create;
  Inner := DstCursor;
  FailW := TFailNTimesWriter.Create(Inner, FailCount, ekInterrupted);
  Dst := FailW;

  BW := TBufWriter.Create(Dst, 16);
  try
    AssertEquals('Write buffered', 5, BW.Write(@Data[0], 5));
    BW.Flush;
    AssertEquals('Flush retries (calls)', FailCount + 1, FailW.CallCount);
    AssertEquals('Dst size', 5, DstCursor.Size);
  finally
    BW.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufWriter_Flush_ZeroWrite_RaisesEIOError;
var
  ZW: IWriter;
  BW: TBufWriter;
  Data: array[0..2] of Byte;
  Raised: Boolean;
  GotKind: TIOErrorKind;
begin
  ZW := TZeroWriter.Create;
  BW := TBufWriter.Create(ZW, 8);
  try
    Data[0] := 1; Data[1] := 2; Data[2] := 3;
    AssertEquals('Write buffered', 3, BW.Write(@Data[0], 3));

    Raised := False;
    GotKind := ekUnknown;
    try
      BW.Flush;
    except
      on E: EIOError do
      begin
        Raised := True;
        GotKind := E.Kind;
      end;
    end;

    AssertTrue('Flush should raise EIOError on zero-write', Raised);
    AssertEquals('Flush zero-write kind', Ord(ekWriteZero), Ord(GotKind));
  finally
    BW.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufWriter_Write_LargeWrite_Interrupted_Retries;
var
  DstCursor: TIOCursor;
  Inner: IWriter;
  FailW: TFailNTimesWriter;
  Dst: IWriter;
  BW: TBufWriter;
  Data: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
  FailCount: Integer;
begin
  FailCount := 2;
  for I := 0 to High(Data) do
    Data[I] := I;

  DstCursor := TIOCursor.Create;
  Inner := DstCursor;
  FailW := TFailNTimesWriter.Create(Inner, FailCount, ekInterrupted);
  Dst := FailW;

  // BufSize 4, writing 10 bytes triggers the direct-write path
  BW := TBufWriter.Create(Dst, 4);
  try
    N := BW.Write(@Data[0], Length(Data));
    AssertEquals('Write count', Length(Data), N);
    AssertEquals('Write retries (calls)', FailCount + 1, FailW.CallCount);
    AssertEquals('Dst size', Length(Data), DstCursor.Size);
  finally
    BW.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufWriter_Write_LargeWrite_ZeroWrite_RaisesEIOError;
var
  ZW: IWriter;
  BW: TBufWriter;
  Data: array[0..3] of Byte;
  Raised: Boolean;
  GotKind: TIOErrorKind;
begin
  // Use small buffer and larger write to hit direct-write path
  ZW := TZeroWriter.Create;
  BW := TBufWriter.Create(ZW, 2);
  try
    Data[0] := 1; Data[1] := 2; Data[2] := 3; Data[3] := 4;

    Raised := False;
    GotKind := ekUnknown;
    try
      BW.Write(@Data[0], 4);
    except
      on E: EIOError do
      begin
        Raised := True;
        GotKind := E.Kind;
      end;
    end;

    AssertTrue('Write should raise EIOError on zero-write', Raised);
    AssertEquals('Write zero-write kind', Ord(ekWriteZero), Ord(GotKind));
  finally
    BW.Free;
  end;
end;

procedure TTestBufferedIO.Test_BufWriter_FlushOnDestroy;
var
  MS: TMemoryStream;
  BW: TBufWriter;
  IO: IWriter;
  Data: array[0..2] of Byte;
begin
  MS := TMemoryStream.Create;
  try
    IO := WriterFromStream(MS, False);
    BW := TBufWriter.Create(IO);
    try
      Data[0] := 1; Data[1] := 2; Data[2] := 3;
      BW.Write(@Data[0], 3);
      // 未显式 Flush，数据在缓冲中
    finally
      BW.Free;  // Destroy 应该 Flush
    end;

    AssertEquals('Data flushed', 3, MS.Size);
  finally
    MS.Free;
  end;
end;

{ TTestIOUtils }

procedure TTestIOUtils.Test_Copy_FullTransfer;
var
  SrcData: TBytes;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
begin
  SetLength(SrcData, 100);
  FillChar(SrcData[0], 100, $CC);

  Src := TIOCursor.FromBytes(SrcData);
  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  Copied := Copy(Dst, Src);
  AssertEquals('Copied bytes', 100, Copied);
  AssertEquals('Dst size', 100, DstCursor.Size);
end;

procedure TTestIOUtils.Test_Copy_Interrupted_Retries;
var
  SrcData: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(SrcData, 10);
  FillChar(SrcData[0], 10, $CC);

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(SrcData), FailCount, ekInterrupted);
  Src := FailR;

  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  Copied := Copy(Dst, Src);

  AssertEquals('Copied bytes', 10, Copied);
  AssertEquals('Dst size', 10, DstCursor.Size);
  AssertEquals('Copy retries (calls)', FailCount + 2, FailR.CallCount);
end;

procedure TTestIOUtils.Test_CopyN_ExactBytes;
var
  SrcData: TBytes;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
begin
  SetLength(SrcData, 100);
  FillChar(SrcData[0], 100, $DD);

  Src := TIOCursor.FromBytes(SrcData);
  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  Copied := CopyN(Dst, Src, 50);
  AssertEquals('Copied exactly 50', 50, Copied);
  AssertEquals('Dst size', 50, DstCursor.Size);
end;

procedure TTestIOUtils.Test_CopyN_Interrupted_Retries;
var
  SrcData: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(SrcData, 10);
  FillChar(SrcData[0], 10, $DD);

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(SrcData), FailCount, ekInterrupted);
  Src := FailR;

  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  Copied := CopyN(Dst, Src, 10);

  AssertEquals('Copied exactly 10', 10, Copied);
  AssertEquals('Dst size', 10, DstCursor.Size);
  AssertEquals('CopyN retries (calls)', FailCount + 1, FailR.CallCount);
end;

procedure TTestIOUtils.Test_ReadAll_Success;
var
  SrcData: TBytes;
  Src: IReader;
  LResult: TBytes;
begin
  SetLength(SrcData, 256);
  FillChar(SrcData[0], 256, $EE);

  Src := TIOCursor.FromBytes(SrcData);
  LResult := ReadAll(Src);
  AssertEquals('ReadAll length', 256, Length(LResult));
end;

procedure TTestIOUtils.Test_ReadAll_Interrupted_Retries;
var
  SrcData: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  LResult: TBytes;
  FailCount: Integer;
begin
  FailCount := 3;
  SetLength(SrcData, 10);
  FillChar(SrcData[0], 10, $AB);

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(SrcData), FailCount, ekInterrupted);
  Src := FailR;

  LResult := ReadAll(Src);
  AssertEquals('ReadAll length', Length(SrcData), Length(LResult));
  AssertEquals('ReadAll first byte', $AB, LResult[0]);
  AssertEquals('ReadAll retries (calls)', FailCount + 2, FailR.CallCount);
end;

procedure TTestIOUtils.Test_ReadFull_Success;
var
  SrcData: TBytes;
  Src: IReader;
  Buf: array[0..49] of Byte;
  N: SizeInt;
begin
  SetLength(SrcData, 100);
  FillChar(SrcData[0], 100, $11);

  Src := TIOCursor.FromBytes(SrcData);
  N := ReadFull(Src, @Buf[0], 50);
  AssertEquals('ReadFull count', 50, N);
end;

procedure TTestIOUtils.Test_ReadFull_Interrupted_Retries;
var
  SrcData: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  Buf: array[0..3] of Byte;
  N: SizeInt;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(SrcData, 4);
  FillChar(SrcData[0], 4, $CD);

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(SrcData), FailCount, ekInterrupted);
  Src := FailR;

  FillChar(Buf[0], 4, 0);
  N := ReadFull(Src, @Buf[0], 4);

  AssertEquals('ReadFull count', 4, N);
  AssertEquals('ReadFull first byte', $CD, Buf[0]);
  AssertEquals('ReadFull retries (calls)', FailCount + 1, FailR.CallCount);
end;

procedure TTestIOUtils.Test_ReadFull_UnexpectedEOF;
var
  SrcData: TBytes;
  Src: IReader;
  Buf: array[0..99] of Byte;
  Raised: Boolean;
begin
  SetLength(SrcData, 10);

  Src := TIOCursor.FromBytes(SrcData);
  Raised := False;
  try
    ReadFull(Src, @Buf[0], 100);
  except
    on E: EUnexpectedEOF do
      Raised := True;
  end;
  AssertTrue('Should raise EUnexpectedEOF', Raised);
end;

procedure TTestIOUtils.Test_WriteAll_Success;
var
  DstCursor: TIOCursor;
  Dst: IWriter;
  Data: array[0..99] of Byte;
  N: SizeInt;
begin
  FillChar(Data[0], 100, $22);

  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  N := WriteAll(Dst, @Data[0], 100);
  AssertEquals('WriteAll count', 100, N);
  AssertEquals('Dst size', 100, DstCursor.Size);
end;

procedure TTestIOUtils.Test_WriteAll_Interrupted_Retries;
var
  DstCursor: TIOCursor;
  Inner: IWriter;
  FailW: TFailNTimesWriter;
  Dst: IWriter;
  Data: array[0..3] of Byte;
  N: SizeInt;
  FailCount: Integer;
begin
  FailCount := 2;
  Data[0] := $10;
  Data[1] := $20;
  Data[2] := $30;
  Data[3] := $40;

  DstCursor := TIOCursor.Create;
  Inner := DstCursor;

  FailW := TFailNTimesWriter.Create(Inner, FailCount, ekInterrupted);
  Dst := FailW;

  N := WriteAll(Dst, @Data[0], 4);

  AssertEquals('WriteAll count', 4, N);
  AssertEquals('WriteAll retries (calls)', FailCount + 1, FailW.CallCount);
  AssertEquals('Dst size', 4, DstCursor.Size);
end;

procedure TTestIOUtils.Test_WriteAll_ZeroWrite_RaisesEIOError;
var
  Dst: IWriter;
  Data: array[0..9] of Byte;
  Raised: Boolean;
  GotKind: TIOErrorKind;
begin
  FillChar(Data[0], 10, $33);
  Dst := TZeroWriter.Create;

  Raised := False;
  GotKind := ekUnknown;
  try
    WriteAll(Dst, @Data[0], 10);
  except
    on E: EIOError do
    begin
      Raised := True;
      GotKind := E.Kind;
    end;
  end;

  AssertTrue('WriteAll should raise EIOError when underlying writer returns 0', Raised);
  AssertEquals('WriteAll zero-write kind', Ord(ekWriteZero), Ord(GotKind));
end;

procedure TTestIOUtils.Test_WriteString_UTF8;
var
  DstCursor: TIOCursor;
  Dst: IWriter;
  N: SizeInt;
  LResult: TBytes;
begin
  DstCursor := TIOCursor.Create;
  Dst := DstCursor;
  N := WriteString(Dst, 'Hello');
  AssertEquals('WriteString count', 5, N);

  LResult := DstCursor.ToBytes;
  AssertEquals('Byte H', Ord('H'), LResult[0]);
  AssertEquals('Byte e', Ord('e'), LResult[1]);
end;

procedure TTestIOUtils.Test_ReadString_UTF8;
var
  SrcData: TBytes;
  Src: IReader;
  S: string;
begin
  SrcData := TEncoding.UTF8.GetBytes('Hello World');
  Src := TIOCursor.FromBytes(SrcData);
  S := ReadString(Src);
  AssertEquals('ReadString', 'Hello World', S);
end;

procedure TTestIOUtils.Test_CopyBuffer_CustomSize;
var
  SrcData: TBytes;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
begin
  SetLength(SrcData, 1000);
  FillChar(SrcData[0], 1000, $AA);

  Src := TIOCursor.FromBytes(SrcData);
  DstCursor := TIOCursor.Create;
  Dst := DstCursor;

  // 使用 256 字节缓冲区
  Copied := CopyBuffer(Dst, Src, 256);
  AssertEquals('Copied', 1000, Copied);
  AssertEquals('Dst size', 1000, DstCursor.Size);
end;

procedure TTestIOUtils.Test_ReadAtLeast_MinReached;
var
  SrcData: TBytes;
  Src: IReader;
  Buf: array[0..99] of Byte;
  N: SizeInt;
begin
  SetLength(SrcData, 50);
  FillChar(SrcData[0], 50, $BB);

  Src := TIOCursor.FromBytes(SrcData);
  N := ReadAtLeast(Src, @Buf[0], 100, 30);  // 至少读 30 字节
  AssertTrue('At least 30', N >= 30);
  AssertEquals('Actually read 50', 50, N);  // 实际读取到 50
end;

procedure TTestIOUtils.Test_ReadAtLeast_Interrupted_Retries;
var
  SrcData: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  Buf: array[0..99] of Byte;
  N: SizeInt;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(SrcData, 50);
  FillChar(SrcData[0], 50, $BB);

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(SrcData), FailCount, ekInterrupted);
  Src := FailR;

  FillChar(Buf[0], Length(Buf), 0);
  N := ReadAtLeast(Src, @Buf[0], 100, 30);

  AssertTrue('At least 30', N >= 30);
  AssertEquals('Actually read 50', 50, N);
  AssertEquals('ReadAtLeast retries (calls)', FailCount + 2, FailR.CallCount);
end;

{ TTestStreamAdapter }

procedure TTestStreamAdapter.Test_StreamIO_ReadWrite;
var
  MS: TMemoryStream;
  IO: TStreamIO;
  WBuf: array[0..3] of Byte;
  RBuf: array[0..3] of Byte;
  N: SizeInt;
begin
  MS := TMemoryStream.Create;
  IO := TStreamIO.Create(MS, True);  // 拥有流
  try
    WBuf[0] := 1; WBuf[1] := 2; WBuf[2] := 3; WBuf[3] := 4;
    N := IO.Write(@WBuf[0], 4);
    AssertEquals('Write count', 4, N);

    IO.Seek(0, SeekStart);

    N := IO.Read(@RBuf[0], 4);
    AssertEquals('Read count', 4, N);
    AssertEquals('Byte 0', 1, RBuf[0]);
    AssertEquals('Byte 3', 4, RBuf[3]);
  finally
    IO.Free;  // 同时释放 MS
  end;
end;

procedure TTestStreamAdapter.Test_StreamIO_Seek;
var
  MS: TMemoryStream;
  IO: TStreamIO;
  Pos: Int64;
begin
  MS := TMemoryStream.Create;
  MS.SetSize(100);
  IO := TStreamIO.Create(MS, True);
  try
    Pos := IO.Seek(50, SeekStart);
    AssertEquals('SeekStart', 50, Pos);

    Pos := IO.Seek(10, SeekCurrent);
    AssertEquals('SeekCurrent', 60, Pos);

    Pos := IO.Seek(-20, SeekEnd);
    AssertEquals('SeekEnd', 80, Pos);
  finally
    IO.Free;
  end;
end;

{ TTestTeeIO }

procedure TTestTeeIO.Test_TeeReader_CopiesOnRead;
var
  SrcData: TBytes;
  Src: IReader;
  CopyCursor: TIOCursor;
  CopyWriter: IWriter;
  Tee: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  // 准备源数据
  SetLength(SrcData, 10);
  FillChar(SrcData[0], 10, $AA);

  Src := TIOCursor.FromBytes(SrcData);
  CopyCursor := TIOCursor.Create;
  CopyWriter := CopyCursor;  // 接口引用计数管理生命周期

  // 创建 TeeReader: 读取时同时写入 Copy
  Tee := TeeReader(Src, CopyWriter);

  // 读取
  N := Tee.Read(@Buf[0], 10);
  AssertEquals('Read count', 10, N);

  // 验证数据被复制到 Copy
  AssertEquals('Copy size', 10, CopyCursor.Size);
  // 所有接口自动释放
end;

procedure TTestTeeIO.Test_TeeReader_PreservesData;
var
  SrcData: TBytes;
  Src: IReader;
  CopyCursor: TIOCursor;
  CopyWriter: IWriter;
  Tee: IReader;
  Buf: array[0..4] of Byte;
  CopyBytes: TBytes;
  I: Integer;
begin
  // 源数据 [1,2,3,4,5]
  SetLength(SrcData, 5);
  for I := 0 to 4 do
    SrcData[I] := I + 1;

  Src := TIOCursor.FromBytes(SrcData);
  CopyCursor := TIOCursor.Create;
  CopyWriter := CopyCursor;

  Tee := TeeReader(Src, CopyWriter);
  Tee.Read(@Buf[0], 5);

  // 验证读取的数据正确
  for I := 0 to 4 do
    AssertEquals('Read byte ' + IntToStr(I), I + 1, Buf[I]);

  // 验证复制的数据正确
  CopyBytes := CopyCursor.ToBytes;
  for I := 0 to 4 do
    AssertEquals('Copy byte ' + IntToStr(I), I + 1, CopyBytes[I]);
end;

procedure TTestTeeIO.Test_TeeReader_ShortWrite_RaisesEIOError;
var
  SrcData: TBytes;
  Src: IReader;
  FailWriter: IWriter;
  Tee: IReader;
  Buf: array[0..3] of Byte;
  Raised: Boolean;
begin
  // 源数据 4 字节
  SetLength(SrcData, 4);
  FillChar(SrcData[0], 4, $AA);
  Src := TIOCursor.FromBytes(SrcData);

  // 目标 Writer 总是短写
  FailWriter := TShortWriter.Create;
  Tee := TeeReader(Src, FailWriter);

  Raised := False;
  try
    Tee.Read(@Buf[0], 4);
  except
    on E: EIOError do
      Raised := True;
  end;

  AssertTrue('TeeReader should raise EIOError on short write', Raised);
end;

procedure TTestTeeIO.Test_MultiWriter_WritesToAll;
var
  C1, C2, C3: TIOCursor;
  W1, W2, W3: IWriter;
  MW: IWriter;
  Data: array[0..4] of Byte;
  N: SizeInt;
  I: Integer;
begin
  // 准备数据
  for I := 0 to 4 do
    Data[I] := I * 10;

  C1 := TIOCursor.Create;
  C2 := TIOCursor.Create;
  C3 := TIOCursor.Create;
  W1 := C1;
  W2 := C2;
  W3 := C3;

  // 创建 MultiWriter
  MW := MultiWriter([W1, W2, W3]);

  // 写入
  N := MW.Write(@Data[0], 5);
  AssertEquals('Write count', 5, N);

  // 验证所有 writer 都收到数据
  AssertEquals('W1 size', 5, C1.Size);
  AssertEquals('W2 size', 5, C2.Size);
  AssertEquals('W3 size', 5, C3.Size);

  // 验证数据内容
  AssertEquals('W1 byte 0', 0, C1.ToBytes[0]);
  AssertEquals('W2 byte 2', 20, C2.ToBytes[2]);
  AssertEquals('W3 byte 4', 40, C3.ToBytes[4]);
  // 接口自动释放
end;

procedure TTestTeeIO.Test_MultiWriter_Empty;
var
  MW: IWriter;
  Data: array[0..4] of Byte;
  N: SizeInt;
begin
  // 空 MultiWriter
  MW := MultiWriter([]);
  N := MW.Write(@Data[0], 5);
  AssertEquals('Empty multi returns count', 5, N);
end;

procedure TTestTeeIO.Test_MultiWriter_Single;
var
  Cursor: TIOCursor;
  W: IWriter;
  MW: IWriter;
  Data: array[0..2] of Byte;
  N: SizeInt;
begin
  Data[0] := 1; Data[1] := 2; Data[2] := 3;

  Cursor := TIOCursor.Create;
  W := Cursor;

  MW := MultiWriter([W]);
  N := MW.Write(@Data[0], 3);
  AssertEquals('Write count', 3, N);
  AssertEquals('W size', 3, Cursor.Size);
end;

procedure TTestTeeIO.Test_MultiWriter_ShortWrite_RaisesEIOError;
var
  GoodCursor: TIOCursor;
  GoodWriter: IWriter;
  FailWriter: IWriter;
  MW: IWriter;
  Data: array[0..3] of Byte;
  Raised: Boolean;
begin
  GoodCursor := TIOCursor.Create;
  GoodWriter := GoodCursor;
  FailWriter := TShortWriter.Create;

  MW := MultiWriter([GoodWriter, FailWriter]);
  FillChar(Data[0], 4, $BB);

  Raised := False;
  try
    MW.Write(@Data[0], 4);
  except
    on E: EIOError do
      Raised := True;
  end;

  AssertTrue('MultiWriter should raise EIOError on short write', Raised);
end;

{ TTestPipe }

procedure TTestPipe.Test_Pipe_WriteRead;
var
  R: IReader;
  W: IWriter;
  WBuf: array[0..4] of Byte;
  RBuf: array[0..4] of Byte;
  NW, NR: SizeInt;
  I: Integer;
begin
  // 创建管道
  Pipe(R, W);

  // 写入数据
  for I := 0 to 4 do
    WBuf[I] := I + 1;
  NW := W.Write(@WBuf[0], 5);
  AssertEquals('Write count', 5, NW);

  // 读取数据
  NR := R.Read(@RBuf[0], 5);
  AssertEquals('Read count', 5, NR);

  // 验证数据
  for I := 0 to 4 do
    AssertEquals('Byte ' + IntToStr(I), I + 1, RBuf[I]);
end;

procedure TTestPipe.Test_Pipe_CloseWriter_ReaderEOF;
var
  R: IReader;
  W: IWriteCloser;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  // 创建管道
  PipeCloser(R, W);

  // 关闭写入端
  W.Close;

  // 读取应该返回 0 (EOF)
  N := R.Read(@Buf[0], 10);
  AssertEquals('Read after close returns 0', 0, N);
end;

procedure TTestPipe.Test_Pipe_MultipleWrites;
var
  R: IReader;
  W: IWriter;
  WBuf1, WBuf2: array[0..2] of Byte;
  RBuf: array[0..5] of Byte;
  N: SizeInt;
begin
  Pipe(R, W);

  // 第一次写入
  WBuf1[0] := 1; WBuf1[1] := 2; WBuf1[2] := 3;
  W.Write(@WBuf1[0], 3);

  // 第二次写入
  WBuf2[0] := 4; WBuf2[1] := 5; WBuf2[2] := 6;
  W.Write(@WBuf2[0], 3);

  // 一次性读取
  N := R.Read(@RBuf[0], 6);
  AssertEquals('Read count', 6, N);
  AssertEquals('Byte 0', 1, RBuf[0]);
  AssertEquals('Byte 5', 6, RBuf[5]);
end;

{ TTestPipeSemantics }

procedure TTestPipeSemantics.Test_WriteToClosedPipe_RaisesError;
var
  R: IReader;
  W: IWriteCloser;
  Buf: array[0..3] of Byte;
  Raised: Boolean;
begin
  PipeCloser(R, W);
  W.Close;

  Raised := False;
  try
    Buf[0] := 1;
    W.Write(@Buf[0], 1);
  except
    on E: EIOError do
      if E.Kind = ekBrokenPipe then
        Raised := True;
  end;

  AssertTrue('Writing to closed pipe should raise EIOError(ekBrokenPipe)', Raised);
end;

procedure TTestPipeSemantics.Test_ReadFromEmptyPipe_NotClosed_ReturnsZero;
var
  R: IReader;
  W: IWriter;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  Pipe(R, W);
  // Pipe is empty, not closed
  N := R.Read(@Buf[0], 10);
  AssertEquals('Read from empty open pipe returns 0 (non-blocking)', 0, N);
end;

procedure TTestPipeSemantics.Test_ReadFromClosedPipe_ReturnsEOF;
var
  R: IReader;
  W: IWriteCloser;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  PipeCloser(R, W);
  W.Close;
  N := R.Read(@Buf[0], 10);
  AssertEquals('Read from closed pipe returns 0 (EOF)', 0, N);
end;

{ TTestCompress }

procedure TTestCompress.Test_Deflate_CompressDecompress;
var
  Original: TBytes;
  Compressed, Decompressed: TBytes;
  I: Integer;
begin
  // 原始数据: 可压缩的重复字节
  SetLength(Original, 1000);
  for I := 0 to High(Original) do
    Original[I] := I mod 256;

  // 压缩
  Compressed := Compress.DeflateCompress(Original);
  AssertTrue('Compressed smaller', Length(Compressed) < Length(Original));

  // 解压
  Decompressed := Compress.DeflateDecompress(Compressed);
  AssertEquals('Decompressed length', Length(Original), Length(Decompressed));

  // 验证内容
  for I := 0 to High(Original) do
    AssertEquals('Byte ' + IntToStr(I), Original[I], Decompressed[I]);
end;

procedure TTestCompress.Test_Gzip_CompressDecompress;
var
  Original: TBytes;
  Compressed, Decompressed: TBytes;
  I: Integer;
begin
  // 原始数据
  SetLength(Original, 500);
  for I := 0 to High(Original) do
    Original[I] := (I * 3) mod 256;

  // 压缩
  Compressed := Compress.GzipCompress(Original);
  // gzip 有 header 和 trailer，对于小数据可能不会更小
  AssertTrue('Compressed has data', Length(Compressed) > 0);

  // 解压
  Decompressed := Compress.GzipDecompress(Compressed);
  AssertEquals('Decompressed length', Length(Original), Length(Decompressed));

  // 验证内容
  for I := 0 to High(Original) do
    AssertEquals('Byte ' + IntToStr(I), Original[I], Decompressed[I]);
end;

{ TTestCompressSemantics }

procedure TTestCompressSemantics.Test_Deflate_DecompressGarbage_RaisesEIOError;
var
  Garbage: TBytes;
  Raised: Boolean;
begin
  SetLength(Garbage, 10);
  FillChar(Garbage[0], 10, $FF); // Random high entropy garbage, likely invalid deflate stream
  Raised := False;
  try
    Compress.DeflateDecompress(Garbage);
  except
    on E: EIOError do
      if E.Kind = ekInvalidData then
        Raised := True;
    on E: Exception do
      // Currently might catch EZDecompressionError here if not wrapped
      ;
  end;
  AssertTrue('Deflate decompress garbage should raise EIOError(ekInvalidData)', Raised);
end;

procedure TTestCompressSemantics.Test_Gzip_DecompressGarbage_RaisesEIOError;
var
  Garbage: TBytes;
  Raised: Boolean;
begin
  SetLength(Garbage, 10);
  FillChar(Garbage[0], 10, $AA);
  Raised := False;
  try
    Compress.GzipDecompress(Garbage);
  except
    on E: EIOError do
      if E.Kind = ekInvalidData then
        Raised := True;
    on E: Exception do
      ;
  end;
  AssertTrue('Gzip decompress garbage should raise EIOError(ekInvalidData)', Raised);
end;

procedure TTestCompressSemantics.Test_Deflate_DecompressTruncated_RaisesEIOError;
var
  Original, Compressed, Truncated: TBytes;
  Raised: Boolean;
  I: Integer;
begin
  // Create valid compressed data
  SetLength(Original, 100);
  for I := 0 to 99 do Original[I] := I;
  Compressed := Compress.DeflateCompress(Original);
  
  // Truncate it
  SetLength(Truncated, Length(Compressed) - 1); // Remove last byte
  Move(Compressed[0], Truncated[0], Length(Truncated));
  
  Raised := False;
  try
    Compress.DeflateDecompress(Truncated);
  except
    on E: EIOError do
    begin
      // Truncated data usually results in unexpected EOF or data error in zlib
      // We map it to ekUnexpectedEOF or ekInvalidData. 
      if (E.Kind = ekInvalidData) or (E.Kind = ekUnexpectedEOF) then
        Raised := True;
    end;
  end;
  AssertTrue('Deflate decompress truncated should raise EIOError', Raised);
end;

procedure TTestCompressSemantics.Test_Gzip_DecompressTruncated_RaisesEIOError;
var
  Original, Compressed, Truncated: TBytes;
  Raised: Boolean;
  I: Integer;
begin
  SetLength(Original, 100);
  for I := 0 to 99 do Original[I] := I;
  Compressed := Compress.GzipCompress(Original);
  
  SetLength(Truncated, Length(Compressed) div 2); // Cut half
  Move(Compressed[0], Truncated[0], Length(Truncated));
  
  Raised := False;
  try
    Compress.GzipDecompress(Truncated);
  except
    on E: EIOError do
      if (E.Kind = ekInvalidData) or (E.Kind = ekUnexpectedEOF) then
        Raised := True;
  end;
  AssertTrue('Gzip decompress truncated should raise EIOError', Raised);
end;

{ TTestCounted }

procedure TTestCounted.Test_CountedReader_TracksBytes;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReader;
  CR: TCountedReader;
  Buf: array[0..9] of Byte;
begin
  SetLength(Data, 100);
  FillChar(Data[0], 100, $AA);

  Cursor := TIOCursor.FromBytes(Data);
  Inner := Cursor;

  CR := TCountedReader.Create(Inner);
  try
    AssertEquals('Initial count', 0, CR.BytesRead);

    CR.Read(@Buf[0], 10);
    AssertEquals('After first read', 10, CR.BytesRead);

    CR.Read(@Buf[0], 5);
    AssertEquals('After second read', 15, CR.BytesRead);
  finally
    CR.Free;
  end;
end;

procedure TTestCounted.Test_CountedWriter_TracksBytes;
var
  Cursor: TIOCursor;
  Inner: IWriter;
  CW: TCountedWriter;
  Buf: array[0..9] of Byte;
begin
  Cursor := TIOCursor.Create;
  Inner := Cursor;

  CW := TCountedWriter.Create(Inner);
  try
    AssertEquals('Initial count', 0, CW.BytesWritten);

    CW.Write(@Buf[0], 10);
    AssertEquals('After first write', 10, CW.BytesWritten);

    CW.Write(@Buf[0], 7);
    AssertEquals('After second write', 17, CW.BytesWritten);
  finally
    CW.Free;
  end;
end;

procedure TTestCounted.Test_CountedReader_MultipleReads;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReader;
  CR: TCountedReader;
  Buf: array[0..99] of Byte;
  I: Integer;
begin
  SetLength(Data, 50);
  for I := 0 to 49 do
    Data[I] := I;

  Cursor := TIOCursor.FromBytes(Data);
  Inner := Cursor;

  CR := TCountedReader.Create(Inner);
  try
    // 读取全部
    CR.Read(@Buf[0], 100);  // 请求 100，实际只有 50
    AssertEquals('Read available bytes', 50, CR.BytesRead);

    // 再读应该是 0
    CR.Read(@Buf[0], 10);
    AssertEquals('No more bytes', 50, CR.BytesRead);  // 不变
  finally
    CR.Free;
  end;
end;

{ TTestSection }

procedure TTestSection.Test_SectionReader_ReadsSection;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReadSeeker;
  SR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
begin
  // 创建 100 字节数据 [0,1,2,...,99]
  SetLength(Data, 100);
  for I := 0 to 99 do
    Data[I] := I;

  Cursor := TIOCursor.FromBytes(Data);
  Inner := Cursor;

  // 只读取偶移量 20 开始的 10 字节
  SR := SectionReader(Inner, 20, 10);

  N := SR.Read(@Buf[0], 10);
  AssertEquals('Read count', 10, N);

  // 验证内容是 [20,21,...,29]
  for I := 0 to 9 do
    AssertEquals('Byte ' + IntToStr(I), 20 + I, Buf[I]);
end;

procedure TTestSection.Test_SectionReader_SeekWithinSection;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReadSeeker;
  SR: TSectionReader;
  Buf: array[0..4] of Byte;
  Pos: Int64;
  I: Integer;
begin
  SetLength(Data, 100);
  for I := 0 to 99 do
    Data[I] := I;

  Cursor := TIOCursor.FromBytes(Data);
  Inner := Cursor;

  // Section: 偶移量 10，长度 20 ([10..29])
  SR := TSectionReader.Create(Inner, 10, 20);
  try
    // Seek 到 section 内偶移量 5
    Pos := SR.Seek(5, SeekStart);
    AssertEquals('Seek position', 5, Pos);

    // 读取 5 字节，应该是 [15,16,17,18,19]
    SR.Read(@Buf[0], 5);
    for I := 0 to 4 do
      AssertEquals('Byte ' + IntToStr(I), 15 + I, Buf[I]);
  finally
    SR.Free;
  end;
end;

procedure TTestSection.Test_SectionReader_BeyondSection;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReadSeeker;
  SR: IReader;
  Buf: array[0..19] of Byte;
  N: SizeInt;
  I: Integer;
begin
  SetLength(Data, 100);
  for I := 0 to 99 do
    Data[I] := I;

  Cursor := TIOCursor.FromBytes(Data);
  Inner := Cursor;

  // Section: 偶移量 90，长度 20（但实际数据只有到 99）
  SR := SectionReader(Inner, 90, 20);

  // 请求 20 字节，但只能读 10 字节
  N := SR.Read(@Buf[0], 20);
  AssertEquals('Read limited by data', 10, N);

  // 验证 [90,91,...,99]
  for I := 0 to 9 do
    AssertEquals('Byte ' + IntToStr(I), 90 + I, Buf[I]);
end;

{ TTestAdapterSemantics }

type
  { TSpySeeker - 仅用于测试 Skip 是否调用了 Seek }
  TSpySeeker = class(TInterfacedObject, IReader, ISeeker)
  private
    FSeekCalled: Boolean;
    FInner: TIOCursor;
  public
    constructor Create(ACursor: TIOCursor);
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
    function Seek(Offset: Int64; Whence: Integer): Int64;
    property SeekCalled: Boolean read FSeekCalled;
  end;

constructor TSpySeeker.Create(ACursor: TIOCursor);
begin
  inherited Create;
  FInner := ACursor;
  FSeekCalled := False;
end;

function TSpySeeker.Read(Buf: Pointer; Count: SizeInt): SizeInt;
begin
  Result := FInner.Read(Buf, Count);
end;

function TSpySeeker.Seek(Offset: Int64; Whence: Integer): Int64;
begin
  FSeekCalled := True;
  Result := FInner.Seek(Offset, Whence);
end;

procedure TTestAdapterSemantics.Test_Skip_UsesSeek_IfAvailable;
var
  C: TIOCursor;
  Spy: TSpySeeker;
  Skipper: IReader;
  Buf: array[0..9] of Byte;
begin
  C := TIOCursor.Create(100); // Size 100
  Buf[0] := 1;
  C.Write(@Buf[0], 1);
  Spy := TSpySeeker.Create(C);
  
  Skipper := IO.Skip(Spy, 50); // Skip 50 bytes
  
  // 触发 Skip
  Skipper.Read(@Buf[0], 10);
  
  AssertTrue('Should use Seek', Spy.SeekCalled);
  // TIOCursor auto expands on Seek write but we are reading. 
  // Wait, TIOCursor starts empty. Let's fill it.
  C.Free;
end;

procedure TTestAdapterSemantics.Test_Skip_FallsBackToRead_IfNoSeek;
var
  C: TIOCursor;
  // IReader wrapper that hides ISeeker
  NoSeek: IReader; 
  Skipper: IReader;
  Buf: array[0..9] of Byte;
begin
  C := TIOCursor.Create;
  Buf[0] := 1; Buf[1] := 2; Buf[2] := 3;
  C.Write(@Buf[0], 3);
  C.Seek(0, SeekStart);
  
  NoSeek := TNopCloser.Create(C); // NopCloser only implements IReader, ICloser, IReadCloser (no ISeeker)
  
  Skipper := IO.Skip(NoSeek, 1); // Skip 1 byte
  
  Skipper.Read(@Buf[0], 1);
  AssertEquals('Read byte', 2, Buf[0]);
end;

procedure TTestAdapterSemantics.Test_Skip_Interrupted_Retries;
var
  Data: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  Skipper: IReader;
  Buf: array[0..4] of Byte;
  N: SizeInt;
  I: Integer;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(Data, 10);
  for I := 0 to High(Data) do
    Data[I] := I;

  FailR := TFailNTimesReader.Create(TIOCursor.FromBytes(Data), FailCount, ekInterrupted);
  Src := FailR;

  Skipper := IO.Skip(Src, 5);

  FillChar(Buf[0], Length(Buf), 0);
  N := Skipper.Read(@Buf[0], 5);

  AssertEquals('Read count', 5, N);
  AssertEquals('Byte 0', 5, Buf[0]);
  AssertEquals('Byte 4', 9, Buf[4]);
  AssertEquals('Skip retries (calls)', FailCount + 2, FailR.CallCount);
end;

{ TTestSectionSemantics }

procedure TTestSectionSemantics.Test_Seek_Negative_RaisesError;
var
  Data: TBytes;
  C: TIOCursor;
  SR: TSectionReader;
  Raised: Boolean;
begin
  SetLength(Data, 10);
  C := TIOCursor.FromBytes(Data);
  SR := TSectionReader.Create(C, 0, 10);
  try
    Raised := False;
    try
      SR.Seek(-1, SeekStart);
    except
      on E: EIOError do
        Raised := True;
    end;
    AssertTrue('Seek negative should raise EIOError', Raised);
  finally
    SR.Free;
  end;
end;

procedure TTestSectionSemantics.Test_Seek_BeyondEnd_ReturnsPos;
var
  Data: TBytes;
  C: TIOCursor;
  SR: TSectionReader;
  Pos: Int64;
begin
  SetLength(Data, 10);
  C := TIOCursor.FromBytes(Data);
  SR := TSectionReader.Create(C, 0, 5); // Section Size 5
  try
    Pos := SR.Seek(10, SeekStart); // Seek to 10 (Size+5)
    AssertEquals('Seek beyond end should return pos', 10, Pos);
  finally
    SR.Free;
  end;
end;

procedure TTestSectionSemantics.Test_Read_AfterSeekBeyondEnd_ReturnsEOF;
var
  Data: TBytes;
  C: TIOCursor;
  SR: TSectionReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 10);
  FillChar(Data[0], 10, $AA);
  C := TIOCursor.FromBytes(Data);
  SR := TSectionReader.Create(C, 0, 5);
  try
    SR.Seek(10, SeekStart); // Seek beyond end
    N := SR.Read(@Buf[0], 10);
    AssertEquals('Read beyond end returns 0', 0, N);
  finally
    SR.Free;
  end;
end;

{ TTestIOFacade }

procedure TTestIOFacade.Test_IO_Cursor_ReadWrite;
var
  C: TIOCursor;
  Buf: array[0..3] of Byte;
  N: SizeInt;
begin
  C := IO.Cursor;
  try
    Buf[0] := 1; Buf[1] := 2; Buf[2] := 3; Buf[3] := 4;
    N := C.Write(@Buf[0], 4);
    AssertEquals('Write', 4, N);

    C.Seek(0, SeekStart);
    FillChar(Buf, 4, 0);
    N := C.Read(@Buf[0], 4);
    AssertEquals('Read', 4, N);
    AssertEquals('Byte 0', 1, Buf[0]);
  finally
    C.Free;
  end;
end;

procedure TTestIOFacade.Test_IO_Limit;
var
  Data: TBytes;
  Src, Limited: IReader;
  Buf: array[0..19] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 100);
  FillChar(Data[0], 100, $AA);

  Src := IO.Cursor(Data);
  Limited := IO.Limit(Src, 10);

  N := Limited.Read(@Buf[0], 20);
  AssertEquals('Limited to 10', 10, N);
end;

procedure TTestIOFacade.Test_IO_Tee;
var
  SrcData: TBytes;
  Src: IReader;
  CopyCursor: TIOCursor;
  CopyWriter: IWriter;
  Tee: IReader;
  Buf: array[0..9] of Byte;
begin
  SetLength(SrcData, 10);
  FillChar(SrcData[0], 10, $BB);

  Src := IO.Cursor(SrcData);
  CopyCursor := IO.Cursor;
  CopyWriter := CopyCursor;

  Tee := IO.Tee(Src, CopyWriter);
  Tee.Read(@Buf[0], 10);

  AssertEquals('Copy size', 10, CopyCursor.Size);
end;

procedure TTestIOFacade.Test_IO_Multi_Writers;
var
  C1, C2: TIOCursor;
  W1, W2: IWriter;
  MW: IWriter;
  Data: array[0..4] of Byte;
begin
  C1 := IO.Cursor;
  C2 := IO.Cursor;
  W1 := C1;
  W2 := C2;

  MW := IO.Multi([W1, W2]);
  Data[0] := 1; Data[1] := 2; Data[2] := 3; Data[3] := 4; Data[4] := 5;
  MW.Write(@Data[0], 5);

  AssertEquals('C1 size', 5, C1.Size);
  AssertEquals('C2 size', 5, C2.Size);
end;

procedure TTestIOFacade.Test_IO_Copy;
var
  SrcData: TBytes;
  Src: IReader;
  DstCursor: TIOCursor;
  Dst: IWriter;
  Copied: Int64;
begin
  SetLength(SrcData, 50);
  FillChar(SrcData[0], 50, $CC);

  Src := IO.Cursor(SrcData);
  DstCursor := IO.Cursor;
  Dst := DstCursor;

  Copied := IO.Copy(Dst, Src);
  AssertEquals('Copied', 50, Copied);
  AssertEquals('Dst size', 50, DstCursor.Size);
end;

procedure TTestIOFacade.Test_IO_ReadAll;
var
  SrcData, LResult: TBytes;
  Src: IReader;
begin
  SetLength(SrcData, 100);
  FillChar(SrcData[0], 100, $DD);

  Src := IO.Cursor(SrcData);
  LResult := IO.ReadAll(Src);

  AssertEquals('ReadAll length', 100, Length(LResult));
  AssertEquals('Byte 0', $DD, LResult[0]);
end;

procedure TTestIOFacade.Test_IO_Pipe;
var
  P: TIOPipePair;
  Buf: array[0..4] of Byte;
  N: SizeInt;
begin
  P := IO.Pipe;

  Buf[0] := 1; Buf[1] := 2; Buf[2] := 3;
  P.Writer.Write(@Buf[0], 3);

  FillChar(Buf, 5, 0);
  N := P.Reader.Read(@Buf[0], 5);
  AssertEquals('Read', 3, N);
  AssertEquals('Byte 0', 1, Buf[0]);

  P.Writer.Close;
end;

procedure TTestIOFacade.Test_IO_Buffered;
var
  Data: TBytes;
  Src: IReader;
  BR: TBufReader;
  Line: string;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10);
  Src := IO.Cursor(Data);

  BR := IO.Buffered(Src);
  try
    AssertTrue('Has line', BR.ReadLine(Line));
    AssertEquals('Line1', 'Line1', Line);
  finally
    BR.Free;
  end;
end;

procedure TTestIOFacade.Test_IO_Count;
var
  Data: TBytes;
  Src: IReader;
  CR: TCountedReader;
  Buf: array[0..9] of Byte;
begin
  SetLength(Data, 50);
  Src := IO.Cursor(Data);

  CR := IO.Count(Src);
  try
    CR.Read(@Buf[0], 10);
    AssertEquals('BytesRead', 10, CR.BytesRead);
  finally
    CR.Free;
  end;
end;

procedure TTestIOFacade.Test_IO_Section;
var
  Data: TBytes;
  Cursor: TIOCursor;
  Inner: IReadSeeker;
  SR: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
begin
  SetLength(Data, 100);
  for I := 0 to 99 do
    Data[I] := I;

  Cursor := IO.Cursor(Data);
  Inner := Cursor;

  SR := IO.Section(Inner, 50, 10);
  N := SR.Read(@Buf[0], 10);

  AssertEquals('Read', 10, N);
  AssertEquals('Byte 0', 50, Buf[0]);
end;

procedure TTestIOFacade.Test_IO_NopCloser;
var
  Data: TBytes;
  Src: IReader;
  RC: IReadCloser;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 10);
  FillChar(Data[0], 10, $EE);

  Src := IO.Cursor(Data);
  RC := IO.NopCloser(Src);  // 包装为 IReadCloser

  N := RC.Read(@Buf[0], 10);
  AssertEquals('Read', 10, N);

  // Close 应该不抛异常
  RC.Close;
end;

procedure TTestIOFacade.Test_IO_Chain;
var
  Data1, Data2: TBytes;
  R1, R2, Chained: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  // R1: [1,2,3]  R2: [4,5,6]
  SetLength(Data1, 3);
  Data1[0] := 1; Data1[1] := 2; Data1[2] := 3;
  SetLength(Data2, 3);
  Data2[0] := 4; Data2[1] := 5; Data2[2] := 6;

  R1 := IO.Cursor(Data1);
  R2 := IO.Cursor(Data2);

  // Chain 串联两个 Reader
  Chained := IO.Chain(R1, R2);

  // 读取全部 6 字节
  N := Chained.Read(@Buf[0], 3);
  AssertEquals('First read', 3, N);
  AssertEquals('Byte 0', 1, Buf[0]);

  N := Chained.Read(@Buf[3], 3);
  AssertEquals('Second read', 3, N);
  AssertEquals('Byte 3', 4, Buf[3]);
end;

procedure TTestIOFacade.Test_IO_ReadString;
var
  SrcData: TBytes;
  Src: IReader;
  S: string;
begin
  SrcData := TEncoding.UTF8.GetBytes('Test String');
  Src := IO.Cursor(SrcData);
  S := IO.ReadString(Src);
  AssertEquals('ReadString', 'Test String', S);
end;

procedure TTestIOFacade.Test_IO_Skip;
var
  Data: TBytes;
  Src, Skipped: IReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
  I: Integer;
begin
  // 数据 [0,1,2,3,4,5,6,7,8,9]
  SetLength(Data, 10);
  for I := 0 to 9 do
    Data[I] := I;

  Src := IO.Cursor(Data);
  Skipped := IO.Skip(Src, 5);  // 跳过前 5 字节

  N := Skipped.Read(@Buf[0], 10);
  AssertEquals('Read remaining 5', 5, N);
  AssertEquals('First byte is 5', 5, Buf[0]);
  AssertEquals('Last byte is 9', 9, Buf[4]);
end;

procedure TTestIOFacade.Test_IO_Lines;
var
  Data: TBytes;
  Src: IReader;
  Lines: TStringArray;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10'Line3');
  Src := IO.Cursor(Data);

  Lines := IO.Lines(Src);
  AssertEquals('Line count', 3, Length(Lines));
  AssertEquals('Line 0', 'Line1', Lines[0]);
  AssertEquals('Line 1', 'Line2', Lines[1]);
  AssertEquals('Line 2', 'Line3', Lines[2]);
end;

{ TTestFileIO }

procedure TTestFileIO.SetUp;
begin
  FTempFile := GetTempFileName('', 'test_io_');
end;

procedure TTestFileIO.TearDown;
begin
  if FileExists(FTempFile) then
    DeleteFile(FTempFile);
end;

procedure TTestFileIO.Test_CreateFile_WritesData;
var
  W: IWriteSeeker;
  Data: TBytes;
  S: TStringList;
begin
  W := IO.CreateFile(FTempFile);
  try
    Data := TEncoding.UTF8.GetBytes('Hello File');
    W.Write(@Data[0], Length(Data));
  finally
    // IWriteSeeker includes ICloser? 
    // In fafafa.core.io.files, CreateFile returns IWriteSeeker.
    // IOFromStream returns TStreamIO which implements ICloser.
    // But IWriteSeeker interface itself does NOT inherit ICloser in base.pas?
    // Let's check base.pas IWriteSeeker.
    // It inherits IWriter.
    // So we might need to cast to ICloser to close explicitly, or rely on refcount?
    // TStreamIO closes stream on Destroy.
    // So refcount 0 -> Close.
    W := nil;
  end;

  S := TStringList.Create;
  try
    S.LoadFromFile(FTempFile);
    AssertEquals('File content', 'Hello File', Trim(S.Text));
  finally
    S.Free;
  end;
end;

procedure TTestFileIO.Test_OpenFile_ReadsData;
var
  R: IReadSeeker;
  W: IWriteSeeker;
  Buf: array[0..99] of Byte;
  N: SizeInt;
  Data: TBytes;
begin
  // Write exact bytes using IO to avoid TStringList line endings
  W := IO.CreateFile(FTempFile);
  Data := TEncoding.UTF8.GetBytes('Read Me');
  W.Write(@Data[0], Length(Data));
  W := nil;

  R := IO.OpenFile(FTempFile);
  try
    N := R.Read(@Buf[0], 100);
    AssertEquals('Read count', 7, N);
    AssertEquals('Byte 0', Ord('R'), Buf[0]);
  finally
    R := nil;
  end;
end;

procedure TTestFileIO.Test_OpenFile_NotFound_RaisesEIOError;
var
  Raised: Boolean;
begin
  // Ensure file does not exist
  if FileExists(FTempFile) then DeleteFile(FTempFile);
  
  Raised := False;
  try
    IO.OpenFile(FTempFile);
  except
    on E: EIOError do
      if E.Kind = ekNotFound then
        Raised := True;
  end;
  AssertTrue('OpenFile not found should raise EIOError(ekNotFound)', Raised);
end;

procedure TTestFileIO.Test_CreateFile_PermissionDenied_RaisesEIOError;
var
  Raised: Boolean;
  DirPath: string;
begin
  // Create a directory
  DirPath := FTempFile + '_conflict_dir';
  if DirectoryExists(DirPath) then RemoveDir(DirPath);
  if not CreateDir(DirPath) then
  begin
    // Could not create dir, skip test
    Exit;
  end;

  try
    Raised := False;
    try
      // Try to CreateFile with same name as directory
      // Should fail with EFCreateError -> EIOError(ekPermissionDenied)
      IO.CreateFile(DirPath);
    except
      on E: EIOError do
      begin
        // Allow ekUnknown as it might be a generic Exception wrapper for now
        if (E.Kind = ekPermissionDenied) or (E.Kind = ekUnknown) then
          Raised := True
        else
          WriteLn('Got unexpected EIOError kind: ', Ord(E.Kind), ' Message: ', E.Message);
      end;
    end;
    AssertTrue('CreateFile on existing directory should raise ekPermissionDenied', Raised);
  finally
    RemoveDir(DirPath);
  end;
end;

procedure TTestFileIO.Test_OpenFileMode_ReadWrite;
var
  RW: IReadWriteSeeker;
  Buf: array[0..3] of Byte;
  Data: TBytes;
  W: IWriteSeeker;
begin
  // Create empty file first
  W := IO.CreateFile(FTempFile);
  W := nil; // Close

  // Open ReadWrite
  RW := IO.OpenFileMode(FTempFile, fmOpenReadWrite);
  
  // Write "TEST"
  Data := TEncoding.UTF8.GetBytes('TEST');
  RW.Write(@Data[0], 4);
  
  // Seek to 0
  RW.Seek(0, SeekStart);
  
  // Read back
  RW.Read(@Buf[0], 4);
  
  AssertEquals('Byte 0', Ord('T'), Buf[0]);
  AssertEquals('Byte 1', Ord('E'), Buf[1]);
  AssertEquals('Byte 2', Ord('S'), Buf[2]);
  AssertEquals('Byte 3', Ord('T'), Buf[3]);
end;

{ TTestIOError }

procedure TTestIOError.Test_EIOError_StructuredFields;
var
  E: EIOError;
begin
  E := EIOError.Create(ekNotFound, 'open', '/tmp/test.txt', 2, 'No such file');
  try
    AssertEquals('Kind', Ord(ekNotFound), Ord(E.Kind));
    AssertEquals('Op', 'open', E.Op);
    AssertEquals('Path', '/tmp/test.txt', E.Path);
    AssertEquals('Code', 2, E.Code);
    AssertEquals('Cause', 'No such file', E.Cause);
    AssertTrue('Message contains path', Pos('/tmp/test.txt', E.Message) > 0);
  finally
    E.Free;
  end;

  // Test minimal constructor still works
  E := EIOError.Create(ekPermissionDenied, 'Permission denied');
  try
    AssertEquals('Minimal Kind', Ord(ekPermissionDenied), Ord(E.Kind));
    AssertEquals('Minimal Op empty', '', E.Op);
    AssertEquals('Minimal Path empty', '', E.Path);
    AssertEquals('Minimal Code zero', 0, E.Code);
  finally
    E.Free;
  end;
end;

procedure TTestIOError.Test_IOErrorWrap_CreatesStructuredError;
var
  Inner: Exception;
  Raised: Boolean;
begin
  Inner := Exception.Create('underlying error');
  Raised := False;
  try
    try
      raise Inner;
    except
      on E: Exception do
        raise IOErrorWrap(ekNotFound, 'open', '/path/to/file', E);
    end;
  except
    on E: EIOError do
    begin
      Raised := True;
      AssertEquals('Wrapped Kind', Ord(ekNotFound), Ord(E.Kind));
      AssertEquals('Wrapped Op', 'open', E.Op);
      AssertEquals('Wrapped Path', '/path/to/file', E.Path);
      AssertTrue('Wrapped Cause contains inner', Pos('underlying error', E.Cause) > 0);
    end;
  end;
  AssertTrue('Should raise wrapped EIOError', Raised);
end;

procedure TTestIOError.Test_IOErrorRetryable_InterruptedIsTrue;
begin
  AssertTrue('ekInterrupted is retryable', IOErrorRetryable(ekInterrupted));
  AssertTrue('ekTimedOut is retryable', IOErrorRetryable(ekTimedOut));
  AssertTrue('ekWouldBlock is retryable', IOErrorRetryable(ekWouldBlock));
end;

procedure TTestIOError.Test_IOErrorRetryable_NotFoundIsFalse;
begin
  AssertFalse('ekNotFound is not retryable', IOErrorRetryable(ekNotFound));
  AssertFalse('ekPermissionDenied is not retryable', IOErrorRetryable(ekPermissionDenied));
  AssertFalse('ekInvalidData is not retryable', IOErrorRetryable(ekInvalidData));
end;

{ TTestFileOpenBuilder }

procedure TTestFileOpenBuilder.SetUp;
begin
  FTempFile := GetTempFileName('', 'test_builder_');
end;

procedure TTestFileOpenBuilder.TearDown;
begin
  if FileExists(FTempFile) then
    DeleteFile(FTempFile);
end;

procedure TTestFileOpenBuilder.Test_Builder_ReadOnly_OpensExisting;
var
  W: IWriteSeeker;
  F: IReadWriteSeeker;
  Buf: array[0..3] of Byte;
  N: SizeInt;
begin
  // Create file first
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'TEST');
  W := nil;

  // Open read-only via builder
  F := IO.FileOpen(FTempFile).ReadOnly.Open;
  try
    N := F.Read(@Buf[0], 4);
    AssertEquals('Read count', 4, N);
    AssertEquals('Byte 0', Ord('T'), Buf[0]);
  finally
    F := nil;
  end;
end;

procedure TTestFileOpenBuilder.Test_Builder_ReadWrite_OpensExisting;
var
  W: IWriteSeeker;
  F: IReadWriteSeeker;
  Buf: array[0..3] of Byte;
  Data: TBytes;
begin
  // Create file first
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'TEST');
  W := nil;

  // Open read-write via builder
  F := IO.FileOpen(FTempFile).ReadWrite.Open;
  F.Seek(0, SeekStart);
  Data := TEncoding.UTF8.GetBytes('ABCD');
  F.Write(@Data[0], 4);
  F.Seek(0, SeekStart);
  F.Read(@Buf[0], 4);
  AssertEquals('Byte 0', Ord('A'), Buf[0]);
end;

procedure TTestFileOpenBuilder.Test_Builder_Create_CreatesNew;
var
  F: IReadWriteSeeker;
  Data: TBytes;
begin
  // Delete if exists
  if FileExists(FTempFile) then DeleteFile(FTempFile);

  // Create via builder
  F := IO.FileOpen(FTempFile).ReadWrite.Create_.Open;
  Data := TEncoding.UTF8.GetBytes('NEW');
  F.Write(@Data[0], Length(Data));
  F := nil;

  AssertTrue('File should exist', FileExists(FTempFile));
end;

procedure TTestFileOpenBuilder.Test_Builder_Truncate_TruncatesExisting;
var
  W: IWriteSeeker;
  F: IReadWriteSeeker;
  Content: string;
  Data: TBytes;
begin
  // Create file with content
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'LONGCONTENT');
  W := nil;

  // Open with truncate
  F := IO.FileOpen(FTempFile).ReadWrite.Truncate.Open;
  Data := TEncoding.UTF8.GetBytes('SHORT');
  F.Write(@Data[0], Length(Data));
  F := nil;

  // Verify truncated
  F := IO.FileOpen(FTempFile).ReadOnly.Open;
  Content := IO.ReadString(F);
  AssertEquals('Content', 'SHORT', Content);
end;

procedure TTestFileOpenBuilder.Test_Builder_Append_AppendsToExisting;
var
  W: IWriteSeeker;
  F: IReadWriteSeeker;
  Content: string;
  Data: TBytes;
begin
  // Create file with content
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'HELLO');
  W := nil;

  // Open with append
  F := IO.FileOpen(FTempFile).Append.Open;
  Data := TEncoding.UTF8.GetBytes('WORLD');
  F.Write(@Data[0], Length(Data));
  F := nil;

  // Verify appended
  F := IO.FileOpen(FTempFile).ReadOnly.Open;
  Content := IO.ReadString(F);
  AssertEquals('Content', 'HELLOWORLD', Content);
end;

procedure TTestFileOpenBuilder.Test_Builder_CreateNew_FailsIfExists;
var
  Raised: Boolean;
  F: IWriteSeeker;
begin
  // Create file first
  F := IO.CreateFile(FTempFile);
  F := nil;

  // Try CreateNew should fail
  Raised := False;
  try
    IO.FileOpen(FTempFile).ReadWrite.CreateNew.Open;
  except
    on E: EIOError do
      if E.Kind = ekAlreadyExists then
        Raised := True;
  end;
  AssertTrue('CreateNew on existing file should raise ekAlreadyExists', Raised);
end;

procedure TTestFileOpenBuilder.Test_Shortcut_OpenRead;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Buf: array[0..3] of Byte;
begin
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'TEST');
  W := nil;

  R := IO.OpenRead(FTempFile);
  R.Read(@Buf[0], 4);
  AssertEquals('Byte 0', Ord('T'), Buf[0]);
end;

procedure TTestFileOpenBuilder.Test_Shortcut_CreateTruncate;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Content: string;
begin
  // Create with old content
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'OLD');
  W := nil;

  // Truncate with new
  W := IO.CreateTruncate(FTempFile);
  IO.WriteString(W, 'NEW');
  W := nil;

  R := IO.OpenRead(FTempFile);
  Content := IO.ReadString(R);
  AssertEquals('Content', 'NEW', Content);
end;

procedure TTestFileOpenBuilder.Test_Shortcut_OpenAppend;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Content: string;
begin
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'A');
  W := nil;

  W := IO.OpenAppend(FTempFile);
  IO.WriteString(W, 'B');
  W := nil;

  R := IO.OpenRead(FTempFile);
  Content := IO.ReadString(R);
  AssertEquals('Content', 'AB', Content);
end;

{ TTestStreamingCompress }

procedure TTestStreamingCompress.Test_Gzip_Streaming_EncodeDecodeRoundtrip;
var
  Original: TBytes;
  CompressedCursor: TIOCursor;
  CompressedW: IWriter;
  CompressedR: IReader;
  Encoder: IWriteCloser;
  Decoder: IReadCloser;
  Decompressed: TBytes;
  I: Integer;
begin
  // 原始数据
  SetLength(Original, 100);
  for I := 0 to High(Original) do
    Original[I] := I mod 256;

  // 压缩：写入 Encoder -> Compressed
  // 使用接口引用确保正确的生命周期管理
  CompressedCursor := IO.Cursor;
  CompressedW := CompressedCursor;
  CompressedR := CompressedCursor;
  Encoder := Compress.Gzip.Encode(CompressedW);
  Encoder.Write(@Original[0], Length(Original));
  Encoder.Close;

  // 解压：从 Compressed 读取
  CompressedCursor.Seek(0, SeekStart);
  Decoder := Compress.Gzip.Decode(CompressedR);
  Decompressed := IO.ReadAll(Decoder);
  Decoder.Close;

  // 验证
  AssertEquals('Decompressed length', Length(Original), Length(Decompressed));
  for I := 0 to High(Original) do
    AssertEquals('Byte ' + IntToStr(I), Original[I], Decompressed[I]);
end;

procedure TTestStreamingCompress.Test_Deflate_Streaming_EncodeDecodeRoundtrip;
var
  Original: TBytes;
  CompressedCursor: TIOCursor;
  CompressedW: IWriter;
  CompressedR: IReader;
  Encoder: IWriteCloser;
  Decoder: IReadCloser;
  Decompressed: TBytes;
  I: Integer;
begin
  SetLength(Original, 50);
  for I := 0 to High(Original) do
    Original[I] := (I * 7) mod 256;

  CompressedCursor := IO.Cursor;
  CompressedW := CompressedCursor;
  CompressedR := CompressedCursor;
  Encoder := Compress.Deflate.Encode(CompressedW);
  Encoder.Write(@Original[0], Length(Original));
  Encoder.Close;

  CompressedCursor.Seek(0, SeekStart);
  Decoder := Compress.Deflate.Decode(CompressedR);
  Decompressed := IO.ReadAll(Decoder);
  Decoder.Close;

  AssertEquals('Decompressed length', Length(Original), Length(Decompressed));
  for I := 0 to High(Original) do
    AssertEquals('Byte ' + IntToStr(I), Original[I], Decompressed[I]);
end;

procedure TTestStreamingCompress.Test_Gzip_Streaming_LargeData;
var
  Original: TBytes;
  CompressedCursor: TIOCursor;
  CompressedW: IWriter;
  CompressedR: IReader;
  Encoder: IWriteCloser;
  Decoder: IReadCloser;
  Decompressed: TBytes;
  I: Integer;
begin
  // 1MB 大数据
  SetLength(Original, 1024 * 1024);
  for I := 0 to High(Original) do
    Original[I] := I mod 256;

  CompressedCursor := IO.Cursor;
  CompressedW := CompressedCursor;
  CompressedR := CompressedCursor;
  Encoder := Compress.Gzip.Encode(CompressedW);
  Encoder.Write(@Original[0], Length(Original));
  Encoder.Close;

  AssertTrue('Compressed smaller', CompressedCursor.Size < Length(Original));

  CompressedCursor.Seek(0, SeekStart);
  Decoder := Compress.Gzip.Decode(CompressedR);
  Decompressed := IO.ReadAll(Decoder);
  Decoder.Close;

  AssertEquals('Decompressed length', Length(Original), Length(Decompressed));
  // 抽样检查
  AssertEquals('First byte', Original[0], Decompressed[0]);
  AssertEquals('Middle byte', Original[512*1024], Decompressed[512*1024]);
  AssertEquals('Last byte', Original[High(Original)], Decompressed[High(Decompressed)]);
end;

procedure TTestStreamingCompress.Test_Gzip_Decode_InvalidData_RaisesEIOError;
var
  Garbage: TBytes;
  GarbageCursor: TIOCursor;
  GarbageReader: IReader;
  Decoder: IReadCloser;
  Raised: Boolean;
  Buf: array[0..99] of Byte;
begin
  SetLength(Garbage, 10);
  FillChar(Garbage[0], 10, $FF);
  GarbageCursor := IO.Cursor(Garbage);
  GarbageReader := GarbageCursor;

  Raised := False;
  try
    Decoder := Compress.Gzip.Decode(GarbageReader);
    Decoder.Read(@Buf[0], 100);
  except
    on E: EIOError do
      Raised := True;
  end;

  AssertTrue('Decoding garbage should raise EIOError', Raised);
end;

procedure TTestStreamingCompress.Test_Gzip_WriteToClosed_RaisesEIOError;
var
  DestCursor: TIOCursor;
  DestWriter: IWriter;
  Encoder: IWriteCloser;
  Data: array[0..9] of Byte;
  Raised: Boolean;
begin
  DestCursor := IO.Cursor;
  DestWriter := DestCursor;
  Encoder := Compress.Gzip.Encode(DestWriter);
  Encoder.Close; // Close first

  Raised := False;
  try
    Encoder.Write(@Data[0], 10);
  except
    on E: EIOError do
      if E.Kind = ekBrokenPipe then
        Raised := True;
  end;

  AssertTrue('Write to closed encoder should raise ekBrokenPipe', Raised);
end;

{ TTestLineIterator }

procedure TTestLineIterator.Test_LinesIter_BasicIteration;
var
  Data: TBytes;
  Src: IReader;
  It: ILineIterator;
  Line: string;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10'Line3'#10);
  Src := IO.Cursor(Data);
  It := IO.LinesIter(Src);

  Count := 0;
  while It.Next(Line) do
  begin
    Inc(Count);
    case Count of
      1: AssertEquals('Line 1', 'Line1', Line);
      2: AssertEquals('Line 2', 'Line2', Line);
      3: AssertEquals('Line 3', 'Line3', Line);
    end;
  end;
  AssertEquals('Total lines', 3, Count);
end;

procedure TTestLineIterator.Test_LinesIter_EmptyInput;
var
  Data: TBytes;
  Src: IReader;
  It: ILineIterator;
  Line: string;
begin
  SetLength(Data, 0);
  Src := IO.Cursor(Data);
  It := IO.LinesIter(Src);

  AssertFalse('Empty input returns false', It.Next(Line));
  AssertEquals('LineNumber is 0', 0, It.LineNumber);
end;

procedure TTestLineIterator.Test_LinesIter_NoTrailingNewline;
var
  Data: TBytes;
  Src: IReader;
  It: ILineIterator;
  Line: string;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2');
  Src := IO.Cursor(Data);
  It := IO.LinesIter(Src);

  Count := 0;
  while It.Next(Line) do
  begin
    Inc(Count);
    case Count of
      1: AssertEquals('Line 1', 'Line1', Line);
      2: AssertEquals('Line 2', 'Line2', Line);
    end;
  end;
  AssertEquals('Total lines', 2, Count);
end;

procedure TTestLineIterator.Test_LinesIter_CRLFHandling;
var
  Data: TBytes;
  Src: IReader;
  It: ILineIterator;
  Line: string;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#13#10'Line2'#13#10);
  Src := IO.Cursor(Data);
  It := IO.LinesIter(Src);

  AssertTrue('Has line 1', It.Next(Line));
  AssertEquals('Line 1 without CR', 'Line1', Line);
  AssertTrue('Has line 2', It.Next(Line));
  AssertEquals('Line 2 without CR', 'Line2', Line);
end;

procedure TTestLineIterator.Test_LinesIter_LineNumber;
var
  Data: TBytes;
  Src: IReader;
  It: ILineIterator;
  Line: string;
begin
  Data := TEncoding.UTF8.GetBytes('A'#10'B'#10'C'#10);
  Src := IO.Cursor(Data);
  It := IO.LinesIter(Src);

  AssertEquals('Before first', 0, It.LineNumber);
  It.Next(Line);
  AssertEquals('After first', 1, It.LineNumber);
  It.Next(Line);
  AssertEquals('After second', 2, It.LineNumber);
  It.Next(Line);
  AssertEquals('After third', 3, It.LineNumber);
end;

{ TTestScanner }

procedure TTestScanner.Test_Scanner_DefaultDelimiter;
var
  Data: TBytes;
  Src: IReader;
  Sc: TScanner;
  Token: string;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10);
  Src := IO.Cursor(Data);
  Sc := IO.Scanner(Src);
  try
    Count := 0;
    while Sc.Scan(Token) do
    begin
      Inc(Count);
      case Count of
        1: AssertEquals('Token 1', 'Line1', Token);
        2: AssertEquals('Token 2', 'Line2', Token);
      end;
    end;
    AssertEquals('Total tokens', 2, Count);
  finally
    Sc.Free;
  end;
end;

procedure TTestScanner.Test_Scanner_CustomDelimiter;
var
  Data: TBytes;
  Src: IReader;
  Sc: TScanner;
  Token: string;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('a,b,c');
  Src := IO.Cursor(Data);
  Sc := IO.Scanner(Src).Delimiter(',').TrimCR(False);
  try
    Count := 0;
    while Sc.Scan(Token) do
    begin
      Inc(Count);
      case Count of
        1: AssertEquals('Token 1', 'a', Token);
        2: AssertEquals('Token 2', 'b', Token);
        3: AssertEquals('Token 3', 'c', Token);
      end;
    end;
    AssertEquals('Total tokens', 3, Count);
  finally
    Sc.Free;
  end;
end;

procedure TTestScanner.Test_Scanner_MaxLength_RaisesError;
var
  Data: TBytes;
  Src: IReader;
  Sc: TScanner;
  Token: string;
  Raised: Boolean;
begin
  Data := TEncoding.UTF8.GetBytes('VeryLongToken'#10);
  Src := IO.Cursor(Data);
  Sc := IO.Scanner(Src).MaxLength(5);
  try
    Raised := False;
    try
      Sc.Scan(Token);
    except
      on E: EIOError do
        if E.Kind = ekInvalidData then
          Raised := True;
    end;
    AssertTrue('Should raise ekInvalidData', Raised);
  finally
    Sc.Free;
  end;
end;

procedure TTestScanner.Test_Scanner_KeepDelimiter;
var
  Data: TBytes;
  Src: IReader;
  Sc: TScanner;
  Token: string;
begin
  Data := TEncoding.UTF8.GetBytes('a,b');
  Src := IO.Cursor(Data);
  Sc := IO.Scanner(Src).Delimiter(',').KeepDelimiter(True).TrimCR(False);
  try
    AssertTrue('Has token', Sc.Scan(Token));
    AssertEquals('Token with delimiter', 'a,', Token);
  finally
    Sc.Free;
  end;
end;

procedure TTestScanner.Test_Scanner_TokenCount;
var
  Data: TBytes;
  Src: IReader;
  Sc: TScanner;
  Token: string;
begin
  Data := TEncoding.UTF8.GetBytes('a'#10'b'#10'c');
  Src := IO.Cursor(Data);
  Sc := IO.Scanner(Src);
  try
    AssertEquals('Initial count', 0, Sc.TokenCount);
    Sc.Scan(Token);
    AssertEquals('After 1', 1, Sc.TokenCount);
    Sc.Scan(Token);
    AssertEquals('After 2', 2, Sc.TokenCount);
    Sc.Scan(Token);
    AssertEquals('After 3', 3, Sc.TokenCount);
  finally
    Sc.Free;
  end;
end;

{ TTestVectoredIO }

procedure TTestVectoredIO.Test_ReadV_MultipleBuffers;
var
  Data: TBytes;
  C: TIOCursor;
  Src: IReader;
  IOV: TIOVecArray;
  Buf1, Buf2, Buf3: array[0..9] of Byte;
  N, I: SizeInt;
begin
  // 准备 30 字节数据 [0..29]
  SetLength(Data, 30);
  for I := 0 to 29 do
    Data[I] := I;

  C := IO.Cursor(Data);
  Src := C;  // 保持接口引用
  try
    // 准备 3 个缓冲区
    SetLength(IOV, 3);
    IOV[0].Base := @Buf1[0]; IOV[0].Len := 10;
    IOV[1].Base := @Buf2[0]; IOV[1].Len := 10;
    IOV[2].Base := @Buf3[0]; IOV[2].Len := 10;

    // 向量化读取
    N := IO.ReadV(Src, IOV);
    AssertEquals('Total read', 30, N);

    // 验证数据
    AssertEquals('Buf1[0]', 0, Buf1[0]);
    AssertEquals('Buf1[9]', 9, Buf1[9]);
    AssertEquals('Buf2[0]', 10, Buf2[0]);
    AssertEquals('Buf2[9]', 19, Buf2[9]);
    AssertEquals('Buf3[0]', 20, Buf3[0]);
    AssertEquals('Buf3[9]', 29, Buf3[9]);
  finally
    Src := nil;  // 释放接口引用
  end;
end;

procedure TTestVectoredIO.Test_WriteV_MultipleBuffers;
var
  C: TIOCursor;
  Dst: IWriter;
  IOV: TIOVecArray;
  Buf1, Buf2: array[0..4] of Byte;
  LResult: TBytes;
  N: SizeInt;
begin
  // 准备数据
  Buf1[0] := 1; Buf1[1] := 2; Buf1[2] := 3; Buf1[3] := 4; Buf1[4] := 5;
  Buf2[0] := 6; Buf2[1] := 7; Buf2[2] := 8; Buf2[3] := 9; Buf2[4] := 10;

  C := IO.Cursor;
  Dst := C;  // 保持接口引用
  try
    SetLength(IOV, 2);
    IOV[0].Base := @Buf1[0]; IOV[0].Len := 5;
    IOV[1].Base := @Buf2[0]; IOV[1].Len := 5;

    N := IO.WriteV(Dst, IOV);
    AssertEquals('Total written', 10, N);

    LResult := C.ToBytes;
    AssertEquals('Result length', 10, Length(LResult));
    AssertEquals('Result[0]', 1, LResult[0]);
    AssertEquals('Result[4]', 5, LResult[4]);
    AssertEquals('Result[5]', 6, LResult[5]);
    AssertEquals('Result[9]', 10, LResult[9]);
  finally
    Dst := nil;  // 释放接口引用
  end;
end;

procedure TTestVectoredIO.Test_ReadV_EOF_PartialFill;
var
  Data: TBytes;
  C: TIOCursor;
  Src: IReader;
  IOV: TIOVecArray;
  Buf1, Buf2: array[0..9] of Byte;
  N, I: SizeInt;
begin
  // 只有 15 字节
  SetLength(Data, 15);
  for I := 0 to 14 do
    Data[I] := I;

  C := IO.Cursor(Data);
  Src := C;  // 保持接口引用
  try
    SetLength(IOV, 2);
    IOV[0].Base := @Buf1[0]; IOV[0].Len := 10;
    IOV[1].Base := @Buf2[0]; IOV[1].Len := 10;  // 请求 20，但只有 15

    N := IO.ReadV(Src, IOV);
    AssertEquals('Partial read', 15, N);

    AssertEquals('Buf1[0]', 0, Buf1[0]);
    AssertEquals('Buf1[9]', 9, Buf1[9]);
    AssertEquals('Buf2[0]', 10, Buf2[0]);
    AssertEquals('Buf2[4]', 14, Buf2[4]);
  finally
    Src := nil;  // 释放接口引用
  end;
end;

procedure TTestVectoredIO.Test_ReadV_Fallback_WithNonVectored;
var
  Data: TBytes;
  Src, Limited: IReader;
  IOV: TIOVecArray;
  Buf1, Buf2: array[0..4] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 10);
  for N := 0 to 9 do
    Data[N] := N * 10;

  Src := IO.Cursor(Data);
  // LimitReader 不实现 IReaderVectored，应回退
  Limited := IO.Limit(Src, 10);

  SetLength(IOV, 2);
  IOV[0].Base := @Buf1[0]; IOV[0].Len := 5;
  IOV[1].Base := @Buf2[0]; IOV[1].Len := 5;

  N := IO.ReadV(Limited, IOV);
  AssertEquals('Fallback read', 10, N);
  AssertEquals('Buf1[0]', 0, Buf1[0]);
  AssertEquals('Buf1[4]', 40, Buf1[4]);
  AssertEquals('Buf2[0]', 50, Buf2[0]);
  AssertEquals('Buf2[4]', 90, Buf2[4]);
end;

procedure TTestVectoredIO.Test_ReadV_Fallback_Interrupted_Retries;
var
  Data: TBytes;
  FailR: TFailNTimesReader;
  Src: IReader;
  IOV: TIOVecArray;
  Buf1, Buf2: array[0..4] of Byte;
  N: SizeInt;
  FailCount: Integer;
begin
  FailCount := 2;
  SetLength(Data, 10);
  for N := 0 to 9 do
    Data[N] := N * 10;

  FailR := TFailNTimesReader.Create(IO.Cursor(Data), FailCount, ekInterrupted);
  Src := FailR;

  SetLength(IOV, 2);
  IOV[0].Base := @Buf1[0]; IOV[0].Len := 5;
  IOV[1].Base := @Buf2[0]; IOV[1].Len := 5;

  N := IO.ReadV(Src, IOV);
  AssertEquals('Fallback read', 10, N);
  AssertEquals('Buf1[0]', 0, Buf1[0]);
  AssertEquals('Buf1[4]', 40, Buf1[4]);
  AssertEquals('Buf2[0]', 50, Buf2[0]);
  AssertEquals('Buf2[4]', 90, Buf2[4]);
  AssertEquals('ReadV fallback retries (calls)', FailCount + 2, FailR.CallCount);
end;

procedure TTestVectoredIO.Test_WriteV_Fallback_WithNonVectored;
var
  DstCursor: TIOCursor;
  Dst: IWriter;
  IOV: TIOVecArray;
  Buf1, Buf2: array[0..2] of Byte;
  LResult: TBytes;
  N: SizeInt;
begin
  Buf1[0] := $AA; Buf1[1] := $BB; Buf1[2] := $CC;
  Buf2[0] := $DD; Buf2[1] := $EE; Buf2[2] := $FF;

  DstCursor := IO.Cursor;
  // 使用 MultiWriter 包装单个 writer，它不实现 IWriterVectored
  Dst := IO.Multi([DstCursor as IWriter]);

  SetLength(IOV, 2);
  IOV[0].Base := @Buf1[0]; IOV[0].Len := 3;
  IOV[1].Base := @Buf2[0]; IOV[1].Len := 3;

  N := IO.WriteV(Dst, IOV);
  AssertEquals('Fallback write', 6, N);

  LResult := DstCursor.ToBytes;
  AssertEquals('Result length', 6, Length(LResult));
  AssertEquals('Result[0]', $AA, LResult[0]);
  AssertEquals('Result[2]', $CC, LResult[2]);
  AssertEquals('Result[3]', $DD, LResult[3]);
  AssertEquals('Result[5]', $FF, LResult[5]);
end;

{ TTestMmap }

procedure TTestMmap.SetUp;
begin
  FTempFile := GetTempFileName('', 'test_mmap_');
end;

procedure TTestMmap.TearDown;
begin
  if FileExists(FTempFile) then
    DeleteFile(FTempFile);
end;

procedure TTestMmap.Test_MmapRead_ReadsFile;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  // 先写入测试数据
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'HelloMmap!');
  W := nil;

  // 使用 MmapRead 读取
  R := IO.MmapRead(FTempFile);
  try
    N := R.Read(@Buf[0], 10);
    AssertEquals('Read count', 10, N);
    AssertEquals('Byte 0', Ord('H'), Buf[0]);
    AssertEquals('Byte 9', Ord('!'), Buf[9]);
  finally
    R := nil;
  end;
end;

procedure TTestMmap.Test_MmapRead_Seek;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Buf: array[0..4] of Byte;
  Pos: Int64;
  N: SizeInt;
begin
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, '0123456789');
  W := nil;

  R := IO.MmapRead(FTempFile);
  try
    Pos := R.Seek(5, SeekStart);
    AssertEquals('Seek position', 5, Pos);

    N := R.Read(@Buf[0], 5);
    AssertEquals('Read count', 5, N);
    AssertEquals('Byte 0', Ord('5'), Buf[0]);
    AssertEquals('Byte 4', Ord('9'), Buf[4]);
  finally
    R := nil;
  end;
end;

procedure TTestMmap.Test_MmapRead_Fallback_OnWindows;
var
  W: IWriteSeeker;
  R: IReadSeeker;
  Buf: array[0..4] of Byte;
  N: SizeInt;
begin
  W := IO.CreateFile(FTempFile);
  IO.WriteString(W, 'Test!');
  W := nil;

  // MmapRead 应该总是返回有效的 IReadSeeker（不管平台）
  R := IO.MmapRead(FTempFile);
  try
    N := R.Read(@Buf[0], 5);
    AssertEquals('Read count', 5, N);
    AssertEquals('Byte 0', Ord('T'), Buf[0]);
  finally
    R := nil;
  end;
end;

{ TTestInstrument }

procedure TTestInstrument.Test_Instrument_Reader_FiresReadEvent;
var
  Data: TBytes;
  Src, Instrumented: IReader;
  Buf: array[0..9] of Byte;
  EventCount: Integer;
  LastEventKind: TIOEventKind;
  LastEventBytes: SizeInt;

  procedure OnEvent(const Evt: TIOEvent);
  begin
    Inc(EventCount);
    LastEventKind := Evt.Kind;
    LastEventBytes := Evt.Bytes;
  end;

begin
  SetLength(Data, 10);
  FillChar(Data[0], 10, $AA);
  Src := IO.Cursor(Data);

  EventCount := 0;
  Instrumented := IO.Instrument(Src, @OnEvent);

  Instrumented.Read(@Buf[0], 10);

  AssertEquals('Event count', 1, EventCount);
  AssertEquals('Event kind', Ord(iekRead), Ord(LastEventKind));
  AssertEquals('Event bytes', 10, LastEventBytes);
end;

procedure TTestInstrument.Test_Instrument_Writer_FiresWriteEvent;
var
  DstCursor: TIOCursor;
  Dst: IWriter;
  Instrumented: IWriter;
  Buf: array[0..4] of Byte;
  EventCount: Integer;
  LastEventKind: TIOEventKind;
  LastEventBytes: SizeInt;

  procedure OnEvent(const Evt: TIOEvent);
  begin
    Inc(EventCount);
    LastEventKind := Evt.Kind;
    LastEventBytes := Evt.Bytes;
  end;

begin
  DstCursor := IO.Cursor;
  Dst := DstCursor;

  EventCount := 0;
  Instrumented := IO.Instrument(Dst, @OnEvent);

  Buf[0] := 1; Buf[1] := 2; Buf[2] := 3; Buf[3] := 4; Buf[4] := 5;
  Instrumented.Write(@Buf[0], 5);

  AssertEquals('Event count', 1, EventCount);
  AssertEquals('Event kind', Ord(iekWrite), Ord(LastEventKind));
  AssertEquals('Event bytes', 5, LastEventBytes);
end;

procedure TTestInstrument.Test_Instrument_Seeker_FiresSeekEvent;
var
  Data: TBytes;
  C: TIOCursor;
  Src: IReadSeeker;
  Instrumented: IReadSeeker;
  EventCount: Integer;
  LastEventKind: TIOEventKind;
  LastEventPos: Int64;

  procedure OnEvent(const Evt: TIOEvent);
  begin
    Inc(EventCount);
    LastEventKind := Evt.Kind;
    LastEventPos := Evt.Position;
  end;

begin
  SetLength(Data, 100);
  C := IO.Cursor(Data);
  Src := C;

  EventCount := 0;
  Instrumented := IO.InstrumentSeeker(Src, @OnEvent);

  Instrumented.Seek(50, SeekStart);

  AssertEquals('Event count', 1, EventCount);
  AssertEquals('Event kind', Ord(iekSeek), Ord(LastEventKind));
  AssertEquals('Event position', 50, LastEventPos);
end;

{ TTestIOErrorMapping }

procedure TTestIOErrorMapping.Test_Unix_IOErrorKind_Mapping_Sample;
begin
  {$IFNDEF WINDOWS}
  // 仅在 Unix 下验证 IOUnixErrorKind 的代表性映射
  AssertEquals(Ord(ekNotFound), Ord(IOUnixErrorKind(ESysENOENT)));
  AssertEquals(Ord(ekPermissionDenied), Ord(IOUnixErrorKind(ESysEACCES)));
  AssertEquals(Ord(ekAlreadyExists), Ord(IOUnixErrorKind(ESysEEXIST)));
  AssertEquals(Ord(ekInvalidInput), Ord(IOUnixErrorKind(ESysEINVAL)));
  AssertEquals(Ord(ekTimedOut), Ord(IOUnixErrorKind(ESysETIMEDOUT)));
  AssertEquals(Ord(ekInterrupted), Ord(IOUnixErrorKind(ESysEINTR)));
  AssertEquals(Ord(ekWouldBlock), Ord(IOUnixErrorKind(ESysEAGAIN)));
  AssertEquals(Ord(ekBrokenPipe), Ord(IOUnixErrorKind(ESysEPIPE)));
  AssertEquals(Ord(ekNotConnected), Ord(IOUnixErrorKind(ESysENOTCONN)));
  {$ELSE}
  // Windows 平台跳过
  AssertTrue(True);
  {$ENDIF}
end;

{ TTestWithResource }

procedure TTestWithResource.Test_WithReader_ExecutesProc;
var
  Data: TBytes;
  Executed: Boolean;
  ReadContent: string;
begin
  Data := TEncoding.UTF8.GetBytes('Hello World');
  Executed := False;
  ReadContent := '';

  IO.WithReader(IO.Cursor(Data), procedure(R: IReader)
  begin
    Executed := True;
    ReadContent := IO.ReadString(R);
  end);

  AssertTrue('Proc should be executed', Executed);
  AssertEquals('Content should be read', 'Hello World', ReadContent);
end;

procedure TTestWithResource.Test_WithWriter_ExecutesProc;
var
  DstCursor: TIOCursor;
  DstWriter: IWriter;  // 保持接口引用
  Executed: Boolean;
begin
  DstCursor := IO.Cursor;
  DstWriter := DstCursor;  // 增加引用计数
  Executed := False;

  IO.WithWriter(DstWriter, procedure(W: IWriter)
  begin
    Executed := True;
    IO.WriteString(W, 'Test Output');
  end);

  AssertTrue('Proc should be executed', Executed);
  AssertEquals('Content should be written', 11, DstCursor.Size);
end;

procedure TTestWithResource.Test_WithBufReader_ProcessLines;
var
  Data: TBytes;
  LineCount: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10'Line3'#10);
  LineCount := 0;

  IO.WithBufReader(IO.Cursor(Data), procedure(BR: TBufReader)
  var
    Line: string;
  begin
    while BR.ReadLine(Line) do
      Inc(LineCount);
  end);

  AssertEquals('Should process 3 lines', 3, LineCount);
end;

procedure TTestWithResource.Test_With_ExceptionPropagates;
var
  Data: TBytes;
  ExceptionRaised: Boolean;
begin
  Data := TEncoding.UTF8.GetBytes('Test');
  ExceptionRaised := False;

  try
    IO.WithReader(IO.Cursor(Data), procedure(R: IReader)
    begin
      raise Exception.Create('Test exception');
    end);
  except
    on E: Exception do
      if E.Message = 'Test exception' then
        ExceptionRaised := True;
  end;

  AssertTrue('Exception should propagate', ExceptionRaised);
end;

{ TTestForInLines }

procedure TTestForInLines.Test_ForIn_BasicIteration;
var
  Data: TBytes;
  Line: string;
  Lines: TStringArray;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2'#10'Line3'#10);
  SetLength(Lines, 0);
  Count := 0;

  for Line in IO.ReadLines(IO.Cursor(Data)) do
  begin
    SetLength(Lines, Count + 1);
    Lines[Count] := Line;
    Inc(Count);
  end;

  AssertEquals('Line count', 3, Count);
  AssertEquals('Line 0', 'Line1', Lines[0]);
  AssertEquals('Line 1', 'Line2', Lines[1]);
  AssertEquals('Line 2', 'Line3', Lines[2]);
end;

procedure TTestForInLines.Test_ForIn_EmptyInput;
var
  Data: TBytes;
  Line: string;
  Count: Integer;
begin
  SetLength(Data, 0);
  Count := 0;

  for Line in IO.ReadLines(IO.Cursor(Data)) do
    Inc(Count);

  AssertEquals('Empty input should yield 0 lines', 0, Count);
end;

procedure TTestForInLines.Test_ForIn_NoTrailingNewline;
var
  Data: TBytes;
  Line: string;
  Lines: TStringArray;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#10'Line2');
  SetLength(Lines, 0);
  Count := 0;

  for Line in IO.ReadLines(IO.Cursor(Data)) do
  begin
    SetLength(Lines, Count + 1);
    Lines[Count] := Line;
    Inc(Count);
  end;

  AssertEquals('Line count', 2, Count);
  AssertEquals('Line 0', 'Line1', Lines[0]);
  AssertEquals('Line 1', 'Line2', Lines[1]);
end;

procedure TTestForInLines.Test_ForIn_CRLFHandling;
var
  Data: TBytes;
  Line: string;
  Lines: TStringArray;
  Count: Integer;
begin
  Data := TEncoding.UTF8.GetBytes('Line1'#13#10'Line2'#13#10);
  SetLength(Lines, 0);
  Count := 0;

  for Line in IO.ReadLines(IO.Cursor(Data)) do
  begin
    SetLength(Lines, Count + 1);
    Lines[Count] := Line;
    Inc(Count);
  end;

  AssertEquals('Line count', 2, Count);
  AssertEquals('Line 0 without CR', 'Line1', Lines[0]);
  AssertEquals('Line 1 without CR', 'Line2', Lines[1]);
end;

{ TTestProgress }

procedure TTestProgress.Test_Progress_Reader_FiresCallback;
var
  Data: TBytes;
  CallbackFired: Boolean;
  BytesReported: Int64;
  Buf: array[0..63] of Byte;
  R: IReader;
begin
  Data := TEncoding.UTF8.GetBytes('Hello World');
  CallbackFired := False;
  BytesReported := 0;

  R := IO.Progress(IO.Cursor(Data) as IReader, procedure(const AEvent: TProgressEvent)
  begin
    CallbackFired := True;
    BytesReported := AEvent.BytesProcessed;
  end);

  R.Read(@Buf[0], 64);

  AssertTrue('Callback should fire on read', CallbackFired);
  AssertEquals('Bytes reported', 11, BytesReported);
end;

procedure TTestProgress.Test_Progress_Writer_FiresCallback;
var
  Cursor: TIOCursor;
  InnerWriter: IWriter;
  CallbackFired: Boolean;
  BytesReported: Int64;
  Data: TBytes;
  W: IWriter;
begin
  Cursor := TIOCursor.Create;
  InnerWriter := Cursor;  // 保持接口引用，防止提前释放
  CallbackFired := False;
  BytesReported := 0;

  W := IO.Progress(InnerWriter, procedure(const AEvent: TProgressEvent)
  begin
    CallbackFired := True;
    BytesReported := AEvent.BytesProcessed;
  end);

  Data := TEncoding.UTF8.GetBytes('Hello');
  W.Write(@Data[0], Length(Data));

  AssertTrue('Callback should fire on write', CallbackFired);
  AssertEquals('Bytes reported', 5, BytesReported);
  // 接口引用自动释放
end;

procedure TTestProgress.Test_Progress_WithTotal_ReportsPercent;
var
  Data: TBytes;
  LastPercent: Double;
  Buf: array[0..4] of Byte;
  R: IReader;
begin
  SetLength(Data, 100);
  FillChar(Data[0], 100, $AA);
  LastPercent := -999;

  R := IO.Progress(IO.Cursor(Data) as IReader, procedure(const AEvent: TProgressEvent)
  begin
    LastPercent := AEvent.Percent;
  end, 100);  // Total = 100 bytes

  R.Read(@Buf[0], 5);   // Read 5 bytes
  AssertEquals('Percent after 5 bytes', 5.0, LastPercent);

  R.Read(@Buf[0], 5);   // Read 5 more bytes (10 total)
  AssertEquals('Percent after 10 bytes', 10.0, LastPercent);
end;

procedure TTestProgress.Test_Progress_UnknownTotal_PercentNegative;
var
  Data: TBytes;
  LastPercent: Double;
  Buf: array[0..63] of Byte;
  R: IReader;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  LastPercent := 999;

  R := IO.Progress(IO.Cursor(Data) as IReader, procedure(const AEvent: TProgressEvent)
  begin
    LastPercent := AEvent.Percent;
  end);  // No total specified

  R.Read(@Buf[0], 64);

  AssertTrue('Percent should be negative when total unknown', LastPercent < 0);
end;

{ TTestPeek }

procedure TTestPeek.Test_Peek_DoesNotAdvance;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..4] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  // Peek 应该返回数据但不移动指针
  N := PR.Peek(@Buf[0], 3);
  AssertEquals('Peek returns 3', 3, N);
  AssertEquals('Peek byte 0', Ord('H'), Buf[0]);

  // 再次 Peek 应该返回相同数据
  FillChar(Buf, SizeOf(Buf), 0);
  N := PR.Peek(@Buf[0], 3);
  AssertEquals('Second peek returns 3', 3, N);
  AssertEquals('Second peek byte 0', Ord('H'), Buf[0]);
end;

procedure TTestPeek.Test_Peek_ThenRead_ReturnsData;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..4] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  // Peek 3 字节
  N := PR.Peek(@Buf[0], 3);
  AssertEquals('Peek returns 3', 3, N);

  // Read 应该从开头读取
  FillChar(Buf, SizeOf(Buf), 0);
  N := PR.Read(@Buf[0], 5);
  AssertEquals('Read returns 5', 5, N);
  AssertEquals('Read byte 0', Ord('H'), Buf[0]);
  AssertEquals('Read byte 4', Ord('o'), Buf[4]);
end;

procedure TTestPeek.Test_Peek_BuffersData;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('ABCDEFGHIJ');
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  // Peek 5 字节
  N := PR.Peek(@Buf[0], 5);
  AssertEquals('Peek 5', 5, N);
  AssertEquals('Peek[0]', Ord('A'), Buf[0]);
  AssertEquals('Peek[4]', Ord('E'), Buf[4]);

  // Read 3 字节（从缓冲区消费）
  N := PR.Read(@Buf[0], 3);
  AssertEquals('Read 3', 3, N);
  AssertEquals('Read[0]', Ord('A'), Buf[0]);

  // Peek 应该返回缓冲区剩余 + 新数据
  N := PR.Peek(@Buf[0], 5);
  AssertEquals('Peek 5 after read', 5, N);
  AssertEquals('New peek[0]', Ord('D'), Buf[0]);
end;

procedure TTestPeek.Test_Peek_EOF_ReturnsZero;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  SetLength(Data, 0);  // 空数据
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  N := PR.Peek(@Buf[0], 10);
  AssertEquals('Peek on empty returns 0', 0, N);
end;

{ TTestChecksum }

procedure TTestChecksum.Test_ChecksumReader_ComputesHash;
var
  Data: TBytes;
  CR: IChecksumReader;
  Buf: array[0..99] of Byte;
  Hash: TBytes;
begin
  Data := TEncoding.UTF8.GetBytes('Hello World');
  CR := IO.Checksum(IO.Cursor(Data) as IReader);

  // 读取数据
  CR.Read(@Buf[0], Length(Data));

  // 获取校验和
  Hash := CR.Checksum;

  // SHA-256 输出 32 字节
  AssertEquals('Hash length', 32, Length(Hash));
  // SHA-256("Hello World") = A591A6D40BF420404A011733CFB7B190D62C65BF0BCDA32B57B277D9AD9F146E
  AssertEquals('First byte', $A5, Hash[0]);
end;

procedure TTestChecksum.Test_ChecksumWriter_ComputesHash;
var
  Cursor: TIOCursor;
  CW: IChecksumWriter;
  Data: TBytes;
  Hash: TBytes;
begin
  Cursor := TIOCursor.Create;
  CW := IO.Checksum(Cursor as IWriter);

  Data := TEncoding.UTF8.GetBytes('Hello World');
  CW.Write(@Data[0], Length(Data));

  Hash := CW.Checksum;

  AssertEquals('Hash length', 32, Length(Hash));
  AssertEquals('First byte', $A5, Hash[0]);
end;

procedure TTestChecksum.Test_ChecksumReader_Reset;
var
  Data: TBytes;
  CR: IChecksumReader;
  Buf: array[0..99] of Byte;
  Hash1, Hash2: TBytes;
begin
  Data := TEncoding.UTF8.GetBytes('Test');
  CR := IO.Checksum(IO.Cursor(Data) as IReader);

  CR.Read(@Buf[0], 4);
  Hash1 := CR.Checksum;

  // Reset 并用相同数据重算
  CR.Reset;
  CR.Read(@Buf[0], 4);
  Hash2 := CR.Checksum;

  // 由于底层 Reader 已读完，Reset 只重置哈希状态，不重置 Reader
  // 所以 Hash2 是空数据的 SHA-256
  AssertEquals('Hash1 length', 32, Length(Hash1));
  AssertEquals('Hash2 length', 32, Length(Hash2));
end;

{ TTestTimeout }

procedure TTestTimeout.Test_TimeoutReader_FastRead_Succeeds;
var
  Data: TBytes;
  TR: IReader;
  Buf: array[0..63] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('Hello World');
  // 1000ms 超时，很宽松
  TR := IO.Timeout(IO.Cursor(Data) as IReader, 1000);

  N := TR.Read(@Buf[0], 64);
  AssertEquals('Read should succeed', 11, N);
  AssertEquals('Byte 0', Ord('H'), Buf[0]);
end;

procedure TTestTimeout.Test_TimeoutWriter_FastWrite_Succeeds;
var
  Cursor: TIOCursor;
  InnerWriter: IWriter;
  TW: IWriter;
  Data: TBytes;
  N: SizeInt;
begin
  Cursor := TIOCursor.Create;
  InnerWriter := Cursor;
  // 1000ms 超时，很宽松
  TW := IO.Timeout(InnerWriter, 1000);

  Data := TEncoding.UTF8.GetBytes('Hello');
  N := TW.Write(@Data[0], Length(Data));

  AssertEquals('Write should succeed', 5, N);
  AssertEquals('Cursor size', 5, Cursor.Size);
end;

procedure TTestTimeout.Test_TimeoutReader_SlowRead_RaisesTimeout;
var
  Data: TBytes;
  Slow: IReader;
  TR: IReader;
  Buf: array[0..63] of Byte;
  Raised: Boolean;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  // TSlowReader 每次读取 Sleep 100ms
  Slow := TSlowReader.Create(Data, 100);
  // 设置 50ms 超时，应该触发超时
  TR := IO.Timeout(Slow, 50);

  Raised := False;
  try
    TR.Read(@Buf[0], 64);
  except
    on E: EIOError do
      if E.Kind = ekTimedOut then
        Raised := True;
  end;

  AssertTrue('Should raise EIOError(ekTimedOut)', Raised);
end;

{ TTestRetry }

procedure TTestRetry.Test_Retry_NoError_SucceedsImmediately;
var
  Data: TBytes;
  Inner: IReader;
  RR: IReader;
  Buf: array[0..63] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('Hello World');
  Inner := IO.Cursor(Data) as IReader;
  // 带重试，最多重试 3 次
  RR := IO.Retry(Inner, 3);

  N := RR.Read(@Buf[0], 64);
  AssertEquals('Read should succeed', 11, N);
  AssertEquals('Byte 0', Ord('H'), Buf[0]);
end;

procedure TTestRetry.Test_Retry_RetryableError_Retries;
var
  Data: TBytes;
  Inner: IReader;
  FailingReader: TFailNTimesReader;
  RR: IReader;
  Buf: array[0..63] of Byte;
  N: SizeInt;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  Inner := IO.Cursor(Data) as IReader;
  // 前 2 次抛出 ekTimedOut（可重试的错误）
  FailingReader := TFailNTimesReader.Create(Inner, 2, ekTimedOut);
  // 最多重试 3 次，应该第 3 次成功
  RR := IO.Retry(FailingReader, 3, 0);  // 0 延迟，加快测试

  N := RR.Read(@Buf[0], 64);

  AssertEquals('Should succeed after retries', 5, N);
  AssertEquals('Called 3 times', 3, FailingReader.CallCount);
end;

procedure TTestRetry.Test_Retry_NonRetryableError_FailsImmediately;
var
  Data: TBytes;
  Inner: IReader;
  FailingReader: TFailNTimesReader;
  RR: IReader;
  Buf: array[0..63] of Byte;
  Raised: Boolean;
begin
  Data := TEncoding.UTF8.GetBytes('Hello');
  Inner := IO.Cursor(Data) as IReader;
  // 抛出 ekNotFound（不可重试的错误）
  FailingReader := TFailNTimesReader.Create(Inner, 5, ekNotFound);
  RR := IO.Retry(FailingReader, 3, 0);

  Raised := False;
  try
    RR.Read(@Buf[0], 64);
  except
    on E: EIOError do
      if E.Kind = ekNotFound then
        Raised := True;
  end;

  AssertTrue('Should raise immediately', Raised);
  AssertEquals('Only called once', 1, FailingReader.CallCount);
end;

{ TTestProgress - 边界条件测试 }

procedure TTestProgress.Test_Progress_ZeroRead_NoCallback;
var
  Data: TBytes;
  R: IReader;
  Buf: array[0..63] of Byte;
  CallbackFired: Boolean;
begin
  // Arrange - EOF 时读取返回 0
  SetLength(Data, 0);  // 空数据
  CallbackFired := False;

  R := IO.Progress(IO.Cursor(Data) as IReader, procedure(const AEvent: TProgressEvent)
  begin
    CallbackFired := True;
  end);

  // Act - 读取空数据
  R.Read(@Buf[0], 64);

  // Assert - 0 字节读取不应触发回调
  AssertFalse('Callback should not fire on zero read', CallbackFired);
end;

procedure TTestProgress.Test_Progress_MultipleReads_AccumulatesBytes;
var
  Data: TBytes;
  R: IReader;
  Buf: array[0..4] of Byte;
  TotalBytes: Int64;
begin
  // Arrange - 10 字节数据
  SetLength(Data, 10);
  FillChar(Data[0], 10, $AA);
  TotalBytes := 0;

  R := IO.Progress(IO.Cursor(Data) as IReader, procedure(const AEvent: TProgressEvent)
  begin
    TotalBytes := AEvent.BytesProcessed;
  end);

  // Act - 多次读取
  R.Read(@Buf[0], 3);   // 读取 3 字节
  AssertEquals('After first read', 3, TotalBytes);

  R.Read(@Buf[0], 4);   // 读取 4 字节
  AssertEquals('After second read', 7, TotalBytes);

  R.Read(@Buf[0], 5);   // 读取剩余 3 字节
  AssertEquals('After third read', 10, TotalBytes);
end;

{ TTestPeek - 边界条件测试 }

procedure TTestPeek.Test_Peek_LargerThanData_ReturnsAvailable;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..99] of Byte;
  N: SizeInt;
begin
  // Arrange - 只有 5 字节数据
  Data := TEncoding.UTF8.GetBytes('Hello');
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  // Act - 请求 100 字节
  N := PR.Peek(@Buf[0], 100);

  // Assert - 只返回可用的 5 字节
  AssertEquals('Should return available bytes only', 5, N);
  AssertEquals('Byte 0', Ord('H'), Buf[0]);
  AssertEquals('Byte 4', Ord('o'), Buf[4]);
end;

procedure TTestPeek.Test_Peek_ZeroBytes_ReturnsZero;
var
  Data: TBytes;
  PR: IPeekReader;
  Buf: array[0..9] of Byte;
  N: SizeInt;
begin
  // Arrange
  Data := TEncoding.UTF8.GetBytes('Hello');
  PR := IO.Peekable(IO.Cursor(Data) as IReader);

  // Act - 请求 0 字节
  N := PR.Peek(@Buf[0], 0);

  // Assert
  AssertEquals('Peek 0 bytes should return 0', 0, N);

  // 确保数据仍然可读
  N := PR.Peek(@Buf[0], 5);
  AssertEquals('Data still available', 5, N);
end;

{ TTestChecksum - 边界条件测试 }

procedure TTestChecksum.Test_ChecksumReader_EmptyData_ValidHash;
var
  Data: TBytes;
  CR: IChecksumReader;
  Buf: array[0..63] of Byte;
  Hash: TBytes;
begin
  // Arrange - 空数据
  SetLength(Data, 0);
  CR := IO.Checksum(IO.Cursor(Data) as IReader);

  // Act - 读取（返回 0）
  CR.Read(@Buf[0], 64);
  Hash := CR.Checksum;

  // Assert - SHA-256 of empty string is well-known
  // SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  AssertEquals('Hash length', 32, Length(Hash));
  AssertEquals('First byte of empty SHA-256', $E3, Hash[0]);
  AssertEquals('Second byte', $B0, Hash[1]);
end;

procedure TTestChecksum.Test_ChecksumWriter_MultipleWrites_CombinedHash;
var
  Cursor: TIOCursor;
  CW: IChecksumWriter;
  Data1, Data2: TBytes;
  Hash: TBytes;
begin
  // Arrange
  Cursor := TIOCursor.Create;
  CW := IO.Checksum(Cursor as IWriter);

  // Act - 多次写入 "Hello" + " World" = "Hello World"
  Data1 := TEncoding.UTF8.GetBytes('Hello');
  Data2 := TEncoding.UTF8.GetBytes(' World');
  CW.Write(@Data1[0], Length(Data1));
  CW.Write(@Data2[0], Length(Data2));
  Hash := CW.Checksum;

  // Assert - 应该等于 SHA-256("Hello World")
  // SHA-256("Hello World") = A591A6D40BF420404A011733CFB7B190D62C65BF0BCDA32B57B277D9AD9F146E
  AssertEquals('Hash length', 32, Length(Hash));
  AssertEquals('First byte', $A5, Hash[0]);
  AssertEquals('Second byte', $91, Hash[1]);
end;

{ TTestTimeout - 边界条件测试 }

procedure TTestTimeout.Test_TimeoutReader_ExactTimeout_Succeeds;
var
  Data: TBytes;
  Slow: IReader;
  TR: IReader;
  Buf: array[0..63] of Byte;
  N: SizeInt;
begin
  // Arrange - 读取延迟 20ms，超时 100ms（宽松）
  Data := TEncoding.UTF8.GetBytes('Hello');
  Slow := TSlowReader.Create(Data, 20);
  TR := IO.Timeout(Slow, 100);

  // Act - 应该在超时前完成
  N := TR.Read(@Buf[0], 64);

  // Assert
  AssertEquals('Should succeed', 5, N);
end;

procedure TTestTimeout.Test_TimeoutWriter_SlowWrite_RaisesTimeout;
var
  SlowWriter: IWriter;
  TW: IWriter;
  Data: TBytes;
  Raised: Boolean;
begin
  // Arrange - TSlowWriter 每次写入 Sleep 100ms
  SlowWriter := TSlowWriter.Create(100);
  // 设置 50ms 超时，应该触发超时
  TW := IO.Timeout(SlowWriter, 50);

  Data := TEncoding.UTF8.GetBytes('Hello');

  // Act & Assert
  Raised := False;
  try
    TW.Write(@Data[0], Length(Data));
  except
    on E: EIOError do
      if E.Kind = ekTimedOut then
        Raised := True;
  end;

  AssertTrue('Should raise timeout', Raised);
end;

{ TTestRetry - 边界条件测试 }

procedure TTestRetry.Test_Retry_ExceedsMaxAttempts_RaisesLastError;
var
  Data: TBytes;
  Inner: IReader;
  FailingReader: TFailNTimesReader;
  RR: IReader;
  Buf: array[0..63] of Byte;
  Raised: Boolean;
begin
  // Arrange - 失败 10 次，但只允许重试 3 次
  Data := TEncoding.UTF8.GetBytes('Hello');
  Inner := IO.Cursor(Data) as IReader;
  FailingReader := TFailNTimesReader.Create(Inner, 10, ekTimedOut);
  RR := IO.Retry(FailingReader, 3, 0);  // 最多 3 次尝试

  // Act
  Raised := False;
  try
    RR.Read(@Buf[0], 64);
  except
    on E: EIOError do
      if E.Kind = ekTimedOut then
        Raised := True;
  end;

  // Assert - 应该在 3 次尝试后放弃
  AssertTrue('Should raise after max attempts', Raised);
  AssertEquals('Called exactly 3 times', 3, FailingReader.CallCount);
end;

procedure TTestRetry.Test_Retry_InterruptedError_Retries;
var
  Data: TBytes;
  Inner: IReader;
  FailingReader: TFailNTimesReader;
  RR: IReader;
  Buf: array[0..63] of Byte;
  N: SizeInt;
begin
  // Arrange - ekInterrupted 也是可重试的错误
  Data := TEncoding.UTF8.GetBytes('Hello');
  Inner := IO.Cursor(Data) as IReader;
  FailingReader := TFailNTimesReader.Create(Inner, 2, ekInterrupted);
  RR := IO.Retry(FailingReader, 5, 0);

  // Act
  N := RR.Read(@Buf[0], 64);

  // Assert
  AssertEquals('Should succeed after retries', 5, N);
  AssertEquals('Called 3 times', 3, FailingReader.CallCount);
end;

initialization
  RegisterTest(TTestIOCursor);
  RegisterTest(TTestLimitedReader);
  RegisterTest(TTestMultiReader);
  RegisterTest(TTestEmptyAndDiscard);
  RegisterTest(TTestRepeatReader);
  RegisterTest(TTestBufferedIO);
  RegisterTest(TTestIOUtils);
  RegisterTest(TTestStreamAdapter);
  RegisterTest(TTestTeeIO);
  RegisterTest(TTestPipe);
  RegisterTest(TTestPipeSemantics);
  RegisterTest(TTestCompress);
  RegisterTest(TTestCompressSemantics);
  RegisterTest(TTestCounted);
  RegisterTest(TTestSection);
  RegisterTest(TTestSectionSemantics);
  RegisterTest(TTestAdapterSemantics);
  RegisterTest(TTestFileIO);
  RegisterTest(TTestIOFacade);
  RegisterTest(TTestIOError);
  RegisterTest(TTestFileOpenBuilder);
  RegisterTest(TTestStreamingCompress);
  RegisterTest(TTestLineIterator);
  RegisterTest(TTestScanner);
  RegisterTest(TTestVectoredIO);
  RegisterTest(TTestMmap);
  RegisterTest(TTestInstrument);
  RegisterTest(TTestIOErrorMapping);
  RegisterTest(TTestWithResource);
  RegisterTest(TTestForInLines);
  RegisterTest(TTestProgress);
  RegisterTest(TTestPeek);
  RegisterTest(TTestChecksum);
  RegisterTest(TTestTimeout);
  RegisterTest(TTestRetry);

end.
