unit fafafa.core.simd.detect;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}

interface

uses
  fafafa.core.simd.types;

// === SIMD 能力检测（真正的硬件检测）===

// 主检测函数
function DetectSimdCapabilities: TSimdISASet;
function GetBestProfile: String;

// x86_64 特定检测
{$IFDEF CPUX86_64}
function HasSSE2: Boolean;
function HasSSE3: Boolean;
function HasSSSE3: Boolean;
function HasSSE41: Boolean;
function HasSSE42: Boolean;
function HasAVX: Boolean;
function HasAVX2: Boolean;
function HasAVX512F: Boolean;
function HasAVX512VL: Boolean;
function HasAVX512BW: Boolean;
function HasAVX512DQ: Boolean;
function HasPopcnt: Boolean;
{$ENDIF}

// ARM64 特定检测
{$IFDEF CPUAARCH64}
function HasNEON: Boolean;
function HasSVE: Boolean;
function HasSVE2: Boolean;
{$ENDIF}

// 操作系统支持检测
function OSSupportsAVX: Boolean;
function OSSupportsAVX512: Boolean;

implementation

uses
  SysUtils;

{$IFDEF CPUX86_64}
// CPUID 辅助函数 - 改进的实现
procedure CPUID(leaf: Cardinal; out eax, ebx, ecx, edx: Cardinal);
{$IFDEF CPUX86_64}
var
  a, b, c, d: Cardinal;
begin
  // 使用内联汇编实现真实的 CPUID 调用
  asm
    mov eax, leaf
    cpuid
    mov a, eax
    mov b, ebx
    mov c, ecx
    mov d, edx
  end;
  eax := a;
  ebx := b;
  ecx := c;
  edx := d;
end;
{$ELSE}
begin
  // 非 x86_64 平台的模拟实现
  eax := 0;
  ebx := 0;
  ecx := 0;
  edx := 0;

  case leaf of
    0: begin
      eax := 13; // 最大支持的标准功能号
      ebx := $756E6547; // "Genu"
      ecx := $6C65746E; // "ntel"
      edx := $49656E69; // "ineI"
    end;
    1: begin
      eax := $000306A9; // 示例处理器签名
      ebx := 0;
      ecx := $80000000; // 一些功能标志
      edx := $178BFBFF; // 一些功能标志
    end;
    7: begin
      eax := 0;
      ebx := $00000000; // 无扩展功能
      ecx := 0;
      edx := 0;
    end;
  end;
end;
{$ENDIF}

// XGETBV 指令（检测操作系统AVX支持）
function XGETBV(xcr: Cardinal): QWord; assembler;
asm
  mov ecx, xcr
  xgetbv
  // 结果在 EDX:EAX 中，组合成 64 位
  shl rdx, 32
  or rax, rdx
end;

function HasSSE2: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (edx and (1 shl 26)) <> 0; // SSE2 bit
end;

function HasSSE3: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (ecx and (1 shl 0)) <> 0; // SSE3 bit
end;

function HasSSSE3: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (ecx and (1 shl 9)) <> 0; // SSSE3 bit
end;

function HasSSE41: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (ecx and (1 shl 19)) <> 0; // SSE4.1 bit
end;

function HasSSE42: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (ecx and (1 shl 20)) <> 0; // SSE4.2 bit
end;

function HasAVX: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  // 检查 OSXSAVE 和 AVX 位
  Result := ((ecx and (1 shl 27)) <> 0) and ((ecx and (1 shl 28)) <> 0);
  if Result then
    Result := OSSupportsAVX;
end;

function HasAVX2: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  if not HasAVX then Exit(False);
  
  CPUID(7, eax, ebx, ecx, edx);
  Result := (ebx and (1 shl 5)) <> 0; // AVX2 bit
end;

function HasAVX512F: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  if not HasAVX then Exit(False);
  
  CPUID(7, eax, ebx, ecx, edx);
  Result := (ebx and (1 shl 16)) <> 0; // AVX-512F bit
  if Result then
    Result := OSSupportsAVX512;
end;

function HasAVX512VL: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  if not HasAVX512F then Exit(False);
  
  CPUID(7, eax, ebx, ecx, edx);
  Result := (ebx and (1 shl 31)) <> 0; // AVX-512VL bit
end;

function HasAVX512BW: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  if not HasAVX512F then Exit(False);
  
  CPUID(7, eax, ebx, ecx, edx);
  Result := (ebx and (1 shl 30)) <> 0; // AVX-512BW bit
end;

function HasAVX512DQ: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  if not HasAVX512F then Exit(False);
  
  CPUID(7, eax, ebx, ecx, edx);
  Result := (ebx and (1 shl 17)) <> 0; // AVX-512DQ bit
end;

function HasPopcnt: Boolean;
var
  eax, ebx, ecx, edx: Cardinal;
begin
  CPUID(1, eax, ebx, ecx, edx);
  Result := (ecx and (1 shl 23)) <> 0; // POPCNT bit
end;

function OSSupportsAVX: Boolean;
var
  xcr0: QWord;
begin
  try
    xcr0 := XGETBV(0);
    // 检查 XMM 和 YMM 状态保存
    Result := (xcr0 and $06) = $06;
  except
    Result := False;
  end;
end;

function OSSupportsAVX512: Boolean;
var
  xcr0: QWord;
begin
  try
    xcr0 := XGETBV(0);
    // 检查 XMM, YMM, 和 ZMM 状态保存
    Result := (xcr0 and $E6) = $E6;
  except
    Result := False;
  end;
end;

{$ENDIF} // CPUX86_64

{$IFDEF CPUAARCH64}
function HasNEON: Boolean;
begin
  // ARM64 默认支持 NEON
  Result := True;
end;

function HasSVE: Boolean;
begin
  // TODO: 实现 SVE 检测
  // 需要读取 ID_AA64PFR0_EL1 寄存器
  Result := False;
end;

function HasSVE2: Boolean;
begin
  // TODO: 实现 SVE2 检测
  Result := False;
end;
{$ENDIF} // CPUAARCH64

{$IFNDEF CPUX86_64}
{$IFNDEF CPUAARCH64}
function OSSupportsAVX: Boolean;
begin
  Result := False;
end;

function OSSupportsAVX512: Boolean;
begin
  Result := False;
end;
{$ENDIF}
{$ENDIF}

function DetectSimdCapabilities: TSimdISASet;
begin
  Result := [isaScalar]; // 标量总是可用
  
  {$IFDEF CPUX86_64}
  if HasSSE2 then Result := Result + [isaSSE2];
  if HasSSE3 then Result := Result + [isaSSE3];
  if HasSSSE3 then Result := Result + [isaSSSE3];
  if HasSSE41 then Result := Result + [isaSSE41];
  if HasSSE42 then Result := Result + [isaSSE42];
  if HasAVX then Result := Result + [isaAVX];
  if HasAVX2 then Result := Result + [isaAVX2];
  if HasAVX512F then Result := Result + [isaAVX512F];
  if HasAVX512VL then Result := Result + [isaAVX512VL];
  if HasAVX512BW then Result := Result + [isaAVX512BW];
  if HasAVX512DQ then Result := Result + [isaAVX512DQ];
  {$ENDIF}
  
  {$IFDEF CPUAARCH64}
  if HasNEON then Result := Result + [isaNEON];
  if HasSVE then Result := Result + [isaSVE];
  if HasSVE2 then Result := Result + [isaSVE2];
  {$ENDIF}
end;

function GetBestProfile: String;
var
  caps: TSimdISASet;
begin
  caps := DetectSimdCapabilities;
  
  {$IFDEF CPUX86_64}
  if isaAVX512F in caps then
    Result := 'X86_64-AVX512F'
  else if isaAVX2 in caps then
    Result := 'X86_64-AVX2'
  else if isaAVX in caps then
    Result := 'X86_64-AVX'
  else if isaSSE42 in caps then
    Result := 'X86_64-SSE42'
  else if isaSSE41 in caps then
    Result := 'X86_64-SSE41'
  else if isaSSE2 in caps then
    Result := 'X86_64-SSE2'
  else
    Result := 'X86_64-SCALAR';
  {$ENDIF}
  
  {$IFDEF CPUAARCH64}
  if isaSVE2 in caps then
    Result := 'AARCH64-SVE2'
  else if isaSVE in caps then
    Result := 'AARCH64-SVE'
  else if isaNEON in caps then
    Result := 'AARCH64-NEON'
  else
    Result := 'AARCH64-SCALAR';
  {$ENDIF}
  
  {$IFNDEF CPUX86_64}
  {$IFNDEF CPUAARCH64}
  Result := 'UNKNOWN-SCALAR';
  {$ENDIF}
  {$ENDIF}
end;

end.
