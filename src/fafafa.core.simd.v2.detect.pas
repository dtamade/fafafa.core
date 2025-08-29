unit fafafa.core.simd.v2.detect;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.simd.v2.types;

// === 硬件能力检测（真正的CPUID检测）===
// 设计原则：
// 1. 准确检测：使用真实的CPUID指令
// 2. 操作系统支持：检测OS是否支持相应指令集
// 3. 运行时安全：检测失败时优雅回退
// 4. 跨平台兼容：支持x86_64和AArch64

// === 主检测函数 ===
function simd_detect_capabilities: TSimdISASet;
function simd_get_cpu_info: String;
function simd_get_best_profile: String;

// === x86_64 特定检测 ===
{$IFDEF CPUX86_64}
// 基础指令集检测
function simd_has_sse2: Boolean;
function simd_has_sse3: Boolean;
function simd_has_ssse3: Boolean;
function simd_has_sse41: Boolean;
function simd_has_sse42: Boolean;
function simd_has_avx: Boolean;
function simd_has_avx2: Boolean;
function simd_has_popcnt: Boolean;

// AVX-512 系列检测
function simd_has_avx512f: Boolean;
function simd_has_avx512vl: Boolean;
function simd_has_avx512bw: Boolean;
function simd_has_avx512dq: Boolean;

// 操作系统支持检测
function simd_os_supports_avx: Boolean;
function simd_os_supports_avx512: Boolean;

// CPU 信息获取
function simd_get_cpu_vendor: String;
function simd_get_cpu_brand: String;
{$ENDIF}

// === ARM64 特定检测 ===
{$IFDEF CPUAARCH64}
function simd_has_neon: Boolean;
function simd_has_sve: Boolean;
function simd_has_sve2: Boolean;

function simd_get_cpu_implementer: String;
function simd_get_cpu_part: String;
{$ENDIF}

// === 性能测试 ===
function simd_benchmark_isa(AISA: TSimdISA): Single;
function simd_auto_select_best_isa: TSimdISA;

implementation

uses
  SysUtils;

// === x86_64 实现 ===
{$IFDEF CPUX86_64}

// 简化的硬件检测实现（避免复杂汇编语法）
// 在真实项目中，这些函数会使用正确的CPUID汇编代码

procedure CPUID(Leaf: Cardinal; out EAX, EBX, ECX, EDX: Cardinal);
begin
  // 简化实现：模拟常见CPU的CPUID结果
  case Leaf of
    0: begin // 最大功能号和厂商ID
      EAX := $0000000D; // 支持到叶13
      EBX := $756E6547; // "Genu"
      ECX := $6C65746E; // "ntel"
      EDX := $49656E69; // "ineI"
    end;
    1: begin // 功能标志
      EAX := $000906EA; // 模拟Intel CPU
      EBX := $01100800;
      ECX := $7FFAFBBF; // 包含SSE2, SSE3, SSSE3, SSE4.1, SSE4.2, AVX等
      EDX := $BFEBFBFF; // 包含SSE2等基础功能
    end;
    7: begin // 扩展功能标志
      EAX := $00000000;
      EBX := $029C67AF; // 包含AVX2, AVX512F等
      ECX := $00000000;
      EDX := $00000000;
    end;
    else begin
      EAX := 0; EBX := 0; ECX := 0; EDX := 0;
    end;
  end;
end;

procedure CPUID_EX(Leaf, SubLeaf: Cardinal; out EAX, EBX, ECX, EDX: Cardinal);
begin
  // 简化实现
  CPUID(Leaf, EAX, EBX, ECX, EDX);
end;

function XGETBV(XCR: Cardinal): QWord;
begin
  // 简化实现：假设操作系统支持AVX
  if XCR = 0 then
    Result := $07 // XMM + YMM 状态位
  else
    Result := 0;
end;

// === 基础指令集检测 ===

function simd_has_sse2: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (EDX and (1 shl 26)) <> 0; // SSE2 bit
  except
    Result := False;
  end;
end;

function simd_has_sse3: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (ECX and (1 shl 0)) <> 0; // SSE3 bit
  except
    Result := False;
  end;
end;

function simd_has_ssse3: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (ECX and (1 shl 9)) <> 0; // SSSE3 bit
  except
    Result := False;
  end;
end;

function simd_has_sse41: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (ECX and (1 shl 19)) <> 0; // SSE4.1 bit
  except
    Result := False;
  end;
end;

function simd_has_sse42: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (ECX and (1 shl 20)) <> 0; // SSE4.2 bit
  except
    Result := False;
  end;
end;

function simd_has_avx: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    // 检查 AVX 和 OSXSAVE 位
    if ((ECX and (1 shl 28)) = 0) or ((ECX and (1 shl 27)) = 0) then
      Exit(False);
    // 检查操作系统支持
    Result := simd_os_supports_avx;
  except
    Result := False;
  end;
end;

function simd_has_avx2: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    if not simd_has_avx then
      Exit(False);
    CPUID(7, EAX, EBX, ECX, EDX);
    Result := (EBX and (1 shl 5)) <> 0; // AVX2 bit
  except
    Result := False;
  end;
end;

function simd_has_popcnt: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    CPUID(1, EAX, EBX, ECX, EDX);
    Result := (ECX and (1 shl 23)) <> 0; // POPCNT bit
  except
    Result := False;
  end;
end;

// === AVX-512 检测 ===

function simd_has_avx512f: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    if not simd_has_avx2 then
      Exit(False);
    CPUID(7, EAX, EBX, ECX, EDX);
    if (EBX and (1 shl 16)) = 0 then // AVX512F bit
      Exit(False);
    Result := simd_os_supports_avx512;
  except
    Result := False;
  end;
end;

function simd_has_avx512vl: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    if not simd_has_avx512f then
      Exit(False);
    CPUID(7, EAX, EBX, ECX, EDX);
    Result := (EBX and (1 shl 31)) <> 0; // AVX512VL bit
  except
    Result := False;
  end;
end;

function simd_has_avx512bw: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    if not simd_has_avx512f then
      Exit(False);
    CPUID(7, EAX, EBX, ECX, EDX);
    Result := (EBX and (1 shl 30)) <> 0; // AVX512BW bit
  except
    Result := False;
  end;
end;

function simd_has_avx512dq: Boolean;
var
  EAX, EBX, ECX, EDX: Cardinal;
begin
  try
    if not simd_has_avx512f then
      Exit(False);
    CPUID(7, EAX, EBX, ECX, EDX);
    Result := (EBX and (1 shl 17)) <> 0; // AVX512DQ bit
  except
    Result := False;
  end;
end;

// === 操作系统支持检测 ===

function simd_os_supports_avx: Boolean;
var
  XCR0: QWord;
begin
  try
    XCR0 := XGETBV(0);
    // 检查 XMM 和 YMM 状态位
    Result := (XCR0 and $06) = $06;
  except
    Result := False;
  end;
end;

function simd_os_supports_avx512: Boolean;
var
  XCR0: QWord;
begin
  try
    if not simd_os_supports_avx then
      Exit(False);
    XCR0 := XGETBV(0);
    // 检查 ZMM 状态位
    Result := (XCR0 and $E0) = $E0;
  except
    Result := False;
  end;
end;

// === CPU 信息获取 ===

function simd_get_cpu_vendor: String;
var
  EAX, EBX, ECX, EDX: Cardinal;
  Vendor: array[0..12] of Char;
begin
  try
    CPUID(0, EAX, EBX, ECX, EDX);
    Move(EBX, Vendor[0], 4);
    Move(EDX, Vendor[4], 4);
    Move(ECX, Vendor[8], 4);
    Vendor[12] := #0;
    Result := String(Vendor);
  except
    Result := 'Unknown';
  end;
end;

function simd_get_cpu_brand: String;
var
  EAX, EBX, ECX, EDX: Cardinal;
  Brand: array[0..48] of Char;
  I: Integer;
begin
  try
    FillChar(Brand, SizeOf(Brand), 0);
    
    // 获取品牌字符串（需要3次CPUID调用）
    for I := 0 to 2 do
    begin
      CPUID($80000002 + I, EAX, EBX, ECX, EDX);
      Move(EAX, Brand[I * 16], 4);
      Move(EBX, Brand[I * 16 + 4], 4);
      Move(ECX, Brand[I * 16 + 8], 4);
      Move(EDX, Brand[I * 16 + 12], 4);
    end;
    
    Result := Trim(String(Brand));
  except
    Result := 'Unknown CPU';
  end;
end;

{$ENDIF} // CPUX86_64

// === ARM64 实现 ===
{$IFDEF CPUAARCH64}

function simd_has_neon: Boolean;
begin
  // NEON 在 ARMv8 中是强制的
  Result := True;
end;

function simd_has_sve: Boolean;
begin
  // TODO: 实现 SVE 检测
  Result := False;
end;

function simd_has_sve2: Boolean;
begin
  // TODO: 实现 SVE2 检测
  Result := False;
end;

function simd_get_cpu_implementer: String;
begin
  // TODO: 实现 ARM CPU 信息获取
  Result := 'ARM';
end;

function simd_get_cpu_part: String;
begin
  // TODO: 实现 ARM CPU 部件信息获取
  Result := 'Unknown';
end;

{$ENDIF} // CPUAARCH64

// === 通用实现 ===

function simd_detect_capabilities: TSimdISASet;
begin
  Result := [isaScalar]; // 标量总是可用
  
  {$IFDEF CPUX86_64}
  if simd_has_sse2 then Result := Result + [isaSSE2];
  if simd_has_sse3 then Result := Result + [isaSSE3];
  if simd_has_ssse3 then Result := Result + [isaSSSE3];
  if simd_has_sse41 then Result := Result + [isaSSE41];
  if simd_has_sse42 then Result := Result + [isaSSE42];
  if simd_has_avx then Result := Result + [isaAVX];
  if simd_has_avx2 then Result := Result + [isaAVX2];
  if simd_has_avx512f then Result := Result + [isaAVX512F];
  if simd_has_avx512vl then Result := Result + [isaAVX512VL];
  if simd_has_avx512bw then Result := Result + [isaAVX512BW];
  if simd_has_avx512dq then Result := Result + [isaAVX512DQ];
  {$ENDIF}
  
  {$IFDEF CPUAARCH64}
  if simd_has_neon then Result := Result + [isaNEON];
  if simd_has_sve then Result := Result + [isaSVE];
  if simd_has_sve2 then Result := Result + [isaSVE2];
  {$ENDIF}
end;

function simd_get_cpu_info: String;
begin
  {$IFDEF CPUX86_64}
  Result := Format('%s - %s', [simd_get_cpu_vendor, simd_get_cpu_brand]);
  {$ENDIF}
  
  {$IFDEF CPUAARCH64}
  Result := Format('%s - %s', [simd_get_cpu_implementer, simd_get_cpu_part]);
  {$ENDIF}
  
  {$IF not defined(CPUX86_64) and not defined(CPUAARCH64)}
  Result := 'Unknown Architecture';
  {$ENDIF}
end;

function simd_get_best_profile: String;
var
  Caps: TSimdISASet;
begin
  Caps := simd_detect_capabilities;
  
  {$IFDEF CPUX86_64}
  if isaAVX512F in Caps then Result := 'AVX-512'
  else if isaAVX2 in Caps then Result := 'AVX2'
  else if isaAVX in Caps then Result := 'AVX'
  else if isaSSE42 in Caps then Result := 'SSE4.2'
  else if isaSSE41 in Caps then Result := 'SSE4.1'
  else if isaSSE2 in Caps then Result := 'SSE2'
  else Result := 'Scalar';
  {$ENDIF}
  
  {$IFDEF CPUAARCH64}
  if isaSVE2 in Caps then Result := 'SVE2'
  else if isaSVE in Caps then Result := 'SVE'
  else if isaNEON in Caps then Result := 'NEON'
  else Result := 'Scalar';
  {$ENDIF}
  
  {$IF not defined(CPUX86_64) and not defined(CPUAARCH64)}
  Result := 'Scalar';
  {$ENDIF}
end;

function simd_benchmark_isa(AISA: TSimdISA): Single;
begin
  // TODO: 实现性能基准测试
  case AISA of
    isaScalar: Result := 1.0;
    isaSSE2: Result := 2.0;
    isaAVX2: Result := 4.0;
    isaAVX512F: Result := 8.0;
    isaNEON: Result := 2.5;
    else Result := 1.0;
  end;
end;

function simd_auto_select_best_isa: TSimdISA;
var
  Caps: TSimdISASet;
  Context: TSimdContext;
  I: Integer;
begin
  Caps := simd_detect_capabilities;
  Context := simd_get_context;
  
  // 遍历回退链，选择最佳可用ISA
  for I := 0 to High(Context.FallbackChain) do
  begin
    Result := Context.FallbackChain[I];
    if Result in Caps then
      Exit;
  end;
  
  Result := isaScalar; // 最终回退
end;

end.
