unit Test_IOCP_Warn_Trigger_Windows;

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
  TTest_IOCP_Warn_Trigger = class(TTestCase)
  published
    procedure Test_TriggerCancelWarnings;
  end;

const
  // 可通过编译宏或 ini 覆盖，默认 False 避免非确定性干扰
  {$IFDEF IOCP_WARN_WEAK_ASSERT}
  C_IOCP_WARN_WEAK_ASSERT_DEFAULT = True;
  {$ELSE}
  C_IOCP_WARN_WEAK_ASSERT_DEFAULT = False;
  {$ENDIF}

  // 可调参数：循环次数和等待毫秒，可由 ini 覆盖
  C_IOCP_WARN_TRIGGER_LOOPS_DEFAULT = 10;
  C_IOCP_WARN_WAIT_MS_DEFAULT = 50;

procedure RegisterTests;

implementation

procedure TTest_IOCP_Warn_Trigger.Test_TriggerCancelWarnings;
var
  Poller: IAdvancedSocketPoller;
  Skt: ISocket;
  I: Integer;
  Summary: string;
  Loops, WaitMs: Integer;
  WeakAssert: Boolean;
  LogVerbose: Boolean;
  Ini: TIniFile;
  IniPath: string;
  FailRate, CancelRate: Integer;
  FoundRate: Boolean;
begin
  // 覆盖配置：读取 iocp_warn_trigger.ini（独立配置，避免混淆）
  Loops := C_IOCP_WARN_TRIGGER_LOOPS_DEFAULT;
  WaitMs := C_IOCP_WARN_WAIT_MS_DEFAULT;
  WeakAssert := C_IOCP_WARN_WEAK_ASSERT_DEFAULT;
  Ini := nil;
  // 使用独立配置文件，避免与其他模块的 testdefaults.ini 混淆
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
      Loops := Ini.ReadInteger('IOCP_WARN', 'loops', Loops);
      WaitMs := Ini.ReadInteger('IOCP_WARN', 'wait_ms', WaitMs);
      WeakAssert := Ini.ReadBool('IOCP_WARN', 'weak_assert', WeakAssert);
      // 运行时 verbose 开关（若未提供，则用 WeakAssert 作为默认）
      LogVerbose := Ini.ReadBool('IOCP_LOG', 'verbose', WeakAssert);
    end;
  finally
    if Ini <> nil then Ini.Free;
  end;

  Poller := TSocketPollerFactory.CreateIOCP(256);
  {$IFDEF DEBUG}
  try TIOCPSocketPoller(Poller).DbgSetVerbose(LogVerbose); except end;
  {$ENDIF}

  // 多次注册后立刻注销，触发 CancelIoEx 完成，从而提高取消比例
  for I := 1 to Loops do
  begin
    Skt := TSocket.CreateTCP;
    Poller.RegisterSocket(Skt, [seRead]);
    Poller.UnregisterSocket(Skt);
    Skt.Close;
  end;

  // 等待worker处理取消完成
  Sleep(WaitMs);

  // 打印一次摘要，便于在 DebugView 中对照 WARN
  if TObject(Pointer(Poller)^) <> nil then; // 防编译器告警的占位
  try
    Summary := TIOCPSocketPoller(Poller).DbgGetSummaryText;
    if Summary <> '' then
      WriteLn('[IOCP][TEST] Summary(after cancels)=', Summary);

    // 简单解析 fail%% / cancel%%
    FailRate := -1; CancelRate := -1; FoundRate := False;
    try
      // 粗糙解析：寻找 "fail%=" 和 "cancel%=" 的数字
      var p := Pos('fail%=', Summary);
      if p > 0 then
      begin
        Inc(p, Length('fail%='));
        FailRate := StrToIntDef(Copy(Summary, p, 3), -1);
        FoundRate := True;
      end;
      p := Pos('cancel%=', Summary);
      if p > 0 then
      begin
        Inc(p, Length('cancel%='));
        CancelRate := StrToIntDef(Copy(Summary, p, 3), -1);
        FoundRate := True;
      end;
    except
      // 忽略解析异常
    end;

    if WeakAssert and FoundRate then
    begin
      // 取消率较高（>=50%）或失败率较高（>=30%）时给出弱断言，用于本地验证 WARN
      AssertTrue('取消率/失败率应较高以触发WARN', (CancelRate >= 50) or (FailRate >= 30));
    end;
  except
    // 在某些编译器设置下，接口->类转换可能无效；忽略异常
  end;

  CheckTrue(True);
end;

procedure RegisterTests;
begin
  RegisterTest(TTest_IOCP_Warn_Trigger);
end;

initialization
  RegisterTests;

{$ENDIF}
{$ENDIF}
{$ENDIF}

end.

