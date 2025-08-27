{$CODEPAGE UTF8}
unit Test_term_best_practices_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.env,
  fafafa.core.term,
  TestHelpers_Env, TestHelpers_Skip;

Type
  TBestPractice_Env_Color_Cap = class(TTestCase)
  published
    procedure Test_ColorEnvMatrix_NO_COLOR_CLICOLOR_COLORTERM_TERM;
    procedure Test_Capabilities_Mouse_Focus_Paste_Bits;
  end;

  TBestPractice_Params_Events = class(TTestCase)
  published
    procedure Test_Move_Coalesce_Parametric;
  end;

  TBestPractice_Output_CursorState = class(TTestCase)
  private
    FStream: TMemoryStream;
    FOut: ITerminalOutput;
    function ContentSize: Integer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_CursorVisible_NoDuplicate;
  end;

implementation

procedure TBestPractice_Env_Color_Cap.Test_ColorEnvMatrix_NO_COLOR_CLICOLOR_COLORTERM_TERM;
var
  gNo, gCli, gForce, gCT, gTerm: TEnvOverrideGuard;
  Info: ITerminalInfo;
  depth: Integer;
begin
  // NO_COLOR -> 全禁彩
  gNo := env_override('NO_COLOR', '1');
  try
    Info := TTerminalInfo.Create;
    AssertFalse('NO_COLOR 应关闭彩色', Info.SupportsColor);
    AssertEquals('NO_COLOR 应使色深为0', 0, Info.GetColorDepth);
  finally
    gNo.Done;
  end;

  // CLICOLOR=0 -> 禁彩
  gCli := env_override('CLICOLOR', '0');
  try
    Info := TTerminalInfo.Create;
    AssertFalse('CLICOLOR=0 应关闭彩色', Info.SupportsColor);
    AssertEquals('CLICOLOR=0 色深为0', 0, Info.GetColorDepth);
  finally
    gCli.Done;
  end;

  // CLICOLOR_FORCE=1 + COLORTERM=truecolor -> 强制彩色且位深24
  gForce := env_override('CLICOLOR_FORCE', '1');
  gCT := env_override('COLORTERM', 'truecolor');
  try
    Info := TTerminalInfo.Create;
    AssertTrue('CLICOLOR_FORCE=1 应开启彩色', Info.SupportsColor);
    depth := Info.GetColorDepth;
    AssertEquals('truecolor 应为24位', 24, depth);
  finally
    gCT.Done; gForce.Done;
  end;

  // CLICOLOR_FORCE=1 + TERM=xterm-256color -> 至少 8（256色）
  gForce := env_override('CLICOLOR_FORCE', '1');
  gTerm := env_override('TERM', 'xterm-256color');
  try
    Info := TTerminalInfo.Create;
    AssertTrue('CLICOLOR_FORCE=1 应开启彩色', Info.SupportsColor);
    depth := Info.GetColorDepth;
    AssertTrue('xterm-256color 应至少为8位', depth >= 8);
  finally
    gTerm.Done; gForce.Done;
  end;
end;

procedure TBestPractice_Env_Color_Cap.Test_Capabilities_Mouse_Focus_Paste_Bits;
var
  Info: ITerminalInfo;
  caps: TTerminalCapabilities;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    Info := TTerminalInfo.Create;
    caps := Info.GetCapabilities;
    // 若细粒度位存在，应包含总类位
    if (tcapMouseSGR in caps) or (tcapMouseBasic in caps) or (tcapMouseDrag in caps) or (tcapMouseUrxvt in caps) then
      AssertTrue('存在鼠标子能力时应包含 tcapMouse', tcapMouse in caps);
    // Focus/Paste 需要 ANSI 支持
    if (tcapFocus in caps) or (tcapBracketedPaste in caps) then
      AssertTrue('Focus/Paste 需要 ANSI', tcapANSI in caps);
    // 只要能调用即通过（环境差异导致的为空集合也允许）
    AssertTrue(True);
  finally
    term_done;
  end;
end;

procedure TBestPractice_Params_Events.Test_Move_Coalesce_Parametric;
var
  g0, g1: TEnvOverrideGuard;
begin
  if not TestEnv_AssumeInteractive(Self) then Exit;
  // 关闭合并
  g0 := env_override('FAFAFA_TERM_COALESCE_MOVE', '0');
  try
    term_init; try
      AssertFalse('关闭合并后应为 False', term_get_coalesce_move);
    finally term_done; end;
  finally g0.Done; end;
  // 开启合并
  g1 := env_override('FAFAFA_TERM_COALESCE_MOVE', '1');
  try
    term_init; try
      AssertTrue('开启合并后应为 True', term_get_coalesce_move);
    finally term_done; end;
  finally g1.Done; end;
end;

procedure TBestPractice_Output_CursorState.SetUp;
begin
  inherited SetUp;
  FStream := TMemoryStream.Create;
  FOut := TTerminalOutput.Create(FStream, False);
end;

procedure TBestPractice_Output_CursorState.TearDown;
begin
  FOut := nil;
  FStream.Free;
  inherited TearDown;
end;

function TBestPractice_Output_CursorState.ContentSize: Integer;
begin
  Result := FStream.Size;
end;

procedure TBestPractice_Output_CursorState.Test_CursorVisible_NoDuplicate;
var
  s1, s2, s3, s4: Integer;
begin
  // Show → Show 抑制重复
  FOut.ShowCursor; s1 := ContentSize;
  FOut.ShowCursor; s2 := ContentSize;
  AssertEquals('重复 ShowCursor 不应追加输出', s1, s2);
  // Hide → Hide 抑制重复
  FOut.HideCursor; s3 := ContentSize;
  FOut.HideCursor; s4 := ContentSize;
  AssertEquals('重复 HideCursor 不应追加输出', s3, s4);
end;

initialization
  RegisterTest(TBestPractice_Env_Color_Cap);
  RegisterTest(TBestPractice_Params_Events);
  RegisterTest(TBestPractice_Output_CursorState);

end.

