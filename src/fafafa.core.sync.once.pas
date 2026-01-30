unit fafafa.core.sync.once;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│ fafafa.core.sync.once - 跨平台高性能一次性执行实现                        │
│                                                                             │
│ Copyright (c) 2024 fafafaStudio                                            │
│ All rights reserved.                                                       │
│                                                                             │
│ This source code is licensed under the MIT license found in the            │
│ LICENSE file in the root directory of this source tree.                    │
│                                                                             │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目:fafafa.core.sync.once - 跨平台高性能一次性执行实现

📖 概述:
  现代化、跨平台的 FreePascal 一次性执行实现,提供统一的 API 接口。

🔧 特性:
  • 跨平台支持:Windows、Linux、macOS、FreeBSD 等
  • 高性能实现:使用平台原生 API 和优化算法
  • 线程安全:支持多线程并发访问
  • 异常安全:自动资源管理和毒化状态处理
  • 现代语义:借鉴 Go sync.Once、Rust std::sync::Once 设计

⚠️  重要说明:
  一次性执行适用于初始化场景,确保某个操作在多线程环境中只被执行一次。
  失败的执行会导致毒化状态,需要使用 ExecuteForce 或创建新实例。

🧵 线程安全性:
  所有一次性执行操作都是线程安全的,支持多线程并发访问。

📜 声明:
  转发或用于个人/商业项目时,请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.once.base
  {$IFDEF WINDOWS}, fafafa.core.sync.once.windows{$ENDIF}
  {$IFDEF UNIX}, fafafa.core.sync.once.unix{$ENDIF};

type

  IOnce = fafafa.core.sync.once.base.IOnce;

  {$IFDEF WINDOWS}
  TOnce = fafafa.core.sync.once.windows.TOnce;
  {$ENDIF}

  {$IFDEF UNIX}
  TOnce = fafafa.core.sync.once.unix.TOnce;
  {$ENDIF}

// 创建平台特定的一次性执行实例(Go/Rust 风格:无状态构造)
function MakeOnce: IOnce; overload;

// 构造时传入回调的工厂函数(现代语言风格)
function MakeOnce(const AProc: TOnceProc): IOnce; overload;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload;
{$ENDIF}



implementation

{$IFDEF FAFAFA_CORE_OBJECT_POOL}
// Once对象池实现:减少内存分配开销
type
  TOncePool = class
  private
    FPool: array[0..15] of IOnce; // 小型对象池,16个实例
    FPoolMask: LongWord;          // 位掩码,标记可用实例
    {$IFDEF WINDOWS}
    FLock: TRTLCriticalSection;   // 池访问锁
    {$ELSE}
    FLock: TRTLCriticalSection;   // Unix也使用相同的锁类型
    {$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    function GetOnce: IOnce;
    procedure ReturnOnce(const AOnce: IOnce);
  end;

var
  GlobalOncePool: TOncePool;

constructor TOncePool.Create;
var
  i: Integer;
begin
  inherited Create;
  System.InitCriticalSection(FLock);
  FPoolMask := $FFFF; // 所有16位都设置为1,表示可用

  // 预分配池中的对象
  for i := 0 to High(FPool) do
  begin
    {$IFDEF UNIX}
    FPool[i] := fafafa.core.sync.once.unix.TOnce.Create;
    {$ENDIF}
    {$IFDEF WINDOWS}
    FPool[i] := fafafa.core.sync.once.windows.TOnce.Create;
    {$ENDIF}
  end;
end;

destructor TOncePool.Destroy;
var
  i: Integer;
begin
  // 清理池中的对象
  for i := 0 to High(FPool) do
    FPool[i] := nil;

  System.DoneCriticalSection(FLock);
  inherited Destroy;
end;

function TOncePool.GetOnce: IOnce;
var
  i: Integer;
  Mask: LongWord;
begin
  System.EnterCriticalSection(FLock);
  try
    // 查找第一个可用的对象
    if FPoolMask <> 0 then
    begin
      // 使用位操作快速找到第一个设置的位
      i := 0;
      Mask := FPoolMask;
      while (Mask and 1) = 0 do
      begin
        Mask := Mask shr 1;
        Inc(i);
      end;

      // 标记为已使用
      FPoolMask := FPoolMask and not (1 shl i);
      Result := FPool[i];
    end
    else
    begin
      // 池已满,创建新对象
      {$IFDEF UNIX}
      Result := fafafa.core.sync.once.unix.TOnce.Create;
      {$ENDIF}
      {$IFDEF WINDOWS}
      Result := fafafa.core.sync.once.windows.TOnce.Create;
      {$ENDIF}
    end;
  finally
    System.LeaveCriticalSection(FLock);
  end;
end;

procedure TOncePool.ReturnOnce(const AOnce: IOnce);
var
  i: Integer;
begin
  System.EnterCriticalSection(FLock);
  try
    // 查找对象在池中的位置
    for i := 0 to High(FPool) do
    begin
      if FPool[i] = AOnce then
      begin
        // 标记为可用
        FPoolMask := FPoolMask or (1 shl i);
        Break;
      end;
    end;
    // 如果不在池中,则忽略(让垃圾回收器处理)
  finally
    System.LeaveCriticalSection(FLock);
  end;
end;
{$ENDIF}

function MakeOnce: IOnce;
begin
  {$IFDEF FAFAFA_CORE_OBJECT_POOL}
  // 使用对象池减少内存分配
  Result := GlobalOncePool.GetOnce;
  {$ELSE}
  // 直接创建新对象
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create;
  {$ENDIF}
  {$ENDIF}
end;

function MakeOnce(const AProc: TOnceProc): IOnce;
begin
  {$IFDEF FAFAFA_CORE_OBJECT_POOL}
  // 注意:对象池版本需要重置对象状态,但Once对象通常是一次性的
  // 所以对于带参数的构造函数,暂时不使用对象池
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AProc);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AProc);
  {$ENDIF}
  {$ELSE}
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AProc);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AProc);
  {$ENDIF}
  {$ENDIF}
end;

function MakeOnce(const AMethod: TOnceMethod): IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AMethod);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AMethod);
  {$ENDIF}
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.once.unix.TOnce.Create(AAnonymousProc);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.once.windows.TOnce.Create(AAnonymousProc);
  {$ENDIF}
end;
{$ENDIF}



{$IFDEF FAFAFA_CORE_OBJECT_POOL}
initialization
  GlobalOncePool := TOncePool.Create;

finalization
  GlobalOncePool.Free;
{$ENDIF}

end.
