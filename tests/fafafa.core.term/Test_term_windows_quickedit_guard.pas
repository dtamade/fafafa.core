{$CODEPAGE UTF8}
unit Test_term_windows_quickedit_guard;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.term, TestHelpers_Env, TestHelpers_Skip
  {$IFDEF MSWINDOWS}, Windows{$ENDIF}
  ;

// 覆盖范围说明（对标 crossterm/tcell 的模式守卫语义）：
// - 幂等：重复 enable/disable 不应翻转无关位（见 Test_MouseEnableDisable_Idempotent）
// - 嵌套：多次启用/关闭恢复顺序（见 Test_MouseEnable_Nested_Restore_Order / Test_ModeGuard_Nested_Restore_Order）
// - 异常路径：try/finally 保证恢复原始 ConsoleMode（见 Test_MouseEnable_ExceptionPath_Restores / Test_ModeGuard_ExceptionPath_Restores）
// - 组合：Guard + 鼠标 Drag/SGR/Focus/Paste 组合场景位级断言（见 Test_ModeGuard_MultiFlags_Mouse_Focus_Paste / With_Drag_Restore）
// - 降级：非 Windows 平台条件跳过；Win 上若启用失败则视为 no-op 并保持幂等


type
  TTestCase_Windows_QuickEditGuard = class(TTestCase)
  published
    procedure Test_MouseEnabled_Temporarily_Disables_QuickEdit; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_MouseEnableDisable_Idempotent; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_MouseToggle_Restores_Original_Mode; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_MouseEnable_Nested_Restore_Order; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_MouseEnable_ExceptionPath_Restores; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_ModeGuard_Nested_Restore_Order; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_ModeGuard_ExceptionPath_Restores; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_ModeGuard_MultiFlags_Mouse_Focus_Paste; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
    procedure Test_ModeGuard_With_Drag_Restore; {$IFNDEF MSWINDOWS} inline; {$ENDIF}
  end;

implementation

{$IFDEF MSWINDOWS}
function GetInputMode(h: THandle): DWORD;
var m: DWORD;
begin
  if GetConsoleMode(h, m) then Exit(m) else Exit(0);
end;
{$ENDIF}

procedure TTestCase_Windows_QuickEditGuard.Test_MouseEnabled_Temporarily_Disables_QuickEdit;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, duringMode, afterMode: DWORD;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    // 说明：
    // - beforeMode 记录原始输入模式
    // - 启用鼠标后（during），应打开 ENABLE_MOUSE_INPUT，并临时清除 Quick Edit 位
    // - 关闭鼠标后（after），应恢复到 beforeMode
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    term_mouse_enable(True);
    duringMode := GetInputMode(hIn);

    term_mouse_enable(False);
    afterMode := GetInputMode(hIn);

    fpcunit.TAssert.AssertTrue('during should enable mouse input', (duringMode and ENABLE_MOUSE_INPUT) <> 0);
    {$IFDEF MSWINDOWS}
    // during 期间 Quick Edit 应被清除（若存在该位）
    fpcunit.TAssert.AssertTrue('during should clear quick edit', (duringMode and ENABLE_QUICK_EDIT_MODE) = 0);
    {$ENDIF}
    fpcunit.TAssert.AssertEquals('after restore input mode', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  // 非 Windows 平台跳过
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

procedure TTestCase_Windows_QuickEditGuard.Test_MouseEnableDisable_Idempotent;
{$IFDEF MSWINDOWS}
var beforeMode, m1, m2: DWORD; hIn: THandle;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);
    term_mouse_enable(True);
    m1 := GetInputMode(hIn);
    term_mouse_enable(True);
    m2 := GetInputMode(hIn);
    fpcunit.TAssert.AssertEquals('idempotent enable should not flip unrelated bits', m1, m2);
    term_mouse_enable(False);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

procedure TTestCase_Windows_QuickEditGuard.Test_MouseToggle_Restores_Original_Mode;
{$IFDEF MSWINDOWS}
var beforeMode, afterMode: DWORD; hIn: THandle;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);
    term_mouse_enable(True);
    term_mouse_enable(False);
    afterMode := GetInputMode(hIn);
    fpcunit.TAssert.AssertEquals('toggle should restore original console mode', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

procedure TTestCase_Windows_QuickEditGuard.Test_MouseEnable_Nested_Restore_Order;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, midMode, afterMode: DWORD;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    // 嵌套启用两次
    term_mouse_enable(True);
    term_mouse_enable(True);
    midMode := GetInputMode(hIn);

    // 依次关闭
    term_mouse_enable(False);
    term_mouse_enable(False);
    afterMode := GetInputMode(hIn);

    // 中间应处于启用（含 MOUSE 输入，且 Quick Edit 被清）
    fpcunit.TAssert.AssertTrue('mid should enable mouse input', (midMode and ENABLE_MOUSE_INPUT) <> 0);
    fpcunit.TAssert.AssertTrue('mid should clear quick edit', (midMode and ENABLE_QUICK_EDIT_MODE) = 0);
    // 最终恢复初值
    fpcunit.TAssert.AssertEquals('nested restore should match before', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

procedure TTestCase_Windows_QuickEditGuard.Test_MouseEnable_ExceptionPath_Restores;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, afterMode: DWORD;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    try
      try
        term_mouse_enable(True);
        // 模拟异常
        raise Exception.Create('boom');
      finally
        term_mouse_enable(False);
      end;
    except
      on E: Exception do ; // 吞掉异常，仅用于测试恢复路径
    end;

    afterMode := GetInputMode(hIn);
    fpcunit.TAssert.AssertEquals('exception path should restore before mode', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;


procedure TTestCase_Windows_QuickEditGuard.Test_ModeGuard_Nested_Restore_Order;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, midMode, afterMode: DWORD; g1, g2: TTermModeGuard;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    g1 := term_mode_guard_acquire_current([tm_mouse_enable_base]);
    g2 := term_mode_guard_acquire_current([tm_mouse_enable_base]);
    midMode := GetInputMode(hIn);

    term_mode_guard_done(g2);
    term_mode_guard_done(g1);
    afterMode := GetInputMode(hIn);

    fpcunit.TAssert.AssertTrue('mid should enable mouse input', (midMode and ENABLE_MOUSE_INPUT) <> 0);
    fpcunit.TAssert.AssertTrue('mid should clear quick edit', (midMode and ENABLE_QUICK_EDIT_MODE) = 0);
    fpcunit.TAssert.AssertEquals('guard nested restore', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

procedure TTestCase_Windows_QuickEditGuard.Test_ModeGuard_ExceptionPath_Restores;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, afterMode: DWORD; g: TTermModeGuard;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    try
      try
        g := term_mode_guard_acquire_current([tm_mouse_enable_base]);
        raise Exception.Create('boom');
      finally
        term_mode_guard_done(g);
      end;
    except on E: Exception do ; end;

    afterMode := GetInputMode(hIn);
    fpcunit.TAssert.AssertEquals('guard exception restore', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}

  end;

procedure TTestCase_Windows_QuickEditGuard.Test_ModeGuard_MultiFlags_Mouse_Focus_Paste;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, midMode, afterMode: DWORD; g: TTermModeGuard;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_sgr_1006, tm_focus_1004, tm_paste_2004]);
    midMode := GetInputMode(hIn);
    term_mode_guard_done(g);
    afterMode := GetInputMode(hIn);

    // 仅断言与 ConsoleMode 相关的位（Mouse 与 QuickEdit），focus/paste/1006 在 Win 控制台不改变 ConsoleMode
    fpcunit.TAssert.AssertTrue('mid should enable mouse input', (midMode and ENABLE_MOUSE_INPUT) <> 0);
    fpcunit.TAssert.AssertTrue('mid should clear quick edit', (midMode and ENABLE_QUICK_EDIT_MODE) = 0);
    fpcunit.TAssert.AssertEquals('multi-flags restore', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;


procedure TTestCase_Windows_QuickEditGuard.Test_ModeGuard_With_Drag_Restore;
{$IFDEF MSWINDOWS}
var hIn: THandle; beforeMode, midMode, afterMode: DWORD; g: TTermModeGuard;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  term_init;
  try
    hIn := GetStdHandle(STD_INPUT_HANDLE);
    beforeMode := GetInputMode(hIn);

    g := term_mode_guard_acquire_current([tm_mouse_enable_base, tm_mouse_button_drag]);
    midMode := GetInputMode(hIn);
    term_mode_guard_done(g);
    afterMode := GetInputMode(hIn);

    fpcunit.TAssert.AssertTrue('mid should enable mouse input', (midMode and ENABLE_MOUSE_INPUT) <> 0);
    fpcunit.TAssert.AssertTrue('mid should clear quick edit', (midMode and ENABLE_QUICK_EDIT_MODE) = 0);
    fpcunit.TAssert.AssertEquals('drag combo restore', beforeMode, afterMode);
  finally
    term_done;
  end;
  {$ELSE}
  fpcunit.TAssert.AssertTrue('skip on non-windows', True);
  {$ENDIF}
end;

initialization
  RegisterTest(TTestCase_Windows_QuickEditGuard);
end.
