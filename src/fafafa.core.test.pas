unit fafafa.core.test;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.test.runner,
  fafafa.core.test.utils,
  fafafa.core.test.snapshot;

// Facade unit: re-export common surface for convenience

type
  // Short aliases for external users
  TTestRunnerHelper = class helper for TObject end; // reserved for future helpers

// Runner
procedure TestMain; inline;

// Utils (re-expose)
function CreateTempDir(const APrefix: string = 'fafafa_test_'): string;

// Snapshot (minimal)
function CompareTextSnapshot(const ASnapDir, AName, AActual: string; AUpdate: boolean = False): boolean;

implementation

procedure TestMain; inline;
begin
  fafafa.core.test.runner.TestMain;
end;

function CreateTempDir(const APrefix: string): string;
begin
  Result := fafafa.core.test.utils.CreateTempDir(APrefix);
end;

function CompareTextSnapshot(const ASnapDir, AName, AActual: string; AUpdate: boolean): boolean;
begin
  Result := fafafa.core.test.snapshot.CompareTextSnapshot(ASnapDir, AName, AActual, AUpdate);
end;

end.

