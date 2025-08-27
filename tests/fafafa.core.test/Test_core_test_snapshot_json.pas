unit Test_core_test_snapshot_json;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fpjson, jsonparser,
  fafafa.core.test.snapshot;

type
  TTestCase_CoreTest_SnapshotJson = class(TTestCase)
  published
    procedure Test_JsonSnapshot_Canonical_And_Update_By_Param;
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

function BuildJsonText(const Pairs: array of string): string;
var
  I: Integer;
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    I := 0;
    while I < Length(Pairs) do
    begin
      Obj.Add(Pairs[I], Pairs[I+1]);
      Inc(I,2);
    end;
    Result := Obj.FormatJSON([]);
  finally
    Obj.Free;
  end;
end;

procedure TTestCase_CoreTest_SnapshotJson.Test_JsonSnapshot_Canonical_And_Update_By_Param;
var
  Dir: string;
  Name: string;
  A, B: string;
  ok: boolean;
  BasePath: string;
  DoUpdate: boolean;
begin
  Dir := GetTempDir(False) + 'snap_json_case';
  ForceDirectories(Dir);
  Name := 'canon';
  // ensure clean baseline for isolation
  BasePath := IncludeTrailingPathDelimiter(Dir) + Name + '.snap.json';
  if FileExists(BasePath) then DeleteFile(BasePath);
  // Create two JSON texts with different key order
  A := '{"b":2, "a":1}';
  B := '{"a":1, "b":2}';
  // if env allows update, skip the initial-false assertion and update baseline directly
  DoUpdate := AllowEnvUpdate;
  if not DoUpdate then
  begin
    ok := CompareJsonSnapshot(Dir, Name, A, False);
    AssertFalse('no baseline -> false', ok);
  end;
  // Update baseline with A (env or explicit)
  ok := CompareJsonSnapshot(Dir, Name, A, True);
  AssertTrue('update baseline -> true', ok);
  // Compare B against baseline -> should be true due to canonicalization
  ok := CompareJsonSnapshot(Dir, Name, B, False);
  AssertTrue('canonical equal -> true', ok);
end;



procedure RegisterTests;
begin
  RegisterTest(TTestCase_CoreTest_SnapshotJson);
end;

end.

