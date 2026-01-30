{$CODEPAGE UTF8}
program example_facade_beta;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  fafafa.core.term;

var
  Tm: ITerminal;
  Outp: ITerminalOutput;
  Cmds: array[0..2] of ITerminalCommand;
begin
  // 创建门面并初始化（幂等）
  Tm := CreateTerminal;
  Tm.Initialize;

  Outp := Tm.Output;
  // 开启缓冲，批处理输出
  Outp.EnableBuffering;

  // 1) 直接写
  Outp.WriteLn('Facade Beta demo: buffering + commands');

  // 2) 批处理命令（与 crossterm execute(queue) 类似）
  Cmds[0] := CreateTerminalCommand(#27'[?1049h', 'enter alt screen');
  Cmds[1] := CreateTerminalCommand(#27'[?25l', 'hide cursor');
  Cmds[2] := CreateTerminalCommand(#27'[31m'+'red text'+#27'[0m\n', 'print red');
  Outp.ExecuteCommands(Cmds);

  // 刷新所有缓冲
  Outp.Flush;

  // 恢复（演示：离开 alt screen、显示光标）
  Outp.ExecuteCommands([
    CreateTerminalCommand(#27'[?25h', 'show cursor'),
    CreateTerminalCommand(#27'[?1049l', 'leave alt screen')
  ]);
  Outp.Flush;

  // 关闭缓冲（幂等）
  Outp.DisableBuffering;
  Tm.Finalize;
end.

