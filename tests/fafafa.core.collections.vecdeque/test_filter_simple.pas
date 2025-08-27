program test_filter_simple;

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

var
  LVecDeque, LFiltered: TIntVecDeque;
  i: SizeUInt;

begin
  WriteLn('Testing Filter method...');
  
  LVecDeque := TIntVecDeque.Create;
  try
    // 添加测试数据: [1, 2, 3, 4, 5, 6]
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(3);
    LVecDeque.PushBack(4);
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(6);
    
    Write('Original: [');
    for i := 0 to LVecDeque.GetCount - 1 do
    begin
      Write(LVecDeque.Get(i));
      if i < LVecDeque.GetCount - 1 then
        Write(', ');
    end;
    WriteLn(']');
    
    // 测试过滤偶数
    LFiltered := LVecDeque.Filter(@IsEven, nil);
    try
      Write('Even numbers: [');
      for i := 0 to LFiltered.GetCount - 1 do
      begin
        Write(LFiltered.Get(i));
        if i < LFiltered.GetCount - 1 then
          Write(', ');
      end;
      WriteLn(']');
      WriteLn('Even count: ', LFiltered.GetCount);
    finally
      LFiltered.Free;
    end;
    
  finally
    LVecDeque.Free;
  end;
  
  WriteLn('Filter test completed successfully!');
end.
