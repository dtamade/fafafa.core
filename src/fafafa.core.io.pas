unit fafafa.core.io;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io - 流式 IO 抽象层（门面模块）

  API 稳定性声明 (v1.0)
  =======================
  本模块 API 已稳定，遵循语义化版本控制：
  - 稳定 API：IO.* 门面方法、核心 trait (IReader/IWriter/ISeeker/ICloser/IFlusher)
  - 稳定 API：组合 trait (IReadSeeker/IWriteSeeker/IReadWriteSeeker/IReadCloser/...)
  - 稳定 API：TIOCursor, TBufReader, TBufWriter, TFileOpenBuilder
  - 稳定 API：惰性迭代 IO.LinesIter/IO.Scanner
  - 稳定 API：向量化 I/O (IReaderVectored/IWriterVectored), 观测 IO.Instrument
  - 实验 API：IO.MmapRead (Unix mmap, Windows 自动回退)

  弃用与迁移指南
  ==============
  IByteReader / IByteWriter (已移除)
    - 弃用版本：v0.9
    - 移除版本：v1.0 (当前版本)
    - 迁移方案：
        旧代码: var BR: IByteReader; B := BR.ReadByte;
        新代码: IO.ReadFull(Reader, @B, 1);

        旧代码: var BW: IByteWriter; BW.WriteByte(B);
        新代码: IO.WriteAll(Writer, @B, 1);

  压缩功能 (已迁移)
    - IO.Gzip / IO.Deflate 已迁移到独立模块 fafafa.core.compress
    - 迁移方案：uses fafafa.core.compress;  // Compress.Gzip.*, Compress.Deflate.*

  一站式入口：用户只需 uses fafafa.core.io 即可使用所有 IO 功能。

  ============================================================================
  常用模式示例
  ============================================================================

  1. 文件读取
  -----------
    var Content: string;
    begin
      Content := IO.ReadString(IO.OpenRead('/path/to/file.txt'));
    end;

  2. 文件写入
  -----------
    var W: IWriteSeeker;
    begin
      W := IO.CreateTruncate('/path/to/output.txt');
      IO.WriteString(W, 'Hello, World!');  // 接口释放时自动关闭
    end;

  3. 逐行读取（惰性迭代）
  -----------------------
    var It: ILineIterator; Line: string;
    begin
      It := IO.LinesIter(IO.OpenRead('log.txt'));
      while It.Next(Line) do
        WriteLn(Format('Line %d: %s', [It.LineNumber, Line]));
    end;

  4. 带缓冲的文件读取
  -------------------
    var BR: TBufReader; Line: string;
    begin
      BR := IO.Buffered(IO.OpenRead('data.csv'));
      try
        while BR.ReadLine(Line) do
          ProcessLine(Line);
      finally
        BR.Free;
      end;
    end;

  5. 流复制
  ---------
    var BytesCopied: Int64;
    begin
      BytesCopied := IO.Copy(
        IO.CreateTruncate('dest.bin'),
        IO.OpenRead('source.bin')
      );
    end;

  6. 内存游标（TIOCursor）
  ------------------------
    var C: TIOCursor; Data: TBytes;
    begin
      C := IO.Cursor;           // 空游标
      IO.WriteString(C, 'Test');
      C.Seek(0, SeekStart);
      Data := IO.ReadAll(C);
      C.Free;
    end;

  7. 限制读取字节数
  -----------------
    var First100: TBytes;
    begin
      First100 := IO.ReadAll(IO.Limit(IO.OpenRead('big.dat'), 100));
    end;

  8. Tee 分流（读取时同步复制）
  ----------------------------
    var Log: TIOCursor; Src: IReader;
    begin
      Log := IO.Cursor;
      Src := IO.Tee(IO.OpenRead('input.bin'), Log);
      ProcessData(IO.ReadAll(Src));
      // Log 现在包含相同数据的副本
    end;

  9. 管道（生产者-消费者）
  ------------------------
    var P: TIOPipePair;
    begin
      P := IO.Pipe;
      // 生产者线程: IO.WriteString(P.Writer, 'data'); P.Writer.Close;
      // 消费者线程: IO.ReadAll(P.Reader);
    end;

  10. 压缩/解压（使用 fafafa.core.compress）
  ------------------------------------------
    uses fafafa.core.compress;
    var Compressed, Original: TBytes;
    begin
      Compressed := Compress.GzipCompress(Original);
      // 或使用流式 API：
      // Encoder := Compress.Gzip.Encode(DstWriter);
      // Encoder.Write(@Data[0], Length(Data));
      // Encoder.Close;
    end;

  11. for-in 行迭代（惰性加载）
  ---------------------------
    var Line: string;
    begin
      for Line in IO.ReadLines(IO.OpenRead('log.txt')) do
        ProcessLine(Line);
    end;

  12. 资源自动管理（IO.With*）
  ----------------------------
    // 以闭包方式处理资源，自动清理
    IO.WithBufReader(IO.OpenRead('data.csv'), procedure(BR: TBufReader)
    var Line: string;
    begin
      while BR.ReadLine(Line) do
        ProcessLine(Line);
    end);

  ============================================================================
  子模块
  ============================================================================
  - io.base       : 核心 trait 定义
  - io.buffered   : 缓冲 IO (TBufReader/TBufWriter)
  - io.combinators: 流组合子 (TIOCursor/TLimitedReader/...)
  - io.utils      : 便捷函数 (Copy/ReadAll/WriteAll/...)
  - io.std        : 标准流 (Stdin/Stdout/Stderr)
  - io.streams    : TStream 适配器
  - io.tee        : Tee/MultiWriter
  - io.pipe       : 同步管道
  - io.counted    : 字节计数
  - io.section    : 区段读取
  - io.scanner    : 惰性行迭代与扫描器
  - io.mmap       : 内存映射读取 (Unix)
  - io.instrument : 观测钩子

  相关模块：
  - fafafa.core.compress : 压缩/解压（独立模块）
}

interface

uses
  Classes, SysUtils,
  fafafa.core.io.base,
  fafafa.core.io.combinators,
  fafafa.core.io.buffered,
  fafafa.core.io.utils,
  fafafa.core.io.std,
  fafafa.core.io.streams,
  fafafa.core.io.tee,
  fafafa.core.io.pipe,
  fafafa.core.io.counted,
  fafafa.core.io.section,
  fafafa.core.io.adapters,
  fafafa.core.io.files,
  fafafa.core.io.scanner,
  fafafa.core.io.mmap,
  fafafa.core.io.instrument,
  fafafa.core.io.progress,
  fafafa.core.io.peek,
  fafafa.core.io.checksum,
  fafafa.core.io.timeout,
  fafafa.core.io.retry,
  fafafa.core.crypto.hash.sha256;

{ 重导出所有公共类型 }
type
  // 错误类型
  TIOErrorKind = fafafa.core.io.base.TIOErrorKind;

  // 异常
  EIOError = fafafa.core.io.base.EIOError;
  EEOFError = fafafa.core.io.base.EEOFError;
  EUnexpectedEOF = fafafa.core.io.base.EUnexpectedEOF;

  // 核心 trait
  IReader = fafafa.core.io.base.IReader;
  IWriter = fafafa.core.io.base.IWriter;
  ISeeker = fafafa.core.io.base.ISeeker;
  ICloser = fafafa.core.io.base.ICloser;
  IFlusher = fafafa.core.io.base.IFlusher;

  // 扩展 trait
  // IByteReader 和 IByteWriter 已弃用，不再导出，请使用 IO.ReadFull/WriteAll 替代
  IBufReader = fafafa.core.io.base.IBufReader;

  // 组合 trait
  IReadWriter = fafafa.core.io.base.IReadWriter;
  IReadCloser = fafafa.core.io.base.IReadCloser;
  IWriteCloser = fafafa.core.io.base.IWriteCloser;
  IReadWriteCloser = fafafa.core.io.base.IReadWriteCloser;
  IReadWriteSeeker = fafafa.core.io.base.IReadWriteSeeker;
  IReadSeeker = fafafa.core.io.base.IReadSeeker;
  IWriteSeeker = fafafa.core.io.base.IWriteSeeker;

  // 向量化 I/O
  TIOVec = fafafa.core.io.base.TIOVec;
  TIOVecArray = fafafa.core.io.base.TIOVecArray;
  IReaderVectored = fafafa.core.io.base.IReaderVectored;
  IWriterVectored = fafafa.core.io.base.IWriterVectored;

  // 回调类型
  TLineProc = fafafa.core.io.base.TLineProc;
  TLineProcNested = fafafa.core.io.base.TLineProcNested;

  // 实现类型
  TIOCursor = fafafa.core.io.combinators.TIOCursor;
  TLimitedReader = fafafa.core.io.combinators.TLimitedReader;
  TMultiReader = fafafa.core.io.combinators.TMultiReader;
  TBufReader = fafafa.core.io.buffered.TBufReader;
  TBufWriter = fafafa.core.io.buffered.TBufWriter;
  TCountedReader = fafafa.core.io.counted.TCountedReader;
  TCountedWriter = fafafa.core.io.counted.TCountedWriter;
  TSectionReader = fafafa.core.io.section.TSectionReader;
  TTeeReader = fafafa.core.io.tee.TTeeReader;
  TMultiWriter = fafafa.core.io.tee.TMultiWriter;
  TStreamReader = fafafa.core.io.streams.TStreamReader;
  TStreamWriter = fafafa.core.io.streams.TStreamWriter;
  TStreamIO = fafafa.core.io.streams.TStreamIO;
  TNopCloser = fafafa.core.io.adapters.TNopCloser;
  TChainReader = fafafa.core.io.adapters.TChainReader;
  TSkipReader = fafafa.core.io.adapters.TSkipReader;
  
  // 文件打开构建器
  TFileOpenBuilder = fafafa.core.io.files.TFileOpenBuilder;

  // 惰性迭代器与扫描器
  ILineIterator = fafafa.core.io.scanner.ILineIterator;
  TLineIterator = fafafa.core.io.scanner.TLineIterator;
  TLineEnumerator = fafafa.core.io.scanner.TLineEnumerator;
  TLineEnumerable = fafafa.core.io.scanner.TLineEnumerable;
  TScanner = fafafa.core.io.scanner.TScanner;

  // 回调类型（用于 IO.With*）
  TReaderProc = procedure(R: IReader) is nested;
  TWriterProc = procedure(W: IWriter) is nested;
  TBufReaderProc = procedure(BR: TBufReader) is nested;

  // 内存映射
  TMmapReader = fafafa.core.io.mmap.TMmapReader;

  // 观测与诊断
  TIOEventKind = fafafa.core.io.instrument.TIOEventKind;
  TIOEvent = fafafa.core.io.instrument.TIOEvent;
  TIOEventProc = fafafa.core.io.instrument.TIOEventProc;
  TIOEventProcNested = fafafa.core.io.instrument.TIOEventProcNested;

  // 进度回调
  TProgressEvent = fafafa.core.io.progress.TProgressEvent;
  TProgressCallback = fafafa.core.io.progress.TProgressCallback;

  // 窃视读取
  IPeekReader = fafafa.core.io.peek.IPeekReader;
  TPeekReader = fafafa.core.io.peek.TPeekReader;

  // 校验和计算
  IChecksumReader = fafafa.core.io.checksum.IChecksumReader;
  IChecksumWriter = fafafa.core.io.checksum.IChecksumWriter;
  TChecksumReader = fafafa.core.io.checksum.TChecksumReader;
  TChecksumWriter = fafafa.core.io.checksum.TChecksumWriter;

  { TIOPipePair - 管道读写端对 }
  TIOPipePair = record
    Reader: IReader;
    Writer: IWriteCloser;
  end;

  { IO - 一站式静态方法命名空间

    提供所有 IO 操作的统一入口点。
    使用 IO.xxx 调用各种工厂函数和便捷方法。
  }
  IO = record
  public
    { === 游标/内存 === }

    { 创建空游标 }
    class function Cursor: TIOCursor; static; overload;
    { 从字节数组创建游标 }
    class function Cursor(const AData: TBytes): TIOCursor; static; overload;
    { 创建指定容量的游标 }
    class function Cursor(ACapacity: SizeInt): TIOCursor; static; overload;

    { === 组合子 === }

    { 限制读取字节数 }
    class function Limit(AReader: IReader; N: Int64): IReader; static;
    { 串联多个读取器 }
    class function Multi(const AReaders: array of IReader): IReader; static; overload;
    { 广播写入多个目标 }
    class function Multi(const AWriters: array of IWriter): IWriter; static; overload;
    { 读取时同时写入副本 }
    class function Tee(AReader: IReader; AWriter: IWriter): IReader; static;
    { 重复单字节 }
    class function Repeat_(AByte: Byte): IReader; static;
    { 空读取器（立即 EOF） }
    class function Empty: IReader; static;
    { 丢弃写入器 }
    class function Discard: IWriter; static;

    { === 适配器 === }

    { 包装为 IReadCloser（空 Close）}
    class function NopCloser(AReader: IReader): IReadCloser; static;
    { 串联两个 Reader }
    class function Chain(AFirst, ASecond: IReader): IReader; static;
    { 跳过前 N 字节 }
    class function Skip(AReader: IReader; N: Int64): IReader; static;

    { === 区段/计数 === }

    { 只读取指定区段 }
    class function Section(AReader: IReadSeeker; AOffset, ASize: Int64): IReader; static;
    { 统计读取字节数 }
    class function Count(AReader: IReader): TCountedReader; static; overload;
    { 统计写入字节数 }
    class function Count(AWriter: IWriter): TCountedWriter; static; overload;

    { === 缓冲 === }

    { 带缓冲读取器 }
    class function Buffered(AReader: IReader; ABufSize: SizeInt = 8192): TBufReader; static; overload;
    { 带缓冲写入器 }
    class function Buffered(AWriter: IWriter; ABufSize: SizeInt = 8192): TBufWriter; static; overload;

    { === 管道 === }

    { 创建同步管道 }
    class function Pipe: TIOPipePair; static;

    { === 标准流 === }

    { 标准输入 }
    class function Stdin: IReader; static;
    { 标准输出 }
    class function Stdout: IWriter; static;
    { 标准错误 }
    class function Stderr: IWriter; static;

    { === 文件操作 === }
    
    { 打开文件 (fmOpenRead) }
    class function OpenFile(const Path: string): IReadSeeker; static;
    { 创建文件 (fmCreate) }
    class function CreateFile(const Path: string): IWriteSeeker; static;
    { 指定模式打开文件 }
    class function OpenFileMode(const Path: string; Mode: Word): IReadWriteSeeker; static;

    { 文件 Builder 与快捷族 }
    class function FileOpen(const Path: string): TFileOpenBuilder; static;
    class function OpenRead(const Path: string): IReadSeeker; static;
    class function CreateTruncate(const Path: string): IWriteSeeker; static;
    class function OpenAppend(const Path: string): IWriteSeeker; static;

    { === TStream 适配 === }

    { 从 TStream 创建 IReader }
    class function FromStream(AStream: TStream; AOwnsStream: Boolean = False): IReader; static; overload;
    { 从 TStream 创建完整 IO }
    class function FromStreamIO(AStream: TStream; AOwnsStream: Boolean = False): IReadWriteSeeker; static;

    { === 便捷函数 === }

    { 复制直到 EOF }
    class function Copy(ADst: IWriter; ASrc: IReader): Int64; static;
    { 复制恰好 N 字节 }
    class function CopyN(ADst: IWriter; ASrc: IReader; N: Int64): Int64; static;
    { 读取所有数据 }
    class function ReadAll(ASrc: IReader): TBytes; static;
    { 完整填充缓冲区 }
    class function ReadFull(ASrc: IReader; ABuf: Pointer; ACount: SizeInt): SizeInt; static;
    { 写入所有数据 }
    class function WriteAll(ADst: IWriter; ABuf: Pointer; ACount: SizeInt): SizeInt; static;
    { 写入字符串 }
    class function WriteString(ADst: IWriter; const S: string): SizeInt; static;
    { 写入字节数组 }
    class function WriteBytes(ADst: IWriter; const AData: TBytes): SizeInt; static;
    { 读取所有数据并转为字符串 }
    class function ReadString(ASrc: IReader): string; static;
    { 按行读取，返回字符串数组 }
    class function Lines(ASrc: IReader): TStringArray; static;

    { === 惰性迭代与扫描 === }

    { 惰性行迭代器 }
    class function LinesIter(AReader: IReader): ILineIterator; static;
    { 可配置扫描器 }
    class function Scanner(AReader: IReader): TScanner; static;
    { for-in 行迭代（支持 for Line in IO.ReadLines(R) do）}
    class function ReadLines(AReader: IReader): TLineEnumerable; static;

    { === 资源自动管理 === }

    { 以闭包方式处理 Reader，自动清理 }
    class procedure WithReader(AReader: IReader; AProc: TReaderProc); static;
    { 以闭包方式处理 Writer，自动清理 }
    class procedure WithWriter(AWriter: IWriter; AProc: TWriterProc); static;
    { 以闭包方式处理带缓冲读取器，自动清理 }
    class procedure WithBufReader(AReader: IReader; AProc: TBufReaderProc); static;

    { === 向量化 I/O === }

    { 向量化读取（自动回退） }
    class function ReadV(ASrc: IReader; const IOV: TIOVecArray): SizeInt; static;
    { 向量化写入（自动回退） }
    class function WriteV(ADst: IWriter; const IOV: TIOVecArray): SizeInt; static;

    { === 内存映射 === }

    { 内存映射读取（Unix mmap，失败回退到 OpenRead） }
    class function MmapRead(const APath: string): IReadSeeker; static;
    { 检查当前平台是否支持 mmap }
    class function MmapSupported: Boolean; static;

    { === 观测与诊断 === }

    { 创建带观测的读取器 }
    class function Instrument(AReader: IReader; AOnEvent: TIOEventProcNested): IReader; static; overload;
    { 创建带观测的写入器 }
    class function Instrument(AWriter: IWriter; AOnEvent: TIOEventProcNested): IWriter; static; overload;
    { 创建带观测的可定位读取器 }
    class function InstrumentSeeker(AReader: IReadSeeker; AOnEvent: TIOEventProcNested): IReadSeeker; static;

    { === 进度回调 === }

    { 创建带进度回调的读取器 }
    class function Progress(AReader: IReader; ACallback: TProgressCallback; ATotal: Int64 = -1): IReader; static; overload;
    { 创建带进度回调的写入器 }
    class function Progress(AWriter: IWriter; ACallback: TProgressCallback; ATotal: Int64 = -1): IWriter; static; overload;

    { === 窃视读取 === }

    { 创建支持窃视的读取器 }
    class function Peekable(AReader: IReader): IPeekReader; static;

    { === 校验和计算 === }

    { 创建带校验和计算的读取器（默认 SHA-256）}
    class function Checksum(AReader: IReader): IChecksumReader; static; overload;
    { 创建带校验和计算的写入器（默认 SHA-256）}
    class function Checksum(AWriter: IWriter): IChecksumWriter; static; overload;

    { === 超时包装 === }

    { 创建带超时检测的读取器 }
    class function Timeout(AReader: IReader; ATimeoutMs: Integer): IReader; static; overload;
    { 创建带超时检测的写入器 }
    class function Timeout(AWriter: IWriter; ATimeoutMs: Integer): IWriter; static; overload;

    { === 自动重试 === }

    { 创建带自动重试的读取器 }
    class function Retry(AReader: IReader; AMaxAttempts: Integer; ADelayMs: Integer = 100): IReader; static; overload;
    { 创建带自动重试的写入器 }
    class function Retry(AWriter: IWriter; AMaxAttempts: Integer; ADelayMs: Integer = 100): IWriter; static; overload;
  end;

const
  // Seek 常量
  SeekStart = fafafa.core.io.base.SeekStart;
  SeekCurrent = fafafa.core.io.base.SeekCurrent;
  SeekEnd = fafafa.core.io.base.SeekEnd;

  // 默认缓冲区大小
  DefaultBufSize = fafafa.core.io.buffered.DefaultBufSize;
  DefaultCopyBufSize = fafafa.core.io.utils.DefaultCopyBufSize;

implementation

{ IO }

class function IO.Cursor: TIOCursor;
begin
  Result := TIOCursor.Create;
end;

class function IO.Cursor(const AData: TBytes): TIOCursor;
begin
  Result := TIOCursor.FromBytes(AData);
end;

class function IO.Cursor(ACapacity: SizeInt): TIOCursor;
begin
  Result := TIOCursor.Create(ACapacity);
end;

class function IO.Limit(AReader: IReader; N: Int64): IReader;
begin
  Result := fafafa.core.io.combinators.LimitReader(AReader, N);
end;

class function IO.Multi(const AReaders: array of IReader): IReader;
begin
  Result := fafafa.core.io.combinators.MultiReader(AReaders);
end;

class function IO.Multi(const AWriters: array of IWriter): IWriter;
begin
  Result := fafafa.core.io.tee.MultiWriter(AWriters);
end;

class function IO.Tee(AReader: IReader; AWriter: IWriter): IReader;
begin
  Result := fafafa.core.io.tee.TeeReader(AReader, AWriter);
end;

class function IO.Repeat_(AByte: Byte): IReader;
begin
  Result := fafafa.core.io.combinators.RepeatByte(AByte);
end;

class function IO.Empty: IReader;
begin
  Result := fafafa.core.io.combinators.EmptyReader;
end;

class function IO.Discard: IWriter;
begin
  Result := fafafa.core.io.combinators.Discard;
end;

class function IO.NopCloser(AReader: IReader): IReadCloser;
begin
  Result := fafafa.core.io.adapters.NopCloser(AReader);
end;

class function IO.Chain(AFirst, ASecond: IReader): IReader;
begin
  Result := fafafa.core.io.adapters.Chain(AFirst, ASecond);
end;

class function IO.Skip(AReader: IReader; N: Int64): IReader;
begin
  Result := fafafa.core.io.adapters.Skip(AReader, N);
end;

class function IO.Section(AReader: IReadSeeker; AOffset, ASize: Int64): IReader;
begin
  Result := fafafa.core.io.section.SectionReader(AReader, AOffset, ASize);
end;

class function IO.Count(AReader: IReader): TCountedReader;
begin
  Result := TCountedReader.Create(AReader);
end;

class function IO.Count(AWriter: IWriter): TCountedWriter;
begin
  Result := TCountedWriter.Create(AWriter);
end;

class function IO.Buffered(AReader: IReader; ABufSize: SizeInt): TBufReader;
begin
  Result := TBufReader.Create(AReader, ABufSize);
end;

class function IO.Buffered(AWriter: IWriter; ABufSize: SizeInt): TBufWriter;
begin
  Result := TBufWriter.Create(AWriter, ABufSize);
end;

class function IO.Pipe: TIOPipePair;
var
  R: IReader;
  W: IWriteCloser;
begin
  fafafa.core.io.pipe.PipeCloser(R, W);
  Result.Reader := R;
  Result.Writer := W;
end;

class function IO.Stdin: IReader;
begin
  Result := fafafa.core.io.std.Stdin;
end;

class function IO.Stdout: IWriter;
begin
  Result := fafafa.core.io.std.Stdout;
end;

class function IO.Stderr: IWriter;
begin
  Result := fafafa.core.io.std.Stderr;
end;

class function IO.OpenFile(const Path: string): IReadSeeker;
begin
  Result := fafafa.core.io.files.OpenFile(Path);
end;

class function IO.CreateFile(const Path: string): IWriteSeeker;
begin
  Result := fafafa.core.io.files.CreateFile(Path);
end;

class function IO.OpenFileMode(const Path: string; Mode: Word): IReadWriteSeeker;
begin
  Result := fafafa.core.io.files.OpenFileMode(Path, Mode);
end;

class function IO.FileOpen(const Path: string): TFileOpenBuilder;
begin
  Result := fafafa.core.io.files.FileOpen(Path);
end;

class function IO.OpenRead(const Path: string): IReadSeeker;
begin
  Result := fafafa.core.io.files.OpenRead(Path);
end;

class function IO.CreateTruncate(const Path: string): IWriteSeeker;
begin
  Result := fafafa.core.io.files.CreateTruncate(Path);
end;

class function IO.OpenAppend(const Path: string): IWriteSeeker;
begin
  Result := fafafa.core.io.files.OpenAppend(Path);
end;

class function IO.FromStream(AStream: TStream; AOwnsStream: Boolean): IReader;
begin
  Result := fafafa.core.io.streams.ReaderFromStream(AStream, AOwnsStream);
end;

class function IO.FromStreamIO(AStream: TStream; AOwnsStream: Boolean): IReadWriteSeeker;
begin
  Result := fafafa.core.io.streams.IOFromStream(AStream, AOwnsStream);
end;

class function IO.Copy(ADst: IWriter; ASrc: IReader): Int64;
begin
  Result := fafafa.core.io.utils.Copy(ADst, ASrc);
end;

class function IO.CopyN(ADst: IWriter; ASrc: IReader; N: Int64): Int64;
begin
  Result := fafafa.core.io.utils.CopyN(ADst, ASrc, N);
end;

class function IO.ReadAll(ASrc: IReader): TBytes;
begin
  Result := fafafa.core.io.utils.ReadAll(ASrc);
end;

class function IO.ReadFull(ASrc: IReader; ABuf: Pointer; ACount: SizeInt): SizeInt;
begin
  Result := fafafa.core.io.utils.ReadFull(ASrc, ABuf, ACount);
end;

class function IO.WriteAll(ADst: IWriter; ABuf: Pointer; ACount: SizeInt): SizeInt;
begin
  Result := fafafa.core.io.utils.WriteAll(ADst, ABuf, ACount);
end;

class function IO.WriteString(ADst: IWriter; const S: string): SizeInt;
begin
  Result := fafafa.core.io.utils.WriteString(ADst, S);
end;

class function IO.WriteBytes(ADst: IWriter; const AData: TBytes): SizeInt;
begin
  Result := fafafa.core.io.utils.WriteBytes(ADst, AData);
end;

class function IO.ReadString(ASrc: IReader): string;
begin
  Result := fafafa.core.io.utils.ReadString(ASrc);
end;

class function IO.Lines(ASrc: IReader): TStringArray;
var
  LBR: TBufReader;
  LLine: string;
  LList: array of string;
  LCount, LCap, I: Integer;
begin
  Result := nil;  // 初始化
  LCount := 0;
  LCap := 16;
  SetLength(LList, LCap);

  LBR := TBufReader.Create(ASrc);
  try
    while LBR.ReadLine(LLine) do
    begin
      if LCount >= LCap then
      begin
        LCap := LCap * 2;
        SetLength(LList, LCap);
      end;
      LList[LCount] := LLine;
      Inc(LCount);
    end;
  finally
    LBR.Free;
  end;

  // 安全的循环赋值，正确处理引用计数
  SetLength(Result, LCount);
  for I := 0 to LCount - 1 do
    Result[I] := LList[I];
end;

class function IO.LinesIter(AReader: IReader): ILineIterator;
begin
  Result := fafafa.core.io.scanner.LineIterator(AReader);
end;

class function IO.Scanner(AReader: IReader): TScanner;
begin
  Result := fafafa.core.io.scanner.Scanner(AReader);
end;

class function IO.ReadLines(AReader: IReader): TLineEnumerable;
begin
  Result := fafafa.core.io.scanner.ReadLines(AReader);
end;

class procedure IO.WithReader(AReader: IReader; AProc: TReaderProc);
begin
  try
    AProc(AReader);
  finally
    // IReader 通过引用计数自动释放
  end;
end;

class procedure IO.WithWriter(AWriter: IWriter; AProc: TWriterProc);
var
  Closer: ICloser;
  Flusher: IFlusher;
begin
  try
    AProc(AWriter);
  finally
    // 如果支持 Flush，先 Flush
    if Supports(AWriter, IFlusher, Flusher) then
      Flusher.Flush;
    // 如果支持 Close，调用 Close
    if Supports(AWriter, ICloser, Closer) then
      Closer.Close;
  end;
end;

class procedure IO.WithBufReader(AReader: IReader; AProc: TBufReaderProc);
var
  BR: TBufReader;
begin
  BR := TBufReader.Create(AReader);
  try
    AProc(BR);
  finally
    BR.Free;
  end;
end;

class function IO.ReadV(ASrc: IReader; const IOV: TIOVecArray): SizeInt;
var
  RV: IReaderVectored;
begin
  if Supports(ASrc, IReaderVectored, RV) then
    Result := RV.ReadV(IOV)
  else
    Result := fafafa.core.io.utils.ReadVFallback(ASrc, IOV);
end;

class function IO.WriteV(ADst: IWriter; const IOV: TIOVecArray): SizeInt;
var
  WV: IWriterVectored;
begin
  if Supports(ADst, IWriterVectored, WV) then
    Result := WV.WriteV(IOV)
  else
    Result := fafafa.core.io.utils.WriteVFallback(ADst, IOV);
end;

class function IO.MmapRead(const APath: string): IReadSeeker;
begin
  {$IFDEF UNIX}
  try
    Result := fafafa.core.io.mmap.MmapRead(APath);
  except
    // mmap 失败，回退到普通文件读取
    Result := IO.OpenRead(APath);
  end;
  {$ELSE}
  // 非 Unix 平台直接使用普通文件读取
  Result := IO.OpenRead(APath);
  {$ENDIF}
end;

class function IO.MmapSupported: Boolean;
begin
  Result := fafafa.core.io.mmap.MmapSupported;
end;

class function IO.Instrument(AReader: IReader; AOnEvent: TIOEventProcNested): IReader;
begin
  Result := fafafa.core.io.instrument.InstrumentReader(AReader, AOnEvent);
end;

class function IO.Instrument(AWriter: IWriter; AOnEvent: TIOEventProcNested): IWriter;
begin
  Result := fafafa.core.io.instrument.InstrumentWriter(AWriter, AOnEvent);
end;

class function IO.InstrumentSeeker(AReader: IReadSeeker; AOnEvent: TIOEventProcNested): IReadSeeker;
begin
  Result := fafafa.core.io.instrument.InstrumentReadSeeker(AReader, AOnEvent);
end;

class function IO.Progress(AReader: IReader; ACallback: TProgressCallback; ATotal: Int64): IReader;
begin
  Result := fafafa.core.io.progress.ProgressReader(AReader, ACallback, ATotal);
end;

class function IO.Progress(AWriter: IWriter; ACallback: TProgressCallback; ATotal: Int64): IWriter;
begin
  Result := fafafa.core.io.progress.ProgressWriter(AWriter, ACallback, ATotal);
end;

class function IO.Peekable(AReader: IReader): IPeekReader;
begin
  Result := fafafa.core.io.peek.PeekReader(AReader);
end;

class function IO.Checksum(AReader: IReader): IChecksumReader;
begin
  Result := fafafa.core.io.checksum.ChecksumReader(AReader, fafafa.core.crypto.hash.sha256.CreateSHA256);
end;

class function IO.Checksum(AWriter: IWriter): IChecksumWriter;
begin
  Result := fafafa.core.io.checksum.ChecksumWriter(AWriter, fafafa.core.crypto.hash.sha256.CreateSHA256);
end;

class function IO.Timeout(AReader: IReader; ATimeoutMs: Integer): IReader;
begin
  Result := fafafa.core.io.timeout.TimeoutReader(AReader, ATimeoutMs);
end;

class function IO.Timeout(AWriter: IWriter; ATimeoutMs: Integer): IWriter;
begin
  Result := fafafa.core.io.timeout.TimeoutWriter(AWriter, ATimeoutMs);
end;

class function IO.Retry(AReader: IReader; AMaxAttempts: Integer; ADelayMs: Integer): IReader;
begin
  Result := fafafa.core.io.retry.RetryReader(AReader, AMaxAttempts, ADelayMs);
end;

class function IO.Retry(AWriter: IWriter; AMaxAttempts: Integer; ADelayMs: Integer): IWriter;
begin
  Result := fafafa.core.io.retry.RetryWriter(AWriter, AMaxAttempts, ADelayMs);
end;

end.
