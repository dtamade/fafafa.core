unit fafafa.core.sync.namedSemaphore.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.base, fafafa.core.sync.base;

type
  // ===== 配置结构 =====
  TNamedSemaphoreConfig = record
    TimeoutMs: Cardinal;           // 默认超时时间（毫秒）
    RetryIntervalMs: Cardinal;     // 重试间隔（毫秒）
    MaxRetries: Integer;           // 最大重试次数
    UseGlobalNamespace: Boolean;   // 是否使用全局命名空间
    InitialCount: Integer;         // 初始计数值
    MaxCount: Integer;             // 最大计数值
  end;

// 配置辅助函数
function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
function NamedSemaphoreConfigWithTimeout(ATimeoutMs: Cardinal): TNamedSemaphoreConfig;
function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;

type
  // ===== RAII 模式的信号量守卫 =====
  INamedSemaphoreGuard = interface
    ['{B2C3D4E5-6F7A-8901-BCDE-F23456789012}']
    function GetName: string;           // 获取信号量名称
    function GetCount: Integer;         // 获取当前计数值（如果支持）
    // 析构时自动释放信号量，无需手动调用 Release
  end;

  // ===== 现代化的命名信号量接口 =====
  INamedSemaphore = interface
    ['{C3D4E5F6-7A8B-9CDE-F012-345678901234}']
    // 核心信号量操作 - 返回 RAII 守卫
    function Wait: INamedSemaphoreGuard;                              // 阻塞等待
    function TryWait: INamedSemaphoreGuard;                          // 非阻塞尝试
    function TryWaitFor(ATimeoutMs: Cardinal): INamedSemaphoreGuard; // 带超时等待
    
    // 释放操作（不返回守卫，因为释放不需要 RAII）
    procedure Release; overload;                                      // 释放一个计数
    procedure Release(ACount: Integer); overload;                    // 释放多个计数

    // 查询操作
    function GetName: string;           // 获取信号量名称
    function GetCurrentCount: Integer;  // 获取当前可用计数（如果支持）
    function GetMaxCount: Integer;      // 获取最大计数值

    // 兼容性方法（向后兼容，但不推荐使用）
    procedure Acquire; deprecated 'Use Wait() instead';
    function TryAcquire: Boolean; deprecated 'Use TryWait() instead';
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload; deprecated 'Use TryWaitFor() instead';
    procedure Acquire(ATimeoutMs: Cardinal); overload; deprecated 'Use TryWaitFor() instead';
    function GetHandle: Pointer; deprecated 'Implementation detail';
    function IsCreator: Boolean; deprecated 'Implementation detail';
  end;

implementation

function DefaultNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result.TimeoutMs := 5000;           // 5秒默认超时
  Result.RetryIntervalMs := 10;       // 10毫秒重试间隔
  Result.MaxRetries := 100;           // 最多重试100次
  Result.UseGlobalNamespace := False; // 默认不使用全局命名空间
  Result.InitialCount := 1;           // 默认初始计数为1
  Result.MaxCount := 1;               // 默认最大计数为1（类似互斥锁）
end;

function NamedSemaphoreConfigWithTimeout(ATimeoutMs: Cardinal): TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.TimeoutMs := ATimeoutMs;
end;

function GlobalNamedSemaphoreConfig: TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.UseGlobalNamespace := True;
end;

function NamedSemaphoreConfigWithCount(AInitialCount, AMaxCount: Integer): TNamedSemaphoreConfig;
begin
  Result := DefaultNamedSemaphoreConfig;
  Result.InitialCount := AInitialCount;
  Result.MaxCount := AMaxCount;
end;

end.
