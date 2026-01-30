unit fafafa.core.lockfree.backoff;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  {$IFDEF UNIX}
  BaseUnix,
  {$ENDIF}
  SysUtils;

type
  IBackoffPolicy = interface
    ['{1C6E8B0C-33E5-4B6B-9F1C-2F8D9E7C5A12}']
    procedure Step(var FailCount: Integer);
  end;

// 获取默认退避策略（线程安全、惰性初始化）
function GetDefaultBackoff: IBackoffPolicy;
// 获取“积极让出/微眠”退避策略（单例）
function GetAggressiveBackoff: IBackoffPolicy;
// 设置默认退避策略（测试/基准用途）
procedure SetDefaultBackoff(const P: IBackoffPolicy);
// 便捷函数：执行一次退避（委托默认策略）
procedure BackoffStep(var FailCount: Integer); inline;

type
  TPausableBackoffPolicy = class(TInterfacedObject, IBackoffPolicy)
  public
    procedure Step(var FailCount: Integer);
  end;
  TAggressiveBackoffPolicy = class(TInterfacedObject, IBackoffPolicy)
  public
    procedure Step(var FailCount: Integer);
  end;


implementation

var
  GDefaultBackoff: IBackoffPolicy = nil;
var
  GAggressiveBackoff: IBackoffPolicy = nil;


type
  TAdaptiveBackoffPolicy = class(TInterfacedObject, IBackoffPolicy)
  public
    procedure Step(var FailCount: Integer);
  end;

procedure TPausableBackoffPolicy.Step(var FailCount: Integer);
begin
  Inc(FailCount);
  // 先短自旋：什么都不做，依赖 CPU 调度；随后尝试让出；极少数情况下微眠
  if (FailCount and $0F) = 0 then
  begin
    {$IFDEF WINDOWS}
    // Windows: Sleep(0) 让出；可选 SwitchToThread 提示调度
    Sleep(0);
    {$ENDIF}
    {$IFDEF UNIX}
    // POSIX: sched_yield 等价；缺省退化为 Sleep(0)
    fpSleep(0);
    {$ENDIF}
  end;
  if (FailCount and $3FF) = 0 then
    SysUtils.Sleep(1);
end;

procedure TAggressiveBackoffPolicy.Step(var FailCount: Integer);
begin
  Inc(FailCount);
  // 积极路径：更频繁让出，极少微眠；可在高冲突基准中观察差异
  if (FailCount and $07) = 0 then
  begin
    {$IFDEF WINDOWS}
    Sleep(0);
    {$ENDIF}
    {$IFDEF UNIX}
    fpSleep(0);
    {$ENDIF}
  end;
  if (FailCount and $1FF) = 0 then
    SysUtils.Sleep(1);
end;

procedure TAdaptiveBackoffPolicy.Step(var FailCount: Integer);
begin
  Inc(FailCount);
  // 每 1024 次冲突小睡 1ms（降噪）；其余每 16 次让出一次时间片
  if (FailCount and $3FF) = 0 then
    SysUtils.Sleep(1)
  else if (FailCount and $0F) = 0 then
    SysUtils.Sleep(0);
end;

function GetDefaultBackoff: IBackoffPolicy;
begin
  // 简单的惰性初始化（多线程下可能重复赋值，但相同语义，安全）
  if GDefaultBackoff = nil then
  begin
    {$IFDEF WINDOWS}
    GDefaultBackoff := TPausableBackoffPolicy.Create;
    {$ELSE}
    GDefaultBackoff := TPausableBackoffPolicy.Create;
    {$ENDIF}
  end;
  Result := GDefaultBackoff;
end;
function GetAggressiveBackoff: IBackoffPolicy;
begin
  if GAggressiveBackoff = nil then
    GAggressiveBackoff := TAggressiveBackoffPolicy.Create;
  Result := GAggressiveBackoff;
end;

procedure SetDefaultBackoff(const P: IBackoffPolicy);
begin
  GDefaultBackoff := P;
end;


procedure BackoffStep(var FailCount: Integer);
var P: IBackoffPolicy;
begin
  P := GetDefaultBackoff;
  P.Step(FailCount);
end;

end.

