program queue_bench;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.thread;

function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;

var
  GTaskMs: Integer = 0;


function ShortTask(Data: Pointer): Boolean;
begin
  // 可控时长的短任务，用于测量吞吐
  if GTaskMs > 0 then Sleep(GTaskMs);
  Result := True;
end;

procedure RunBench(Threads, QueueCap, Tasks, Loops: Integer);
var
  P: IThreadPool;
  I, L: Integer;
  StartMs, EndMs, DurMs: QWord;
  F: IFuture;
  Throughput: Double;
begin
  Writeln('--- queue_bench ---');
  Writeln('threads=', Threads, ' queueCap=', QueueCap, ' tasks=', Tasks, ' loops=', Loops);

  // 构建线程池
  if QueueCap >= 0 then
    P := CreateThreadPool(Threads, Threads, 60000, QueueCap, TRejectPolicy.rpAbort)
  else
    P := CreateThreadPool(Threads, Threads, 60000);

  try
    // 预热一轮，避免冷启动影响
    for I := 1 to Threads * 4 do
    begin
      F := P.Submit(@ShortTask, nil);
      F.WaitFor(2000);
    end;

    for L := 1 to Loops do
    begin
      StartMs := NowMs;
      for I := 1 to Tasks do
      begin
        F := P.Submit(@ShortTask, nil);
        // 也可以批量提交再 Join；这里逐个等待更保守，关注核心队列路径
        F.WaitFor(5000);
      end;
      EndMs := NowMs;
      DurMs := EndMs - StartMs;
      if DurMs = 0 then DurMs := 1;
      Throughput := (Tasks * 1000.0) / DurMs;
      Writeln('loop ', L, ': duration(ms)=', DurMs, ' throughput(tps)=', Format('%.0f', [Throughput]));
    end;
  finally
    P.Shutdown;
    P.AwaitTermination(3000);
  end;
end;

function GetEnvInt(const Name: string; Def: Integer): Integer;
var s: string; v: Int64;
begin

function GetEnvIntDefMin(const Name: string; Def, MinVal: Integer): Integer;
var v: Integer;
begin
  v := GetEnvInt(Name, Def);
  if v < MinVal then v := MinVal;
  Result := v;
end;

  s := GetEnvironmentVariable(Name);
  if s = '' then Exit(Def);
  v := StrToIntDef(s, Def);
  if v < 0 then v := Def;
  Result := v;
end;

var
  Threads, QueueCap, Tasks, Loops: Integer;
  Csv: TextFile; CsvPath: string; DoCsv: Boolean; TaskMs: Integer;
begin
  // 参数：环境变量为主（也可拓展解析命令行）
  Threads  := GetEnvIntDefMin('BENCH_THREADS', 4, 1);
  QueueCap := GetEnvInt('BENCH_QUEUE_CAP', 1024); // -1 表示无限
  Tasks    := GetEnvIntDefMin('BENCH_TASKS',  50000, 1);
  Loops    := GetEnvIntDefMin('BENCH_LOOPS', 3, 1);
  TaskMs   := GetEnvInt('BENCH_TASK_MS', 0);
  GTaskMs  := TaskMs;

  // 可选 CSV 输出
  CsvPath := GetEnvironmentVariable('BENCH_CSV');
  DoCsv := CsvPath <> '';
  if DoCsv then
  begin
    AssignFile(Csv, CsvPath);
    if FileExists(CsvPath) then
      Append(Csv)
    else
    begin
      Rewrite(Csv);
      Writeln(Csv, 'timestamp,threads,queue_cap,task_ms,tasks,loops');
    end;
    CloseFile(Csv);
  end;

  // 执行矩阵（可用逗号分隔配置，简单示例使用单组参数）
  if DoCsv then
  begin
    AssignFile(Csv, CsvPath); Append(Csv);
    try
      Writeln(Csv, Format('%d,%d,%d,%d,%d,%d', [
        NowMs, Threads, QueueCap, TaskMs, Tasks, Loops
      ]));
    finally
      CloseFile(Csv);
    end;
  end;

  RunBench(Threads, QueueCap, Tasks, Loops);
end.

