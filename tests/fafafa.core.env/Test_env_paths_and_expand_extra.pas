{$CODEPAGE UTF8}
unit Test_env_paths_and_expand_extra;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env;

type
  TEnvPathsAndExpandExtra = class(TTestCase)
  published
    procedure Test_Split_Ignores_Empty_Segments;
    procedure Test_Expand_Mixed_Text;
    procedure Test_Expand_Invalid_Start_Char;
    procedure Test_Expand_Unmatched_Brace_BestEffort;
    procedure Test_Expand_Nested_Brace_Not_Supported;
    {$IFDEF WINDOWS}
    procedure Test_Windows_Percent_Unmatched_Preserved;
    {$ENDIF}
  end;

implementation

procedure TEnvPathsAndExpandExtra.Test_Split_Ignores_Empty_Segments;
var p: string; arr: TStringArray;
begin
  p := 'a' + env_path_list_separator + env_path_list_separator + 'b';
  arr := env_split_paths(p);
  AssertEquals(2, Length(arr));
  AssertEquals('a', arr[0]);
  AssertEquals('b', arr[1]);
end;

procedure TEnvPathsAndExpandExtra.Test_Expand_Mixed_Text;
var old: string; had: boolean; s: string;
begin
  old := env_get('FA_ENV_MIX'); had := old <> '';
  env_set('FA_ENV_MIX', 'ZZ');
  try
    s := env_expand('pre-${FA_ENV_MIX}-mid-$FA_ENV_MIX-post');
    AssertTrue(Pos('pre-ZZ-mid-ZZ-post', s) > 0);
    {$IFDEF WINDOWS}
    s := env_expand('pre-%FA_ENV_MIX%-post');
    AssertEquals('pre-ZZ-post', s);
    {$ENDIF}
  finally
    if had then env_set('FA_ENV_MIX', old) else env_unset('FA_ENV_MIX');
  end;
end;

procedure TEnvPathsAndExpandExtra.Test_Expand_Invalid_Start_Char;
var s: string;
begin
  s := env_expand('pre$1Xpost');
  AssertEquals('pre$1Xpost', s);
end;

procedure TEnvPathsAndExpandExtra.Test_Expand_Unmatched_Brace_BestEffort;
var old: string; had: boolean; s: string;
begin
  old := env_get('UNMATCHED'); had := old <> '';
  env_set('UNMATCHED', 'VV');
  try
    s := env_expand('${UNMATCHED');
    AssertEquals('VV', s);
  finally
    if had then env_set('UNMATCHED', old) else env_unset('UNMATCHED');
  end;
end;

procedure TEnvPathsAndExpandExtra.Test_Expand_Nested_Brace_Not_Supported;
var s: string;
begin
  // ${A${B}} -> expands name "A${B" (likely undefined) then leaves trailing '}' literal
  s := env_expand('${A${B}}');
  AssertTrue(Copy(s, Length(s), 1) = '}');
end;

{$IFDEF WINDOWS}
procedure TEnvPathsAndExpandExtra.Test_Windows_Percent_Unmatched_Preserved;
var s: string;
begin
  s := env_expand('%FOO');
  AssertEquals('%FOO', s);
end;
{$ENDIF}

initialization
  RegisterTest(TEnvPathsAndExpandExtra);

end.

