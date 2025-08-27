program simple_test;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.collections.forwardList;

type
  TIntForwardList = specialize TForwardList<Integer>;

var
  LList: TIntForwardList;
  LIter: TIntForwardList.TIter;
  i: Integer;

begin
  WriteLn('=== 简单的 ForwardList 测试 ===');
  
  // 创建列表
  LList := TIntForwardList.Create;
  try
    WriteLn('1. 创建空列表');
    WriteLn('   计数: ', LList.GetCount);
    WriteLn('   是否为空: ', LList.IsEmpty);
    
    // 添加元素
    WriteLn('2. 添加元素 1, 2, 3');
    LList.PushFront(1);
    LList.PushFront(2);
    LList.PushFront(3);
    WriteLn('   计数: ', LList.GetCount);
    WriteLn('   是否为空: ', LList.IsEmpty);
    WriteLn('   前端元素: ', LList.Front);
    
    // 遍历元素
    WriteLn('3. 遍历元素:');
    LIter := LList.Begin_;
    i := 0;
    while not LIter.Equal(LList.End_) do
    begin
      Inc(i);
      WriteLn('   元素 ', i, ': ', LIter.GetData^);
      LIter.Next;
    end;
    
    // 清空列表
    WriteLn('4. 清空列表');
    LList.Clear;
    WriteLn('   计数: ', LList.GetCount);
    WriteLn('   是否为空: ', LList.IsEmpty);
    
    WriteLn('✅ 基本功能测试通过！');
    
  finally
    LList.Free;
  end;
  
  WriteLn('=== 测试完成 ===');
end.
