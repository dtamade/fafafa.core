unit fafafa.core.collections.iterators;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

{**
 * fafafa.core.collections.iterators - 迭代器适配器模块
 *
 * 提供 Rust 风格的惰性迭代器适配器:
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
  fafafa.core.collections.base;

type
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

implementation

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

end.
