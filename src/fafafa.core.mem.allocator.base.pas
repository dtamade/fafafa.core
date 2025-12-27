unit fafafa.core.mem.allocator.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.base,
  fafafa.core.mem.allocator.instrumentation;

type
  {**
   * TAllocatorTraits
   *
   * @desc 只读能力描述，便于上层策略化选择
   *
   * 注意：所有 IAllocator 实现都提供 AllocAligned/FreeAligned 方法，
   * 但实现方式不同：
   * - SupportsAligned=True: 原生支持，无额外开销（如 mimalloc）
   * - SupportsAligned=False: 通过 over-allocate 模拟，有内存/性能开销
   *}
  TAllocatorTraits = record
    ZeroInitialized: Boolean;   // AllocMem 是否保证零填充
    ThreadSafe     : Boolean;   // 是否内置线程安全（无需外部加锁）
    HasMemSize     : Boolean;   // 是否支持查询已分配块大小（如 MemSizeOf）
    SupportsAligned: Boolean;   // 是否原生支持对齐分配（无 over-allocate 开销）
  end;
  {**
   * IAllocator
   *
   * @desc 通用内存分配器的接口
   *}
  IAllocator = interface
    ['{1CEB691D-D538-48D2-A5C4-A4F0A1B98928}']
    function GetMem(aSize: SizeUInt): Pointer;
    function AllocMem(aSize: SizeUInt): Pointer;
    function ReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
    procedure FreeMem(aDst: Pointer);
    // 对齐分配（整合到核心契约）
    function AllocAligned(aSize, aAlignment: SizeUInt): Pointer;
    procedure FreeAligned(aPtr: Pointer);
    // 能力查询（只读，不抛异常）
    function Traits: TAllocatorTraits;
  end;

  {**
   * TAllocator
   *
   * @desc 内存分配器的抽象基类, 实现了 IAllocator 接口
   *}
  TAllocator = class(TInterfacedObject, IAllocator)
  protected
    function DoGetMem(aSize: SizeUInt): Pointer; virtual; abstract;
    function DoAllocMem(aSize: SizeUInt): Pointer; virtual; abstract;
    function DoReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer; virtual; abstract;
    procedure DoFreeMem(aDst: Pointer); virtual; abstract;
  public
    function  GetMem(aSize: SizeUInt): Pointer; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function  AllocMem(aSize: SizeUInt): Pointer; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    function  ReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer; {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    procedure FreeMem(aDst: Pointer); {$IFDEF FAFAFA_CORE_INLINE}inline;{$ENDIF}
    // 对齐分配（默认回退实现，子类可覆盖为原生对齐）
    function  AllocAligned(aSize, aAlignment: SizeUInt): Pointer;
    procedure FreeAligned(aPtr: Pointer);
    function  Traits: TAllocatorTraits; virtual;
  end;


implementation

function IsPowerOfTwo(x: SizeUInt): Boolean; inline;
begin
  Result := (x <> 0) and ((x and (x - 1)) = 0);
end;

function AlignUpPtr(P: Pointer; AAlignment: SizeUInt): Pointer; inline;
var
  Addr, Mask: PtrUInt;
begin
  Addr := PtrUInt(P);
  Mask := PtrUInt(AAlignment - 1);
  Result := Pointer((Addr + Mask) and not Mask);
end;

function TAllocator.Traits: TAllocatorTraits;
begin
  // 基类缺省值：
  // - ThreadSafe=True: 大多数 RTL 分配器线程安全
  // - ZeroInitialized=False: GetMem 不保证零填充
  // - HasMemSize=False: 不支持查询块大小
  // - SupportsAligned=False: 通过 over-allocate 模拟
  Result.ZeroInitialized := False;
  Result.ThreadSafe      := True;
  Result.HasMemSize      := False;
  Result.SupportsAligned := False;
end;

function TAllocator.GetMem(aSize: SizeUInt): Pointer;
begin
  if aSize = 0 then
    Exit(nil);
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if AllocatorFaults_ShouldFailNow then Exit(nil);
  {$ENDIF}
  Result := DoGetMem(aSize);
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if Result <> nil then AllocatorStats_OnAlloc(aSize);
  {$ENDIF}
end;

function TAllocator.AllocMem(aSize: SizeUInt): Pointer;
begin
  if aSize = 0 then
    Exit(nil);
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if AllocatorFaults_ShouldFailNow then Exit(nil);
  {$ENDIF}
  Result := DoAllocMem(aSize);
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if Result <> nil then AllocatorStats_OnAlloc(aSize);
  {$ENDIF}
end;

function TAllocator.ReallocMem(aDst: Pointer; aSize: SizeUInt): Pointer;
begin
  if aSize = 0 then
  begin
    if aDst <> nil then
      {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  AllocatorStats_OnFree;
  {$ENDIF}
  DoFreeMem(aDst);
    Exit(nil);
  end;
  if aDst = nil then
    Exit(GetMem(aSize));
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if AllocatorFaults_ShouldFailNow then Exit(nil);
  {$ENDIF}
  Result := DoReallocMem(aDst, aSize);
  {$IFDEF FAFAFA_CORE_ALLOCATOR_INSTRUMENTATION}
  if Result <> nil then AllocatorStats_OnRealloc(aSize);
  {$ENDIF}
end;

procedure TAllocator.FreeMem(aDst: Pointer);
begin
  if aDst = nil then
  begin
    {$IFDEF FAFAFA_CORE_STRICT_NULL_FREE}
    raise EArgumentNil.Create('TAllocator.FreeMem: aDst cannot be nil.');
    {$ELSE}
    Exit;
    {$ENDIF}
  end;
  DoFreeMem(aDst);
end;

function TAllocator.AllocAligned(aSize, aAlignment: SizeUInt): Pointer;
var
  Raw: Pointer;
  Needed: SizeUInt;
  HeaderPtr: PPointer;
begin
  if aSize = 0 then Exit(nil);
  if (aAlignment < SizeOf(Pointer)) or (not IsPowerOfTwo(aAlignment)) then
    raise EInvalidArgument.Create('AllocAligned: alignment must be power of two and >= pointer size');
  // Over-allocate and store the original pointer just before the aligned block
  Needed := aSize + aAlignment - 1 + SizeOf(Pointer);
  Raw := GetMem(Needed);
  if Raw = nil then Exit(nil);
  Result := AlignUpPtr(Pointer(PtrUInt(Raw) + SizeOf(Pointer)), aAlignment);
  HeaderPtr := PPointer(PtrUInt(Result) - SizeOf(Pointer));
  HeaderPtr^ := Raw;
end;

procedure TAllocator.FreeAligned(aPtr: Pointer);
var
  Raw: Pointer;
  HeaderPtr: PPointer;
begin
  if aPtr = nil then Exit;
  HeaderPtr := PPointer(PtrUInt(aPtr) - SizeOf(Pointer));
  Raw := HeaderPtr^;
  FreeMem(Raw);
end;

end.

