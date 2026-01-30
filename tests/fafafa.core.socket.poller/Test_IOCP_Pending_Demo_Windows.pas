unit Test_IOCP_Pending_Demo_Windows;

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
  TTest_IOCP_Pending_Demo = class(TTestCase)
  published
    procedure Test_PrintPendingAndSummary;
  end;

procedure RegisterTests;

implementation

procedure TTest_IOCP_Pending_Demo.Test_PrintPendingAndSummary;
var
  Poller: IAdvancedSocketPoller;
  Summary: string;
  Ini: TIniFile;
  IniPath: string;
  Enabled: Boolean;
  TagText: string;
  LogVerbose: Boolean;
begin
  // 读取演示开关：默认关闭，避免默认执行大量打印
  Enabled := False;
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
      Enabled := Ini.ReadBool('IOCP_PENDING_DEMO', 'enabled', Enabled);
      TagText := Ini.ReadString('IOCP_PENDING_DEMO', 'tag', 'PendingDemo');
      LogVerbose := Ini.ReadBool('IOCP_LOG', 'verbose', True);
    end;
  finally
    if Ini <> nil then Ini.Free;
  end;
  if not Enabled then
  begin
    CheckTrue(True);
    Exit; // 默认不执行演示输出
  end;

  Poller := TSocketPollerFactory.CreateIOCP(64);
  {$IFDEF DEBUG}
  try TIOCPSocketPoller(Poller).DbgSetVerbose(LogVerbose); except end;
  {$ENDIF}

  // 不做任何 I/O，仅演示如何打印 pending 列表与摘要
  // 此时 pending 可能为空；我们只是演示接口输出
  try
    // 打印 pending 列表（受 VERBOSE 控制）
    if TagText = '' then TagText := 'PendingDemo';
    TIOCPSocketPoller(Poller).DbgLogPendingOps(TagText);

    // 打印摘要文本
    Summary := TIOCPSocketPoller(Poller).DbgGetSummaryText;
    if Summary <> '' then
      WriteLn('[IOCP][DEMO] Summary=', Summary)
    else
      WriteLn('[IOCP][DEMO] Summary=<empty>');
  except
    // 在某些编译器设置下，接口->类转换可能无效；忽略异常
  end;

  // 不断言，示例演示用途
  CheckTrue(True);
end;

procedure RegisterTests;
begin
  RegisterTest(TTest_IOCP_Pending_Demo);
end;

initialization
  RegisterTests;

{$ENDIF}
{$ENDIF}
{$ENDIF}

end.

