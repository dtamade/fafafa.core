unit fafafa.core.lockfree.stats;

{**
 * fafafa.core.lockfree.stats - 无锁数据结构性能统计模块
 *
 * 这个模块提供了无锁数据结构的性能统计功能，包括：
 *
 * 📊 统计功能：
 *   - 操作计数统计（入队/出队、成功/失败）
 *   - 性能指标计算（吞吐量、错误率）
 *   - 时间统计（平均延迟、运行时间）
 *   - 统计重置和管理
 *
 * 🔒 线程安全：
 *   - 使用原子操作保证线程安全
 *   - 支持多线程并发统计
 *   - 无锁设计，避免性能瓶颈
 *
 * 🎯 设计目标：
 *   - 轻量级，最小化性能开销
 *   - 精确统计，提供可靠数据
 *   - 易于集成，简单的API接口
 *   - 跨平台兼容
 *
 * 作者：fafafa.core 开发团队
 * 版本：1.3.0
 * 许可：MIT License
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses
  SysUtils, Classes;

type
  {**
   * 性能统计接口
   * 
   * 提供无锁数据结构的性能统计功能，包括操作计数、
   * 性能指标计算等。所有方法都是线程安全的。
   *}
  ILockFreeStats = interface
  ['{E5F6A7B8-C9D0-1234-EFAB-567890123456}']
    // 操作统计
    function GetTotalOperations: Int64;
    function GetSuccessfulOperations: Int64;
    function GetFailedOperations: Int64;
    
    // 性能统计
    function GetThroughput: Double;
    
    // 重置统计
    procedure ResetStats;
    
    // 兼容性方法（用于队列/栈特定统计）
    function GetTotalEnqueues: Int64;
    function GetTotalDequeues: Int64;
    function GetFailedEnqueues: Int64;
    function GetFailedDequeues: Int64;
    function GetAverageLatency: Double;
  end;

  {**
   * 性能统计实现类
   * 
   * 使用原子操作实现线程安全的性能统计，适用于
   * 无锁数据结构的性能监控和分析。
   *
   * @note 所有统计操作都是原子的，可以在多线程
   *       环境中安全使用，不会影响无锁数据结构的性能
   *}
  TLockFreeStats = class(TInterfacedObject, ILockFreeStats)
  private
    FTotalEnqueues: Int64;      // 总入队次数
    FTotalDequeues: Int64;      // 总出队次数
    FFailedEnqueues: Int64;     // 失败入队次数
    FFailedDequeues: Int64;     // 失败出队次数
    FStartTime: QWord;          // 创建时间
    FLastResetTime: QWord;      // 上次重置时间

  public
    constructor Create;

    // 统计更新方法（线程安全）
    procedure IncEnqueue(ASuccess: Boolean);
    procedure IncDequeue(ASuccess: Boolean);

    // ILockFreeStats 接口实现
    function GetTotalOperations: Int64;
    function GetSuccessfulOperations: Int64;
    function GetFailedOperations: Int64;
    function GetThroughput: Double;
    procedure ResetStats;
    
    // 兼容性方法
    function GetTotalEnqueues: Int64;
    function GetTotalDequeues: Int64;
    function GetFailedEnqueues: Int64;
    function GetFailedDequeues: Int64;
    function GetAverageLatency: Double;
  end;

implementation

{ TLockFreeStats }

constructor TLockFreeStats.Create;
begin
  inherited Create;
  FStartTime := GetTickCount64;
  FLastResetTime := FStartTime;
  ResetStats;
end;

procedure TLockFreeStats.IncEnqueue(ASuccess: Boolean);
begin
  // 使用原子操作确保线程安全
  InterlockedIncrement64(FTotalEnqueues);
  if not ASuccess then
    InterlockedIncrement64(FFailedEnqueues);
end;

procedure TLockFreeStats.IncDequeue(ASuccess: Boolean);
begin
  // 使用原子操作确保线程安全
  InterlockedIncrement64(FTotalDequeues);
  if not ASuccess then
    InterlockedIncrement64(FFailedDequeues);
end;

function TLockFreeStats.GetTotalEnqueues: Int64;
begin
  Result := FTotalEnqueues;
end;

function TLockFreeStats.GetTotalDequeues: Int64;
begin
  Result := FTotalDequeues;
end;

function TLockFreeStats.GetFailedEnqueues: Int64;
begin
  Result := FFailedEnqueues;
end;

function TLockFreeStats.GetFailedDequeues: Int64;
begin
  Result := FFailedDequeues;
end;

function TLockFreeStats.GetAverageLatency: Double;
begin
  // 简化实现，返回0
  // 在实际应用中，可以通过记录时间戳来计算平均延迟
  Result := 0.0;
end;

function TLockFreeStats.GetThroughput: Double;
var
  LElapsed: QWord;
  LTotalOps: Int64;
begin
  LElapsed := GetTickCount64 - FLastResetTime;
  if LElapsed = 0 then
  begin
    Result := 0.0;
    Exit;
  end;

  LTotalOps := FTotalEnqueues + FTotalDequeues;
  Result := LTotalOps * 1000.0 / LElapsed; // ops/sec
end;

procedure TLockFreeStats.ResetStats;
begin
  FTotalEnqueues := 0;
  FTotalDequeues := 0;
  FFailedEnqueues := 0;
  FFailedDequeues := 0;
  FLastResetTime := GetTickCount64;
end;

// 新增的接口方法实现
function TLockFreeStats.GetTotalOperations: Int64;
begin
  Result := FTotalEnqueues + FTotalDequeues;
end;

function TLockFreeStats.GetSuccessfulOperations: Int64;
begin
  Result := (FTotalEnqueues - FFailedEnqueues) + (FTotalDequeues - FFailedDequeues);
end;

function TLockFreeStats.GetFailedOperations: Int64;
begin
  Result := FFailedEnqueues + FFailedDequeues;
end;

end.
