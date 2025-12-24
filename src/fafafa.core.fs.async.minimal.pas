unit fafafa.core.fs.async.minimal;

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

  // 异步文件读取结果
  TAsyncFileReadResult = class
  private
    FStatus: TAsyncStatus;
    FData: TBytes;
    FErrorMessage: string;
    FThread: TThread;
    FLock: TRTLCriticalSection;
  public
    constructor Create(const aPath: string);
    destructor Destroy; override;
    
    function IsCompleted: Boolean;
    function Wait(aTimeoutMs: Integer = -1): Boolean;
    function GetData: TBytes;
    function GetStatus: TAsyncStatus;
    function GetErrorMessage: string;
    procedure Cancel;
  end;

  // 异步文件写入结果
  TAsyncFileWriteResult = class
  private
    FStatus: TAsyncStatus;
    FSuccess: Boolean;
    FErrorMessage: string;
    FThread: TThread;
    FLock: TRTLCriticalSection;
  public
    constructor Create(const aPath: string; const aData: TBytes);
    destructor Destroy; override;
    
    function IsCompleted: Boolean;
    function Wait(aTimeoutMs: Integer = -1): Boolean;
    function GetSuccess: Boolean;
    function GetStatus: TAsyncStatus;
    function GetErrorMessage: string;
    procedure Cancel;
  end;

  // 最小化异步文件系统
  TMinimalAsyncFileSystem = class
  public
    // 基础异步文件操作
    function ReadFileAsync(const aPath: string): TAsyncFileReadResult;
    function WriteFileAsync(const aPath: string; const aData: TBytes): TAsyncFileWriteResult;
    function ReadTextAsync(const aPath: string): TAsyncFileReadResult;
    function WriteTextAsync(const aPath: string; const aText: string): TAsyncFileWriteResult;
  end;

// 工厂函数
function CreateMinimalAsyncFileSystem: TMinimalAsyncFileSystem;

implementation

// 文件读取工作线程
type
  TFileReadWorkerThread = class(TThread)
  private
    FPath: string;
    FResult: TAsyncFileReadResult;
  public
    constructor Create(const aPath: string; aResult: TAsyncFileReadResult);
    procedure Execute; override;
  end;

  // 文件写入工作线程
  TFileWriteWorkerThread = class(TThread)
  private
    FPath: string;
    FData: TBytes;
    FResult: TAsyncFileWriteResult;
  public
    constructor Create(const aPath: string; const aData: TBytes; aResult: TAsyncFileWriteResult);
    procedure Execute; override;
  end;

// TFileReadWorkerThread 实现

constructor TFileReadWorkerThread.Create(const aPath: string; aResult: TAsyncFileReadResult);
begin
  inherited Create(False);
  FPath := aPath;
  FResult := aResult;
  FreeOnTerminate := True;
end;

procedure TFileReadWorkerThread.Execute;
begin
  try
    EnterCriticalSection(FResult.FLock);
    try
      FResult.FData := fs_read_file(FPath);
      FResult.FStatus := asCompleted;
    finally
      LeaveCriticalSection(FResult.FLock);
    end;
  except
    on E: Exception do
    begin
      EnterCriticalSection(FResult.FLock);
      try
        FResult.FStatus := asFailed;
        FResult.FErrorMessage := 'Failed to read file "' + FPath + '": ' + E.Message;
      finally
        LeaveCriticalSection(FResult.FLock);
      end;
    end;
  end;
end;

// TFileWriteWorkerThread 实现

constructor TFileWriteWorkerThread.Create(const aPath: string; const aData: TBytes; aResult: TAsyncFileWriteResult);
begin
  inherited Create(False);
  FPath := aPath;
  FData := Copy(aData); // 复制数据避免并发问题
  FResult := aResult;
  FreeOnTerminate := True;
end;

procedure TFileWriteWorkerThread.Execute;
begin
  try
    EnterCriticalSection(FResult.FLock);
    try
      FResult.FSuccess := fs_write_file(FPath, FData);
      FResult.FStatus := asCompleted;
    finally
      LeaveCriticalSection(FResult.FLock);
    end;
  except
    on E: Exception do
    begin
      EnterCriticalSection(FResult.FLock);
      try
        FResult.FStatus := asFailed;
        FResult.FSuccess := False;
        FResult.FErrorMessage := 'Failed to write file "' + FPath + '": ' + E.Message;
      finally
        LeaveCriticalSection(FResult.FLock);
      end;
    end;
  end;
end;

// TAsyncFileReadResult 实现

constructor TAsyncFileReadResult.Create(const aPath: string);
begin
  inherited Create;
  InitCriticalSection(FLock);
  FStatus := asRunning;
  FErrorMessage := '';
  
  // 启动工作线程
  FThread := TFileReadWorkerThread.Create(aPath, Self);
end;

destructor TAsyncFileReadResult.Destroy;
begin
  if Assigned(FThread) and not FThread.Finished then
  begin
    FThread.Terminate;
    FThread.WaitFor;
  end;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TAsyncFileReadResult.IsCompleted: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FStatus in [asCompleted, asFailed, asCancelled];
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileReadResult.Wait(aTimeoutMs: Integer): Boolean;
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

function TAsyncFileReadResult.GetData: TBytes;
begin
  Wait(-1); // 等待完成
  
  EnterCriticalSection(FLock);
  try
    case FStatus of
      asCompleted: Result := FData;
      asFailed: raise EAsyncFileError.Create(FErrorMessage);
      asCancelled: raise EAsyncFileError.Create('Operation was cancelled');
    else
      raise EAsyncFileError.Create('Operation is still running');
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileReadResult.GetStatus: TAsyncStatus;
begin
  EnterCriticalSection(FLock);
  try
    Result := FStatus;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileReadResult.GetErrorMessage: string;
begin
  EnterCriticalSection(FLock);
  try
    Result := FErrorMessage;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAsyncFileReadResult.Cancel;
begin
  if Assigned(FThread) then
    FThread.Terminate;
    
  EnterCriticalSection(FLock);
  try
    FStatus := asCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

// TAsyncFileWriteResult 实现

constructor TAsyncFileWriteResult.Create(const aPath: string; const aData: TBytes);
begin
  inherited Create;
  InitCriticalSection(FLock);
  FStatus := asRunning;
  FSuccess := False;
  FErrorMessage := '';
  
  // 启动工作线程
  FThread := TFileWriteWorkerThread.Create(aPath, aData, Self);
end;

destructor TAsyncFileWriteResult.Destroy;
begin
  if Assigned(FThread) and not FThread.Finished then
  begin
    FThread.Terminate;
    FThread.WaitFor;
  end;
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TAsyncFileWriteResult.IsCompleted: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FStatus in [asCompleted, asFailed, asCancelled];
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileWriteResult.Wait(aTimeoutMs: Integer): Boolean;
var
  LStartTime: QWord;
  LElapsed: QWord;
begin
  if IsCompleted then
    Exit(True);
    
  LStartTime := GetTickCount64;
  
  while not IsCompleted do
  begin
    Sleep(10);
    
    if aTimeoutMs > 0 then
    begin
      LElapsed := GetTickCount64 - LStartTime;
      if LElapsed >= QWord(aTimeoutMs) then
        Exit(False);
    end;
  end;
  
  Result := True;
end;

function TAsyncFileWriteResult.GetSuccess: Boolean;
begin
  Wait(-1); // 等待完成
  
  EnterCriticalSection(FLock);
  try
    case FStatus of
      asCompleted: Result := FSuccess;
      asFailed: raise EAsyncFileError.Create(FErrorMessage);
      asCancelled: raise EAsyncFileError.Create('Operation was cancelled');
    else
      raise EAsyncFileError.Create('Operation is still running');
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileWriteResult.GetStatus: TAsyncStatus;
begin
  EnterCriticalSection(FLock);
  try
    Result := FStatus;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAsyncFileWriteResult.GetErrorMessage: string;
begin
  EnterCriticalSection(FLock);
  try
    Result := FErrorMessage;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TAsyncFileWriteResult.Cancel;
begin
  if Assigned(FThread) then
    FThread.Terminate;
    
  EnterCriticalSection(FLock);
  try
    FStatus := asCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

// TMinimalAsyncFileSystem 实现

function TMinimalAsyncFileSystem.ReadFileAsync(const aPath: string): TAsyncFileReadResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := TAsyncFileReadResult.Create(aPath);
end;

function TMinimalAsyncFileSystem.WriteFileAsync(const aPath: string; const aData: TBytes): TAsyncFileWriteResult;
begin
  // 路径安全验证
  if not ValidatePath(aPath) then
    raise EAsyncFileError.Create('Invalid or unsafe path: ' + aPath);
  
  Result := TAsyncFileWriteResult.Create(aPath, aData);
end;

function TMinimalAsyncFileSystem.ReadTextAsync(const aPath: string): TAsyncFileReadResult;
begin
  // 文本读取就是二进制读取，调用者负责编码转换
  Result := ReadFileAsync(aPath);
end;

function TMinimalAsyncFileSystem.WriteTextAsync(const aPath: string; const aText: string): TAsyncFileWriteResult;
var
  LData: TBytes;
begin
  // 将文本转换为UTF8字节数组
  LData := TEncoding.UTF8.GetBytes(aText);
  Result := WriteFileAsync(aPath, LData);
end;

// 工厂函数

function CreateMinimalAsyncFileSystem: TMinimalAsyncFileSystem;
begin
  Result := TMinimalAsyncFileSystem.Create;
end;

end.
