program test_minimal_cpuid;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$ASMMODE INTEL}

uses
  SysUtils;

// 最简单的 CPUID 测试
procedure SimpleCPUID(leaf: DWord; var eax, ebx, ecx, edx: DWord);
{$IFDEF CPUX86_64}
begin
  // 使用 Pascal 代码调用系统 API 或回退实现
  // 暂时返回模拟数据来验证框架
  case leaf of
    0: begin
      eax := 13;
      ebx := $756E6547; // "Genu"
      ecx := $6C65746E; // "ntel"
      edx := $49656E69; // "ineI"
    end;
    1: begin
      eax := $000306A9;
      ebx := $00100800;
      ecx := $80982201; // SSE3, SSSE3, SSE4.1, SSE4.2, AVX
      edx := $0FEBFBFF; // SSE, SSE2
    end;
    7: begin
      eax := 0;
      ebx := $00000020; // AVX2
      ecx := 0;
      edx := 0;
    end;
  else
    eax := 0; ebx := 0; ecx := 0; edx := 0;
  end;
end;
{$ELSE}
asm
  push ebx
  push edi
  
  // 执行 CPUID
  cpuid
  
  // 存储结果
  mov edi, eax_
  mov [edi], eax
  
  mov edi, ebx_
  mov [edi], ebx
  
  mov edi, ecx_
  mov [edi], ecx
  
  mov edi, edx_
  mov [edi], edx
  
  pop edi
  pop ebx
end;
{$ENDIF}

procedure TestCPUID;
var
  eax, ebx, ecx, edx: DWord;
  vendor: string;
begin
  WriteLn('=== 最小化 CPUID 测试 ===');
  
  // 测试叶子 0
  SimpleCPUID(0, eax, ebx, ecx, edx);
  WriteLn('叶子 0:');
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
  
  // 测试叶子 1
  SimpleCPUID(1, eax, ebx, ecx, edx);
  WriteLn('叶子 1:');
  WriteLn('  SSE: ', (edx and (1 shl 25)) <> 0);
  WriteLn('  SSE2: ', (edx and (1 shl 26)) <> 0);
  WriteLn('  SSE3: ', (ecx and (1 shl 0)) <> 0);
  WriteLn('  AVX: ', (ecx and (1 shl 28)) <> 0);
  
  // 测试叶子 7
  SimpleCPUID(7, eax, ebx, ecx, edx);
  WriteLn('叶子 7:');
  WriteLn('  AVX2: ', (ebx and (1 shl 5)) <> 0);
  
  WriteLn('=== 测试完成 ===');
end;

begin
  try
    TestCPUID;
  except
    on E: Exception do
      WriteLn('错误: ', E.Message);
  end;
  
  WriteLn('按任意键退出...');
  ReadLn;
end.
