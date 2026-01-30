unit Test_core_args_config_json;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

{$IFDEF FAFAFA_ARGS_CONFIG_JSON} // enable these tests only when JSON feature is on
procedure RegisterTests;
{$ENDIF}

implementation

{$IFDEF FAFAFA_ARGS_CONFIG_JSON}
uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.config, fafafa.core.test.utils, args_test_helper;

function WriteTempFileJSON(const Content: string): string;
var FN: string; FS: TFileStream; dir: string;

begin
  dir := IncludeTrailingPathDelimiter(GetTempDir(False));
  FN := dir + 'cfg_json_' + IntToStr(GetTickCount64) + '.json';
  FS := TFileStream.Create(FN, fmCreate);
  try
    if Length(Content) > 0 then FS.WriteBuffer(Content[1], Length(Content));
  finally
    FS.Free;
  end;
  Result := FN;
end;









type
  TTestCase_Core_Args_Config_Json = class(TTestCase)
  published
    procedure Test_JSON_Scalars_To_Argv;
    procedure Test_JSON_Array_To_Repeated_Argv;
    procedure Test_JSON_Precendence_Config_Env_Cli;
    procedure Test_JSON_ArrayOfObjects_Ignored;
    procedure Test_JSON_Null_Ignored;
    procedure Test_JSON_EmptyObject_Produces_Empty;
    procedure Test_JSON_EmptyArray_Produces_Empty;
    procedure Test_JSON_DeepObject_Flattens;
    procedure Test_JSON_MixedArray_OnlyScalars_Kept;
    procedure Test_JSON_Invalid_ReturnsEmpty;
    procedure Test_JSON_RootArray_ReturnsEmpty;
    procedure Test_JSON_Key_Normalization;
    procedure Test_JSON_Key_Normalization_Boundaries;
  end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Scalars_To_Argv;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; s: string; n: Int64; b: boolean;
begin
  FN := WriteTempFileJSON('{"app":{"name":"core","count":3,"debug":true}}');
  try
    argv := ArgsArgvFromJson(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    AssertTrue(A.TryGetValue('app.name', s)); AssertEquals('core', s);
    AssertTrue(A.TryGetInt64('app.count', n)); AssertEquals(Int64(3), n);
    AssertTrue(A.TryGetBool('app.debug', b)); AssertTrue(b);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Array_To_Repeated_Argv;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; all: TStringArray;
begin
  FN := WriteTempFileJSON('{"tags":["a","b","c"]}');
  try
    argv := ArgsArgvFromJson(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    all := A.GetAll('tags');
    AssertEquals(3, Length(all));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Precendence_Config_Env_Cli;
var FN: string; cfgArgv, envArgv, cliArgv, merged: TStringArray; opts: TArgsOptions; A: IArgs; v: string; db: boolean;
begin
  FN := WriteTempFileJSON('{"count":1,"debug":true}');
  try
    cfgArgv := ArgsArgvFromJson(FN);
    envArgv := Arr(['--count=2']);
    cliArgv := Arr(['run','--count=5']);
    merged := Join(Join(cfgArgv, envArgv), cliArgv);

    opts := MakeDefaultOpts;
    A := TArgs.FromArray(merged, opts);
    AssertTrue(A.TryGetValue('count', v));
    AssertEquals('5', v);
    AssertTrue(A.TryGetBool('debug', db));
    AssertTrue(db);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_ArrayOfObjects_Ignored;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('{"items":[{"a":1},{"a":2}]}');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Null_Ignored;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('{"a":null}');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_EmptyObject_Produces_Empty;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('{}');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_EmptyArray_Produces_Empty;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('{"tags":[]}');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_DeepObject_Flattens;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; s: string;
begin
  FN := WriteTempFileJSON('{"app":{"db":{"host":"h"}}}');
  try
    argv := ArgsArgvFromJson(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    AssertTrue(A.TryGetValue('app.db.host', s)); AssertEquals('h', s);
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_MixedArray_OnlyScalars_Kept;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; all: TStringArray;
begin
  FN := WriteTempFileJSON('{"tags":["a",1,true,null,{},[]]}');
  try
    argv := ArgsArgvFromJson(FN);
    opts := MakeDefaultOpts;
    A := TArgs.FromArray(argv, opts);
    all := A.GetAll('tags');
    AssertEquals(3, Length(all));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Invalid_ReturnsEmpty;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('{\"a\":,}');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_RootArray_ReturnsEmpty;
var FN: string; argv: TStringArray;
begin
  FN := WriteTempFileJSON('[1,2,3]');
  try
    argv := ArgsArgvFromJson(FN);
    AssertEquals(0, Length(argv));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Key_Normalization;
var FN: string; argv: TStringArray; A: TArgs; opts: TArgsOptions; all: TStringArray; s: string;
begin
  FN := WriteTempFileJSON('{"APP_Name":"X","app_count":2, "App_DEBUG":true, "app":{"DB_Host":"h"}}');
  try
    argv := ArgsArgvFromJson(FN);
    opts := ArgsOptionsDefault;
    A := TArgs.FromArray(argv, opts);
    AssertTrue(A.TryGetValue('app-name', s));
    AssertTrue(A.TryGetValue('app-count', s));
    AssertTrue(A.TryGetValue('app-debug', s));
    AssertTrue(A.TryGetValue('app.db-host', s));
    all := A.GetAll('app.name'); AssertEquals(1, Length(all));
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;

procedure TTestCase_Core_Args_Config_Json.Test_JSON_Key_Normalization_Boundaries;
var FN: string; argv: TStringArray; A: TArgs; s: string;
begin
  FN := WriteTempFileJSON('{"A__B-C1":"v","arr_key":[1,2],"N_N":"x","obj":{"__K":"v"}}');
  try
    argv := ArgsArgvFromJson(FN);
    A := TArgs.FromArray(argv, MakeDefaultOpts);
    AssertTrue(A.TryGetValue('a--b-c1', s)); // existing dash preserved; double underscore stays as two dashes
    AssertTrue(A.TryGetValue('arr-key', s)); // array produces repeated tokens; key normalized
    AssertTrue(A.TryGetValue('n-n', s));     // underscores->dashes; case lowered
    AssertTrue(A.TryGetValue('obj.--k', s)); // edge prefix underscores normalized inside segment
  finally
    if FileExists(FN) then DeleteFile(FN);
  end;
end;


procedure RegisterTests;
begin
  RegisterTest(TTestCase_Core_Args_Config_Json);
end;

{$ENDIF}

end.
