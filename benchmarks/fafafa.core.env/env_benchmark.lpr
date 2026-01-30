{$MODE OBJFPC}{$H+}
program env_benchmark;

uses
  {$IFDEF UNIX}Unix,{$ENDIF}
  {$IFDEF WINDOWS}Windows,{$ENDIF}
  SysUtils, Classes,
  fafafa.core.env;

{ ============================================================================ }
{ === Timing Utilities ======================================================= }
{ ============================================================================ }

function GetTickCountMicro: Int64;
{$IFDEF WINDOWS}
var
  F: Int64;
begin
  QueryPerformanceCounter(F);
  Result := F;
end;
{$ELSE}
var
  T: TTimeVal;
begin
  fpGetTimeOfDay(@T, nil);
  Result := Int64(T.tv_usec) + Int64(T.tv_sec) * 1000000;
end;
{$ENDIF}

{ ============================================================================ }
{ === Benchmark: env_expand ================================================== }
{ ============================================================================ }

procedure Benchmark_EnvExpand_Simple;
const
  Iterations = 10000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  S, R: string;
begin
  WriteLn('[Benchmark] env_expand - Simple $VAR');
  WriteLn('  Setup: HOME and USER environment variables');

  S := 'Home: $HOME, User: $USER';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_expand(S);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Sample output: %s', [R]));
  WriteLn;
end;

procedure Benchmark_EnvExpand_Braced;
const
  Iterations = 10000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  S, R: string;
begin
  WriteLn('[Benchmark] env_expand - Braced ${VAR}');

  S := 'Path: ${HOME}/projects/${USER}/data';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_expand(S);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Sample output: %s', [R]));
  WriteLn;
end;

procedure Benchmark_EnvExpand_Mixed;
const
  Iterations = 10000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  S, R: string;
begin
  WriteLn('[Benchmark] env_expand - Mixed syntax');

  S := '$HOME/${USER}/config:${PATH}:$SHELL';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_expand(S);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Sample length: %d chars', [Length(R)]));
  WriteLn;
end;

procedure Benchmark_EnvExpand_NoVars;
const
  Iterations = 50000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  S, R: string;
begin
  WriteLn('[Benchmark] env_expand - No variables (passthrough)');

  S := '/usr/local/bin:/usr/bin:/bin';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_expand(S);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;
end;

procedure Benchmark_EnvExpand_LongString;
const
  Iterations = 5000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  S, R: string;
begin
  WriteLn('[Benchmark] env_expand - Long string with multiple vars');

  // Build a long string with many variable references
  S := '';
  for I := 1 to 20 do
    S := S + '$HOME/${USER}/path' + IntToStr(I) + ':';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_expand(S);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Input length: %d chars', [Length(S)]));
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Output length: %d chars', [Length(R)]));
  WriteLn;
end;

{ ============================================================================ }
{ === Benchmark: PATH Handling =============================================== }
{ ============================================================================ }

procedure Benchmark_SplitPaths_Typical;
const
  Iterations = 10000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  PathStr: string;
  Parts: TStringArray;
begin
  WriteLn('[Benchmark] env_split_paths - Typical PATH');

  PathStr := '/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/home/user/bin';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    Parts := env_split_paths(PathStr);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Path segments: %d', [Length(Parts)]));
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;
end;

procedure Benchmark_SplitPaths_Long;
const
  Iterations = 5000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  PathStr: string;
  Parts: TStringArray;
begin
  WriteLn('[Benchmark] env_split_paths - Long PATH (50 segments)');

  PathStr := '';
  for I := 1 to 50 do
  begin
    if I > 1 then PathStr := PathStr + ':';
    PathStr := PathStr + '/path/to/dir' + IntToStr(I);
  end;

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    Parts := env_split_paths(PathStr);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Path segments: %d', [Length(Parts)]));
  WriteLn(Format('  Input length: %d chars', [Length(PathStr)]));
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;
end;

procedure Benchmark_JoinPaths_Typical;
const
  Iterations = 10000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  Paths: array[0..5] of string;
  R: string;
begin
  WriteLn('[Benchmark] env_join_paths - 6 segments');

  Paths[0] := '/usr/local/bin';
  Paths[1] := '/usr/bin';
  Paths[2] := '/bin';
  Paths[3] := '/usr/sbin';
  Paths[4] := '/sbin';
  Paths[5] := '/home/user/bin';

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_join_paths(Paths);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Output: %s', [R]));
  WriteLn;
end;

procedure Benchmark_JoinPaths_Large;
const
  Iterations = 2000;
  SegmentCount = 50;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  Paths: array of string;
  R: string;
begin
  WriteLn('[Benchmark] env_join_paths - 50 segments');

  SetLength(Paths, SegmentCount);
  for I := 0 to SegmentCount - 1 do
    Paths[I] := '/path/to/directory' + IntToStr(I);

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_join_paths(Paths);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Segments: %d', [SegmentCount]));
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn(Format('  Output length: %d chars', [Length(R)]));
  WriteLn;
end;

{ ============================================================================ }
{ === Benchmark: Basic Operations ============================================ }
{ ============================================================================ }

procedure Benchmark_EnvGet;
const
  Iterations = 50000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  R: string;
begin
  WriteLn('[Benchmark] env_get - Single variable lookup');

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_get('HOME');
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;
end;

procedure Benchmark_EnvLookup;
const
  Iterations = 50000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  V: string;
  Found: Boolean;
begin
  WriteLn('[Benchmark] env_lookup - With existence check');

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    Found := env_lookup('HOME', V);
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  if Found then ; // Suppress hint
  WriteLn;
end;

procedure Benchmark_EnvHas;
const
  Iterations = 100000;
var
  I: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  R: Boolean;
begin
  WriteLn('[Benchmark] env_has - Existence check');

  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
    R := env_has('HOME');
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f ops/sec', [Iterations / (Duration / 1000.0)]));
  if R then ; // Suppress hint
  WriteLn;
end;

procedure Benchmark_EnvIter;
const
  Iterations = 1000;
var
  I, Count: Integer;
  StartTick, EndTick: Int64;
  Duration: Double;
  KV: TEnvKVPair;
begin
  WriteLn('[Benchmark] env_iter - Iterate all variables');

  Count := 0;
  StartTick := GetTickCountMicro;
  for I := 1 to Iterations do
  begin
    Count := 0;
    for KV in env_iter do
      Inc(Count);
  end;
  EndTick := GetTickCountMicro;

  Duration := (EndTick - StartTick) / 1000.0;
  WriteLn(Format('  Environment variables: %d', [Count]));
  WriteLn(Format('  Iterations: %d', [Iterations]));
  WriteLn(Format('  Time: %.2f ms', [Duration]));
  WriteLn(Format('  Rate: %.0f iter/sec', [Iterations / (Duration / 1000.0)]));
  WriteLn;
end;

{ ============================================================================ }
{ === Main =================================================================== }
{ ============================================================================ }

var
  LStart, LEnd: Int64;
  LDuration: Double;
begin
  WriteLn('============================================================');
  WriteLn('fafafa.core.env Performance Benchmark');
  WriteLn('============================================================');
  WriteLn(Format('Platform: %s / %s', [env_os, env_arch]));
  WriteLn(Format('Environment variable count: %d', [env_count]));
  WriteLn('============================================================');
  WriteLn;

  LStart := GetTickCountMicro;

  // Basic operations
  WriteLn('--- Basic Operations ---');
  Benchmark_EnvGet;
  Benchmark_EnvLookup;
  Benchmark_EnvHas;
  Benchmark_EnvIter;

  // String expansion
  WriteLn('--- String Expansion (env_expand) ---');
  Benchmark_EnvExpand_Simple;
  Benchmark_EnvExpand_Braced;
  Benchmark_EnvExpand_Mixed;
  Benchmark_EnvExpand_NoVars;
  Benchmark_EnvExpand_LongString;

  // PATH handling
  WriteLn('--- PATH Handling ---');
  Benchmark_SplitPaths_Typical;
  Benchmark_SplitPaths_Long;
  Benchmark_JoinPaths_Typical;
  Benchmark_JoinPaths_Large;

  LEnd := GetTickCountMicro;
  LDuration := (LEnd - LStart) / 1000.0;

  WriteLn('============================================================');
  WriteLn(Format('Total benchmark time: %.2f ms', [LDuration]));
  WriteLn('============================================================');
end.
