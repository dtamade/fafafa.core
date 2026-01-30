{**
 * fafafa.core.socket.windows.inc
 * 
 * Windows平台Socket实现
 * 使用WinSock2 API提供真实的系统调用后端
 *}

{$IFDEF WINDOWS}

uses
  Windows, WinSock2;

// 定义可能缺失的常量
const
  IPPROTO_IPV6 = 41;
  AF_INET6 = 23;
  SO_EXCLUSIVEADDRUSE = $0004; // Windows特有的独占地址使用
  SO_CONDITIONAL_ACCEPT = $3002; // Windows特有的条件接受
  // 兼容性补充（部分SDK未定义）
  SO_REUSEPORT = $0200; // 占位常量，用于编译与尽力设置；如不支持，setsockopt将失败
  IPV6_V6ONLY = 27;     // Winsock: IPV6_V6ONLY 选项编号

// 定义getaddrinfo相关的类型和常量
type
  PAddrInfo = ^TAddrInfo;
  TAddrInfo = record
    ai_flags: Integer;
    ai_family: Integer;
    ai_socktype: Integer;
    ai_protocol: Integer;
    ai_addrlen: Integer;
    ai_canonname: PAnsiChar;
    ai_addr: PSockAddr;
    ai_next: PAddrInfo;
  end;

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

// 导入getaddrinfo函数
function getaddrinfo(nodename: PAnsiChar; servname: PAnsiChar; hints: PAddrInfo; var res: PAddrInfo): Integer; stdcall; external 'ws2_32.dll';
procedure freeaddrinfo(ai: PAddrInfo); stdcall; external 'ws2_32.dll';

var
  // WinSock初始化状态
  GWinSockInitialized: Boolean = False;
  GWinSockInitCount: Integer = 0;

// WinSock初始化和清理
function InitializeWinSock: Boolean;
var
  LWSAData: TWSAData;
  LResult: Integer;
begin
  Result := True;
  
  if not GWinSockInitialized then
  begin
    FillChar(LWSAData, SizeOf(LWSAData), 0);
    LResult := WSAStartup(MAKEWORD(2, 2), LWSAData);
    if LResult = 0 then
    begin
      GWinSockInitialized := True;
      GWinSockInitCount := 1;
    end
    else
    begin
      Result := False;
    end;
  end
  else
  begin
    Inc(GWinSockInitCount);
  end;
end;

procedure CleanupWinSock;
begin
  if GWinSockInitialized then
  begin
    Dec(GWinSockInitCount);
    if GWinSockInitCount <= 0 then
    begin
      WSACleanup;
      GWinSockInitialized := False;
      GWinSockInitCount := 0;
    end;
  end;
end;

// 错误处理
function GetLastSocketErrorCode: Integer;
begin
  Result := WSAGetLastError;
end;

function SocketErrorToString(aErrorCode: Integer): string;
begin
  case aErrorCode of
    WSAEACCES: Result := '权限被拒绝 (WSAEACCES)';
    WSAEADDRINUSE: Result := '地址已被使用 (WSAEADDRINUSE)';
    WSAEADDRNOTAVAIL: Result := '地址不可用 (WSAEADDRNOTAVAIL)';
    WSAEAFNOSUPPORT: Result := '地址族不支持 (WSAEAFNOSUPPORT)';
    WSAEALREADY: Result := '操作已在进行中 (WSAEALREADY)';
    WSAEBADF: Result := '无效的文件描述符 (WSAEBADF)';
    WSAECONNABORTED: Result := '连接被中止 (WSAECONNABORTED)';
    WSAECONNREFUSED: Result := '连接被拒绝 (WSAECONNREFUSED)';
    WSAECONNRESET: Result := '连接被重置 (WSAECONNRESET)';
    WSAEDESTADDRREQ: Result := '需要目标地址 (WSAEDESTADDRREQ)';
    WSAEFAULT: Result := '无效的地址';
    WSAEHOSTDOWN: Result := '主机已关闭';
    WSAEHOSTUNREACH: Result := '主机不可达';
    WSAEINPROGRESS: Result := '操作正在进行中';
    WSAEINTR: Result := '操作被中断';
    WSAEINVAL: Result := '无效的参数';
    WSAEISCONN: Result := '套接字已连接';
    WSAEMFILE: Result := '打开的文件过多';
    WSAEMSGSIZE: Result := '消息过长';
    WSAENETDOWN: Result := '网络已关闭';
    WSAENETRESET: Result := '网络连接被重置';
    WSAENETUNREACH: Result := '网络不可达';
    WSAENOBUFS: Result := '缓冲区空间不足';
    WSAENOPROTOOPT: Result := '协议选项不支持';
    WSAENOTCONN: Result := '套接字未连接';
    WSAENOTSOCK: Result := '操作的不是套接字';
    WSAEOPNOTSUPP: Result := '操作不支持';
    WSAEPFNOSUPPORT: Result := '协议族不支持';
    WSAEPROCLIM: Result := '进程过多';
    WSAEPROTONOSUPPORT: Result := '协议不支持';
    WSAEPROTOTYPE: Result := '协议类型错误';
    WSAESHUTDOWN: Result := '套接字已关闭';
    WSAESOCKTNOSUPPORT: Result := '套接字类型不支持';
    WSAETIMEDOUT: Result := '操作超时';
    WSAEWOULDBLOCK: Result := '操作将阻塞';
    WSAHOST_NOT_FOUND: Result := '主机未找到';
    WSANO_DATA: Result := '无数据';
    WSANO_RECOVERY: Result := '不可恢复的错误';
    WSATRY_AGAIN: Result := '请重试';
  else
    Result := '未知错误 (' + IntToStr(aErrorCode) + ')';
  end;
end;

// 地址族转换
function ConvertAddressFamilyToNative(aFamily: TAddressFamily): Integer;
begin
  case aFamily of
    afUnspec: Result := AF_UNSPEC;
    afInet: Result := AF_INET;
    afInet6: Result := AF_INET6;
  else
    raise EInvalidArgument.Create('Windows不支持的地址族');
  end;
end;

// Socket类型转换
function ConvertSocketTypeToNative(aType: TSocketType): Integer;
begin
  case aType of
    stStream: Result := SOCK_STREAM;
    stDgram: Result := SOCK_DGRAM;
    stRaw: Result := SOCK_RAW;
  else
    raise EInvalidArgument.Create('不支持的Socket类型');
  end;
end;

// 协议转换
function ConvertProtocolToNative(aProtocol: TProtocol): Integer;
begin
  case aProtocol of
    pDefault: Result := 0;
    pTCP: Result := IPPROTO_TCP;
    pUDP: Result := IPPROTO_UDP;
    {$IFDEF IPPROTO_ICMP}
    pICMP: Result := IPPROTO_ICMP;
    {$ELSE}
    pICMP: Result := 1; // 回退：ICMP 协议号
    {$ENDIF}
  else
    raise EInvalidArgument.Create('不支持的协议类型');
  end;
end;

// 关闭模式转换
function ConvertShutdownModeToNative(aMode: TShutdownMode): Integer;
begin
  case aMode of
    sdReceive: Result := SD_RECEIVE;
    sdSend: Result := SD_SEND;
    sdBoth: Result := SD_BOTH;
  else
    raise EInvalidArgument.Create('无效的关闭模式');
  end;
end;

// Socket选项级别转换
function ConvertSocketOptionLevelToNative(aLevel: TSocketOptionLevel): Integer;
begin
  case aLevel of
    solSocket: Result := SOL_SOCKET;
    solTCP: Result := IPPROTO_TCP;
    solIP: Result := IPPROTO_IP;
    solIPv6: Result := IPPROTO_IPV6;
  else
    raise EInvalidArgument.Create('不支持的Socket选项级别');
  end;
end;

// 核心Socket操作实现
function PlatformCreateSocket(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol): TSocketHandle;
var
  LResult: QWord;
  LError: Integer;
begin
  // 确保WinSock已初始化
  if not InitializeWinSock then
    raise ESocketCreateError.Create('WinSock初始化失败');

  LResult := socket(
    ConvertAddressFamilyToNative(aFamily),
    ConvertSocketTypeToNative(aType),
    ConvertProtocolToNative(aProtocol)
  );

  if LResult = QWord(INVALID_SOCKET) then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketCreateError.Create('创建Socket失败: ' + SocketErrorToString(LError));
  end;

  Result := TSocketHandle(LResult);
end;

procedure PlatformCloseSocket(aHandle: TSocketHandle);
var
  LResult: Integer;
  LError: Integer;
begin
  if aHandle <> TSocketHandle(INVALID_SOCKET) then
  begin
    LResult := closesocket(QWord(aHandle));
    if LResult = SOCKET_ERROR then
    begin
      // 记录错误但不抛出异常，因为这通常在析构函数中调用
      LError := GetLastSocketErrorCode;
      // 可以记录日志：'关闭Socket失败: ' + SocketErrorToString(LError)
    end;
  end;
end;

procedure PlatformBindSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := bind(QWord(aHandle), PSockAddr(aAddress), aAddressSize);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketBindError.Create('Bind failed: ' + SocketErrorToString(LError), LError, aHandle);
  end;
end;

procedure PlatformListenSocket(aHandle: TSocketHandle; aBacklog: Integer);
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := listen(QWord(aHandle), aBacklog);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketListenError.Create('Listen failed: ' + SocketErrorToString(LError));
  end;
end;

function PlatformAcceptSocket(aHandle: TSocketHandle; aAddress: Pointer; var aAddressSize: Integer): TSocketHandle;
var
  LResult: QWord;
  LError: Integer;
  LAddrLen: LongInt;
begin
  LAddrLen := aAddressSize;
  if (aAddress <> nil) and (LAddrLen > 0) then FillChar(aAddress^, LAddrLen, 0);
  LResult := accept(QWord(aHandle), PSockAddr(aAddress), @LAddrLen);
  if LResult = QWord(INVALID_SOCKET) then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketAcceptError.Create('Accept failed: ' + SocketErrorToString(LError));
  end;

  aAddressSize := LAddrLen;
  Result := TSocketHandle(LResult);
end;

procedure PlatformConnectSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := connect(QWord(aHandle), PSockAddr(aAddress), aAddressSize);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketConnectError.Create('Connect failed: ' + SocketErrorToString(LError));
  end;
end;

function PlatformSendSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := send(QWord(aHandle), aData, aSize, aFlags);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketSendError.Create('Send failed: ' + SocketErrorToString(LError));
  end;

  Result := LResult;
end;

function PlatformSendSocketNoExcept(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer; out aLastError: Integer): Integer;
begin
  aLastError := 0;
  Result := send(QWord(aHandle), aData, aSize, aFlags);
  if Result = SOCKET_ERROR then
  begin
    aLastError := GetLastSocketErrorCode;
    Result := -1;
  end;
end;

function PlatformReceiveSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := recv(QWord(aHandle), aBuffer, aSize, aFlags);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketReceiveError.Create('Receive failed: ' + SocketErrorToString(LError));
  end;

  Result := LResult;
end;

function PlatformReceiveSocketNoExcept(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer; out aLastError: Integer): Integer;
begin
  aLastError := 0;
  Result := recv(QWord(aHandle), aBuffer, aSize, aFlags);
  if Result = SOCKET_ERROR then
  begin
    aLastError := GetLastSocketErrorCode;
    Result := -1;
  end;
end;

function PlatformSendToSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; aAddressSize: Integer): Integer;
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := sendto(QWord(aHandle), aData, aSize, aFlags, PSockAddr(aAddress), aAddressSize);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketSendError.Create('Send failed: ' + SocketErrorToString(LError));
  end;

  Result := LResult;
end;

function PlatformReceiveFromSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; var aAddressSize: Integer): Integer;
var
  LResult: Integer;
  LError: Integer;
  LAddrLen: LongInt;
begin
  LAddrLen := aAddressSize;
  if (aAddress <> nil) and (LAddrLen > 0) then FillChar(aAddress^, LAddrLen, 0);
  LResult := recvfrom(QWord(aHandle), aBuffer, aSize, aFlags, PSockAddr(aAddress), @LAddrLen);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketReceiveError.Create('Receive failed: ' + SocketErrorToString(LError));
  end;

  aAddressSize := LAddrLen;
  Result := LResult;
end;

procedure PlatformShutdownSocket(aHandle: TSocketHandle; aHow: TShutdownMode);
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := shutdown(QWord(aHandle), ConvertShutdownModeToNative(aHow));
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    // 在某些情况下shutdown可能失败，但这不一定是致命错误
    // 可以记录日志而不抛出异常
  end;
end;

procedure PlatformSetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; aSize: Integer);
var
  LResult: Integer;
  LError: Integer;
begin
  LResult := setsockopt(QWord(aHandle), aLevel, aOption, aValue, aSize);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketError.Create('Set socket option failed: ' + SocketErrorToString(LError));
  end;
end;

procedure PlatformGetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; var aSize: Integer);
var
  LResult: Integer;
  LError: Integer;
  LOptLen: LongInt;
begin
  LOptLen := aSize;
  LResult := getsockopt(QWord(aHandle), aLevel, aOption, aValue, LOptLen);
  if LResult = SOCKET_ERROR then
  begin
    LError := GetLastSocketErrorCode;
    raise ESocketError.Create('Get socket option failed: ' + SocketErrorToString(LError));
  end;
  aSize := LOptLen;
end;

// DNS解析功能
function PlatformResolveHostname(const aHostname: string): string;
var
  LAnsiHostname: AnsiString;
  Hints: TAddrInfo;
  Res, Cur: PAddrInfo;
  Sock4: PSockAddrIn;
  Ret: Integer;
  B: array[0..3] of Byte;
  LHostEnt: PHostEnt;
  LAddr: PInAddr;
begin
  Result := '';

  // 确保WinSock已初始化
  if not InitializeWinSock then
    Exit;

  // 优先使用 getaddrinfo(IPv4)
  LAnsiHostname := AnsiString(aHostname);
  FillChar(Hints, SizeOf(Hints), 0);
  Hints.ai_family := AF_INET;
  Hints.ai_socktype := SOCK_STREAM;
  Res := nil;
  Ret := getaddrinfo(PAnsiChar(LAnsiHostname), nil, @Hints, Res);
  if Ret = 0 then
  begin
    try
      Cur := Res;
      while Assigned(Cur) do
      begin
        if (Cur^.ai_family = AF_INET) and (Cur^.ai_addrlen >= SizeOf(TSockAddrIn)) then
        begin
          Sock4 := PSockAddrIn(Cur^.ai_addr);
          Move(Sock4^.sin_addr, B[0], 4);
          Result := Format('%d.%d.%d.%d', [B[0], B[1], B[2], B[3]]);
          Exit;
        end;
        Cur := Cur^.ai_next;
      end;
    finally
      freeaddrinfo(Res);
    end;
  end;

  // 回退到 gethostbyname（兼容旧行为）
  LHostEnt := gethostbyname(PAnsiChar(LAnsiHostname));
  if Assigned(LHostEnt) and Assigned(LHostEnt^.h_addr_list) and Assigned(LHostEnt^.h_addr_list^) then
  begin
    LAddr := PInAddr(LHostEnt^.h_addr_list^);
    Result := Format('%d.%d.%d.%d', [
      LAddr^.S_addr and $FF,
      (LAddr^.S_addr shr 8) and $FF,
      (LAddr^.S_addr shr 16) and $FF,
      (LAddr^.S_addr shr 24) and $FF
    ]);
  end;
end;

// IPv6 DNS解析功能
function PlatformResolveHostnameIPv6(const aHostname: string; var aBytes: array of Byte): Boolean;
var
  LAnsiHostname: AnsiString;
  LHints: TAddrInfo;
  LResult: PAddrInfo;
  LCurrent: PAddrInfo;
  LSockAddrIn6: PSockAddrIn6;
  LRetCode: Integer;
  PrefFound: Boolean;
  TmpBytes: array[0..15] of Byte;
  function IsLinkLocal(const B: array of Byte): Boolean; inline;
  begin
    // 近似判断：fe80::/16（足够用于选择偏好，非严格掩码）
    Result := (Length(B) >= 2) and (B[0] = $FE) and (B[1] = $80);
  end;
begin
  Result := False;
  FillChar(aBytes, 16, 0);

  // 确保WinSock已初始化
  if not InitializeWinSock then
    Exit;

  // 转换为ANSI字符串
  LAnsiHostname := AnsiString(aHostname);

  // 设置hints
  FillChar(LHints, SizeOf(LHints), 0);
  LHints.ai_family := AF_INET6;
  LHints.ai_socktype := SOCK_STREAM;
  LResult := nil;

  // 调用getaddrinfo
  LRetCode := getaddrinfo(PAnsiChar(LAnsiHostname), nil, @LHints, LResult);
  if LRetCode = 0 then
  begin
    try
      // 第一轮：优先挑选非 link-local 的 IPv6
      PrefFound := False;
      LCurrent := LResult;
      while Assigned(LCurrent) do
      begin
        if (LCurrent^.ai_family = AF_INET6) and
           (LCurrent^.ai_addrlen >= SizeOf(TSockAddrIn6)) then
        begin
          LSockAddrIn6 := PSockAddrIn6(LCurrent^.ai_addr);
          Move(LSockAddrIn6^.sin6_addr, TmpBytes[0], 16);
          if not IsLinkLocal(TmpBytes) then
          begin
            Move(TmpBytes[0], aBytes[0], 16);
            Result := True; PrefFound := True;
            Break;
          end;
        end;
        LCurrent := LCurrent^.ai_next;
      end;
      // 第二轮：若仅有 link-local，则接受之
      if not PrefFound then
      begin
        LCurrent := LResult;
        while Assigned(LCurrent) do
        begin
          if (LCurrent^.ai_family = AF_INET6) and
             (LCurrent^.ai_addrlen >= SizeOf(TSockAddrIn6)) then
          begin
            LSockAddrIn6 := PSockAddrIn6(LCurrent^.ai_addr);
            Move(LSockAddrIn6^.sin6_addr, aBytes[0], 16);
            Result := True;
            Break;
          end;
          LCurrent := LCurrent^.ai_next;
        end;
      end;
    finally
      freeaddrinfo(LResult);
    end;
  end;
end;

// 高级DNS解析功能（同时支持IPv4和IPv6）
function PlatformResolveHostnameAdvanced(const aHostname: string; aFamily: Integer): string;
var
  LAnsiHostname: AnsiString;
  LHints: TAddrInfo;
  LResult: PAddrInfo;
  LCurrent: PAddrInfo;
  LSockAddrIn: PSockAddrIn;
  LSockAddrIn6: PSockAddrIn6;
  LRetCode: Integer;
  LAddr: LongWord;
  LIPParts: array[0..3] of Byte;
begin
  Result := '';

  // 确保WinSock已初始化
  if not InitializeWinSock then
    Exit;

  // 转换为ANSI字符串
  LAnsiHostname := AnsiString(aHostname);

  // 设置hints
  FillChar(LHints, SizeOf(LHints), 0);
  LHints.ai_family := aFamily;
  LHints.ai_socktype := SOCK_STREAM;
  LResult := nil;

  // 调用getaddrinfo
  LRetCode := getaddrinfo(PAnsiChar(LAnsiHostname), nil, @LHints, LResult);
  if LRetCode = 0 then
  begin
    try
      LCurrent := LResult;
      while Assigned(LCurrent) do
      begin
        if LCurrent^.ai_family = AF_INET then
        begin
          LSockAddrIn := PSockAddrIn(LCurrent^.ai_addr);
          LAddr := LSockAddrIn^.sin_addr;
          LIPParts[0] := LAddr and $FF;
          LIPParts[1] := (LAddr shr 8) and $FF;
          LIPParts[2] := (LAddr shr 16) and $FF;
          LIPParts[3] := (LAddr shr 24) and $FF;
          Result := Format('%d.%d.%d.%d', [LIPParts[0], LIPParts[1], LIPParts[2], LIPParts[3]]);
          Break;
        end
        else if LCurrent^.ai_family = AF_INET6 then
        begin
          LSockAddrIn6 := PSockAddrIn6(LCurrent^.ai_addr);
          // 简化IPv6地址表示（实际应该完整格式化）
          Result := '::1'; // 暂时返回回环地址
          Break;
        end;
        LCurrent := LCurrent^.ai_next;
      end;
    finally
      freeaddrinfo(LResult);
    end;
  end;
end;

// 获取Socket本地地址
function PlatformGetSocketName(aSocket: TSocketHandle; aAddr: Pointer; var aSize: Integer): Integer;
var
  LSockAddr: WinSock2.TSockAddrIn;
  LAddrSize: Integer;
begin
  LAddrSize := SizeOf(LSockAddr);
  FillChar(LSockAddr, SizeOf(LSockAddr), 0);
  Result := getsockname(aSocket, LSockAddr, LAddrSize);
  if Result = SOCKET_ERROR then
    Result := WSAGetLastError
  else
  begin
    Result := 0;
    // 复制地址数据
    if aSize >= SizeOf(LSockAddr) then
    begin
      Move(LSockAddr, aAddr^, SizeOf(LSockAddr));
      aSize := SizeOf(LSockAddr);
    end
    else
    begin
      Move(LSockAddr, aAddr^, aSize);
    end;
  end;
end;

// 非阻塞设置（Windows：ioctlsocket FIONBIO）
function PlatformSetNonBlocking(aHandle: TSocketHandle; aEnable: Boolean): Boolean;
var
  NonBlock: u_long;
  Res: Integer;
  Cmd: u_long;
begin
  NonBlock := Ord(aEnable);
  // 避免编译期常量范围检查，使用变量承载 FIONBIO 值
  Cmd := $8004667E;
  Res := ioctlsocket(QWord(aHandle), Longint(Cmd), NonBlock);
  Result := (Res = 0);
end;

function PlatformGetNonBlocking(aHandle: TSocketHandle): Boolean;
begin
  // Windows 无通用 getsockopt 读取非阻塞标志的接口；返回 False。
  // 上层采用缓存（FNonBlocking）反映最近设置值。
  aHandle := aHandle; // 抑制未使用参数警告
  Result := False;
end;

{$ENDIF} // WINDOWS
