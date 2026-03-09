unit fafafa.core.simd.cpuinfo.x86.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.cpuinfo.x86.base,
  fafafa.core.simd.cpuinfo.x86;

type
  // 全局函数测试
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_HasCPUID;
    procedure Test_CPUID;
    procedure Test_CPUIDEX;
    procedure Test_HasSSE;
    procedure Test_HasSSE2;
    procedure Test_HasAVX;
    procedure Test_HasAVX2;
    procedure Test_XCR0HasAVX_BitMask;
    procedure Test_XCR0HasAVX512_BitMask;
    procedure Test_GetVendorString;
    procedure Test_GetBrandString;
  end;

  TTestCase_SampleDriven = class(TTestCase)
  published
    procedure Test_X86VendorStringFromLeaf0_Samples;
    procedure Test_X86BrandStringFromExtendedLeaves_FallbackToVendor;
    procedure Test_X86FeaturesFromCPUID_AVXRequiresOSXSAVEAndXCR0;
    procedure Test_X86FeaturesFromCPUID_AVX2RequiresUsableAVX;
    procedure Test_X86FeaturesFromCPUID_AVX512RequiresFullXCR0Mask;
  end;

implementation

function PackAsciiDWord(const aText: AnsiString): DWord;
var
  LIndex: Integer;
begin
  Result := 0;
  for LIndex := 0 to 3 do
    if LIndex + 1 <= Length(aText) then
      Result := Result or (DWord(Ord(aText[LIndex + 1])) shl (LIndex * 8));
end;

function RegsFromAscii16(const aText: AnsiString): TX86CPUIDRegs;
begin
  Result := MakeX86CPUIDRegs(
    PackAsciiDWord(Copy(aText, 1, 4)),
    PackAsciiDWord(Copy(aText, 5, 4)),
    PackAsciiDWord(Copy(aText, 9, 4)),
    PackAsciiDWord(Copy(aText, 13, 4))
  );
end;

{ TTestCase_Global }

procedure TTestCase_Global.Test_HasCPUID;
begin
  // CPUID 在现代 x64 系统上应该总是可用
  AssertTrue('HasCPUID should return True on x64 systems', HasCPUID);
end;

procedure TTestCase_Global.Test_CPUID;
var
  LEax: DWord;
  LEbx: DWord;
  LEcx: DWord;
  LEdx: DWord;
  LVendor: string;
begin
  LEax := 0;
  LEbx := 0;
  LEcx := 0;
  LEdx := 0;
  LVendor := '';

  // 测试 CPUID 叶子 0
  CPUID(0, LEax, LEbx, LEcx, LEdx);
  
  // EAX 应该包含最大支持的叶子号
  AssertTrue('CPUID(0) EAX should be > 0', LEax > 0);
  
  // 构造厂商字符串
  SetLength(LVendor, 12);
  Move(LEbx, LVendor[1], 4);
  Move(LEdx, LVendor[5], 4);
  Move(LEcx, LVendor[9], 4);
  
  // 厂商字符串应该是已知的值之一
  AssertTrue('Vendor should be known', 
    (LVendor = 'GenuineIntel') or 
    (LVendor = 'AuthenticAMD') or 
    (LVendor = 'CentaurHauls'));
end;

procedure TTestCase_Global.Test_CPUIDEX;
var
  LMaxLeaf: DWord;
  LUnusedEbx: DWord;
  LUnusedEcx: DWord;
  LUnusedEdx: DWord;
  LEax1: DWord;
  LEbx1: DWord;
  LEcx1: DWord;
  LEdx1: DWord;
  LEax2: DWord;
  LEbx2: DWord;
  LEcx2: DWord;
  LEdx2: DWord;
begin
  LMaxLeaf := 0;
  LUnusedEbx := 0;
  LUnusedEcx := 0;
  LUnusedEdx := 0;
  LEax1 := 0;
  LEbx1 := 0;
  LEcx1 := 0;
  LEdx1 := 0;
  LEax2 := 0;
  LEbx2 := 0;
  LEcx2 := 0;
  LEdx2 := 0;

  CPUID(0, LMaxLeaf, LUnusedEbx, LUnusedEcx, LUnusedEdx);

  // 叶子 7 不是所有 x86 CPU 都支持：不支持时仅验证调用安全性。
  if LMaxLeaf < 7 then
  begin
    CPUIDEX(7, 0, LEax1, LEbx1, LEcx1, LEdx1);
    Exit;
  end;

  // 测试 CPUIDEX 叶子 7，子叶 0
  CPUIDEX(7, 0, LEax1, LEbx1, LEcx1, LEdx1);
  CPUIDEX(7, 0, LEax2, LEbx2, LEcx2, LEdx2);

  AssertEquals('CPUIDEX leaf 7 EAX should be deterministic', LEax1, LEax2);
  AssertEquals('CPUIDEX leaf 7 EBX should be deterministic', LEbx1, LEbx2);
  AssertEquals('CPUIDEX leaf 7 ECX should be deterministic', LEcx1, LEcx2);
  AssertEquals('CPUIDEX leaf 7 EDX should be deterministic', LEdx1, LEdx2);

  if HasAVX2 then
    AssertTrue('HasAVX2 implies CPUIDEX(7,0).EBX bit 5', (LEbx1 and (DWord(1) shl 5)) <> 0);
end;

procedure TTestCase_Global.Test_HasSSE;
begin
  // 在现代 x64 系统上，SSE 应该总是可用
  AssertTrue('SSE should be available on x64 systems', HasSSE);
end;

procedure TTestCase_Global.Test_HasSSE2;
begin
  // 在现代 x64 系统上，SSE2 应该总是可用
  AssertTrue('SSE2 should be available on x64 systems', HasSSE2);
end;

procedure TTestCase_Global.Test_HasAVX;
var
  LFeatures: TX86Features;
  LHasAVX: Boolean;
begin
  LHasAVX := HasAVX;
  LFeatures := DetectX86Features;

  // wrapper 与特性检测结果必须一致
  AssertEquals('HasAVX should match DetectX86Features.HasAVX', LFeatures.HasAVX, LHasAVX);

  // AVX 能力应满足基础不变量
  if LHasAVX then
  begin
    AssertTrue('AVX implies SSE2 support', HasSSE2);
    AssertTrue('AVX implies OS AVX support', IsAVXSupportedByOS);
  end;
end;

procedure TTestCase_Global.Test_HasAVX2;
var
  LFeatures: TX86Features;
  LHasAVX: Boolean;
  LHasAVX2: Boolean;
begin
  LHasAVX := HasAVX;
  LHasAVX2 := HasAVX2;
  LFeatures := DetectX86Features;

  // wrapper 与特性检测结果必须一致
  AssertEquals('HasAVX2 should match DetectX86Features.HasAVX2', LFeatures.HasAVX2, LHasAVX2);

  // AVX2 能力应满足基础不变量
  if LHasAVX2 then
  begin
    AssertTrue('AVX2 implies AVX support', LHasAVX);
    AssertTrue('AVX2 implies OS AVX support', IsAVXSupportedByOS);
  end;
end;

procedure TTestCase_Global.Test_XCR0HasAVX_BitMask;
begin
  AssertFalse('XCR0=0 should not enable AVX', XCR0HasAVX($0));
  AssertFalse('Missing YMM bit should not enable AVX', XCR0HasAVX($2));
  AssertFalse('Missing XMM bit should not enable AVX', XCR0HasAVX($4));
  AssertTrue('XMM+YMM bits should enable AVX', XCR0HasAVX($6));
  AssertTrue('Superset of required bits should enable AVX', XCR0HasAVX(High(UInt64)));
end;

procedure TTestCase_Global.Test_XCR0HasAVX512_BitMask;
begin
  AssertFalse('XCR0=0 should not enable AVX-512', XCR0HasAVX512($0));
  AssertFalse('Only AVX bits should not enable AVX-512', XCR0HasAVX512($6));
  AssertFalse('Missing OPMASK bit should not enable AVX-512', XCR0HasAVX512($C6));
  AssertFalse('Missing ZMM_Hi256 bit should not enable AVX-512', XCR0HasAVX512($A6));
  AssertFalse('Missing Hi16_ZMM bit should not enable AVX-512', XCR0HasAVX512($66));
  AssertTrue('Required XCR0 bits should enable AVX-512', XCR0HasAVX512($E6));
  AssertTrue('Superset of required bits should enable AVX-512', XCR0HasAVX512(High(UInt64)));
end;

procedure TTestCase_Global.Test_GetVendorString;
var
  LVendor: string;
begin
  LVendor := GetVendorString;
  
  // 厂商字符串应该不为空且是已知值
  AssertTrue('Vendor string should not be empty', LVendor <> '');
  AssertTrue('Vendor should be known', 
    (LVendor = 'GenuineIntel') or 
    (LVendor = 'AuthenticAMD') or 
    (LVendor = 'CentaurHauls'));
    
  WriteLn('Vendor: "', LVendor, '"');
end;

procedure TTestCase_Global.Test_GetBrandString;
var
  LBrand: string;
begin
  LBrand := GetBrandString;
  
  // 品牌字符串应该不为空
  AssertTrue('Brand string should not be empty', LBrand <> '');
  
  WriteLn('Brand: "', LBrand, '"');
end;

{ TTestCase_SampleDriven }

procedure TTestCase_SampleDriven.Test_X86VendorStringFromLeaf0_Samples;
var
  LLeaf0: TX86CPUIDRegs;
begin
  LLeaf0 := MakeX86CPUIDRegs(0, $756E6547, $6C65746E, $49656E69);
  AssertEquals('leaf0 vendor should decode GenuineIntel', 'GenuineIntel', X86VendorStringFromLeaf0(LLeaf0));

  LLeaf0 := MakeX86CPUIDRegs(0, $68747541, $444D4163, $69746E65);
  AssertEquals('leaf0 vendor should decode AuthenticAMD', 'AuthenticAMD', X86VendorStringFromLeaf0(LLeaf0));
end;

procedure TTestCase_SampleDriven.Test_X86BrandStringFromExtendedLeaves_FallbackToVendor;
var
  LLeaf2: TX86CPUIDRegs;
  LLeaf3: TX86CPUIDRegs;
  LLeaf4: TX86CPUIDRegs;
begin
  LLeaf2 := RegsFromAscii16('Unit Test CPU  ');
  LLeaf3 := RegsFromAscii16('Vector Path    ');
  LLeaf4 := RegsFromAscii16('Verifier       ');

  AssertEquals(
    'brand leaves should be stitched into one readable string',
    'Unit Test CPU  Vector Path    Verifier',
    Trim(X86BrandStringFromExtendedLeaves('GenuineIntel', $80000004, LLeaf2, LLeaf3, LLeaf4))
  );

  AssertEquals(
    'missing extended brand leaves should fall back to vendor',
    'GenuineIntel Processor',
    X86BrandStringFromExtendedLeaves('GenuineIntel', $80000003, LLeaf2, LLeaf3, LLeaf4)
  );
end;

procedure TTestCase_SampleDriven.Test_X86FeaturesFromCPUID_AVXRequiresOSXSAVEAndXCR0;
var
  LLeaf1: TX86CPUIDRegs;
  LLeaf7: TX86CPUIDRegs;
  LExt1: TX86CPUIDRegs;
  LFeatures: TX86Features;
begin
  LLeaf1 := MakeX86CPUIDRegs(0, 0, DWord(1 shl 28) or DWord(1 shl 12), DWord(1 shl 26));
  LLeaf7 := MakeX86CPUIDRegs(0, DWord(1 shl 5), 0, 0);
  LExt1 := MakeX86CPUIDRegs(0, 0, 0, 0);

  LFeatures := X86FeaturesFromCPUID(7, $80000000, LLeaf1, LLeaf7, LExt1, 0);
  AssertFalse('AVX should be masked off when OSXSAVE/XCR0 are not usable', LFeatures.HasAVX);
  AssertFalse('AVX2 should be masked off when AVX is unusable', LFeatures.HasAVX2);
  AssertFalse('FMA should be masked off when AVX is unusable', LFeatures.HasFMA);
end;

procedure TTestCase_SampleDriven.Test_X86FeaturesFromCPUID_AVX2RequiresUsableAVX;
var
  LLeaf1: TX86CPUIDRegs;
  LLeaf7: TX86CPUIDRegs;
  LExt1: TX86CPUIDRegs;
  LFeatures: TX86Features;
begin
  LLeaf1 := MakeX86CPUIDRegs(0, 0, DWord(1 shl 27) or DWord(1 shl 28), DWord(1 shl 26));
  LLeaf7 := MakeX86CPUIDRegs(0, DWord(1 shl 5), 0, 0);
  LExt1 := MakeX86CPUIDRegs(0, 0, 0, 0);

  LFeatures := X86FeaturesFromCPUID(7, $80000000, LLeaf1, LLeaf7, LExt1, $0000000000000002);
  AssertFalse('AVX should stay disabled when XCR0 lacks YMM', LFeatures.HasAVX);
  AssertFalse('AVX2 should stay disabled when AVX usability gate fails', LFeatures.HasAVX2);
end;

procedure TTestCase_SampleDriven.Test_X86FeaturesFromCPUID_AVX512RequiresFullXCR0Mask;
var
  LLeaf1: TX86CPUIDRegs;
  LLeaf7: TX86CPUIDRegs;
  LExt1: TX86CPUIDRegs;
  LFeatures: TX86Features;
begin
  LLeaf1 := MakeX86CPUIDRegs(0, 0, DWord(1 shl 27) or DWord(1 shl 28), DWord(1 shl 26));
  LLeaf7 := MakeX86CPUIDRegs(0, DWord(1 shl 5) or DWord(1 shl 16) or DWord(1 shl 17) or DWord(1 shl 30) or DWord(1 shl 31), DWord(1 shl 1), 0);
  LExt1 := MakeX86CPUIDRegs(0, 0, 0, 0);

  LFeatures := X86FeaturesFromCPUID(7, $80000000, LLeaf1, LLeaf7, LExt1, $0000000000000006);
  AssertTrue('AVX should remain enabled with XMM+YMM', LFeatures.HasAVX);
  AssertTrue('AVX2 should remain enabled when AVX is usable', LFeatures.HasAVX2);
  AssertFalse('AVX512F should be masked off without full AVX512 XCR0 state', LFeatures.HasAVX512F);
  AssertFalse('AVX512VBMI should be masked off without full AVX512 XCR0 state', LFeatures.HasAVX512VBMI);
end;

initialization
  RegisterTest(TTestCase_Global);
  RegisterTest(TTestCase_SampleDriven);

end.
