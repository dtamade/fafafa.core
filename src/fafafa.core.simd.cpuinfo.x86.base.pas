unit fafafa.core.simd.cpuinfo.x86.base;

{$mode objfpc}
{$I fafafa.core.settings.inc}

interface

{ x86 共用辅助�?
  - 预留放置 CPUID 位常量、特性归一化与 OS 门槛判定的纯 Pascal 逻辑
  - 架构相关�?CPUID/XGETBV �?x86.i386/.x86.x86_64 提供
}

// 预留：根�?XCR0 判断 AVX/AVX-512 OS 支持
function XCR0HasAVX(xcr0: UInt64): Boolean; inline;
function XCR0HasAVX512(xcr0: UInt64): Boolean; inline;

implementation

function XCR0HasAVX(xcr0: UInt64): Boolean; inline;
begin
  Result := (xcr0 and $06) = $06;
end;

function XCR0HasAVX512(xcr0: UInt64): Boolean; inline;
begin
  Result := (xcr0 and $00000000000000E6) = $00000000000000E6;
end;

end.
