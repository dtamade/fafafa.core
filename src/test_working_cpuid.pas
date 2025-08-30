program test_working_cpuid;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$ASMMODE INTEL}

uses
  SysUtils;

procedure GetCPUID(leaf: DWord; out eax, ebx, ecx, edx: DWord);
begin
  {$IFDEF CPUX86_64}
  asm
    push rbx
    mov eax, leaf
    cpuid
    mov eax, eax
    mov ebx, ebx
    mov ecx, ecx
    mov edx, edx
    pop rbx
  end;
  {$ELSE}
  asm
    push ebx
    mov eax, leaf
    cpuid
    mov eax, eax
    mov ebx, ebx
    mov ecx, ecx
    mov edx, edx
    pop ebx
  end;
  {$ENDIF}
end;

var
  eax, ebx, ecx, edx: DWord;
  vendor: string;

begin
  WriteLn('=== 工作的 CPUID 测试 ===');
  
  // 测试叶子 0
  GetCPUID(0, eax, ebx, ecx, edx);
  WriteLn('CPUID(0):');
  WriteLn('  EAX: $', IntToHex(eax, 8));
  WriteLn('  EBX: $', IntToHex(ebx, 8));
  WriteLn('  ECX: $', IntToHex(ecx, 8));
  WriteLn('  EDX: $', IntToHex(edx, 8));
  
  // 构造厂商字符串
  SetLength(vendor, 12);
  Move(ebx, vendor[1], 4);
  Move(edx, vendor[5], 4);
  Move(ecx, vendor[9], 4);
  WriteLn('厂商: "', vendor, '"');
  
  // 测试叶子 1
  GetCPUID(1, eax, ebx, ecx, edx);
  WriteLn('');
  WriteLn('CPUID(1) 特性:');
  WriteLn('  SSE: ', (edx and (1 shl 25)) <> 0);
  WriteLn('  SSE2: ', (edx and (1 shl 26)) <> 0);
  WriteLn('  SSE3: ', (ecx and (1 shl 0)) <> 0);
  WriteLn('  AVX: ', (ecx and (1 shl 28)) <> 0);
  
  WriteLn('');
  WriteLn('按任意键退出...');
  ReadLn;
end.
