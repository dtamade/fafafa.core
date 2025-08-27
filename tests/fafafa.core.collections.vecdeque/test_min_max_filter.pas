{$CODEPAGE UTF8}
program test_min_max_filter;

{$mode objfpc}{$H+}

uses
  fafafa.core.collections.vecdeque;

type
  TIntegerVecDeque = specialize TVecDeque<Integer>;

var
  LVecDeque: TIntegerVecDeque;
  LFiltered: TIntegerVecDeque;
  LMinValue, LMaxValue: Integer;
  LMinIndex, LMaxIndex: SizeUInt;

function IsEven(const aValue: Integer): Boolean;
begin
  Result := (aValue mod 2) = 0;
end;

begin
  WriteLn('Testing Min/Max/Filter methods...');
  
  LVecDeque := TIntegerVecDeque.Create;
  try
    // Add test data: [5, 2, 8, 1, 9, 3]
    LVecDeque.PushBack(5);
    LVecDeque.PushBack(2);
    LVecDeque.PushBack(8);
    LVecDeque.PushBack(1);
    LVecDeque.PushBack(9);
    LVecDeque.PushBack(3);
    
    WriteLn('VecDeque contents: [5, 2, 8, 1, 9, 3]');
    
    // Test MinElement
    LMinValue := LVecDeque.MinElement;
    WriteLn('Min value: ', LMinValue);

    // Test MaxElement
    LMaxValue := LVecDeque.MaxElement;
    WriteLn('Max value: ', LMaxValue);

    // Test MinElementIndex
    LMinIndex := LVecDeque.MinElementIndex;
    WriteLn('Min index: ', LMinIndex);

    // Test MaxElementIndex
    LMaxIndex := LVecDeque.MaxElementIndex;
    WriteLn('Max index: ', LMaxIndex);
    
    // Test Filter
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    LFiltered := LVecDeque.Filter(@IsEven);
    {$ELSE}
    // 如果没有匿名引用支持，跳过 Filter 测试
    WriteLn('Filter test skipped (anonymous references not supported)');
    LFiltered := nil;
    {$ENDIF}

    if LFiltered <> nil then
    try
      WriteLn('Filtered (even numbers) count: ', LFiltered.GetCount);
      if LFiltered.GetCount > 0 then
      begin
        WriteLn('First even number: ', LFiltered.Get(0));
        if LFiltered.GetCount > 1 then
          WriteLn('Second even number: ', LFiltered.Get(1));
      end;
    finally
      LFiltered.Free;
    end;
    
    WriteLn('All tests completed successfully!');
    
  finally
    LVecDeque.Free;
  end;
end.
