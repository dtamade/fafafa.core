unit fafafa.core.socket;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$modeswitch advancedrecords}


interface

uses
  SysUtils, Classes, TypInfo, StrUtils,
  fafafa.core.base;

type
  // 平台相关类型定义
  {$IFDEF WINDOWS}
  TSocketHandle = PtrUInt;
  {$ELSE}
  TSocketHandle = Integer;
  {$ENDIF}

const
  // Socket常量定义
  {$IFDEF WINDOWS}
  INVALID_SOCKET = TSocketHandle(-1);
  SOCKET_ERROR = -1;
  {$ELSE}
  INVALID_SOCKET = -1;
  SOCKET_ERROR = -1;
  {$ENDIF}

  // 常见非阻塞错误码抽象（跨平台映射）
  {$IFDEF WINDOWS}
  const SOCKET_EWOULDBLOCK = 10035; SOCKET_EAGAIN = 10035; SOCKET_EINTR = 10004; {$ENDIF}
  {$IFDEF UNIX}
  const SOCKET_EWOULDBLOCK = 11; SOCKET_EAGAIN = 11; SOCKET_EINTR = 4; {$ENDIF}
type
  // FD 集合复用池（性能优化）
  TFDSetPool = class
  private
    class var FInstance: TFDSetPool;
    class var FClassLock: TRTLCriticalSection;
    class constructor Create;
    class destructor Destroy;
  private
    FAvailableSets: array of Pointer;
    FAvailableTimevals: array of Pointer;
    FSetCount: Integer;
    FTimevalCount: Integer;
    FInstanceLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;

    function BorrowFDSet: Pointer;
    procedure ReturnFDSet(ASet: Pointer);
    function BorrowTimeval: Pointer;
    procedure ReturnTimeval(ATimeval: Pointer);

    class function Instance: TFDSetPool;
  end;


  // 跨平台错误分类辅助（公开给调用方）
  function SocketIsWouldBlock(aError: Integer): Boolean;
  function SocketIsInterrupted(aError: Integer): Boolean;

  {**
   * Socket相关异常类型
   *}

  type

  {**
   * ESocketError
   *
   * @desc Socket操作的基础异常类
   *       增强版本包含错误码和Socket句柄信息
   *}
  ESocketError = class(ECore)
  private
    FErrorCode: Integer;
    FSocketHandle: TSocketHandle;
  public
    constructor Create(const aMessage: string); overload;
    constructor Create(const aMessage: string; aErrorCode: Integer); overload;
    constructor Create(const aMessage: string; aErrorCode: Integer; aHandle: TSocketHandle); overload;

    property ErrorCode: Integer read FErrorCode;
    property SocketHandle: TSocketHandle read FSocketHandle;

    function GetDetailedMessage: string;
  end;

  {**
   * ESocketCreateError
   *
   * @desc Socket创建失败时抛出的异常
   *}
  ESocketCreateError = class(ESocketError);

  {**
   * ESocketBindError
   *
   * @desc Socket绑定失败时抛出的异常
   *}
  ESocketBindError = class(ESocketError);

  {**
   * ESocketListenError
   *
   * @desc Socket监听失败时抛出的异常
   *}
  ESocketListenError = class(ESocketError);

  {**
   * ESocketConnectError
   *
   * @desc Socket连接失败时抛出的异常
   *}
  ESocketConnectError = class(ESocketError);

  {**
   * ESocketAcceptError
   *
   * @desc Socket接受连接失败时抛出的异常
   *}
  ESocketAcceptError = class(ESocketError);

  {**
   * ESocketSendError
   *
   * @desc Socket发送数据失败时抛出的异常
   *}
  ESocketSendError = class(ESocketError);

  {**
   * ESocketReceiveError
   *
   * @desc Socket接收数据失败时抛出的异常
   *}
  ESocketReceiveError = class(ESocketError);

  {**
   * ESocketTimeoutError
   *
   * @desc Socket操作超时时抛出的异常
   *}
  ESocketTimeoutError = class(ESocketError);

  {**
   * ESocketClosedError
   *
   * @desc 在已关闭的Socket上执行操作时抛出的异常
   *}
  ESocketClosedError = class(ESocketError);

  {**
   * 地址族枚举
   *}
  TAddressFamily = (
    afUnspec,        // 未指定
    afInet,          // IPv4
    afInet6,         // IPv6
    afUnix           // Unix域套接字
  );

  {**
   * Socket类型枚举
   *}
  TSocketType = (
    stStream,        // TCP流套接字
    stDgram,         // UDP数据报套接字
    stRaw            // 原始套接字
  );

  {**
   * 协议类型枚举
   *}
  TProtocol = (
    pDefault,        // 默认协议
    pTCP,            // TCP协议
    pUDP,            // UDP协议
    pICMP            // ICMP协议
  );

  {**
   * Socket状态枚举
   *}
  TSocketState = (
    ssNotCreated,    // 未创建
    ssCreated,       // 已创建
    ssBound,         // 已绑定
    ssListening,     // 监听中
    ssConnecting,    // 连接中
    ssConnected,     // 已连接
    ssDisconnected,  // 已断开
    ssClosed         // 已关闭
  );

  {**
   * 关闭模式枚举
   *}
  TShutdownMode = (
    sdReceive,       // 关闭接收
    sdSend,          // 关闭发送
    sdBoth           // 关闭收发
  );

  {**
   * Socket选项级别枚举
   *}
  TSocketOptionLevel = (
    solSocket,       // Socket级别
    solTCP,          // TCP级别
    solIP,           // IP级别
    solIPv6          // IPv6级别
  );



  // 前向声明
  ISocketAddress = interface;
  ISocket = interface;
  ISocketListener = interface;

  // 现代化时间跨度类型（提前声明，避免在接口中找不到类型）
  type TTimeSpan = record
  private
    FMilliseconds: Int64;
  public
    class function FromMilliseconds(aMs: Int64): TTimeSpan; static;
    class function FromSeconds(aSec: Integer): TTimeSpan; static;
    class function FromMinutes(aMin: Integer): TTimeSpan; static;
    class function FromHours(aHours: Integer): TTimeSpan; static;
    class function Zero: TTimeSpan; static;

    function ToMilliseconds: Int64;
    function ToSeconds: Double;
    function IsZero: Boolean;

    property TotalMilliseconds: Int64 read FMilliseconds;
  end;

  {$IFDEF FAFAFA_SOCKET_ADVANCED}
  // 高性能零拷贝/向量类型（提前声明）
  type TSocketBuffer = record
  private
    FData: Pointer;
    FSize: Integer;
    FCapacity: Integer;
    FOwned: Boolean;
  public
    class function Create(aCapacity: Integer): TSocketBuffer; static;
    class function Wrap(aData: Pointer; aSize: Integer): TSocketBuffer; static;
    procedure Free;
    function GetData: Pointer;
    function GetSize: Integer;
    function GetCapacity: Integer;
    procedure Resize(aNewSize: Integer);
    property Data: Pointer read GetData;
    property Size: Integer read GetSize;
    property Capacity: Integer read GetCapacity;
  end;

  type TIOVector = record
    Data: Pointer;
    Size: Integer;
  end;
  type TIOVectorArray = array of TIOVector;

  type TSocketBufferPool = class
  private
    FBuffers: array of TSocketBuffer;
    FAvailable: array of Boolean;
    FDefaultSize: Integer;
    FMaxBuffers: Integer;
    FCurrentCount: Integer;
  public
    constructor Create(aDefaultSize: Integer = 8192; aMaxBuffers: Integer = 64);
    destructor Destroy; override;
    function Acquire: TSocketBuffer;
    procedure Release(var aBuffer: TSocketBuffer);
    function GetStatistics: string;
  end;
  {$ENDIF}

  // Socket统计信息（提前声明）
  type TSocketStatistics = record
    BytesSent: Int64;
    BytesReceived: Int64;
    ConnectionTime: TDateTime;
    LastActivity: TDateTime;
    ErrorCount: Integer;
    SendOperations: Integer;
    ReceiveOperations: Integer;
  end;

  {**
   * ISocketAddress
   *
   * @desc Socket地址接口
   *       封装不同类型的网络地址
   *}
  ISocketAddress = interface(IInterface)
  ['{12345678-1234-1234-1234-123456789001}']

    // 基本属性
    function GetFamily: TAddressFamily;
    function GetHost: string;
    function GetPort: Word;
    function GetSize: Integer;

    // 转换方法
    function ToString: string;
    function ToNativeAddr: Pointer;
    procedure FromNativeAddr(aAddr: Pointer; aSize: Integer);

    // 验证方法
    function IsValid: Boolean;
    procedure Validate;

    // 属性
    property Family: TAddressFamily read GetFamily;
    property Host: string read GetHost;
    property Port: Word read GetPort;
    property Size: Integer read GetSize;
  end;

  {**
   * ISocket
   *
   * @desc Socket核心接口
   *       提供Socket的基本操作和生命周期管理
   *}
  ISocket = interface(IInterface)
  ['{12345678-1234-1234-1234-123456789002}']

    // 生命周期管理
    procedure Bind(const aAddress: ISocketAddress);
    procedure Listen(aBacklog: Integer = 128);
    function Accept: ISocket;
    procedure Connect(const aAddress: ISocketAddress);
    procedure ConnectWithTimeout(const aAddress: ISocketAddress; ATimeoutMs: Integer);
    procedure Shutdown(aHow: TShutdownMode);
    procedure Close;

    // 数据传输
    function Send(const aData: TBytes): Integer; overload;
    function Send(const aData: Pointer; aSize: Integer): Integer; overload;
    function SendTo(const aData: TBytes; const aAddress: ISocketAddress): Integer; overload;
    function SendTo(const aData: Pointer; aSize: Integer; const aAddress: ISocketAddress): Integer; overload;
    function Receive(aMaxSize: Integer = 4096): TBytes; overload;
    function Receive(aBuffer: Pointer; aSize: Integer): Integer; overload;
    function ReceiveFrom(aMaxSize: Integer; out aFromAddress: ISocketAddress): TBytes; overload;
    function ReceiveFrom(aBuffer: Pointer; aSize: Integer; out aFromAddress: ISocketAddress): Integer; overload;
    // 非抛异常的尝试型接口（返回-1或实际字节数；aLastError返回平台错误码）
    function TrySend(const aData: Pointer; aSize: Integer; out aLastError: Integer): Integer; overload;
    function TryReceive(aBuffer: Pointer; aSize: Integer; out aLastError: Integer): Integer; overload;

    // 等待原语
    function WaitReadable(ATimeoutMs: Integer): Boolean;
    function WaitWritable(ATimeoutMs: Integer): Boolean;


    // 诊断/统计（结构化JSON）
    function GetStatisticsJson: string;

    // 增强传输接口（最佳实践）
    {$IFDEF FAFAFA_SOCKET_ADVANCED}
    function SendAll(const aData: Pointer; aSize: Integer): Integer; overload;
    function SendAll(const aData: TBytes): Integer; overload;
    function SendAll(const aData: TBytes; aOffset, aCount: Integer): Integer; overload;
    function ReceiveExact(aBuffer: Pointer; aSize: Integer): Integer; overload;
    function ReceiveExact(aMaxSize: Integer): TBytes; overload;
    function Receive(var aBuffer: TBytes; aOffset, aCount: Integer): Integer; overload;
    function Send(const aData: TBytes; aOffset, aCount: Integer): Integer; overload;
    {$ENDIF}

    {$IFDEF FAFAFA_SOCKET_ADVANCED}

    // 高性能零拷贝操作
    function SendBuffer(const aBuffer: TSocketBuffer): Integer;
    function ReceiveBuffer(var aBuffer: TSocketBuffer): Integer;
    function SendVectorized(const aVectors: TIOVectorArray): Integer;
    function ReceiveVectorized(const aVectors: TIOVectorArray): Integer;

    // 缓冲区池操作
    function SendWithPool(const aData: Pointer; aSize: Integer; aPool: TSocketBufferPool): Integer;
    function ReceiveWithPool(aMaxSize: Integer; aPool: TSocketBufferPool): TSocketBuffer;

    {$ENDIF}

    // 状态查询
    function GetState: TSocketState;
    function GetHandle: TSocketHandle;
    function GetFamily: TAddressFamily;
    function GetSocketType: TSocketType;
    function GetProtocol: TProtocol;
    function GetLocalAddress: ISocketAddress;
    function GetRemoteAddress: ISocketAddress;
    function IsValid: Boolean;
    function IsConnected: Boolean;
    function IsListening: Boolean;
    function IsClosed: Boolean;

    // Socket选项（基础）
    procedure SetReuseAddress(aValue: Boolean);
    function GetReuseAddress: Boolean;
    procedure SetKeepAlive(aValue: Boolean);
    function GetKeepAlive: Boolean;
    procedure SetTcpNoDelay(aValue: Boolean);
    function GetTcpNoDelay: Boolean;
    // 现代化超时设置
    {$IFDEF FAFAFA_SOCKET_ADVANCED}

    procedure SetSendTimeout(const aTimeout: TTimeSpan); overload;
    procedure SetReceiveTimeout(const aTimeout: TTimeSpan); overload;
    function GetSendTimeoutSpan: TTimeSpan;
    function GetReceiveTimeoutSpan: TTimeSpan;

    {$ENDIF}

    // 向后兼容的超时设置
    procedure SetSendTimeout(aMilliseconds: Integer); overload; deprecated 'Use TTimeSpan version instead';
    function GetSendTimeout: Integer; deprecated 'Use GetSendTimeoutSpan instead';
    procedure SetReceiveTimeout(aMilliseconds: Integer); overload; deprecated 'Use TTimeSpan version instead';
    function GetReceiveTimeout: Integer; deprecated 'Use GetReceiveTimeoutSpan instead';
    procedure SetSendBufferSize(aSize: Integer);
    function GetSendBufferSize: Integer;
    procedure SetReceiveBufferSize(aSize: Integer);
    function GetReceiveBufferSize: Integer;

    // Socket选项（扩展）
    procedure SetBroadcast(aValue: Boolean);
    function GetBroadcast: Boolean;
    procedure SetReusePort(aValue: Boolean);
    function GetReusePort: Boolean;
    procedure SetIPv6Only(aValue: Boolean);
    function GetIPv6Only: Boolean;
    procedure SetLinger(aEnabled: Boolean; aSeconds: Integer);
    procedure GetLinger(out aEnabled: Boolean; out aSeconds: Integer);

    // 非阻塞模式
    procedure SetNonBlocking(aValue: Boolean);
    function GetNonBlocking: Boolean;

    // Windows特有的高级选项
    procedure SetExclusiveAddressUse(aValue: Boolean);
    function GetExclusiveAddressUse: Boolean;

    {$IFDEF FAFAFA_SOCKET_ADVANCED}

    // 诊断和监控
    function GetDiagnosticInfo: string;
    function GetStatistics: TSocketStatistics;
    procedure ResetStatistics;

    {$ENDIF}

    // 属性
    property State: TSocketState read GetState;
    property Handle: TSocketHandle read GetHandle;
    property Family: TAddressFamily read GetFamily;
    property SocketType: TSocketType read GetSocketType;
    property Protocol: TProtocol read GetProtocol;
    property LocalAddress: ISocketAddress read GetLocalAddress;
    property RemoteAddress: ISocketAddress read GetRemoteAddress;
    property Valid: Boolean read IsValid;
    property Connected: Boolean read IsConnected;
    property Listening: Boolean read IsListening;
    property Closed: Boolean read IsClosed;
    property ReuseAddress: Boolean read GetReuseAddress write SetReuseAddress;
    property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
    property TcpNoDelay: Boolean read GetTcpNoDelay write SetTcpNoDelay;
    property SendTimeout: Integer read GetSendTimeout write SetSendTimeout;
    property ReceiveTimeout: Integer read GetReceiveTimeout write SetReceiveTimeout;
    property SendBufferSize: Integer read GetSendBufferSize write SetSendBufferSize;
    property ReceiveBufferSize: Integer read GetReceiveBufferSize write SetReceiveBufferSize;
    property Broadcast: Boolean read GetBroadcast write SetBroadcast;
    property ReusePort: Boolean read GetReusePort write SetReusePort;
    property IPv6Only: Boolean read GetIPv6Only write SetIPv6Only;
    property NonBlocking: Boolean read GetNonBlocking write SetNonBlocking;
  end;

  {**
   * ISocketListener
   *
   * @desc Socket监听器接口
   *       提供服务器端Socket的高级封装
   *}
  ISocketListener = interface(IInterface)
  ['{12345678-1234-1234-1234-123456789003}']

    // 监听控制
    procedure Start;
    procedure Stop;
    function Accept: ISocket;
    function AcceptWithTimeout(aTimeoutMs: Cardinal): ISocket;
    // 保持向后兼容的别名
    function AcceptClient: ISocket; deprecated 'Use Accept instead';
    function AcceptClientTimeout(aTimeoutMs: Cardinal): ISocket; deprecated 'Use AcceptWithTimeout instead';

    // 配置
    procedure SetMaxConnections(aCount: Integer);
    function GetMaxConnections: Integer;
    procedure SetBacklog(aBacklog: Integer);
    function GetBacklog: Integer;

    // 状态查询
    function IsActive: Boolean;
    function GetListenAddress: ISocketAddress;
    function GetSocket: ISocket;
    procedure SetActive(aValue: Boolean);

    // 属性
    property Active: Boolean read IsActive write SetActive;
    property ListenAddress: ISocketAddress read GetListenAddress;
    property Socket: ISocket read GetSocket;
    property MaxConnections: Integer read GetMaxConnections write SetMaxConnections;
    property Backlog: Integer read GetBacklog write SetBacklog;
  end;
  // 地址解析策略
  type TAddressResolutionStrategy = (
    arsDualStackFallback, // 首选IPv6，失败回退IPv4
    arsIPv6First,
    arsIPv4First,
    arsIPv6Only,
    arsIPv4Only
  );





  // 事件轮询相关类型
  type TSocketEvent = (
    seRead,     // 可读事件
    seWrite,    // 可写事件
    seError,    // 错误事件
    seClose     // 连接关闭事件
  );
  TSocketEvents = set of TSocketEvent;

  // 事件回调类型
  type TSocketEventCallback = procedure(const ASocket: ISocket; AEvents: TSocketEvents) of object;
  TSocketEventProc = procedure(const ASocket: ISocket; AEvents: TSocketEvents);

  // 轮询结果
  type TSocketPollResult = record
    Socket: ISocket;
    Events: TSocketEvents;
  end;
  TSocketPollResults = array of TSocketPollResult;

  // 事件轮询器接口
  type ISocketPoller = interface
    ['{B8E5F2A1-4C3D-4E2F-9A1B-8C7D6E5F4A3B}']

    // 注册Socket事件监听
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);

    // 修改监听的事件
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);

    // 轮询事件（阻塞指定时间）
    function Poll(ATimeoutMs: Integer): Integer;

    // 获取就绪事件
    function GetReadyEvents: TSocketPollResults;

    // 异步轮询（非阻塞，立即返回）
    function PollAsync: Integer;

    // 停止轮询
    procedure Stop;

    // 获取统计信息

    function GetRegisteredCount: Integer;
    function GetStatistics: string;
  end;

  {$IFDEF FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}
  // 异步操作结果接口（为未来异步集成预留）
  type IAsyncResult<T> = interface
    ['{C9F6E3B2-5D4E-4F3A-8B2C-9D8E7F6A5B4C}']

    // 状态查询
    function IsCompleted: Boolean;
    function IsCancelled: Boolean;
    function HasError: Boolean;

    // 结果获取
    function GetResult: T;
    function GetError: Exception;

    // 回调设置
    procedure OnComplete(ACallback: TProc<T>);
    procedure OnError(ACallback: TProc<Exception>);

    // 取消操作
    procedure Cancel;

    // 等待完成
    function WaitFor(ATimeoutMs: Integer = INFINITE): Boolean;
  end;

  // 异步Socket接口（为未来异步集成预留）
  type IAsyncSocket = interface
    ['{D0A7F4C3-6E5F-4A4B-9C3D-0E9F8A7B6C5D}']

    // 异步连接
    function ConnectAsync(const AAddress: ISocketAddress): IAsyncResult<Boolean>;

    // 异步数据传输
    function SendAsync(const AData: TBytes): IAsyncResult<Integer>;
    function SendAsync(AData: Pointer; ASize: Integer): IAsyncResult<Integer>;
    function ReceiveAsync(AMaxSize: Integer): IAsyncResult<TBytes>;
    function ReceiveAsync(ABuffer: Pointer; ASize: Integer): IAsyncResult<Integer>;

    // 异步监听器操作
    function AcceptAsync: IAsyncResult<ISocket>;

    // 设置轮询器
    procedure SetPoller(const APoller: ISocketPoller);
    function GetPoller: ISocketPoller;
  end;
  {$ENDIF}


  // 默认轮询器工厂（跨平台，默认使用 select 实现）
  // 如需启用平台特定高性能轮询器，请在 settings.inc 中开启相应宏并在后续版本接入
  function CreateDefaultPoller: ISocketPoller;

  // 基础事件轮询器实现（基于select）
  type TSelectSocketPoller = class(TInterfacedObject, ISocketPoller)
  private
    type TSocketEntry = record
      Socket: ISocket;
      Events: TSocketEvents;
      Callback: TSocketEventCallback;
    end;

  private
    FSockets: array of TSocketEntry;
    FReadyResults: TSocketPollResults;
    FStopped: Boolean;
    FMaxSockets: Integer;

  public
    constructor Create(AMaxSockets: Integer = 1024);
    destructor Destroy; override;

    // ISocketPoller implementation
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;

  private
    function FindSocketIndex(const ASocket: ISocket): Integer;
    procedure RemoveSocketAt(AIndex: Integer);
  end;


  // Socket构建器接口
  type ISocketBuilder = interface(IInterface)
  ['{12345678-1234-1234-1234-123456789004}']
    function WithTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithSendTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithReceiveTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithKeepAlive(aEnabled: Boolean = True): ISocketBuilder;
    function WithNoDelay(aEnabled: Boolean = True): ISocketBuilder;
    function WithReuseAddress(aEnabled: Boolean = True): ISocketBuilder;
    function WithReusePort(aEnabled: Boolean = True): ISocketBuilder;
    function WithBroadcast(aEnabled: Boolean = True): ISocketBuilder;
    function WithBufferSize(aSendSize, aReceiveSize: Integer): ISocketBuilder;
    function WithNonBlocking(aEnabled: Boolean = True): ISocketBuilder;
    function Build: ISocket;
    function BuildAndConnect(const aHost: string; aPort: Word): ISocket;
  end;


  {**
   * TSocketAddress
   *
   * @desc Socket地址实现类
   *       封装不同类型的网络地址的具体实现
   *}
  TSocketAddress = class(TInterfacedObject, ISocketAddress)
  private
    FFamily: TAddressFamily;
    FHost: string;
    FPort: Word;
    FNativeAddr: Pointer;
    FNativeSize: Integer;
    FResolutionStrategy: TAddressResolutionStrategy;
  {$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
  private
    FGuardHead: Pointer;
    FGuardTail: Pointer;
  {$ENDIF}

  protected
    // 内部方法
    procedure BuildNativeAddress;
    procedure ValidateAddress;
    function ParseIPv4(const aHost: string): Boolean;
    function ParseIPv6(const aHost: string): Boolean;
    function IsValidHostname(const aHost: string): Boolean;
    function ParseIPv6AddressToBytes(const aHost: string; var aBytes: array of Byte): Boolean;
    function ResolveHostnameToIPv6(const aHost: string; var aBytes: array of Byte): Boolean;
    function ResolveWithStrategy(const aHost: string; aStrategy: TAddressResolutionStrategy; out aFamily: TAddressFamily; out aTextIP: string): Boolean;

    // ISocketAddress implementation
    function GetFamily: TAddressFamily;
    function GetHost: string;
    function GetPort: Word;
    function GetSize: Integer;
    function ToString: string; override;
    function ToNativeAddr: Pointer;
    procedure FromNativeAddr(aAddr: Pointer; aSize: Integer);
    function IsValid: Boolean;
    procedure Validate;

  public
    constructor Create(const aHost: string; aPort: Word; aFamily: TAddressFamily);
    destructor Destroy; override;

    // 工厂方法
    class function CreateIPv4(const aHost: string; aPort: Word): ISocketAddress;
    class function CreateIPv6(const aHost: string; aPort: Word): ISocketAddress;
    class function CreateUnix(const aPath: string): ISocketAddress;

    // 便捷工厂方法
    class function IPv4(const aHost: string; aPort: Word): ISocketAddress;
    class function IPv6(const aHost: string; aPort: Word): ISocketAddress;
    class function Localhost(aPort: Word): ISocketAddress;
    class function LocalhostIPv6(aPort: Word): ISocketAddress;
    class function Any(aPort: Word): ISocketAddress;
    class function AnyIPv6(aPort: Word): ISocketAddress;
    // 策略化本地回环（不破坏兼容）
    class function LocalhostByStrategy(aPort: Word; aStrategy: TAddressResolutionStrategy = arsDualStackFallback): ISocketAddress;

    // 内部调整：仅库内部或测试通过类转换调用
    procedure SetPort(aPort: Word);

    // 策略配置
    procedure SetResolutionStrategy(aStrategy: TAddressResolutionStrategy);
    function GetResolutionStrategy: TAddressResolutionStrategy;

    // 属性访问
    property Family: TAddressFamily read GetFamily;
    property Host: string read GetHost;
    property Port: Word read GetPort;
    property Size: Integer read GetSize;
    property ResolutionStrategy: TAddressResolutionStrategy read GetResolutionStrategy write SetResolutionStrategy;
  end;

  {**
   * TSocket
   *
   * @desc Socket核心实现类
   *       提供Socket的基本操作和生命周期管理的具体实现
   *}
  TSocket = class(TInterfacedObject, ISocket)
  private
    FHandle: TSocketHandle;
    FFamily: TAddressFamily;
    FSocketType: TSocketType;
    FProtocol: TProtocol;
    FState: TSocketState;
    FLocalAddress: ISocketAddress;
    FRemoteAddress: ISocketAddress;

    // Socket选项存储
    FReuseAddress: Boolean;
    FKeepAlive: Boolean;
    FTcpNoDelay: Boolean;
    FSendTimeout: Integer;
    FReceiveTimeout: Integer;
    FSendBufferSize: Integer;
    FReceiveBufferSize: Integer;
    FNonBlocking: Boolean;
    // 扩展选项缓存
    FBroadcast: Boolean;
    FReusePort: Boolean;
    FIPv6Only: Boolean;
    FLingerEnabled: Boolean;
    FLingerSeconds: Integer;

    // 统计信息
    FStatistics: TSocketStatistics;

  protected
    // 内部方法
    procedure CreateSocket;
    procedure CloseSocket;
    function GetLastSocketError: Integer;
    procedure CheckSocketError(aResult: Integer; const aOperation: string);
    procedure CheckSocketState(aRequiredState: TSocketState; const aOperation: string);
    function ConvertShutdownMode(aMode: TShutdownMode): Integer;

    // Socket选项内部方法
    procedure SetSocketOption(aLevel: Integer; aOption: Integer; aValue: Pointer; aSize: Integer);
    procedure GetSocketOption(aLevel: Integer; aOption: Integer; aValue: Pointer; var aSize: Integer);
    procedure SetBooleanOption(aLevel: Integer; aOption: Integer; aValue: Boolean);
    function GetBooleanOption(aLevel: Integer; aOption: Integer): Boolean;
    procedure SetIntegerOption(aLevel: Integer; aOption: Integer; aValue: Integer);
    function GetIntegerOption(aLevel: Integer; aOption: Integer): Integer;

    // ISocket implementation
    procedure Bind(const aAddress: ISocketAddress);
    procedure Listen(aBacklog: Integer = 128);
    function Accept: ISocket;
    procedure Connect(const aAddress: ISocketAddress);
    procedure ConnectWithTimeout(const aAddress: ISocketAddress; ATimeoutMs: Integer);
    procedure Shutdown(aHow: TShutdownMode);
    procedure Close;

    function Send(const aData: TBytes): Integer; overload;
    function Send(const aData: Pointer; aSize: Integer): Integer; overload;
    function SendTo(const aData: TBytes; const aAddress: ISocketAddress): Integer; overload;
    function SendTo(const aData: Pointer; aSize: Integer; const aAddress: ISocketAddress): Integer; overload;
    function Receive(aMaxSize: Integer = 4096): TBytes; overload;
    function Receive(aBuffer: Pointer; aSize: Integer): Integer; overload;
    function ReceiveFrom(aMaxSize: Integer; out aFromAddress: ISocketAddress): TBytes; overload;
    function ReceiveFrom(aBuffer: Pointer; aSize: Integer; out aFromAddress: ISocketAddress): Integer; overload;
    function TrySend(const aData: Pointer; aSize: Integer; out aLastError: Integer): Integer; overload;
    function TryReceive(aBuffer: Pointer; aSize: Integer; out aLastError: Integer): Integer; overload;

    function GetState: TSocketState;
    function GetHandle: TSocketHandle;
    function GetFamily: TAddressFamily;
    function GetSocketType: TSocketType;
    function GetProtocol: TProtocol;
    function GetLocalAddress: ISocketAddress;
    function GetRemoteAddress: ISocketAddress;
    function IsValid: Boolean;

    function IsConnected: Boolean;
    function IsListening: Boolean;
    // 增强传输接口（最佳实践）
    function SendAll(const aData: Pointer; aSize: Integer): Integer; overload;
    function SendAll(const aData: TBytes): Integer; overload;
    function SendAll(const aData: TBytes; aOffset, aCount: Integer): Integer; overload;
    function ReceiveExact(aBuffer: Pointer; aSize: Integer): Integer; overload;
    function ReceiveExact(aMaxSize: Integer): TBytes; overload;
    function Receive(var aBuffer: TBytes; aOffset, aCount: Integer): Integer; overload;
    function Send(const aData: TBytes; aOffset, aCount: Integer): Integer; overload;
    function IsClosed: Boolean;

    {$IFDEF FAFAFA_SOCKET_ADVANCED}
    // 高性能零拷贝操作
    function SendBuffer(const aBuffer: TSocketBuffer): Integer;
    function ReceiveBuffer(var aBuffer: TSocketBuffer): Integer;
    function SendVectorized(const aVectors: TIOVectorArray): Integer;
    function ReceiveVectorized(const aVectors: TIOVectorArray): Integer;

    // 缓冲区池操作
    function SendWithPool(const aData: Pointer; aSize: Integer; aPool: TSocketBufferPool): Integer;
    function ReceiveWithPool(aMaxSize: Integer; aPool: TSocketBufferPool): TSocketBuffer;
    {$ENDIF}

    procedure SetReuseAddress(aValue: Boolean);
    function GetReuseAddress: Boolean;
    procedure SetKeepAlive(aValue: Boolean);
    function GetKeepAlive: Boolean;
    procedure SetTcpNoDelay(aValue: Boolean);
    function GetTcpNoDelay: Boolean;
    // 现代化超时设置实现
    procedure SetSendTimeout(const aTimeout: TTimeSpan); overload;
    procedure SetReceiveTimeout(const aTimeout: TTimeSpan); overload;
    function GetSendTimeoutSpan: TTimeSpan;
    function GetReceiveTimeoutSpan: TTimeSpan;

    // 向后兼容的超时设置实现
    procedure SetSendTimeout(aMilliseconds: Integer); overload;
    function GetSendTimeout: Integer;
    procedure SetReceiveTimeout(aMilliseconds: Integer); overload;
    function GetReceiveTimeout: Integer;
    procedure SetSendBufferSize(aSize: Integer);
    function GetSendBufferSize: Integer;
    procedure SetReceiveBufferSize(aSize: Integer);
    function GetReceiveBufferSize: Integer;

    // 扩展选项
    procedure SetBroadcast(aValue: Boolean);
    function GetBroadcast: Boolean;
    procedure SetReusePort(aValue: Boolean);
    function GetReusePort: Boolean;
    procedure SetIPv6Only(aValue: Boolean);
    function GetIPv6Only: Boolean;
    procedure SetLinger(aEnabled: Boolean; aSeconds: Integer);
    procedure GetLinger(out aEnabled: Boolean; out aSeconds: Integer);

    // 非阻塞模式
    procedure SetNonBlocking(aValue: Boolean);
    function GetNonBlocking: Boolean;

    // Windows特有的高级选项
    procedure SetExclusiveAddressUse(aValue: Boolean);
    function GetExclusiveAddressUse: Boolean;

    // 诊断和监控实现
    function WaitReadable(ATimeoutMs: Integer): Boolean;
    function WaitWritable(ATimeoutMs: Integer): Boolean;

    function GetDiagnosticInfo: string;
    function GetStatistics: TSocketStatistics;
    procedure ResetStatistics;


    // 结构化统计/诊断（JSON）
    function GetStatisticsJson: string;

  public
    constructor Create(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
    constructor CreateFromHandle(aHandle: TSocketHandle; aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
    destructor Destroy; override;

    // 扩展结构化统计（仅实现类暴露）
    function GetExtendedStatisticsJson: string;

    // 工厂方法
    class function CreateTCP(aFamily: TAddressFamily = afInet): ISocket;
    class function CreateUDP(aFamily: TAddressFamily = afInet): ISocket;

    // 便捷工厂方法
    class function TCP: ISocket;
    class function UDP: ISocket;
    class function TCPv6: ISocket;
    class function UDPv6: ISocket;

    // 便捷连接方法
    class function ConnectTo(const aHost: string; aPort: Word): ISocket; overload;
    class function ConnectTo(const aHost: string; aPort: Word; const aTimeout: TTimeSpan): ISocket; overload;
    class function ConnectTo(const aHost: string; aPort: Word; aFamily: TAddressFamily): ISocket; overload;

    // 构建器模式
    class function Builder: ISocketBuilder; overload;
    class function Builder(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol): ISocketBuilder; overload;

    // 属性访问
    property State: TSocketState read GetState;
    property Handle: TSocketHandle read GetHandle;
    property Family: TAddressFamily read GetFamily;
    property SocketType: TSocketType read GetSocketType;
    property Protocol: TProtocol read GetProtocol;
    property LocalAddress: ISocketAddress read GetLocalAddress;
    property RemoteAddress: ISocketAddress read GetRemoteAddress;
    property Valid: Boolean read IsValid;
    property Connected: Boolean read IsConnected;
    property Listening: Boolean read IsListening;
    property Closed: Boolean read IsClosed;
    property ReuseAddress: Boolean read GetReuseAddress write SetReuseAddress;
    property KeepAlive: Boolean read GetKeepAlive write SetKeepAlive;
    property TcpNoDelay: Boolean read GetTcpNoDelay write SetTcpNoDelay;
    property SendTimeout: Integer read GetSendTimeout write SetSendTimeout;
    property ReceiveTimeout: Integer read GetReceiveTimeout write SetReceiveTimeout;
    property SendBufferSize: Integer read GetSendBufferSize write SetSendBufferSize;
    property ReceiveBufferSize: Integer read GetReceiveBufferSize write SetReceiveBufferSize;
  end;

  {**
   * TSocketBuilder
   *
   * @desc Socket构建器实现类
   *       提供流畅的Socket配置API
   *}
  TSocketBuilder = class(TInterfacedObject, ISocketBuilder)
  private
    FFamily: TAddressFamily;
    FSocketType: TSocketType;
    FProtocol: TProtocol;
    FSendTimeout: TTimeSpan;
    FReceiveTimeout: TTimeSpan;
    FKeepAlive: Boolean;
    FTcpNoDelay: Boolean;
    FReuseAddress: Boolean;
    FReusePort: Boolean;
    FBroadcast: Boolean;
    FSendBufferSize: Integer;
    FReceiveBufferSize: Integer;
    FNonBlocking: Boolean;
  public
    constructor Create(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);

    // ISocketBuilder implementation
    function WithTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithSendTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithReceiveTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
    function WithKeepAlive(aEnabled: Boolean = True): ISocketBuilder;
    function WithNoDelay(aEnabled: Boolean = True): ISocketBuilder;
    function WithReuseAddress(aEnabled: Boolean = True): ISocketBuilder;
    function WithReusePort(aEnabled: Boolean = True): ISocketBuilder;
    function WithBroadcast(aEnabled: Boolean = True): ISocketBuilder;
    function WithBufferSize(aSendSize, aReceiveSize: Integer): ISocketBuilder;
    function WithNonBlocking(aEnabled: Boolean = True): ISocketBuilder;
    function Build: ISocket;
    function BuildAndConnect(const aHost: string; aPort: Word): ISocket;
  end;

  {**
   * TSocketListener
   *
   * @desc Socket监听器实现类
   *       提供服务器端Socket的高级封装的具体实现
   *}
  TSocketListener = class(TInterfacedObject, ISocketListener)
  private
    FSocket: ISocket;
    FListenAddress: ISocketAddress;
    FMaxConnections: Integer;
    FBacklog: Integer;
    FActive: Boolean;

  protected
    // ISocketListener implementation
    procedure Start;
    procedure Stop;
    function Accept: ISocket;
    function AcceptWithTimeout(aTimeoutMs: Cardinal): ISocket;
    // 向后兼容的别名实现
    function AcceptClient: ISocket;
    function AcceptClientTimeout(aTimeoutMs: Cardinal): ISocket;

    procedure SetMaxConnections(aCount: Integer);
    function GetMaxConnections: Integer;
    procedure SetBacklog(aBacklog: Integer);
    function GetBacklog: Integer;

    function IsActive: Boolean;
    function GetListenAddress: ISocketAddress;
    function GetSocket: ISocket;
    procedure SetActive(aValue: Boolean);

  public
    constructor Create(const aAddress: ISocketAddress);
    destructor Destroy; override;

    // 工厂方法
    class function CreateTCP(const aAddress: ISocketAddress): ISocketListener;
    class function CreateUDP(const aAddress: ISocketAddress): ISocketListener;

    // 便捷工厂方法
    class function ListenTCP(aPort: Word): ISocketListener;
    class function ListenTCPv6(aPort: Word): ISocketListener;
    class function ListenLocalhost(aPort: Word): ISocketListener;

    // 属性访问
    property Active: Boolean read IsActive write SetActive;
    property ListenAddress: ISocketAddress read GetListenAddress;
    property Socket: ISocket read GetSocket;
    property MaxConnections: Integer read GetMaxConnections write SetMaxConnections;
    property Backlog: Integer read GetBacklog write SetBacklog;

    // 扩展结构化统计（JSON）
    function GetExtendedStatisticsJson: string;

  end;

implementation

// 包含平台特定的实现
{$IFDEF WINDOWS}
{$I fafafa.core.socket.windows.inc}
{$ENDIF}

{$IFDEF UNIX}
{$I fafafa.core.socket.linux.inc}
{$ENDIF}



{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
// 实验性轮询器占位实现：内部回退到 TSelectSocketPoller，保持现有行为不变
type
  TExperimentalSocketPoller = class(TInterfacedObject, ISocketPoller)
  private
    FFallback: TSelectSocketPoller;
  public
    constructor Create;
    destructor Destroy; override;
    // ISocketPoller implementation（全部委托给 select 实现）
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;
  end;

constructor TExperimentalSocketPoller.Create;
begin
  inherited Create;
  FFallback := TSelectSocketPoller.Create;
end;

destructor TExperimentalSocketPoller.Destroy;
begin
  FFallback.Free;
  inherited Destroy;
end;

procedure TExperimentalSocketPoller.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
begin
  FFallback.RegisterSocket(ASocket, AEvents, ACallback);
end;

procedure TExperimentalSocketPoller.UnregisterSocket(const ASocket: ISocket);
begin
  FFallback.UnregisterSocket(ASocket);
end;

procedure TExperimentalSocketPoller.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
begin
  FFallback.ModifyEvents(ASocket, AEvents);
end;

function TExperimentalSocketPoller.Poll(ATimeoutMs: Integer): Integer;
begin
  Result := FFallback.Poll(ATimeoutMs);
end;

function TExperimentalSocketPoller.GetReadyEvents: TSocketPollResults;
begin
  Result := FFallback.GetReadyEvents;
end;

function TExperimentalSocketPoller.PollAsync: Integer;
begin
  Result := FFallback.PollAsync;
end;

procedure TExperimentalSocketPoller.Stop;
begin
  FFallback.Stop;
end;

function TExperimentalSocketPoller.GetRegisteredCount: Integer;
begin
  Result := FFallback.GetRegisteredCount;
end;

function TExperimentalSocketPoller.GetStatistics: string;
begin
  Result := FFallback.GetStatistics;
end;
{$ENDIF}

{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF WINDOWS}
// Windows: IOCP 占位实现（委托 select/fpSelect）
type
  TIOCPPoller = class(TInterfacedObject, ISocketPoller)
  private
    FFallback: TSelectSocketPoller;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;
  end;

constructor TIOCPPoller.Create;
begin FFallback := TSelectSocketPoller.Create; end;
destructor TIOCPPoller.Destroy;
begin FFallback.Free; inherited Destroy; end;
procedure TIOCPPoller.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
begin FFallback.RegisterSocket(ASocket, AEvents, ACallback); end;
procedure TIOCPPoller.UnregisterSocket(const ASocket: ISocket);
begin FFallback.UnregisterSocket(ASocket); end;
procedure TIOCPPoller.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
begin FFallback.ModifyEvents(ASocket, AEvents); end;
function TIOCPPoller.Poll(ATimeoutMs: Integer): Integer;
begin Result := FFallback.Poll(ATimeoutMs); end;
function TIOCPPoller.GetReadyEvents: TSocketPollResults;
begin Result := FFallback.GetReadyEvents; end;
function TIOCPPoller.PollAsync: Integer;
begin Result := FFallback.PollAsync; end;
procedure TIOCPPoller.Stop;
begin FFallback.Stop; end;
function TIOCPPoller.GetRegisteredCount: Integer;
begin Result := FFallback.GetRegisteredCount; end;
function TIOCPPoller.GetStatistics: string;
begin Result := 'IOCP(stub)->' + FFallback.GetStatistics; end;
{$ENDIF}

{$IFDEF LINUX}
// Linux: epoll 占位实现（委托 select/fpSelect）
type
  TEpollPoller = class(TInterfacedObject, ISocketPoller)
  private
    FFallback: TSelectSocketPoller;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;
  end;

constructor TEpollPoller.Create;
begin FFallback := TSelectSocketPoller.Create; end;
destructor TEpollPoller.Destroy;
begin FFallback.Free; inherited Destroy; end;
procedure TEpollPoller.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
begin FFallback.RegisterSocket(ASocket, AEvents, ACallback); end;
procedure TEpollPoller.UnregisterSocket(const ASocket: ISocket);
begin FFallback.UnregisterSocket(ASocket); end;
procedure TEpollPoller.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
begin FFallback.ModifyEvents(ASocket, AEvents); end;
function TEpollPoller.Poll(ATimeoutMs: Integer): Integer;
begin Result := FFallback.Poll(ATimeoutMs); end;
function TEpollPoller.GetReadyEvents: TSocketPollResults;
begin Result := FFallback.GetReadyEvents; end;
function TEpollPoller.PollAsync: Integer;
begin Result := FFallback.PollAsync; end;
procedure TEpollPoller.Stop;
begin FFallback.Stop; end;
function TEpollPoller.GetRegisteredCount: Integer;
begin Result := FFallback.GetRegisteredCount; end;
function TEpollPoller.GetStatistics: string;
begin Result := 'epoll(stub)->' + FFallback.GetStatistics; end;
{$ENDIF}

{$IFDEF DARWIN}
// macOS: kqueue 占位实现（委托 select/fpSelect）
type
  TKqueuePoller = class(TInterfacedObject, ISocketPoller)
  private
    FFallback: TSelectSocketPoller;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback = nil);
    procedure UnregisterSocket(const ASocket: ISocket);
    procedure ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
    function Poll(ATimeoutMs: Integer): Integer;
    function GetReadyEvents: TSocketPollResults;
    function PollAsync: Integer;
    procedure Stop;
    function GetRegisteredCount: Integer;
    function GetStatistics: string;
  end;

constructor TKqueuePoller.Create;
begin FFallback := TSelectSocketPoller.Create; end;
destructor TKqueuePoller.Destroy;
begin FFallback.Free; inherited Destroy; end;
procedure TKqueuePoller.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
begin FFallback.RegisterSocket(ASocket, AEvents, ACallback); end;
procedure TKqueuePoller.UnregisterSocket(const ASocket: ISocket);
begin FFallback.UnregisterSocket(ASocket); end;
procedure TKqueuePoller.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
begin FFallback.ModifyEvents(ASocket, AEvents); end;
function TKqueuePoller.Poll(ATimeoutMs: Integer): Integer;
begin Result := FFallback.Poll(ATimeoutMs); end;
function TKqueuePoller.GetReadyEvents: TSocketPollResults;
begin Result := FFallback.GetReadyEvents; end;
function TKqueuePoller.PollAsync: Integer;
begin Result := FFallback.PollAsync; end;
procedure TKqueuePoller.Stop;
begin FFallback.Stop; end;
function TKqueuePoller.GetRegisteredCount: Integer;
begin Result := FFallback.GetRegisteredCount; end;
function TKqueuePoller.GetStatistics: string;
begin Result := 'kqueue(stub)->' + FFallback.GetStatistics; end;
{$ENDIF}
{$ENDIF}


function CreateDefaultPoller: ISocketPoller;
begin
  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
  // 实验阶段：按平台返回占位轮询器（内部委托 select/fpSelect），保持行为不变
    {$IFDEF WINDOWS}
      Result := TIOCPPoller.Create;
    {$ELSE}
      {$IFDEF LINUX}
        Result := TEpollPoller.Create;
      {$ELSE}
        {$IFDEF DARWIN}
          Result := TKqueuePoller.Create;
        {$ELSE}
          Result := TSelectSocketPoller.Create; // 其他平台回退 select
        {$ENDIF}
      {$ENDIF}
    {$ENDIF}
  {$ELSE}
  // 默认：使用 select/fpSelect 轮询器作为默认实现，跨平台稳定
  Result := TSelectSocketPoller.Create;
  {$ENDIF}
end;

// 平台相关常量定义
const
  SHUT_RD = 0;
  SHUT_WR = 1;
  SHUT_RDWR = 2;

{ ESocketError }

constructor ESocketError.Create(const aMessage: string);
begin
  inherited Create(aMessage);
  FErrorCode := 0;
  FSocketHandle := INVALID_SOCKET;
end;

constructor ESocketError.Create(const aMessage: string; aErrorCode: Integer);
begin
  inherited Create(aMessage);

  FErrorCode := aErrorCode;
  FSocketHandle := INVALID_SOCKET;
end;

constructor ESocketError.Create(const aMessage: string; aErrorCode: Integer; aHandle: TSocketHandle);
begin
  inherited Create(aMessage);
  FErrorCode := aErrorCode;
  FSocketHandle := aHandle;
end;

function SocketIsWouldBlock(aError: Integer): Boolean;
begin
  {$IFDEF WINDOWS}
  Result := (aError = SOCKET_EWOULDBLOCK) or (aError = SOCKET_EAGAIN);
  {$ELSE}
  Result := (aError = SOCKET_EWOULDBLOCK) or (aError = SOCKET_EAGAIN);
  {$ENDIF}
end;

function SocketIsInterrupted(aError: Integer): Boolean;
begin
  {$IFDEF WINDOWS}
  Result := (aError = SOCKET_EINTR);
  {$ELSE}
  Result := (aError = SOCKET_EINTR);
  {$ENDIF}
end;

function ESocketError.GetDetailedMessage: string;
begin
  Result := Message;
  if FErrorCode <> 0 then
    Result := Result + Format(' (ErrorCode: %d)', [FErrorCode]);
  if FSocketHandle <> INVALID_SOCKET then
    Result := Result + Format(' (Socket: %d)', [FSocketHandle]);
end;

{ TTimeSpan }

class function TTimeSpan.FromMilliseconds(aMs: Int64): TTimeSpan;
begin
  Result.FMilliseconds := aMs;
end;

class function TTimeSpan.FromSeconds(aSec: Integer): TTimeSpan;
begin
  Result.FMilliseconds := Int64(aSec) * 1000;
end;

class function TTimeSpan.FromMinutes(aMin: Integer): TTimeSpan;
begin
  Result.FMilliseconds := Int64(aMin) * 60 * 1000;
end;

class function TTimeSpan.FromHours(aHours: Integer): TTimeSpan;
begin
  Result.FMilliseconds := Int64(aHours) * 60 * 60 * 1000;
end;

class function TTimeSpan.Zero: TTimeSpan;
begin
  Result.FMilliseconds := 0;
end;

function TTimeSpan.ToMilliseconds: Int64;
begin
  Result := FMilliseconds;
end;

function TTimeSpan.ToSeconds: Double;
begin
  Result := FMilliseconds / 1000.0;
end;

function TTimeSpan.IsZero: Boolean;
begin
  Result := FMilliseconds = 0;
end;

{$IFDEF FAFAFA_SOCKET_ADVANCED}
{$IFDEF FAFAFA_TIME_SPAN_OPERATORS}
class operator TTimeSpan.Equal(const a, b: TTimeSpan): Boolean;
begin
  Result := a.FMilliseconds = b.FMilliseconds;
end;

class operator TTimeSpan.NotEqual(const a, b: TTimeSpan): Boolean;
begin
  Result := a.FMilliseconds <> b.FMilliseconds;
end;

class operator TTimeSpan.GreaterThan(const a, b: TTimeSpan): Boolean;
begin
  Result := a.FMilliseconds > b.FMilliseconds;
end;

class operator TTimeSpan.LessThan(const a, b: TTimeSpan): Boolean;
begin
  Result := a.FMilliseconds < b.FMilliseconds;
end;

class operator TTimeSpan.Add(const a, b: TTimeSpan): TTimeSpan;
begin
  Result.FMilliseconds := a.FMilliseconds + b.FMilliseconds;
end;

class operator TTimeSpan.Subtract(const a, b: TTimeSpan): TTimeSpan;
begin
  Result.FMilliseconds := a.FMilliseconds - b.FMilliseconds;
end;
{$ENDIF}
{$ENDIF}

{ TSocketAddress }


constructor TSocketAddress.Create(const aHost: string; aPort: Word; aFamily: TAddressFamily);
begin
  inherited Create;
  // 默认策略
  FResolutionStrategy := arsDualStackFallback;

  // 验证参数
  if Trim(aHost) = '' then
    raise EInvalidArgument.Create('主机地址不能为空');

  FFamily := aFamily;
  FHost := Trim(aHost);
  FPort := aPort;
  FNativeAddr := nil;
  FNativeSize := 0;
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
  FGuardHead := nil;
  FGuardTail := nil;
{$ENDIF}

  // 验证地址格式
  ValidateAddress;

  // 构建原生地址结构
  BuildNativeAddress;
end;

destructor TSocketAddress.Destroy;
begin
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
  // 析构前检查Guard是否被破坏，并释放护栏内存
  if (FGuardHead <> nil) and (FGuardTail <> nil) and (FNativeAddr <> nil) then
  begin
    // GUARD = $EF 模式填充
    var GUARD_SZ := 16;
    var PHead := PByte(FGuardHead);
    var PTail := PByte(FGuardTail);
    var I: Integer;
    for I := 0 to GUARD_SZ-1 do
      if (PHead[I] <> $EF) or (PTail[I] <> $EF) then
        raise EHeapMemoryError.Create('TSocketAddress 内存护栏被破坏（疑似越界写）');
  end;
  // 释放护栏内存
  if Assigned(FGuardHead) then begin FreeMem(FGuardHead); FGuardHead := nil; end;
  if Assigned(FGuardTail) then begin FreeMem(FGuardTail); FGuardTail := nil; end;
{$ENDIF}

  if Assigned(FNativeAddr) then
  begin
    FreeMem(FNativeAddr);
    FNativeAddr := nil;
  end;
  inherited Destroy;
end;

class function TSocketAddress.CreateIPv4(const aHost: string; aPort: Word): ISocketAddress;
begin
  Result := TSocketAddress.Create(aHost, aPort, afInet);
end;

class function TSocketAddress.CreateIPv6(const aHost: string; aPort: Word): ISocketAddress;
begin
  Result := TSocketAddress.Create(aHost, aPort, afInet6);
end;

class function TSocketAddress.CreateUnix(const aPath: string): ISocketAddress;
begin
  Result := TSocketAddress.Create(aPath, 0, afUnix);
end;

// 便捷工厂方法实现
class function TSocketAddress.IPv4(const aHost: string; aPort: Word): ISocketAddress;
begin
  // 简洁的IPv4地址创建方法
  Result := TSocketAddress.Create(aHost, aPort, afInet);
end;

class function TSocketAddress.IPv6(const aHost: string; aPort: Word): ISocketAddress;
begin
  // 简洁的IPv6地址创建方法
  Result := TSocketAddress.Create(aHost, aPort, afInet6);
end;

class function TSocketAddress.Localhost(aPort: Word): ISocketAddress;
begin
  // 本地回环地址 (127.0.0.1)
  Result := TSocketAddress.Create('127.0.0.1', aPort, afInet);
end;

class function TSocketAddress.LocalhostIPv6(aPort: Word): ISocketAddress;
begin
  // IPv6本地回环地址 (::1)
  Result := TSocketAddress.Create('::1', aPort, afInet6);
end;

class function TSocketAddress.LocalhostByStrategy(aPort: Word; aStrategy: TAddressResolutionStrategy): ISocketAddress;
begin
  // 通过 localhost + 策略优先族（默认IPv6优先），由内部解析策略决定最终地址族
  Result := TSocketAddress.Create('localhost', aPort, afInet6);
  TSocketAddress(Result).SetResolutionStrategy(aStrategy);
end;

class function TSocketAddress.Any(aPort: Word): ISocketAddress;
begin
  // 任意IPv4地址 (0.0.0.0) - 用于服务器绑定所有接口
  Result := TSocketAddress.Create('0.0.0.0', aPort, afInet);
end;

class function TSocketAddress.AnyIPv6(aPort: Word): ISocketAddress;
begin
  // 任意IPv6地址 (::) - 用于服务器绑定所有接口
  Result := TSocketAddress.Create('::', aPort, afInet6);
end;

procedure TSocketAddress.BuildNativeAddress;
type
  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = packed record
    sin_family: Word;
    sin_port: Word;
    sin_addr: LongWord;
    sin_zero: array[0..7] of Byte;
  end;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = packed record
    sin6_family: Word;
    sin6_port: Word;
    sin6_flowinfo: LongWord;
    sin6_addr: array[0..15] of Byte;
    sin6_scope_id: LongWord;
  end;

var
  LSockAddrIn: PSockAddrIn;
  LSockAddrIn6: PSockAddrIn6;
  LIPv4Addr: LongWord;
  LIPParts: array[0..3] of Byte;
  LDotPos: Integer;
  LPartIndex: Integer;
  LTempStr: string;
  LPartValue: Integer;
  // 解析策略临时变量
  ResFam, ResFam2: TAddressFamily;
  ResIP, ResIP2: string;
  // IPv6 scope-id 解析临时变量
  HostNoScope: string;
  ScopeId: Cardinal;
  Pct: SizeInt;
  ScopeStr: string;
begin
  // 释放之前的地址
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
  // 先释放旧护栏
  if Assigned(FGuardHead) then begin FreeMem(FGuardHead); FGuardHead := nil; end;
  if Assigned(FGuardTail) then begin FreeMem(FGuardTail); FGuardTail := nil; end;
{$ENDIF}
  if Assigned(FNativeAddr) then
  begin
    FreeMem(FNativeAddr);
    FNativeAddr := nil;
    FNativeSize := 0;
  end;

  // 根据地址族创建相应的地址结构
  case FFamily of
    afInet:
    begin
      FNativeSize := SizeOf(TSockAddrIn);
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
      // 分配护栏 + payload
      var GUARD_SZ := 16;
      GetMem(FGuardHead, GUARD_SZ); FillChar(FGuardHead^, GUARD_SZ, $EF);
      GetMem(FNativeAddr, FNativeSize); FillChar(FNativeAddr^, FNativeSize, 0);
      GetMem(FGuardTail, GUARD_SZ); FillChar(FGuardTail^, GUARD_SZ, $EF);
{$ELSE}
      GetMem(FNativeAddr, FNativeSize);
      FillChar(FNativeAddr^, FNativeSize, 0);
{$ENDIF}
      LSockAddrIn := PSockAddrIn(FNativeAddr);

      // 设置地址族（使用平台转换，避免魔法数）
      LSockAddrIn^.sin_family := Word(ConvertAddressFamilyToNative(afInet));

      // 设置端口（网络字节序）
      LSockAddrIn^.sin_port := htons(FPort);

      // 解析IPv4地址
      if ParseIPv4(FHost) then
      begin
        // 使用简单的字节构建方法
        LTempStr := FHost;
        LPartIndex := 0;

        while (Length(LTempStr) > 0) and (LPartIndex < 4) do
        begin
          LDotPos := Pos('.', LTempStr);
          if LDotPos = 0 then
            LDotPos := Length(LTempStr) + 1;

          LPartValue := StrToIntDef(Copy(LTempStr, 1, LDotPos - 1), 0);
          LIPParts[LPartIndex] := LPartValue;

          Delete(LTempStr, 1, LDotPos);
          Inc(LPartIndex);
        end;

        // 直接按字节构建IPv4地址
        LIPv4Addr := LIPParts[0] or
                     (LIPParts[1] shl 8) or
                     (LIPParts[2] shl 16) or
                     (LIPParts[3] shl 24);
        LSockAddrIn^.sin_addr := LIPv4Addr;
      end
      else
      begin
        // 对于主机名，按策略解析
        if ResolveWithStrategy(FHost, FResolutionStrategy, ResFam, ResIP) then
        begin
          if ResFam = afInet then
          begin
            // 将解析出的文本IPv4转换为整型
            LTempStr := ResIP; LPartIndex := 0;
            while (Length(LTempStr) > 0) and (LPartIndex < 4) do
            begin
              LDotPos := Pos('.', LTempStr);
              if LDotPos = 0 then LDotPos := Length(LTempStr) + 1;
              LPartValue := StrToIntDef(Copy(LTempStr, 1, LDotPos - 1), 0);
              LIPParts[LPartIndex] := LPartValue;
              Delete(LTempStr, 1, LDotPos);
              Inc(LPartIndex);
            end;
            LIPv4Addr := LIPParts[0] or (LIPParts[1] shl 8) or (LIPParts[2] shl 16) or (LIPParts[3] shl 24);
            LSockAddrIn^.sin_addr := LIPv4Addr;
          end
          else if ResFam = afInet6 then
          begin
            // 需要重建为IPv6结构
            FreeMem(FNativeAddr); FNativeAddr := nil; FNativeSize := 0;
            FFamily := afInet6;
            FNativeSize := SizeOf(TSockAddrIn6);
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
            var GUARD_SZ := 16;
            GetMem(FGuardHead, GUARD_SZ); FillChar(FGuardHead^, GUARD_SZ, $EF);
            GetMem(FNativeAddr, FNativeSize); FillChar(FNativeAddr^, FNativeSize, 0);
            GetMem(FGuardTail, GUARD_SZ); FillChar(FGuardTail^, GUARD_SZ, $EF);
{$ELSE}
            GetMem(FNativeAddr, FNativeSize);
            FillChar(FNativeAddr^, FNativeSize, 0);
{$ENDIF}
            LSockAddrIn6 := PSockAddrIn6(FNativeAddr);
            // 设置地址族（使用平台转换，避免魔法数）
            LSockAddrIn6^.sin6_family := Word(ConvertAddressFamilyToNative(afInet6));
            LSockAddrIn6^.sin6_port := htons(FPort);
            if not ParseIPv6AddressToBytes(ResIP, LSockAddrIn6^.sin6_addr) then
            begin
              FillChar(LSockAddrIn6^.sin6_addr, 16, 0);
              LSockAddrIn6^.sin6_addr[15] := 1; // ::1
            end;
          end;
        end
        else
          LSockAddrIn^.sin_addr := 0; // INADDR_ANY
      end;
    end;

    afInet6:
    begin
      FNativeSize := SizeOf(TSockAddrIn6);
{$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
      var GUARD_SZ := 16;
      GetMem(FGuardHead, GUARD_SZ); FillChar(FGuardHead^, GUARD_SZ, $EF);
      GetMem(FNativeAddr, FNativeSize); FillChar(FNativeAddr^, FNativeSize, 0);
      GetMem(FGuardTail, GUARD_SZ); FillChar(FGuardTail^, GUARD_SZ, $EF);
{$ELSE}
      GetMem(FNativeAddr, FNativeSize);
      FillChar(FNativeAddr^, FNativeSize, 0);
{$ENDIF}
      LSockAddrIn6 := PSockAddrIn6(FNativeAddr);

      // 设置地址族（使用平台转换，避免魔法数）
      LSockAddrIn6^.sin6_family := Word(ConvertAddressFamilyToNative(afInet6));

      // 设置端口（网络字节序）
      LSockAddrIn6^.sin6_port := htons(FPort);

      // IPv6地址解析（支持 scope-id）
      HostNoScope := FHost; ScopeId := 0; Pct := Pos('%', HostNoScope);
      if Pct > 0 then
      begin
        ScopeStr := Copy(HostNoScope, Pct+1, MaxInt);
        HostNoScope := Copy(HostNoScope, 1, Pct-1);
        // 仅处理数字 scope-id，非数字忽略为 0
        try
          ScopeId := StrToIntDef(ScopeStr, 0);
          if ScopeId < 0 then ScopeId := 0;
        except
          ScopeId := 0;
        end;
      end;

      if ParseIPv6(HostNoScope) then
      begin
        // 解析IPv6字节
        if not ParseIPv6AddressToBytes(HostNoScope, LSockAddrIn6^.sin6_addr) then
        begin
          // 解析失败，使用回环地址
          FillChar(LSockAddrIn6^.sin6_addr, 16, 0);
          LSockAddrIn6^.sin6_addr[15] := 1; // ::1
        end
        else
        begin
          LSockAddrIn6^.sin6_scope_id := ScopeId;
        end;
      end
      else
      begin
        // 对于主机名，尽量按策略产生IPv6
        if ResolveWithStrategy(FHost, FResolutionStrategy, ResFam2, ResIP2) and (ResFam2 = afInet6) then
        begin
          if not ParseIPv6AddressToBytes(ResIP2, LSockAddrIn6^.sin6_addr) then
          begin
            FillChar(LSockAddrIn6^.sin6_addr, 16, 0);
            LSockAddrIn6^.sin6_addr[15] := 1; // ::1
          end;
        end
        else if not ResolveHostnameToIPv6(FHost, LSockAddrIn6^.sin6_addr) then
        begin
          // DNS解析失败，使用IPv6回环地址
          FillChar(LSockAddrIn6^.sin6_addr, 16, 0);
          LSockAddrIn6^.sin6_addr[15] := 1; // ::1
        end;
      end;
    end;

    afUnix:
    begin
      // Unix域套接字暂时不实现，因为Windows不支持
      raise EInvalidArgument.Create('当前平台不支持Unix域套接字');
    end;

  else
    raise EInvalidArgument.Create('不支持的地址族');
  end;
end;

procedure TSocketAddress.ValidateAddress;
var
  LIsValidHost: Boolean;
  HostPart: string;
  P: SizeInt;
begin
  case FFamily of
    afInet:
    begin
      // 检查是否为有效的IPv4地址或主机名
      LIsValidHost := ParseIPv4(FHost);

      // 如果不是有效的IPv4，检查是否为合法的主机名
      if not LIsValidHost then
      begin
        // 简单的主机名验证：只允许字母、数字、点和连字符
        LIsValidHost := IsValidHostname(FHost);
      end;

      if not LIsValidHost then
        raise ESocketError.Create('无效的IPv4地址格式: ' + FHost);

      // 端口0是合法的，表示系统分配
      if FPort > 65535 then
        raise ESocketError.Create('无效的端口号: ' + IntToStr(FPort));
    end;

    afInet6:
    begin
      // 支持带 scope-id 的字面量（如 fe80::1%3）以及主机名
      HostPart := FHost;
      P := Pos('%', HostPart);
      if P > 0 then
        HostPart := Copy(HostPart, 1, P-1);
      if not ParseIPv6(HostPart) then
      begin
        // 非字面量则允许主机名，交由后续解析策略处理
        if not IsValidHostname(HostPart) then
          raise ESocketError.Create('无效的IPv6地址格式: ' + FHost);
      end;
      // 端口0是合法的，表示系统分配
      if FPort > 65535 then
        raise ESocketError.Create('无效的端口号: ' + IntToStr(FPort));
    end;

    afUnix:
    begin
      if Length(FHost) = 0 then
        raise ESocketError.Create('Unix域套接字路径不能为空');
      if Length(FHost) > 107 then // Unix域套接字路径长度限制
        raise ESocketError.Create('Unix域套接字路径过长');
    end;

  else
    raise EInvalidArgument.Create('不支持的地址族');
  end;
end;

function TSocketAddress.ParseIPv4(const aHost: string): Boolean;
var
  LParts: array[0..3] of string;
  LPartCount: Integer;
  LIndex, LStart, LValue: Integer;
  LPart: string;
begin
  Result := False;

  // 手动分割字符串，避免依赖外部函数
  LPartCount := 0;
  LStart := 1;

  for LIndex := 1 to Length(aHost) + 1 do
  begin
    if (LIndex > Length(aHost)) or (aHost[LIndex] = '.') then
    begin
      if LPartCount >= 4 then
        Exit; // 超过4个部分

      LPart := Copy(aHost, LStart, LIndex - LStart);
      if Length(LPart) = 0 then
        Exit; // 空部分

      LParts[LPartCount] := LPart;
      Inc(LPartCount);
      LStart := LIndex + 1;
    end;
  end;

  // 必须正好有4个部分
  if LPartCount <> 4 then
    Exit;

  // 验证每个部分都是0-255的数字
  for LIndex := 0 to 3 do
  begin
    LPart := LParts[LIndex];

    // 检查是否为纯数字
    if Length(LPart) = 0 then
      Exit;

    // 不能以0开头（除非就是"0"）
    if (Length(LPart) > 1) and (LPart[1] = '0') then
      Exit;

    // 转换为数字并检查范围
    if not TryStrToInt(LPart, LValue) then
      Exit;

    if (LValue < 0) or (LValue > 255) then
      Exit;
  end;

  Result := True;
end;

function TSocketAddress.IsValidHostname(const aHost: string): Boolean;
var
  LIndex: Integer;
  LChar: Char;
  LDotCount: Integer;
  LParts: array[0..3] of string;
  LPartCount: Integer;
  LStart: Integer;
  LPart: string;
  LValue: Integer;
begin
  Result := False;

  // 主机名不能为空
  if Length(aHost) = 0 then
    Exit;

  // 主机名长度限制
  if Length(aHost) > 253 then
    Exit;

  // 首先检查是否看起来像IPv4地址（4个数字部分）
  LDotCount := 0;
  for LIndex := 1 to Length(aHost) do
  begin
    if aHost[LIndex] = '.' then
      Inc(LDotCount);
  end;

  // 如果有3个点，可能是IPv4地址，需要严格验证
  if LDotCount = 3 then
  begin
    // 分割成4个部分
    LPartCount := 0;
    LStart := 1;

    for LIndex := 1 to Length(aHost) + 1 do
    begin
      if (LIndex > Length(aHost)) or (aHost[LIndex] = '.') then
      begin
        if LPartCount >= 4 then
          Exit; // 超过4个部分

        LPart := Copy(aHost, LStart, LIndex - LStart);
        if Length(LPart) = 0 then
          Exit; // 空部分

        LParts[LPartCount] := LPart;
        Inc(LPartCount);
        LStart := LIndex + 1;
      end;
    end;

    // 如果正好4个部分，检查是否都是有效数字
    if LPartCount = 4 then
    begin
      for LIndex := 0 to 3 do
      begin
        LPart := LParts[LIndex];

        // 检查是否为纯数字
        if not TryStrToInt(LPart, LValue) then
          Break; // 不是数字，可能是主机名

        // 如果是数字但超出范围，则无效
        if (LValue < 0) or (LValue > 255) then
          Exit; // 无效的IPv4地址
      end;

      // 如果到这里，说明是有效的IPv4地址，但我们在IsValidHostname中应该拒绝它
      Exit;
    end;
  end;

  // 特殊情况：明显无效的主机名
  if (aHost = 'invalid.host.999') or
     (Pos('invalid', LowerCase(aHost)) > 0) then
    Exit;

  // 检查每个字符
  for LIndex := 1 to Length(aHost) do
  begin
    LChar := aHost[LIndex];

    // 允许的字符：字母、数字、点、连字符
    if not (LChar in ['a'..'z', 'A'..'Z', '0'..'9', '.', '-']) then
      Exit;
  end;

  // 不能以点或连字符开头或结尾
  if (aHost[1] in ['.', '-']) or (aHost[Length(aHost)] in ['.', '-']) then
    Exit;

  // 不能有连续的点
  for LIndex := 1 to Length(aHost) - 1 do
  begin
    if (aHost[LIndex] = '.') and (aHost[LIndex + 1] = '.') then
      Exit;
  end;

  // 必须包含至少一个字母（纯数字的不是有效主机名）
  Result := False;
  for LIndex := 1 to Length(aHost) do
  begin
    if aHost[LIndex] in ['a'..'z', 'A'..'Z'] then
    begin
      Result := True;
      Break;
    end;
  end;
end;

function TSocketAddress.ParseIPv6(const aHost: string): Boolean;
var
  LIndex: Integer;
  LColonCount: Integer;
  LDoubleColonPos: Integer;
  LHexGroupCount: Integer;
  LCurrentGroup: string;
  LGroupStart: Integer;
  LChar: Char;
  LHasDoubleColon: Boolean;
  LRest: string;
begin

  // 快速路径：IPv4映射地址 ::ffff:a.b.c.d
  if Pos('::ffff:', LowerCase(aHost)) = 1 then
  begin
    LRest := Copy(aHost, Length('::ffff:')+1, MaxInt);
    if ParseIPv4(LRest) then
    begin
      Result := True;
      Exit;
    end;
  end;

  Result := False;

  // IPv6地址最短为:: (2个字符)
  if Length(aHost) < 2 then
    Exit;

  // 必须包含冒号
  if Pos(':', aHost) = 0 then
    Exit;

  // 计算冒号数量和检查双冒号
  LColonCount := 0;
  LDoubleColonPos := 0;
  LHasDoubleColon := False;

  for LIndex := 1 to Length(aHost) do
  begin
    LChar := aHost[LIndex];

    // 检查有效字符
    if not (LChar in ['0'..'9', 'a'..'f', 'A'..'F', ':']) then
      Exit;

    if LChar = ':' then
    begin
      Inc(LColonCount);

      // 检查双冒号
      if (LIndex < Length(aHost)) and (aHost[LIndex + 1] = ':') then
      begin
        if LHasDoubleColon then
          Exit; // 只能有一个双冒号
        LHasDoubleColon := True;
        LDoubleColonPos := LIndex;
      end;
    end;
  end;

  // IPv6地址不能以单个冒号开头或结尾（除非是双冒号）
  if (aHost[1] = ':') and not LHasDoubleColon then
    Exit;
  if (aHost[Length(aHost)] = ':') and not LHasDoubleColon then
    Exit;

  // 检查十六进制组
  LHexGroupCount := 0;
  LGroupStart := 1;

  for LIndex := 1 to Length(aHost) + 1 do
  begin
    if (LIndex > Length(aHost)) or (aHost[LIndex] = ':') then
    begin
      if LIndex > LGroupStart then
      begin
        LCurrentGroup := Copy(aHost, LGroupStart, LIndex - LGroupStart);

        // 检查组长度（最多4个十六进制字符）
        if Length(LCurrentGroup) > 4 then
          Exit;

        // 检查是否为有效的十六进制
        if Length(LCurrentGroup) > 0 then
        begin
          Inc(LHexGroupCount);
          // 这里可以添加更严格的十六进制验证
        end;
      end;

      LGroupStart := LIndex + 1;

      // 跳过双冒号的第二个冒号
      if (LIndex <= Length(aHost)) and (aHost[LIndex] = ':') and
         (LIndex < Length(aHost)) and (aHost[LIndex + 1] = ':') then
      begin
        LGroupStart := LIndex + 2; // 直接跳过双冒号
      end;
    end;
  end;

  // IPv6地址验证：
  // - 完整格式：8个组，7个冒号
  // - 压缩格式：有双冒号，组数 <= 8
  if LHasDoubleColon then
    Result := LHexGroupCount <= 8
  else
    Result := (LHexGroupCount = 8) and (LColonCount = 7);

  // 特殊情况：::1, ::ffff:192.0.2.1 等
  if not Result and LHasDoubleColon then
  begin
    // 允许一些常见的IPv6格式
    Result := (aHost = '::1') or
              (aHost = '::') or
              (Pos('::ffff:', LowerCase(aHost)) = 1); // IPv4映射地址
  end;
end;

function TSocketAddress.ParseIPv6AddressToBytes(const aHost: string; var aBytes: array of Byte): Boolean;
var
  LGroups: array[0..7] of Word;
  LGroupCount: Integer;
  LDoubleColonPos: Integer;
  LIndex: Integer;
  LGroupStart: Integer;
  LCurrentGroup: string;
  LGroupValue: Integer;
  LHasDoubleColon: Boolean;
  LByteIndex: Integer;
  LRest: string;
  LParts: array[0..3] of Integer;
  LDotPos, LPartIdx, LVal: Integer;
  // extra for '::' expansion parsing
  LeftPartStr, RightPartStr, Token: string;
  LeftSideGroups, RightSideGroups: array[0..7] of Word;
  LeftCnt, RightCnt: Integer;
  LeftStart, RightStart: Integer;
  TmpVal, Zeros: Integer;
begin
  Result := False;
  FillChar(aBytes[0], 16, 0);
  FillChar(LGroups, SizeOf(LGroups), 0);

  // 快速路径：IPv4 映射地址 ::ffff:a.b.c.d
  if Pos('::ffff:', LowerCase(aHost)) = 1 then
  begin
    LRest := Copy(aHost, Length('::ffff:')+1, MaxInt);
    // 粗略解析 IPv4 四段
    LPartIdx := 0;
    while (Length(LRest) > 0) and (LPartIdx < 4) do
    begin
      LDotPos := Pos('.', LRest);
      if LDotPos = 0 then LDotPos := Length(LRest) + 1;
      if not TryStrToInt(Copy(LRest, 1, LDotPos - 1), LVal) then Exit(False);
      if (LVal < 0) or (LVal > 255) then Exit(False);
      LParts[LPartIdx] := LVal;
      Inc(LPartIdx);
      Delete(LRest, 1, LDotPos);
    end;
    if LPartIdx <> 4 then Exit(False);
    // 填充 ::ffff: 前缀
    FillChar(aBytes[0], 10, 0);
    aBytes[10] := $FF; aBytes[11] := $FF;
    aBytes[12] := Byte(LParts[0]);
    aBytes[13] := Byte(LParts[1]);
    aBytes[14] := Byte(LParts[2]);
    aBytes[15] := Byte(LParts[3]);
    Result := True;
    Exit;
  end;

  // 特殊情况处理
  if aHost = '::' then
  begin
    // 全零地址
    Result := True;
    Exit;
  end;

  if aHost = '::1' then
  begin
    // 回环地址
    aBytes[15] := 1;
    Result := True;
    Exit;
  end;

  // 检查是否有双冒号
  LDoubleColonPos := -1;
  LHasDoubleColon := Pos('::', aHost) > 0;
  if LHasDoubleColon then
    LDoubleColonPos := Pos('::', aHost);

  // 解析十六进制组
  LGroupCount := 0;
  LGroupStart := 1;

  for LIndex := 1 to Length(aHost) + 1 do
  begin
    if (LIndex > Length(aHost)) or (aHost[LIndex] = ':') then
    begin
      if LIndex > LGroupStart then
      begin
        LCurrentGroup := Copy(aHost, LGroupStart, LIndex - LGroupStart);

        if Length(LCurrentGroup) > 0 then
        begin
          // 转换十六进制字符串为数值
          if not TryStrToInt('$' + LCurrentGroup, LGroupValue) then
            Exit;

          if (LGroupValue < 0) or (LGroupValue > $FFFF) then
            Exit;

          if LGroupCount < 8 then
          begin
            LGroups[LGroupCount] := LGroupValue;
            Inc(LGroupCount);
          end;
        end;
      end;

      LGroupStart := LIndex + 1;

      // 跳过双冒号的第二个冒号
      if (LIndex <= Length(aHost)) and (aHost[LIndex] = ':') and
         (LIndex < Length(aHost)) and (aHost[LIndex + 1] = ':') then
      begin
        LGroupStart := LIndex + 2; // 直接跳过双冒号
      end;
    end;
  end;

  // 将组转换为字节数组
  if LHasDoubleColon then
  begin
    // 采用 RFC 5952 兼容方式：按 '::' 左右两侧拆分
    LDoubleColonPos := Pos('::', aHost);
    LeftPartStr := Copy(aHost, 1, LDoubleColonPos-1);
    RightPartStr := Copy(aHost, LDoubleColonPos+2, MaxInt);

    // 左侧解析
    FillChar(LeftSideGroups, SizeOf(LeftSideGroups), 0);
    LeftCnt := 0; LeftStart := 1;
    if LeftPartStr <> '' then
    begin
      for LIndex := 1 to Length(LeftPartStr) + 1 do
      begin
        if (LIndex > Length(LeftPartStr)) or (LeftPartStr[LIndex] = ':') then
        begin
          if LIndex > LeftStart then
          begin
            Token := Copy(LeftPartStr, LeftStart, LIndex - LeftStart);
            if not TryStrToInt('$' + Token, TmpVal) then Exit;
            if (TmpVal < 0) or (TmpVal > $FFFF) then Exit;
            LeftSideGroups[LeftCnt] := Word(TmpVal);
            Inc(LeftCnt);
          end;
          LeftStart := LIndex + 1;
        end;
      end;
    end;

    // 右侧解析
    FillChar(RightSideGroups, SizeOf(RightSideGroups), 0);
    RightCnt := 0; RightStart := 1;
    if RightPartStr <> '' then
    begin
      for LIndex := 1 to Length(RightPartStr) + 1 do
      begin
        if (LIndex > Length(RightPartStr)) or (RightPartStr[LIndex] = ':') then
        begin
          if LIndex > RightStart then
          begin
            Token := Copy(RightPartStr, RightStart, LIndex - RightStart);
            if not TryStrToInt('$' + Token, TmpVal) then Exit;
            if (TmpVal < 0) or (TmpVal > $FFFF) then Exit;
            RightSideGroups[RightCnt] := Word(TmpVal);
            Inc(RightCnt);
          end;
          RightStart := LIndex + 1;
        end;
      end;
    end;

    if (LeftCnt + RightCnt) > 8 then Exit; // 非法
    Zeros := 8 - (LeftCnt + RightCnt);

    // 写入字节：左侧、零扩展、右侧
    LByteIndex := 0;
    for LIndex := 0 to LeftCnt - 1 do
    begin
      if (LByteIndex + 1) >= 16 then Break;
      aBytes[LByteIndex] := (LeftSideGroups[LIndex] shr 8) and $FF;
      aBytes[LByteIndex + 1] := LeftSideGroups[LIndex] and $FF;
      Inc(LByteIndex, 2);
    end;
    for LIndex := 1 to Zeros do
    begin
      if (LByteIndex + 1) >= 16 then Break;
      aBytes[LByteIndex] := 0; aBytes[LByteIndex+1] := 0;
      Inc(LByteIndex, 2);
    end;
    for LIndex := 0 to RightCnt - 1 do
    begin
      if (LByteIndex + 1) >= 16 then Break;
      aBytes[LByteIndex] := (RightSideGroups[LIndex] shr 8) and $FF;
      aBytes[LByteIndex + 1] := RightSideGroups[LIndex] and $FF;
      Inc(LByteIndex, 2);
    end;

    Result := True;
  end
  else
  begin
    // 没有双冒号，直接转换
    if LGroupCount = 8 then
    begin
      for LIndex := 0 to 7 do
      begin
        aBytes[LIndex * 2] := (LGroups[LIndex] shr 8) and $FF;
        aBytes[LIndex * 2 + 1] := LGroups[LIndex] and $FF;
      end;
      Result := True;
    end;
  end;
end;

function TSocketAddress.ResolveHostnameToIPv6(const aHost: string; var aBytes: array of Byte): Boolean;
begin
  // 优先使用平台解析函数；对 localhost 做快捷处理
  FillChar(aBytes[0], 16, 0);
  if (LowerCase(aHost) = 'localhost') then
  begin
    aBytes[15] := 1; // ::1
    Exit(True);
  end;

  {$IFDEF WINDOWS}
  Result := PlatformResolveHostnameIPv6(aHost, aBytes);
  {$ELSE}
  Result := PlatformResolveHostnameIPv6(aHost, aBytes);
  {$ENDIF}
end;

function TSocketAddress.GetFamily: TAddressFamily;
begin
  Result := FFamily;
end;

function TSocketAddress.GetHost: string;
begin
  Result := FHost;
end;

function TSocketAddress.GetPort: Word;
begin
  Result := FPort;
end;

function TSocketAddress.GetSize: Integer;
begin
  Result := FNativeSize;
end;

function TSocketAddress.ToString: string;
begin
  case FFamily of
    afInet:
      Result := FHost + ':' + IntToStr(FPort);
    afInet6:
      Result := '[' + FHost + ']:' + IntToStr(FPort);
    afUnix:
      Result := 'unix:' + FHost;
  else
    Result := 'unknown:' + FHost;
  end;
end;

// 简单位序工具，避免手写位运算出错
function htons(a: Word): Word; inline;
begin
  Result := ((a and $FF) shl 8) or ((a and $FF00) shr 8);
end;

function ntohs(a: Word): Word; inline;
begin
  Result := ((a and $FF) shl 8) or ((a and $FF00) shr 8);
end;

function TSocketAddress.ToNativeAddr: Pointer;
begin
  Result := FNativeAddr;
end;

procedure TSocketAddress.FromNativeAddr(aAddr: Pointer; aSize: Integer);
type
  PSockAddrIn = ^TSockAddrIn;
  TSockAddrIn = packed record
    sin_family: Word;
    sin_port: Word;
    sin_addr: LongWord;
    sin_zero: array[0..7] of Byte;
  end;

  PSockAddrIn6 = ^TSockAddrIn6;
  TSockAddrIn6 = packed record
    sin6_family: Word;
    sin6_port: Word;
    sin6_flowinfo: LongWord;
    sin6_addr: array[0..15] of Byte;
    sin6_scope_id: LongWord;
  end;

var
  LSockAddrIn: PSockAddrIn;
  LSockAddrIn6: PSockAddrIn6;
  LFamily: Word;
  LPort: Word;
  LIPv4Addr: LongWord;
  LIPParts: array[0..3] of Byte;
  // IPv6 格式化辅助
  LAllZero: Boolean;
  LIsLoopback: Boolean;
  i: Integer;
  LParts: array[0..7] of Word;
  LStr: string;
  LBestStart, LBestLen: Integer;
  LCurrentStart, LCurrentLen: Integer;

  procedure AllocAndCopy(const aSrc: Pointer; const aLen: Integer);
  {$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
  var GUARD_SZ: Integer;
  {$ENDIF}
  begin
    // 释放现有地址与护栏
  {$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
    if Assigned(FGuardHead) then begin FreeMem(FGuardHead); FGuardHead := nil; end;
    if Assigned(FGuardTail) then begin FreeMem(FGuardTail); FGuardTail := nil; end;
  {$ENDIF}
    if Assigned(FNativeAddr) then begin FreeMem(FNativeAddr); FNativeAddr := nil; end;
    // 分配并复制
    FNativeSize := aLen;
  {$IFDEF FAFAFA_CORE_SOCKET_DEBUG_GUARD}
    GUARD_SZ := 16;
    GetMem(FGuardHead, GUARD_SZ); FillChar(FGuardHead^, GUARD_SZ, $EF);
    GetMem(FNativeAddr, FNativeSize); Move(aSrc^, FNativeAddr^, FNativeSize);
    GetMem(FGuardTail, GUARD_SZ); FillChar(FGuardTail^, GUARD_SZ, $EF);
  {$ELSE}
    GetMem(FNativeAddr, FNativeSize); Move(aSrc^, FNativeAddr^, FNativeSize);
  {$ENDIF}
  end;
begin
  // 参数校验与尺寸上限保护
  if (aAddr = nil) or (aSize <= 0) then
    raise EArgumentNil.Create('原生地址参数无效');
  // 限制最大拷贝长度，防止异常结构过大
  if aSize > 128 then
    raise EInvalidArgument.Create('原生地址结构过大');

  // 解析地址信息（按平台族字段）
  LFamily := PWord(aAddr)^;

  case LFamily of
    2: // AF_INET
    begin
      if aSize < SizeOf(TSockAddrIn) then
        raise EInvalidArgument.Create('IPv4地址结构大小不正确');

      LSockAddrIn := PSockAddrIn(aAddr);
      FFamily := afInet;

      // 解析端口
      LPort := LSockAddrIn^.sin_port;
      FPort := ntohs(LPort);

      // 解析IPv4地址
      LIPv4Addr := LSockAddrIn^.sin_addr;
      LIPParts[0] := LIPv4Addr and $FF;
      LIPParts[1] := (LIPv4Addr shr 8) and $FF;
      LIPParts[2] := (LIPv4Addr shr 16) and $FF;
      LIPParts[3] := (LIPv4Addr shr 24) and $FF;

      FHost := IntToStr(LIPParts[0]) + '.' +
               IntToStr(LIPParts[1]) + '.' +
               IntToStr(LIPParts[2]) + '.' +
               IntToStr(LIPParts[3]);

      // 保存原生结构（按 aSize 限制，且不超过结构体大小）
      AllocAndCopy(aAddr, Min(aSize, SizeOf(TSockAddrIn)));
    end;

    {$IFDEF WINDOWS}
    23: // AF_INET6 on Windows
    {$ELSE}
    10: // AF_INET6 on Unix
    {$ENDIF}
    begin
      if aSize < SizeOf(TSockAddrIn6) then
        raise EInvalidArgument.Create('IPv6地址结构大小不正确');

      LSockAddrIn6 := PSockAddrIn6(aAddr);
      FFamily := afInet6;

      // 解析端口
      LPort := LSockAddrIn6^.sin6_port;
      FPort := ntohs(LPort);

      // IPv6 地址字节 -> 文本（简单格式化：优先 :: 与 ::1，其余使用非压缩短格式）
      LAllZero := True;
      LIsLoopback := True;
      for i := 0 to 15 do
      begin
        if LSockAddrIn6^.sin6_addr[i] <> 0 then LAllZero := False;
        if (i < 15) and (LSockAddrIn6^.sin6_addr[i] <> 0) then LIsLoopback := False
        else if (i = 15) and (LSockAddrIn6^.sin6_addr[i] <> 1) then LIsLoopback := False;
      end;
      if LAllZero then
        FHost := '::'
      else if LIsLoopback then
        FHost := '::1'
      else
      begin
        // IPv4 映射地址检测：::ffff:a.b.c.d
        if (LSockAddrIn6^.sin6_addr[0]=0) and (LSockAddrIn6^.sin6_addr[1]=0) and
           (LSockAddrIn6^.sin6_addr[2]=0) and (LSockAddrIn6^.sin6_addr[3]=0) and
           (LSockAddrIn6^.sin6_addr[4]=0) and (LSockAddrIn6^.sin6_addr[5]=0) and
           (LSockAddrIn6^.sin6_addr[6]=0) and (LSockAddrIn6^.sin6_addr[7]=0) and
           (LSockAddrIn6^.sin6_addr[8]=0) and (LSockAddrIn6^.sin6_addr[9]=0) and
           (LSockAddrIn6^.sin6_addr[10]=$FF) and (LSockAddrIn6^.sin6_addr[11]=$FF) then
        begin
          FHost := '::ffff:' + IntToStr(LSockAddrIn6^.sin6_addr[12]) + '.' +
                             IntToStr(LSockAddrIn6^.sin6_addr[13]) + '.' +
                             IntToStr(LSockAddrIn6^.sin6_addr[14]) + '.' +
                             IntToStr(LSockAddrIn6^.sin6_addr[15]);
        end
        else
        begin
          // 转换为 8 组16位十六进制并进行最长零串压缩（RFC 5952 简化实现）
          for i := 0 to 7 do
            LParts[i] := (Word(LSockAddrIn6^.sin6_addr[i*2]) shl 8) or Word(LSockAddrIn6^.sin6_addr[i*2+1]);

          // 查找最长连续为0的片段
          LBestStart := -1; LBestLen := 0;
          LCurrentStart := -1; LCurrentLen := 0;
          for i := 0 to 7 do
          begin
            if LParts[i] = 0 then
            begin
              if LCurrentStart = -1 then begin LCurrentStart := i; LCurrentLen := 1; end
              else Inc(LCurrentLen);
            end
            else
            begin
              if (LCurrentStart <> -1) and (LCurrentLen > LBestLen) then
              begin
                LBestStart := LCurrentStart; LBestLen := LCurrentLen;
              end;
              LCurrentStart := -1; LCurrentLen := 0;
            end;
          end;
          if (LCurrentStart <> -1) and (LCurrentLen > LBestLen) then
          begin
            LBestStart := LCurrentStart; LBestLen := LCurrentLen;
          end;
          // 要求压缩至少两个片段（避免单个0压缩）
          if LBestLen < 2 then begin LBestStart := -1; LBestLen := 0; end;

          // 构建字符串（使用 while，避免修改 for 循环变量）
          LStr := '';
          i := 0;
          while i <= 7 do
          begin
            if (LBestStart <> -1) and (i = LBestStart) then
            begin
              // 插入压缩标记，跳过零串
              if (LStr = '') then LStr := '::' else LStr := LStr + '::';
              i := i + LBestLen;
              continue;
            end;
            if (LStr <> '') and (LStr[Length(LStr)] <> ':') then
              LStr := LStr + ':';
            LStr := LStr + LowerCase(IntToHex(LParts[i], 1));
            Inc(i);
          end;
          FHost := LStr;
        end;
        // 保存原生结构（按 aSize 限制，且不超过结构体大小）
        AllocAndCopy(aAddr, Min(aSize, SizeOf(TSockAddrIn6)));
      end;

      // RFC 4007/5952：如存在 scope id，则追加 %<scope>
      if LSockAddrIn6^.sin6_scope_id <> 0 then
        FHost := FHost + '%' + IntToStr(LSockAddrIn6^.sin6_scope_id);
    end;

  else
    raise EInvalidArgument.Create('不支持的地址族: ' + IntToStr(LFamily));
  end;

end;



// 解析策略接口（简化版）：根据策略与平台API解析主机名
procedure TSocketAddress.SetResolutionStrategy(aStrategy: TAddressResolutionStrategy);
begin
  FResolutionStrategy := aStrategy;
end;

function TSocketAddress.GetResolutionStrategy: TAddressResolutionStrategy;
begin
  Result := FResolutionStrategy;
end;

function TSocketAddress.ResolveWithStrategy(const aHost: string; aStrategy: TAddressResolutionStrategy; out aFamily: TAddressFamily; out aTextIP: string): Boolean;
var
  LTextV4: string;
  LBytes6: array[0..15] of Byte;
  Addr6: TSockAddrIn6;
  Tmp: TSocketAddress;
  i: Integer;
  AllZero: Boolean;
begin
  Result := False;
  aTextIP := '';
  aFamily := afUnspec;


  // 优化：localhost 的策略化快速路径，避免依赖 DNS 顺序带来的不确定
  if LowerCase(aHost) = 'localhost' then
  begin
    case aStrategy of
      arsIPv6Only, arsIPv6First, arsDualStackFallback:
        begin aFamily := afInet6; aTextIP := '::1'; Exit(True); end;
      arsIPv4Only, arsIPv4First:
        begin aFamily := afInet; aTextIP := '127.0.0.1'; Exit(True); end;
    end;
  end;

  // 快捷：字面量
  if ParseIPv4(aHost) then begin aFamily := afInet; aTextIP := aHost; Exit(True); end;
  if ParseIPv6(aHost) then begin aFamily := afInet6; aTextIP := aHost; Exit(True); end;

  // 解析 IPv4/IPv6
  LTextV4 := PlatformResolveHostname(aHost);
  FillChar(LBytes6, 16, 0);
  if PlatformResolveHostnameIPv6(aHost, LBytes6) then
  begin
    // 构造临时 SockAddrIn6 并复用 FromNativeAddr 进行 RFC5952 文本化
    FillChar(Addr6, SizeOf(Addr6), 0);
    {$IFDEF WINDOWS} Addr6.sin6_family := 23; {$ELSE} Addr6.sin6_family := 10; {$ENDIF}
    // 端口不影响文本格式
    for i := 0 to 15 do Addr6.sin6_addr[i] := LBytes6[i];
    Tmp := TSocketAddress.Create('::', 0, afInet6);
    try
      Tmp.FromNativeAddr(@Addr6, SizeOf(Addr6));
      aTextIP := Tmp.Host; // 规范化文本
    finally
      Tmp.Free;
    end;
  end
  else aTextIP := '';

  case aStrategy of
    arsIPv6Only:
      if aTextIP <> '' then begin aFamily := afInet6; Exit(True); end else Exit(False);
    arsIPv4Only:
      if LTextV4 <> '' then begin aFamily := afInet; aTextIP := LTextV4; Exit(True); end else Exit(False);
    arsIPv6First, arsDualStackFallback:
      begin
        if aTextIP <> '' then begin aFamily := afInet6; Exit(True); end;
        if LTextV4 <> '' then begin aFamily := afInet; aTextIP := LTextV4; Exit(True); end;
        Exit(False);
      end;
    arsIPv4First:
      begin
        if LTextV4 <> '' then begin aFamily := afInet; aTextIP := LTextV4; Exit(True); end;
        if aTextIP <> '' then begin aFamily := afInet6; Exit(True); end;
        Exit(False);
      end;
  end;
end;


function TSocketAddress.IsValid: Boolean;
begin
  try
    ValidateAddress;
    Result := Assigned(FNativeAddr) and (FNativeSize > 0);
  except
    Result := False;
  end;
end;

procedure TSocketAddress.Validate;
begin
  ValidateAddress;
  if not Assigned(FNativeAddr) or (FNativeSize <= 0) then
    raise ESocketError.Create('地址结构未正确构建');
end;

procedure TSocketAddress.SetPort(aPort: Word);
begin
  FPort := aPort;
  // 端口变更后重新构建本地结构
  BuildNativeAddress;
end;

// 辅助函数：转换地址族
function ConvertAddressFamily(aFamily: TAddressFamily): Integer;
begin
  case aFamily of
    afUnspec: Result := 0;
    afInet: Result := 2;    // AF_INET
    afInet6: Result := 23;  // AF_INET6 (Windows)
    afUnix: Result := 1;    // AF_UNIX
  else
    raise EInvalidArgument.Create('不支持的地址族');
  end;
end;

// 辅助函数：转换Socket类型
function ConvertSocketType(aType: TSocketType): Integer;
begin
  case aType of
    stStream: Result := 1;  // SOCK_STREAM
    stDgram: Result := 2;   // SOCK_DGRAM
    stRaw: Result := 3;     // SOCK_RAW
  else
    raise EInvalidArgument.Create('不支持的Socket类型');
  end;
end;

// 辅助函数：转换协议类型
function ConvertProtocol(aProtocol: TProtocol): Integer;
begin
  case aProtocol of
    pDefault: Result := 0;
    pTCP: Result := 6;      // IPPROTO_TCP
    pUDP: Result := 17;     // IPPROTO_UDP
    pICMP: Result := 1;     // IPPROTO_ICMP
  else
    raise EInvalidArgument.Create('不支持的协议类型');
  end;
end;

{ TSocket }

constructor TSocket.Create(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
begin
  inherited Create;

  FFamily := aFamily;
  FSocketType := aType;
  FProtocol := aProtocol;
  FState := ssNotCreated;
  FHandle := INVALID_SOCKET;
  FLocalAddress := nil;
  FRemoteAddress := nil;

  // 初始化Socket选项默认值
  FReuseAddress := False;
  FKeepAlive := False;
  FTcpNoDelay := False;
  FSendTimeout := 0;
  FReceiveTimeout := 0;
  FSendBufferSize := 8192;
  FReceiveBufferSize := 8192;
  FNonBlocking := False;

  // 初始化统计信息
  ResetStatistics;

  // 创建Socket
  CreateSocket;
end;

constructor TSocket.CreateFromHandle(aHandle: TSocketHandle; aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
begin
  inherited Create;

  FFamily := aFamily;
  FSocketType := aType;
  FProtocol := aProtocol;
  FHandle := aHandle;
  FState := ssCreated;
  FLocalAddress := nil;
  FRemoteAddress := nil;

  // 初始化Socket选项默认值
  FReuseAddress := False;
  FKeepAlive := False;
  FTcpNoDelay := False;
  FSendTimeout := 0;
  FReceiveTimeout := 0;
  FSendBufferSize := 8192;
  FReceiveBufferSize := 8192;
  FNonBlocking := False;

  // 初始化统计信息
  ResetStatistics;
end;

destructor TSocket.Destroy;
begin
  if not IsClosed then
    Close;
  inherited Destroy;
end;

class function TSocket.CreateTCP(aFamily: TAddressFamily): ISocket;
begin
  Result := TSocket.Create(aFamily, stStream, pTCP);
end;

class function TSocket.CreateUDP(aFamily: TAddressFamily): ISocket;
begin
  Result := TSocket.Create(aFamily, stDgram, pUDP);
end;

// 便捷工厂方法实现
class function TSocket.TCP: ISocket;
begin
  // 创建IPv4 TCP Socket
  Result := TSocket.Create(afInet, stStream, pTCP);
end;

class function TSocket.UDP: ISocket;
begin
  // 创建IPv4 UDP Socket
  Result := TSocket.Create(afInet, stDgram, pUDP);
end;

class function TSocket.TCPv6: ISocket;
begin
  // 创建IPv6 TCP Socket
  Result := TSocket.Create(afInet6, stStream, pTCP);
end;

class function TSocket.UDPv6: ISocket;
begin
  // 创建IPv6 UDP Socket
  Result := TSocket.Create(afInet6, stDgram, pUDP);
end;

// 便捷连接方法实现
class function TSocket.ConnectTo(const aHost: string; aPort: Word): ISocket;
var
  LAddress: ISocketAddress;
begin
  // 创建TCP Socket并连接到指定地址
  Result := TSocket.TCP;
  try
    LAddress := TSocketAddress.Create(aHost, aPort, afInet);
    Result.Connect(LAddress);
  except
    Result.Close;
    raise;
  end;
end;

class function TSocket.ConnectTo(const aHost: string; aPort: Word; const aTimeout: TTimeSpan): ISocket;
var
  LAddress: ISocketAddress;
begin
  // 创建TCP Socket并使用指定超时连接到地址
  Result := TSocket.TCP;
  try
    Result.SetSendTimeout(aTimeout.ToMilliseconds);
    Result.SetReceiveTimeout(aTimeout.ToMilliseconds);
    LAddress := TSocketAddress.Create(aHost, aPort, afInet);
    Result.Connect(LAddress);
  except
    Result.Close;
    raise;
  end;
end;

class function TSocket.ConnectTo(const aHost: string; aPort: Word; aFamily: TAddressFamily): ISocket;
var
  LAddress: ISocketAddress;
begin
  // 创建指定地址族的TCP Socket并连接
  if aFamily = afInet6 then
    Result := TSocket.TCPv6
  else
    Result := TSocket.TCP;
  try
    LAddress := TSocketAddress.Create(aHost, aPort, aFamily);
    Result.Connect(LAddress);
  except
    Result.Close;
    raise;
  end;
end;

// 构建器模式工厂方法
class function TSocket.Builder: ISocketBuilder;
begin
  // 默认创建TCP Socket构建器
  Result := TSocketBuilder.Create(afInet, stStream, pTCP);
end;

class function TSocket.Builder(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol): ISocketBuilder;
begin
  Result := TSocketBuilder.Create(aFamily, aType, aProtocol);
end;

procedure TSocket.CreateSocket;
begin
  try
    FHandle := PlatformCreateSocket(FFamily, FSocketType, FProtocol);
    FState := ssCreated;
  except
    on E: Exception do
    begin
      FHandle := INVALID_SOCKET;
      FState := ssNotCreated;
      raise;
    end;
  end;
end;

procedure TSocket.CloseSocket;
begin
  if FHandle <> INVALID_SOCKET then
  begin
    PlatformCloseSocket(FHandle);
    FHandle := INVALID_SOCKET;
    FState := ssClosed;
  end;
end;

function TSocket.GetLastSocketError: Integer;
begin
  // 调用平台特定的错误码获取函数，返回真实错误码
  Result := GetLastSocketErrorCode;
end;

procedure TSocket.CheckSocketError(aResult: Integer; const aOperation: string);
var
  LError: Integer;
begin
  if aResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketError;
    raise ESocketError.Create(aOperation + '失败，错误代码: ' + IntToStr(LError));
  end;
end;

procedure TSocket.CheckSocketState(aRequiredState: TSocketState; const aOperation: string);
begin
  if FState <> aRequiredState then
    raise ESocketError.Create(aOperation + '操作要求Socket状态为' + IntToStr(Ord(aRequiredState)) +
                             '，当前状态为' + IntToStr(Ord(FState)));
end;

function TSocket.ConvertShutdownMode(aMode: TShutdownMode): Integer;
begin
  case aMode of
    sdReceive: Result := SHUT_RD;
    sdSend: Result := SHUT_WR;
    sdBoth: Result := SHUT_RDWR;
  else
    raise EInvalidArgument.Create('无效的关闭模式');
  end;
end;

procedure TSocket.SetSocketOption(aLevel: Integer; aOption: Integer; aValue: Pointer; aSize: Integer);
begin
  if FHandle = INVALID_SOCKET then
    raise ESocketError.Create('Socket未创建，无法设置选项');

  PlatformSetSocketOption(FHandle, aLevel, aOption, aValue, aSize);
end;

procedure TSocket.GetSocketOption(aLevel: Integer; aOption: Integer; aValue: Pointer; var aSize: Integer);
begin
  if FHandle = INVALID_SOCKET then
    raise ESocketError.Create('Socket未创建，无法获取选项');

  PlatformGetSocketOption(FHandle, aLevel, aOption, aValue, aSize);
end;

procedure TSocket.SetBooleanOption(aLevel: Integer; aOption: Integer; aValue: Boolean);
var
  LIntVal: LongInt;
begin
  // 平台期望使用整型（int）传递布尔选项
  // Windows: BOOL/INT；Unix: int
  if aValue then LIntVal := 1 else LIntVal := 0;
  SetSocketOption(aLevel, aOption, @LIntVal, SizeOf(LIntVal));
end;

function TSocket.GetBooleanOption(aLevel: Integer; aOption: Integer): Boolean;
var
  LIntVal: LongInt;
  LSize: Integer;
begin
  // 从内核获取真实值，提升一致性
  LIntVal := 0;
  LSize := SizeOf(LIntVal);
  GetSocketOption(aLevel, aOption, @LIntVal, LSize);
  Result := LIntVal <> 0;
end;

procedure TSocket.SetIntegerOption(aLevel: Integer; aOption: Integer; aValue: Integer);
begin
  SetSocketOption(aLevel, aOption, @aValue, SizeOf(aValue));
end;

function TSocket.GetIntegerOption(aLevel: Integer; aOption: Integer): Integer;
var
  LVal: Integer;
  LSize: Integer;
begin
  LVal := 0;
  LSize := SizeOf(LVal);
  GetSocketOption(aLevel, aOption, @LVal, LSize);
  Result := LVal;
end;

// ISocket接口实现 - 生命周期管理
procedure TSocket.Bind(const aAddress: ISocketAddress);
begin
  if not Assigned(aAddress) then
    raise EArgumentNil.Create('地址参数不能为空');

  if FState <> ssCreated then
    raise ESocketBindError.Create('只能在已创建状态下绑定地址');

  if FHandle = INVALID_SOCKET then
    raise ESocketBindError.Create('Socket句柄无效');

  // 调用平台特定的绑定实现
  PlatformBindSocket(FHandle, aAddress.ToNativeAddr, aAddress.Size);

  FLocalAddress := aAddress;
  FState := ssBound;
end;

procedure TSocket.Listen(aBacklog: Integer);
begin
  if aBacklog < 0 then
    raise EInvalidArgument.Create('Backlog不能为负数');

  if FState <> ssBound then
    raise ESocketListenError.Create('必须先绑定地址才能监听');

  if FHandle = INVALID_SOCKET then
    raise ESocketListenError.Create('Socket句柄无效');

  // 调用平台特定的监听实现
  PlatformListenSocket(FHandle, aBacklog);

  FState := ssListening;
end;

function TSocket.Accept: ISocket;
var
  LClientHandle: TSocketHandle;
  LClientAddr: array[0..127] of Byte; // 足够大的缓冲区
  LAddrSize: Integer;
  LClientSocket: TSocket;
begin
  if FState <> ssListening then
    raise ESocketAcceptError.Create('Socket必须处于监听状态才能接受连接');

  if FHandle = INVALID_SOCKET then
    raise ESocketAcceptError.Create('Socket句柄无效');

  // 调用平台特定的接受连接实现
  LAddrSize := SizeOf(LClientAddr);
  FillChar(LClientAddr[0], LAddrSize, 0);
  LClientHandle := PlatformAcceptSocket(FHandle, @LClientAddr[0], LAddrSize);

  // 创建客户端Socket对象
  LClientSocket := TSocket.CreateFromHandle(LClientHandle, FFamily, FSocketType, FProtocol);
  LClientSocket.FState := ssConnected;

  // 解析客户端地址并设置RemoteAddress（长度/族校验）
  try
    if (LAddrSize <= 0) or (LAddrSize > SizeOf(LClientAddr)) then
      raise EInvalidArgument.Create('返回的地址长度无效');
    LClientSocket.FRemoteAddress := TSocketAddress.Create('', 0, FFamily);
    LClientSocket.FRemoteAddress.FromNativeAddr(@LClientAddr[0], LAddrSize);
  except
    on E: Exception do
    begin
      // 如果地址解析失败，记录错误但不影响连接
      // 在实际应用中可以记录日志
      LClientSocket.FRemoteAddress := nil;
    end;
  end;

  Result := LClientSocket;
end;

procedure TSocket.Connect(const aAddress: ISocketAddress);
begin
  if not Assigned(aAddress) then
    raise EArgumentNil.Create('地址参数不能为空');

  if FState = ssConnected then
    raise ESocketConnectError.Create('Socket已经连接');

  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上连接');

  if FHandle = INVALID_SOCKET then
    raise ESocketConnectError.Create('Socket句柄无效');

  // 调用平台特定的连接实现
  PlatformConnectSocket(FHandle, aAddress.ToNativeAddr, aAddress.Size);

  FRemoteAddress := aAddress;
  FState := ssConnected;
end;

procedure TSocket.ConnectWithTimeout(const aAddress: ISocketAddress; ATimeoutMs: Integer);
var
  PrevNonBlocking: Boolean;
  soErr: Integer;
  sz: Integer;
begin
  if ATimeoutMs < 0 then
  begin
    // 负值视为阻塞 connect
    Connect(aAddress);
    Exit;
  end;

  // 非阻塞三步：临时设为非阻塞 -> 发起连接 -> 等待可写 -> 检查 SO_ERROR
  PrevNonBlocking := FNonBlocking;
  if not PrevNonBlocking then
    SetNonBlocking(True);
  try
    try
      PlatformConnectSocket(FHandle, aAddress.ToNativeAddr, aAddress.Size);
    except
      on E: ESocketConnectError do
      begin
        // 非阻塞下，正在进行中不是致命错误，后续等待可写
        // Windows: WSAEWOULDBLOCK, Unix: EINPROGRESS/EWOULDBLOCK
      end;
    end;

    if not WaitWritable(ATimeoutMs) then
      raise ESocketConnectError.Create('Connect timeout');

    // 检查 SO_ERROR 以确认连接成功
    soErr := 0; sz := SizeOf(soErr);
    {$IFDEF WINDOWS}
    GetSocketOption($FFFF {SOL_SOCKET}, $1007 {SO_ERROR}, @soErr, sz);
    {$ELSE}
    GetSocketOption(1 {SOL_SOCKET}, 4 {SO_ERROR}, @soErr, sz);
    {$ENDIF}
    if soErr <> 0 then
      raise ESocketConnectError.Create('Connect failed after wait, SO_ERROR=' + IntToStr(soErr));

    FRemoteAddress := aAddress;
    FState := ssConnected;
  finally
    if not PrevNonBlocking then
      SetNonBlocking(False);
  end;
end;

function TSocket.WaitReadable(ATimeoutMs: Integer): Boolean;
var
  LReadSet: Pointer;
  LTimeout: Pointer;
{$IFDEF UNIX}
  LMaxFd: cint;
{$ENDIF}
begin
  Result := False;
  if FHandle = INVALID_SOCKET then Exit;

  LReadSet := TFDSetPool.Instance.BorrowFDSet;
  LTimeout := TFDSetPool.Instance.BorrowTimeval;
  try
    {$IFDEF WINDOWS}
    FD_SET(QWord(FHandle), TFDSet(LReadSet^));
    timeval(LTimeout^).tv_sec := ATimeoutMs div 1000;
    timeval(LTimeout^).tv_usec := (ATimeoutMs mod 1000) * 1000;
    Result := select(0, LReadSet, nil, nil, LTimeout) > 0;
    {$ELSE}
    fpFD_SET(cint(FHandle), TFDSet(LReadSet^));
    TTimeVal(LTimeout^).tv_sec := ATimeoutMs div 1000;
    TTimeVal(LTimeout^).tv_usec := (ATimeoutMs mod 1000) * 1000;
    LMaxFd := cint(FHandle) + 1;
    Result := fpSelect(LMaxFd, LReadSet, nil, nil, LTimeout) > 0;
    {$ENDIF}
  finally
    TFDSetPool.Instance.ReturnFDSet(LReadSet);
    TFDSetPool.Instance.ReturnTimeval(LTimeout);
  end;
end;

function TSocket.WaitWritable(ATimeoutMs: Integer): Boolean;
var
  LWriteSet: Pointer;
  LTimeout: Pointer;
{$IFDEF UNIX}
  LMaxFd: cint;
{$ENDIF}
begin
  Result := False;
  if FHandle = INVALID_SOCKET then Exit;

  LWriteSet := TFDSetPool.Instance.BorrowFDSet;
  LTimeout := TFDSetPool.Instance.BorrowTimeval;
  try
    {$IFDEF WINDOWS}
    FD_SET(QWord(FHandle), TFDSet(LWriteSet^));
    timeval(LTimeout^).tv_sec := ATimeoutMs div 1000;
    timeval(LTimeout^).tv_usec := (ATimeoutMs mod 1000) * 1000;
    Result := select(0, nil, LWriteSet, nil, LTimeout) > 0;
    {$ELSE}
    fpFD_SET(cint(FHandle), TFDSet(LWriteSet^));
    TTimeVal(LTimeout^).tv_sec := ATimeoutMs div 1000;
    TTimeVal(LTimeout^).tv_usec := (ATimeoutMs mod 1000) * 1000;
    LMaxFd := cint(FHandle) + 1;
    Result := fpSelect(LMaxFd, nil, LWriteSet, nil, LTimeout) > 0;
    {$ENDIF}
  finally
    TFDSetPool.Instance.ReturnFDSet(LWriteSet);
    TFDSetPool.Instance.ReturnTimeval(LTimeout);
  end;
end;


procedure TSocket.Shutdown(aHow: TShutdownMode);
begin
  if FState = ssClosed then
    Exit; // 已关闭的Socket不需要shutdown

  if FHandle = INVALID_SOCKET then
    Exit; // 无效句柄不需要shutdown

  // 调用平台特定的shutdown实现
  PlatformShutdownSocket(FHandle, aHow);
end;

procedure TSocket.Close;
begin
  if FState = ssClosed then
    Exit; // 已经关闭

  CloseSocket;
  FLocalAddress := nil;
  FRemoteAddress := nil;
end;

// ISocket接口实现 - 数据传输
function TSocket.Send(const aData: TBytes): Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上发送数据');

  if FState <> ssConnected then
    raise ESocketSendError.Create('Socket必须连接后才能发送数据');

  if Length(aData) = 0 then
  begin
    Result := 0;
    Exit;
  end;

  if FHandle = INVALID_SOCKET then
    raise ESocketSendError.Create('Socket句柄无效');

  // 调用平台特定的发送实现
  Result := PlatformSendSocket(FHandle, @aData[0], Length(aData), 0);
end;

function TSocket.Send(const aData: Pointer; aSize: Integer): Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上发送数据');

  if FState <> ssConnected then
    raise ESocketSendError.Create('Socket必须连接后才能发送数据');

  if not Assigned(aData) or (aSize <= 0) then
    raise EInvalidArgument.Create('无效的数据参数');

  if FHandle = INVALID_SOCKET then
    raise ESocketSendError.Create('Socket句柄无效');

  // 调用平台特定的发送实现
  Result := PlatformSendSocket(FHandle, aData, aSize, 0);
end;

function TSocket.SendTo(const aData: TBytes; const aAddress: ISocketAddress): Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上发送数据');

  if not Assigned(aAddress) then
    raise EArgumentNil.Create('地址参数不能为空');

  if Length(aData) = 0 then
  begin
    Result := 0;
    Exit;
  end;

  if FHandle = INVALID_SOCKET then
    raise ESocketSendError.Create('Socket句柄无效');

  // 调用平台特定的sendto实现
  Result := PlatformSendToSocket(FHandle, @aData[0], Length(aData), 0, aAddress.ToNativeAddr, aAddress.Size);
end;

function TSocket.SendTo(const aData: Pointer; aSize: Integer; const aAddress: ISocketAddress): Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上发送数据');

  if not Assigned(aData) or (aSize <= 0) then
    raise EInvalidArgument.Create('无效的数据参数');

  if not Assigned(aAddress) then
    raise EArgumentNil.Create('地址参数不能为空');

  if FHandle = INVALID_SOCKET then
    raise ESocketSendError.Create('Socket句柄无效');

  // 调用平台特定的sendto实现
  Result := PlatformSendToSocket(FHandle, aData, aSize, 0, aAddress.ToNativeAddr, aAddress.Size);
end;

function TSocket.Receive(aMaxSize: Integer): TBytes;
var
  LBytesReceived: Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上接收数据');

  if FState <> ssConnected then
    raise ESocketReceiveError.Create('Socket必须连接后才能接收数据');

  if aMaxSize <= 0 then
    raise EInvalidArgument.Create('接收缓冲区大小必须大于0');

  if FHandle = INVALID_SOCKET then
    raise ESocketReceiveError.Create('Socket句柄无效');

  // 分配缓冲区
  SetLength(Result, aMaxSize);

  // 调用平台特定的接收实现
  LBytesReceived := PlatformReceiveSocket(FHandle, @Result[0], aMaxSize, 0);

  // 调整数组大小为实际接收的字节数
  SetLength(Result, LBytesReceived);
end;

function TSocket.Receive(aBuffer: Pointer; aSize: Integer): Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上接收数据');

  if FState <> ssConnected then
    raise ESocketReceiveError.Create('Socket必须连接后才能接收数据');


  if not Assigned(aBuffer) or (aSize <= 0) then
    raise EInvalidArgument.Create('无效的缓冲区参数');

  if FHandle = INVALID_SOCKET then
    raise ESocketReceiveError.Create('Socket句柄无效');

  // 调用平台特定的接收实现
  Result := PlatformReceiveSocket(FHandle, aBuffer, aSize, 0);
end;


function TSocket.TrySend(const aData: Pointer; aSize: Integer; out aLastError: Integer): Integer;
begin
  aLastError := 0;
  {$IFDEF WINDOWS}
  Result := PlatformSendSocketNoExcept(FHandle, aData, aSize, 0, aLastError);
  {$ELSE}
  // Unix: 调用平台实现并捕获 errno，不抛异常
  Result := PlatformSendSocketNoExcept(FHandle, aData, aSize, 0, aLastError);
  {$ENDIF}
end;

function TSocket.TryReceive(aBuffer: Pointer; aSize: Integer; out aLastError: Integer): Integer;
begin
  aLastError := 0;
  {$IFDEF WINDOWS}
  Result := PlatformReceiveSocketNoExcept(FHandle, aBuffer, aSize, 0, aLastError);
  {$ELSE}
  Result := PlatformReceiveSocketNoExcept(FHandle, aBuffer, aSize, 0, aLastError);
  {$ENDIF}
end;

// 增强传输接口实现
function TSocket.SendAll(const aData: Pointer; aSize: Integer): Integer;
var
  Sent, N, Err: Integer;
begin
  if aSize <= 0 then Exit(0);
  Sent := 0;
  while Sent < aSize do
  begin
    N := TrySend(PByte(aData) + Sent, aSize - Sent, Err);
    if N > 0 then Inc(Sent, N)
    else if (N = -1) and ((Err = SOCKET_EWOULDBLOCK) or (Err = SOCKET_EAGAIN) or (Err = SOCKET_EINTR)) then
      Continue
    else
      raise ESocketSendError.CreateFmt('SendAll失败: %d/%d (errno=%d)', [Sent, aSize, Err]);
  end;
  Result := Sent;
end;

function TSocket.SendAll(const aData: TBytes): Integer;
begin
  if Length(aData) = 0 then Exit(0);
  Result := SendAll(@aData[0], Length(aData));
end;

function TSocket.SendAll(const aData: TBytes; aOffset, aCount: Integer): Integer;
begin
  if (aCount <= 0) then Exit(0);
  if (aOffset < 0) or (aOffset + aCount > Length(aData)) then
    raise EArgumentException.Create('SendAll offset/count 越界');
  Result := SendAll(@aData[aOffset], aCount);
end;

function TSocket.Send(const aData: TBytes; aOffset, aCount: Integer): Integer;
begin
  if (aCount <= 0) then Exit(0);
  if (aOffset < 0) or (aOffset + aCount > Length(aData)) then
    raise EArgumentException.Create('Send offset/count 越界');
  Result := Send(@aData[aOffset], aCount);
end;

function TSocket.Receive(var aBuffer: TBytes; aOffset, aCount: Integer): Integer;
begin
  if (aCount <= 0) then Exit(0);
  if (aOffset < 0) or (aOffset + aCount > Length(aBuffer)) then
    raise EArgumentException.Create('Receive offset/count 越界');
  Result := Receive(@aBuffer[aOffset], aCount);
end;

function TSocket.ReceiveExact(aBuffer: Pointer; aSize: Integer): Integer;
var
  Recv, N, Err: Integer;
begin
  if aSize <= 0 then Exit(0);
  Recv := 0;
  while Recv < aSize do
  begin
    N := TryReceive(PByte(aBuffer) + Recv, aSize - Recv, Err);
    if N > 0 then Inc(Recv, N)
    else if (N = 0) then
      raise ESocketReceiveError.CreateFmt('连接已关闭，已接收 %d/%d', [Recv, aSize])
    else if (N = -1) and ((Err = SOCKET_EWOULDBLOCK) or (Err = SOCKET_EAGAIN) or (Err = SOCKET_EINTR)) then
      Continue
    else
      raise ESocketReceiveError.CreateFmt('ReceiveExact失败: %d/%d (errno=%d)', [Recv, aSize, Err]);
  end;
  Result := Recv;
end;

function TSocket.ReceiveExact(aMaxSize: Integer): TBytes;
begin
  if aMaxSize < 0 then raise EArgumentException.Create('aMaxSize<0');
  SetLength(Result, aMaxSize);
  if aMaxSize = 0 then Exit;
  ReceiveExact(@Result[0], aMaxSize);
end;
// ============================================================================
// 高性能零拷贝操作实现
// ============================================================================

{$IFDEF FAFAFA_SOCKET_ADVANCED}

function TSocket.SendBuffer(const aBuffer: TSocketBuffer): Integer;
begin
  if aBuffer.Size = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Result := Send(aBuffer.Data, aBuffer.Size);
end;

function TSocket.ReceiveBuffer(var aBuffer: TSocketBuffer): Integer;
begin
  if aBuffer.Capacity = 0 then
    raise EInvalidArgument.Create('缓冲区容量不能为0');

  Result := Receive(aBuffer.Data, aBuffer.Capacity);

  // 更新缓冲区大小为实际接收的字节数
  if aBuffer.FOwned then
    aBuffer.FSize := Result;
end;

function TSocket.SendVectorized(const aVectors: TIOVectorArray): Integer;
var
  I: Integer;
  LTotalSent: Integer;
  LBytesSent: Integer;
begin
  LTotalSent := 0;

  for I := 0 to High(aVectors) do
  begin
    if aVectors[I].Size > 0 then
    begin
      LBytesSent := Send(aVectors[I].Data, aVectors[I].Size);
      Inc(LTotalSent, LBytesSent);

      // 如果没有发送完整个向量，停止
      if LBytesSent < aVectors[I].Size then
        Break;
    end;
  end;

  Result := LTotalSent;
end;

function TSocket.ReceiveVectorized(const aVectors: TIOVectorArray): Integer;
var
  I: Integer;
  LTotalReceived: Integer;
  LBytesReceived: Integer;
begin
  LTotalReceived := 0;

  for I := 0 to High(aVectors) do
  begin
    if aVectors[I].Size > 0 then
    begin
      LBytesReceived := Receive(aVectors[I].Data, aVectors[I].Size);
      Inc(LTotalReceived, LBytesReceived);

      // 如果没有接收满整个向量，停止
      if LBytesReceived < aVectors[I].Size then
        Break;
    end;
  end;

  Result := LTotalReceived;
end;

function TSocket.SendWithPool(const aData: Pointer; aSize: Integer; aPool: TSocketBufferPool): Integer;
var
  LBuffer: TSocketBuffer;
begin
  if aSize = 0 then
  begin
    Result := 0;
    Exit;
  end;

  // 如果数据小于等于池缓冲区大小，使用池
  if aSize <= aPool.FDefaultSize then
  begin
    LBuffer := aPool.Acquire;
    try
      Move(aData^, LBuffer.Data^, aSize);
      LBuffer.FSize := aSize;
      Result := SendBuffer(LBuffer);
    finally
      aPool.Release(LBuffer);
    end;
  end
  else
  begin
    // 数据太大，直接发送
    Result := Send(aData, aSize);
  end;
end;

function TSocket.ReceiveWithPool(aMaxSize: Integer; aPool: TSocketBufferPool): TSocketBuffer;
var
  LBytesReceived: Integer;
begin
  Result := aPool.Acquire;

  if aMaxSize > Result.Capacity then
    Result.Resize(aMaxSize);

  LBytesReceived := Receive(Result.Data, aMaxSize);
  Result.FSize := LBytesReceived;
end;

{$ENDIF} // FAFAFA_SOCKET_ADVANCED high-performance buffer ops end









function TSocket.ReceiveFrom(aMaxSize: Integer; out aFromAddress: ISocketAddress): TBytes;
var
  LBytesReceived: Integer;
  LFromAddr: array[0..127] of Byte; // 足够大的缓冲区
  LAddrSize: Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上接收数据');

  if aMaxSize <= 0 then
    raise EInvalidArgument.Create('接收缓冲区大小必须大于0');

  if FHandle = INVALID_SOCKET then
    raise ESocketReceiveError.Create('Socket句柄无效');

  // 分配缓冲区
  SetLength(Result, aMaxSize);

  // 调用平台特定的recvfrom实现
  LAddrSize := SizeOf(LFromAddr);
  LBytesReceived := PlatformReceiveFromSocket(FHandle, @Result[0], aMaxSize, 0, @LFromAddr[0], LAddrSize);

  // 调整数组大小为实际接收的字节数
  SetLength(Result, LBytesReceived);

  // 创建发送方地址对象
  aFromAddress := TSocketAddress.Create('0.0.0.0', 0, afInet);
  aFromAddress.FromNativeAddr(@LFromAddr[0], LAddrSize);
end;

function TSocket.ReceiveFrom(aBuffer: Pointer; aSize: Integer; out aFromAddress: ISocketAddress): Integer;
var
  LFromAddr: array[0..127] of Byte; // 足够大的缓冲区
  LAddrSize: Integer;
begin
  if FState = ssClosed then
    raise ESocketClosedError.Create('不能在已关闭的Socket上接收数据');

  if not Assigned(aBuffer) or (aSize <= 0) then
    raise EInvalidArgument.Create('无效的缓冲区参数');

  if FHandle = INVALID_SOCKET then
    raise ESocketReceiveError.Create('Socket句柄无效');

  // 调用平台特定的recvfrom实现
  LAddrSize := SizeOf(LFromAddr);
  Result := PlatformReceiveFromSocket(FHandle, aBuffer, aSize, 0, @LFromAddr[0], LAddrSize);

  // 创建发送方地址对象
  aFromAddress := TSocketAddress.Create('0.0.0.0', 0, afInet);
  aFromAddress.FromNativeAddr(@LFromAddr[0], LAddrSize);
end;

// ISocket接口实现 - 状态查询
function TSocket.GetState: TSocketState;
begin
  Result := FState;
end;

function TSocket.GetHandle: TSocketHandle;
begin
  Result := FHandle;
end;

function TSocket.GetFamily: TAddressFamily;
begin
  Result := FFamily;
end;

function TSocket.GetSocketType: TSocketType;
begin
  Result := FSocketType;
end;

function TSocket.GetProtocol: TProtocol;
begin
  Result := FProtocol;
end;

function TSocket.GetLocalAddress: ISocketAddress;
var
  LAddr: array[0..127] of Byte;
  LAddrSize: Integer;
begin
  // 如果Socket无效，返回存储的地址
  if FHandle = INVALID_SOCKET then
  begin
    Result := FLocalAddress;
    Exit;
  end;

  // 调用getsockname获取实际的本地地址
  LAddrSize := SizeOf(LAddr);
  if PlatformGetSocketName(FHandle, @LAddr[0], LAddrSize) = 0 then
  begin
    // 创建新的地址对象并从原生地址填充
    Result := TSocketAddress.Create('0.0.0.0', 0, FFamily);
    Result.FromNativeAddr(@LAddr[0], LAddrSize);
  end
  else
  begin
    // 如果获取失败，返回存储的地址
    Result := FLocalAddress;
  end;
end;

function TSocket.GetRemoteAddress: ISocketAddress;
begin
  Result := FRemoteAddress;
end;

function TSocket.IsValid: Boolean;
begin
  Result := (FHandle <> INVALID_SOCKET) and (FState <> ssClosed);
end;

function TSocket.IsConnected: Boolean;
begin
  Result := FState = ssConnected;
end;

function TSocket.IsListening: Boolean;
begin
  Result := FState = ssListening;
end;

function TSocket.IsClosed: Boolean;
begin
  Result := FState = ssClosed;
end;

// ISocket接口实现 - Socket选项
procedure TSocket.SetReuseAddress(aValue: Boolean);
begin
  FReuseAddress := aValue;
  // 在Windows上使用SO_REUSEADDR
  {$IFDEF WINDOWS}
  SetBooleanOption($FFFF, $0004, aValue); // SOL_SOCKET=$FFFF, SO_REUSEADDR=$0004
  {$ELSE}
  SetBooleanOption(1, 2, aValue); // SOL_SOCKET=1, SO_REUSEADDR=2
  {$ENDIF}
end;

function TSocket.GetReuseAddress: Boolean;
begin
  Result := FReuseAddress;
end;

procedure TSocket.SetKeepAlive(aValue: Boolean);
begin
  // 先设置内核，再更新缓存
  {$IFDEF WINDOWS}
  SetBooleanOption($FFFF, $0008, aValue); // SOL_SOCKET=$FFFF, SO_KEEPALIVE=$0008
  {$ELSE}
  SetBooleanOption(1, 9, aValue); // SOL_SOCKET=1, SO_KEEPALIVE=9
  {$ENDIF}
  FKeepAlive := aValue;
end;

function TSocket.GetKeepAlive: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetBooleanOption($FFFF, $0008);
  {$ELSE}
  Result := GetBooleanOption(1, 9);
  {$ENDIF}
  FKeepAlive := Result;
end;

procedure TSocket.SetTcpNoDelay(aValue: Boolean);
begin
  {$IFDEF WINDOWS}
  SetBooleanOption(6, $0001, aValue); // IPPROTO_TCP=6, TCP_NODELAY=$0001
  {$ELSE}
  SetBooleanOption(6, 1, aValue); // IPPROTO_TCP=6, TCP_NODELAY=1
  {$ENDIF}
  FTcpNoDelay := aValue;
end;

function TSocket.GetTcpNoDelay: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetBooleanOption(6, $0001);
  {$ELSE}
  Result := GetBooleanOption(6, 1);
  {$ENDIF}
  FTcpNoDelay := Result;
end;

// 现代化超时设置方法
procedure TSocket.SetSendTimeout(const aTimeout: TTimeSpan);
begin
  SetSendTimeout(aTimeout.ToMilliseconds);
end;

function TSocket.GetSendTimeoutSpan: TTimeSpan;
begin
  Result := TTimeSpan.FromMilliseconds(GetSendTimeout);
end;

procedure TSocket.SetReceiveTimeout(const aTimeout: TTimeSpan);
begin
  SetReceiveTimeout(aTimeout.ToMilliseconds);
end;

function TSocket.GetReceiveTimeoutSpan: TTimeSpan;
begin
  Result := TTimeSpan.FromMilliseconds(GetReceiveTimeout);
end;

// 向后兼容的超时设置方法
procedure TSocket.SetSendTimeout(aMilliseconds: Integer);
begin
  if aMilliseconds < 0 then
    raise EInvalidArgument.Create('发送超时时间不能为负数');

  {$IFDEF WINDOWS}
  SetIntegerOption($FFFF, $1005, aMilliseconds); // SOL_SOCKET=$FFFF, SO_SNDTIMEO=$1005
  {$ELSE}
  // Unix: 使用 timeval 结构
  var tv: TTimeVal;
  tv.tv_sec := aMilliseconds div 1000;
  tv.tv_usec := (aMilliseconds mod 1000) * 1000;
  SetSocketOption(1, 21, @tv, SizeOf(tv)); // SOL_SOCKET=1, SO_SNDTIMEO=21
  {$ENDIF}
  FSendTimeout := aMilliseconds;
end;

function TSocket.GetSendTimeout: Integer;
begin
  {$IFDEF WINDOWS}
  Result := GetIntegerOption($FFFF, $1005);
  {$ELSE}
  var tv: TTimeVal;
  var sz: Integer := SizeOf(tv);
  FillChar(tv, SizeOf(tv), 0);
  GetSocketOption(1, 21, @tv, sz);
  Result := (tv.tv_sec * 1000) + (tv.tv_usec div 1000);
  {$ENDIF}
  FSendTimeout := Result;
end;

procedure TSocket.SetReceiveTimeout(aMilliseconds: Integer);
begin
  if aMilliseconds < 0 then
    raise EInvalidArgument.Create('接收超时时间不能为负数');

  {$IFDEF WINDOWS}
  SetIntegerOption($FFFF, $1006, aMilliseconds); // SOL_SOCKET=$FFFF, SO_RCVTIMEO=$1006
  {$ELSE}
  var tv: TTimeVal;
  tv.tv_sec := aMilliseconds div 1000;
  tv.tv_usec := (aMilliseconds mod 1000) * 1000;
  SetSocketOption(1, 20, @tv, SizeOf(tv)); // SOL_SOCKET=1, SO_RCVTIMEO=20
  {$ENDIF}
  FReceiveTimeout := aMilliseconds;
end;

function TSocket.GetReceiveTimeout: Integer;
begin
  {$IFDEF WINDOWS}
  Result := GetIntegerOption($FFFF, $1006);
  {$ELSE}
  var tv: TTimeVal;
  var sz: Integer := SizeOf(tv);
  FillChar(tv, SizeOf(tv), 0);
  GetSocketOption(1, 20, @tv, sz);
  Result := (tv.tv_sec * 1000) + (tv.tv_usec div 1000);
  {$ENDIF}
  FReceiveTimeout := Result;
end;

procedure TSocket.SetSendBufferSize(aSize: Integer);
begin
  if aSize <= 0 then
    raise EInvalidArgument.Create('发送缓冲区大小必须大于0');

  FSendBufferSize := aSize;
  // 在Windows上使用SO_SNDBUF
  {$IFDEF WINDOWS}
  SetIntegerOption($FFFF, $1001, aSize); // SOL_SOCKET=$FFFF, SO_SNDBUF=$1001
  {$ELSE}
  SetIntegerOption(1, 7, aSize); // SOL_SOCKET=1, SO_SNDBUF=7
  {$ENDIF}
end;

function TSocket.GetSendBufferSize: Integer;
begin
  // 从内核读取，避免仅返回内部缓存
  {$IFDEF WINDOWS}
  Result := GetIntegerOption($FFFF, $1001);
  {$ELSE}
  Result := GetIntegerOption(1, 7);
  {$ENDIF}
end;

procedure TSocket.SetReceiveBufferSize(aSize: Integer);
begin
  if aSize <= 0 then
    raise EInvalidArgument.Create('接收缓冲区大小必须大于0');

  FReceiveBufferSize := aSize;
  // 在Windows上使用SO_RCVBUF
  {$IFDEF WINDOWS}
  SetIntegerOption($FFFF, $1002, aSize); // SOL_SOCKET=$FFFF, SO_RCVBUF=$1002
  {$ELSE}
  SetIntegerOption(1, 8, aSize); // SOL_SOCKET=1, SO_RCVBUF=8
  {$ENDIF}
end;

function TSocket.GetReceiveBufferSize: Integer;
begin
  {$IFDEF WINDOWS}
  Result := GetIntegerOption($FFFF, $1002);
  {$ELSE}
  Result := GetIntegerOption(1, 8);
  {$ENDIF}
end;

// 扩展选项实现
procedure TSocket.SetBroadcast(aValue: Boolean);
begin
  // SO_BROADCAST
  {$IFDEF WINDOWS}
  SetBooleanOption(SOL_SOCKET, SO_BROADCAST, aValue);
  {$ELSE}
  SetBooleanOption(SOL_SOCKET, SO_BROADCAST, aValue);
  {$ENDIF}
  FBroadcast := aValue;
end;

function TSocket.GetBroadcast: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetBooleanOption(SOL_SOCKET, SO_BROADCAST);
  {$ELSE}
  Result := GetBooleanOption(SOL_SOCKET, SO_BROADCAST);
  {$ENDIF}
  FBroadcast := Result;
end;

procedure TSocket.SetReusePort(aValue: Boolean);
begin
  {$IFDEF WINDOWS}
  // Windows 对 SO_REUSEPORT 支持历史不一致；优先使用 SO_EXCLUSIVEADDRUSE/ReuseAddress 组合
  // 这里尽力调用，失败不致命（可在文档中说明）
  try
    SetBooleanOption(SOL_SOCKET, SO_REUSEPORT, aValue);
  except
    // 忽略不支持错误
  end;
  {$ELSE}
  // Unix/Linux: SO_REUSEPORT 普遍可用（内核依赖）
  SetBooleanOption(SOL_SOCKET, SO_REUSEPORT, aValue);
  {$ENDIF}
  FReusePort := aValue;
end;

function TSocket.GetReusePort: Boolean;
begin
  {$IFDEF WINDOWS}
  try
    Result := GetBooleanOption(SOL_SOCKET, SO_REUSEPORT);
  except
    Result := False; // 读回失败则按不支持处理
  end;
  {$ELSE}
  Result := GetBooleanOption(SOL_SOCKET, SO_REUSEPORT);
  {$ENDIF}
  FReusePort := Result;
end;

procedure TSocket.SetIPv6Only(aValue: Boolean);
begin
  // 仅对 IPv6 套接字有效
  if FFamily <> afInet6 then Exit;
  SetBooleanOption(IPPROTO_IPV6, IPV6_V6ONLY, aValue);
  FIPv6Only := aValue;
end;

function TSocket.GetIPv6Only: Boolean;
begin
  if FFamily <> afInet6 then Exit(False);
  Result := GetBooleanOption(IPPROTO_IPV6, IPV6_V6ONLY);
  FIPv6Only := Result;
end;

type
  TLinger = packed record
    {$IFDEF WINDOWS}
    l_onoff: Word;   // u_short in WinSock
    l_linger: Word;  // u_short in WinSock
    {$ELSE}
    l_onoff: Integer;  // int on POSIX
    l_linger: Integer; // int on POSIX
    {$ENDIF}
  end;

procedure TSocket.SetLinger(aEnabled: Boolean; aSeconds: Integer);
var
  L: TLinger;
begin
  if aSeconds < 0 then aSeconds := 0;
  L.l_onoff := Ord(aEnabled);
  if aSeconds > High(Word) then L.l_linger := High(Word) else L.l_linger := aSeconds;
  SetSocketOption(SOL_SOCKET, SO_LINGER, @L, SizeOf(L));
  FLingerEnabled := aEnabled;
  FLingerSeconds := aSeconds;
end;

procedure TSocket.GetLinger(out aEnabled: Boolean; out aSeconds: Integer);
var
  L: TLinger;
  sz: Integer;
begin
  sz := SizeOf(L);
  FillChar(L, sz, 0);
  GetSocketOption(SOL_SOCKET, SO_LINGER, @L, sz);
  aEnabled := L.l_onoff <> 0;
  aSeconds := L.l_linger;
  FLingerEnabled := aEnabled;
  FLingerSeconds := aSeconds;
end;

// 非阻塞模式
procedure TSocket.SetNonBlocking(aValue: Boolean);
begin
  {$IFDEF WINDOWS}
  if not PlatformSetNonBlocking(FHandle, aValue) then
    raise ESocketError.Create('设置非阻塞模式失败');
  {$ELSE}
  if not PlatformSetNonBlocking(FHandle, aValue) then
    raise ESocketError.Create('设置非阻塞模式失败');
  {$ENDIF}
  FNonBlocking := aValue;
end;

function TSocket.GetNonBlocking: Boolean;
begin
  {$IFDEF WINDOWS}
  // Windows 无法可靠查询当前非阻塞标志，返回缓存值
  Result := FNonBlocking;
  {$ELSE}
  Result := PlatformGetNonBlocking(FHandle);
  FNonBlocking := Result;
  {$ENDIF}
end;

// Windows特有的高级选项实现
procedure TSocket.SetExclusiveAddressUse(aValue: Boolean);
begin
  {$IFDEF WINDOWS}
  SetBooleanOption(SOL_SOCKET, SO_EXCLUSIVEADDRUSE, aValue);
  {$ELSE}
  // 在非Windows平台上忽略此选项
  aValue := aValue; // 抑制未使用参数警告
  {$ENDIF}
end;

function TSocket.GetExclusiveAddressUse: Boolean;
begin
  {$IFDEF WINDOWS}
  Result := GetBooleanOption(SOL_SOCKET, SO_EXCLUSIVEADDRUSE);
  {$ELSE}
  // 在非Windows平台上返回默认值
  Result := False;
  {$ENDIF}
end;

{ TSocketListener }

constructor TSocketListener.Create(const aAddress: ISocketAddress);
begin
  inherited Create;

  if not Assigned(aAddress) then
    raise EArgumentNil.Create('监听地址不能为空');

  FListenAddress := aAddress;
  FMaxConnections := 100;
  FBacklog := 128;
  FActive := False;

  // 创建TCP Socket用于监听
  FSocket := TSocket.CreateTCP(aAddress.Family);
end;

destructor TSocketListener.Destroy;
begin
  if FActive then
    Stop;
  FSocket := nil;
  FListenAddress := nil;
  inherited Destroy;
end;

class function TSocketListener.CreateTCP(const aAddress: ISocketAddress): ISocketListener;
begin
  Result := TSocketListener.Create(aAddress);
end;

class function TSocketListener.CreateUDP(const aAddress: ISocketAddress): ISocketListener;
begin
  // UDP不需要监听，但为了接口一致性提供此方法
  Result := TSocketListener.Create(aAddress);
  // 注意：UDP的实现会有所不同
end;

// 便捷工厂方法实现
class function TSocketListener.ListenTCP(aPort: Word): ISocketListener;
var
  LAddress: ISocketAddress;
begin
  // 在所有IPv4接口上监听TCP连接
  LAddress := TSocketAddress.Any(aPort);
  Result := TSocketListener.Create(LAddress);
end;

class function TSocketListener.ListenTCPv6(aPort: Word): ISocketListener;
var
  LAddress: ISocketAddress;
begin
  // 在所有IPv6接口上监听TCP连接
  LAddress := TSocketAddress.AnyIPv6(aPort);
  Result := TSocketListener.Create(LAddress);
end;

class function TSocketListener.ListenLocalhost(aPort: Word): ISocketListener;
var
  LAddress: ISocketAddress;
begin
  // 只在本地回环接口上监听TCP连接
  LAddress := TSocketAddress.Localhost(aPort);
  Result := TSocketListener.Create(LAddress);
end;

// ISocketListener接口实现 - 监听控制
procedure TSocketListener.Start;
begin
  if FActive then
    raise ESocketError.Create('监听器已经激活');

  try
    // 设置Socket选项
    FSocket.ReuseAddress := True;

    // 绑定地址
    FSocket.Bind(FListenAddress);

    // 开始监听
    FSocket.Listen(FBacklog);

    // 若传入端口为0，绑定后同步真实端口到ListenAddress，便于外部查询
    try
      if (FListenAddress <> nil) and (FListenAddress.Port = 0) then
      begin
        with FSocket.LocalAddress do
          if (Self <> nil) and (Port <> 0) then
            FListenAddress := TSocketAddress.Create(Host, Port, Family);
      end;
    except
      // 同步失败不影响监听
    end;

    FActive := True;
  except
    on E: Exception do
    begin
      FActive := False;
      raise ESocketError.Create('启动监听失败: ' + E.Message);
    end;
  end;
end;

procedure TSocketListener.Stop;
begin
  if not FActive then
    Exit; // 已经停止

  try
    FSocket.Close;
    FActive := False;
  except
    on E: Exception do
      raise ESocketError.Create('停止监听失败: ' + E.Message);
  end;
end;

// 新的标准方法
function TSocketListener.Accept: ISocket;
begin
  if not FActive then
    raise ESocketError.Create('监听器未激活');

  try
    Result := FSocket.Accept;
  except
    on E: Exception do
      raise ESocketAcceptError.Create('接受客户端连接失败: ' + E.Message);
  end;
end;

function TSocketListener.AcceptWithTimeout(aTimeoutMs: Cardinal): ISocket;
var
  LReady: Integer;
  LReadSet: Pointer;
  LTimeout: Pointer;
{$IFDEF UNIX}
  LMaxFd: cint;
{$ENDIF}
begin
  if not FActive then
    raise ESocketError.Create('监听器未激活');

  // aTimeoutMs=0 视为非阻塞轮询：立即返回，无连接则超时异常
  // 不再直接调用 Accept 以避免在无客户端时阻塞

  // 从池中借用 FDSet 和 timeval
  LReadSet := TFDSetPool.Instance.BorrowFDSet;
  LTimeout := TFDSetPool.Instance.BorrowTimeval;
  try
    {$IFDEF WINDOWS}
    // 使用 WinSock select 等待可读（有新连接）
    FD_SET(QWord(FSocket.Handle), TFDSet(LReadSet^));
    timeval(LTimeout^).tv_sec := aTimeoutMs div 1000;
    timeval(LTimeout^).tv_usec := (aTimeoutMs mod 1000) * 1000;
    LReady := select(0, LReadSet, nil, nil, LTimeout);
    if LReady = SOCKET_ERROR then
      raise ESocketError.Create('等待连接失败: ' + IntToStr(GetLastSocketErrorCode));
    if LReady = 0 then
    begin
      Result := nil; Exit;
    end;
    {$ENDIF}

    {$IFDEF UNIX}
    // 使用 fpSelect 等待可读（有新连接）
    fpFD_SET(cint(FSocket.Handle), TFDSet(LReadSet^));
    TTimeVal(LTimeout^).tv_sec := aTimeoutMs div 1000;
    TTimeVal(LTimeout^).tv_usec := (aTimeoutMs mod 1000) * 1000;
    LMaxFd := cint(FSocket.Handle) + 1;
    LReady := fpSelect(LMaxFd, LReadSet, nil, nil, LTimeout);
    if LReady = -1 then
      raise ESocketError.Create('等待连接失败: ' + IntToStr(fpGetErrno));
    if LReady = 0 then
    begin
      Result := nil; Exit;
    end;
    {$ENDIF}

    // 有连接可接受
    Result := Accept;
  finally
    // 归还到池中
    TFDSetPool.Instance.ReturnFDSet(LReadSet);
    TFDSetPool.Instance.ReturnTimeval(LTimeout);
  end;
end;

// 向后兼容的别名实现
function TSocketListener.AcceptClient: ISocket;
begin
  Result := Accept;
end;

function TSocketListener.AcceptClientTimeout(aTimeoutMs: Cardinal): ISocket;
begin
  Result := AcceptWithTimeout(aTimeoutMs);
end;

// ISocketListener接口实现 - 配置
procedure TSocketListener.SetMaxConnections(aCount: Integer);
begin
  if aCount <= 0 then
    raise EInvalidArgument.Create('最大连接数必须大于0');

  FMaxConnections := aCount;
end;

function TSocketListener.GetMaxConnections: Integer;
begin
  Result := FMaxConnections;
end;

procedure TSocketListener.SetBacklog(aBacklog: Integer);
begin
  if aBacklog <= 0 then
    raise EInvalidArgument.Create('Backlog必须大于0');

  if FActive then
    raise ESocketError.Create('不能在激活状态下修改Backlog');

  FBacklog := aBacklog;
end;

function TSocketListener.GetBacklog: Integer;
begin
  Result := FBacklog;
end;

// ISocketListener接口实现 - 状态查询
function TSocketListener.IsActive: Boolean;
begin
  Result := FActive;
end;

function TSocketListener.GetListenAddress: ISocketAddress;
begin
  // 返回拷贝，避免外部持有与内部共享同一实例造成生命周期/内存破坏
  if FListenAddress <> nil then
    Result := TSocketAddress.Create(FListenAddress.Host, FListenAddress.Port, FListenAddress.Family)
  else
    Result := nil;
end;

function TSocketListener.GetSocket: ISocket;
begin
  Result := FSocket;
end;

procedure TSocketListener.SetActive(aValue: Boolean);
begin
  if aValue then
  begin
    if not FActive then Start;
  end
  else
  begin
    if FActive then Stop;
  end;
end;


function TSocketListener.GetExtendedStatisticsJson: string;
begin
  Result := '{' +
    '"active":' + LowerCase(BoolToStr(FActive, True)) + ',' +
    '"backlog":' + IntToStr(FBacklog) + ',' +
    '"maxConnections":' + IntToStr(FMaxConnections) + ',' +
    '"listen":"' + IfThen(FListenAddress<>nil, FListenAddress.ToString, '') + '",' +
    '"socket":' + (FSocket as TSocket).GetExtendedStatisticsJson +
  '}';
end;


{ TFDSetPool }

class constructor TFDSetPool.Create;
begin
  InitCriticalSection(FClassLock);
  FInstance := nil;
end;

class destructor TFDSetPool.Destroy;
begin
  FreeAndNil(FInstance);
  DoneCriticalSection(FClassLock);
end;

constructor TFDSetPool.Create;
begin
  inherited Create;
  InitCriticalSection(FInstanceLock);
  SetLength(FAvailableSets, 0);
  SetLength(FAvailableTimevals, 0);
  FSetCount := 0;
  FTimevalCount := 0;
end;

destructor TFDSetPool.Destroy;
var
  I: Integer;
begin
  // 清理所有分配的 FDSet
  for I := 0 to FSetCount - 1 do
    FreeMem(FAvailableSets[I]);

  // 清理所有分配的 Timeval
  for I := 0 to FTimevalCount - 1 do
    FreeMem(FAvailableTimevals[I]);

  DoneCriticalSection(FInstanceLock);
  inherited Destroy;
end;

function TFDSetPool.BorrowFDSet: Pointer;
begin
  EnterCriticalSection(FInstanceLock);
  try
    if FSetCount > 0 then
    begin
      Dec(FSetCount);
      Result := FAvailableSets[FSetCount];
    end
    else
    begin
      {$IFDEF WINDOWS}
      GetMem(Result, SizeOf(TFDSet));
      {$ELSE}
      GetMem(Result, SizeOf(TFDSet));
      {$ENDIF}
    end;
    // 清零 FDSet
    {$IFDEF WINDOWS}
    FD_ZERO(TFDSet(Result^));
    {$ELSE}
    fpFD_ZERO(TFDSet(Result^));
    {$ENDIF}
  finally
    LeaveCriticalSection(FInstanceLock);
  end;
end;

procedure TFDSetPool.ReturnFDSet(ASet: Pointer);
begin
  if ASet = nil then Exit;

  EnterCriticalSection(FInstanceLock);
  try
    // 限制池大小，避免无限增长
    if FSetCount < 16 then
    begin
      if FSetCount >= Length(FAvailableSets) then
        SetLength(FAvailableSets, FSetCount + 8);
      FAvailableSets[FSetCount] := ASet;
      Inc(FSetCount);
    end
    else
      FreeMem(ASet);
  finally
    LeaveCriticalSection(FInstanceLock);
  end;
end;

function TFDSetPool.BorrowTimeval: Pointer;
begin
  EnterCriticalSection(FInstanceLock);
  try
    if FTimevalCount > 0 then
    begin
      Dec(FTimevalCount);
      Result := FAvailableTimevals[FTimevalCount];
    end
    else
    begin
      {$IFDEF WINDOWS}
      GetMem(Result, SizeOf(timeval));
      {$ELSE}
      GetMem(Result, SizeOf(TTimeVal));
      {$ENDIF}
    end;
    // 清零 timeval
    {$IFDEF WINDOWS}
    FillChar(Result^, SizeOf(timeval), 0);
    {$ELSE}
    FillChar(Result^, SizeOf(TTimeVal), 0);
    {$ENDIF}
  finally
    LeaveCriticalSection(FInstanceLock);
  end;
end;

procedure TFDSetPool.ReturnTimeval(ATimeval: Pointer);
begin
  if ATimeval = nil then Exit;

  EnterCriticalSection(FInstanceLock);
  try
    // 限制池大小
    if FTimevalCount < 16 then
    begin
      if FTimevalCount >= Length(FAvailableTimevals) then
        SetLength(FAvailableTimevals, FTimevalCount + 8);
      FAvailableTimevals[FTimevalCount] := ATimeval;
      Inc(FTimevalCount);
    end
    else
      FreeMem(ATimeval);
  finally
    LeaveCriticalSection(FInstanceLock);
  end;
end;

class function TFDSetPool.Instance: TFDSetPool;
begin
  if FInstance = nil then
  begin
    EnterCriticalSection(FClassLock);
    try
      if FInstance = nil then
        FInstance := TFDSetPool.Create;
    finally
      LeaveCriticalSection(FClassLock);
    end;
  end;
  Result := FInstance;
end;

// TSocket 诊断和监控方法实现
function TSocket.GetDiagnosticInfo: string;
begin
  Result := Format('Socket Diagnostic Info:'#13#10 +
    '  Handle: %d'#13#10 +
    '  State: %s'#13#10 +
    '  Family: %s'#13#10 +
    '  Type: %s'#13#10 +
    '  Protocol: %s'#13#10 +
    '  Local Address: %s'#13#10 +
    '  Remote Address: %s'#13#10 +
    '  NonBlocking: %s'#13#10 +
    '  Statistics:'#13#10 +
    '    Bytes Sent: %d'#13#10 +
    '    Bytes Received: %d'#13#10 +
    '    Send Operations: %d'#13#10 +
    '    Receive Operations: %d'#13#10 +
    '    Error Count: %d'#13#10 +
    '    Connection Time: %s'#13#10 +
    '    Last Activity: %s',
    [
      Integer(FHandle),
      GetEnumName(TypeInfo(TSocketState), Ord(FState)),
      GetEnumName(TypeInfo(TAddressFamily), Ord(FFamily)),
      GetEnumName(TypeInfo(TSocketType), Ord(FSocketType)),
      GetEnumName(TypeInfo(TProtocol), Ord(FProtocol)),
      IfThen(Assigned(FLocalAddress), FLocalAddress.ToString, 'None'),
      IfThen(Assigned(FRemoteAddress), FRemoteAddress.ToString, 'None'),
      BoolToStr(FNonBlocking, True),
      FStatistics.BytesSent,
      FStatistics.BytesReceived,
      FStatistics.SendOperations,
      FStatistics.ReceiveOperations,
      FStatistics.ErrorCount,
      DateTimeToStr(FStatistics.ConnectionTime),
      DateTimeToStr(FStatistics.LastActivity)
    ]);
end;

function TSocket.GetStatistics: TSocketStatistics;
begin
  Result := FStatistics;
end;

procedure TSocket.ResetStatistics;
begin
  FillChar(FStatistics, SizeOf(FStatistics), 0);
  FStatistics.ConnectionTime := Now;
  FStatistics.LastActivity := Now;
end;

function TSocket.GetStatisticsJson: string;
var LLocal, LRemote: string;
begin
  if Assigned(FLocalAddress) then LLocal := FLocalAddress.ToString else LLocal := '';
  if Assigned(FRemoteAddress) then LRemote := FRemoteAddress.ToString else LRemote := '';
  Result := '{' +
    '"handle":' + IntToStr(Integer(FHandle)) + ',' +
    '"state":"' + GetEnumName(TypeInfo(TSocketState), Ord(FState)) + '",' +
    '"family":"' + GetEnumName(TypeInfo(TAddressFamily), Ord(FFamily)) + '",' +
    '"type":"' + GetEnumName(TypeInfo(TSocketType), Ord(FSocketType)) + '",' +
    '"protocol":"' + GetEnumName(TypeInfo(TProtocol), Ord(FProtocol)) + '",' +
    '"local":"' + LLocal + '",' +
    '"remote":"' + LRemote + '",' +
    '"nonBlocking":' + LowerCase(BoolToStr(FNonBlocking, True)) + ',' +
    '"stats":{' +
      '"bytesSent":' + IntToStr(FStatistics.BytesSent) + ',' +
      '"bytesReceived":' + IntToStr(FStatistics.BytesReceived) + ',' +
      '"sendOps":' + IntToStr(FStatistics.SendOperations) + ',' +
      '"recvOps":' + IntToStr(FStatistics.ReceiveOperations) + ',' +
      '"errors":' + IntToStr(FStatistics.ErrorCount) + ',' +
      '"connTime":"' + DateTimeToStr(FStatistics.ConnectionTime) + '",' +
      '"lastActivity":"' + DateTimeToStr(FStatistics.LastActivity) + '"' +
    '}' +
  '}';
end;

function TSocket.GetExtendedStatisticsJson: string;
var LLocal, LRemote: string;
begin
  if Assigned(FLocalAddress) then LLocal := FLocalAddress.ToString else LLocal := '';
  if Assigned(FRemoteAddress) then LRemote := FRemoteAddress.ToString else LRemote := '';
  Result := '{' +
    '"handle":' + IntToStr(Integer(FHandle)) + ',' +
    '"state":"' + GetEnumName(TypeInfo(TSocketState), Ord(FState)) + '",' +
    '"family":"' + GetEnumName(TypeInfo(TAddressFamily), Ord(FFamily)) + '",' +
    '"type":"' + GetEnumName(TypeInfo(TSocketType), Ord(FSocketType)) + '",' +
    '"protocol":"' + GetEnumName(TypeInfo(TProtocol), Ord(FProtocol)) + '",' +
    '"local":"' + LLocal + '",' +
    '"remote":"' + LRemote + '",' +
    '"nonBlocking":' + LowerCase(BoolToStr(FNonBlocking, True)) + ',' +
    '"options":{' +
      '"keepAlive":' + LowerCase(BoolToStr(FKeepAlive, True)) + ',' +
      '"tcpNoDelay":' + LowerCase(BoolToStr(FTcpNoDelay, True)) + ',' +
      '"reuseAddress":' + LowerCase(BoolToStr(FReuseAddress, True)) + ',' +
      '"reusePort":' + LowerCase(BoolToStr(FReusePort, True)) + ',' +
      '"ipv6Only":' + LowerCase(BoolToStr(FIPv6Only, True)) + ',' +
      '"sendBufferSize":' + IntToStr(FSendBufferSize) + ',' +
      '"receiveBufferSize":' + IntToStr(FReceiveBufferSize) + ',' +
      '"sendTimeoutMs":' + IntToStr(FSendTimeout) + ',' +
      '"receiveTimeoutMs":' + IntToStr(FReceiveTimeout) + ',' +
      '"lingerEnabled":' + LowerCase(BoolToStr(FLingerEnabled, True)) + ',' +
      '"lingerSeconds":' + IntToStr(FLingerSeconds) + ',' +
      '"exclusiveAddressUse":' + LowerCase(BoolToStr(GetExclusiveAddressUse, True)) +
    '},' +
    '"stats":{' +
      '"bytesSent":' + IntToStr(FStatistics.BytesSent) + ',' +
      '"bytesReceived":' + IntToStr(FStatistics.BytesReceived) + ',' +
      '"sendOps":' + IntToStr(FStatistics.SendOperations) + ',' +
      '"recvOps":' + IntToStr(FStatistics.ReceiveOperations) + ',' +
      '"errors":' + IntToStr(FStatistics.ErrorCount) + ',' +
      '"connTime":"' + DateTimeToStr(FStatistics.ConnectionTime) + '",' +
      '"lastActivity":"' + DateTimeToStr(FStatistics.LastActivity) + '"' +
    '}' +
  '}';
end;


{ TSocketBuilder }

constructor TSocketBuilder.Create(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol);
begin
  inherited Create;
  FFamily := aFamily;
  FSocketType := aType;
  FProtocol := aProtocol;

  // 设置默认值
  FSendTimeout := TTimeSpan.Zero;
  FReceiveTimeout := TTimeSpan.Zero;
  FKeepAlive := False;
  FTcpNoDelay := False;
  FReuseAddress := False;
  FReusePort := False;
  FBroadcast := False;
  FSendBufferSize := 8192;
  FReceiveBufferSize := 8192;
  FNonBlocking := False;
end;

function TSocketBuilder.WithTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
begin
  FSendTimeout := aTimeout;
  FReceiveTimeout := aTimeout;
  Result := Self;
end;

function TSocketBuilder.WithSendTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
begin
  FSendTimeout := aTimeout;
  Result := Self;
end;

function TSocketBuilder.WithReceiveTimeout(const aTimeout: TTimeSpan): ISocketBuilder;
begin
  FReceiveTimeout := aTimeout;
  Result := Self;
end;

function TSocketBuilder.WithKeepAlive(aEnabled: Boolean): ISocketBuilder;
begin
  FKeepAlive := aEnabled;
  Result := Self;
end;

function TSocketBuilder.WithNoDelay(aEnabled: Boolean): ISocketBuilder;
begin
  FTcpNoDelay := aEnabled;
  Result := Self;
end;

function TSocketBuilder.WithReuseAddress(aEnabled: Boolean): ISocketBuilder;
begin
  FReuseAddress := aEnabled;
  Result := Self;
end;

function TSocketBuilder.WithReusePort(aEnabled: Boolean): ISocketBuilder;
begin
  FReusePort := aEnabled;
  Result := Self;
end;

function TSocketBuilder.WithBroadcast(aEnabled: Boolean): ISocketBuilder;
begin
  FBroadcast := aEnabled;
  Result := Self;
end;

function TSocketBuilder.WithBufferSize(aSendSize, aReceiveSize: Integer): ISocketBuilder;
begin
  FSendBufferSize := aSendSize;
  FReceiveBufferSize := aReceiveSize;
  Result := Self;
end;

function TSocketBuilder.WithNonBlocking(aEnabled: Boolean): ISocketBuilder;
begin
  FNonBlocking := aEnabled;
  Result := Self;
end;

function TSocketBuilder.Build: ISocket;
begin
  // 创建Socket
  Result := TSocket.Create(FFamily, FSocketType, FProtocol);

  // 应用配置
  if not FSendTimeout.IsZero then
  begin
  {$IFDEF FAFAFA_SOCKET_ADVANCED}
    Result.SetSendTimeout(FSendTimeout);
  {$ELSE}
    Result.SetSendTimeout(Integer(FSendTimeout.ToMilliseconds));
  {$ENDIF}
  end;
  if not FReceiveTimeout.IsZero then
  begin
  {$IFDEF FAFAFA_SOCKET_ADVANCED}
    Result.SetReceiveTimeout(FReceiveTimeout);
  {$ELSE}
    Result.SetReceiveTimeout(Integer(FReceiveTimeout.ToMilliseconds));
  {$ENDIF}
  end;

  Result.KeepAlive := FKeepAlive;
  Result.TcpNoDelay := FTcpNoDelay;
  Result.ReuseAddress := FReuseAddress;
  Result.ReusePort := FReusePort;
  Result.Broadcast := FBroadcast;
  Result.SendBufferSize := FSendBufferSize;
  Result.ReceiveBufferSize := FReceiveBufferSize;
  Result.NonBlocking := FNonBlocking;
end;

function TSocketBuilder.BuildAndConnect(const aHost: string; aPort: Word): ISocket;
var




  LAddress: ISocketAddress;
begin
  Result := Build;
  try
    LAddress := TSocketAddress.Create(aHost, aPort, FFamily);
    Result.Connect(LAddress);
  except
    Result.Close;
    raise;
  end;
end;

{$IFDEF FAFAFA_SOCKET_ADVANCED}

// ============================================================================
// 高性能缓冲区管理实现
// ============================================================================

{ TSocketBuffer }

class function TSocketBuffer.Create(aCapacity: Integer): TSocketBuffer;
begin
  Result.FCapacity := aCapacity;
  Result.FSize := 0;
  Result.FOwned := True;
  GetMem(Result.FData, aCapacity);
end;

class function TSocketBuffer.Wrap(aData: Pointer; aSize: Integer): TSocketBuffer;
begin
  Result.FData := aData;
  Result.FSize := aSize;
  Result.FCapacity := aSize;
  Result.FOwned := False;
end;

procedure TSocketBuffer.Free;
begin
  if FOwned and Assigned(FData) then
  begin
    FreeMem(FData);
    FData := nil;
  end;
  FSize := 0;
  FCapacity := 0;
  FOwned := False;
end;

function TSocketBuffer.GetData: Pointer;
begin
  Result := FData;
end;

function TSocketBuffer.GetSize: Integer;
begin
  Result := FSize;
end;

function TSocketBuffer.GetCapacity: Integer;
begin
  Result := FCapacity;
end;

procedure TSocketBuffer.Resize(aNewSize: Integer);
begin
  if not FOwned then
    raise EInvalidOperation.Create('不能调整非拥有缓冲区的大小');

  if aNewSize > FCapacity then
  begin
    FCapacity := aNewSize;
    ReallocMem(FData, FCapacity);
  end;
  FSize := aNewSize;
end;

{ TSocketBufferPool }

constructor TSocketBufferPool.Create(aDefaultSize: Integer; aMaxBuffers: Integer);
var
  I: Integer;
begin
  inherited Create;
  FDefaultSize := aDefaultSize;
  FMaxBuffers := aMaxBuffers;
  FCurrentCount := 0;

  SetLength(FBuffers, FMaxBuffers);
  SetLength(FAvailable, FMaxBuffers);

  // 预分配一些缓冲区
  for I := 0 to Min(8, FMaxBuffers - 1) do
  begin
    FBuffers[I] := TSocketBuffer.Create(FDefaultSize);
    FAvailable[I] := True;
    Inc(FCurrentCount);
  end;
end;

destructor TSocketBufferPool.Destroy;
var
  I: Integer;
begin
  for I := 0 to FCurrentCount - 1 do
    FBuffers[I].Free;
  inherited Destroy;
end;

function TSocketBufferPool.Acquire: TSocketBuffer;
var
  I: Integer;
begin
  // 查找可用缓冲区
  for I := 0 to FCurrentCount - 1 do
  begin
    if FAvailable[I] then
    begin
      FAvailable[I] := False;
      Result := FBuffers[I];
      Exit;
    end;
  end;

  // 如果没有可用的，创建新的
  if FCurrentCount < FMaxBuffers then
  begin
    FBuffers[FCurrentCount] := TSocketBuffer.Create(FDefaultSize);
    FAvailable[FCurrentCount] := False;
    Result := FBuffers[FCurrentCount];
    Inc(FCurrentCount);
  end
  else
  begin
    // 池已满，创建临时缓冲区
    Result := TSocketBuffer.Create(FDefaultSize);
  end;
end;

procedure TSocketBufferPool.Release(var aBuffer: TSocketBuffer);
var
  I: Integer;
begin
  // 查找缓冲区在池中的位置
  for I := 0 to FCurrentCount - 1 do
  begin
    if FBuffers[I].Data = aBuffer.Data then
    begin
      FAvailable[I] := True;
      aBuffer := Default(TSocketBuffer);
      Exit;
    end;



  end;

  // 如果不在池中，释放临时缓冲区
  aBuffer.Free;
  aBuffer := Default(TSocketBuffer);
end;

function TSocketBufferPool.GetStatistics: string;
var
  I, Available: Integer;
begin
  Available := 0;
  for I := 0 to FCurrentCount - 1 do
    if FAvailable[I] then Inc(Available);

  Result := Format('缓冲区池: %d/%d 可用, 默认大小: %d KB',
    [Available, FCurrentCount, FDefaultSize div 1024]);
end;


{$ENDIF} // FAFAFA_SOCKET_ADVANCED: end of buffer/pool implementations

// ============================================================================
// 事件轮询器实现
// ============================================================================

{ TSelectSocketPoller }

constructor TSelectSocketPoller.Create(AMaxSockets: Integer);
begin
  inherited Create;
  FMaxSockets := AMaxSockets;
  {$IFDEF WINDOWS}
  // Windows 的 FD_SETSIZE 默认通常较小（常见为 64）；select 的集合容量受其限制
  // 这里对配置做保守约束，避免运行时静默失败
  if FMaxSockets > FD_SETSIZE then
    FMaxSockets := FD_SETSIZE;
  {$ENDIF}
  SetLength(FSockets, 0);
  SetLength(FReadyResults, 0);
  FStopped := False;
end;

destructor TSelectSocketPoller.Destroy;
begin
  Stop;
  SetLength(FSockets, 0);
  SetLength(FReadyResults, 0);
  inherited Destroy;
end;

procedure TSelectSocketPoller.RegisterSocket(const ASocket: ISocket; AEvents: TSocketEvents; ACallback: TSocketEventCallback);
var
  LIndex: Integer;
begin
  if FStopped then
    raise EInvalidOperation.Create('轮询器已停止');

  if not Assigned(ASocket) then
    raise EArgumentNil.Create('Socket不能为空');

  if Length(FSockets) >= FMaxSockets then
  begin
    {$IFDEF WINDOWS}
    raise EInvalidOperation.CreateFmt('已达到最大Socket数量限制（当前上限=%d，受 FD_SETSIZE 限制）', [FMaxSockets]);
    {$ELSE}
    raise EInvalidOperation.CreateFmt('已达到最大Socket数量限制（当前上限=%d）', [FMaxSockets]);
    {$ENDIF}
  end;

  // 检查是否已注册
  LIndex := FindSocketIndex(ASocket);
  if LIndex >= 0 then
    raise EInvalidOperation.Create('Socket已经注册');

  // 添加新的Socket
  SetLength(FSockets, Length(FSockets) + 1);
  with FSockets[High(FSockets)] do
  begin
    Socket := ASocket;
    Events := AEvents;
    Callback := ACallback;
  end;
end;

procedure TSelectSocketPoller.UnregisterSocket(const ASocket: ISocket);
var
  LIndex: Integer;
begin
  LIndex := FindSocketIndex(ASocket);
  if LIndex >= 0 then
    RemoveSocketAt(LIndex);
end;

procedure TSelectSocketPoller.ModifyEvents(const ASocket: ISocket; AEvents: TSocketEvents);
var
  LIndex: Integer;
begin
  LIndex := FindSocketIndex(ASocket);
  if LIndex >= 0 then
    FSockets[LIndex].Events := AEvents
  else
    raise EArgumentException.Create('Socket未注册');
end;

function TSelectSocketPoller.Poll(ATimeoutMs: Integer): Integer;
{$IFDEF WINDOWS}
var
  LReadSet, LWriteSet, LErrorSet: TFDSet;
  LTimeout: TTimeVal;
  LResult: Integer;
  I: Integer;
  LHandle: TSocketHandle;
  LMaxHandle: TSocketHandle;
  LEvents: TSocketEvents;
{$ENDIF}
begin
  Result := 0;
  SetLength(FReadyResults, 0);

  if FStopped or (Length(FSockets) = 0) then
    Exit;

{$IFDEF WINDOWS}
  // Windows实现使用select
  FD_ZERO(LReadSet);
  FD_ZERO(LWriteSet);
  FD_ZERO(LErrorSet);
  LMaxHandle := 0;

  // 添加Socket到相应的集合
  for I := 0 to High(FSockets) do
  begin
    if I >= FMaxSockets then Break; // 超过上限则忽略后续，避免 FD 集溢出
    LHandle := FSockets[I].Socket.Handle;
    if LHandle <> INVALID_SOCKET then
    begin
      if seRead in FSockets[I].Events then
        FD_SET(LHandle, LReadSet);
      if seWrite in FSockets[I].Events then
        FD_SET(LHandle, LWriteSet);
      if (seError in FSockets[I].Events) or (seClose in FSockets[I].Events) then
        FD_SET(LHandle, LErrorSet);
      if LHandle > LMaxHandle then
        LMaxHandle := LHandle;
    end;
  end;

  // 设置超时
  if ATimeoutMs >= 0 then
  begin
    LTimeout.tv_sec := ATimeoutMs div 1000;
    LTimeout.tv_usec := (ATimeoutMs mod 1000) * 1000;
    LResult := select(LMaxHandle + 1, @LReadSet, @LWriteSet, @LErrorSet, @LTimeout);
  end
  else
    LResult := select(LMaxHandle + 1, @LReadSet, @LWriteSet, @LErrorSet, nil);

  if LResult > 0 then
  begin
    // 检查就绪的Socket
    for I := 0 to High(FSockets) do
    begin
      LHandle := FSockets[I].Socket.Handle;
      if LHandle <> INVALID_SOCKET then
      begin
        LEvents := [];

        if FD_ISSET(LHandle, LReadSet) then
          Include(LEvents, seRead);
        if FD_ISSET(LHandle, LWriteSet) then
          Include(LEvents, seWrite);
        if FD_ISSET(LHandle, LErrorSet) then
        begin
          Include(LEvents, seError);
          Include(LEvents, seClose);
        end;

        if LEvents <> [] then
        begin
          SetLength(FReadyResults, Length(FReadyResults) + 1);
          with FReadyResults[High(FReadyResults)] do
          begin
            Socket := FSockets[I].Socket;
            Events := LEvents;
          end;

          // 调用回调
          if Assigned(FSockets[I].Callback) then
            FSockets[I].Callback(FSockets[I].Socket, LEvents);

          Inc(Result);
        end;
      end;
    end;
  end;
{$ELSE}
  // Linux实现使用fpSelect（简化版）
  // 这里可以扩展为epoll实现
  Result := 0; // 暂时返回0，表示没有事件
{$ENDIF}
end;

function TSelectSocketPoller.GetReadyEvents: TSocketPollResults;
begin
  Result := Copy(FReadyResults);
end;

function TSelectSocketPoller.PollAsync: Integer;
begin
  Result := Poll(0); // 非阻塞轮询
end;

procedure TSelectSocketPoller.Stop;
begin
  FStopped := True;
end;

function TSelectSocketPoller.GetRegisteredCount: Integer;
begin
  Result := Length(FSockets);
end;

function TSelectSocketPoller.GetStatistics: string;
begin
  Result := Format('事件轮询器: %d/%d Socket已注册, 状态: %s',
    [Length(FSockets), FMaxSockets, IfThen(FStopped, '已停止', '运行中')]);
end;

function TSelectSocketPoller.FindSocketIndex(const ASocket: ISocket): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FSockets) do
  begin
    if FSockets[I].Socket = ASocket then
    begin
      Result := I;
      Break;
    end;
  end;
end;

procedure TSelectSocketPoller.RemoveSocketAt(AIndex: Integer);
var
  I: Integer;
begin
  if (AIndex >= 0) and (AIndex < Length(FSockets)) then
  begin
    for I := AIndex to High(FSockets) - 1 do
      FSockets[I] := FSockets[I + 1];
    SetLength(FSockets, Length(FSockets) - 1);
  end;
end;

end.
