program minimal_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.vec;

var
  LVec: specialize TVec<Integer>;

begin
  WriteLn('开始最小测试...');
  
  try
    WriteLn('创建 TVec...');
    LVec := specialize TVec<Integer>.Create;
    WriteLn('TVec 创建成功');
    
    WriteLn('检查基本属性...');
    WriteLn('IsEmpty: ', LVec.IsEmpty);
    WriteLn('Count: ', LVec.GetCount);
    WriteLn('Capacity: ', LVec.GetCapacity);
    
    WriteLn('释放 TVec...');
    LVec.Free;
    WriteLn('TVec 释放成功');
    
  except
    on E: Exception do
    begin
      WriteLn('异常: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn('测试完成');
end.
