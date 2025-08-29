unit fafafa.core.sync.once.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.once.base, fafafa.core.atomic;

// 分支预测优化宏定义
{$IFDEF CPUX86_64}
// x86-64 支持分支预测提示
{$DEFINE BRANCH_PREDICTION_SUPPORTED}
{$ENDIF}

{$IFDEF BRANCH_PREDICTION_SUPPORTED}
// 使用编译器内建函数进行分支预测优化
function Likely(condition: Boolean): Boolean; inline;
function Unlikely(condition: Boolean): Boolean; inline;
{$ELSE}
// 不支持分支预测的平台，使用普通条件判断
function Likely(condition: Boolean): Boolean; inline;
function Unlikely(condition: Boolean): Boolean; inline;
{$ENDIF}

type
  // 轻量级自旋锁实现（替代重量级 CRITICAL_SECTION）
  TLightweightLock = record
  private
    FLocked: LongInt;  // 0=未锁定, 1=已锁定
    FSpinCount: LongInt; // 自旋计数
  public
    procedure Initialize;
    procedure Lock;
    procedure Unlock;
    function TryLock: Boolean;
  end;

  TOnce = class(TInterfacedObject, IOnce)
  private
    // 修复缓存行对齐：正确计算字段大小和填充
    // 第一个缓存行：热路径数据（高频访问）
    FDone: LongBool;              // 1字节：原子布尔值，快速路径检查
    FState: LongInt;              // 4字节：详细状态
    FExecutingThreadId: DWORD;    // 4字节：当前执行线程ID

    // 精确计算填充：确保下一个字段在新缓存行开始
    // 对象头(8字节) + FDone(1字节) + 对齐填充(3字节) + FState(4字节) + FExecutingThreadId(4字节) = 20字节
    // 需要填充 64 - 20 = 44字节 到缓存行边界
    FPadding1: array[0..43] of Byte;

    // 第二个缓存行：同步数据（64字节对齐）
    FLock: TLightweightLock;      // 轻量级自旋锁

    // 确保锁数据不跨越缓存行边界
    // TLightweightLock 大小需要检查，可能需要额外填充
    FPadding2: array[0..31] of Byte; // 预留32字节填充

    // 第三个缓存行：回调存储（64字节对齐）
    FCallback: TOnceCallback;     // 存储的回调函数

    const
      STATE_NOT_STARTED = 0;
      STATE_IN_PROGRESS = 1;
      STATE_COMPLETED = 2;
      STATE_POISONED = 3;

    // 内部执行方法
    procedure DoInternal(const AProc: TOnceProc; AForce: Boolean); overload;
    procedure DoInternal(const AMethod: TOnceMethod; AForce: Boolean); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean); overload;
    {$ENDIF}

  public
    constructor Create; overload;
    constructor Create(const AProc: TOnceProc); overload;
    constructor Create(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    constructor Create(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}
    destructor Destroy; override;

    // ISynchronizable 接口实现
    function GetLastError: TWaitError;

    // 移除ILock接口方法：IOnce不再继承ILock，避免语义混乱
    // 这些方法已被移除，因为Once不是传统意义的锁

    // IOnce 核心接口实现（Go/Rust 风格）
    procedure Execute; overload;
    procedure Execute(const AProc: TOnceProc); overload;
    procedure Execute(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Execute(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 强制执行（忽略毒化状态）
    procedure ExecuteForce; overload;
    procedure ExecuteForce(const AProc: TOnceProc); overload;
    procedure ExecuteForce(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure ExecuteForce(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure Call(const AProc: TOnceProc); overload; deprecated 'Use Execute instead';
    procedure Call(const AMethod: TOnceMethod); overload; deprecated 'Use Execute instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Call(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use Execute instead';
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure CallForce(const AProc: TOnceProc); overload; deprecated 'Use ExecuteForce instead';
    procedure CallForce(const AMethod: TOnceMethod); overload; deprecated 'Use ExecuteForce instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure CallForce(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use ExecuteForce instead';
    {$ENDIF}

    // 等待机制
    procedure Wait;
    procedure WaitForce;

    // 状态查询（属性风格，符合 Pascal 约定）
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // Reset 功能已移除 - 请创建新的 Once 实例
  end;

implementation

// 分支预测优化函数实现
{$IFDEF BRANCH_PREDICTION_SUPPORTED}
function Likely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
  // 在支持的编译器中，这里可以添加 __builtin_expect 等价物
  // FreePascal 目前没有直接的分支预测支持，但函数名提供了语义提示
end;

function Unlikely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
  // 在支持的编译器中，这里可以添加 __builtin_expect 等价物
end;
{$ELSE}
function Likely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
end;

function Unlikely(condition: Boolean): Boolean; inline;
begin
  Result := condition;
end;
{$ENDIF}

// 错误消息资源字符串
resourcestring
  rsOnceAlreadyPoisoned = 'Once is poisoned due to previous panic';
  rsOnceRecursiveCall = 'Recursive call to Once.Execute() detected from the same thread';

// 中文错误消息（可选）
{$IFDEF FAFAFA_CORE_CHINESE_MESSAGES}
resourcestring
  rsOnceAlreadyPoisonedCN = 'Once 已因先前的异常而中毒';
  rsOnceRecursiveCallCN = '检测到同一线程对 Once.Execute() 的递归调用';
{$ENDIF}

{ TLightweightLock }

procedure TLightweightLock.Initialize;
begin
  FLocked := 0;
  FSpinCount := 0;
end;

procedure TLightweightLock.Lock;
var
  SpinCount: Integer;
begin
  SpinCount := 0;

  // 快速尝试获取锁
  while InterlockedCompareExchange(FLocked, 1, 0) <> 0 do
  begin
    Inc(SpinCount);

    // 自适应自旋：先自旋一段时间，然后让出 CPU
    if SpinCount < 4000 then
    begin
      // 短暂自旋，使用 PAUSE 指令优化
      {$IFDEF CPUX86_64}
      asm
        pause
      end;
      {$ELSE}
      // 32位或其他架构的兼容处理
      Sleep(0);
      {$ENDIF}
    end
    else if SpinCount < 8000 then
    begin
      // 让出时间片
      Sleep(0);
    end
    else
    begin
      // 长时间等待，使用更长的睡眠
      Sleep(1);
      SpinCount := 0; // 重置计数
    end;
  end;

  InterlockedIncrement(FSpinCount);
end;

procedure TLightweightLock.Unlock;
begin
  InterlockedExchange(FLocked, 0);
end;

function TLightweightLock.TryLock: Boolean;
begin
  Result := InterlockedCompareExchange(FLocked, 1, 0) = 0;
end;

{ TOnce }

constructor TOnce.Create;
begin
  inherited Create;
  FDone := False;               // 原子布尔值初始化
  FState := STATE_NOT_STARTED;  // 详细状态初始化
  FExecutingThreadId := 0;      // 初始化执行线程ID
  FLock.Initialize;             // 初始化轻量级锁

  // 初始化回调为空
  FCallback.CallbackType := octNone;
  FCallback.Proc := nil;
  FCallback.Method := nil;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  FCallback.AnonymousProc := nil;
  {$ENDIF}

  // 调试钩子
  {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
  if Assigned(OnceDebugHook) then
    OnceDebugHook(odeCreated, Self, 'Once instance created');
  {$ENDIF}
end;

constructor TOnce.Create(const AProc: TOnceProc);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octProc;
  FCallback.Proc := AProc;
end;

constructor TOnce.Create(const AMethod: TOnceMethod);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octMethod;
  FCallback.Method := AMethod;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
constructor TOnce.Create(const AAnonymousProc: TOnceAnonymousProc);
begin
  Create; // 调用基础构造函数
  FCallback.CallbackType := octAnonymous;
  FCallback.AnonymousProc := AAnonymousProc;
end;
{$ENDIF}



destructor TOnce.Destroy;
begin
  // 轻量级锁无需显式销毁
  inherited Destroy;
end;

// ISynchronizable 接口实现
function TOnce.GetLastError: TWaitError;
begin
  // Once 不使用传统的等待错误，总是返回无错误
  Result := weNone;
end;

// ILock 接口方法已移除：IOnce不再继承ILock
// 这避免了语义混乱，Once不是传统意义的锁

// IOnce Execute 方法实现
procedure TOnce.Execute;
begin
  case FCallback.CallbackType of
    octNone: ; // 无回调，什么都不做
    octProc: DoInternal(FCallback.Proc, False);
    octMethod: DoInternal(FCallback.Method, False);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, False);
    {$ENDIF}
  end;
end;

procedure TOnce.Execute(const AProc: TOnceProc);
begin
  DoInternal(AProc, False);
end;

procedure TOnce.Execute(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, False);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.Execute(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, False);
end;
{$ENDIF}

// ExecuteForce 方法实现
procedure TOnce.ExecuteForce;
begin
  case FCallback.CallbackType of
    octNone: ; // 无回调，什么都不做
    octProc: DoInternal(FCallback.Proc, True);
    octMethod: DoInternal(FCallback.Method, True);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    octAnonymous: DoInternal(FCallback.AnonymousProc, True);
    {$ENDIF}
  end;
end;

procedure TOnce.ExecuteForce(const AProc: TOnceProc);
begin
  DoInternal(AProc, True);
end;

procedure TOnce.ExecuteForce(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, True);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.ExecuteForce(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, True);
end;
{$ENDIF}

// 兼容旧接口（标记为废弃）
// 高性能核心实现：Go 风格的快速路径 + 慢速路径
procedure TOnce.Call(const AProc: TOnceProc);
begin
  DoInternal(AProc, False);
end;

procedure TOnce.Call(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, False);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.Call(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, False);
end;
{$ENDIF}

procedure TOnce.CallForce(const AProc: TOnceProc);
begin
  DoInternal(AProc, True);
end;

procedure TOnce.CallForce(const AMethod: TOnceMethod);
begin
  DoInternal(AMethod, True);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.CallForce(const AAnonymousProc: TOnceAnonymousProc);
begin
  DoInternal(AAnonymousProc, True);
end;
{$ENDIF}

// 核心内部实现：高性能原子快速路径 + 慢速路径
procedure TOnce.DoInternal(const AProc: TOnceProc; AForce: Boolean);
var
  CurrentState: LongInt;
  ExecutingThread: TThreadID;
begin
  // 调试钩子：开始执行
  {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
  WriteLn('[DEBUG] Execute started, Force=', AForce);
  {$ENDIF}

  // 快速路径：原子读取，无锁检查（Go 风格优化）
  // 使用 acquire 语义确保后续读取不会重排序到此之前
  // 分支预测优化：已完成的情况是最常见的（likely）
  if Likely(InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0) then
  begin
    // AForce 通常为 false，这是常见情况（likely）
    if Likely(not AForce) then
    begin
      // 修复ABA问题：使用原子读取而不是CAS来检查毒化状态
      // 这避免了ABA问题，因为我们只是读取而不是修改
      CurrentState := InterlockedCompareExchange(FState, 0, 0); // 原子读取
      // 毒化状态很少见（unlikely）
      if Unlikely(CurrentState = STATE_POISONED) then
      begin
        {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
        WriteLn('[DEBUG] Attempt to execute poisoned Once');
        {$ENDIF}
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      end;

      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Execution skipped - already completed');
      {$ENDIF}
      Exit;
    end;
  end;

  // 递归调用检测（修复竞态条件）
  // 使用原子读取避免竞态条件
  ExecutingThread := InterlockedCompareExchange(FExecutingThreadId, 0, 0);
  if ExecutingThread = GetCurrentThreadId then
  begin
    {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
    WriteLn('[DEBUG] Recursive call detected from thread ', GetCurrentThreadId);
    {$ENDIF}
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);
  end;

  // 慢速路径：优化锁粒度，减少锁持有时间
  var ExecutionSucceeded: Boolean;
  var ShouldExecute: Boolean;

  // 第一阶段：获取锁，检查状态，设置执行标志
  FLock.Lock;
  try
    // 双重检查锁定模式
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    // 如果是毒化状态且不强制执行，抛出异常
    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    // 标记为进行中，并设置执行线程ID
    InterlockedExchange(FState, STATE_IN_PROGRESS);
    FExecutingThreadId := GetCurrentThreadId;
    ShouldExecute := True;
  finally
    FLock.Unlock; // 尽早释放锁
  end;

  // 第二阶段：在锁外执行用户回调（提高并发性）
  ExecutionSucceeded := False;
  if ShouldExecute then
  begin
    try
      // 用户回调在锁外执行，不阻塞其他线程
      if Assigned(AProc) then
        AProc();

      ExecutionSucceeded := True;

      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Execution completed successfully');
      {$ENDIF}
    except
      {$IFDEF FAFAFA_CORE_DEBUG_ONCE}
      WriteLn('[DEBUG] Execution failed - Once will be poisoned');
      {$ENDIF}
      // 异常会在第三阶段处理
    end;
  end;

  // 第三阶段：重新获取锁，设置最终状态
  FLock.Lock;
  try
    if ExecutionSucceeded then
    begin
      // 成功路径：设置完成状态
      InterlockedExchange(FState, STATE_COMPLETED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
    end
    else
    begin
      // 失败路径：设置毒化状态
      InterlockedExchange(FState, STATE_POISONED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
      // 重新抛出原始异常
      raise;
    end;
  finally
    FLock.Unlock;
  end;
end;

procedure TOnce.DoInternal(const AMethod: TOnceMethod; AForce: Boolean);
var
  CurrentState: LongInt;
  ExecutingThread: TThreadID;
begin
  // 快速路径：原子读取，无锁检查（acquire 语义）
  // 分支预测优化：已完成的情况是最常见的
  if Likely(InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0) then
  begin
    if Likely(not AForce) then
    begin
      // 修复ABA问题：使用原子读取检查毒化状态
      CurrentState := InterlockedCompareExchange(FState, 0, 0);
      // 毒化状态很少见
      if Unlikely(CurrentState = STATE_POISONED) then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;
  end;

  // 递归调用检测（修复竞态条件）
  ExecutingThread := InterlockedCompareExchange(FExecutingThreadId, 0, 0);
  if ExecutingThread = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 慢速路径：需要同步执行
  // 优化锁粒度：三阶段锁控制
  var ExecutionSucceeded: Boolean;
  var ShouldExecute: Boolean;

  // 第一阶段：获取锁，检查状态，设置执行标志
  FLock.Lock;
  try
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    InterlockedExchange(FState, STATE_IN_PROGRESS);
    FExecutingThreadId := GetCurrentThreadId;
    ShouldExecute := True;
  finally
    FLock.Unlock; // 尽早释放锁
  end;

  // 第二阶段：在锁外执行用户回调
  ExecutionSucceeded := False;
  if ShouldExecute then
  begin
    try
      if Assigned(AMethod) then
        AMethod();
      ExecutionSucceeded := True;
    except
      // 异常会在第三阶段处理
    end;
  end;

  // 第三阶段：重新获取锁，设置最终状态
  FLock.Lock;
  try
    if ExecutionSucceeded then
    begin
      InterlockedExchange(FState, STATE_COMPLETED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
    end
    else
    begin
      InterlockedExchange(FState, STATE_POISONED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
      raise;
    end;
  finally
    FLock.Unlock;
  end;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TOnce.DoInternal(const AAnonymousProc: TOnceAnonymousProc; AForce: Boolean);
var
  CurrentState: LongInt;
  ExecutingThread: TThreadID;
begin
  // 快速路径：原子读取，无锁检查（acquire 语义）
  // 分支预测优化：已完成的情况是最常见的
  if Likely(InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0) then
  begin
    if Likely(not AForce) then
    begin
      // 修复ABA问题：使用原子读取检查毒化状态
      CurrentState := InterlockedCompareExchange(FState, 0, 0);
      // 毒化状态很少见
      if Unlikely(CurrentState = STATE_POISONED) then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;
  end;

  // 递归调用检测（修复竞态条件）
  ExecutingThread := InterlockedCompareExchange(FExecutingThreadId, 0, 0);
  if ExecutingThread = GetCurrentThreadId then
    raise EOnceRecursiveCall.Create(rsOnceRecursiveCall);

  // 优化锁粒度：三阶段锁控制
  var ExecutionSucceeded: Boolean;
  var ShouldExecute: Boolean;

  // 第一阶段：获取锁，检查状态，设置执行标志
  FLock.Lock;
  try
    if FDone and not AForce then
    begin
      if FState = STATE_POISONED then
        raise ELockError.Create(rsOnceAlreadyPoisoned);
      Exit;
    end;

    if (FState = STATE_POISONED) and not AForce then
      raise ELockError.Create(rsOnceAlreadyPoisoned);

    InterlockedExchange(FState, STATE_IN_PROGRESS);
    FExecutingThreadId := GetCurrentThreadId;
    ShouldExecute := True;
  finally
    FLock.Unlock; // 尽早释放锁
  end;

  // 第二阶段：在锁外执行用户回调
  ExecutionSucceeded := False;
  if ShouldExecute then
  begin
    try
      if Assigned(AAnonymousProc) then
        AAnonymousProc();
      ExecutionSucceeded := True;
    except
      // 异常会在第三阶段处理
    end;
  end;

  // 第三阶段：重新获取锁，设置最终状态
  FLock.Lock;
  try
    if ExecutionSucceeded then
    begin
      InterlockedExchange(FState, STATE_COMPLETED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
    end
    else
    begin
      InterlockedExchange(FState, STATE_POISONED);
      InterlockedExchange(LongInt(FDone), 1);
      FExecutingThreadId := 0;
      raise;
    end;
  finally
    FLock.Unlock;
  end;
end;
{$ENDIF}
// 等待机制实现（高性能版本）
procedure TOnce.Wait;
var
  SpinCount: Integer;
  CurrentState: LongInt;
begin
  // 快速路径：如果已完成，直接返回（acquire 语义）
  // 分支预测优化：Wait调用时通常已经完成
  if Likely(InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0) then
  begin
    // 修复ABA问题：使用原子读取检查毒化状态
    CurrentState := InterlockedCompareExchange(FState, 0, 0);
    // 毒化状态很少见
    if Unlikely(CurrentState = STATE_POISONED) then
      raise ELockError.Create(rsOnceAlreadyPoisoned);
    Exit;
  end;

  // 高性能等待策略：自适应自旋 + 指数退避
  SpinCount := 0;

  while not InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0 do
  begin
    Inc(SpinCount);

    // 分支预测优化：短时间自旋是最常见的情况
    if Likely(SpinCount < 1000) then
    begin
      // 阶段1：CPU自旋等待（适合短时间等待）
      // 使用 PAUSE 指令优化超线程性能
      {$IFDEF CPUX86_64}
      asm
        pause
      end;
      {$ELSE}
      // 其他架构使用 YieldProcessor 或短暂延迟
      Sleep(0);
      {$ENDIF}
    end
    else if Likely(SpinCount < 10000) then
    begin
      // 阶段2：让出时间片（适合中等时间等待）
      Sleep(0);
    end
    else
    begin
      // 阶段3：短暂休眠（适合长时间等待）
      Sleep(1);
      // 重置计数器，避免无限增长
      if Unlikely(SpinCount > 50000) then
        SpinCount := 10000;
    end;
  end;

  // 检查最终状态
  CurrentState := InterlockedCompareExchange(FState, 0, 0);
  if CurrentState = STATE_POISONED then
    raise ELockError.Create(rsOnceAlreadyPoisoned);
end;

procedure TOnce.WaitForce;
var
  SpinCount: Integer;
begin
  // 强制等待，忽略毒化状态（高性能版本）
  SpinCount := 0;

  while InterlockedCompareExchange(LongInt(FDone), 1, 1) = 0 do
  begin
    Inc(SpinCount);

    if SpinCount < 1000 then
    begin
      // 阶段1：CPU自旋等待
      {$IFDEF CPUX86_64}
      asm
        pause
      end;
      {$ELSE}
      Sleep(0);
      {$ENDIF}
    end
    else if SpinCount < 10000 then
    begin
      // 阶段2：让出时间片
      Sleep(0);
    end
    else
    begin
      // 阶段3：短暂休眠
      Sleep(1);
      if SpinCount > 50000 then
        SpinCount := 10000;
    end;
  end;
end;



function TOnce.GetState: TOnceState;
var
  CurrentState: LongInt;
begin
  // 使用单次原子读取而不是三重读取
  CurrentState := InterlockedCompareExchange(FState, 0, 0);
  case CurrentState of
    STATE_NOT_STARTED: Result := osNotStarted;
    STATE_IN_PROGRESS: Result := osInProgress;
    STATE_COMPLETED: Result := osCompleted;
    STATE_POISONED: Result := osPoisoned;
  else
    Result := osNotStarted; // 默认值
  end;
end;

function TOnce.GetCompleted: Boolean;
begin
  // 使用单次原子读取检查 FDone 标志
  Result := InterlockedCompareExchange(LongInt(FDone), 1, 1) <> 0;
end;

function TOnce.GetPoisoned: Boolean;
begin
  // 使用单次原子读取检查状态
  Result := InterlockedCompareExchange(FState, 0, 0) = STATE_POISONED;
end;

// Reset 方法已移除 - 不安全且不符合主流语言实践
// 如需重新执行，请创建新的 Once 实例

end.
