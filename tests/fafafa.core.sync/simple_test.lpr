program simple_test;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.base;

type
  // 简化的锁接口
  ISimpleLock = interface
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function IsLocked: Boolean;
  end;

  // 简化的互斥锁实现
  TSimpleMutex = class(TInterfacedObject, ISimpleLock)
  private
    FLocked: Boolean;
    FOwnerThread: TThreadID;
  public
    constructor Create;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
    function IsLocked: Boolean;
  end;

{ TSimpleMutex }

constructor TSimpleMutex.Create;
begin
  inherited Create;
  FLocked := False;
  FOwnerThread := 0;
end;

procedure TSimpleMutex.Acquire;
begin
  if FLocked and (FOwnerThread = GetCurrentThreadId) then
    Exit; // 重入锁
    
  while FLocked do
    Sleep(1); // 简单的等待
    
  FLocked := True;
  FOwnerThread := GetCurrentThreadId;
end;

procedure TSimpleMutex.Release;
begin
  if not FLocked then
    raise Exception.Create('Mutex is not locked');
    
  if FOwnerThread <> GetCurrentThreadId then
    raise Exception.Create('Cannot release mutex from different thread');
    
  FLocked := False;
  FOwnerThread := 0;
end;

function TSimpleMutex.TryAcquire: Boolean;
begin
  if FLocked then
    Exit(False);
    
  FLocked := True;
  FOwnerThread := GetCurrentThreadId;
  Result := True;
end;

function TSimpleMutex.IsLocked: Boolean;
begin
  Result := FLocked;
end;

// 测试函数
procedure TestBasicMutex;
var
  LMutex: ISimpleLock;
begin
  WriteLn('Testing basic mutex...');
  
  LMutex := TSimpleMutex.Create;
  
  // 测试初始状态
  if LMutex.IsLocked then
    raise Exception.Create('Mutex should not be locked initially');
    
  // 测试获取锁
  LMutex.Acquire;
  if not LMutex.IsLocked then
    raise Exception.Create('Mutex should be locked after Acquire');
    
  // 测试释放锁
  LMutex.Release;
  if LMutex.IsLocked then
    raise Exception.Create('Mutex should not be locked after Release');
    
  // 测试 TryAcquire
  if not LMutex.TryAcquire then
    raise Exception.Create('TryAcquire should succeed on unlocked mutex');
    
  if not LMutex.IsLocked then
    raise Exception.Create('Mutex should be locked after TryAcquire');
    
  LMutex.Release;
  
  WriteLn('Basic mutex test passed!');
end;

procedure TestExceptionHandling;
var
  LMutex: ISimpleLock;
begin
  WriteLn('Testing exception handling...');
  
  LMutex := TSimpleMutex.Create;
  
  // 测试释放未锁定的互斥锁
  try
    LMutex.Release;
    raise Exception.Create('Should have thrown exception');
  except
    on E: Exception do
      if Pos('not locked', E.Message) = 0 then
        raise Exception.Create('Wrong exception message: ' + E.Message);
  end;
  
  WriteLn('Exception handling test passed!');
end;

begin
  WriteLn('Simple Sync Test');
  WriteLn('================');
  
  try
    TestBasicMutex;
    TestExceptionHandling;
    
    WriteLn('');
    WriteLn('All tests passed!');
    ExitCode := 0;
    
  except
    on E: Exception do
    begin
      WriteLn('Test failed: ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
