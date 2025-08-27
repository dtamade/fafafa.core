unit fafafa.core.lockfree.map;

{**
 * fafafa.core.lockfree.map - 面向接口的无锁映射抽象与适配器
 *
 * 说明：为避免对现有工程产生破坏性影响，默认不启用该接口单元的实际实现。
 * 若需要启用接口与适配器，请在编译选项中定义 FAFAFA_CORE_MAP_INTERFACE 宏。
 *}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

{$IFNDEF FAFAFA_CORE_MAP_INTERFACE}
interface
implementation
end.
{$ENDIF}

{$IFDEF FAFAFA_CORE_MAP_INTERFACE}

interface

uses
  SysUtils,
  fafafa.core.lockfree.stats,
  // 具体实现单元
  fafafa.core.lockfree.hashmap,                // TMichaelHashMap
  fafafa.core.lockfree.hashmap.openAddressing; // TLockFreeHashMap (OA)

type
  {**
   * 通用无锁映射接口（最小可用集合）
   *
   * 统一公开接口，便于替换实现与契约测试。
   * Size 使用 Int64 以兼容不同实现的计数类型。
   * Capacity 在 MM 实现中等价于 bucket_count。
   *}
  generic ILockFreeMap<TKey, TValue> = interface
    ['{A3C0F8E6-67E4-4D51-9C0D-2B1A5F6B99C1}']
    function Put(const AKey: TKey; const AValue: TValue): Boolean;
    function Get(const AKey: TKey; out AValue: TValue): Boolean;
    function Remove(const AKey: TKey): Boolean;
    function ContainsKey(const AKey: TKey): Boolean;

    function IsEmpty: Boolean;
    function Size: Int64;
    function Capacity: Integer;
    procedure Clear;

    function GetStats: ILockFreeStats;
  end;

  {**
   * OA（开放寻址）实现的适配器
   *}
  generic TLockFreeMapOA<TKey, TValue> = class(TInterfacedObject, specialize ILockFreeMap<TKey, TValue>)
  private
    type TOAImpl = specialize TLockFreeHashMap<TKey, TValue>;
    FMap: TOAImpl;
  public
    constructor Create(ACapacity: Integer = 1024);
    destructor Destroy; override;

    function Put(const AKey: TKey; const AValue: TValue): Boolean;
    function Get(const AKey: TKey; out AValue: TValue): Boolean;
    function Remove(const AKey: TKey): Boolean;
    function ContainsKey(const AKey: TKey): Boolean;

    function IsEmpty: Boolean;
    function Size: Int64;
    function Capacity: Integer;
    procedure Clear;

    function GetStats: ILockFreeStats;
  end;

  {**
   * MM（Michael & Michael）实现的适配器
   * 需要调用方提供哈希函数与比较器（或使用门面便捷构造器创建底层实例）。
   *}
  generic TLockFreeMapMM<TKey, TValue> = class(TInterfacedObject, specialize ILockFreeMap<TKey, TValue>)
  public
    type
      THashFunction = specialize TMichaelHashMap<TKey, TValue>.THashFunction;
      TKeyComparer  = specialize TMichaelHashMap<TKey, TValue>.TKeyComparer;
  private
    FMap: specialize TMichaelHashMap<TKey, TValue>;
  public
    constructor Create(ABucketCount: Integer; AHash: THashFunction; AComparer: TKeyComparer);
    destructor Destroy; override;

    function Put(const AKey: TKey; const AValue: TValue): Boolean;
    function Get(const AKey: TKey; out AValue: TValue): Boolean;
    function Remove(const AKey: TKey): Boolean;
    function ContainsKey(const AKey: TKey): Boolean;

    function IsEmpty: Boolean;
    function Size: Int64;
    function Capacity: Integer;
    procedure Clear;

    function GetStats: ILockFreeStats;
  end;

implementation
{$ENDIF}

{ TLockFreeMapOA }

constructor TLockFreeMapOA.Create(ACapacity: Integer);
begin
  inherited Create;
  FMap := TOAImpl.Create(ACapacity);
end;

destructor TLockFreeMapOA.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

function TLockFreeMapOA.Put(const AKey: TKey; const AValue: TValue): Boolean;
begin
  Result := FMap.Put(AKey, AValue);
end;

function TLockFreeMapOA.Get(const AKey: TKey; out AValue: TValue): Boolean;
begin
  Result := FMap.Get(AKey, AValue);
end;

function TLockFreeMapOA.Remove(const AKey: TKey): Boolean;
begin
  Result := FMap.Remove(AKey);
end;

function TLockFreeMapOA.ContainsKey(const AKey: TKey): Boolean;
begin
  Result := FMap.ContainsKey(AKey);
end;

function TLockFreeMapOA.IsEmpty: Boolean;
begin
  Result := FMap.IsEmpty;
end;

function TLockFreeMapOA.Size: Int64;
begin
  Result := FMap.GetSize;
end;

function TLockFreeMapOA.Capacity: Integer;
begin
  Result := FMap.GetCapacity;
end;

procedure TLockFreeMapOA.Clear;
begin
  FMap.Clear;
end;

function TLockFreeMapOA.GetStats: ILockFreeStats;
begin
  Result := nil;
end;

{ TLockFreeMapMM }

constructor TLockFreeMapMM.Create(ABucketCount: Integer; AHash: THashFunction; AComparer: TKeyComparer);
begin
  inherited Create;
  FMap := specialize TMichaelHashMap<TKey, TValue>.Create(ABucketCount, AHash, AComparer);
end;

destructor TLockFreeMapMM.Destroy;
begin
  FMap.Free;
  inherited Destroy;
end;

function TLockFreeMapMM.Put(const AKey: TKey; const AValue: TValue): Boolean;
begin
  // MM 的 insert: 若存在则返回 False；我们按 Put 语义：存在即更新
  if not FMap.insert(AKey, AValue) then
    Result := FMap.update(AKey, AValue)
  else
    Result := True;
end;

function TLockFreeMapMM.Get(const AKey: TKey; out AValue: TValue): Boolean;
begin
  Result := FMap.find(AKey, AValue);
end;

function TLockFreeMapMM.Remove(const AKey: TKey): Boolean;
begin
  Result := FMap.erase(AKey);
end;

function TLockFreeMapMM.ContainsKey(const AKey: TKey): Boolean;
var
  LTmp: TValue;
begin
  Result := FMap.find(AKey, LTmp);
end;

function TLockFreeMapMM.IsEmpty: Boolean;
begin
  Result := FMap.empty;
end;

function TLockFreeMapMM.Size: Int64;
begin
  Result := FMap.size;
end;

function TLockFreeMapMM.Capacity: Integer;
begin
  Result := FMap.bucket_count;
end;

procedure TLockFreeMapMM.Clear;
begin
  FMap.clear;
end;

function TLockFreeMapMM.GetStats: ILockFreeStats;
begin
  Result := nil;
end;

end.

