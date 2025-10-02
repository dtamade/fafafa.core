program test_direct_cpuid;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}
{$ASMMODE INTEL}

uses
  SysUtils;

// 最直接的 CPUID 测试
procedure DirectCPUID;
var
  eax, ebx, ecx, edx: DWord;
  vendor: string;
begin
  WriteLn('=== 最直接的 CPUID 测试 ===');
  
  // 方法1：直接内联汇编
  WriteLn('方法1：直接内联汇编');
  try
    asm
      push rbx
      
      mov eax, 0
      cpuid
      
      mov eax, eax
      mov ebx, ebx
      mov ecx, ecx
      mov edx, edx
      
      pop rbx
    end;
    
    WriteLn('  EAX: $', IntToHex(eax, 8));
    WriteLn('  EBX: $', IntToHex(ebx, 8));
    WriteLn('  ECX: $', IntToHex(ecx, 8));
    WriteLn('  EDX: $', IntToHex(edx, 8));
    
    // 构造厂商字符串
    SetLength(vendor, 12);
    Move(ebx, vendor[1], 4);
    Move(edx, vendor[5], 4);
    Move(ecx, vendor[9], 4);
    WriteLn('  厂商: "', vendor, '"');
    
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
  
  // 方法2：使用局部变量
  WriteLn('');
  WriteLn('方法2：使用局部变量');
  try
    eax := 0; ebx := 0; ecx := 0; edx := 0;
    
    asm
      push rbx
      
      mov eax, 0
      cpuid
      
      mov eax, eax
      mov ebx, ebx
      mov ecx, ecx
      mov edx, edx
      
      pop rbx
    end;
    
    WriteLn('  EAX: $', IntToHex(eax, 8));
    WriteLn('  EBX: $', IntToHex(ebx, 8));
    WriteLn('  ECX: $', IntToHex(ecx, 8));
    WriteLn('  EDX: $', IntToHex(edx, 8));
    
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
  
  // 方法3：检查 CPUID 是否可用
  WriteLn('');
  WriteLn('方法3：检查 CPUID 可用性');
  try
    asm
      // 检查 CPUID 是否可用
      pushfq
      pop rax
      mov rcx, rax
      xor rax, $200000
      push rax
      popfq
      pushfq
      pop rax
      xor rax, rcx
      mov eax, eax
    end;
    
    if (eax and $200000) <> 0 then
      WriteLn('  CPUID 可用')
    else
      WriteLn('  CPUID 不可用');
      
  except
    on E: Exception do
      WriteLn('  错误: ', E.Message);
  end;
end;

begin
  try
    DirectCPUID;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('按任意键退出...');
  ReadLn;
end.
