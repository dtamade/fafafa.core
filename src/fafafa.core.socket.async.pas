unit fafafa.core.socket.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

{$IFDEF FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.thread.future,
  fafafa.core.async.runtime;

type
  // 前向声明
  IAsyncSocket = interface;
  IAsyncSocketListener = interface;

  // 异步Socket结果类型
  generic IAsyncResult<T> = interface(IInterface)
    ['{F3E2D1C0-B9A8-7654-3210-FEDCBA987654}']

    // 状态查询
    function IsCompleted: Boolean;
    function IsCancelled: Boolean;
    function HasError: Boolean;

    // 结果获取
    function GetResult: T;
    function GetError: Exception;

    // 回调设置
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnComplete(ACallback: specialize TProc<T>);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}

    // 取消操作
    procedure Cancel;

    // 等待完成
    function WaitFor(ATimeoutMs: Integer = INFINITE): Boolean;
  end;

  // 异步Socket接口
  IAsyncSocket = interface(ISocket)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']

    // 异步连接
    function ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
    function ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Integer): specialize IAsyncResult<Boolean>;

    // 异步数据传输
    function SendAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
    function SendAsync(AData: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
    function ReceiveAsync(AMaxSize: Integer): specialize IAsyncResult<TBytes>;
    function ReceiveAsync(ABuffer: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;

    // 批量异步操作
    function SendAllAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
    function ReceiveExactAsync(ASize: Integer): specialize IAsyncResult<TBytes>;

    // 高性能异步操作
    function SendBufferAsync(const ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
    function ReceiveBufferAsync(var ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
    function SendVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
    function ReceiveVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;

    // 事件轮询器集成
    procedure SetPoller(const APoller: ISocketPoller);
    function GetPoller: ISocketPoller;

    // 异步回调
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnConnected(ACallback: specialize TProc<Boolean>);
    procedure OnDataReceived(ACallback: specialize TProc<TBytes>);
    procedure OnDisconnected(ACallback: TProc);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}
  end;

  // 异步Socket监听器接口
  IAsyncSocketListener = interface(ISocketListener)
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']

    // 异步接受连接
    function AcceptAsync: specialize IAsyncResult<IAsyncSocket>;
    function AcceptAsync(ATimeoutMs: Integer): specialize IAsyncResult<IAsyncSocket>;

    // 批量接受
    function AcceptMultipleAsync(AMaxCount: Integer): specialize IAsyncResult<TArray<IAsyncSocket>>;

    // 事件回调
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnClientConnected(ACallback: specialize TProc<IAsyncSocket>);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}
  end;

  // 异步结果实现
  generic TAsyncResult<T> = class(TInterfacedObject, specialize IAsyncResult<T>)
  private
    FCompleted: Boolean;
    FCancelled: Boolean;
    FHasError: Boolean;
    FResult: T;
    FError: Exception;
    FLock: TRTLCriticalSection;
    FEvent: TRTLEvent;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnComplete: specialize TProc<T>;
    FOnError: specialize TProc<Exception>;
    {$ENDIF}

  public
    constructor Create;
    destructor Destroy; override;

    // IAsyncResult implementation
    function IsCompleted: Boolean;
    function IsCancelled: Boolean;
    function HasError: Boolean;
    function GetResult: T;
    function GetError: Exception;
    procedure Cancel;
    function WaitFor(ATimeoutMs: Integer = INFINITE): Boolean;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnComplete(ACallback: specialize TProc<T>);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}

    // 内部方法
    procedure SetResult(const AResult: T);
    procedure SetError(AError: Exception);
  end;

  // 异步Socket实现
  TAsyncSocket = class(TSocket, IAsyncSocket)
  private
    FPoller: ISocketPoller;
    FRuntime: TAsyncRuntime;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnConnected: specialize TProc<Boolean>;
    FOnDataReceived: specialize TProc<TBytes>;
    FOnDisconnected: TProc;
    FOnError: specialize TProc<Exception>;
    {$ENDIF}

  public
    constructor Create(AFamily: TAddressFamily = afInet; ASocketType: TSocketType = stStream; AProtocol: TProtocol = pDefault);
    destructor Destroy; override;

    // IAsyncSocket implementation
    function ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
    function ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Integer): specialize IAsyncResult<Boolean>;
    function SendAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
    function SendAsync(AData: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
    function ReceiveAsync(AMaxSize: Integer): specialize IAsyncResult<TBytes>;
    function ReceiveAsync(ABuffer: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
    function SendAllAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
    function ReceiveExactAsync(ASize: Integer): specialize IAsyncResult<TBytes>;
    function SendBufferAsync(const ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
    function ReceiveBufferAsync(var ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
    function SendVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
    function ReceiveVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;

    procedure SetPoller(const APoller: ISocketPoller);
    function GetPoller: ISocketPoller;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnConnected(ACallback: specialize TProc<Boolean>);
    procedure OnDataReceived(ACallback: specialize TProc<TBytes>);
    procedure OnDisconnected(ACallback: TProc);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}

    // 便捷创建方法
    class function CreateTCP: IAsyncSocket;
    class function CreateUDP: IAsyncSocket;
  end;

  // 异步Socket监听器实现
  TAsyncSocketListener = class(TSocketListener, IAsyncSocketListener)
  private
    FPoller: ISocketPoller;
    FRuntime: TAsyncRuntime;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnClientConnected: specialize TProc<IAsyncSocket>;
    FOnError: specialize TProc<Exception>;
    {$ENDIF}

  public
    constructor Create(const AAddress: ISocketAddress);
    destructor Destroy; override;

    // IAsyncSocketListener implementation
    function AcceptAsync: specialize IAsyncResult<IAsyncSocket>;
    function AcceptAsync(ATimeoutMs: Integer): specialize IAsyncResult<IAsyncSocket>;
    function AcceptMultipleAsync(AMaxCount: Integer): specialize IAsyncResult<TArray<IAsyncSocket>>;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnClientConnected(ACallback: specialize TProc<IAsyncSocket>);
    procedure OnError(ACallback: specialize TProc<Exception>);
    {$ENDIF}

    // 便捷创建方法
    class function ListenTCP(APort: Word): IAsyncSocketListener;
    class function ListenUDP(APort: Word): IAsyncSocketListener;
  end;

implementation

// ============================================================================
// TAsyncResult<T> 实现
// ============================================================================

{ TAsyncResult<T> }

constructor TAsyncResult.Create;
begin
  inherited Create;
  FCompleted := False;
  FCancelled := False;
  FHasError := False;
  FError := nil;
  InitCriticalSection(FLock);
  FEvent := RTLEventCreate;
end;

destructor TAsyncResult.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
  RTLEventDestroy(FEvent);
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TAsyncResult.IsCompleted: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCompleted;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.HasError: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FHasError;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.GetResult: T;
begin
  EnterCriticalSection(FLock);
  try
    if not FCompleted then
      raise EInvalidOperation.Create('异步操作尚未完成');
    if FHasError then
      raise FError;
    if FCancelled then
      raise EOperationCancelled.Create('异步操作已取消');
    Result := FResult;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.GetError: Exception;
begin
  EnterCriticalSection(FLock);
  try
    Result := FError;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAsyncResult.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    if not FCompleted then
    begin
      FCancelled := True;
      FCompleted := True;
      RTLEventSetEvent(FEvent);
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.WaitFor(ATimeoutMs: Integer): Boolean;
begin
  if IsCompleted then
  begin
    Result := True;
    Exit;
  end;

  if ATimeoutMs = INFINITE then
    Result := RTLEventWaitFor(FEvent) = wrSignaled
  else
    Result := RTLEventWaitFor(FEvent, ATimeoutMs) = wrSignaled;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TAsyncResult.OnComplete(ACallback: specialize TProc<T>);
begin
  EnterCriticalSection(FLock);
  try
    FOnComplete := ACallback;
    if FCompleted and not FHasError and not FCancelled and Assigned(FOnComplete) then
      FOnComplete(FResult);
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAsyncResult.OnError(ACallback: specialize TProc<Exception>);
begin
  EnterCriticalSection(FLock);
  try
    FOnError := ACallback;
    if FCompleted and FHasError and Assigned(FOnError) then
      FOnError(FError);
  finally
    LeaveCriticalSection(FLock);
  end;
end;
{$ENDIF}

procedure TAsyncResult.SetResult(const AResult: T);
begin
  EnterCriticalSection(FLock);
  try
    if not FCompleted and not FCancelled then
    begin
      FResult := AResult;
      FCompleted := True;
      RTLEventSetEvent(FEvent);

      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      if Assigned(FOnComplete) then
        FOnComplete(FResult);
      {$ENDIF}
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAsyncResult.SetError(AError: Exception);
begin
  EnterCriticalSection(FLock);
  try
    if not FCompleted and not FCancelled then
    begin
      FError := AError;
      FHasError := True;
      FCompleted := True;
      RTLEventSetEvent(FEvent);

      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      if Assigned(FOnError) then
        FOnError(FError);
      {$ENDIF}
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

// ============================================================================
// TAsyncSocket 实现
// ============================================================================

{ TAsyncSocket }

constructor TAsyncSocket.Create(AFamily: TAddressFamily; ASocketType: TSocketType; AProtocol: TProtocol);
begin
  inherited Create(AFamily, ASocketType, AProtocol);
  FRuntime := TAsyncRuntime.GetInstance;
  FPoller := TSelectSocketPoller.Create;
end;

destructor TAsyncSocket.Destroy;
begin
  if Assigned(FPoller) then
    FPoller.UnregisterSocket(Self);
  inherited Destroy;
end;

function TAsyncSocket.ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
begin
  Result := ConnectAsync(AAddress, INFINITE);
end;

function TAsyncSocket.ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Integer): specialize IAsyncResult<Boolean>;
var
  LResult: specialize TAsyncResult<Boolean>;
begin
  LResult := specialize TAsyncResult<Boolean>.Create;
  Result := LResult;

  // 在线程池中执行连接操作
  FRuntime.Schedule(procedure
    begin
      try
        // 设置非阻塞模式
        Self.NonBlocking := True;

        // 尝试连接
        var LConnected := Self.Connect(AAddress);

        if LConnected then
        begin
          LResult.SetResult(True);
          {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
          if Assigned(FOnConnected) then
            FOnConnected(True);
          {$ENDIF}
        end
        else
        begin
          // 注册到轮询器等待连接完成
          FPoller.RegisterSocket(Self, [seWrite, seError], procedure(const ASocket: ISocket; AEvents: TSocketEvents)
            begin
              if seWrite in AEvents then
              begin
                LResult.SetResult(True);
                {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
                if Assigned(FOnConnected) then
                  FOnConnected(True);
                {$ENDIF}
              end
              else if seError in AEvents then
              begin
                LResult.SetError(ESocketError.Create('连接失败'));
                {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
                if Assigned(FOnConnected) then
                  FOnConnected(False);
                {$ENDIF}
              end;
              FPoller.UnregisterSocket(Self);
            end);
        end;

      except
        on E: Exception do
        begin
          LResult.SetError(E);
          {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
          if Assigned(FOnError) then
            FOnError(E);
          {$ENDIF}
        end;
      end;
    end);
end;

function TAsyncSocket.SendAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
begin
  Result := SendAsync(@AData[0], Length(AData));
end;

function TAsyncSocket.SendAsync(AData: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesSent := Self.Send(AData, ASize);
        LResult.SetResult(LBytesSent);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.ReceiveAsync(AMaxSize: Integer): specialize IAsyncResult<TBytes>;
var
  LResult: specialize TAsyncResult<TBytes>;
begin
  LResult := specialize TAsyncResult<TBytes>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LData := Self.Receive(AMaxSize);
        LResult.SetResult(LData);

        {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
        if Assigned(FOnDataReceived) then
          FOnDataReceived(LData);
        {$ENDIF}
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.ReceiveAsync(ABuffer: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesReceived := Self.Receive(ABuffer, ASize);
        LResult.SetResult(LBytesReceived);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.SendAllAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        Self.SendAll(AData);
        LResult.SetResult(Length(AData));
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.ReceiveExactAsync(ASize: Integer): specialize IAsyncResult<TBytes>;
var
  LResult: specialize TAsyncResult<TBytes>;
begin
  LResult := specialize TAsyncResult<TBytes>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LData := Self.ReceiveExact(ASize);
        LResult.SetResult(LData);

        {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
        if Assigned(FOnDataReceived) then
          FOnDataReceived(LData);
        {$ENDIF}
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.SendBufferAsync(const ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesSent := Self.SendBuffer(ABuffer);
        LResult.SetResult(LBytesSent);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.ReceiveBufferAsync(var ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesReceived := Self.ReceiveBuffer(ABuffer);
        LResult.SetResult(LBytesReceived);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.SendVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesSent := Self.SendVectorized(AVectors);
        LResult.SetResult(LBytesSent);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

function TAsyncSocket.ReceiveVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  FRuntime.Schedule(procedure
    begin
      try
        var LBytesReceived := Self.ReceiveVectorized(AVectors);
        LResult.SetResult(LBytesReceived);
      except
        on E: Exception do
          LResult.SetError(E);
      end;
    end);
end;

procedure TAsyncSocket.SetPoller(const APoller: ISocketPoller);
begin
  FPoller := APoller;
end;

function TAsyncSocket.GetPoller: ISocketPoller;
begin
  Result := FPoller;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TAsyncSocket.OnConnected(ACallback: specialize TProc<Boolean>);
begin
  FOnConnected := ACallback;
end;

procedure TAsyncSocket.OnDataReceived(ACallback: specialize TProc<TBytes>);
begin
  FOnDataReceived := ACallback;
end;

procedure TAsyncSocket.OnDisconnected(ACallback: TProc);
begin
  FOnDisconnected := ACallback;
end;

procedure TAsyncSocket.OnError(ACallback: specialize TProc<Exception>);
begin
  FOnError := ACallback;
end;
{$ENDIF}

class function TAsyncSocket.CreateTCP: IAsyncSocket;
begin
  Result := TAsyncSocket.Create(afInet, stStream, pTCP);
end;

class function TAsyncSocket.CreateUDP: IAsyncSocket;
begin
  Result := TAsyncSocket.Create(afInet, stDgram, pUDP);
end;

{$ENDIF} // FAFAFA_SOCKET_ASYNC_EXPERIMENTAL


end.
