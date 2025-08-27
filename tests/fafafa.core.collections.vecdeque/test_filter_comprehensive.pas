program test_filter_comprehensive;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.collections.vecdeque;

type
  TIntVecDeque = specialize TVecDeque<Integer>;

// 测试用的断言函数
function IsEven(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsPositive(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := aValue > 0;
end;

function IsGreaterThan5(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := aValue > 5;
end;

// 测试用的方法断言函数
type
  TFilterTester = class
  public
    function IsEvenMethod(const aValue: Integer; aData: Pointer): Boolean;
    function IsPositiveMethod(const aValue: Integer; aData: Pointer): Boolean;
  end;

function TFilterTester.IsEvenMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function TFilterTester.IsPositiveMethod(const aValue: Integer; aData: Pointer): Boolean;
begin
  Result := aValue > 0;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
// 引用函数版本的断言函数
function IsEvenRefFunc(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

function IsPositiveRefFunc(const aValue: Integer): Boolean;
begin
  Result := aValue > 0;
end;
{$ENDIF}

procedure PrintVecDeque(const ATitle: string; AVecDeque: TIntVecDeque);
var
  i: SizeUInt;
begin
  Write(ATitle, ': [');
  if AVecDeque.GetCount > 0 then
  begin
    for i := 0 to AVecDeque.GetCount - 1 do
    begin
      Write(AVecDeque.Get(i));
      if i < AVecDeque.GetCount - 1 then
        Write(', ');
    end;
  end;
  WriteLn(']');
end;

procedure TestFilterFunc;
var
  LVecDeque, LFiltered: TIntVecDeque;
begin
  WriteLn('=== Testing Filter with Function ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 添加测试数据: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(6);
    LVecDeque.PushBack(7);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(10);
    
    PrintVecDeque('Original', LVecDeque);
    
    // 测试过滤偶数
    LFiltered := LVecDeque.Filter(@IsEven, nil);
    try
      PrintVecDeque('Even numbers', LFiltered);
      WriteLn('Even count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
    // 测试过滤正数（所有数都是正数）
    LFiltered := LVecDeque.Filter(@IsPositive, nil);
    try
      PrintVecDeque('Positive numbers', LFiltered);
      WriteLn('Positive count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
    // 测试过滤大于5的数
    LFiltered := LVecDeque.Filter(@IsGreaterThan5, nil);
    try
      PrintVecDeque('Numbers > 5', LFiltered);
      WriteLn('Numbers > 5 count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;

procedure TestFilterMethod;
var
  LVecDeque, LFiltered: TIntVecDeque;
  LTester: TFilterTester;
begin
  WriteLn('=== Testing Filter with Method ===');
  
  LVecDeque := TIntVecDeque.Create;
  LTester := TFilterTester.Create;
  try
    // 添加测试数据: [-3, -2, -1, 0, 1, 2, 3, 4]
    LVecDeque.PushBack(-3);
    LVecDeque.PushBack(-2);
    LVecDeque.PushBack(-1);
    LVecDeque.PushBack(0);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    
    PrintVecDeque('Original', LVecDeque);
    
    // 测试过滤偶数
    LFiltered := LVecDeque.Filter(@LTester.IsEvenMethod, nil);
    try
      PrintVecDeque('Even numbers', LFiltered);
      WriteLn('Even count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
    // 测试过滤正数
    LFiltered := LVecDeque.Filter(@LTester.IsPositiveMethod, nil);
    try
      PrintVecDeque('Positive numbers', LFiltered);
      WriteLn('Positive count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
  finally
    LTester.Free;
    LVecDeque.Free;
  end;
  WriteLn;
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TestFilterRefFunc;
var
  LVecDeque, LFiltered: TIntVecDeque;
begin
  WriteLn('=== Testing Filter with Reference Function ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 添加测试数据: [10, 15, 20, 25, 30]
    LVecDeque.PushBack(10);
    LVecDeque.PushBack(15);
    LVecDeque.PushBack(20);
    LVecDeque.PushBack(25);
    LVecDeque.PushBack(30);
    
    PrintVecDeque('Original', LVecDeque);
    
    // 测试过滤偶数
    LFiltered := LVecDeque.Filter(@IsEvenRefFunc);
    try
      PrintVecDeque('Even numbers', LFiltered);
      WriteLn('Even count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
    // 测试过滤正数（所有数都是正数）
    LFiltered := LVecDeque.Filter(@IsPositiveRefFunc);
    try
      PrintVecDeque('Positive numbers', LFiltered);
      WriteLn('Positive count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;
{$ENDIF}

procedure TestEmptyFilter;
var
  LVecDeque, LFiltered: TIntVecDeque;
begin
  WriteLn('=== Testing Filter with Empty VecDeque ===');
  
  LVecDeque := TIntVecDeque.Create;
  try
    PrintVecDeque('Original (empty)', LVecDeque);
    
    // 测试空集合的过滤
    LFiltered := LVecDeque.Filter(@IsEven, nil);
    try
      PrintVecDeque('Filtered (empty)', LFiltered);
      WriteLn('Filtered count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
  finally
    LVecDeque.Free;
  end;
  WriteLn;
end;

begin
  WriteLn('Testing Filter methods comprehensively...');
  WriteLn;
  
  TestFilterFunc;
  TestFilterMethod;
  
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TestFilterRefFunc;
  {$ELSE}
  WriteLn('=== Reference Function Filter Test Skipped ===');
  WriteLn('(Anonymous references not supported)');
  WriteLn;
  {$ENDIF}
  
  TestEmptyFilter;
  
  WriteLn('All Filter tests completed successfully!');
end.
