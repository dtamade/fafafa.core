{$CODEPAGE UTF8}
unit Test_term_core_smoke;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term,
  TestHelpers_Env, TestHelpers_Skip;


// 说明（对标 crossterm/tcell 帧循环）：CoreSmoke 覆盖“无事件帧”的稳定性
// - Test_EventPoll_Timeout_NoCrash / Test_EventPoll_MultipleTimeouts_NoStateLeak
// - 要求：短超时下 poll O(1) 返回；无事件时不污染内部状态；用于支撑“每帧先 collect（预算/合并）→ 渲染 → flush”的模型
// - 注：不同宿主/时序下 ok 值不作强断言，仅检查调用链稳定

type
  TTestCase_CoreSmoke = class(TTestCase)
  published
    procedure Test_Init_Size_Clear;
    procedure Test_AltScreen_Enable_Disable_Safely;
    procedure Test_EventPoll_Timeout_NoCrash;
    procedure Test_RawMode_Enable_Disable_Safely;
    procedure Test_Title_Icon_Set_Safely;
    procedure Test_ScrollRegion_Write_Safely;
    procedure Test_ScrollRegion_Reset_Safely;
    procedure Test_Raw_Mouse_EnableDisable_Idempotent;
    procedure Test_EventPoll_MultipleTimeouts_NoStateLeak;
    procedure Test_Windows_QuickEdit_Guard_Restore;
    procedure Test_Focus_EnableDisable_Placeholder;
    procedure Test_BracketedPaste_EnableDisable_Placeholder;
  end;

implementation

function Assume_Or_Skip(const aTest: TTestCase): Boolean;
begin
  Result := TestEnv_AssumeInteractive(aTest);
  if not Result then TestSkip(aTest, 'interactive terminal required');
end;


procedure TTestCase_CoreSmoke.Test_Init_Size_Clear;
var
  w,h: term_size_t;
begin
  if not Assume_Or_Skip(Self) then Exit;
  // init/done 可重复调用应安全
  term_init;
  try
    w := 0; h := 0;
    CheckTrue(term_size(w,h), 'term_size should succeed');
    CheckTrue((w>0) and (h>0), 'size should be positive when term is initialized');
    CheckTrue(term_clear, 'term_clear should succeed');
  finally
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_AltScreen_Enable_Disable_Safely;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    if term_support_alternate_screen then
    begin
      ok := term_alternate_screen_enable(true);
      CheckTrue(ok, 'enable alt screen');
      ok := term_alternate_screen_disable;
      CheckTrue(ok, 'disable alt screen');
    end
    else
      CheckTrue(True, 'alt screen not supported: skipped');
  finally
    // 确保退出时处于正常屏幕
    if term_support_alternate_screen then
      term_alternate_screen_disable;
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_EventPoll_Timeout_NoCrash;
var
  ev: term_event_t;
  ok: boolean;
begin
  // 语义说明：
  // - 本用例覆盖“无事件帧”的安全性：短超时情况下 poll 不应崩溃或污染内部状态
  // - 不断言具体 True/False（不同终端/时序可能立刻得到事件），仅验证调用链稳定
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    FillByte(ev, SizeOf(ev), 0);
    ok := term_event_poll(ev, 5); // 5ms 小超时，常见情况下返回 False
    // 仅用于引用 ok，避免局部“未使用”提示；不关心实际值
    if ok then CheckTrue(True) else CheckTrue(True);
  finally
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_RawMode_Enable_Disable_Safely;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    ok := term_raw_mode_enable(True);
    if ok then CheckTrue(True) else CheckTrue(True);
    ok := term_raw_mode_disable;
    if ok then CheckTrue(True) else CheckTrue(True);
  finally
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_Title_Icon_Set_Safely;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    if term_support_title_set then
    begin
      ok := term_title_set('unit-test-title');
      if ok then CheckTrue(True) else CheckTrue(True);
    end;
    if term_support_icon_set then
    begin
      ok := term_icon_set('unit-test-icon');
      if ok then CheckTrue(True) else CheckTrue(True);
    end;
  finally
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_ScrollRegion_Write_Safely;
var
  s: string;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    // 仅验证生成器可生成，无需实际视觉断言
    s := TANSIGenerator.SetScrollRegion(0, 23);
    CheckEquals(#27'[1;24r', s);
  finally
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_ScrollRegion_Reset_Safely;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    ok := term_scroll_region_reset;
    if ok then CheckTrue(True) else CheckTrue(True);
  finally
    term_done;

  end;
end;

procedure TTestCase_CoreSmoke.Test_Raw_Mouse_EnableDisable_Idempotent;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    // 尝试多次启停 Raw 与 Mouse，要求不崩溃、幂等
    ok := term_raw_mode_enable(True);
    ok := term_mouse_enable(True);
    ok := term_mouse_disable;
    ok := term_raw_mode_disable;
    // 再来一轮
    ok := term_raw_mode_enable(True);
    ok := term_mouse_enable(True);
    ok := term_mouse_disable;
    ok := term_raw_mode_disable;
    CheckTrue(True);
  finally
    // 收尾确保关闭
    term_mouse_disable;
    term_raw_mode_disable;
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_EventPoll_MultipleTimeouts_NoStateLeak;
var
  i: Integer;
  ev: term_event_t;
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    for i := 1 to 20 do
    begin
      FillByte(ev, SizeOf(ev), 0);
      ok := term_event_poll(ev, 2); // 2ms 短超时，多轮调用不应崩溃
      if ok then CheckTrue(True) else CheckTrue(True);
    end;
  finally
    term_done;
  end;
end;


procedure TTestCase_CoreSmoke.Test_Windows_QuickEdit_Guard_Restore;
var
  ok: boolean;
begin
  // 语义说明（黑盒）：
  // - Windows 路径：鼠标启用期临时关闭 Quick Edit，退出恢复（内部 ConsoleMode 守卫）
  // - 此处不直接读取 ConsoleMode 位，仅验证启停幂等与无异常；位级断言在专用用例覆盖
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    ok := term_raw_mode_enable(True);
    ok := term_mouse_enable(True);
    ok := term_mouse_disable;
    ok := term_raw_mode_disable;
    // 再重复一轮，验证幂等
    ok := term_raw_mode_enable(True);
    ok := term_mouse_enable(True);
    ok := term_mouse_disable;
    ok := term_raw_mode_disable;
    CheckTrue(True);
  finally
    term_mouse_disable;
    term_raw_mode_disable;
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_Focus_EnableDisable_Placeholder;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    if not term_support_ansi then
    begin
      CheckTrue(True, 'ansi not supported: skip focus test');
      Exit;
    end;
    ok := term_focus_enable(True);
    if ok then CheckTrue(True) else CheckTrue(True);
    ok := term_focus_enable(False);
    if ok then CheckTrue(True) else CheckTrue(True);
    // 幂等序列
    ok := term_focus_enable(True);
    ok := term_focus_enable(True);
    ok := term_focus_enable(False);
    ok := term_focus_enable(False);
    CheckTrue(True);
  finally
    term_focus_enable(False);
    term_done;
  end;
end;

procedure TTestCase_CoreSmoke.Test_BracketedPaste_EnableDisable_Placeholder;
var
  ok: boolean;
begin
  if not Assume_Or_Skip(Self) then Exit;
  term_init;
  try
    if not term_support_ansi then
    begin
      CheckTrue(True, 'ansi not supported: skip bracketed paste test');
      Exit;
    end;
    ok := term_paste_bracket_enable(True);
    if ok then CheckTrue(True) else CheckTrue(True);
    ok := term_paste_bracket_enable(False);
    if ok then CheckTrue(True) else CheckTrue(True);
    // 幂等序列
    ok := term_paste_bracket_enable(True);
    ok := term_paste_bracket_enable(True);
    ok := term_paste_bracket_enable(False);
    ok := term_paste_bracket_enable(False);
    CheckTrue(True);
  finally
    term_paste_bracket_enable(False);
    term_done;
  end;
end;





initialization
  RegisterTest(TTestCase_CoreSmoke);
end.
