{$CODEPAGE UTF8}
program example_overrides_showcase;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.env;

procedure Println(const S: string);
begin
  WriteLn(S);
end;

procedure DumpVar(const Name: string);
var v: string; ok: boolean;
begin
  ok := env_lookup(Name, v);
  if ok then
    Println(Format('%s = "%s" (defined)', [Name, v]))
  else
    Println(Format('%s = <undefined>', [Name]));
end;

var
  g: TEnvOverrideGuard;
  batch: TEnvOverridesGuard;
  kvs: array of TEnvKV;
  hadX, hadY: boolean;
  oldX, oldY: string;
begin
  WriteLn('=== overrides showcase ===');

  // Snapshot originals
  oldX := env_get('FA_ENV_X'); hadX := oldX <> '';
  oldY := env_get('FA_ENV_Y'); hadY := oldY <> '';

  Println('-- before --');
  DumpVar('FA_ENV_X');
  DumpVar('FA_ENV_Y');

  // Single override guard
  g := env_override('FA_ENV_X', 'VX');
  try
    Println('-- during single override --');
    DumpVar('FA_ENV_X');
  finally
    g.Done;
  end;

  // Batch overrides: set X, unset Y
  SetLength(kvs, 2);
  kvs[0].Name := 'FA_ENV_X'; kvs[0].Value := 'BX'; kvs[0].HasValue := True;
  kvs[1].Name := 'FA_ENV_Y'; kvs[1].HasValue := False; // explicit unset
  batch := env_overrides(kvs);
  try
    Println('-- during batch overrides --');
    DumpVar('FA_ENV_X');
    DumpVar('FA_ENV_Y');
  finally
    batch.Done;
  end;

  Println('-- after --');
  DumpVar('FA_ENV_X');
  DumpVar('FA_ENV_Y');

  // Explicit unset guard demonstration
  g := env_override_unset('FA_ENV_Y');
  try
    Println('-- during explicit unset guard --');
    DumpVar('FA_ENV_Y');
  finally
    g.Done;
  end;

  // Restore originals if they existed (safety, though guards already restored)
  if hadX then env_set('FA_ENV_X', oldX) else env_unset('FA_ENV_X');
  if hadY then env_set('FA_ENV_Y', oldY) else env_unset('FA_ENV_Y');
end.

