unit Test_core_test_snapshot_toml;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.test.snapshot;

type
  TTestCase_CoreTest_SnapshotToml = class(TTestCase)
  published
    procedure Test_TomlSnapshot_TextOnly_Normalization;
  end;

procedure RegisterTests;

implementation

function EnvTrueLocal(const AName: string): boolean;
var v: string;
begin
  v := LowerCase(Trim(GetEnvironmentVariable(AName)));
  Result := (v='1') or (v='true') or (v='yes') or (v='on');
end;

function AllowEnvUpdate: boolean;
begin
  Result := EnvTrueLocal('TEST_SNAPSHOT_UPDATE') or EnvTrueLocal('FAFAFA_TEST_SNAPSHOT_UPDATE');
  if Result and EnvTrueLocal('CI') then
    Result := False;
end;

procedure TTestCase_CoreTest_SnapshotToml.Test_TomlSnapshot_TextOnly_Normalization;
var
  Dir, Name: string;
  A, B: string;
  ok: boolean;
  BasePath: string;
  DoUpdate: boolean;
begin
  Dir := GetTempDir(False) + 'snap_toml_case';
  ForceDirectories(Dir);
  Name := 'basic';
  // ensure clean baseline for isolation
  BasePath := IncludeTrailingPathDelimiter(Dir) + Name + '.snap.toml';
  if FileExists(BasePath) then DeleteFile(BasePath);
  // A ends with newline; B does not. NormalizeText should make them equivalent.
  A := 'a=1'#10; // with LF ending
  B := 'a=1';   // no final newline
  // if env allows update, skip the initial-false assertion
  DoUpdate := AllowEnvUpdate;
  if not DoUpdate then
  begin
    ok := CompareTomlSnapshot(Dir, Name, B, False);
    AssertFalse(ok);
  end;
  // update baseline using A
  ok := CompareTomlSnapshot(Dir, Name, A, True);
  AssertTrue(ok);
  // compare B against baseline -> True after normalization
  ok := CompareTomlSnapshot(Dir, Name, B, False);
  AssertTrue(ok);
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_SnapshotToml);
end;

end.

