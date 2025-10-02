unit fafafa.core.simd.cpuinfo.x86.asm;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{$ASMMODE INTEL}

interface

// 外部汇编函数：执行真实的 CPUID 指令
type
  TCPUIDResult = array[0..3] of DWord;

function ExecuteRealCPUID(leaf: DWord): TCPUIDResult;
function ExecuteRealCPUIDEX(leaf, ecx_in: DWord): TCPUIDResult;

implementation

// 使用与成功测试完全相同的实现
function ExecuteRealCPUID(leaf: DWord): array[0..3] of DWord;
{$IFDEF CPUX86_64}
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    // 保存寄存�?    push rbx

    // 设置输入
    mov eax, leaf

    // 执行 CPUID
    cpuid

    // 保存结果到局部变�?    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx

    // 恢复寄存�?    pop rbx
  end;

  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;
{$ELSE}
var
  temp_eax, temp_ebx, temp_ecx, temp_edx: DWord;
begin
  asm
    push ebx
    push edi
    
    mov eax, leaf
    cpuid
    
    mov temp_eax, eax
    mov temp_ebx, ebx
    mov temp_ecx, ecx
    mov temp_edx, edx
    
    pop edi
    pop ebx
  end;
  
  eax_out := temp_eax;
  ebx_out := temp_ebx;
  ecx_out := temp_ecx;
  edx_out := temp_edx;
end;
{$ENDIF}

function ExecuteRealCPUIDEX(leaf, ecx_in: DWord): TCPUIDResult;
{$IFDEF CPUX86_64}
var
  result_eax, result_ebx, result_ecx, result_edx: DWord;
begin
  asm
    push rbx

    mov eax, leaf
    mov ecx, ecx_in
    cpuid

    mov result_eax, eax
    mov result_ebx, ebx
    mov result_ecx, ecx
    mov result_edx, edx

    pop rbx
  end;

  Result[0] := result_eax;
  Result[1] := result_ebx;
  Result[2] := result_ecx;
  Result[3] := result_edx;
end;
{$ELSE}
var
  temp_eax, temp_ebx, temp_ecx, temp_edx: DWord;
begin
  asm
    push ebx
    push edi
    
    mov eax, leaf
    mov ecx, ecx_in
    cpuid
    
    mov temp_eax, eax
    mov temp_ebx, ebx
    mov temp_ecx, ecx
    mov temp_edx, edx
    
    pop edi
    pop ebx
  end;
  
  eax_out := temp_eax;
  ebx_out := temp_ebx;
  ecx_out := temp_ecx;
  edx_out := temp_edx;
end;
{$ENDIF}

end.


