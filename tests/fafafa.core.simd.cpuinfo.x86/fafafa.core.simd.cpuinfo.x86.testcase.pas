unit fafafa.core.simd.cpuinfo.x86.testcase;

{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
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
    procedure Test_GetVendorString;
    procedure Test_GetBrandString;
  end;

implementation

{ TTestCase_Global }

procedure TTestCase_Global.Test_HasCPUID;
begin
  // CPUID 在现代 x64 系统上应该总是可用
  AssertTrue('HasCPUID should return True on x64 systems', HasCPUID);
end;

procedure TTestCase_Global.Test_CPUID;
var
  eax, ebx, ecx, edx: DWord;
  vendor: string;
begin
  // 测试 CPUID 叶子 0
  CPUID(0, eax, ebx, ecx, edx);
  
  // EAX 应该包含最大支持的叶子号
  AssertTrue('CPUID(0) EAX should be > 0', eax > 0);
  
  // 构造厂商字符串
  SetLength(vendor, 12);
  Move(ebx, vendor[1], 4);
  Move(edx, vendor[5], 4);
  Move(ecx, vendor[9], 4);
  
  // 厂商字符串应该是已知的值之一
  AssertTrue('Vendor should be known', 
    (vendor = 'GenuineIntel') or 
    (vendor = 'AuthenticAMD') or 
    (vendor = 'CentaurHauls'));
end;

procedure TTestCase_Global.Test_CPUIDEX;
var
  eax, ebx, ecx, edx: DWord;
begin
  // 测试 CPUIDEX 叶子 7，子叶 0
  CPUIDEX(7, 0, eax, ebx, ecx, edx);
  
  // 这个调用应该成功完成（不崩溃）
  // 具体值取决于 CPU，但调用应该是安全的
  AssertTrue('CPUIDEX should complete without error', True);
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
  hasAVX: Boolean;
begin
  hasAVX := HasAVX;
  // AVX 可能可用也可能不可用，但调用应该成功
  AssertTrue('HasAVX should complete without error', True);
  WriteLn('AVX available: ', hasAVX);
end;

procedure TTestCase_Global.Test_HasAVX2;
var
  hasAVX2: Boolean;
begin
  hasAVX2 := HasAVX2;
  // AVX2 可能可用也可能不可用，但调用应该成功
  AssertTrue('HasAVX2 should complete without error', True);
  WriteLn('AVX2 available: ', hasAVX2);
end;

procedure TTestCase_Global.Test_GetVendorString;
var
  vendor: string;
begin
  vendor := GetVendorString;
  
  // 厂商字符串应该不为空且是已知值
  AssertTrue('Vendor string should not be empty', vendor <> '');
  AssertTrue('Vendor should be known', 
    (vendor = 'GenuineIntel') or 
    (vendor = 'AuthenticAMD') or 
    (vendor = 'CentaurHauls'));
    
  WriteLn('Vendor: "', vendor, '"');
end;

procedure TTestCase_Global.Test_GetBrandString;
var
  brand: string;
begin
  brand := GetBrandString;
  
  // 品牌字符串应该不为空
  AssertTrue('Brand string should not be empty', brand <> '');
  
  WriteLn('Brand: "', brand, '"');
end;

initialization
  RegisterTest(TTestCase_Global);

end.
