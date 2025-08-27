program fafafa_core_socket_poller_test;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$CODEPAGE UTF8}

uses
  SysUtils, Classes, fpcunit, testregistry, consoletestrunner,
  fafafa.core.socket, fafafa.core.socket.poller,
  fafafa.core.socket.poller.testcase
  {$IFDEF WINDOWS}{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}, Test_IOCP_Smoke_Windows, Test_IOCP_Debug_Stats_Windows, Test_IOCP_Warn_Trigger_Windows, Test_IOCP_Pending_Demo_Windows, Test_IOCP_Write_Demo_Windows{$ENDIF}{$ENDIF};

type
  TMyTestRunner = class(TTestRunner)
  protected
    procedure WriteCustomHelp; override;
  end;

procedure TMyTestRunner.WriteCustomHelp;
{$IFDEF WINDOWS}{$IFDEF DEBUG}{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
var
  LPoller: IAdvancedSocketPoller;
  Cfg: string;
{$ENDIF}{$ENDIF}{$ENDIF}
begin
  inherited WriteCustomHelp;
  WriteLn('');
  WriteLn('fafafa.core.socket.poller 单元测试');
  WriteLn('================================');
  WriteLn('');
  WriteLn('构建模式: debug + 内存泄漏检查');
  {$IFDEF WINDOWS}{$IFDEF DEBUG}
  WriteLn('');
  WriteLn('IOCP 调试提示:');
  WriteLn('  - 在 src/fafafa.core.settings.inc 启用 FAFAFA_SOCKET_POLLER_EXPERIMENTAL');
  WriteLn('  - 可选启用 FAFAFA_IOCP_DEBUG_STRICT_ASSERT（析构阶段严格断言）');
  WriteLn('  - WARN 触发测试配置: tests/fafafa.core.socket.poller/bin/iocp_warn_trigger.ini');
  WriteLn('  - 日志开关: [IOCP_LOG] verbose=true/false（运行期控制详细日志）');
  WriteLn('  - Pending 演示开关在同一 ini: [IOCP_PENDING_DEMO] enabled=true/false，支持自定义 tag');
  WriteLn('  - 详见: tests/fafafa.core.socket.poller/README-IOCP-Debug.md');
  WriteLn('  - 观测清单: tests/fafafa.core.socket.poller/OBSERVATION-CHECKLIST.md');
  {$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
  try
    LPoller := TSocketPollerFactory.CreateIOCP(64);
    try
      Cfg := TIOCPSocketPoller(LPoller).DbgGetConfigText;
      if Cfg <> '' then
      begin
        WriteLn('  - IOCP 当前调试配置:');
        WriteLn(Cfg);
      end;
    except
      // 忽略类型转换等异常，保持帮助输出稳定
    end;
  except
    // 忽略创建失败
  end;
  {$ENDIF}
  {$ENDIF}{$ENDIF}
end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Initialize;
    Application.Title := 'fafafa.core.socket.poller Test Suite';
    Application.Run;
  finally
    Application.Free;
  end;
end.
