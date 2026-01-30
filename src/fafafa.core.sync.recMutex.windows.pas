unit fafafa.core.sync.recMutex.windows;

{
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│          ______   ______     ______   ______     ______   ______             │
│         /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            │
│         \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           │
│          \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          │
│           \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          │
│                                                                              │
│                                Studio                                        │
└──────────────────────────────────────────────────────────────────────────────┘

📦 项目：fafafa.core.sync.recMutex.windows - Windows 可重入互斥锁实现

📖 概述：
  基于 Windows Critical Section 的高性能可重入互斥锁实现，专为 Windows 系统优化。
  使用 CRITICAL_SECTION 结构提供原生的重入支持和自旋优化。

🔧 特性：
  • Windows 原生支持：Windows XP/Vista/7/8/10/11 及 Server 版本
  • Critical Section 实现：基于 CRITICAL_SECTION 和相关 Win32 API
  • 自旋计数优化：可配置的自旋等待减少内核切换开销
  • 零本地状态：完全依赖系统原生重入计数，无额外开销
  • 超时支持：使用 TryEnterCriticalSection 和计时器实现超时机制
  • 异常安全：RAII 模式确保异常情况下的锁释放

⚠️  重要说明：
  此实现专为 Windows 系统设计，依赖 Win32 API 和 CRITICAL_SECTION。
  自旋计数可显著提升多核系统性能，但需根据应用场景调整。

🧵 线程安全性：
  基于 Windows 内核同步原语，所有操作都是线程安全的。
  重入特性由系统内核保证，同一线程可安全多次获取锁。

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731

}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  Windows, SysUtils,
  fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base;

type

  {**
   * TRecMutex - Windows 平台可重入互斥锁实现
   *
   * @desc
   *   基于 Windows Critical Section 的可重入互斥锁实现。
   *   Critical Section 天然支持重入，性能优异，是 Windows 平台
   *   可重入互斥锁的最佳选择。
   *
   * @implementation
   *   - 使用 TRTLCriticalSection 作为底层实现
   *   - 支持自旋计数优化
   *   - 继承 TTryLock 获得三段式等待策略
   *   - 实现完整的 IRecMutex 接口
   *
   * @performance
   *   - Critical Section 是用户态锁，性能优异
   *   - 支持自旋计数，减少内核调用
   *   - 天然支持重入，无额外开销
   *   - 在无竞争情况下接近原子操作性能
   *
   * @thread_safety
   *   完全线程安全，支持多线程并发访问和重入。
   *}
  TRecMutex = class(TTryLock, IRecMutex)
  private
    FCS: TRTLCriticalSection;  // Windows Critical Section
  protected
    // 重写默认参数以适应可重入互斥锁的特性
    function GetDefaultTightSpin: UInt32; override;
    function GetDefaultBackOffSpin: UInt32; override;
    function GetDefaultBlockSpin: UInt32; override;
  public
    {**
     * Create - 创建可重入互斥锁（默认自旋计数）
     *
     * @desc
     *   使用默认自旋计数（4000）创建可重入互斥锁。
     *   这是推荐的创建方式，适用于大多数场景。
     *}
    constructor Create; overload;

    {**
     * Create - 创建带自定义自旋计数的可重入互斥锁
     *
     * @param ASpinCount 自旋计数，在进入内核等待前的自旋次数
     *
     * @desc
     *   创建带自定义自旋计数的可重入互斥锁。自旋计数可以
     *   显著提高短期锁竞争的性能。
     *
     * @spin_count_guide
     *   - 0: 禁用自旋，直接进入内核等待
     *   - 1000-4000: 适合一般应用（推荐）
     *   - 4000-8000: 适合高竞争场景
     *   - 8000+: 适合极高竞争或特殊优化场景
     *}
    constructor Create(ASpinCount: DWORD); overload;
    destructor Destroy; override;

    procedure Acquire; override;
    procedure Release; override;
    function TryAcquire: Boolean; override;

    {**
     * GetHandle - 获取底层 Critical Section 句柄
     *
     * @return Critical Section 的指针
     *
     * @desc
     *   返回底层 Critical Section 的指针，供高级用户
     *   或其他同步原语使用。
     *
     * @advanced_usage
     *   此方法主要用于：
     *   - 与条件变量等高级同步原语集成
     *   - 性能分析和调试
     *   - 底层系统编程
     *
     * @warning
     *   直接操作返回的句柄可能导致未定义行为，
     *   请确保了解 Critical Section 的使用规则。
     *}
    function GetHandle: Pointer;
  end;

{**
 * MakeRecMutex - 创建可重入互斥锁实例
 *
 * @return 可重入互斥锁接口实例
 *
 * @desc
 *   使用默认参数创建可重入互斥锁实例。
 *   这是推荐的创建方式。
 *}
function MakeRecMutex: IRecMutex;

{**
 * MakeRecMutex - 创建带自旋计数的可重入互斥锁实例
 *
 * @param ASpinCount 自旋计数
 * @return 可重入互斥锁接口实例
 *
 * @desc
 *   创建带自定义自旋计数的可重入互斥锁实例。
 *   允许针对特定场景进行性能优化。
 *}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex; overload;

implementation

uses
  fafafa.core.time.cpu;

function MakeRecMutex: IRecMutex;
begin
  Result := TRecMutex.Create;
end;

function MakeRecMutex(ASpinCount: DWORD): IRecMutex;
begin
  Result := TRecMutex.Create(ASpinCount);
end;

constructor TRecMutex.Create;
begin
  Create(4000); // 默认自旋计数
end;

constructor TRecMutex.Create(ASpinCount: DWORD);
begin
  inherited Create;

  // 尝试使用带自旋计数的初始化
  if (not InitializeCriticalSectionAndSpinCount(FCS, ASpinCount)) then
    InitializeCriticalSection(FCS); // 回退到标准初始化
end;

destructor TRecMutex.Destroy;
begin
  DeleteCriticalSection(FCS);
  inherited Destroy;
end;

function TRecMutex.GetDefaultTightSpin: UInt32;
begin
  // 可重入互斥锁通常持有时间较长，减少紧密自旋
  Result := 1000;
end;

function TRecMutex.GetDefaultBackOffSpin: UInt32;
begin
  // 适中的退避自旋
  Result := 100;
end;

function TRecMutex.GetDefaultBlockSpin: UInt32;
begin
  // 较少的阻塞自旋，更多依赖睡眠
  Result := 500;
end;

procedure TRecMutex.Acquire;
begin
  EnterCriticalSection(FCS);
end;

procedure TRecMutex.Release;
begin
  LeaveCriticalSection(FCS);
end;

function TRecMutex.TryAcquire: Boolean;
begin
  Result := TryEnterCriticalSection(FCS);
end;

function TRecMutex.GetHandle: Pointer;
begin
  Result := @FCS;
end;

end.

