unit fafafa.core.async.runtime;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  Classes,
  SyncObjs;

type
  TEventLoopState = (elsIdle, elsRunning, elsShutdown);

  TAsyncRuntime = class
  private
    class var FInstance: TAsyncRuntime;
    class var FLock: TCriticalSection;

    FState: TEventLoopState;
    FRunning: Boolean;

    constructor Create;
  public
    destructor Destroy; override;

    class function Instance: TAsyncRuntime;
    class function GetInstance: TAsyncRuntime;
    class procedure Initialize;
    class procedure Finalize;

    procedure Run;
    procedure RunOnce;
    procedure Shutdown;
    procedure Stop;

    function IsRunning: Boolean;
    function IsMainThread: Boolean;
    function GetState: TEventLoopState;

    procedure Schedule(const aTask: TThreadMethod; aPriority: Integer = 0);
    procedure ScheduleDelayed(const aTask: TThreadMethod; aDelayMs: Cardinal);

    property State: TEventLoopState read GetState;
  end;

implementation

constructor TAsyncRuntime.Create;
begin
  inherited Create;
  FState := elsIdle;
  FRunning := False;
end;

destructor TAsyncRuntime.Destroy;
begin
  inherited Destroy;
end;

class function TAsyncRuntime.Instance: TAsyncRuntime;
begin
  if FInstance = nil then
  begin
    if FLock = nil then
      FLock := TCriticalSection.Create;

    FLock.Enter;
    try
      if FInstance = nil then
        FInstance := TAsyncRuntime.Create;
    finally
      FLock.Leave;
    end;
  end;
  Result := FInstance;
end;

class function TAsyncRuntime.GetInstance: TAsyncRuntime;
begin
  Result := Instance;
end;

class procedure TAsyncRuntime.Initialize;
begin
  if FLock = nil then
    FLock := TCriticalSection.Create;
  Instance;
end;

class procedure TAsyncRuntime.Finalize;
begin
  if FInstance <> nil then
  begin
    FInstance.Shutdown;
    FreeAndNil(FInstance);
  end;
  FreeAndNil(FLock);
end;

procedure TAsyncRuntime.Run;
begin
  if FRunning then
    Exit;

  FRunning := True;
  FState := elsRunning;
end;

procedure TAsyncRuntime.RunOnce;
begin
  if FState = elsShutdown then
    Exit;

  FState := elsRunning;
end;

procedure TAsyncRuntime.Shutdown;
begin
  FRunning := False;
  FState := elsShutdown;
end;

procedure TAsyncRuntime.Stop;
begin
  Shutdown;
end;

function TAsyncRuntime.IsRunning: Boolean;
begin
  Result := FRunning and (FState = elsRunning);
end;

function TAsyncRuntime.IsMainThread: Boolean;
begin
  Result := GetCurrentThreadId = MainThreadID;
end;

function TAsyncRuntime.GetState: TEventLoopState;
begin
  Result := FState;
end;

procedure TAsyncRuntime.Schedule(const aTask: TThreadMethod; aPriority: Integer);
begin
  if not Assigned(aTask) then
    Exit;

  TThread.CreateAnonymousThread(procedure
    begin
      try
        aTask();
      except
        on E: Exception do
        begin
          // no-op: 保持与原运行时“任务异常不崩溃主流程”一致
        end;
      end;
    end).Start;
end;

procedure TAsyncRuntime.ScheduleDelayed(const aTask: TThreadMethod; aDelayMs: Cardinal);
begin
  if not Assigned(aTask) then
    Exit;

  TThread.CreateAnonymousThread(procedure
    begin
      try
        Sleep(aDelayMs);
        aTask();
      except
        on E: Exception do
        begin
          // no-op
        end;
      end;
    end).Start;
end;

end.
