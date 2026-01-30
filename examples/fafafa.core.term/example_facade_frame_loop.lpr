{$CODEPAGE UTF8}
program example_facade_frame_loop;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.term;

procedure RenderFrame(const Outp: ITerminalOutput; const FrameNo: Integer);
begin
  if FrameNo = 1 then
  begin
    Outp.SetForegroundColorRGB(MakeRGBColor(0, 200, 255));
    Outp.WriteLn('Frame 1: draw full scene');
    Outp.ResetColors;
  end
  else
  begin
    Outp.SetForegroundColorRGB(MakeRGBColor(0, 255, 120));
    Outp.WriteLn('Frame 2: draw only changes');
    Outp.ResetColors;
  end;
end;

var
  Tm: ITerminal;
  Outp: ITerminalOutput;
  Guard: IInterface;
  i: Integer;
begin
  Tm := CreateTerminal;
  Tm.Initialize;
  Outp := Tm.Output;

  // 开启缓冲，模拟两帧渲染（与 ratatui 节奏相仿：collect → render → flush）
  Outp.EnableBuffering;

  // 进入 AltScreen 并隐藏光标（演示性的命令批处理）
  Outp.ExecuteCommands([
    CreateTerminalCommand(#27'[?1049h', 'enter alt screen'),
    CreateTerminalCommand(#27'[?25l', 'hide cursor')
  ]);

  for i := 1 to 2 do
  begin
    RenderFrame(Outp, i);
    Outp.Flush; // 每帧一次 flush
  end;

  // 恢复光标与屏幕
  Outp.ExecuteCommands([
    CreateTerminalCommand(#27'[?25h', 'show cursor'),
    CreateTerminalCommand(#27'[?1049l', 'leave alt screen')
  ]);
  Outp.Flush;
  Outp.DisableBuffering;

  Tm.Finalize;
end.

