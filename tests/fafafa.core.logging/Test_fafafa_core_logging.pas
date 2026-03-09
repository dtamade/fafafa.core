unit Test_fafafa_core_logging;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  Test_helpers_io;

type
  { 全局函数测试 }
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_GetLogger_And_Log;
    procedure Test_TextSink_With_StringSink_Assert;
    procedure Test_AsyncTextSink_Basic;
    procedure Test_JsonFormatter_Basic;
    procedure Test_AsyncLogSink_Basic;
    procedure Test_EnableAsyncRoot_And_Stats;
    procedure Test_RollingFile_Basic;
    procedure Test_Composite_Console_And_Rolling;
  end;

implementation

uses
  fafafa.core.io,
  fafafa.core.logging.sinks.textsink, fafafa.core.logging.sinks.console,
  fafafa.core.logging.sinks.async,
  fafafa.core.logging.formatters.text, fafafa.core.logging.formatters.json;

procedure TTestCase_Global.Test_GetLogger_And_Log;
var
  L: ILogger;
begin
  L := GetLogger('test');
  CheckNotNull(L);
  L.Info('hello %s', ['world']);
end;

procedure TTestCase_Global.Test_TextSink_With_StringSink_Assert;
var
  S: TStringSink;
  Sink: ILogSink;
  Fmt: ILogFormatter;
  L: ILogger;
  PrevFactory: ILoggerFactory;
begin
  // 捕获输出
  S := TStringSink.Create;
  Fmt := TTextLogFormatter.Create;
  Sink := TTextSinkLogSink.Create(S, Fmt);

  // 注入全局 sink/formatter（保留 Factory）
  PrevFactory := Logging.GetFactory;
  Logging.SetRootSink(Sink);
  Logging.SetFormatter(Fmt);
  try
    L := GetLogger('cap');
    L.Info('sum=%d', [3]);
  finally
    // 复原全局（最小化副作用）
    Logging.SetRootSink(TConsoleLogSink.Create);
    Logging.SetFormatter(TTextLogFormatter.Create);
    if PrevFactory <> nil then Logging.SetFactory(PrevFactory);
  end;

  // 断言输出包含关键片段（时间前缀不做强匹配）
  CheckTrue(Pos(' [INF] cap - sum=3', S.AsText) > 0, 'captured text should contain rendered message');
end;

procedure TTestCase_Global.Test_AsyncTextSink_Basic;
var S: TStringSink; Fmt, PrevFmt: ILogFormatter; L: ILogger; Sink, PrevSink: ILogSink;
begin
  S := TStringSink.Create;
  Fmt := TTextLogFormatter.Create;
  // 使用异步 sink 包装 StringSink
  Sink := TAsyncLogSink.Create(TTextSinkLogSink.Create(S, Fmt), 8, 4, ldpDropOld);
  // 保存并替换全局
  PrevSink := Logging.GetRootSink;
  PrevFmt := Logging.GetFormatter;
  Logging.SetRootSink(Sink);
  Logging.SetFormatter(Fmt);
  try
    L := GetLogger('async');
    L.Info('a', []);
    L.Info('b', []);
    L.Info('c', []);
    // 冲刷
    Logging.GetRootSink.Flush;
    CheckTrue(Pos('async - a', S.AsText) > 0);
  finally
    // 复原全局，释放异步 sink
    Logging.SetRootSink(PrevSink);
    Logging.SetFormatter(PrevFmt);
  end;
end;

procedure TTestCase_Global.Test_JsonFormatter_Basic;
var S: TStringSink; Fmt: ILogFormatter; L: ILogger; Sink: ILogSink; OutText: string;
begin
  S := TStringSink.Create;
  Fmt := TJsonLogFormatter.Create;
  Sink := TTextSinkLogSink.Create(S, Fmt);
  Logging.SetRootSink(Sink);
  L := GetLogger('json');
  L.Info('hello %s', ['x']);
  Sink.Flush;
  OutText := S.AsText;
  CheckTrue(Pos('"level":"info"', OutText) > 0);
  CheckTrue(Pos('"logger":"json"', OutText) > 0);
  CheckTrue(Pos('"message":"hello x"', OutText) > 0);
end;

procedure TTestCase_Global.Test_AsyncLogSink_Basic;
var
  S: TStringSink;
  Fmt, PrevFmt: ILogFormatter;
  L: ILogger;
  Inner, Async, PrevSink: ILogSink;
begin
  // 使用 TAsyncLogSink 包装 Console 文本 sink 适配器
  S := TStringSink.Create;
  Fmt := TTextLogFormatter.Create;
  Inner := TTextSinkLogSink.Create(S, Fmt);
  Async := TAsyncLogSink.Create(Inner, 8, 4, ldpDropOld);
  // 保存并替换全局
  PrevSink := Logging.GetRootSink;
  PrevFmt := Logging.GetFormatter;
  Logging.SetRootSink(Async);
  Logging.SetFormatter(Fmt);
  try
    L := GetLogger('alog');
    L.Info('m1', []);
    L.Info('m2', []);
    // Flush 要求把队列中的记录全部落到内层 sink
    Logging.GetRootSink.Flush;
    CheckTrue(Pos('alog - m1', S.AsText) > 0);
    CheckTrue(Pos('alog - m2', S.AsText) > 0);
  finally
    // 复原全局，释放异步 sink
    Logging.SetRootSink(PrevSink);
    Logging.SetFormatter(PrevFmt);
  end;
end;

procedure TTestCase_Global.Test_EnableAsyncRoot_And_Stats;
var
  L: ILogger;
  Stats: TLogSinkStats;
begin
  EnableAsyncRoot(16, 4);
  L := GetLogger('root');
  L.Info('x', []);
  L.Info('y', []);
  // Flush to ensure worker drained
  Logging.GetRootSink.Flush;
  CheckTrue(TryGetRootSinkStats(Stats));
  CheckTrue(Stats.Enqueued >= 2);
  CheckTrue(Stats.Dequeued >= 2);
end;

procedure TTestCase_Global.Test_RollingFile_Basic;
var
  tmp: string;
  L: ILogger;
  content: string;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'log.txt';
  if FileExists(tmp) then DeleteFile(tmp);
  // 设置较大的阈值，避免本测试中发生滚动影响断言
  EnableAsyncRollingFileRoot(tmp, 4096, 64, 16);
  L := GetLogger('file');
  L.Info('0123456789', []);
  L.Info('abcdefghij', []);
  L.Info('KLMNOPQRST', []);
  // 冲刷并读取
  Logging.GetRootSink.Flush;
  if FileExists(tmp) then
    content := ReadAllText(tmp)
  else
    content := '';
  CheckTrue(Pos('file - 0123456789', content) > 0);
end;

procedure TTestCase_Global.Test_Composite_Console_And_Rolling;
var
  tmp: string;
  L: ILogger;
  content: string;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'log2.txt';
  if FileExists(tmp) then DeleteFile(tmp);
  EnableConsoleAndRollingRoot(tmp, 4096, 64, 16);
  L := GetLogger('comp');
  L.Info('hello', []);
  Logging.GetRootSink.Flush;
  content := ReadAllText(tmp);
  CheckTrue(Pos('comp - hello', content) > 0);
end;


initialization
  RegisterTest(TTestCase_Global);
end.

