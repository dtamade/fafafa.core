unit Test_IOCP_Write_Demo_Windows;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  fpcunit, testregistry, SysUtils, IniFiles,
  fafafa.core.socket, fafafa.core.socket.poller;

{$IFDEF WINDOWS}
{$IFDEF FAFAFA_SOCKET_POLLER_EXPERIMENTAL}
{$IFDEF DEBUG}

type
  TTest_IOCP_Write_Demo = class(TTestCase)
  published
    procedure Test_WriteReadyWithZeroSend;
  end;

procedure RegisterTests;

implementation

procedure TTest_IOCP_Write_Demo.Test_WriteReadyWithZeroSend;
var
  Poller: IAdvancedSocketPoller;
  Client: ISocket;
  Results: TSocketPollResults;
  Count: Integer;
  Ini: TIniFile;
  IniPath: string;
  Enabled: Boolean;
  LogVerbose: Boolean;
  QueueN, I: Integer;
  MaxPending: Integer;
  BackoffMs: Integer;
  WarnP95Ms: Integer;
begin
  // 默认关闭演示，避免污染常规输出；可通过 ini 打开
  Enabled := False;
  LogVerbose := False;
  Ini := nil;
  IniPath := ExtractFilePath(ParamStr(0)) + 'iocp_warn_trigger.ini';
  if FileExists(IniPath) then
    Ini := TIniFile.Create(IniPath)
  else if FileExists('tests\\fafafa.core.socket.poller\\bin\\iocp_warn_trigger.ini') then
    Ini := TIniFile.Create('tests\\fafafa.core.socket.poller\\bin\\iocp_warn_trigger.ini')
  else if FileExists('tests\\fafafa.core.socket.poller\\iocp_warn_trigger.ini') then
    Ini := TIniFile.Create('tests\\fafafa.core.socket.poller\\iocp_warn_trigger.ini');
  try
    if Ini <> nil then
    begin
      Enabled := Ini.ReadBool('IOCP_WRITE_DEMO', 'enabled', Enabled);
      LogVerbose := Ini.ReadBool('IOCP_LOG', 'verbose', LogVerbose);
      QueueN := Ini.ReadInteger('IOCP_WRITE_DEMO', 'queue_n', 1);
      MaxPending := Ini.ReadInteger('IOCP_WRITE', 'max_pending_zero_sends', 1);
      BackoffMs := Ini.ReadInteger('IOCP_WRITE', 'backoff_ms', 0);
      WarnP95Ms := Ini.ReadInteger('IOCP_WRITE', 'warn_p95_ms', 0);
    end;
  finally
    if Ini <> nil then Ini.Free;
  end;
  if not Enabled then
  begin
    CheckTrue(True);
    Exit;
  end;

  Poller := TSocketPollerFactory.CreateIOCP(16);
  {$IFDEF DEBUG}
  try
    TIOCPSocketPoller(Poller).DbgSetVerbose(LogVerbose);
    // 将 ini 的阈值带入 poller（如果读到）
    TIOCPSocketPoller(Poller).DbgSetWriteThresholds(MaxPending, BackoffMs);
    TIOCPSocketPoller(Poller).DbgSetWriteWarnP95Ms(WarnP95Ms);
    TIOCPSocketPoller(Poller).DbgResetWriteLatency; // 每次演示前清零，方便观察
  except
  end;
  {$ENDIF}

  // 创建一个未连接的 socket，仅用于触发 seWrite 的最小闭环
  Client := TSocket.CreateTCP;
  Poller.RegisterSocket(Client, [seWrite]);

  // 尝试多次触发（受阈值限制），用于观察写队列与 in-flight 行为
  if QueueN < 1 then QueueN := 1;
  for I := 1 to QueueN do
  begin
    // 简化：再次 Modify 以促发投递（demo用途）；真实场景应由上层写队列驱动
    Poller.ModifyEvents(Client, [seWrite]);
    if BackoffMs > 0 then Sleep(BackoffMs);
  end;

  // 轮询查看结果（不强断言）
  SetLength(Results, 0);
  Count := Poller.Poll(100, Results);
  CheckTrue(Count >= 0);

  Client.Close;
end;

procedure RegisterTests;
begin
  RegisterTest(TTest_IOCP_Write_Demo);
end;

initialization
  RegisterTests;

{$ENDIF}
{$ENDIF}
{$ENDIF}

end.

