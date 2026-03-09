unit fafafa.core.socket.async;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFNDEF FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}{$DEFINE FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}{$ENDIF}

interface

{$IFDEF FAFAFA_SOCKET_ASYNC_EXPERIMENTAL}

uses
  SysUtils,
  Classes,
  fafafa.core.base,
  fafafa.core.socket,
  fafafa.core.async.runtime;

type
  IAsyncSocket = interface;
  IAsyncSocketListener = interface;
  TAsyncSocketArray = array of IAsyncSocket;

{$IFNDEF FAFAFA_SOCKET_ADVANCED}
type
  TSocketBuffer = record
  public
    Data: Pointer;
    FSize: Integer;
    Capacity: Integer;

    class function Create(aCapacity: Integer): TSocketBuffer; static;
    procedure Free;
    procedure Resize(aNewSize: Integer);

    property Size: Integer read FSize write FSize;
  end;

  TIOVector = record
    Data: Pointer;
    Size: Integer;
  end;

  TIOVectorArray = array of TIOVector;
{$ENDIF}

  generic IAsyncResult<T> = interface(IInterface)
    ['{F3E2D1C0-B9A8-7654-3210-FEDCBA987654}']
    function IsCompleted: Boolean;
    function IsCancelled: Boolean;
    function HasError: Boolean;

    function GetResult: T;
    function GetError: Exception;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnComplete(ACallback: specialize TRefAction<T>);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}

    procedure Cancel;
    function WaitFor(ATimeoutMs: Cardinal = INFINITE): Boolean;
  end;

  IAsyncSocket = interface(ISocket)
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
    function ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Cardinal): specialize IAsyncResult<Boolean>;

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
    procedure OnConnected(ACallback: specialize TRefAction<Boolean>);
    procedure OnDataReceived(ACallback: specialize TRefAction<TBytes>);
    procedure OnDisconnected(ACallback: TRefProc);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}
  end;

  IAsyncSocketListener = interface(ISocketListener)
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function AcceptAsync: specialize IAsyncResult<IAsyncSocket>;
    function AcceptAsync(ATimeoutMs: Cardinal): specialize IAsyncResult<IAsyncSocket>;
    function AcceptMultipleAsync(AMaxCount: Integer): specialize IAsyncResult<TAsyncSocketArray>;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnClientConnected(ACallback: specialize TRefAction<IAsyncSocket>);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}
  end;

  generic TAsyncResult<T> = class(TInterfacedObject, specialize IAsyncResult<T>)
  private
    FCompleted: Boolean;
    FCancelled: Boolean;
    FHasError: Boolean;
    FResult: T;
    FError: Exception;
    FLock: TRTLCriticalSection;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnComplete: specialize TRefAction<T>;
    FOnError: specialize TRefAction<Exception>;
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;

    function IsCompleted: Boolean;
    function IsCancelled: Boolean;
    function HasError: Boolean;
    function GetResult: T;
    function GetError: Exception;
    procedure Cancel;
    function WaitFor(ATimeoutMs: Cardinal = INFINITE): Boolean;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnComplete(ACallback: specialize TRefAction<T>);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}

    procedure SetResult(const AResult: T);
    procedure SetError(AError: Exception);
  end;

  TAsyncSocket = class(TSocket, IAsyncSocket)
  private
    FPoller: ISocketPoller;
    FRuntime: TAsyncRuntime;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnConnected: specialize TRefAction<Boolean>;
    FOnDataReceived: specialize TRefAction<TBytes>;
    FOnDisconnected: TRefProc;
    FOnError: specialize TRefAction<Exception>;
    {$ENDIF}
  public
    constructor Create(AFamily: TAddressFamily = afInet; ASocketType: TSocketType = stStream; AProtocol: TProtocol = pDefault);
    destructor Destroy; override;

    function ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
    function ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Cardinal): specialize IAsyncResult<Boolean>;
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
    procedure OnConnected(ACallback: specialize TRefAction<Boolean>);
    procedure OnDataReceived(ACallback: specialize TRefAction<TBytes>);
    procedure OnDisconnected(ACallback: TRefProc);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}

    class function CreateTCP: IAsyncSocket;
    class function CreateUDP: IAsyncSocket;
  end;

  TAsyncSocketListener = class(TSocketListener, IAsyncSocketListener)
  private
    FPoller: ISocketPoller;
    FRuntime: TAsyncRuntime;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FOnClientConnected: specialize TRefAction<IAsyncSocket>;
    FOnError: specialize TRefAction<Exception>;
    {$ENDIF}
  public
    constructor Create(const AAddress: ISocketAddress);
    destructor Destroy; override;

    function AcceptAsync: specialize IAsyncResult<IAsyncSocket>;
    function AcceptAsync(ATimeoutMs: Cardinal): specialize IAsyncResult<IAsyncSocket>;
    function AcceptMultipleAsync(AMaxCount: Integer): specialize IAsyncResult<TAsyncSocketArray>;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure OnClientConnected(ACallback: specialize TRefAction<IAsyncSocket>);
    procedure OnError(ACallback: specialize TRefAction<Exception>);
    {$ENDIF}

    class function ListenTCP(APort: Word): IAsyncSocketListener;
    class function ListenUDP(APort: Word): IAsyncSocketListener;
  end;

implementation

{$IFNDEF FAFAFA_SOCKET_ADVANCED}

class function TSocketBuffer.Create(aCapacity: Integer): TSocketBuffer;
begin
  Result.Data := nil;
  Result.FSize := 0;
  Result.Capacity := 0;

  if aCapacity <= 0 then
    Exit;

  GetMem(Result.Data, aCapacity);
  FillChar(Result.Data^, aCapacity, 0);
  Result.Capacity := aCapacity;
end;

procedure TSocketBuffer.Free;
begin
  if Data <> nil then
  begin
    FreeMem(Data);
    Data := nil;
  end;
  FSize := 0;
  Capacity := 0;
end;

procedure TSocketBuffer.Resize(aNewSize: Integer);
begin
  if aNewSize < 0 then
    aNewSize := 0;

  if aNewSize > Capacity then
  begin
    ReAllocMem(Data, aNewSize);
    Capacity := aNewSize;
  end;

  FSize := aNewSize;
end;

{$ENDIF}

{ TAsyncResult<T> }

constructor TAsyncResult.Create;
begin
  inherited Create;
  FCompleted := False;
  FCancelled := False;
  FHasError := False;
  FError := nil;
  InitCriticalSection(FLock);
end;

destructor TAsyncResult.Destroy;
begin
  if Assigned(FError) then
    FError.Free;
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
    if FHasError and Assigned(FError) then
      raise Exception.Create(FError.Message);
    if FCancelled then
      raise ECore.Create('异步操作已取消');
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
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncResult.WaitFor(ATimeoutMs: Cardinal): Boolean;
var
  LStart: QWord;
begin
  if IsCompleted then
    Exit(True);

  if ATimeoutMs = INFINITE then
  begin
    while not IsCompleted do
      Sleep(1);
    Exit(True);
  end;

  LStart := GetTickCount64;
  while not IsCompleted do
  begin
    if (GetTickCount64 - LStart) >= QWord(ATimeoutMs) then
      Break;
    Sleep(1);
  end;

  Result := IsCompleted;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TAsyncResult.OnComplete(ACallback: specialize TRefAction<T>);
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

procedure TAsyncResult.OnError(ACallback: specialize TRefAction<Exception>);
begin
  EnterCriticalSection(FLock);
  try
    FOnError := ACallback;
    if FCompleted and FHasError and Assigned(FOnError) and Assigned(FError) then
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
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      if Assigned(FOnError) and Assigned(FError) then
        FOnError(FError);
      {$ENDIF}
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

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
  begin
    try
      FPoller.UnregisterSocket(Self);
    except
      // ignore
    end;
  end;
  inherited Destroy;
end;

function TAsyncSocket.ConnectAsync(const AAddress: ISocketAddress): specialize IAsyncResult<Boolean>;
begin
  Result := ConnectAsync(AAddress, INFINITE);
end;

function TAsyncSocket.ConnectAsync(const AAddress: ISocketAddress; ATimeoutMs: Cardinal): specialize IAsyncResult<Boolean>;
var
  LResult: specialize TAsyncResult<Boolean>;
  LError: Exception;
begin
  LResult := specialize TAsyncResult<Boolean>.Create;
  Result := LResult;

  try
    Self.Connect(AAddress);
    LResult.SetResult(True);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    if Assigned(FOnConnected) then
      FOnConnected(True);
    {$ENDIF}
  except
    on E: Exception do
    begin
      LError := Exception.Create(E.Message);
      LResult.SetError(LError);

      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      if Assigned(FOnConnected) then
        FOnConnected(False);
      if Assigned(FOnError) then
        FOnError(LError);
      {$ENDIF}
    end;
  end;
end;

function TAsyncSocket.SendAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
begin
  if Length(AData) = 0 then
    Exit(SendAsync(nil, 0));
  Result := SendAsync(@AData[0], Length(AData));
end;

function TAsyncSocket.SendAsync(AData: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LBytesSent: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    if (AData = nil) or (ASize <= 0) then
      LBytesSent := 0
    else
      LBytesSent := Self.Send(AData, ASize);
    LResult.SetResult(LBytesSent);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.ReceiveAsync(AMaxSize: Integer): specialize IAsyncResult<TBytes>;
var
  LResult: specialize TAsyncResult<TBytes>;
  LData: TBytes;
begin
  LResult := specialize TAsyncResult<TBytes>.Create;
  Result := LResult;

  try
    LData := Self.Receive(AMaxSize);
    LResult.SetResult(LData);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    if Assigned(FOnDataReceived) then
      FOnDataReceived(LData);
    {$ENDIF}
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.ReceiveAsync(ABuffer: Pointer; ASize: Integer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LBytesReceived: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    if (ABuffer = nil) or (ASize <= 0) then
      LBytesReceived := 0
    else
      LBytesReceived := Self.Receive(ABuffer, ASize);
    LResult.SetResult(LBytesReceived);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.SendAllAsync(const AData: TBytes): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LSent: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    if Length(AData) = 0 then
      LSent := 0
    else
      LSent := Self.SendAll(AData);
    LResult.SetResult(LSent);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.ReceiveExactAsync(ASize: Integer): specialize IAsyncResult<TBytes>;
var
  LResult: specialize TAsyncResult<TBytes>;
  LData: TBytes;
begin
  LResult := specialize TAsyncResult<TBytes>.Create;
  Result := LResult;

  try
    LData := Self.ReceiveExact(ASize);
    LResult.SetResult(LData);

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    if Assigned(FOnDataReceived) then
      FOnDataReceived(LData);
    {$ENDIF}
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.SendBufferAsync(const ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LBytesSent: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    if (ABuffer.Data = nil) or (ABuffer.Size <= 0) then
      LBytesSent := 0
    else
      LBytesSent := Self.Send(ABuffer.Data, ABuffer.Size);
    LResult.SetResult(LBytesSent);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.ReceiveBufferAsync(var ABuffer: TSocketBuffer): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LBytesReceived: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    if (ABuffer.Data = nil) or (ABuffer.Capacity <= 0) then
      LBytesReceived := 0
    else
      LBytesReceived := Self.Receive(ABuffer.Data, ABuffer.Capacity);

    if LBytesReceived > 0 then
      ABuffer.Resize(LBytesReceived)
    else
      ABuffer.Resize(0);

    LResult.SetResult(LBytesReceived);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.SendVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LIndex: Integer;
  LTotalSent: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    LTotalSent := 0;
    for LIndex := 0 to High(AVectors) do
    begin
      if (AVectors[LIndex].Data <> nil) and (AVectors[LIndex].Size > 0) then
        Inc(LTotalSent, Self.Send(AVectors[LIndex].Data, AVectors[LIndex].Size));
    end;
    LResult.SetResult(LTotalSent);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
end;

function TAsyncSocket.ReceiveVectorizedAsync(const AVectors: TIOVectorArray): specialize IAsyncResult<Integer>;
var
  LResult: specialize TAsyncResult<Integer>;
  LIndex: Integer;
  LRead: Integer;
  LTotalRead: Integer;
begin
  LResult := specialize TAsyncResult<Integer>.Create;
  Result := LResult;

  try
    LTotalRead := 0;
    for LIndex := 0 to High(AVectors) do
    begin
      if (AVectors[LIndex].Data <> nil) and (AVectors[LIndex].Size > 0) then
      begin
        LRead := Self.Receive(AVectors[LIndex].Data, AVectors[LIndex].Size);
        if LRead > 0 then
          Inc(LTotalRead, LRead);
      end;
    end;
    LResult.SetResult(LTotalRead);
  except
    on E: Exception do
      LResult.SetError(Exception.Create(E.Message));
  end;
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
procedure TAsyncSocket.OnConnected(ACallback: specialize TRefAction<Boolean>);
begin
  FOnConnected := ACallback;
end;

procedure TAsyncSocket.OnDataReceived(ACallback: specialize TRefAction<TBytes>);
begin
  FOnDataReceived := ACallback;
end;

procedure TAsyncSocket.OnDisconnected(ACallback: TRefProc);
begin
  FOnDisconnected := ACallback;
end;

procedure TAsyncSocket.OnError(ACallback: specialize TRefAction<Exception>);
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

{ TAsyncSocketListener }

constructor TAsyncSocketListener.Create(const AAddress: ISocketAddress);
begin
  inherited Create(AAddress);
  FRuntime := TAsyncRuntime.GetInstance;
  FPoller := TSelectSocketPoller.Create;
end;

destructor TAsyncSocketListener.Destroy;
begin
  FPoller := nil;
  inherited Destroy;
end;

function TAsyncSocketListener.AcceptAsync: specialize IAsyncResult<IAsyncSocket>;
begin
  Result := AcceptAsync(INFINITE);
end;

function TAsyncSocketListener.AcceptAsync(ATimeoutMs: Cardinal): specialize IAsyncResult<IAsyncSocket>;
var
  LResult: specialize TAsyncResult<IAsyncSocket>;
  LError: Exception;
begin
  LResult := specialize TAsyncResult<IAsyncSocket>.Create;
  Result := LResult;

  try
    if ATimeoutMs = INFINITE then
      inherited Accept
    else
      inherited AcceptWithTimeout(ATimeoutMs);

    LResult.SetError(ESocketError.Create('当前版本未提供已接受连接到 IAsyncSocket 的直接包装'));
  except
    on E: Exception do
    begin
      LError := Exception.Create(E.Message);
      LResult.SetError(LError);
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      if Assigned(FOnError) then
        FOnError(LError);
      {$ENDIF}
    end;
  end;
end;

function TAsyncSocketListener.AcceptMultipleAsync(AMaxCount: Integer): specialize IAsyncResult<TAsyncSocketArray>;
var
  LResult: specialize TAsyncResult<TAsyncSocketArray>;
  LSockets: TAsyncSocketArray;
begin
  LResult := specialize TAsyncResult<TAsyncSocketArray>.Create;
  Result := LResult;

  if AMaxCount <= 0 then
  begin
    SetLength(LSockets, 0);
    LResult.SetResult(LSockets);
    Exit;
  end;

  SetLength(LSockets, 0);
  LResult.SetResult(LSockets);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TAsyncSocketListener.OnClientConnected(ACallback: specialize TRefAction<IAsyncSocket>);
begin
  FOnClientConnected := ACallback;
end;

procedure TAsyncSocketListener.OnError(ACallback: specialize TRefAction<Exception>);
begin
  FOnError := ACallback;
end;
{$ENDIF}

class function TAsyncSocketListener.ListenTCP(APort: Word): IAsyncSocketListener;
var
  LAddress: ISocketAddress;
begin
  LAddress := TSocketAddress.Any(APort);
  Result := TAsyncSocketListener.Create(LAddress);
end;

class function TAsyncSocketListener.ListenUDP(APort: Word): IAsyncSocketListener;
var
  LAddress: ISocketAddress;
begin
  LAddress := TSocketAddress.Any(APort);
  Result := TAsyncSocketListener.Create(LAddress);
end;

{$ENDIF} // FAFAFA_SOCKET_ASYNC_EXPERIMENTAL

end.
