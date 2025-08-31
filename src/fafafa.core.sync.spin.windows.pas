unit fafafa.core.sync.spin.windows;

{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.sync.base,
  fafafa.core.sync.spin.base;

type
  // 极简高性能自旋锁 - Windows 实现
  // 专注极致性能，移除所有不必要的复杂性
  TSpin = class(TTryLock, ISpin)
  private
    FState: LongInt;  // 0=未锁定, 1=已锁定

  public
    constructor Create;

    // ILock 接口实现
    procedure Acquire; override;
    procedure Release; override;

    // ITryLock 接口实现
    function TryAcquire: Boolean; override;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; override;
  end;

// 工厂函数
function MakeSpin: ISpin;
implementation

uses
  fafafa.core.atomic,
  fafafa.core.time.cpu;


{ TSpin }

constructor TSpin.Create;
begin
  inherited Create;
  FState := 0;  // 初始化为未锁定状态
end;

procedure TSpin.Acquire;
var
  SpinCount: Integer;
  Expected: LongInt;
begin
  // 极简高效自旋循环 - 使用 fafafa.core.atomic
  SpinCount := 0;
  repeat
    Expected := 0;
    if atomic_compare_exchange_weak(FState, Expected, 1) then
      Exit;

    Inc(SpinCount);

    // 简化的自旋策略
    if SpinCount <= 4000 then
      CpuRelax
    else if SpinCount <= 8000 then
      Sleep(0)
    else
    begin
      // 长期竞争：重置计数器 + 短暂休眠
      SpinCount := 0;
      Sleep(1);
    end;
  until False;
end;

procedure TSpin.Release;
begin
  // 极简原子释放 - 使用 fafafa.core.atomic
  atomic_store(FState, 0);
end;

function TSpin.TryAcquire: Boolean;
var
  Expected: LongInt;
begin
  // 极简非阻塞尝试 - 使用 fafafa.core.atomic
  Expected := 0;
  Result := atomic_compare_exchange_weak(FState, Expected, 1);
end;

function TSpin.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
  SpinCount: Integer;
  Expected: LongInt;
begin
  // 先尝试快速获取
  if TryAcquire then
    Exit(True);

  if ATimeoutMs = 0 then
    Exit(False);

  StartTime := GetTickCount;
  SpinCount := 0;

  // 带超时的高效自旋 - 使用 fafafa.core.atomic
  repeat
    Expected := 0;
    if atomic_compare_exchange_weak(FState, Expected, 1) then
      Exit(True);

    // 检查超时
    if (GetTickCount - StartTime) >= ATimeoutMs then
      Exit(False);

    Inc(SpinCount);
    if SpinCount <= 100 then
      CpuRelax
    else
    begin
      SpinCount := 0;
      Sleep(0);
    end;
  until False;
end;

// 工厂函数
function MakeSpin: ISpin;
begin
  Result := TSpin.Create;
end;

end.
