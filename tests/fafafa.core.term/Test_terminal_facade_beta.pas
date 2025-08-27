{$CODEPAGE UTF8}
unit Test_terminal_facade_beta;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term;

implementation

type
  TTestCase_TerminalFacadeBeta = class(TTestCase)
  published
    procedure Test_Create_And_Initialize_Finalize;
    procedure Test_Output_Buffering_And_ExecuteCommands_Overloads;
    procedure Test_Input_PeekKey_NoCrash_NoConsume;
  end;

procedure TTestCase_TerminalFacadeBeta.Test_Create_And_Initialize_Finalize;
var Tm: ITerminal;
begin
  Tm := CreateTerminal;
  AssertTrue('CreateTerminal returns object', Tm <> nil);
  // 调用 Initialize/Finalize 不应抛异常
  Tm.Initialize;
  Tm.Finalize;
  // 再次调用也应安全（幂等）
  Tm.Initialize;
  Tm.Finalize;
  // 访问 Info/Output/Input 不应为 nil
  AssertTrue('Info not nil', Tm.Info <> nil);
  AssertTrue('Output not nil', Tm.Output <> nil);
  AssertTrue('Input not nil', Tm.Input <> nil);
end;

procedure TTestCase_TerminalFacadeBeta.Test_Output_Buffering_And_ExecuteCommands_Overloads;
var Tm: ITerminal;
    Outp: ITerminalOutput;
    Cmd1, Cmd2: ITerminalCommand;
begin
  Tm := CreateTerminal;
  Outp := Tm.Output;
  AssertTrue('Output available', Outp <> nil);
  // 缓冲开关幂等与可用
  Outp.EnableBuffering;
  AssertTrue('buffering on', Outp.IsBufferingEnabled);
  Outp.EnableBuffering; // 幂等
  Outp.DisableBuffering;
  AssertFalse('buffering off', Outp.IsBufferingEnabled);
  Outp.DisableBuffering; // 幂等

  // ExecuteCommand(s) 两种重载均可调用且不崩溃
  Cmd1 := CreateTerminalCommand(''); // 空命令也允许，通过 IsValid 控制
  Cmd2 := CreateTerminalCommand('\e[?25l', 'hide cursor');
  Outp.ExecuteCommand(Cmd1);
  Outp.ExecuteCommands([IInterface(Cmd1), IInterface(Cmd2)]);
  Outp.ExecuteCommands([Cmd1, Cmd2]);
  // Flush 允许在任何时候调用
  Outp.Flush;
end;

procedure TTestCase_TerminalFacadeBeta.Test_Input_PeekKey_NoCrash_NoConsume;
var Tm: ITerminal;
    Inp: ITerminalInput;
    K: TKeyEvent;
    Has: Boolean;
begin
  Tm := CreateTerminal;
  Inp := Tm.Input;
  Has := Inp.PeekKey(K);
  // 在非交互环境下通常为 False；此处仅要求调用链稳定
  if Has then begin
    // 若确有键存在，后续 TryReadKey 应该能拿到同一个或一个有效键
    AssertTrue('TryReadKey after PeekKey should succeed', Inp.TryReadKey(K));
  end;
  // FlushInput 可随时调用
  Inp.FlushInput;
end;

initialization
  RegisterTest(TTestCase_TerminalFacadeBeta);
end.

