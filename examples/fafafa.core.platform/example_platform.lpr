{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}
program example_platform;

{$mode objfpc}{$H+}

uses
  fafafa.core.platform;

var
  LTarget: TPlatformTarget;
begin
  LTarget := PlatformTarget;

  WriteLn('fafafa.core.platform');
  WriteLn('====================');
  WriteLn('os          : ', PlatformOSName(LTarget.OS));
  WriteLn('arch        : ', PlatformArchName(LTarget.Arch));
  WriteLn('pointerBits : ', LTarget.PointerBits);
  WriteLn('is64Bit     : ', PlatformIs64Bit);
  WriteLn('endianness  : ', Ord(LTarget.Endianness));
end.
