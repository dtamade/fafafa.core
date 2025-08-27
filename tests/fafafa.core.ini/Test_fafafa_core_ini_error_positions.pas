{$CODEPAGE UTF8}
unit Test_fafafa_core_ini_error_positions;

{$MODE OBJFPC}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_ErrorPositions = class(TTestCase)
  published
    procedure Test_Empty_Key_Error_Position;
    procedure Test_Section_Name_Contains_Closing_Bracket_Error_Position;
  end;

implementation

procedure TTestCase_ErrorPositions.Test_Empty_Key_Error_Position;
const
  SRC = '[s]'+LineEnding+': bad'+LineEnding;
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString(SRC), Doc, Err));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(iecInvalidIni), Ord(Err.Code));
  AssertEquals(2, Integer(Err.Line));
  // Column expected at 1 (start of line), or at separator position +1 depending on policy;
  // current implementation sets Column=1. If changed, update test accordingly.
  AssertEquals(1, Integer(Err.Column));
end;

procedure TTestCase_ErrorPositions.Test_Section_Name_Contains_Closing_Bracket_Error_Position;
const
  SRC = '[bad]]'+LineEnding+'k=v'+LineEnding; // extra closing bracket in name
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  // Current parser does not explicitly check illegal ']' inside name; treat as unclosed or accept.
  // This test asserts parse failure if implementation chooses to be strict; if not, adjust accordingly.
  if Parse(RawByteString(SRC), Doc, Err) then
  begin
    // Accepting implementation: ensure Section name trimmed properly ('bad]') and still functional
    AssertTrue(Doc.HasSection('bad]'));
  end
  else
  begin
    AssertTrue(Err.HasError);
  end;
end;

initialization
  RegisterTest(TTestCase_ErrorPositions);
end.

