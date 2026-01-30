{$CODEPAGE UTF8}
unit Test_env_override;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env;

type
  TEnvOverrideTests = class(TTestCase)
  published
    procedure Test_Basic;
    procedure Test_Unset_Restore_Missing;
    procedure Test_Nested;
    procedure Test_Done_Idempotent;
  end;

implementation

procedure TEnvOverrideTests.Test_Basic;
var
  g: TEnvOverrideGuard;
  key: string;
  before, during, after: string;
begin
  key := 'FAFAFA_TEST_ENV_OVERRIDE';
  before := env_get(key);
  g := env_override(key, 'xyz');
  try
    during := env_get(key);
    AssertEquals('xyz', during);
  finally
    g.Done;
  end;
  after := env_get(key);
  AssertEquals(before, after);
end;

procedure TEnvOverrideTests.Test_Unset_Restore_Missing;
var
  g: TEnvOverrideGuard;
  key: string;
  after: string;
begin
  key := 'FAFAFA_TEST_ENV_OVERRIDE_UNSET';
  env_unset(key);
  g := env_override(key, '');
  try
    AssertEquals('', env_get(key));
  finally
    g.Done;
  end;
  after := env_get(key);
  AssertEquals('', after);
end;

procedure TEnvOverrideTests.Test_Nested;
var
  key, orig: string;
  g1, g2: TEnvOverrideGuard;
begin
  key := 'FAFAFA_TEST_ENV_OVERRIDE_NESTED';
  orig := env_get(key);
  g1 := env_override(key, 'outer');
  try
    AssertEquals('outer', env_get(key));
    g2 := env_override(key, 'inner');
    try
      AssertEquals('inner', env_get(key));
    finally
      g2.Done; // back to 'outer'
    end;
    AssertEquals('outer', env_get(key));
  finally
    g1.Done; // back to orig (or unset)
  end;
  AssertEquals(orig, env_get(key));
end;

procedure TEnvOverrideTests.Test_Done_Idempotent;
var
  key, orig: string;
  g: TEnvOverrideGuard;
begin
  key := 'FAFAFA_TEST_ENV_OVERRIDE_IDEMP';
  orig := env_get(key);
  g := env_override(key, 'v1');
  try
    AssertEquals('v1', env_get(key));
  finally
    g.Done;
    g.Done; // should be safe/no-op
  end;
  AssertEquals(orig, env_get(key));
end;

initialization
  RegisterTest(TEnvOverrideTests);

end.

