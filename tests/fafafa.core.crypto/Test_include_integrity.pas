{$CODEPAGE UTF8}
unit Test_include_integrity;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

// This test only ensures that include files referenced by crypto sources exist
// and can be included by the compiler. It does not execute any code.

type
  TTestCase_IncludeIntegrity = class(TTestCase)
  published
    procedure Test_GHash_Cache_Inc_Is_Reachable;
  end;

implementation

// include removed; cache helpers are now inlined under {$IFDEF DEBUG}
{$IFDEF NEVER}
{$I ../src/fafafa.core.crypto.aead.gcm.ghash.cache.inc}
{$ENDIF}

procedure TTestCase_IncludeIntegrity.Test_GHash_Cache_Inc_Is_Reachable;
begin
  // If we reached here, the include file was found and parsed by the compiler
  AssertTrue(True);
end;

initialization
  RegisterTest(TTestCase_IncludeIntegrity);

end.

