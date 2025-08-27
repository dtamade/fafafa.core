unit fafafa.core.sync.spin.windows;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Windows,
  fafafa.core.base, fafafa.core.sync.base, fafafa.core.sync.spin.base, fafafa.core.atomic;

type
  TSpinLock = class(TInterfacedObject, ISpinLock)
  private
    FFlag: atomic_flag;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean; overload;
    function TryAcquire(ATimeoutMs: Cardinal): Boolean; overload;
  end;

implementation

{ TSpinLock }

constructor TSpinLock.Create;
begin
  inherited Create;
  // 初始化原子标志为清除状态
  atomic_flag_clear(FFlag, memory_order_relaxed);
end;

destructor TSpinLock.Destroy;
begin
  inherited Destroy;
end;

procedure TSpinLock.Acquire;
var
  spins, phase: Integer;
begin
  // 多阶段退避：短期忙等 -> SwitchToThread -> Sleep(0) -> Sleep(1)
  spins := 0; phase := 0;
  while atomic_flag_test_and_set(FFlag, memory_order_acquire) do
  begin
    Inc(spins);
    case phase of
      0: begin
           // 短期忙等（轻量退避提示 CPU）
           if (spins and 255) = 0 then
             phase := 1
           else
             asm pause end;
         end;
      1: begin
           Windows.SwitchToThread;
           phase := 2;
         end;
      2: begin
           Sleep(0);
           phase := 3;
         end;
      else
        Sleep(1);
    end;
  end;
end;

procedure TSpinLock.Release;
begin
  atomic_flag_clear(FFlag, memory_order_release);
end;

function TSpinLock.TryAcquire: Boolean;
begin
  Result := not atomic_flag_test_and_set(FFlag, memory_order_acquire);
end;

function TSpinLock.TryAcquire(ATimeoutMs: Cardinal): Boolean;
var
  StartTime: DWORD;
  ElapsedMs: DWORD;
  spins, phase: Integer;
begin
  if ATimeoutMs = 0 then
  begin
    Result := TryAcquire;
    Exit;
  end;

  StartTime := GetTickCount;
  spins := 0; phase := 0;
  repeat
    Result := not atomic_flag_test_and_set(FFlag, memory_order_acquire);
    if Result then Exit;

    // 检查超时
    ElapsedMs := GetTickCount - StartTime;
    if ElapsedMs >= ATimeoutMs then
      Exit(False);

    // 阶段化退避
    Inc(spins);
    case phase of
      0: begin
           if (spins and 255) = 0 then
             phase := 1
           else
             asm pause end;
         end;
      1: begin
           Windows.SwitchToThread;
           phase := 2;
         end;
      2: begin
           Sleep(0);
           phase := 3;
         end;
      else
        Sleep(1);
    end;
  until False;
end;



end.
