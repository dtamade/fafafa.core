unit Test_core_env_filtering;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  {$IFDEF MSWINDOWS} Windows, {$ENDIF}
  {$IFDEF UNIX} BaseUnix, {$ENDIF}
  fafafa.core.args.config;

type
  TTestCase_Core_EnvFiltering = class(TTestCase)
  private
    function GetEnvOld(const Name: string; out Had: boolean): string;
    procedure SetEnvKV(const Name, Value: string);
    procedure RestoreEnv(const Name, OldValue: string; const Had: boolean);
  published
    procedure Test_Allow_Filter_Includes_Only_Allowed;
    procedure Test_Deny_Filter_Excludes_Denied;
    procedure Test_Flags_Trim_And_BoolLowercase;
    procedure Test_EmptyValue_Becomes_SwitchToken;
  end;

procedure RegisterTests;

implementation

function TTestCase_Core_EnvFiltering.GetEnvOld(const Name: string; out Had: boolean): string;
begin
  Result := SysUtils.GetEnvironmentVariable(Name);
  Had := Result <> '';
end;

procedure TTestCase_Core_EnvFiltering.SetEnvKV(const Name, Value: string);
begin
  {$IFDEF MSWINDOWS}
  Windows.SetEnvironmentVariable(PChar(Name), PChar(Value));
  {$ELSE}
  BaseUnix.FpSetEnv(PChar(Name+'='+Value));
  {$ENDIF}
end;

procedure TTestCase_Core_EnvFiltering.RestoreEnv(const Name, OldValue: string; const Had: boolean);
begin
  if Had then SetEnvKV(Name, OldValue)
  else SetEnvKV(Name, '');
end;

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_EnvFiltering);
end;

procedure TTestCase_Core_EnvFiltering.Test_Allow_Filter_Includes_Only_Allowed;
var oldF, oldB: string; hadF, hadB: boolean; arr: array of string; 
    tokens: array of string; i: Integer;
begin
  oldF := GetEnvOld('APP_FOO', hadF);
  oldB := GetEnvOld('APP_BAR', hadB);
  try
    SetEnvKV('APP_FOO','1');
    SetEnvKV('APP_BAR','2');

    tokens := ArgvFromEnvEx('APP_', ['foo'], [], []);
    // expect only --foo=1
    AssertEquals(1, Length(tokens));
    AssertEquals('--foo=1', tokens[0]);
  finally
    RestoreEnv('APP_FOO', oldF, hadF);
    RestoreEnv('APP_BAR', oldB, hadB);
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_Deny_Filter_Excludes_Denied;
var oldF, oldB: string; hadF, hadB: boolean; tokens: array of string;
begin
  oldF := GetEnvOld('APP_FOO', hadF);
  oldB := GetEnvOld('APP_BAR', hadB);
  try
    SetEnvKV('APP_FOO','1');
    SetEnvKV('APP_BAR','2');

    tokens := ArgvFromEnvEx('APP_', [], ['bar'], []);
    // expect only --foo=1
    AssertEquals(1, Length(tokens));
    AssertEquals('--foo=1', tokens[0]);
  finally
    RestoreEnv('APP_FOO', oldF, hadF);
    RestoreEnv('APP_BAR', oldB, hadB);
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_Flags_Trim_And_BoolLowercase;
var oldD, oldN: string; hadD, hadN: boolean; tokens: array of string;
    seenDebug, seenName: boolean; i: Integer;
begin
  oldD := GetEnvOld('APP_DEBUG', hadD);
  oldN := GetEnvOld('APP_NAME', hadN);
  try
    SetEnvKV('APP_DEBUG','  TRUE  ');
    SetEnvKV('APP_NAME','  x  ');

    tokens := ArgvFromEnvEx('APP_', [], [], [efTrimValues, efLowercaseBools]);
    seenDebug := False; seenName := False;
    for i := 0 to High(tokens) do begin
      if tokens[i] = '--debug=true' then seenDebug := True;
      if tokens[i] = '--name=x' then seenName := True;
    end;
    AssertTrue(seenDebug);
    AssertTrue(seenName);
  finally
    RestoreEnv('APP_DEBUG', oldD, hadD);
    RestoreEnv('APP_NAME', oldN, hadN);
  end;
end;

procedure TTestCase_Core_EnvFiltering.Test_EmptyValue_Becomes_SwitchToken;
var oldE: string; hadE: boolean; tokens: array of string; i: Integer; seen: boolean;
begin
  oldE := GetEnvOld('APP_EMPTY', hadE);
  try
    SetEnvKV('APP_EMPTY','');
    tokens := ArgvFromEnvEx('APP_', [], [], [efTrimValues]);
    seen := False;
    for i := 0 to High(tokens) do if tokens[i] = '--empty' then begin seen := True; Break; end;
    AssertTrue(seen);
  finally
    RestoreEnv('APP_EMPTY', oldE, hadE);
  end;
end;

end.

