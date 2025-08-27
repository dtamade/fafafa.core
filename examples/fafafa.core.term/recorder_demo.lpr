{$CODEPAGE UTF8}
program recorder_demo;

{**
 * 录制回放演示
 *
 * 这个示例演示了如何使用 fafafa.core.term 的录制回放功能：
 * - 终端会话录制
 * - 录制文件保存和加载
 * - 会话回放
 * - asciicast格式支持
 * - 录制事件处理
 * - 回放控制
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Math,
  fafafa.core.base, fafafa.core.term,
  recorder_stub;

type
  {**
   * 录制回放演示器
   *}
  TRecorderDemo = class
  private
    FTerminal: ITerminal;
    FOutput: ITerminalOutput;
    FInput: ITerminalInput;
    FRecorder: ITerminalRecorder;
    FRunning: Boolean;

    procedure ShowMenu;
    procedure DemoRecording;
    procedure DemoPlayback;
    procedure DemoSessionInfo;
    procedure DemoRecordingControl;
    procedure DemoFileOperations;
    procedure ShowRecorderStatus;
    procedure OnRecordEvent(const aEventType: string; const aData: string; aTimestamp: Double);
    procedure OnPlaybackEvent(const aEventType: string; const aData: string; aTimestamp: Double);
    procedure WaitForKey(const aPrompt: string = '按任意键继续...');
  public
    constructor Create;
    destructor Destroy; override;
    
    procedure Run;
  end;

constructor TRecorderDemo.Create;
begin
  inherited Create;
  FTerminal := CreateTerminal;
  FOutput := FTerminal.Output;
  FInput := FTerminal.Input;
  FRecorder := CreateSimpleRecorder;
  FRunning := False;
  
  // 设置录制和回放事件回调
  FRecorder.SetRecordEventCallback(@OnRecordEvent);
  FRecorder.SetPlaybackEventCallback(@OnPlaybackEvent);
end;

destructor TRecorderDemo.Destroy;
begin
  if FRecorder.IsRecording then
    FRecorder.StopRecording;
  if FRecorder.IsPlaying then
    FRecorder.StopPlayback;
    
  FTerminal := nil;
  inherited Destroy;
end;

procedure TRecorderDemo.ShowMenu;
var
  LState: TRecordingState;
  LStateText: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.MoveCursor(0, 0);
  
  FOutput.SetForegroundColor(tcYellow);
  FOutput.WriteLn('fafafa.core.term 录制回放演示');
  FOutput.WriteLn('=============================');
  FOutput.ResetColors;
  FOutput.WriteLn;
  
  // 显示当前状态
  LState := FRecorder.GetRecordingState;
  FOutput.Write('当前状态: ');
  case LState of
    rsIdle: begin FOutput.SetForegroundColor(tcGreen); LStateText := '空闲'; end;
    rsRecording: begin FOutput.SetForegroundColor(tcRed); LStateText := '录制中'; end;
    rsPaused: begin FOutput.SetForegroundColor(tcYellow); LStateText := '录制暂停'; end;
    rsPlaying: begin FOutput.SetForegroundColor(tcBlue); LStateText := '回放中'; end;
    rsPlayPaused: begin FOutput.SetForegroundColor(tcMagenta); LStateText := '回放暂停'; end;
  end;
  FOutput.Write(LStateText);
  FOutput.ResetColors;
  FOutput.WriteLn;
  FOutput.WriteLn;

  FOutput.WriteLn('请选择演示项目:');
  FOutput.WriteLn;
  FOutput.WriteLn('1. 录制演示');
  FOutput.WriteLn('2. 回放演示');
  FOutput.WriteLn('3. 会话信息演示');
  FOutput.WriteLn('4. 录制控制演示');
  FOutput.WriteLn('5. 文件操作演示');
  FOutput.WriteLn('6. 显示录制器状态');
  FOutput.WriteLn('0. 退出');
  FOutput.WriteLn;
  FOutput.Write('请输入选择 (0-6): ');
end;

procedure TRecorderDemo.DemoRecording;
var
  LInput: string;
  LStartTime: TDateTime;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('录制演示');
  FOutput.WriteLn('========');
  FOutput.WriteLn;
  
  if FRecorder.IsRecording then
  begin
    FOutput.WriteLn('当前正在录制中，请先停止录制');
    WaitForKey;
    Exit;
  end;
  
  FOutput.WriteLn('开始录制会话...');
  FRecorder.StartRecording('演示录制会话');
  
  LStartTime := Now;
  FOutput.WriteLn('录制已开始！');
  FOutput.WriteLn;
  
  // 模拟一些终端活动
  FOutput.WriteLn('这是一个录制演示');
  FRecorder.RecordOutput('这是一个录制演示' + LineEnding);
  Sleep(500);
  
  FOutput.SetForegroundColor(tcGreen);
  FOutput.WriteLn('绿色文本输出');
  FRecorder.RecordOutput(#27'[32m绿色文本输出'#27'[0m' + LineEnding);
  FOutput.ResetColors;
  Sleep(300);
  
  FOutput.SetForegroundColor(tcBlue);
  FOutput.WriteLn('蓝色文本输出');
  FRecorder.RecordOutput(#27'[34m蓝色文本输出'#27'[0m' + LineEnding);
  FOutput.ResetColors;
  Sleep(400);
  
  // 记录一些事件
  FRecorder.RecordMarker('demo_marker', '这是一个演示标记');
  FRecorder.RecordResize(80, 25);
  
  FOutput.WriteLn;
  FOutput.WriteLn('录制了一些示例内容');
  FOutput.WriteLn(Format('录制时长: %.2f 秒', [(Now - LStartTime) * 24 * 60 * 60]));
  FOutput.WriteLn(Format('事件数量: %d', [FRecorder.GetEventCount]));
  FOutput.WriteLn;
  
  FOutput.Write('按回车停止录制...');
  ReadLn(LInput);
  
  FRecorder.StopRecording;
  FOutput.WriteLn('录制已停止');
  
  WaitForKey;
end;

procedure TRecorderDemo.DemoPlayback;
var
  LFileName: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('回放演示');
  FOutput.WriteLn('========');
  FOutput.WriteLn;
  
  if FRecorder.IsPlaying then
  begin
    FOutput.WriteLn('当前正在回放中，请先停止回放');
    WaitForKey;
    Exit;
  end;
  
  // 首先保存当前录制
  if FRecorder.GetEventCount > 0 then
  begin
    LFileName := 'demo_session.cast';
    FOutput.WriteLn('保存当前录制到: ' + LFileName);
    
    try
      FRecorder.SaveRecording(LFileName);
      FOutput.WriteLn('保存成功');
    except
      on E: Exception do
      begin
        FOutput.WriteLn('保存失败: ' + E.Message);
        WaitForKey;
        Exit;
      end;
    end;
    
    FOutput.WriteLn;
    FOutput.WriteLn('开始回放...');
    Sleep(1000);
    
    try
      FRecorder.StartPlayback(LFileName);
      FOutput.WriteLn('回放完成');
    except
      on E: Exception do
        FOutput.WriteLn('回放失败: ' + E.Message);
    end;
  end
  else
  begin
    FOutput.WriteLn('没有录制内容可以回放');
    FOutput.WriteLn('请先进行录制演示');
  end;
  
  WaitForKey;
end;

procedure TRecorderDemo.DemoSessionInfo;
var
  LSession: TRecordingSession;
  I: Integer;
  LEventName: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('会话信息演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  LSession := FRecorder.GetCurrentSession;
  
  FOutput.WriteLn('当前会话信息:');
  FOutput.WriteLn('  版本: ' + IntToStr(LSession.Version));
  FOutput.WriteLn('  尺寸: ' + IntToStr(LSession.Width) + 'x' + IntToStr(LSession.Height));
  FOutput.WriteLn('  标题: ' + LSession.Title);
  FOutput.WriteLn('  命令: ' + LSession.Command);
  FOutput.WriteLn('  Shell: ' + LSession.Shell);
  FOutput.WriteLn('  终端类型: ' + LSession.TerminalType);
  FOutput.WriteLn('  开始时间: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', LSession.Timestamp));
  FOutput.WriteLn('  时长: ' + FormatTimestamp(LSession.Duration));
  FOutput.WriteLn('  事件数量: ' + IntToStr(Length(LSession.Events)));
  FOutput.WriteLn;
  
  if Length(LSession.Events) > 0 then
  begin
    FOutput.WriteLn('最近的事件:');
    for I := Max(0, Length(LSession.Events) - 5) to High(LSession.Events) do
    begin
      // 将事件类型转换为名称字符串
      LEventName := '';
      case LSession.Events[I].EventType of
        retOutput:   LEventName := 'OUTPUT';
        retInput:    LEventName := 'INPUT';
        retResize:   LEventName := 'RESIZE';
        retMouse:    LEventName := 'MOUSE';
        retKeyboard: LEventName := 'KEYBOARD';
        retCommand:  LEventName := 'COMMAND';
        retMarker:   LEventName := 'MARKER';
        retMetadata: LEventName := 'METADATA';
      else
        LEventName := 'UNKNOWN';
      end;

      FOutput.WriteLn(Format('  [%s] %s: %s', [
        FormatTimestamp(LSession.Events[I].Timestamp),
        LEventName,
        Copy(LSession.Events[I].Data, 1, 50)
      ]));
    end;
  end;
  
  WaitForKey;
end;

procedure TRecorderDemo.DemoRecordingControl;
var
  LChoice: string;
  LStateText: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('录制控制演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  while True do
  begin
    FOutput.MoveCursor(0, 4);
    // 将状态枚举转换为可打印文本

    case FRecorder.GetRecordingState of
      rsIdle:       LStateText := '空闲';
      rsRecording:  LStateText := '录制中';
      rsPaused:     LStateText := '暂停';
      rsPlaying:    LStateText := '回放中';
      rsPlayPaused: LStateText := '回放暂停';
    else
      LStateText := '未知';
    end;
    FOutput.WriteLn('当前状态: ' + LStateText + '                    ');

    FOutput.WriteLn;
    FOutput.WriteLn('控制选项:');
    FOutput.WriteLn('  s - 开始录制');
    FOutput.WriteLn('  t - 停止录制');
    FOutput.WriteLn('  p - 暂停/恢复录制');
    FOutput.WriteLn('  m - 添加标记');
    FOutput.WriteLn('  q - 返回主菜单');
    FOutput.WriteLn;
    FOutput.Write('请选择: ');
    
    ReadLn(LChoice);
    LChoice := LowerCase(Trim(LChoice));
    
    case LChoice of
      's':
      begin
        if not FRecorder.IsRecording then
        begin
          FRecorder.StartRecording('控制演示录制');
          FOutput.WriteLn('录制已开始');
        end
        else
          FOutput.WriteLn('已经在录制中');
      end;
      
      't':
      begin
        if FRecorder.IsRecording then
        begin
          FRecorder.StopRecording;
          FOutput.WriteLn('录制已停止');
        end
        else
          FOutput.WriteLn('当前没有在录制');
      end;
      
      'p':
      begin
        case FRecorder.GetRecordingState of
          rsRecording:
          begin
            FRecorder.PauseRecording;
            FOutput.WriteLn('录制已暂停');
          end;
          rsPaused:
          begin
            FRecorder.ResumeRecording;
            FOutput.WriteLn('录制已恢复');
          end;
        else
          FOutput.WriteLn('当前状态不支持暂停/恢复');
        end;
      end;
      
      'm':
      begin
        if FRecorder.IsRecording then
        begin
          FRecorder.RecordMarker('user_marker', '用户添加的标记');
          FOutput.WriteLn('标记已添加');
        end
        else
          FOutput.WriteLn('需要在录制状态下添加标记');
      end;
      
      'q':
        Break;
        
    else
      FOutput.WriteLn('无效选择');
    end;
    
    Sleep(500);
  end;
end;

procedure TRecorderDemo.DemoFileOperations;
var
  LFileName: string;
  LFormats: array of TRecordingFormat;
  I: Integer;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('文件操作演示');
  FOutput.WriteLn('============');
  FOutput.WriteLn;
  
  // 显示支持的格式
  LFormats := FRecorder.GetSupportedFormats;
  FOutput.WriteLn('支持的格式:');
  for I := 0 to High(LFormats) do
  begin
    FOutput.WriteLn('  ' + case LFormats[I] of
      rfAsciiCast: 'asciicast (.cast)';
      rfJSON: 'JSON (.json)';
      rfBinary: 'Binary (.bin)';
      rfCustom: 'Custom';
    end);
  end;
  FOutput.WriteLn;
  
  if FRecorder.GetEventCount > 0 then
  begin
    LFileName := 'test_session.cast';
    
    FOutput.WriteLn('保存录制到文件: ' + LFileName);
    try
      FRecorder.SaveRecording(LFileName);
      FOutput.WriteLn('保存成功');
      
      FOutput.WriteLn('文件大小: ' + IntToStr(FileSize(LFileName)) + ' 字节');
      
      // 测试导入
      FOutput.WriteLn('测试导入文件...');
      if FRecorder.ImportRecording(LFileName) then
        FOutput.WriteLn('导入成功')
      else
        FOutput.WriteLn('导入失败');
        
    except
      on E: Exception do
        FOutput.WriteLn('操作失败: ' + E.Message);
    end;
  end
  else
  begin
    FOutput.WriteLn('没有录制内容可以保存');
    FOutput.WriteLn('请先进行录制');
  end;
  
  WaitForKey;
end;

procedure TRecorderDemo.ShowRecorderStatus;
var
  LOptions: TPlaybackOptions;
  LStateText: string;
begin
  FOutput.ClearScreen(tctAll);
  FOutput.WriteLn('录制器状态');
  FOutput.WriteLn('==========');
  FOutput.WriteLn;

  // 将状态枚举转换为可打印文本

  case FRecorder.GetRecordingState of
    rsIdle:       LStateText := '空闲';
    rsRecording:  LStateText := '录制中';
    rsPaused:     LStateText := '录制暂停';
    rsPlaying:    LStateText := '回放中';
    rsPlayPaused: LStateText := '回放暂停';
  else
    LStateText := '未知';
  end;
  FOutput.WriteLn('录制状态: ' + LStateText);
  
  FOutput.WriteLn('是否正在录制: ' + BoolToStr(FRecorder.IsRecording, '是', '否'));
  FOutput.WriteLn('是否正在回放: ' + BoolToStr(FRecorder.IsPlaying, '是', '否'));
  FOutput.WriteLn('会话时长: ' + FormatTimestamp(FRecorder.GetSessionDuration));
  FOutput.WriteLn('事件数量: ' + IntToStr(FRecorder.GetEventCount));
  
  if FRecorder.IsPlaying then
    FOutput.WriteLn('回放位置: ' + FormatTimestamp(FRecorder.GetPlaybackPosition));
  
  FOutput.WriteLn;
  
  LOptions := FRecorder.GetPlaybackOptions;
  FOutput.WriteLn('回放选项:');
  FOutput.WriteLn('  速度: ' + FormatFloat('0.0', LOptions.Speed) + 'x');
  FOutput.WriteLn('  最大延迟: ' + FormatFloat('0.0', LOptions.MaxDelay) + 's');
  FOutput.WriteLn('  跳过空闲: ' + BoolToStr(LOptions.SkipIdle, '是', '否'));
  FOutput.WriteLn('  循环回放: ' + BoolToStr(LOptions.Loop, '是', '否'));
  FOutput.WriteLn('  显示时间戳: ' + BoolToStr(LOptions.ShowTimestamp, '是', '否'));
  FOutput.WriteLn('  显示进度: ' + BoolToStr(LOptions.ShowProgress, '是', '否'));
  
  WaitForKey;
end;

procedure TRecorderDemo.OnRecordEvent(const aEventType: string; const aData: string; aTimestamp: Double);
begin
  // 录制事件回调 - 可以用于实时监控录制
  // 这里简化处理，实际应用中可以显示录制状态等
end;

procedure TRecorderDemo.OnPlaybackEvent(const aEventType: string; const aData: string; aTimestamp: Double);
begin
  // 回放事件回调 - 可以用于显示回放进度
  // 这里简化处理，实际应用中可以显示进度条等
end;

procedure TRecorderDemo.WaitForKey(const aPrompt: string = '按任意键继续...');
begin
  FOutput.WriteLn;
  FOutput.Write(aPrompt);
  ReadLn;
end;

procedure TRecorderDemo.Run;
var
  LChoice: string;
begin
  FRunning := True;
  
  while FRunning do
  begin
    ShowMenu;
    ReadLn(LChoice);
    
    case LChoice of
      '1': DemoRecording;
      '2': DemoPlayback;
      '3': DemoSessionInfo;
      '4': DemoRecordingControl;
      '5': DemoFileOperations;
      '6': ShowRecorderStatus;
      '0': FRunning := False;
    else
      begin
        FOutput.WriteLn('无效选择，请重新输入');
        WaitForKey;
      end;
    end;
  end;
  
  FOutput.WriteLn('感谢使用录制回放演示！');
end;

var
  LDemo: TRecorderDemo;

begin
  try
    LDemo := TRecorderDemo.Create;
    try
      LDemo.Run;
    finally
      LDemo.Free;
    end;
    
  except
    on E: Exception do
    begin
      WriteLn('录制回放演示失败: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
