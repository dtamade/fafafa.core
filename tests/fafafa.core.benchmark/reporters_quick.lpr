program reporters_quick;

{$MODE OBJFPC}{$H+}
{$I ..\..\src\fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.benchmark,
  test_reporters_extra;

var
  Fails: Integer = 0;

procedure RunCase(const Name: string; P: procedure);
begin
  WriteLn('Running ', Name, ' ...');
  try
    P();
    WriteLn('  PASS');
  except
    on E: Exception do
    begin
      Inc(Fails);
      WriteLn('  FAIL: ', E.ClassName, ': ', E.Message);
    end;
  end;
end;

begin
  // 顺序执行 5 条用例，失败抛异常、累计失败计数
  RunCase('Reporter-JSON注入Sink截获', @Test_JSONReporter_SinkCapture_Minimal);
  RunCase('Reporter-CSV注入Sink截获', @Test_CSVReporter_SinkCapture_Minimal);
  RunCase('Reporter-ReporterMux 扇出冒烟', @Test_ReporterMux_Fanout_Smoke);
  RunCase('Reporter-NullSink 静默冒烟', @Test_NullSink_Silence_Smoke);
  RunCase('Reporter-Console注入Sink截获', @Test_ConsoleReporter_SinkCapture_Minimal);

  if Fails <> 0 then
    Halt(1)
  else
    Halt(0);
end.

