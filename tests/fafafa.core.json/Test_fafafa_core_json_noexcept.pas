unit Test_fafafa_core_json_noexcept;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.mem.allocator,
  fafafa.core.json,
  fafafa.core.json.noexcept;

procedure RegisterTests;

implementation

type
  TTestCase_NoExcept = class(TTestCase)
  published
    procedure Test_Read_FromString_Ok;
    procedure Test_Read_FromString_Error;
  end;

procedure TTestCase_NoExcept.Test_Read_FromString_Ok;
var R: TJsonReaderNoExcept; D: IJsonDocument; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(nil);
  Code := R.ReadFromString('{"a":1}', D);
  AssertEquals(0, Code);
  AssertTrue(D <> nil);
  AssertTrue(D.Root.IsObject);
end;

procedure TTestCase_NoExcept.Test_Read_FromString_Error;
var R: TJsonReaderNoExcept; D: IJsonDocument; Code: Integer;
begin
  R := TJsonReaderNoExcept.New(nil);
  Code := R.ReadFromString('{"a":,}', D);
  AssertTrue(Code <> 0);
  AssertTrue(D = nil);
end;

procedure RegisterTests;
begin
  RegisterTest('json-noexcept', TTestCase_NoExcept.Suite);
end;

end.

