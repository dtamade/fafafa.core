unit Test_fafafa_core_ini_duplicate_keys;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.ini;

type
  TTestCase_DuplicateKeys = class(TTestCase)
  published
    procedure Test_DuplicateKey_Default_AllowsOverride;
    procedure Test_DuplicateKey_WithFlag_Error;
  end;

implementation

procedure TTestCase_DuplicateKeys.Test_DuplicateKey_Default_AllowsOverride;
var Doc: IIniDocument; Err: TIniError; S: String;
begin
  AssertTrue(Parse(RawByteString('[s]' + LineEnding + 'a=1' + LineEnding + 'a=2' + LineEnding), Doc, Err));
  AssertTrue(Doc.TryGetString('s','a', S));
  AssertEquals('2', S);
end;

procedure TTestCase_DuplicateKeys.Test_DuplicateKey_WithFlag_Error;
var Doc: IIniDocument; Err: TIniError;
begin
  Err.Clear;
  AssertFalse(Parse(RawByteString('[s]' + LineEnding + 'a=1' + LineEnding + 'a=2' + LineEnding), Doc, Err, [irfDuplicateKeyError]));
  AssertTrue(Err.HasError);
  AssertEquals(Ord(iecDuplicateKey), Ord(Err.Code));
end;

initialization
  RegisterTest(TTestCase_DuplicateKeys);
end.

