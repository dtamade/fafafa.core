unit Test_fafafa_core_logging_more;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.logging.formatters.json,
  fafafa.core.logging.sinks.textsink,
  fafafa.core.io;

type
  TTestCase_More = class(TTestCase)
  published
    procedure Test_JsonFormatter_UTC_Time;
    procedure Test_AsyncWaitAttempts_WithBlock;
  end;

implementation

procedure TTestCase_More.Test_JsonFormatter_UTC_Time;
var
  S: TStringSink;
  F: ILogFormatter;
  L: ILogger;
  Sink: ILogSink;
  OutText: string;
begin
  S := TStringSink.Create;
  F := TJsonLogFormatter.Create(True {UseUTC});
  Sink := TTextSinkLogSink.Create(S, F);
  Logging.SetRootSink(Sink);
  L := GetLogger('utc');
  L.Info('t', []);
  Sink.Flush;
  OutText := S.AsText;
  // 只断言包含 Z
  AssertTrue(Pos('"time":"', OutText) > 0);
  AssertTrue(Pos('Z"', OutText) > 0);
end;

procedure TTestCase_More.Test_AsyncWaitAttempts_WithBlock;
var
  S: TStringSink;
  F: ILogFormatter;
  Inner: ILogSink;
  Async: ILogSink;
  L: ILogger;
  Stats: TLogSinkStats;
  i: Integer;
begin
  // 小容量+dpBlock，制造一点等待
  S := TStringSink.Create;
  F := TTextLogFormatter.Create;
  Inner := TTextSinkLogSink.Create(S, F);
  // 容量1 批量1，阻塞策略
  Async := TAsyncLogSink.Create(Inner, 1, 1, ldpBlock);
  Logging.SetRootSink(Async);
  Logging.SetFormatter(F);
  L := GetLogger('blk');
  for i := 1 to 50 do L.Info('x', []);
  Logging.GetRootSink.Flush;
  AssertTrue(TryGetRootSinkStats(Stats));
  // WaitAttempts 应该大于0（环境敏感，保守断言 > 0）
  AssertTrue(Stats.WaitAttempts > 0);
end;

initialization
  RegisterTest(TTestCase_More);
end.

