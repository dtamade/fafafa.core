unit fafafa.core.simd;

{$mode objfpc}{$H+}
{$ifdef FAFAFA_SIMD_NO_ASM}
  {$define DISABLE_X86_ASM}
{$endif}


interface

uses
  SysUtils, fafafa.core.simd.types;

type
  // 指令集标识（仅作 Profile 标识，不直接暴露实现细节）
  TSimdISA = (
    SCALAR,
    SSE2, AVX2, // x86/x64
    NEON,       // AArch64
    AVX_512,    // x86 高端
    SVE, SVE2   // ARM 高端
  );



  // 函数类型定义（对外稳定接口）
  TMemEqualFunc      = function(a, b: Pointer; len: SizeUInt): LongBool;
  TMemFindByteFunc   = function(p: Pointer; len: SizeUInt; value: Byte): PtrInt;
  TMemDiffRangeFunc  = function(a, b: Pointer; len: SizeUInt): TDiffRange;

  TUtf8ValidateFunc  = function(p: Pointer; len: SizeUInt): LongBool;
  TAsciiCaseProc     = procedure(p: Pointer; len: SizeUInt);
  TAsciiIeqFunc      = function(a, b: Pointer; len: SizeUInt): LongBool;

  TPopCountFunc      = function(p: Pointer; bitLen: SizeUInt): SizeUInt;

  // 搜索
  TBytesIndexOfFunc  = function(hay: Pointer; len: SizeUInt; ned: Pointer; nlen: SizeUInt): PtrInt;

// 对外函数变量（初始化时绑定到最佳实现；无 SIMD 时为标量）
var
  MemEqual:      TMemEqualFunc;
  MemFindByte:   TMemFindByteFunc;
  MemDiffRange:  TMemDiffRangeFunc;

  Utf8Validate:  TUtf8ValidateFunc;
  ToLowerAscii:  TAsciiCaseProc;
  ToUpperAscii:  TAsciiCaseProc;
  AsciiIEqual:   TAsciiIeqFunc;

  BitsetPopCount: TPopCountFunc;

  // 搜索
  BytesIndexOf:  TBytesIndexOfFunc;

// 运行时信息与控制
function SimdInfo: string;
procedure SimdSetForcedProfile(const AName: string);
function SimdGetForcedProfile: string;

implementation

uses
  fafafa.core.simd.detect,
  fafafa.core.simd.mem,
  fafafa.core.simd.text,
  fafafa.core.simd.bitset,
  fafafa.core.simd.search;

{$IFDEF CPUX86_64}
procedure _assert_abi_safety; inline;
begin
  // 预留：可在调试模式下静态断言/运行时检查 ABI 假设
end;
{$ENDIF}

const
  ENV_FORCE = 'FAFAFA_SIMD_FORCE';

var
  GProfileName: string = '';
  GForcedProfile: string = '';

procedure BindScalar;
begin
  // 绑定标量参考实现（默认安全路径）
  MemEqual      := @MemEqual_Scalar;
  MemFindByte   := @MemFindByte_Scalar;
  MemDiffRange  := @MemDiffRange_Scalar;

  Utf8Validate  := @Utf8Validate_Scalar;
  ToLowerAscii  := @ToLowerAscii_Scalar;
  ToUpperAscii  := @ToUpperAscii_Scalar;
  AsciiIEqual   := @AsciiEqualIgnoreCase_Scalar;

  BitsetPopCount := @BitsetPopCount_Scalar;

  BytesIndexOf  := @BytesIndexOf_Scalar;
end;

procedure BindBestAvailable;
var
  profile: string;
begin
  // 默认先绑定标量，随后按 profile 选择性覆盖
  BindScalar;

  {$IFDEF DISABLE_X86_ASM}
  // 在禁用 ASM 的配置下，直接保持 SCALAR 绑定避免混用路径
  GProfileName := 'SCALAR';
  Exit;
  {$ENDIF}

  // 尊重强制 Profile（环境变量或显式设置）；避免在强制场景下进入探测流程
  if GForcedProfile <> '' then
  begin
    {$IFDEF CPUX86_64}
    profile := 'X86_64-' + GForcedProfile;
    {$ELSEIF Defined(CPUAARCH64)}
    profile := 'AARCH64-' + GForcedProfile;
    {$ELSE}
    profile := GForcedProfile; // Fallback
    {$ENDIF}
  end
  else
    profile := DetectBestProfile('');
  GProfileName := profile;

  // x86_64: 为确保稳定，先全局绑定 SCALAR；专项测试中通过环境/接口强制 SSE2/AVX2
  {$IFDEF CPUX86_64}
  // 按 Profile 渐进恢复绑定（先恢复 MemFindByte_SSE2）
  if (Pos('X86_64-SSE2', profile) = 1) then
  begin
    MemFindByte  := @MemFindByte_SSE2;
    BytesIndexOf := @BytesIndexOf_SSE2;
  end;
  {$ENDIF}

  {$IFDEF CPUAARCH64}
  {$IFDEF FAFAFA_SIMD_NEON_ASM}
    if (Pos('AARCH64-NEON', profile) = 1) or (profile = 'AARCH64-NEON') then
    begin
      MemEqual      := @MemEqual_NEON;
      MemFindByte   := @MemFindByte_NEON;
      MemDiffRange  := @MemDiffRange_NEON;
      ToLowerAscii  := @ToLowerAscii_NEON;
      ToUpperAscii  := @ToUpperAscii_NEON;
      Utf8Validate  := @Utf8Validate_NEON_ASCII;
      BytesIndexOf  := @BytesIndexOf_NEON;
    end;
  {$ENDIF}
  {$ENDIF}
end;

function SimdInfo: string;
begin
  if GProfileName = '' then
    Result := 'SCALAR'
  else
    Result := GProfileName;
end;

procedure SimdSetForcedProfile(const AName: string);
begin
  GForcedProfile := Trim(UpperCase(AName));
  // 交给 detect 模块处理强制策略，同时重新派发绑定
  BindBestAvailable;
end;

function SimdGetForcedProfile: string;
begin
  Result := GForcedProfile;
end;

initialization
  // 环境变量强制优先
  GForcedProfile := GetEnvironmentVariable(ENV_FORCE);
  if GForcedProfile <> '' then
    GForcedProfile := UpperCase(GForcedProfile);

  // 绑定实现并记录 Profile
  BindBestAvailable;

end.

