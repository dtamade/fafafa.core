{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_builder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Builder = class(TTestCase)
  published
    procedure Test_Builder_BasicChain_And_Save;
  end;

implementation

procedure TTestCase_Toml_Builder.Test_Builder_BasicChain_And_Save;
var
  B: ITomlBuilder;
  D: ITomlDocument;
  S: String;
begin
  B := NewDoc;
  D := B.PutAtStr('app.name','demo')
        .BeginTable('db').PutStr('host','localhost').PutInt('port',5432).EndTable
        .Build;
  S := String(ToToml(D, [twfSortKeys, twfSpacesAroundEquals]));
  AssertTrue(Pos('[app]', S) > 0);
  AssertTrue(Pos('[db]', S) > 0);
  AssertTrue(Pos('host = "localhost"', S) > 0);
  AssertTrue(Pos('port = 5432', S) > 0);
end;

initialization
  RegisterTest(TTestCase_Toml_Builder);
end.

