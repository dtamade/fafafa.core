unit fafafa.core.sync.once.base;

{
  IOnce - Cross-platform once execution interface (base unit)

  Design goals:
  - Follow the same modular pattern as other sync primitives (e.g., mutex, barrier):
    define the interface in a dedicated *base* unit, keep factories/platform
    implementations in their own units.
  - Greatest common denominator API between Windows and Unix/Linux native once:
    * Windows:   InterlockedCompareExchange + CRITICAL_SECTION with exception recovery
    * Unix/POSIX: pthread_once_t (pthread_once) with system-level guarantees
  - Modern language semantics: Go sync.Once, Rust std::sync::Once, C++ std::once_flag

  Contract:
  - Execute() ensures the callback is called exactly once across all threads
  - First successful execution marks the once as "completed"
  - Failed execution (exception) marks the once as "poisoned"
  - Subsequent Execute() calls on completed once are no-ops
  - Subsequent Execute() calls on poisoned once throw exception (unless using ExecuteForce)
  - ExecuteForce() ignores poisoned state and allows re-execution

  Notes:
  - This interface does NOT inherit from ISynchronizable to avoid semantic confusion
  - Once is not a traditional lock and should not have Lock/Unlock semantics
  - Wait() provides Rust-style waiting for completion without execution
  - State queries allow inspection of current execution state
  - No Reset() functionality by design (matches Go/Rust/Java behavior)
}

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 一次性执行状�?=====
  TOnceState = (
    osNotStarted,   // 尚未开始执�?
    osInProgress,   // 正在执行�?
    osCompleted,    // 已完成执�?
    osPoisoned      // 毒化状态（执行时发生异常）
  );

  // ===== 回调函数类型 =====
  TOnceProc = procedure;
  TOnceMethod = procedure of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TOnceAnonymousProc = reference to procedure;
  {$ENDIF}

  // ===== 回调存储类型 =====
  TOnceCallbackType = (
    octNone,        // 无回�?
    octProc,        // 过程指针
    octMethod,      // 对象方法
    octAnonymous    // 匿名过程
  );

  // ===== 回调存储记录 =====
  TOnceCallback = record
    CallbackType: TOnceCallbackType;
    Proc: TOnceProc;
    Method: TOnceMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    AnonymousProc: TOnceAnonymousProc;
    {$ENDIF}
  end;



  // ===== 一次性执行接�?=====
  // 修复接口设计：IOnce继承ISynchronizable以保持架构一致�?
  // Once不是传统意义的锁，但作为同步原语应该继承基础接口
  IOnce = interface(ISynchronizable)
    ['{A1B2C3D4-E5F6-4789-9012-123456789ABC}']

    // 核心方法：执行回调（Go/Rust 风格�?
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



    // 等待机制（Rust 风格�?
    procedure Wait;
    procedure WaitForce;

    // 状态查询（属性风格，符合 Pascal 约定�?
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // 属性接�?
    property State: TOnceState read GetState;
    property Completed: Boolean read GetCompleted;
    property Poisoned: Boolean read GetPoisoned;

    // 注意：Reset 功能已移除，因为�?
    // 1. 并发安全问题：Reset 期间其他线程可能仍在快速路径中
    // 2. 语义不清晰：Reset 后的状态转换不明确
    // 3. 主流语言不提供：Go、Rust、Java 都不提供 Reset 功能
    // 如果需要重新执行，请创建新�?Once 实例
  end;

implementation

end.
