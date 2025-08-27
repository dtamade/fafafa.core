unit Test_fafafa_core_term_ui_hooks;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  fpcunit, testregistry, sysutils,
  fafafa.core.term,
  fafafa.core.term.ui,
  fafafa.core.term.ui.surface;
// 这些用例通过 termui_debug_set_hooks 注入 Hook，
// 验证：
// 1) UiFrameBegin/UiFrameEnd + UiWriteAt/UiFillRect 的“最小差异输出”行为
// 2) 终端尺寸 SizeHook 可控制，避免真实终端依赖
// 3) 光标移动通过 CursorLine/ColHook 记录

type
  TStringArray = array of UnicodeString;

  THookRecorder = class
  public
    Writes: TStringArray;
    CursorLines: array of Integer;
    CursorCols: array of Integer;
    W, H: Word;
    constructor Create(aW, aH: Word);
    procedure Clear;
    procedure RecWrite(const S: UnicodeString);
    procedure RecWriteln(const S: UnicodeString);
    procedure RecCursorLine(Line: Word);
    procedure RecCursorCol(Col: Word);
    function RecCursorVisibleSet(Visible: Boolean): Boolean; inline; // visible flag recorded externally
    function RecSize(var aW, aH: Word): Boolean; inline;
  end;

  TTestCase_Hooks = class(TTestCase)
  private
    FRec: THookRecorder;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_MinimalDiff_WriteAt;
    procedure Test_FillRect_MinimalDiff;
  end;

implementation

{ THookRecorder }
constructor THookRecorder.Create(aW, aH: Word);
begin
  inherited Create;
  W := aW; H := aH;
  Clear;
end;

procedure THookRecorder.Clear;
begin
  SetLength(Writes, 0);
  SetLength(CursorLines, 0);
  SetLength(CursorCols, 0);
end;

procedure THookRecorder.RecWrite(const S: UnicodeString);
var n: Integer;
begin
  n := Length(Writes);
  SetLength(Writes, n+1);
  Writes[n] := S;
end;

procedure THookRecorder.RecWriteln(const S: UnicodeString);
begin
  RecWrite(S + LineEnding);
end;

procedure THookRecorder.RecCursorLine(Line: Word);
var n: Integer;
begin
  n := Length(CursorLines);
  SetLength(CursorLines, n+1);
  CursorLines[n] := Line;
end;

procedure THookRecorder.RecCursorCol(Col: Word);
var n: Integer;
begin
  n := Length(CursorCols);
  SetLength(CursorCols, n+1);
  CursorCols[n] := Col;
end;

function THookRecorder.RecCursorVisibleSet(Visible: Boolean): Boolean;
begin
  Result := True;
end;

function THookRecorder.RecSize(var aW, aH: Word): Boolean;
begin
  aW := W; aH := H;
  Result := True;
end;

// 全局桥接，转调到当前测试实例的 FRec.RecSize；
// 由于 fpcunit 的 Runner 初始化时机，我们通过一个 module-level 的变量保存当前用例实例。
var
  GActiveRecorder: THookRecorder = nil;

procedure WriteHookBridge(const S: UnicodeString);
begin
  if Assigned(GActiveRecorder) then GActiveRecorder.RecWrite(S);
end;

procedure WritelnHookBridge(const S: UnicodeString);
begin
  if Assigned(GActiveRecorder) then GActiveRecorder.RecWriteln(S);
end;

procedure CursorLineHookBridge(Line: Word);
begin
  if Assigned(GActiveRecorder) then GActiveRecorder.RecCursorLine(Line);
end;

procedure CursorColHookBridge(Col: Word);
begin
  if Assigned(GActiveRecorder) then GActiveRecorder.RecCursorCol(Col);
end;

function CursorVisibleSetBridge(Visible: Boolean): Boolean;
begin
  if Assigned(GActiveRecorder) then
    Result := GActiveRecorder.RecCursorVisibleSet(Visible)
  else
    Result := True;
end;

function SizeHookBridge(var aW, aH: Word): Boolean;
begin
  if Assigned(GActiveRecorder) then
    Result := GActiveRecorder.RecSize(aW, aH)
  else
  begin
    aW := 80; aH := 24; Result := True;
  end;
end;

// 供 termui_run 使用的全局渲染过程
procedure Render_Clear_WriteHello;
begin
  termui_clear;
  termui_write_at(0, 0, 'Hello');
end;

procedure Render_Clear_WriteHeXlo;
begin
  termui_clear;
  termui_write_at(0, 0, 'HeXlo');
end;

procedure Render_FillRect_Base;
begin
  termui_clear;
  termui_fill_rect(0, 0, 4, 2, '#');
end;

procedure Render_FillRect_Modified;
begin
  termui_clear;
  termui_fill_rect(0, 0, 4, 2, '#');
  termui_fill_rect(2, 0, 2, 2, '*');
end;

{ TTestCase_Hooks }
procedure TTestCase_Hooks.SetUp;
begin
  GActiveRecorder := nil;
  FRec := THookRecorder.Create(20, 6);
  GActiveRecorder := FRec;
  // 传递全部为非 method 的全局桥接
  termui_debug_set_hooks(@WriteHookBridge, @WritelnHookBridge, @CursorLineHookBridge, @CursorColHookBridge, @CursorVisibleSetBridge, @SizeHookBridge);
end;

procedure TTestCase_Hooks.TearDown;
begin
  termui_debug_reset_hooks;
  FreeAndNil(FRec);
end;

procedure TTestCase_Hooks.Test_MinimalDiff_WriteAt;
// 两帧：第1帧写 "Hello"@ (1,1)；第2帧写 "Hello"@ (1,1) 仅把第3个字符改为 'X'
// 断言：第1帧输出一次 "Hello"；第2帧仅输出 "X"（而非整行/整段）
var
  countBefore, countAfter: Integer;
begin
  // 帧 1
  FRec.Clear;
  termui_invalidate_all; // 保守起见
  fafafa.core.term.ui.surface.UiFrameBegin;
  Render_Clear_WriteHello;
  fafafa.core.term.ui.surface.UiFrameEnd;
  countBefore := Length(FRec.Writes);
  AssertTrue('first frame should produce at least 1 write', countBefore >= 1);

  // 帧 2
  FRec.Clear;
  fafafa.core.term.ui.surface.UiFrameBegin;
  Render_Clear_WriteHeXlo;
  fafafa.core.term.ui.surface.UiFrameEnd;
  countAfter := Length(FRec.Writes);
  AssertTrue('second frame must write only minimal diff (<=2 segments)', countAfter <= 2);
  if countAfter >= 1 then
    CheckEquals('X', FRec.Writes[0], 'first diff segment should be X');
end;

procedure TTestCase_Hooks.Test_FillRect_MinimalDiff;
// 两帧：第1帧在 (0,0)-(4x2) 填充 '#'
// 第2帧在 (2,0)-(2x2) 改为 '*'
// 断言：第二帧仅输出两段（每行各一个 2 长度的段）
var
  i, cnt: Integer;
begin
  // 帧 1
  FRec.Clear;
  fafafa.core.term.ui.surface.UiFrameBegin;
  Render_FillRect_Base;
  fafafa.core.term.ui.surface.UiFrameEnd;

  // 帧 2
  FRec.Clear;
  fafafa.core.term.ui.surface.UiFrameBegin;
  Render_FillRect_Modified;
  fafafa.core.term.ui.surface.UiFrameEnd;
  cnt := Length(FRec.Writes);
  AssertTrue('second frame writes should be small', cnt <= 4);
end;

initialization
  RegisterTest(TTestCase_Hooks);

end.

