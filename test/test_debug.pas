program test_debug;

{$mode objfpc}{$H+}
{$ifdef windows}{$codepage utf8}{$endif}

uses
  SysUtils,
  fafafa.core.simd.cpuinfo.base,
  fafafa.core.simd.types;

var
  features: TGenericFeatureSet;
begin
  WriteLn('Starting test...');
  
  try
    features := [];
    WriteLn('Created empty feature set');
    
    Include(features, gfSimd128);
    WriteLn('Added gfSimd128');
    
    Include(features, gfSimd256);
    WriteLn('Added gfSimd256');
    
    if gfSimd128 in features then
      WriteLn('✓ SIMD-128 detected');
      
    if gfSimd256 in features then
      WriteLn('✓ SIMD-256 detected');
      
    if not (gfSimd512 in features) then
      WriteLn('✓ SIMD-512 not in set (expected)');
      
    WriteLn('Test completed successfully!');
  except
    on E: Exception do
    begin
      WriteLn('ERROR: ', E.ClassName, ': ', E.Message);
    end;
  end;
  
  WriteLn('Press Enter to exit...');
  ReadLn;
end.