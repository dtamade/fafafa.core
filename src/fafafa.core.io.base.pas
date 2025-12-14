unit fafafa.core.io.base;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{
  fafafa.core.io - 流式 IO 抽象层

  对标 Rust std::io，提供：
  - 核心 trait: IReader, IWriter, ISeeker, ICloser, IFlusher
  - 扩展 trait: IByteReader, IByteWriter, IBufReader
  - 组合 trait: IReadWriter, IReadCloser, IWriteCloser, IReadWriteCloser, IReadWriteSeeker

  设计原则：
  - 纯 trait 定义，不依赖 fafafa.core.bytes
  - 统一命名：Reader/Writer/Seeker
  - 最小接口原则
}

interface

uses
  SysUtils;

const
  { Seek 起点常量 }
  SeekStart   = 0;  // 从文件开始
  SeekCurrent = 1;  // 从当前位置
  SeekEnd     = 2;  // 从文件末尾

type
  { TIOVec - 向量化 I/O 缓冲区描述符

    用于 readv/writev 风格的批量 I/O 操作。
    参考: POSIX iovec, Rust IoSlice/IoSliceMut
  }
  TIOVec = record
    Base: Pointer;  // 缓冲区起始地址
    Len: SizeInt;   // 缓冲区长度
  end;

  { TIOVec 数组类型 }
  TIOVecArray = array of TIOVec;

  { IO 错误类型枚举 }
  TIOErrorKind = (
    ekUnknown,           // 未知错误
    ekEOF,               // 文件结束
    ekUnexpectedEOF,     // 意外的文件结束
    ekNotFound,          // 未找到
    ekPermissionDenied,  // 权限拒绝
    ekAlreadyExists,     // 已存在
    ekInvalidInput,      // 无效输入
    ekInvalidData,       // 无效数据
    ekTimedOut,          // 超时
    ekWriteZero,         // 写入返回 0
    ekInterrupted,       // 被中断
    ekWouldBlock,        // 会阻塞
    ekBrokenPipe,        // 管道断开
    ekNotConnected,      // 未连接
    ekAddrInUse,         // 地址已使用
    ekAddrNotAvailable   // 地址不可用
  );

  { IO 异常基类
  
    结构化字段：
    - Kind: 错误类型
    - Op: 操作名称 (open/read/write/seek/close)
    - Path: 相关文件路径 (可为空)
    - Code: 原始系统错误码 (errno/winerr, 0=未知)
    - Cause: 底层错误描述
    
    参考: Rust std::io::Error
  }
  EIOError = class(Exception)
  private
    FKind: TIOErrorKind;
    FOp: string;
    FPath: string;
    FCode: Integer;
    FCause: string;
  public
    { 简单构造 }
    constructor Create(const AMessage: string); overload;
    { 带 Kind 的构造 }
    constructor Create(AKind: TIOErrorKind; const AMessage: string); overload;
    { 完整结构化构造 }
    constructor Create(AKind: TIOErrorKind; const AOp, APath: string; 
      ACode: Integer; const ACause: string); overload;
    
    property Kind: TIOErrorKind read FKind;
    property Op: string read FOp;
    property Path: string read FPath;
    property Code: Integer read FCode;
    property Cause: string read FCause;
  end;

  { EOF 异常 }
  EEOFError = class(EIOError)
  public
    constructor Create; overload;
    constructor Create(const AMessage: string); overload;
  end;

  { 意外 EOF 异常 }
  EUnexpectedEOF = class(EIOError)
  public
    constructor Create; overload;
    constructor Create(const AMessage: string); overload;
  end;

  { ========================================================================
    核心 trait
    ======================================================================== }

  { IReader - 读取器接口

    从数据源读取字节到缓冲区。
    返回实际读取的字节数，0 表示 EOF。

    参考: Rust std::io::Read
  }
  IReader = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    function Read(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { IWriter - 写入器接口

    将缓冲区中的字节写入目标。
    返回实际写入的字节数。

    参考: Rust std::io::Write
  }
  IWriter = interface
    ['{B2C3D4E5-F6A7-8901-2345-6789ABCDEF01}']
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { ISeeker - 定位器接口

    在数据流中定位读写位置。
    Whence: SeekStart, SeekCurrent, SeekEnd
    返回新的绝对位置。

    参考: Rust std::io::Seek
  }
  ISeeker = interface
    ['{C3D4E5F6-A7B8-9012-3456-789ABCDEF012}']
    function Seek(Offset: Int64; Whence: Integer): Int64;
  end;

  { ICloser - 关闭器接口

    关闭资源，释放底层句柄。

    参考: Rust Drop trait / Go io.Closer
  }
  ICloser = interface
    ['{D4E5F6A7-B8C9-0123-4567-89ABCDEF0123}']
    procedure Close;
  end;

  { IFlusher - 刷新器接口

    将内部缓冲区的数据刷新到底层目标。

    参考: Rust std::io::Write::flush
  }
  IFlusher = interface
    ['{E5F6A7B8-C9D0-1234-5678-9ABCDEF01234}']
    procedure Flush;
  end;

  { ========================================================================
    扩展 trait
    ======================================================================== }

  { IByteReader - 字节读取器扩展 (Deprecated)
    建议使用 IReader 配合 fafafa.core.io.utils 中的辅助函数
  }
  IByteReader = interface(IReader)
    ['{F6A7B8C9-D0E1-2345-6789-ABCDEF012345}']
    function ReadByte: Byte; deprecated 'Use IO.ReadFull or TBufReader';
    function ReadBytes(Count: SizeInt): TBytes; deprecated 'Use IO.ReadFull or IO.ReadAll';
    function ReadAll: TBytes; deprecated 'Use IO.ReadAll';
  end deprecated 'Use IReader and Utils instead';

  { IByteWriter - 字节写入器扩展

    在 IWriter 基础上提供便捷的字节级写入方法。
  }
  IByteWriter = interface(IWriter)
    ['{A7B8C9D0-E1F2-3456-789A-BCDEF0123456}']
    function WriteByte(Value: Byte): SizeInt; deprecated 'Use IO.WriteAll or TBufWriter';
    function WriteBytes(const B: TBytes): SizeInt; deprecated 'Use IO.WriteAll';
  end deprecated 'Use IWriter and Utils instead';

  { IBufReader - 带缓冲读取器

    提供内部缓冲区访问和行读取功能。

    参考: Rust std::io::BufRead
  }
  IBufReader = interface(IReader)
    ['{B8C9D0E1-F2A3-4567-89AB-CDEF01234567}']
    { 获取内部缓冲区引用，返回是否有数据 }
    function FillBuf(out Buf: PByte; out Len: SizeInt): Boolean;
    { 标记已消费的字节数 }
    procedure Consume(N: SizeInt);
    { 读取一行（不含换行符），返回是否成功 }
    function ReadLine(out Line: string): Boolean;
    { 读取直到遇到分隔符，返回是否成功 }
    function ReadUntil(Delim: Byte; out Data: TBytes): Boolean;
  end;

  { ========================================================================
    向量化 I/O 可选接口
    ======================================================================== }

  { IReaderVectored - 向量化读取器

    支持一次读取到多个缓冲区（readv 风格）。
    返回实际读取的总字节数，0 表示 EOF。

    参考: Rust Read::read_vectored, POSIX readv
  }
  IReaderVectored = interface
    ['{1A2B3C4D-5E6F-7890-ABCD-EF1234567001}']
    function ReadV(const IOV: TIOVecArray): SizeInt;
  end;

  { IWriterVectored - 向量化写入器

    支持一次从多个缓冲区写入（writev 风格）。
    返回实际写入的总字节数。

    参考: Rust Write::write_vectored, POSIX writev
  }
  IWriterVectored = interface
    ['{2B3C4D5E-6F70-8901-BCDE-F12345670012}']
    function WriteV(const IOV: TIOVecArray): SizeInt;
  end;

  { ========================================================================
    组合 trait
    ======================================================================== }

  { IReadWriter - 读写器 }
  IReadWriter = interface(IReader)
    ['{C9D0E1F2-A3B4-5678-9ABC-DEF012345678}']
    function Write(Buf: Pointer; Count: SizeInt): SizeInt;
  end;

  { IReadCloser - 可关闭读取器 }
  IReadCloser = interface(IReader)
    ['{D0E1F2A3-B4C5-6789-ABCD-EF0123456789}']
    procedure Close;
  end;

  { IWriteCloser - 可关闭写入器 }
  IWriteCloser = interface(IWriter)
    ['{E1F2A3B4-C5D6-789A-BCDE-F01234567890}']
    procedure Close;
  end;

  { IReadWriteCloser - 可关闭读写器 }
  IReadWriteCloser = interface(IReadWriter)
    ['{F2A3B4C5-D6E7-89AB-CDEF-012345678901}']
    procedure Close;
  end;

  { IReadWriteSeeker - 可定位读写器 }
  IReadWriteSeeker = interface(IReadWriter)
    ['{A3B4C5D6-E7F8-9ABC-DEF0-123456789012}']
    function Seek(Offset: Int64; Whence: Integer): Int64;
  end;

  { IReadSeeker - 可定位读取器 }
  IReadSeeker = interface(IReader)
    ['{B4C5D6E7-F8A9-ABCD-EF01-234567890123}']
    function Seek(Offset: Int64; Whence: Integer): Int64;
  end;

  { IWriteSeeker - 可定位写入器 }
  IWriteSeeker = interface(IWriter)
    ['{C5D6E7F8-A9BA-BCDE-F012-345678901234}']
    function Seek(Offset: Int64; Whence: Integer): Int64;
  end;

  { ========================================================================
    回调类型
    ======================================================================== }

  { 行处理回调 }
  TLineProc = procedure(const Line: string) of object;
  TLineProcNested = procedure(const Line: string) is nested;

{$IFDEF UNIX}
{ 将 Unix errno 映射到 IO 错误类型 }
function IOUnixErrorKind(ErrNo: LongInt): TIOErrorKind;
{$ENDIF}

{$IFDEF WINDOWS}
{ 将 Windows GetLastError 映射到 IO 错误类型 }
function IOWinErrorKind(ErrNo: LongInt): TIOErrorKind;
{$ENDIF}

implementation

{$IFDEF UNIX}
uses BaseUnix;
{$ENDIF}
{$IFDEF WINDOWS}
uses Windows;
{$ENDIF}

{$IFDEF UNIX}
function IOUnixErrorKind(ErrNo: LongInt): TIOErrorKind;
begin
  case ErrNo of
    ESysENOENT:
      Result := ekNotFound;
    ESysEACCES, ESysEPERM:
      Result := ekPermissionDenied;
    ESysEEXIST:
      Result := ekAlreadyExists;
    ESysEINVAL:
      Result := ekInvalidInput;
    ESysEIO:
      Result := ekInvalidData;
    ESysETIMEDOUT:
      Result := ekTimedOut;
    ESysEINTR:
      Result := ekInterrupted;
    ESysEAGAIN{$IFDEF ESysEWOULDBLOCK}, ESysEWOULDBLOCK{$ENDIF}:
      Result := ekWouldBlock;
    ESysEPIPE:
      Result := ekBrokenPipe;
    ESysENOTCONN:
      Result := ekNotConnected;
    ESysEADDRINUSE:
      Result := ekAddrInUse;
    ESysEADDRNOTAVAIL:
      Result := ekAddrNotAvailable;
  else
    Result := ekUnknown;
  end;
end;
{$ENDIF}

{$IFDEF WINDOWS}
function IOWinErrorKind(ErrNo: LongInt): TIOErrorKind;
begin
  case ErrNo of
    ERROR_FILE_NOT_FOUND, ERROR_PATH_NOT_FOUND:
      Result := ekNotFound;
    ERROR_ACCESS_DENIED:
      Result := ekPermissionDenied;
    ERROR_ALREADY_EXISTS, ERROR_FILE_EXISTS:
      Result := ekAlreadyExists;
    ERROR_INVALID_PARAMETER:
      Result := ekInvalidInput;
    ERROR_BROKEN_PIPE:
      Result := ekBrokenPipe;
  else
    Result := ekUnknown;
  end;
end;
{$ENDIF}

{ EIOError }

constructor EIOError.Create(const AMessage: string);
begin
  inherited Create(AMessage);
  FKind := ekUnknown;
  FOp := '';
  FPath := '';
  FCode := 0;
  FCause := '';
end;

constructor EIOError.Create(AKind: TIOErrorKind; const AMessage: string);
begin
  inherited Create(AMessage);
  FKind := AKind;
  FOp := '';
  FPath := '';
  FCode := 0;
  FCause := '';
end;

constructor EIOError.Create(AKind: TIOErrorKind; const AOp, APath: string;
  ACode: Integer; const ACause: string);
var
  Msg: string;
begin
  // 构建结构化消息
  Msg := AOp;
  if APath <> '' then
    Msg := Msg + ' ' + APath;
  if ACause <> '' then
    Msg := Msg + ': ' + ACause;
  
  inherited Create(Msg);
  FKind := AKind;
  FOp := AOp;
  FPath := APath;
  FCode := ACode;
  FCause := ACause;
end;

{ EEOFError }

constructor EEOFError.Create;
begin
  inherited Create(ekEOF, 'EOF');
end;

constructor EEOFError.Create(const AMessage: string);
begin
  inherited Create(ekEOF, AMessage);
end;

{ EUnexpectedEOF }

constructor EUnexpectedEOF.Create;
begin
  inherited Create(ekUnexpectedEOF, 'unexpected EOF');
end;

constructor EUnexpectedEOF.Create(const AMessage: string);
begin
  inherited Create(ekUnexpectedEOF, AMessage);
end;

end.

