program debug_por;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.simd.intrinsics.mmx;

var
  a, b, result: TM64;

begin
  WriteLn('Debug mmx_por Test');
  WriteLn('==================');
  
  a.mm_u64 := UInt64(17361641481138401520);  // $F0F0F0F0F0F0F0F0
  b.mm_u64 := UInt64(12297829382473034410); // $AAAAAAAAAAAAAAAA
  result := mmx_por(a, b);
  
  WriteLn('a.mm_u64 = ', a.mm_u64, ' (hex: $', IntToHex(a.mm_u64, 16), ')');
  WriteLn('b.mm_u64 = ', b.mm_u64, ' (hex: $', IntToHex(b.mm_u64, 16), ')');
  WriteLn('result.mm_u64 = ', result.mm_u64, ' (hex: $', IntToHex(result.mm_u64, 16), ')');
  
  WriteLn('');
  WriteLn('Manual calculation:');
  WriteLn('$F0F0F0F0F0F0F0F0 OR $AAAAAAAAAAAAAAAA = $FAFAFAFAFAFAFAFAFA');
  WriteLn('Expected decimal: 18077129492005502970');
  WriteLn('Actual decimal:   ', result.mm_u64);
  
  WriteLn('');
  WriteLn('Debug completed.');
end.
