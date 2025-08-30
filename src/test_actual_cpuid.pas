program test_actual_cpuid;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$ASMMODE INTEL}

uses
  SysUtils;

// 真实的 CPUID 实现 - 使用更简单的方法
type
  TCPUIDResult = array[0..3] of DWord;

function ActualCPUID(leaf: DWord): TCPUIDResult;
{$IFDEF CPUX86_64}
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    // 保存寄存器
    push rbx
    
    // 设置输入
    mov eax, leaf
    
    // 执行 CPUID
    cpuid
    
    // 保存结果到局部变量
    mov result_eax, eax
    mov result_ebx, ebx  
    mov result_ecx, ecx
    mov result_edx, edx
    
    // 恢复寄存器
    pop rbx
  end;
  
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;
{$ELSE}
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push ebx
    push edi
    
    mov eax, leaf
    cpuid
    
    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx
    
    pop edi
    pop ebx
  end;
  
  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;
{$ENDIF}

procedure TestActualCPUID;
var
  regs: array[0..3] of DWord;
  vendor: string;
begin
  WriteLn('=== 真实 CPUID 测试 ===');
  
  try
    // 测试叶子 0
    regs := ActualCPUID(0);
    WriteLn('叶子 0 (厂商信息):');
    WriteLn('  EAX: $', IntToHex(regs[0], 8));
    WriteLn('  EBX: $', IntToHex(regs[1], 8));
    WriteLn('  ECX: $', IntToHex(regs[2], 8));
    WriteLn('  EDX: $', IntToHex(regs[3], 8));
    
    // 构造厂商字符串
    SetLength(vendor, 12);
    Move(regs[1], vendor[1], 4);  // EBX
    Move(regs[3], vendor[5], 4);  // EDX
    Move(regs[2], vendor[9], 4);  // ECX
    WriteLn('  厂商: "', vendor, '"');
    
    // 测试叶子 1
    regs := ActualCPUID(1);
    WriteLn('');
    WriteLn('叶子 1 (特性标志):');
    WriteLn('  EAX: $', IntToHex(regs[0], 8));
    WriteLn('  EBX: $', IntToHex(regs[1], 8));
    WriteLn('  ECX: $', IntToHex(regs[2], 8));
    WriteLn('  EDX: $', IntToHex(regs[3], 8));
    
    WriteLn('  特性检查:');
    WriteLn('    SSE: ', (regs[3] and (1 shl 25)) <> 0);
    WriteLn('    SSE2: ', (regs[3] and (1 shl 26)) <> 0);
    WriteLn('    SSE3: ', (regs[2] and (1 shl 0)) <> 0);
    WriteLn('    SSSE3: ', (regs[2] and (1 shl 9)) <> 0);
    WriteLn('    SSE4.1: ', (regs[2] and (1 shl 19)) <> 0);
    WriteLn('    SSE4.2: ', (regs[2] and (1 shl 20)) <> 0);
    WriteLn('    AVX: ', (regs[2] and (1 shl 28)) <> 0);
    
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('');
  WriteLn('=== 测试完成 ===');
end;

begin
  try
    TestActualCPUID;
  except
    on E: Exception do
      WriteLn('致命错误: ', E.Message);
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
