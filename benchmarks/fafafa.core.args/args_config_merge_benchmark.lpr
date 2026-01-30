program args_config_merge_benchmark;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, DateUtils, Classes,
  fafafa.core.args,
  fafafa.core.args.config,
  fafafa.core.env;

const
  ITERATIONS = 2000;
  CONFIG_SIZE_SMALL = 10;
  CONFIG_SIZE_LARGE = 100;

function CreateTempConfigFile(KeyCount: Integer): string;
var
  i: Integer;
  content: TStringList;
  tempFile: string;
begin
  content := TStringList.Create;
  try
    content.Add('[app]');
    for i := 1 to KeyCount do
    begin
      content.Add(Format('key%d = "value%d"', [i, i]));
      if i mod 10 = 0 then
      begin
        content.Add(Format('[section%d]', [i div 10]));
      end;
    end;
    
    tempFile := GetTempFileName('', 'bench_config_');
    content.SaveToFile(tempFile);
    Result := tempFile;
  finally
    content.Free;
  end;
end;

procedure SetupTestEnv(KeyCount: Integer);
var
  i: Integer;
begin
  for i := 1 to KeyCount do
    env_set(Format('APP_ENV_KEY%d', [i]), Format('env_value%d', [i]));
end;

procedure CleanupTestEnv(KeyCount: Integer);
var
  i: Integer;
begin
  for i := 1 to KeyCount do
    env_unset(Format('APP_ENV_KEY%d', [i]));
end;

function GenerateCLIArgs(KeyCount: Integer): TStringArray;
var
  i: Integer;
begin
  SetLength(Result, KeyCount);
  for i := 0 to KeyCount-1 do
    Result[i] := Format('--cli-key%d=cli_value%d', [i+1, i+1]);
end;

procedure BenchmarkEnvParsing;
var
  i: Integer;
  envArgv: TStringArray;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Environment Variable Parsing ===');
  
  SetupTestEnv(CONFIG_SIZE_SMALL);
  try
    startTime := Now;
    for i := 1 to ITERATIONS do
      envArgv := ArgsArgvFromEnv('APP_');
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('ENV parsing (%d vars): %.0f parses/sec', 
      [CONFIG_SIZE_SMALL, ITERATIONS / elapsed * 1000]));
    WriteLn(Format('Found %d environment arguments', [Length(envArgv)]));
  finally
    CleanupTestEnv(CONFIG_SIZE_SMALL);
  end;
end;

{$IFDEF FAFAFA_ARGS_CONFIG_TOML}
procedure BenchmarkTOMLParsing;
var
  i: Integer;
  configFile: string;
  configArgv: TStringArray;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== TOML Config Parsing ===');
  
  configFile := CreateTempConfigFile(CONFIG_SIZE_SMALL);
  try
    startTime := Now;
    for i := 1 to ITERATIONS do
      configArgv := ArgsArgvFromToml(configFile);
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('TOML parsing (%d keys): %.0f parses/sec', 
      [CONFIG_SIZE_SMALL, ITERATIONS / elapsed * 1000]));
    WriteLn(Format('Found %d config arguments', [Length(configArgv)]));
  finally
    DeleteFile(configFile);
  end;
end;
{$ENDIF}

procedure BenchmarkConfigMerging;
var
  i: Integer;
  configFile: string;
  envArgv, configArgv, cliArgv, merged: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Config Merging Performance ===');
  
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  configFile := CreateTempConfigFile(CONFIG_SIZE_SMALL);
  {$ENDIF}
  SetupTestEnv(CONFIG_SIZE_SMALL);
  
  try
    {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
    configArgv := ArgsArgvFromToml(configFile);
    {$ELSE}
    SetLength(configArgv, 0);
    {$ENDIF}
    envArgv := ArgsArgvFromEnv('APP_');
    cliArgv := GenerateCLIArgs(CONFIG_SIZE_SMALL);
    
    opts := ArgsOptionsDefault;
    
    startTime := Now;
    for i := 1 to ITERATIONS do
    begin
      // 模拟配置合并：CONFIG → ENV → CLI
      merged := configArgv + envArgv + cliArgv;
      A := TArgs.FromArray(merged, opts);
      A.Free;
    end;
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('Config merging: %.0f merges/sec', [ITERATIONS / elapsed * 1000]));
    WriteLn(Format('Total merged args: %d', [Length(merged)]));
    
  finally
    {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
    DeleteFile(configFile);
    {$ENDIF}
    CleanupTestEnv(CONFIG_SIZE_SMALL);
  end;
end;

procedure BenchmarkLargeConfigMerging;
var
  i: Integer;
  configFile: string;
  envArgv, configArgv, cliArgv, merged: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
begin
  WriteLn('=== Large Config Merging Performance ===');
  
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  configFile := CreateTempConfigFile(CONFIG_SIZE_LARGE);
  {$ENDIF}
  SetupTestEnv(CONFIG_SIZE_LARGE);
  
  try
    {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
    configArgv := ArgsArgvFromToml(configFile);
    {$ELSE}
    SetLength(configArgv, 0);
    {$ENDIF}
    envArgv := ArgsArgvFromEnv('APP_');
    cliArgv := GenerateCLIArgs(CONFIG_SIZE_LARGE);
    
    opts := ArgsOptionsDefault;
    
    startTime := Now;
    for i := 1 to ITERATIONS div 10 do  // 减少迭代次数，因为配置更大
    begin
      merged := configArgv + envArgv + cliArgv;
      A := TArgs.FromArray(merged, opts);
      A.Free;
    end;
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('Large config merging: %.0f merges/sec', 
      [(ITERATIONS div 10) / elapsed * 1000]));
    WriteLn(Format('Total merged args: %d', [Length(merged)]));
    
  finally
    {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
    DeleteFile(configFile);
    {$ENDIF}
    CleanupTestEnv(CONFIG_SIZE_LARGE);
  end;
end;

procedure BenchmarkPrecedenceResolution;
var
  i: Integer;
  configFile: string;
  envArgv, configArgv, cliArgv, merged: TStringArray;
  A: TArgs;
  opts: TArgsOptions;
  startTime, endTime: TDateTime;
  elapsed: Double;
  v: string;
begin
  WriteLn('=== Precedence Resolution Performance ===');
  
  // 创建冲突的配置：同样的键在不同源中有不同值
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  configFile := CreateTempConfigFile(5);
  configArgv := ArgsArgvFromToml(configFile);
  {$ELSE}
  SetLength(configArgv, 0);
  {$ENDIF}
  
  env_set('APP_KEY1', 'env_value');
  env_set('APP_KEY2', 'env_value');
  envArgv := ArgsArgvFromEnv('APP_');
  
  SetLength(cliArgv, 2);
  cliArgv[0] := '--key1=cli_value';
  cliArgv[1] := '--key3=cli_value';
  
  try
    merged := configArgv + envArgv + cliArgv;
    opts := ArgsOptionsDefault;
    
    startTime := Now;
    for i := 1 to ITERATIONS do
    begin
      A := TArgs.FromArray(merged, opts);
      // 测试优先级解析
      A.TryGetValue('key1', v);  // 应该是 CLI 值
      A.TryGetValue('key2', v);  // 应该是 ENV 值
      A.Free;
    end;
    endTime := Now;
    
    elapsed := MilliSecondsBetween(endTime, startTime);
    WriteLn(Format('Precedence resolution: %.0f resolutions/sec', 
      [ITERATIONS / elapsed * 1000]));
    
  finally
    {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
    DeleteFile(configFile);
    {$ENDIF}
    env_unset('APP_KEY1');
    env_unset('APP_KEY2');
  end;
end;

begin
  WriteLn('fafafa.core.args Config Merge Performance Benchmark');
  WriteLn('===================================================');
  WriteLn('Iterations per test: ', ITERATIONS);
  WriteLn('Small config size: ', CONFIG_SIZE_SMALL);
  WriteLn('Large config size: ', CONFIG_SIZE_LARGE);
  WriteLn;
  
  BenchmarkEnvParsing;
  WriteLn;
  
  {$IFDEF FAFAFA_ARGS_CONFIG_TOML}
  BenchmarkTOMLParsing;
  WriteLn;
  {$ENDIF}
  
  BenchmarkConfigMerging;
  WriteLn;
  
  BenchmarkLargeConfigMerging;
  WriteLn;
  
  BenchmarkPrecedenceResolution;
  WriteLn;
  
  WriteLn('Config merge benchmark completed successfully.');
end.
