{$CODEPAGE UTF8}
unit Test_fafafa_core_toml_builder_getters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.toml;

type
  TTestCase_Toml_Builder_Getters = class(TTestCase)
  published
    procedure Test_Getters_Work_With_Defaults;
  end;

implementation

procedure TTestCase_Toml_Builder_Getters.Test_Getters_Work_With_Defaults;
var
  D: ITomlDocument;
  Err: TTomlError;
  S: RawByteString;
  Host: String;
  Port: Int64;
  Enabled: Boolean;
begin
  Err.Clear;
  S := RawByteString('db.host = "localhost"' + LineEnding + 'db.port = 5432');
  AssertTrue(Parse(S, D, Err));
  AssertFalse(Err.HasError);
  Host := GetString(D, 'db.host', '127.0.0.1');
  Port := GetInt(D, 'db.port', 3306);
  Enabled := GetBool(D, 'feature.enabled', False);
  AssertEquals('localhost', Host);
  AssertEquals(5432, Port);
  AssertEquals(False, Enabled);
end;

initialization
  RegisterTest(TTestCase_Toml_Builder_Getters);
end.

