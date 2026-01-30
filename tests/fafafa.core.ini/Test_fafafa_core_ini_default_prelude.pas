{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_default_prelude;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_DefaultPrelude = class(TTestCase)
  published
    procedure Test_DefaultOnly_Prelude_Attributed_To_File;
  end;

implementation

procedure TTestCase_DefaultPrelude.Test_DefaultOnly_Prelude_Attributed_To_File;
const
  SRC = '; prelude comment'+LineEnding+
        ''+LineEnding+
        'k=v'+LineEnding; // default-only, no [section]
var Doc: IIniDocument; Err: TIniError; Out1: RawByteString;
begin
  Err.Clear;
  AssertTrue(Parse(RawByteString(SRC), Doc, Err));
  // Roundtrip should keep prelude intact and default section keys separate
  Out1 := ToIni(Doc, []);
  AssertTrue(Pos('; prelude comment', String(Out1)) > 0);
  AssertTrue(Pos('k=v', String(Out1)) > 0);
end;

initialization
  RegisterTest(TTestCase_DefaultPrelude);
end.

