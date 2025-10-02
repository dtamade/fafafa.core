program test_integration;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.cpuinfo.base;

procedure PrintCPUInfo;
var
  arch: TCPUArch;
begin
  WriteLn('=== CPU Information Test ===');
  WriteLn;
  
  // Test basic types
  arch := caX86;
  WriteLn('Architecture: ', Ord(arch));
  
  // Test feature sets
  var features: TGenericFeatureSet;
  features := [gfSimd128, gfSimd256];
  
  if gfSimd128 in features then
    WriteLn('SIMD-128 is in feature set');
    
  if gfSimd256 in features then
    WriteLn('SIMD-256 is in feature set');
    
  if not (gfSimd512 in features) then
    WriteLn('SIMD-512 is NOT in feature set');
    
  WriteLn;
end;

procedure TestCacheInfo;
var
  cache: TCacheInfo;
begin
  WriteLn('=== Cache Information Test ===');
  
  FillChar(cache, SizeOf(cache), 0);
  cache.L1DataKB := 32;
  cache.L1InstrKB := 32;
  cache.L2KB := 256;
  cache.L3KB := 8192;
  cache.LineSize := 64;
  
  WriteLn('L1 Data Cache: ', cache.L1DataKB, ' KB');
  WriteLn('L1 Instruction Cache: ', cache.L1InstrKB, ' KB');
  WriteLn('L2 Cache: ', cache.L2KB, ' KB');
  WriteLn('L3 Cache: ', cache.L3KB, ' KB');
  WriteLn('Cache Line Size: ', cache.LineSize, ' bytes');
  WriteLn;
end;

begin
  WriteLn('SIMD CPU Info Integration Test');
  WriteLn('==============================');
  WriteLn;
  
  PrintCPUInfo;
  TestCacheInfo;
  
  WriteLn('All tests completed successfully!');
end.