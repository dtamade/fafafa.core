unit fafafa.core.sync.once;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.once.base
  {$IFDEF WINDOWS}, fafafa.core.sync.once.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.once.unix{$ENDIF};

type

  IOnce = fafafa.core.sync.once.base.IOnce;

  {$IFDEF WINDOWS}
  TOnce = fafafa.core.sync.once.windows.TOnce;
  {$ENDIF}

  {$IFDEF UNIX}
  TOnce = fafafa.core.sync.once.unix.TOnce;
  {$ENDIF}

// 创建平台特定的一次性执行实例（Go/Rust 风格：无状态构造）
function MakeOnce: IOnce; overload;

// 构造时传入回调的工厂函数（现代语言风格）
function MakeOnce(const AProc: TOnceProc): IOnce; overload;
function MakeOnce(const AMethod: TOnceMethod): IOnce; overload;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
function MakeOnce(const AAnonymousProc: TOnceAnonymousProc): IOnce; overload;
{$ENDIF}



implementation

{$IFDEF FAFAFA_CORE_OBJECT_POOL}
// Once对象池实现：减少内存分配开销
type
  TOncePool = class
  private
    FPool: array[0..15] of IOnce; // 小型对象池，16个实例
    FPoolMask: LongWord;          // 位掩码，标记可用实例
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
  {$IFDEF WINDOWS}
  InitializeCriticalSection(FLock);
  {$ELSE}
  InitializeCriticalSection(FLock);
  {$ENDIF}
  FPoolMask := $FFFF; // 所有16位都设置为1，表示可用

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

  {$IFDEF WINDOWS}
  DeleteCriticalSection(FLock);
  {$ELSE}
  DeleteCriticalSection(FLock);
  {$ENDIF}
  inherited Destroy;
end;

function TOncePool.GetOnce: IOnce;
var
  i: Integer;
  Mask: LongWord;
begin
  EnterCriticalSection(FLock);
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
      // 池已满，创建新对象
      {$IFDEF UNIX}
      Result := fafafa.core.sync.once.unix.TOnce.Create;
      {$ENDIF}
      {$IFDEF WINDOWS}
      Result := fafafa.core.sync.once.windows.TOnce.Create;
      {$ENDIF}
    end;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

procedure TOncePool.ReturnOnce(const AOnce: IOnce);
var
  i: Integer;
begin
  EnterCriticalSection(FLock);
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
    // 如果不在池中，则忽略（让垃圾回收器处理）
  finally
    LeaveCriticalSection(FLock);
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
  // 注意：对象池版本需要重置对象状态，但Once对象通常是一次性的
  // 所以对于带参数的构造函数，暂时不使用对象池
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
