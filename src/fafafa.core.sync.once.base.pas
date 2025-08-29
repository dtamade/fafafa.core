unit fafafa.core.sync.once.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 一次性执行状态 =====
  TOnceState = (
    osNotStarted,   // 尚未开始执行
    osInProgress,   // 正在执行中
    osCompleted,    // 已完成执行
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
    octNone,        // 无回调
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



  // ===== 一次性执行接口 =====
  // 修复接口设计：IOnce不再继承ILock，避免语义混乱
  // Once不是传统意义的锁，不应该有Lock/Unlock语义
  IOnce = interface
    ['{A1B2C3D4-E5F6-4789-9012-123456789ABC}']

    // 核心方法：执行回调（Go/Rust 风格）
    procedure Execute; overload;
    procedure Execute(const AProc: TOnceProc); overload;
    procedure Execute(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Execute(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure Call(const AProc: TOnceProc); overload; deprecated 'Use Execute instead';
    procedure Call(const AMethod: TOnceMethod); overload; deprecated 'Use Execute instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure Call(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use Execute instead';
    {$ENDIF}

    // 强制执行（忽略毒化状态）
    procedure ExecuteForce; overload;
    procedure ExecuteForce(const AProc: TOnceProc); overload;
    procedure ExecuteForce(const AMethod: TOnceMethod); overload;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure ExecuteForce(const AAnonymousProc: TOnceAnonymousProc); overload;
    {$ENDIF}

    // 兼容旧接口（标记为废弃）
    procedure CallForce(const AProc: TOnceProc); overload; deprecated 'Use ExecuteForce instead';
    procedure CallForce(const AMethod: TOnceMethod); overload; deprecated 'Use ExecuteForce instead';
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure CallForce(const AAnonymousProc: TOnceAnonymousProc); overload; deprecated 'Use ExecuteForce instead';
    {$ENDIF}

    // 等待机制（Rust 风格）
    procedure Wait;
    procedure WaitForce;

    // 状态查询（属性风格，符合 Pascal 约定）
    function GetState: TOnceState;
    function GetCompleted: Boolean;
    function GetPoisoned: Boolean;

    // 属性接口
    property State: TOnceState read GetState;
    property Completed: Boolean read GetCompleted;
    property Poisoned: Boolean read GetPoisoned;

    // 注意：Reset 功能已移除，因为：
    // 1. 并发安全问题：Reset 期间其他线程可能仍在快速路径中
    // 2. 语义不清晰：Reset 后的状态转换不明确
    // 3. 主流语言不提供：Go、Rust、Java 都不提供 Reset 功能
    // 如果需要重新执行，请创建新的 Once 实例
  end;

implementation

end.
