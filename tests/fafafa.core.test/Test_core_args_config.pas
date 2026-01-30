unit Test_core_args_config;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

{$IFDEF FAFAFA_ARGS_CONFIG_TOML} // TOML feature must be enabled to run these tests

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.config, fafafa.core.args.command, fafafa.core.test.utils, args_test_helper;

procedure RegisterTests;

{$ENDIF}

implementation

{$IFDEF FAFAFA_ARGS_CONFIG_TOML} // TOML feature must be enabled to run these tests

function HandleRun(const A2: IArgs): Integer; begin Result := 0; end;


function WriteTempFile(const Content: string): string;
var FN: string; FS: TFileStream; dir: string;
begin
  dir := IncludeTrailingPathDelimiter(GetTempDir(False));
  FN := dir + 'cfg_' + IntToStr(GetTickCount64) + '.toml';
  FS := TFileStream.Create(FN, fmCreate);
  try
    if Length(Content) > 0 then FS.WriteBuffer(Content[1], Length(Content));
  finally
    FS.Free;
  end;
  Result := FN;
end;



type
  TTestCase_Core_Args_Config = class(TTestCase)
  published
    procedure Test_Toml_Scalars_To_Argv; reintroduce;
    procedure Test_Toml_Array_To_Repeated_Argv; reintroduce;
    procedure Test_Precendence_Config_Env_Cli; reintroduce;
    procedure Test_Toml_ArraysOfTables_Ignored; reintroduce;
    procedure Test_Toml_ArrayOfArrays_Ignored; reintroduce;
    procedure Test_Toml_Key_Normalization; reintroduce;
  end;

procedure TTestCase_Core_Args_Config.Test_Toml_Scalars_To_Argv;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; s: string; n: Int64; b: boolean;
begin
  FN := WriteTempFile('[app]' + LineEnding + 'name = "core"' + LineEnding + 'count = 3' + LineEnding + 'debug = true');
  try
    argv := ArgsArgvFromToml(FN);
    AssertTrue(Length(argv) >= 3);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    AssertTrue(A.TryGetValue('app.name', s)); AssertEquals('core', s);
    AssertTrue(A.TryGetInt64('app.count', n)); AssertEquals(Int64(3), n);
    AssertTrue(A.TryGetBool('app.debug', b)); AssertTrue(b);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config.Test_Toml_Array_To_Repeated_Argv;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; all: TStringArray;
begin
  FN := WriteTempFile('tags = ["a","b","c"]');
  try
    argv := ArgsArgvFromToml(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    all := A.GetAll('tags');
    AssertEquals(3, Length(all));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config.Test_Precendence_Config_Env_Cli;
var FN: string; cfgArgv, envArgv, cliArgv, merged: TStringArray; Root: IRootCommand; code: Integer; opts: TArgsOptions; A: IArgs; v: string; db: boolean;
begin
  FN := WriteTempFile('count = 1' + LineEnding + 'debug = true');
  try
    cfgArgv := ArgsArgvFromToml(FN);
    envArgv := Arr(['--count=2']);
    cliArgv := Arr(['run','--count=5']);
    merged := Join(Join(cfgArgv, envArgv), cliArgv);

    Root := NewRootCommand;
    Root.Register(NewCommandPath(['run'], @HandleRun, 'run'));

    opts := MakeDefaultOpts;
    code := Root.Run(merged, opts);
    AssertEquals(0, code);

    A := TArgs.FromArray(merged, opts);
    AssertTrue(A.TryGetValue('count', v));
    AssertEquals('5', v);
    AssertTrue(A.TryGetBool('debug', db));
    AssertTrue(db);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config.Test_Toml_ArraysOfTables_Ignored;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFile('[[items]]' + LineEnding + 'name = "a"' + LineEnding + '[[items]]' + LineEnding + 'name = "b"');
  try
    argv := ArgsArgvFromToml(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config.Test_Toml_ArrayOfArrays_Ignored;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFile('k = [[1,2],[3]]');
  try
    argv := ArgsArgvFromToml(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config.Test_Toml_Key_Normalization;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; s: string;
begin
  FN := WriteTempFile('[API]' + LineEnding + 'ACCESS_KEY_ID = "x"');
  try
    argv := ArgsArgvFromToml(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    AssertTrue(A.TryGetValue('api.access-key-id', s));
    AssertEquals('x', s);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;


procedure RegisterTests;
begin
  RegisterTest(TTestCase_Core_Args_Config);
end;


{$ENDIF} // FAFAFA_ARGS_CONFIG_TOML

end.

