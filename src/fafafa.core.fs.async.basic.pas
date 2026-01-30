unit fafafa.core.fs.async.basic;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  {$IFDEF WINDOWS}
  Windows,
  {$ELSE}
  BaseUnix, Unix,
  {$ENDIF}
  fafafa.core.fs,
  fafafa.core.fs.path,
  fafafa.core.fs.async.iface;  // ✅ 使用公共类型

type
  // TAsyncStatus 和 EAsyncFileError 现在从 async.iface 导入

  // 基础异步结果接口
  IAsyncResult = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetStatus: TAsyncStatus;
    function IsCompleted: Boolean;
    function Wait(aTimeoutMs: Integer = -1): Boolean;
    function GetErrorMessage: string;
  end;

  // 字节数组异步结果
  IAsyncBytesResult = interface(IAsyncResult)
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function GetResult: TBytes;
  end;

  // 布尔异步结果
  IAsyncBooleanResult = interface(IAsyncResult)
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function GetResult: Boolean;
  end;

  // 字符串异步结果
  IAsyncStringResult = interface(IAsyncResult)
    ['{D4E5F6A7-B8C9-0123-DEF1-234567890123}']
    function GetResult: string;
  end;

  // 整数异步结果
  IAsyncInt64Result = interface(IAsyncResult)
    ['{E5F6A7B8-C9D0-1234-EF12-345678901234}']
    function GetResult: Int64;
  end;

  // 基础异步结果实现
  TBaseAsyncResult = class(TInterfacedObject, IAsyncResult)
  private
    FStatus: TAsyncStatus;
    FErrorMessage: string;
    FLock: TRTLCriticalSection;
    FThread: TThread;
  protected
    procedure SetCompleted;
    procedure SetFailed(const aErrorMessage: string);
    procedure SetCancelled;
  public
    constructor Create;
    destructor Destroy; override;
    
    function GetStatus: TAsyncStatus;
    function IsCompleted: Boolean;
    function Wait(aTimeoutMs: Integer = -1): Boolean;
    function GetErrorMessage: string;
    
    procedure Cancel;
  end;

  // 字节数组异步结果实现
  TAsyncBytesResult = class(TBaseAsyncResult, IAsyncBytesResult)
  private
    FResult: TBytes;
  public
    constructor Create(const aPath: string; aOperation: TProc);
    function GetResult: TBytes;
  end;

  // 布尔异步结果实现
  TAsyncBooleanResult = class(TBaseAsyncResult, IAsyncBooleanResult)
  private
    FResult: Boolean;
  public
    constructor Create(aOperation: TFunc<Boolean>);
    function GetResult: Boolean;
  end;

  // 字符串异步结果实现
  TAsyncStringResult = class(TBaseAsyncResult, IAsyncStringResult)
  private
    FResult: string;
  public
    constructor Create(aOperation: TFunc<string>);
    function GetResult: string;
  end;

  // 整数异步结果实现
  TAsyncInt64Result = class(TBaseAsyncResult, IAsyncInt64Result)
  private
    FResult: Int64;
  public
    constructor Create(aOperation: TFunc<Int64>);
    function GetResult: Int64;
  end;

  // 基础异步文件系统
  TBasicAsyncFileSystem = class
  public
    // 基础文件操作
    function ReadFileAsync(const aPath: string): IAsyncBytesResult;
    function WriteFileAsync(const aPath: string; const aData: TBytes): IAsyncBooleanResult;
    function ReadTextAsync(const aPath: string): IAsyncStringResult;
    function WriteTextAsync(const aPath: string; const aText: string): IAsyncBooleanResult;
    
    // 文件信息
    function ExistsAsync(const aPath: string): IAsyncBooleanResult;
    function FileSizeAsync(const aPath: string): IAsyncInt64Result;
    function DeleteAsync(const aPath: string): IAsyncBooleanResult;
  end;

// 工厂函数
function CreateBasicAsyncFileSystem: TBasicAsyncFileSystem;

implementation

// 工作线程类
type
  TAsyncWorkerThread = class(TThread)
  private
    FAsyncResult: TBaseAsyncResult;
    FOperation: TProc;
  public
    constructor Create(aAsyncResult: TBaseAsyncResult; aOperation: TProc);
    procedure Execute; override;
  end;

// TAsyncWorkerThread 实现

constructor TAsyncWorkerThread.Create(aAsyncResult: TBaseAsyncResult; aOperation: TProc);
begin
  inherited Create(False);
  FAsyncResult := aAsyncResult;
  FOperation := aOperation;
  FreeOnTerminate := True;
end;

procedure TAsyncWorkerThread.Execute;
begin
  try
    if Assigned(FOperation) then
      FOperation();
    FAsyncResult.SetCompleted;
  except
    on E: Exception do
      FAsyncResult.SetFailed(E.Message);
  end;
end;

// TBaseAsyncResult 实现

constructor TBaseAsyncResult.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
  FStatus := asRunning;
  FErrorMessage := '';
end;

destructor TBaseAsyncResult.Destroy;
begin
  if Assigned(FThread) and not FThread.Finished then
  begin
    FThread.Terminate;
    FThread.WaitFor;
  end;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TBaseAsyncResult.SetCompleted;
begin
  EnterCriticalSection(FLock);
  try
    FStatus := asCompleted;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TBaseAsyncResult.SetFailed(const aErrorMessage: string);
begin
  EnterCriticalSection(FLock);
  try
    FStatus := asFailed;
    FErrorMessage := aErrorMessage;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TBaseAsyncResult.SetCancelled;
begin
  EnterCriticalSection(FLock);
  try
    FStatus := asCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TBaseAsyncResult.GetStatus: TAsyncStatus;
begin
  EnterCriticalSection(FLock);
  try
    Result := FStatus;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TBaseAsyncResult.IsCompleted: Boolean;
begin
  Result := GetStatus in [asCompleted, asFailed, asCancelled];
end;

function TBaseAsyncResult.Wait(aTimeoutMs: Integer): Boolean;
var
  LStartTime: QWord;
  LElapsed: QWord;
begin
  if IsCompleted then
    Exit(True);
    
  LStartTime := GetTickCount64;
  
  while not IsCompleted do
  begin
    Sleep(10); // 短暂休眠避免忙等待
    
    if aTimeoutMs > 0 then
    begin
      LElapsed := GetTickCount64 - LStartTime;
      if LElapsed >= QWord(aTimeoutMs) then
        Exit(False);
    end;
  end;
  
  Result := True;
end;

function TBaseAsyncResult.GetErrorMessage: string;
begin
  EnterCriticalSection(FLock);
  try
    Result := FErrorMessage;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TBaseAsyncResult.Cancel;
begin
  if Assigned(FThread) then
    FThread.Terminate;
  SetCancelled;
end;

// TAsyncBytesResult 实现

constructor TAsyncBytesResult.Create(const aPath: string; aOperation: TProc);
begin
  inherited Create;
  
  FThread := TAsyncWorkerThread.Create(Self, aOperation);
end;

function TAsyncBytesResult.GetResult: TBytes;
begin
  Wait(-1); // 等待完成
  
  case GetStatus of
    asCompleted: Result := FResult;
    asFailed: raise EAsyncFileError.Create(GetErrorMessage);
    asCancelled: raise EAsyncFileError.Create('Operation was cancelled');
  else
    raise EAsyncFileError.Create('Operation is still running');
  end;
end;

// TBasicAsyncFileSystem 实现

function TBasicAsyncFileSystem.ReadFileAsync(const aPath: string): IAsyncBytesResult;
var
  LPathCopy: string;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  LPathCopy := aPath;
  
  // 创建异步操作
  Result := TAsyncBytesResult.Create(LPathCopy, 
    procedure
    var
      LResult: TAsyncBytesResult;
    begin
      LResult := Result as TAsyncBytesResult;
      try
        LResult.FResult := fs_read_file(LPathCopy);
      except
        on E: Exception do
          raise EAsyncFileError.Create('Failed to read file "' + LPathCopy + '": ' + E.Message);
      end;
    end);
end;

function TBasicAsyncFileSystem.WriteFileAsync(const aPath: string; const aData: TBytes): IAsyncBooleanResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  // 暂时返回nil，需要实现
  Result := nil;
end;

function TBasicAsyncFileSystem.ReadTextAsync(const aPath: string): IAsyncStringResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := nil;
end;

function TBasicAsyncFileSystem.WriteTextAsync(const aPath: string; const aText: string): IAsyncBooleanResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := nil;
end;

function TBasicAsyncFileSystem.ExistsAsync(const aPath: string): IAsyncBooleanResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := nil;
end;

function TBasicAsyncFileSystem.FileSizeAsync(const aPath: string): IAsyncInt64Result;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := nil;
end;

function TBasicAsyncFileSystem.DeleteAsync(const aPath: string): IAsyncBooleanResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := nil;
end;

// 工厂函数

function CreateBasicAsyncFileSystem: TBasicAsyncFileSystem;
begin
  Result := TBasicAsyncFileSystem.Create;
end;

end.
