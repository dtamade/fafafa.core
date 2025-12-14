unit fafafa.core.collections.iterators;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{**
 * fafafa.core.collections.iterators - 迭代器适配器模块
 *
 * 提供 Rust 风格的惰性迭代器适配器:
 * - TEnumerateIter<T> : 枚举迭代器，带索引迭代
 * - TZipIter<T, U>    : 压缩迭代器，并行迭代两个迭代器
 * - TChainIter<T>     : 链接迭代器，串联两个迭代器
 * - TMapIter<T, U>    : 映射迭代器，将 T 转换为 U
 * - TFilterIter<T>    : 过滤迭代器，只保留满足条件的元素
 * - TTakeIter<T>      : 取前 N 个元素
 * - TSkipIter<T>      : 跳过前 N 个元素
 *
 * 所有适配器都是惰性求值的，支持链式组合。
 *}

interface

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vec;

type
  {**
   * TEnumerateIter<T> - 枚举迭代器
   *
   * 在迭代时同时提供元素索引和元素值
   * 类似 Rust 的 .enumerate() 和 Python 的 enumerate()
   *}
  generic TEnumerateIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
  private
    FSource: TSourceIter;
    FIndex: SizeUInt;
    FStartIndex: SizeUInt;
    FCurrent: T;
    FStarted: Boolean;
  public
    procedure Init(const aSource: TSourceIter; aStartIndex: SizeUInt = 0);
    class function Create(const aSource: TSourceIter; aStartIndex: SizeUInt = 0): specialize TEnumerateIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetIndex: SizeUInt; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    // For TIter<T> compatibility
    function ToIter: TSourceIter;
    
    property Current: T read GetCurrent;
    property Index: SizeUInt read GetIndex;
  end;

  {**
   * TZipIter<T, U> - 压缩迭代器
   *
   * 并行迭代两个迭代器，返回元素对
   * 当任一迭代器耗尽时停止
   * 类似 Rust 的 .zip() 和 Python 的 zip()
   *}
  generic TZipIter<T, U> = record
  public type
    TFirstIter = specialize TIter<T>;
    TSecondIter = specialize TIter<U>;
  private
    FFirst: TFirstIter;
    FSecond: TSecondIter;
    FCurrentFirst: T;
    FCurrentSecond: U;
  public
    procedure Init(const aFirst: TFirstIter; const aSecond: TSecondIter);
    class function Create(const aFirst: TFirstIter; const aSecond: TSecondIter): specialize TZipIter<T, U>; static;
    
    function MoveNext: Boolean;
    function GetFirst: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    function GetSecond: U; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    property First: T read GetFirst;
    property Second: U read GetSecond;
  end;

  {**
   * TChainIter<T> - 链接迭代器
   *
   * 串联两个相同类型的迭代器
   * 先迭代第一个，耗尽后迭代第二个
   * 类似 Rust 的 .chain()
   *}
  generic TChainIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
  private
    FFirst: TSourceIter;
    FSecond: TSourceIter;
    FCurrent: T;
    FFirstExhausted: Boolean;
  public
    procedure Init(const aFirst: TSourceIter; const aSecond: TSourceIter);
    class function Create(const aFirst: TSourceIter; const aSecond: TSourceIter): specialize TChainIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    property Current: T read GetCurrent;
  end;

  {**
   * TMapIter<T, U> - 映射迭代器
   *
   * 将源迭代器的每个元素通过映射函数转换为新类型
   *}
  generic TMapIter<T, U> = record
  public type
    TSourceIter = specialize TIter<T>;
    TMapperFunc = function(const aElement: T; aData: Pointer): U;
  private
    FSource: TSourceIter;
    FMapper: TMapperFunc;
    FData: Pointer;
    FCurrent: U;
    FStarted: Boolean;
  public
    procedure Init(const aSource: TSourceIter; aMapper: TMapperFunc; aData: Pointer);
    class function Create(const aSource: TSourceIter; aMapper: TMapperFunc; aData: Pointer): specialize TMapIter<T, U>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: U; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    property Current: U read GetCurrent;
  end;

  {**
   * TFilterIter<T> - 过滤迭代器
   *
   * 只返回满足谓词条件的元素
   *}
  generic TFilterIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
    TPredicateFunc = function(const aElement: T; aData: Pointer): Boolean;
  private
    FSource: TSourceIter;
    FPredicate: TPredicateFunc;
    FData: Pointer;
    FCurrent: T;
    FStarted: Boolean;
  public
    procedure Init(const aSource: TSourceIter; aPredicate: TPredicateFunc; aData: Pointer);
    class function Create(const aSource: TSourceIter; aPredicate: TPredicateFunc; aData: Pointer): specialize TFilterIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    // For TIter<T> compatibility
    function ToIter: TSourceIter;
    
    property Current: T read GetCurrent;
  end;

  {**
   * TTakeIter<T> - 取前 N 个元素
   *
   * 最多返回前 N 个元素
   *}
  generic TTakeIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
  private
    FSource: TSourceIter;
    FRemaining: SizeUInt;
    FCurrent: T;
    FStarted: Boolean;
  public
    procedure Init(const aSource: TSourceIter; aCount: SizeUInt);
    class function Create(const aSource: TSourceIter; aCount: SizeUInt): specialize TTakeIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    property Current: T read GetCurrent;
  end;

  {**
   * TRevIter<T> - 反向迭代器
   *
   * 将源迭代器的元素以反向顺序返回
   * 注意：需要缓存所有元素，因此会消耗额外内存
   * 类似 Rust 的 .rev()
   *}
  generic TRevIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
    TElementArray = array of T;
  private
    FElements: TElementArray;
    FIndex: SizeInt;  // 当前位置，从 Count-1 向 0 递减
    FCurrent: T;
    FInitialized: Boolean;
  public
    procedure Init(const aSource: TSourceIter);
    class function Create(const aSource: TSourceIter): specialize TRevIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    property Current: T read GetCurrent;
  end;

  {**
   * TSkipIter<T> - 跳过前 N 个元素
   *
   * 跳过前 N 个元素，返回剩余元素
   *}
  generic TSkipIter<T> = record
  public type
    TSourceIter = specialize TIter<T>;
  private
    FSource: TSourceIter;
    FSkipCount: SizeUInt;
    FSkipped: Boolean;
    FCurrent: T;
    FStarted: Boolean;
  public
    procedure Init(const aSource: TSourceIter; aCount: SizeUInt);
    class function Create(const aSource: TSourceIter; aCount: SizeUInt): specialize TSkipIter<T>; static;
    
    function MoveNext: Boolean;
    function GetCurrent: T; {$IFDEF FAFAFA_CORE_INLINE} inline;{$ENDIF}
    
    // For TIter<T> compatibility  
    function ToIter: TSourceIter;
    
    property Current: T read GetCurrent;
  end;

// ==== Collect 收集器函数 ====
// 从迭代器收集元素到 Vec 容器

{**
 * CollectToVec<T> - 从 TIter<T> 收集到 IVec<T>
 *
 * 消费迭代器中的所有元素，构造一个新的 Vec
 *}
generic function CollectToVec<T>(var aIter: specialize TIter<T>): specialize IVec<T>;

{**
 * CollectFilterToVec<T> - 从 TFilterIter<T> 收集到 IVec<T>
 *
 * 消费过滤迭代器中的所有元素，构造一个新的 Vec
 *}
generic function CollectFilterToVec<T>(var aIter: specialize TFilterIter<T>): specialize IVec<T>;

{**
 * CollectTakeToVec<T> - 从 TTakeIter<T> 收集到 IVec<T>
 *
 * 消费取前 N 个迭代器中的所有元素，构造一个新的 Vec
 *}
generic function CollectTakeToVec<T>(var aIter: specialize TTakeIter<T>): specialize IVec<T>;

{**
 * CollectChainToVec<T> - 从 TChainIter<T> 收集到 IVec<T>
 *
 * 消费链接迭代器中的所有元素，构造一个新的 Vec
 *}
generic function CollectChainToVec<T>(var aIter: specialize TChainIter<T>): specialize IVec<T>;

implementation

{ TEnumerateIter<T> }

procedure TEnumerateIter.Init(const aSource: TSourceIter; aStartIndex: SizeUInt);
begin
  FSource := aSource;
  FStartIndex := aStartIndex;
  FIndex := aStartIndex;
  FStarted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TEnumerateIter.Create(const aSource: TSourceIter; aStartIndex: SizeUInt): specialize TEnumerateIter<T>;
begin
  Result.Init(aSource, aStartIndex);
end;

function TEnumerateIter.MoveNext: Boolean;
begin
  Result := FSource.MoveNext;
  if Result then
  begin
    FCurrent := FSource.Current;
    // First successful MoveNext: index stays at FStartIndex
    // Subsequent calls: increment index before returning
    if FStarted then
      Inc(FIndex)
    else
      FStarted := True;
  end;
end;

function TEnumerateIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

function TEnumerateIter.GetIndex: SizeUInt;
begin
  Result := FIndex;
end;

function TEnumerateIter.ToIter: TSourceIter;
begin
  Result := FSource;
end;

{ TZipIter<T, U> }

procedure TZipIter.Init(const aFirst: TFirstIter; const aSecond: TSecondIter);
begin
  FFirst := aFirst;
  FSecond := aSecond;
  FillChar(FCurrentFirst, SizeOf(FCurrentFirst), 0);
  FillChar(FCurrentSecond, SizeOf(FCurrentSecond), 0);
end;

class function TZipIter.Create(const aFirst: TFirstIter; const aSecond: TSecondIter): specialize TZipIter<T, U>;
begin
  Result.Init(aFirst, aSecond);
end;

function TZipIter.MoveNext: Boolean;
begin
  // Both must advance successfully
  Result := FFirst.MoveNext and FSecond.MoveNext;
  if Result then
  begin
    FCurrentFirst := FFirst.Current;
    FCurrentSecond := FSecond.Current;
  end;
end;

function TZipIter.GetFirst: T;
begin
  Result := FCurrentFirst;
end;

function TZipIter.GetSecond: U;
begin
  Result := FCurrentSecond;
end;

{ TChainIter<T> }

procedure TChainIter.Init(const aFirst: TSourceIter; const aSecond: TSourceIter);
begin
  FFirst := aFirst;
  FSecond := aSecond;
  FFirstExhausted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TChainIter.Create(const aFirst: TSourceIter; const aSecond: TSourceIter): specialize TChainIter<T>;
begin
  Result.Init(aFirst, aSecond);
end;

function TChainIter.MoveNext: Boolean;
begin
  if not FFirstExhausted then
  begin
    Result := FFirst.MoveNext;
    if Result then
    begin
      FCurrent := FFirst.Current;
      Exit;
    end;
    // First exhausted, switch to second
    FFirstExhausted := True;
  end;
  
  // Try second iterator
  Result := FSecond.MoveNext;
  if Result then
    FCurrent := FSecond.Current;
end;

function TChainIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

{ TMapIter<T, U> }

procedure TMapIter.Init(const aSource: TSourceIter; aMapper: TMapperFunc; aData: Pointer);
begin
  FSource := aSource;
  FMapper := aMapper;
  FData := aData;
  FStarted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TMapIter.Create(const aSource: TSourceIter; aMapper: TMapperFunc; aData: Pointer): specialize TMapIter<T, U>;
begin
  Result.Init(aSource, aMapper, aData);
end;

function TMapIter.MoveNext: Boolean;
begin
  Result := FSource.MoveNext;
  if Result then
    FCurrent := FMapper(FSource.Current, FData);
end;

function TMapIter.GetCurrent: U;
begin
  Result := FCurrent;
end;

{ TFilterIter<T> }

procedure TFilterIter.Init(const aSource: TSourceIter; aPredicate: TPredicateFunc; aData: Pointer);
begin
  FSource := aSource;
  FPredicate := aPredicate;
  FData := aData;
  FStarted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TFilterIter.Create(const aSource: TSourceIter; aPredicate: TPredicateFunc; aData: Pointer): specialize TFilterIter<T>;
begin
  Result.Init(aSource, aPredicate, aData);
end;

function TFilterIter.MoveNext: Boolean;
begin
  // Keep moving until we find an element that matches predicate
  while FSource.MoveNext do
  begin
    if FPredicate(FSource.Current, FData) then
    begin
      FCurrent := FSource.Current;
      Exit(True);
    end;
  end;
  Result := False;
end;

function TFilterIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

function TFilterIter.ToIter: TSourceIter;
begin
  Result := FSource;
end;

{ TTakeIter<T> }

procedure TTakeIter.Init(const aSource: TSourceIter; aCount: SizeUInt);
begin
  FSource := aSource;
  FRemaining := aCount;
  FStarted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TTakeIter.Create(const aSource: TSourceIter; aCount: SizeUInt): specialize TTakeIter<T>;
begin
  Result.Init(aSource, aCount);
end;

function TTakeIter.MoveNext: Boolean;
begin
  if FRemaining = 0 then
    Exit(False);
    
  Result := FSource.MoveNext;
  if Result then
  begin
    FCurrent := FSource.Current;
    Dec(FRemaining);
  end;
end;

function TTakeIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

{ TRevIter<T> }

procedure TRevIter.Init(const aSource: TSourceIter);
var
  LSource: TSourceIter;
  LCapacity, LCount: SizeUInt;
begin
  // Collect all elements from source in one pass with dynamic growth
  LSource := aSource;
  LCapacity := 16;
  LCount := 0;
  SetLength(FElements, LCapacity);
  
  while LSource.MoveNext do
  begin
    if LCount >= LCapacity then
    begin
      LCapacity := LCapacity * 2;
      SetLength(FElements, LCapacity);
    end;
    FElements[LCount] := LSource.Current;
    Inc(LCount);
  end;
  
  // Trim to actual size
  SetLength(FElements, LCount);
  
  // Initialize for reverse iteration
  FIndex := SizeInt(LCount);  // Start past the end
  FInitialized := True;
  FillChar(FCurrent, SizeOf(T), 0);
end;

class function TRevIter.Create(const aSource: TSourceIter): specialize TRevIter<T>;
var
  LSource: TSourceIter;
  LCapacity, LCount: SizeUInt;
begin
  // Collect all elements from source in one pass
  LSource := aSource;
  LCapacity := 16;
  LCount := 0;
  SetLength(Result.FElements, LCapacity);
  
  while LSource.MoveNext do
  begin
    if LCount >= LCapacity then
    begin
      LCapacity := LCapacity * 2;
      SetLength(Result.FElements, LCapacity);
    end;
    Result.FElements[LCount] := LSource.Current;
    Inc(LCount);
  end;
  
  // Trim to actual size
  SetLength(Result.FElements, LCount);
  
  // Initialize for reverse iteration
  Result.FIndex := SizeInt(LCount);  // Start past the end
  Result.FInitialized := True;
  FillChar(Result.FCurrent, SizeOf(T), 0);
end;

function TRevIter.MoveNext: Boolean;
begin
  // FIndex starts at Length(FElements), decrements each call
  Dec(FIndex);
  if FIndex >= 0 then
  begin
    FCurrent := FElements[FIndex];
    Result := True;
  end
  else
    Result := False;
end;

function TRevIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

{ TSkipIter<T> }

procedure TSkipIter.Init(const aSource: TSourceIter; aCount: SizeUInt);
begin
  FSource := aSource;
  FSkipCount := aCount;
  FSkipped := False;
  FStarted := False;
  FillChar(FCurrent, SizeOf(FCurrent), 0);
end;

class function TSkipIter.Create(const aSource: TSourceIter; aCount: SizeUInt): specialize TSkipIter<T>;
begin
  Result.Init(aSource, aCount);
end;

function TSkipIter.MoveNext: Boolean;
begin
  // Skip elements on first call
  if not FSkipped then
  begin
    FSkipped := True;
    while (FSkipCount > 0) and FSource.MoveNext do
      Dec(FSkipCount);
  end;
  
  // Now return remaining elements
  Result := FSource.MoveNext;
  if Result then
    FCurrent := FSource.Current;
end;

function TSkipIter.GetCurrent: T;
begin
  Result := FCurrent;
end;

function TSkipIter.ToIter: TSourceIter;
begin
  Result := FSource;
end;

{ Collect 收集器函数实现 }

generic function CollectToVec<T>(var aIter: specialize TIter<T>): specialize IVec<T>;
begin
  Result := specialize TVec<T>.Create;
  while aIter.MoveNext do
    Result.Push(aIter.Current);
end;

generic function CollectFilterToVec<T>(var aIter: specialize TFilterIter<T>): specialize IVec<T>;
begin
  Result := specialize TVec<T>.Create;
  while aIter.MoveNext do
    Result.Push(aIter.Current);
end;

generic function CollectTakeToVec<T>(var aIter: specialize TTakeIter<T>): specialize IVec<T>;
begin
  Result := specialize TVec<T>.Create;
  while aIter.MoveNext do
    Result.Push(aIter.Current);
end;

generic function CollectChainToVec<T>(var aIter: specialize TChainIter<T>): specialize IVec<T>;
begin
  Result := specialize TVec<T>.Create;
  while aIter.MoveNext do
    Result.Push(aIter.Current);
end;

end.
