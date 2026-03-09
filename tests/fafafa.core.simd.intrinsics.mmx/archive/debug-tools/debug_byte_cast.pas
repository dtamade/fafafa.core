program debug_byte_cast;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils;

begin
  WriteLn('Debug Byte Cast');
  WriteLn('===============');
  
  WriteLn('Byte(-128) = ', Byte(-128));
  WriteLn('Byte(-50) = ', Byte(-50));
  WriteLn('Byte(-10) = ', Byte(-10));
  
  WriteLn('ShortInt(-128) = ', ShortInt(-128));
  WriteLn('ShortInt(-50) = ', ShortInt(-50));
  WriteLn('ShortInt(-10) = ', ShortInt(-10));
  
  WriteLn('UInt8(-128) = ', UInt8(-128));
  WriteLn('UInt8(-50) = ', UInt8(-50));
  WriteLn('UInt8(-10) = ', UInt8(-10));
  
  WriteLn('');
  WriteLn('Debug completed.');
end.
