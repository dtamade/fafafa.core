unit fafafa.core.sync.builder;

{**
 * fafafa.core.sync.builder - 同步原语 Builder 模式
 *
 * @desc
 *   提供流式 API 来配置和创建同步原语实例。
 *   遵循 Rust/Java Builder 模式设计。
 *
 * @features
 *   - MutexBuilder: 互斥锁构建器
 *   - SemBuilder: 信号量构建器
 *   - RWLockBuilder: 读写锁构建器
 *   - CondVarBuilder: 条件变量构建器
 *   - BarrierBuilder: 屏障构建器
 *   - OnceBuilder: 一次性执行构建器
 *
 * @usage
 *   var Mutex := MutexBuilder.Build;
 *   var Sem := SemBuilder.WithMaxCount(10).WithInitialCount(5).Build;
 *   var RWLock := RWLockBuilder.Build;
 *   var CondVar := CondVarBuilder.Build;
 *   var Barrier := BarrierBuilder.WithParticipantCount(4).Build;
 *   var Once := OnceBuilder.WithCallback(@MyProc).Build;
 *
 * @author fafafaStudio
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.mutex,
  fafafa.core.sync.sem,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.rwlock.base,
  fafafa.core.sync.condvar,
  fafafa.core.sync.condvar.base,
  fafafa.core.sync.barrier,
  fafafa.core.sync.barrier.base,
  fafafa.core.sync.once,
  fafafa.core.sync.once.base,
  fafafa.core.sync.event,
  fafafa.core.sync.event.base,
  fafafa.core.sync.waitgroup,
  fafafa.core.sync.waitgroup.base,
  fafafa.core.sync.latch,
  fafafa.core.sync.latch.base,
  // Phase 2: 新增 Builder 所需
  fafafa.core.sync.spin,
  fafafa.core.sync.parker,
  fafafa.core.sync.recMutex;

type

  {**
   * TMutexBuilder - 互斥锁构建器
   *
   * @desc
   *   流式 API 用于创建 IMutex 实例。
   *   当前支持默认配置，未来可扩展更多选项。
   *
   * @usage
   *   var Mutex := MutexBuilder.Build;
   *}
  TMutexBuilder = record
  public
    {**
     * Build - 创建互斥锁实例
     *
     * @return IMutex 互斥锁接口
     *}
    function Build: IMutex;
  end;

  {**
   * TSemBuilder - 信号量构建器
   *
   * @desc
   *   流式 API 用于配置和创建 ISem 实例。
   *   支持配置最大计数和初始计数。
   *
   * @usage
   *   var Sem := SemBuilder.WithMaxCount(10).WithInitialCount(5).Build;
   *}
  TSemBuilder = record
  private
    FMaxCount: Integer;
    FInitialCount: Integer;
    FInitialized: Boolean;
  public
    {**
     * WithMaxCount - 设置最大许可数
     *
     * @param AMaxCount 最大许可数（必须 > 0）
     * @return Self 支持链式调用
     *}
    function WithMaxCount(AMaxCount: Integer): TSemBuilder;

    {**
     * WithInitialCount - 设置初始许可数
     *
     * @param AInitialCount 初始许可数（必须 >= 0 且 <= MaxCount）
     * @return Self 支持链式调用
     *}
    function WithInitialCount(AInitialCount: Integer): TSemBuilder;

    {**
     * Build - 创建信号量实例
     *
     * @return ISem 信号量接口
     *
     * @remark
     *   如果未设置 MaxCount，默认为 1（二元信号量）。
     *   如果未设置 InitialCount，默认等于 MaxCount。
     *}
    function Build: ISem;
  end;

  {**
   * TRWLockBuilder - 读写锁构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IRWLock 实例。
   *   支持各种配置选项：写者优先、公平模式、最大读者数等。
   *
   * @usage
   *   var RWLock := RWLockBuilder.WithWriterPriority.WithMaxReaders(100).Build;
   *}
  TRWLockBuilder = record
  private
    FWriterPriority: Boolean;
    FFairMode: Boolean;
    FMaxReaders: Integer;
    FSpinCount: Integer;
    FInitialized: Boolean;
  public
    {**
     * WithWriterPriority - 启用写者优先模式
     *
     * @return Self 支持链式调用
     *}
    function WithWriterPriority: TRWLockBuilder;

    {**
     * WithFairMode - 启用公平模式 (FIFO)
     *
     * @return Self 支持链式调用
     *}
    function WithFairMode: TRWLockBuilder;

    {**
     * WithMaxReaders - 设置最大读者数量
     *
     * @param AMaxReaders 最大读者数量
     * @return Self 支持链式调用
     *}
    function WithMaxReaders(AMaxReaders: Integer): TRWLockBuilder;

    {**
     * WithSpinCount - 设置自旋次数
     *
     * @param ASpinCount 自旋次数
     * @return Self 支持链式调用
     *}
    function WithSpinCount(ASpinCount: Integer): TRWLockBuilder;

    {**
     * Build - 创建读写锁实例
     *
     * @return IRWLock 读写锁接口
     *}
    function Build: IRWLock;
  end;

  {**
   * TCondVarBuilder - 条件变量构建器
   *
   * @desc
   *   流式 API 用于创建 ICondVar 实例。
   *   当前支持默认配置，未来可扩展更多选项。
   *
   * @usage
   *   var CondVar := CondVarBuilder.Build;
   *}
  TCondVarBuilder = record
  public
    {**
     * Build - 创建条件变量实例
     *
     * @return ICondVar 条件变量接口
     *}
    function Build: ICondVar;
  end;

  {**
   * TBarrierBuilder - 屏障构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IBarrier 实例。
   *   支持设置参与者数量。
   *
   * @usage
   *   var Barrier := BarrierBuilder.WithParticipantCount(4).Build;
   *}
  TBarrierBuilder = record
  private
    FParticipantCount: Integer;
    FInitialized: Boolean;
  public
    {**
     * WithParticipantCount - 设置参与者数量
     *
     * @param ACount 参与者数量（必须 > 0）
     * @return Self 支持链式调用
     *}
    function WithParticipantCount(ACount: Integer): TBarrierBuilder;

    {**
     * Build - 创建屏障实例
     *
     * @return IBarrier 屏障接口
     *
     * @remark
     *   如果未设置参与者数量，默认为 2。
     *}
    function Build: IBarrier;
  end;

  {**
   * TOnceBuilder - 一次性执行构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IOnce 实例。
   *   支持预设回调函数。
   *
   * @usage
   *   var Once := OnceBuilder.Build;
   *   var Once := OnceBuilder.WithCallback(@MyProc).Build;
   *}
  TOnceBuilder = record
  private
    FCallback: TOnceCallback;
    FHasCallback: Boolean;
  public
    {**
     * WithCallback - 设置回调过程
     *
     * @param AProc 过程指针
     * @return Self 支持链式调用
     *}
    function WithCallback(const AProc: TOnceProc): TOnceBuilder; overload;

    {**
     * WithCallback - 设置回调方法
     *
     * @param AMethod 对象方法
     * @return Self 支持链式调用
     *}
    function WithCallback(const AMethod: TOnceMethod): TOnceBuilder; overload;

    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    {**
     * WithCallback - 设置匿名回调
     *
     * @param AAnonymousProc 匿名过程
     * @return Self 支持链式调用
     *}
    function WithCallback(const AAnonymousProc: TOnceAnonymousProc): TOnceBuilder; overload;
    {$ENDIF}

    {**
     * Build - 创建一次性执行实例
     *
     * @return IOnce 一次性执行接口
     *}
    function Build: IOnce;
  end;

  {**
   * TEventBuilder - 事件构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IEvent 实例。
   *   支持配置手动重置和初始状态。
   *
   * @usage
   *   var Event := EventBuilder.WithManualReset.Build;
   *   var Event := EventBuilder.WithInitialState(True).Build;
   *}
  TEventBuilder = record
  private
    FManualReset: Boolean;
    FInitialState: Boolean;
    FInitialized: Boolean;
  public
    {**
     * WithManualReset - 设置为手动重置模式
     *
     * @return Self 支持链式调用
     *}
    function WithManualReset: TEventBuilder;

    {**
     * WithAutoReset - 设置为自动重置模式（默认）
     *
     * @return Self 支持链式调用
     *}
    function WithAutoReset: TEventBuilder;

    {**
     * WithInitialState - 设置初始信号状态
     *
     * @param ASignaled True 为信号状态，False 为非信号状态
     * @return Self 支持链式调用
     *}
    function WithInitialState(ASignaled: Boolean): TEventBuilder;

    {**
     * Build - 创建事件实例
     *
     * @return IEvent 事件接口
     *}
    function Build: IEvent;
  end;

  {**
   * TWaitGroupBuilder - 等待组构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IWaitGroup 实例。
   *   支持配置初始计数。
   *
   * @usage
   *   var WG := WaitGroupBuilder.Build;
   *   var WG := WaitGroupBuilder.WithInitialCount(5).Build;
   *}
  TWaitGroupBuilder = record
  private
    FInitialCount: Integer;
    FInitialized: Boolean;
  public
    {**
     * WithInitialCount - 设置初始计数
     *
     * @param ACount 初始计数值（>= 0）
     * @return Self 支持链式调用
     *}
    function WithInitialCount(ACount: Integer): TWaitGroupBuilder;

    {**
     * Build - 创建等待组实例
     *
     * @return IWaitGroup 等待组接口
     *}
    function Build: IWaitGroup;
  end;

  {**
   * TLatchBuilder - 倒计数门板构建器
   *
   * @desc
   *   流式 API 用于配置和创建 ILatch 实例。
   *   必须指定计数值。
   *
   * @usage
   *   var Latch := LatchBuilder.WithCount(5).Build;
   *}
  TLatchBuilder = record
  private
    FCount: Integer;
    FInitialized: Boolean;
  public
    {**
     * WithCount - 设置计数值
     *
     * @param ACount 计数值（必须 > 0）
     * @return Self 支持链式调用
     *}
    function WithCount(ACount: Integer): TLatchBuilder;

    {**
     * Build - 创建倒计数门板实例
     *
     * @return ILatch 倒计数门板接口
     *
     * @remark
     *   如果未设置 Count，默认为 1。
     *}
    function Build: ILatch;
  end;

  {**
   * TSpinBuilder - 自旋锁构建器
   *
   * @desc
   *   流式 API 用于创建 ISpin 实例。
   *   当前支持默认配置。
   *
   * @usage
   *   var Spin := SpinBuilder.Build;
   *}
  TSpinBuilder = record
  public
    {**
     * Build - 创建自旋锁实例
     *
     * @return ISpin 自旋锁接口
     *}
    function Build: ISpin;
  end;

  {**
   * TParkerBuilder - Parker 构建器
   *
   * @desc
   *   流式 API 用于创建 IParker 实例。
   *   当前支持默认配置。
   *
   * @usage
   *   var Parker := ParkerBuilder.Build;
   *}
  TParkerBuilder = record
  public
    {**
     * Build - 创建 Parker 实例
     *
     * @return IParker Parker 接口
     *}
    function Build: IParker;
  end;

  {**
   * TRecMutexBuilder - 可重入互斥锁构建器
   *
   * @desc
   *   流式 API 用于配置和创建 IRecMutex 实例。
   *   Windows 平台支持配置 SpinCount。
   *
   * @usage
   *   var RecMutex := RecMutexBuilder.Build;
   *   var RecMutex := RecMutexBuilder.WithSpinCount(4000).Build; // Windows only
   *}
  TRecMutexBuilder = record
  private
    {$IFDEF WINDOWS}
    FSpinCount: DWORD;
    FHasSpinCount: Boolean;
    {$ENDIF}
  public
    {$IFDEF WINDOWS}
    {**
     * WithSpinCount - 设置自旋计数 (Windows only)
     *
     * @param ASpinCount 自旋计数
     * @return Self 支持链式调用
     *}
    function WithSpinCount(ASpinCount: DWORD): TRecMutexBuilder;
    {$ENDIF}

    {**
     * Build - 创建可重入互斥锁实例
     *
     * @return IRecMutex 可重入互斥锁接口
     *}
    function Build: IRecMutex;
  end;

{**
 * MutexBuilder - 获取互斥锁构建器
 *
 * @return TMutexBuilder 互斥锁构建器实例
 *}
function MutexBuilder: TMutexBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SemBuilder - 获取信号量构建器
 *
 * @return TSemBuilder 信号量构建器实例（默认配置）
 *}
function SemBuilder: TSemBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * RWLockBuilder - 获取读写锁构建器
 *
 * @return TRWLockBuilder 读写锁构建器实例
 *}
function RWLockBuilder: TRWLockBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * CondVarBuilder - 获取条件变量构建器
 *
 * @return TCondVarBuilder 条件变量构建器实例
 *}
function CondVarBuilder: TCondVarBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * BarrierBuilder - 获取屏障构建器
 *
 * @return TBarrierBuilder 屏障构建器实例
 *}
function BarrierBuilder: TBarrierBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * OnceBuilder - 获取一次性执行构建器
 *
 * @return TOnceBuilder 一次性执行构建器实例
 *}
function OnceBuilder: TOnceBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * EventBuilder - 获取事件构建器
 *
 * @return TEventBuilder 事件构建器实例
 *}
function EventBuilder: TEventBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * WaitGroupBuilder - 获取等待组构建器
 *
 * @return TWaitGroupBuilder 等待组构建器实例
 *}
function WaitGroupBuilder: TWaitGroupBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * LatchBuilder - 获取倒计数门板构建器
 *
 * @return TLatchBuilder 倒计数门板构建器实例
 *}
function LatchBuilder: TLatchBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * SpinBuilder - 获取自旋锁构建器
 *
 * @return TSpinBuilder 自旋锁构建器实例
 *}
function SpinBuilder: TSpinBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * ParkerBuilder - 获取 Parker 构建器
 *
 * @return TParkerBuilder Parker 构建器实例
 *}
function ParkerBuilder: TParkerBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

{**
 * RecMutexBuilder - 获取可重入互斥锁构建器
 *
 * @return TRecMutexBuilder 可重入互斥锁构建器实例
 *}
function RecMutexBuilder: TRecMutexBuilder; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}

implementation

{ Global Builder Factory Functions }

function MutexBuilder: TMutexBuilder;
begin
  // TMutexBuilder 是值类型，无需初始化
  Result := Default(TMutexBuilder);
end;

function SemBuilder: TSemBuilder;
begin
  Result := Default(TSemBuilder);
  Result.FMaxCount := 1;      // 默认：二元信号量
  Result.FInitialCount := 1;  // 默认：满的
  Result.FInitialized := True;
end;

function RWLockBuilder: TRWLockBuilder;
begin
  Result := Default(TRWLockBuilder);
end;

function CondVarBuilder: TCondVarBuilder;
begin
  Result := Default(TCondVarBuilder);
end;

function BarrierBuilder: TBarrierBuilder;
begin
  Result := Default(TBarrierBuilder);
  Result.FParticipantCount := 2;  // 默认：2个参与者（最小合理值）
  Result.FInitialized := False;
end;

function OnceBuilder: TOnceBuilder;
begin
  Result := Default(TOnceBuilder);
  Result.FHasCallback := False;
end;

function EventBuilder: TEventBuilder;
begin
  Result := Default(TEventBuilder);
  Result.FManualReset := False;  // 默认自动重置
  Result.FInitialState := False; // 默认未信号
  Result.FInitialized := False;
end;

function WaitGroupBuilder: TWaitGroupBuilder;
begin
  Result := Default(TWaitGroupBuilder);
  Result.FInitialCount := 0;  // 默认初始计数为 0
  Result.FInitialized := False;
end;

function LatchBuilder: TLatchBuilder;
begin
  Result := Default(TLatchBuilder);
  Result.FCount := 1;  // 默认计数为 1
  Result.FInitialized := False;
end;

{ TMutexBuilder }

function TMutexBuilder.Build: IMutex;
begin
  Result := fafafa.core.sync.mutex.MakeMutex;
end;

{ TSemBuilder }

function TSemBuilder.WithMaxCount(AMaxCount: Integer): TSemBuilder;
begin
  Result := Self;
  Result.FMaxCount := AMaxCount;
  // 如果 InitialCount 还没有设置，或者大于新的 MaxCount，调整它
  if (not FInitialized) or (Result.FInitialCount > AMaxCount) then
    Result.FInitialCount := AMaxCount;
  Result.FInitialized := True;
end;

function TSemBuilder.WithInitialCount(AInitialCount: Integer): TSemBuilder;
begin
  Result := Self;
  Result.FInitialCount := AInitialCount;
  Result.FInitialized := True;
end;

function TSemBuilder.Build: ISem;
var
  LMaxCount, LInitialCount: Integer;
begin
  // 获取配置值
  if FInitialized then
  begin
    LMaxCount := FMaxCount;
    LInitialCount := FInitialCount;
  end
  else
  begin
    // 未初始化时使用默认值
    LMaxCount := 1;
    LInitialCount := 1;
  end;

  // 参数验证
  if LMaxCount <= 0 then
    LMaxCount := 1;
  if LInitialCount < 0 then
    LInitialCount := 0;
  if LInitialCount > LMaxCount then
    LInitialCount := LMaxCount;

  Result := fafafa.core.sync.sem.MakeSem(LInitialCount, LMaxCount);
end;

{ TRWLockBuilder }

function TRWLockBuilder.WithWriterPriority: TRWLockBuilder;
begin
  Result := Self;
  Result.FWriterPriority := True;
  Result.FInitialized := True;
end;

function TRWLockBuilder.WithFairMode: TRWLockBuilder;
begin
  Result := Self;
  Result.FFairMode := True;
  Result.FInitialized := True;
end;

function TRWLockBuilder.WithMaxReaders(AMaxReaders: Integer): TRWLockBuilder;
begin
  Result := Self;
  Result.FMaxReaders := AMaxReaders;
  Result.FInitialized := True;
end;

function TRWLockBuilder.WithSpinCount(ASpinCount: Integer): TRWLockBuilder;
begin
  Result := Self;
  Result.FSpinCount := ASpinCount;
  Result.FInitialized := True;
end;

function TRWLockBuilder.Build: IRWLock;
var
  LOptions: TRWLockOptions;
begin
  if FInitialized then
  begin
    // 使用自定义配置
    LOptions := DefaultRWLockOptions;
    LOptions.WriterPriority := FWriterPriority;
    LOptions.FairMode := FFairMode;
    if FMaxReaders > 0 then
      LOptions.MaxReaders := FMaxReaders;
    if FSpinCount > 0 then
      LOptions.SpinCount := FSpinCount;
    Result := fafafa.core.sync.rwlock.MakeRWLock(LOptions);
  end
  else
    // 使用默认配置
    Result := fafafa.core.sync.rwlock.MakeRWLock;
end;

{ TCondVarBuilder }

function TCondVarBuilder.Build: ICondVar;
begin
  Result := fafafa.core.sync.condvar.MakeCondVar;
end;

{ TBarrierBuilder }

function TBarrierBuilder.WithParticipantCount(ACount: Integer): TBarrierBuilder;
begin
  Result := Self;
  if ACount > 0 then
    Result.FParticipantCount := ACount
  else
    Result.FParticipantCount := 2;  // 无效值时使用默认值
  Result.FInitialized := True;
end;

function TBarrierBuilder.Build: IBarrier;
var
  LCount: Integer;
begin
  if FInitialized then
    LCount := FParticipantCount
  else
    LCount := 2;  // 默认2个参与者

  // 确保参与者数量有效
  if LCount <= 0 then
    LCount := 2;

  Result := fafafa.core.sync.barrier.MakeBarrier(LCount);
end;

{ TOnceBuilder }

function TOnceBuilder.WithCallback(const AProc: TOnceProc): TOnceBuilder;
begin
  Result := Self;
  Result.FCallback.CallbackType := octProc;
  Result.FCallback.Proc := AProc;
  Result.FHasCallback := True;
end;

function TOnceBuilder.WithCallback(const AMethod: TOnceMethod): TOnceBuilder;
begin
  Result := Self;
  Result.FCallback.CallbackType := octMethod;
  Result.FCallback.Method := AMethod;
  Result.FHasCallback := True;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function TOnceBuilder.WithCallback(const AAnonymousProc: TOnceAnonymousProc): TOnceBuilder;
begin
  Result := Self;
  Result.FCallback.CallbackType := octAnonymous;
  Result.FCallback.AnonymousProc := AAnonymousProc;
  Result.FHasCallback := True;
end;
{$ENDIF}

function TOnceBuilder.Build: IOnce;
begin
  if FHasCallback then
  begin
    case FCallback.CallbackType of
      octProc:
        Result := fafafa.core.sync.once.MakeOnce(FCallback.Proc);
      octMethod:
        Result := fafafa.core.sync.once.MakeOnce(FCallback.Method);
      {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
      octAnonymous:
        Result := fafafa.core.sync.once.MakeOnce(FCallback.AnonymousProc);
      {$ENDIF}
    else
      Result := fafafa.core.sync.once.MakeOnce;
    end;
  end
  else
    Result := fafafa.core.sync.once.MakeOnce;
end;

{ TEventBuilder }

function TEventBuilder.WithManualReset: TEventBuilder;
begin
  Result := Self;
  Result.FManualReset := True;
  Result.FInitialized := True;
end;

function TEventBuilder.WithAutoReset: TEventBuilder;
begin
  Result := Self;
  Result.FManualReset := False;
  Result.FInitialized := True;
end;

function TEventBuilder.WithInitialState(ASignaled: Boolean): TEventBuilder;
begin
  Result := Self;
  Result.FInitialState := ASignaled;
  Result.FInitialized := True;
end;

function TEventBuilder.Build: IEvent;
begin
  Result := fafafa.core.sync.event.MakeEvent(FManualReset, FInitialState);
end;

{ TWaitGroupBuilder }

function TWaitGroupBuilder.WithInitialCount(ACount: Integer): TWaitGroupBuilder;
begin
  Result := Self;
  if ACount >= 0 then
    Result.FInitialCount := ACount
  else
    Result.FInitialCount := 0;
  Result.FInitialized := True;
end;

function TWaitGroupBuilder.Build: IWaitGroup;
var
  WG: IWaitGroup;
begin
  WG := fafafa.core.sync.waitgroup.MakeWaitGroup;
  if FInitialized and (FInitialCount > 0) then
    WG.Add(FInitialCount);
  Result := WG;
end;

{ TLatchBuilder }

function TLatchBuilder.WithCount(ACount: Integer): TLatchBuilder;
begin
  Result := Self;
  if ACount > 0 then
    Result.FCount := ACount
  else
    Result.FCount := 1;  // 无效值时使用默认值
  Result.FInitialized := True;
end;

function TLatchBuilder.Build: ILatch;
var
  LCount: Integer;
begin
  if FInitialized then
    LCount := FCount
  else
    LCount := 1;  // 默认计数为 1

  // 确保计数有效
  if LCount <= 0 then
    LCount := 1;

  Result := fafafa.core.sync.latch.MakeLatch(LCount);
end;

{ TSpinBuilder }

function TSpinBuilder.Build: ISpin;
begin
  Result := fafafa.core.sync.spin.MakeSpin;
end;

{ TParkerBuilder }

function TParkerBuilder.Build: IParker;
begin
  Result := fafafa.core.sync.parker.MakeParker;
end;

{ TRecMutexBuilder }

{$IFDEF WINDOWS}
function TRecMutexBuilder.WithSpinCount(ASpinCount: DWORD): TRecMutexBuilder;
begin
  Result := Self;
  Result.FSpinCount := ASpinCount;
  Result.FHasSpinCount := True;
end;
{$ENDIF}

function TRecMutexBuilder.Build: IRecMutex;
begin
  {$IFDEF WINDOWS}
  if FHasSpinCount then
    Result := fafafa.core.sync.recMutex.MakeRecMutex(FSpinCount)
  else
    Result := fafafa.core.sync.recMutex.MakeRecMutex;
  {$ELSE}
  Result := fafafa.core.sync.recMutex.MakeRecMutex;
  {$ENDIF}
end;

{ Builder Factory Functions - New }

function SpinBuilder: TSpinBuilder;
begin
  Result := Default(TSpinBuilder);
end;

function ParkerBuilder: TParkerBuilder;
begin
  Result := Default(TParkerBuilder);
end;

function RecMutexBuilder: TRecMutexBuilder;
begin
  Result := Default(TRecMutexBuilder);
  {$IFDEF WINDOWS}
  Result.FHasSpinCount := False;
  {$ENDIF}
end;

end.
