{**
 * fafafa.core.socket.linux.inc
 *
 * Linux平台Socket实现
 * 提供标准libc和直接syscall两种实现方式
 *}

{$IFDEF UNIX}

type
  PPAddrInfo = ^PAddrInfo;
  PAddrInfo = ^TAddrInfo;
  TAddrInfo = record
    ai_flags: cint;
    ai_family: cint;
    ai_socktype: cint;
    ai_protocol: cint;
    ai_addrlen: cint;
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

function getaddrinfo(nodename: PAnsiChar; servname: PAnsiChar; hints: PAddrInfo; res: PPAddrInfo): cint; cdecl; external 'c' name 'getaddrinfo';
procedure freeaddrinfo(ai: PAddrInfo); cdecl; external 'c' name 'freeaddrinfo';

// 编译选项：选择实现方式
{$DEFINE USE_LIBC_SOCKET} // 使用标准libc方式
// {$DEFINE USE_DIRECT_SYSCALL} // 使用直接syscall方式

{$IFDEF USE_DIRECT_SYSCALL}
// 直接系统调用常量定义

// 一些平台常量兜底定义（通常 glibc/Sockets 单元已定义，这里仅确保编译通过）
{$IFNDEF SO_REUSEPORT}
const SO_REUSEPORT = 15;
{$ENDIF}
{$IFNDEF IPV6_V6ONLY}
const IPV6_V6ONLY = 26;
{$ENDIF}

const
  SYS_socket = 41;
  SYS_bind = 49;
  SYS_listen = 50;
  SYS_accept = 43;
  SYS_connect = 42;
  SYS_sendto = 44;
  SYS_recvfrom = 45;
  SYS_shutdown = 48;
  SYS_setsockopt = 54;
  SYS_getsockopt = 55;
  SYS_close = 3;
{$ENDIF}

// 错误处理
function GetLastSocketErrorCode: Integer;
begin
  Result := fpgeterrno;
end;

function SocketErrorToString(aErrorCode: Integer): string;
begin
  case aErrorCode of
    ESysEACCES: Result := '权限被拒绝';
    ESysEADDRINUSE: Result := '地址已被使用';
    ESysEADDRNOTAVAIL: Result := '地址不可用';
    ESysEAFNOSUPPORT: Result := '地址族不支持';
    ESysEALREADY: Result := '操作已在进行中';
    ESysEBADF: Result := '无效的文件描述符';
    ESysECONNABORTED: Result := '连接被中止';
    ESysECONNREFUSED: Result := '连接被拒绝';
    ESysECONNRESET: Result := '连接被重置';
    ESysEDESTADDRREQ: Result := '需要目标地址';
    ESysEFAULT: Result := '无效的地址';
    ESysEHOSTDOWN: Result := '主机已关闭';
    ESysEHOSTUNREACH: Result := '主机不可达';
    ESysEINPROGRESS: Result := '操作正在进行中';
    ESysEINTR: Result := '操作被中断';
    ESysEINVAL: Result := '无效的参数';
    ESysEISCONN: Result := '套接字已连接';
    ESysEMFILE: Result := '打开的文件过多';
    ESysEMSGSIZE: Result := '消息过长';
    ESysENETDOWN: Result := '网络已关闭';
    ESysENETRESET: Result := '网络连接被重置';
    ESysENETUNREACH: Result := '网络不可达';
    ESysENOBUFS: Result := '缓冲区空间不足';
    ESysENOPROTOOPT: Result := '协议选项不支持';
    ESysENOTCONN: Result := '套接字未连接';
    ESysENOTSOCK: Result := '操作的不是套接字';
    ESysEOPNOTSUPP: Result := '操作不支持';
    ESysEPFNOSUPPORT: Result := '协议族不支持';
{$if declared(ESysEPROCLIM)}
    ESysEPROCLIM: Result := '进程过多';
    {$endif}
    ESysEPROTONOSUPPORT: Result := '协议不支持';
    ESysEPROTOTYPE: Result := '协议类型错误';
    ESysESHUTDOWN: Result := '套接字已关闭';
    ESysESOCKTNOSUPPORT: Result := '套接字类型不支持';
    ESysETIMEDOUT: Result := '操作超时';
    ESysEWOULDBLOCK: Result := '操作将阻塞';
  else
    Result := '未知错误 (' + IntToStr(aErrorCode) + ')';
  end;
end;

// 简单 IPv4 解析（用于主机名解析回退）
function PlatformResolveHostname(const aHostname: string): string;
var
  Hints: TAddrInfo;
  Res, Cur: PAddrInfo;
  Sock4: PSockAddrIn;
  AnsiHost: AnsiString;
  Ret: cint;
  B: array[0..3] of Byte;
begin
  Result := '';
  FillChar(Hints, SizeOf(Hints), 0);
  Hints.ai_family := AF_INET;
  Hints.ai_socktype := SOCK_STREAM;
  Res := nil;
  AnsiHost := AnsiString(aHostname);
  Ret := getaddrinfo(PAnsiChar(AnsiHost), nil, @Hints, @Res);
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
end;

// 地址族转换
function ConvertAddressFamilyToNative(aFamily: TAddressFamily): Integer;
begin
  case aFamily of
    afUnspec: Result := AF_UNSPEC;
    afInet: Result := AF_INET;
    afInet6: Result := AF_INET6;
    afUnix: Result := AF_UNIX;
  else
    raise EInvalidArgument.Create('不支持的地址族');
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
    pICMP: Result := IPPROTO_ICMP;
  else
    raise EInvalidArgument.Create('不支持的协议类型');
  end;
end;

// 关闭模式转换
function ConvertShutdownModeToNative(aMode: TShutdownMode): Integer;
begin
  case aMode of
    sdReceive: Result := SHUT_RD;
    sdSend: Result := SHUT_WR;
    sdBoth: Result := SHUT_RDWR;
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

{$IFDEF USE_LIBC_SOCKET}
// 标准libc实现

function PlatformCreateSocket(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol): TSocketHandle;
var
  LResult: Integer;
begin
  LResult := fpSocket(
    ConvertAddressFamilyToNative(aFamily),
    ConvertSocketTypeToNative(aType),
    ConvertProtocolToNative(aProtocol)
  );

  if LResult = -1 then
  begin
        raise ESocketCreateError.Create('Create socket failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := TSocketHandle(LResult);
end;

procedure PlatformCloseSocket(aHandle: TSocketHandle);
var
  LResult: Integer;
begin
  if aHandle <> TSocketHandle(-1) then
  begin
    LResult := fpClose(Integer(aHandle));
    if LResult = -1 then
    begin
      // 记录错误但不抛出异常，因为这通常在析构函数中调用
            // 可以记录日志：'关闭Socket失败: ' + SocketErrorToString(GetLastSocketErrorCode)
    end;
  end;
end;

procedure PlatformBindSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
begin
  LResult := fpBind(Integer(aHandle), aAddress, aAddressSize);
  if LResult = -1 then
  begin
        raise ESocketBindError.Create('Bind failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

procedure PlatformListenSocket(aHandle: TSocketHandle; aBacklog: Integer);
var
  LResult: Integer;
begin
  LResult := fpListen(Integer(aHandle), aBacklog);
  if LResult = -1 then
  begin
        raise ESocketListenError.Create('Listen failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

function PlatformAcceptSocket(aHandle: TSocketHandle; aAddress: Pointer; var aAddressSize: Integer): TSocketHandle;
var
  LResult: Integer;
  LAddrLen: TSockLen;
begin
  LAddrLen := aAddressSize;
  LResult := fpAccept(Integer(aHandle), aAddress, @LAddrLen);
  if LResult = -1 then
  begin
        raise ESocketAcceptError.Create('Accept failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  aAddressSize := LAddrLen;
  Result := TSocketHandle(LResult);
end;

procedure PlatformConnectSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
begin
  LResult := fpConnect(Integer(aHandle), aAddress, aAddressSize);
  if LResult = -1 then
  begin
        raise ESocketConnectError.Create('Connect failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

function PlatformSendSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: TSsize;
  LFlags: Integer;
  {$IFDEF DARWIN}
  Val: cint;
  {$ENDIF}
begin
  LFlags := aFlags;
  {$IFDEF LINUX}
  LFlags := LFlags or $4000; // MSG_NOSIGNAL
  {$ENDIF}
  {$IFDEF DARWIN}
  // macOS 不支持 MSG_NOSIGNAL，改用套接字级 SO_NOSIGPIPE
  Val := 1;
  fpSetSockOpt(Integer(aHandle), SOL_SOCKET, SO_NOSIGPIPE, @Val, SizeOf(Val));
  {$ENDIF}
  LResult := fpSend(Integer(aHandle), aData, aSize, LFlags);
  if LResult = -1 then
  begin
        raise ESocketSendError.Create('Send failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
  Result := Integer(LResult);
end;

function PlatformReceiveSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: TSsize;
begin
  LResult := fpRecv(Integer(aHandle), aBuffer, aSize, aFlags);
  if LResult = -1 then
  begin
        raise ESocketReceiveError.Create('Receive failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
  Result := Integer(LResult);
end;

function PlatformSendToSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; aAddressSize: Integer): Integer;
var
  LResult: TSsize;
  LFlags: Integer;
  {$IFDEF DARWIN}
  Val: cint;
  {$ENDIF}
begin
  LFlags := aFlags;
  {$IFDEF LINUX}
  LFlags := LFlags or $4000; // MSG_NOSIGNAL
  {$ENDIF}
  {$IFDEF DARWIN}
  Val := 1; fpSetSockOpt(Integer(aHandle), SOL_SOCKET, SO_NOSIGPIPE, @Val, SizeOf(Val));
  {$ENDIF}
  LResult := fpSendTo(Integer(aHandle), aData, aSize, LFlags, aAddress, aAddressSize);
  if LResult = -1 then
  begin
        raise ESocketSendError.Create('Send failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := Integer(LResult);
end;

function PlatformReceiveFromSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; var aAddressSize: Integer): Integer;
var
  LResult: TSsize;
  LAddrLen: TSockLen;
begin
  LAddrLen := aAddressSize;
  LResult := fpRecvFrom(Integer(aHandle), aBuffer, aSize, aFlags, aAddress, @LAddrLen);
  if LResult = -1 then
  begin
        raise ESocketReceiveError.Create('Receive failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  aAddressSize := LAddrLen;
  Result := Integer(LResult);
end;

procedure PlatformShutdownSocket(aHandle: TSocketHandle; aHow: TShutdownMode);
var
  LResult: Integer;
begin
  LResult := fpShutdown(Integer(aHandle), ConvertShutdownModeToNative(aHow));
  if LResult = -1 then
  begin
    // 在某些情况下shutdown可能失败，但这不一定是致命错误
    // 可以记录日志而不抛出异常
  end;
end;

function PlatformSendSocketNoExcept(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer; out aLastError: Integer): Integer;
var
  LResult: TSsize;
  LFlags: Integer;
begin
  aLastError := 0;
  LFlags := aFlags;
  {$IFDEF LINUX}
  LFlags := LFlags or $4000; // MSG_NOSIGNAL
  {$ENDIF}
  LResult := fpSend(Integer(aHandle), aData, aSize, LFlags);
  if LResult = -1 then
  begin
    aLastError := GetLastSocketErrorCode;
    Exit(-1);
  end;
  Result := Integer(LResult);
end;

function PlatformReceiveSocketNoExcept(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer; out aLastError: Integer): Integer;
var
  LResult: TSsize;
begin
  aLastError := 0;
  LResult := fpRecv(Integer(aHandle), aBuffer, aSize, aFlags);
  if LResult = -1 then
  begin
    aLastError := GetLastSocketErrorCode;
    Exit(-1);
  end;
  Result := Integer(LResult);
end;

procedure PlatformSetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; aSize: Integer);
var
  LResult: Integer;
begin
  LResult := fpSetSockOpt(Integer(aHandle), aLevel, aOption, aValue, aSize);
  if LResult = -1 then
  begin
        raise ESocketError.Create('Set socket option failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

procedure PlatformGetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; var aSize: Integer);
var
  LResult: Integer;
  LOptLen: TSockLen;
begin
  LOptLen := aSize;
  LResult := fpGetSockOpt(Integer(aHandle), aLevel, aOption, aValue, @LOptLen);
  if LResult = -1 then
  begin
        raise ESocketError.Create('Get socket option failed: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
  aSize := LOptLen;
end;

// 获取Socket本地地址（供 GetLocalAddress 使用）
function PlatformGetSocketName(aSocket: TSocketHandle; aAddr: Pointer; var aSize: Integer): Integer;
var
  LAddrLen: TSockLen;
begin
  LAddrLen := aSize;
  Result := fpGetSockName(Integer(aSocket), aAddr, @LAddrLen);
  if Result = 0 then
  begin
    aSize := LAddrLen;
  end
  else
  begin
    // 返回错误码（调用方可据此获取并转为异常信息）
    Result := GetLastSocketErrorCode;
  end;
end;

{$ENDIF} // USE_LIBC_SOCKET

{$IFDEF USE_DIRECT_SYSCALL}
// 直接系统调用实现

function PlatformCreateSocket(aFamily: TAddressFamily; aType: TSocketType; aProtocol: TProtocol): TSocketHandle;
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_socket,
    TSysParam(ConvertAddressFamilyToNative(aFamily)),
    TSysParam(ConvertSocketTypeToNative(aType)),
    TSysParam(ConvertProtocolToNative(aProtocol)));

  if LResult = -1 then
  begin
        raise ESocketCreateError.Create('创建Socket失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := TSocketHandle(LResult);
end;

procedure PlatformCloseSocket(aHandle: TSocketHandle);
var
  LResult: Integer;
begin
  if aHandle <> TSocketHandle(-1) then
  begin
    LResult := Do_SysCall(SYS_close, TSysParam(aHandle));
    if LResult = -1 then
    begin
      // 记录错误但不抛出异常
          end;
  end;
end;

procedure PlatformBindSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_bind,
    TSysParam(aHandle),
    TSysParam(aAddress),
    TSysParam(aAddressSize));
  if LResult = -1 then
  begin
        raise ESocketBindError.Create('绑定Socket失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

procedure PlatformListenSocket(aHandle: TSocketHandle; aBacklog: Integer);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_listen, TSysParam(aHandle), TSysParam(aBacklog));
  if LResult = -1 then
  begin
        raise ESocketListenError.Create('监听Socket失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

function PlatformAcceptSocket(aHandle: TSocketHandle; aAddress: Pointer; var aAddressSize: Integer): TSocketHandle;
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_accept,
    TSysParam(aHandle),
    TSysParam(aAddress),
    TSysParam(@aAddressSize));
  if LResult = -1 then
  begin
        raise ESocketAcceptError.Create('接受连接失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := TSocketHandle(LResult);
end;

procedure PlatformConnectSocket(aHandle: TSocketHandle; aAddress: Pointer; aAddressSize: Integer);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_connect,
    TSysParam(aHandle),
    TSysParam(aAddress),
    TSysParam(aAddressSize));
  if LResult = -1 then
  begin
        raise ESocketConnectError.Create('连接Socket失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

function PlatformSendSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: Integer;
  LFlags: Integer;
  {$IFDEF DARWIN}
  Val: cint;
  {$ENDIF}
begin
  LFlags := aFlags;
  {$IFDEF LINUX}
  LFlags := LFlags or $4000; // MSG_NOSIGNAL
  {$ENDIF}
  {$IFDEF DARWIN}
  Val := 1; fpSetSockOpt(Integer(aHandle), SOL_SOCKET, SO_NOSIGPIPE, @Val, SizeOf(Val));
  {$ENDIF}
  LResult := Do_SysCall(SYS_sendto,
    TSysParam(aHandle),
    TSysParam(aData),
    TSysParam(aSize),
    TSysParam(LFlags),
    TSysParam(nil),
    TSysParam(0));
  if LResult = -1 then
  begin
        raise ESocketSendError.Create('发送数据失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := LResult;
end;

function PlatformReceiveSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer): Integer;
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_recvfrom,
    TSysParam(aHandle),
    TSysParam(aBuffer),
    TSysParam(aSize),
    TSysParam(aFlags),
    TSysParam(nil),
    TSysParam(nil));
  if LResult = -1 then
  begin
        raise ESocketReceiveError.Create('接收数据失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := LResult;
end;

function PlatformSendToSocket(aHandle: TSocketHandle; aData: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; aAddressSize: Integer): Integer;
var
  LResult: Integer;
  LFlags: Integer;
  {$IFDEF DARWIN}
  Val: cint;
  {$ENDIF}
begin
  LFlags := aFlags;
  {$IFDEF LINUX}
  LFlags := LFlags or $4000; // MSG_NOSIGNAL
  {$ENDIF}
  {$IFDEF DARWIN}
  Val := 1; fpSetSockOpt(Integer(aHandle), SOL_SOCKET, SO_NOSIGPIPE, @Val, SizeOf(Val));
  {$ENDIF}
  LResult := Do_SysCall(SYS_sendto,
    TSysParam(aHandle),
    TSysParam(aData),
    TSysParam(aSize),
    TSysParam(LFlags),
    TSysParam(aAddress),
    TSysParam(aAddressSize));
  if LResult = -1 then
  begin
        raise ESocketSendError.Create('发送数据失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := LResult;
end;

function PlatformReceiveFromSocket(aHandle: TSocketHandle; aBuffer: Pointer; aSize: Integer; aFlags: Integer; aAddress: Pointer; var aAddressSize: Integer): Integer;
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_recvfrom,
    TSysParam(aHandle),
    TSysParam(aBuffer),
    TSysParam(aSize),
    TSysParam(aFlags),
    TSysParam(aAddress),
    TSysParam(@aAddressSize));
  if LResult = -1 then
  begin
        raise ESocketReceiveError.Create('接收数据失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;

  Result := LResult;
end;

procedure PlatformShutdownSocket(aHandle: TSocketHandle; aHow: TShutdownMode);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_shutdown, TSysParam(aHandle), TSysParam(ConvertShutdownModeToNative(aHow)));
  if LResult = -1 then
  begin
        // 在某些情况下shutdown可能失败，但这不一定是致命错误
  end;
end;

procedure PlatformSetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; aSize: Integer);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_setsockopt,
    TSysParam(aHandle),
    TSysParam(aLevel),
    TSysParam(aOption),
    TSysParam(aValue),
    TSysParam(aSize));
  if LResult = -1 then
  begin
        raise ESocketError.Create('设置Socket选项失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

procedure PlatformGetSocketOption(aHandle: TSocketHandle; aLevel: Integer; aOption: Integer; aValue: Pointer; var aSize: Integer);
var
  LResult: Integer;
begin
  LResult := Do_SysCall(SYS_getsockopt,
    TSysParam(aHandle),
    TSysParam(aLevel),
    TSysParam(aOption),
    TSysParam(aValue),
    TSysParam(@aSize));
  if LResult = -1 then
  begin
        raise ESocketError.Create('获取Socket选项失败: ' + SocketErrorToString(GetLastSocketErrorCode));
  end;
end;

{$ENDIF} // USE_DIRECT_SYSCALL

// IPv6 DNS解析：使用 getaddrinfo
function PlatformResolveHostnameIPv6(const aHostname: string; var aBytes: array of Byte): Boolean;
var
  LHints: TAddrInfo;
  LRes, LCur: PAddrInfo;
  LSock6: PSockAddrIn6;
  LAnsi: AnsiString;
  LRet: cint;
  PrefFound: Boolean;
  Tmp: array[0..15] of Byte;
  function IsLinkLocal(const B: array of Byte): Boolean; inline;
  begin
    // 近似判断 fe80::/16（用于优先级选择，非严格掩码）
    Result := (Length(B) >= 2) and (B[0] = $FE) and (B[1] = $80);
  end;
begin
  Result := False;
  FillChar(aBytes[0], Length(aBytes), 0);
  FillChar(LHints, SizeOf(LHints), 0);
  LHints.ai_family := AF_INET6;
  LHints.ai_socktype := SOCK_STREAM;
  LRes := nil;
  LAnsi := AnsiString(aHostname);
  LRet := getaddrinfo(PAnsiChar(LAnsi), nil, @LHints, @LRes);
  if LRet = 0 then
  begin
    try
      // 第一轮：优先非 link-local
      PrefFound := False;
      LCur := LRes;
      while Assigned(LCur) do
      begin
        if (LCur^.ai_family = AF_INET6) and (LCur^.ai_addrlen >= SizeOf(TSockAddrIn6)) then
        begin
          LSock6 := PSockAddrIn6(LCur^.ai_addr);
          Move(LSock6^.sin6_addr, Tmp[0], 16);
          if not IsLinkLocal(Tmp) then
          begin
            Move(Tmp[0], aBytes[0], 16);
            Result := True; PrefFound := True;
            Break;
          end;
        end;
        LCur := LCur^.ai_next;
      end;
      if not PrefFound then
      begin
        // 第二轮：接受 link-local
        LCur := LRes;
        while Assigned(LCur) do
        begin
          if (LCur^.ai_family = AF_INET6) and (LCur^.ai_addrlen >= SizeOf(TSockAddrIn6)) then
          begin
            LSock6 := PSockAddrIn6(LCur^.ai_addr);
            Move(LSock6^.sin6_addr, aBytes[0], 16);
            Exit(True);
          end;
          LCur := LCur^.ai_next;
        end;
      end;
    finally
      freeaddrinfo(LRes);
    end;
  end;
end;

// 非阻塞设置（Unix：fcntl O_NONBLOCK）
function PlatformSetNonBlocking(aHandle: TSocketHandle; aEnable: Boolean): Boolean;
var
  Flags: cint;
begin
  Flags := fpFcntl(Integer(aHandle), F_GETFL, 0);
  if Flags = -1 then Exit(False);
  if aEnable then
    Flags := Flags or O_NONBLOCK
  else
    Flags := Flags and not O_NONBLOCK;
  Result := fpFcntl(Integer(aHandle), F_SETFL, Flags) = 0;
end;

function PlatformGetNonBlocking(aHandle: TSocketHandle): Boolean;
var
  Flags: cint;
begin
  Flags := fpFcntl(Integer(aHandle), F_GETFL, 0);
  if Flags = -1 then Exit(False);
  Result := (Flags and O_NONBLOCK) <> 0;
end;

{$ENDIF} // UNIX
