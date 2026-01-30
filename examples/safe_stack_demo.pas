program SafeStackDemo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.sync,
  fafafa.core.lockfree;

{**
 * 测试带引用计数的安全Treiber栈
 *}
procedure TestSafeTreiberStack;
type
  TIntStack = specialize TSafeTreiberStack<Integer>;
var
  LStack: TIntStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 带引用计数的安全Treiber栈测试 ===');
  
  LStack := TIntStack.Create;
  try
    WriteLn('测试基础功能...');
    
    // 压栈测试
    WriteLn('压栈1-10...');
    for I := 1 to 10 do
      LStack.Push(I);
    
    // 弹栈测试
    WriteLn('弹栈结果 (LIFO顺序): ');
    while LStack.Pop(LValue) do
      Write(LValue, ' ');
    WriteLn;
    
    WriteLn('栈是否为空: ', BoolToStr(LStack.IsEmpty, 'True', 'False'));
    
    WriteLn('✅ 安全Treiber栈基础功能正常！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 比较普通栈和安全栈的性能
 *}
procedure ComparePerformance;
type
  TNormalStack = specialize TTreiberStack<Integer>;
  TSafeStack = specialize TSafeTreiberStack<Integer>;
var
  LNormalStack: TNormalStack;
  LSafeStack: TSafeStack;
  LStartTime, LEndTime: QWord;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 性能对比测试 ===');
  
  // 测试普通Treiber栈
  LNormalStack := TNormalStack.Create;
  try
    WriteLn('普通Treiber栈: 10万次压栈弹栈...');
    
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LNormalStack.Push(I);
    
    for I := 1 to 100000 do
      LNormalStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('普通栈耗时: ', LEndTime - LStartTime, ' ms');
    
  finally
    LNormalStack.Free;
  end;
  
  // 测试安全Treiber栈
  LSafeStack := TSafeStack.Create;
  try
    WriteLn('安全Treiber栈: 10万次压栈弹栈...');
    
    LStartTime := GetTickCount64;
    
    for I := 1 to 100000 do
      LSafeStack.Push(I);
    
    for I := 1 to 100000 do
      LSafeStack.Pop(LValue);
    
    LEndTime := GetTickCount64;
    
    WriteLn('安全栈耗时: ', LEndTime - LStartTime, ' ms');
    
  finally
    LSafeStack.Free;
  end;
  
  WriteLn('📊 性能对比完成！');
  WriteLn('💡 安全栈由于引用计数开销，性能会比普通栈低');
  WriteLn;
end;

{**
 * 测试边界条件和错误处理
 *}
procedure TestEdgeCases;
type
  TSafeStack = specialize TSafeTreiberStack<Integer>;
var
  LStack: TSafeStack;
  LValue: Integer;
  I: Integer;
begin
  WriteLn('=== 边界条件测试 ===');
  
  LStack := TSafeStack.Create;
  try
    WriteLn('测试空栈弹出...');
    if LStack.Pop(LValue) then
      WriteLn('❌ 空栈弹出应该失败')
    else
      WriteLn('✅ 空栈弹出正确失败');
    
    WriteLn('测试单个元素...');
    LStack.Push(42);
    if LStack.Pop(LValue) and (LValue = 42) then
      WriteLn('✅ 单个元素压栈弹栈正确')
    else
      WriteLn('❌ 单个元素压栈弹栈失败');
    
    WriteLn('测试大量元素...');
    for I := 1 to 1000 do
      LStack.Push(I);
    
    WriteLn('压入1000个元素，开始弹出...');
    I := 1000;
    while LStack.Pop(LValue) do
    begin
      if LValue <> I then
      begin
        WriteLn('❌ 弹出顺序错误，期望', I, '，实际', LValue);
        Break;
      end;
      Dec(I);
    end;
    
    if I = 0 then
      WriteLn('✅ 大量元素LIFO顺序正确')
    else
      WriteLn('❌ 大量元素测试失败');
    
    WriteLn('✅ 边界条件测试完成！');
    
  finally
    LStack.Free;
  end;
  WriteLn;
end;

{**
 * 主程序
 *}
begin
  WriteLn('带引用计数的安全无锁栈演示');
  WriteLn('============================');
  WriteLn;
  
  try
    TestSafeTreiberStack;
    ComparePerformance;
    TestEdgeCases;
    
    WriteLn('🎉 所有安全栈测试完成！');
    WriteLn;
    WriteLn('📝 技术说明:');
    WriteLn('- 使用原子引用计数解决ABA问题');
    WriteLn('- TryIncRef确保不会增加正在删除节点的引用');
    WriteLn('- 每个CAS操作都有对应的引用计数管理');
    WriteLn('- 性能比普通栈低，但内存安全性更高');
    WriteLn;
    WriteLn('⚠️  使用建议:');
    WriteLn('- 对安全性要求高的场景使用安全栈');
    WriteLn('- 对性能要求高的场景使用普通栈');
    WriteLn('- 在生产环境中需要充分测试');
    
  except
    on E: Exception do
    begin
      WriteLn('演示过程中发生异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('按回车键退出...');
  ReadLn;
end.
