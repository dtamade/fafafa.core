{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_v2_router;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_V2Router = class(TTestCase)
  published
    procedure Test_Parse_V2_Inline_Table_Nested_Array_Smoke;
  end;

implementation

procedure TTestCase_V2Router.Test_Parse_V2_Inline_Table_Nested_Array_Smoke;
var
  Doc: ITomlDocument; Err: TTomlError;
begin
  Err.Clear;
  // 该用法在 v1 里不完整，v2 应完全支持
  AssertTrue(Parse(RawByteString('a = [{x = 1}, {x = 2}]'), Doc, Err, [trfUseV2]));
  AssertFalse(Err.HasError);
  AssertTrue(Doc.Root.Contains('a'));
end;

initialization
  RegisterTest(TTestCase_V2Router);
end.

