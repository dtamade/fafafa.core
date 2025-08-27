{$CODEPAGE UTF8}
program example_snowflake_config;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, StrUtils,
  fafafa.core.id.snowflake;

function GetEnvInt(const Name: string; const Default: Int64): Int64;
var S: string;
begin
  S := GetEnvironmentVariable(Name);
  if S = '' then Exit(Default);
  try
    Result := StrToInt64(S);
  except
    on E: Exception do Result := Default;
  end;
end;

function GetArgValue(const Key: string; const Default: Int64): Int64;
var i: Integer; S, Pfx: string;
begin
  Pfx := Key + '=';
  for i := 1 to ParamCount do
  begin
    S := ParamStr(i);
    if AnsiStartsStr(Pfx, S) then
    begin
      try
        Exit(StrToInt64(Copy(S, Length(Pfx)+1, MaxInt)));
      except
        on E: Exception do Exit(Default);
      end;
    end;
  end;
  Result := Default;
end;

function ChooseIntParam(const ArgKey, EnvKey: string; const Default: Int64): Int64;
var vArg, vEnv: Int64;
begin
  vArg := GetArgValue(ArgKey, High(Int64));
  if vArg <> High(Int64) then Exit(vArg);
  vEnv := GetEnvInt(EnvKey, High(Int64));
  if vEnv <> High(Int64) then Exit(vEnv);
  Result := Default;
end;

procedure PrintCfg(const C: TSnowflakeConfig);
begin
  WriteLn('Snowflake Config: workerId=', C.WorkerId,
          ' epochMs=', C.EpochMs,
          ' policy=', Ord(C.BackwardPolicy));
end;

var
  cfg: TSnowflakeConfig;
  g: ISnowflake;
  id: TSnowflakeID;
begin
  // 默认：Twitter epoch / workerId=0 / sbWait
  cfg.EpochMs := 1288834974657;
  cfg.WorkerId := 0;
  cfg.BackwardPolicy := sbWait;

  // 优先级：参数 > 环境变量 > 默认
  cfg.WorkerId := Word(ChooseIntParam('--worker-id', 'FA_SF_WORKER_ID', cfg.WorkerId));
  cfg.EpochMs  := ChooseIntParam('--sf-epoch-ms', 'FA_SF_EPOCH_MS', cfg.EpochMs);
  if ChooseIntParam('--sf-throw', 'FA_SF_THROW', 0) <> 0 then
    cfg.BackwardPolicy := sbThrow
  else
    cfg.BackwardPolicy := sbWait;

  PrintCfg(cfg);

  g := CreateSnowflakeEx(cfg);
  id := g.NextID;
  WriteLn('Sample ID: ', id,
          ' ts=', Snowflake_TimestampMs(id, cfg.EpochMs),
          ' wid=', Snowflake_WorkerId(id),
          ' seq=', Snowflake_Sequence(id));
end.

