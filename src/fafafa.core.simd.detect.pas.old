unit fafafa.core.simd.detect;

{$mode objfpc}{$H+}
{$IFDEF CPUX86_64}{$asmmode intel}{$ENDIF}

interface

// 返回最佳 Profile 名称（如 "X86_64-AVX2"、"AARCH64-NEON"、"SCALAR"）。
// 当 AForced 非空时，按其强制（SCALAR|SSE2|AVX2|NEON|AVX-512|SVE|SVE2）。
function DetectBestProfile(const AForced: string = ''): string;
// x86_64: 检测 POPCNT 指令（leaf 1, ECX bit 23）；其他平台返回 False
function HasPopcnt: Boolean;
// x86_64: 检测 AVX/AVX2 可用性（CPUID leaf 1: OSXSAVE/AVX；leaf 7: AVX2；XGETBV 确认 XMM/YMM 保存）
function HasAVX2: Boolean;

implementation

uses
  SysUtils;

function CPUArchProfile: string;
begin
  {$IFDEF CPUX86_64}
  Result := 'X86_64';
  {$ELSEIF Defined(CPUAARCH64)}
  Result := 'AARCH64';
  {$ELSE}
  Result := 'UNKNOWN-ARCH';
  {$ENDIF}
end;

function HasPopcnt: Boolean;
{$IFDEF CPUX86_64}
var
  a, b, c, d: DWord;
begin
  asm
    push    rbx             // preserve non-volatile
    mov     eax, 1
    cpuid
    mov     a, eax
    mov     b, ebx
    mov     c, ecx
    mov     d, edx
    pop     rbx
  end;
  Result := (c and (1 shl 23)) <> 0;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function HasAVX2: Boolean;
{$IFDEF CPUX86_64}
var
  a, b, c, d: DWord;
  xcr0lo, xcr0hi: DWord;
  hasOSXSAVE, hasAVX, avx2Flag: Boolean;
begin
  // CPUID leaf 1
  asm
    push    rbx
    mov     eax, 1
    cpuid
    mov     a, eax
    mov     b, ebx
    mov     c, ecx
    mov     d, edx
    pop     rbx
  end;
  hasOSXSAVE := (c and (1 shl 27)) <> 0;
  hasAVX     := (c and (1 shl 28)) <> 0;
  if not (hasOSXSAVE and hasAVX) then Exit(False);
  // XGETBV(XCR0)
  asm
    xor ecx, ecx
    db $0F,$01,$D0 // xgetbv
    mov xcr0lo, eax
    mov xcr0hi, edx
  end;
  if ((xcr0lo and 2) = 0) or ((xcr0lo and 4) = 0) then Exit(False);
  // CPUID leaf 7 subleaf 0
  asm
    push    rbx
    mov     eax, 7
    xor     ecx, ecx
    cpuid
    mov     a, eax
    mov     b, ebx
    mov     c, ecx
    mov     d, edx
    pop     rbx
  end;
  avx2Flag := (b and (1 shl 5)) <> 0;
  Result := avx2Flag;
end;
{$ELSE}
begin
  Result := False;
end;
{$ENDIF}

function DetectBestProfile(const AForced: string): string;
var
  arch: string;
  forced: string;
begin
  forced := Trim(UpperCase(AForced));
  if forced <> '' then
  begin
    if forced = 'AVX512' then forced := 'AVX-512';
    if (forced='SCALAR') or (forced='SSE2') or (forced='AVX2') or (forced='NEON') or
       (forced='AVX-512') or (forced='SVE') or (forced='SVE2') then
      Exit(CPUArchProfile + '-' + forced);
  end;

  arch := CPUArchProfile;
  if arch = 'X86_64' then
  begin
    // 先尝试 AVX2，再回退 SSE2；若探测异常，默认 SSE2 保守路径
    try
      if HasAVX2 then Exit('X86_64-AVX2') else Exit('X86_64-SSE2');
    except
      Exit('X86_64-SSE2');
    end;
  end
  else if arch = 'AARCH64' then
    Exit('AARCH64-NEON')
  else
    Exit('SCALAR');
end;

end.

