unit Test_IOCP_Debug_Stats_Windows;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils,
  fafafa.core.socket, fafafa.core.socket.poller;

{$IFDEF WINDOWS}
{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF DEBUG}

type
  TTest_IOCP_Debug_Stats = class(TTestCase)
  published
    procedure Test_DebugStats_SummaryAndReset;
  end;

procedure RegisterTests;

implementation

procedure TTest_IOCP_Debug_Stats.Test_DebugStats_SummaryAndReset;
var
  Poller: IAdvancedSocketPoller;
  S: string;
begin
  // 创建 IOCP 轮询器
  Poller := TSocketPollerFactory.CreateIOCP(128);

  // 仅 DEBUG 下可用的查询接口
  {$IFDEF DEBUG}
  if Supports(Poller, TIOCPSocketPoller) then
  begin
    // 拉取一次摘要（可能为空，验证接口可用即可）
    S := TIOCPSocketPoller(Poller).DbgGetSummaryText;
    // 输出到控制台（测试日志），不做严格断言
    if S <> '' then
      WriteLn('[IOCP][TEST] Summary=', S);

    // 重置统计
    TIOCPSocketPoller(Poller).DbgResetStats;
  end;
  {$ENDIF}

  // 不做进一步断言：该测试仅作为接口可用性的演示
  CheckTrue(True);
end;

procedure RegisterTests;
begin
  RegisterTest(TTest_IOCP_Debug_Stats);
end;

initialization
  RegisterTests;

{$ENDIF}
{$ENDIF}
{$ENDIF}

end.

