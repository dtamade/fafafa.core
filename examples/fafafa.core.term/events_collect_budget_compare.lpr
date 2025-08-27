{$CODEPAGE UTF8}
program events_collect_budget_compare;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.term;

var
  evs: array[0..63] of term_event_t;
  n: SizeUInt;
  running: Boolean = True;
  frame: Integer = 0;

procedure PrintHelp;
begin
  term_writeln('events_collect_budget_compare');
  term_writeln('------------------------------------------');
  term_writeln('ESC: quit');
  term_writeln('b: toggle budget mode (0ms vs 8ms)');
  term_writeln('h: print this help');
  term_writeln('');
end;

function IsEscKey(const E: term_event_t): Boolean;
begin
  Result := (E.kind = tek_key) and (E.key.key = KEY_ESC);
end;

function IsCharKey(const E: term_event_t; const C: WideChar): Boolean;
var
  isUnknown: Boolean;
  isMatch: Boolean;
begin
  isUnknown := (E.kind = tek_key) and (E.key.key = KEY_UNKOWN);
  if not isUnknown then Exit(False);
  // 兼容 AnsiChar 与 WideChar 两种存储
  isMatch := (E.key.char.wchar = C) or (E.key.char.char = AnsiChar(C));
  Result := isMatch;
end;

var
  budgetMs: UInt32 = 0; // start with 0ms (consume queue only)
  lastModeNote: QWord = 0;
  i: Integer;

begin
  term_init;
  try
    term_alternate_screen_enable(True);
    term_focus_enable(True);
    term_paste_bracket_enable(True);
    term_mouse_enable(True);
    PrintHelp;

    while running do
    begin
      // 切换模式时提示
      if GetTickCount64 - lastModeNote > 1000 then
      begin
        term_writeln(Format('[mode] budget=%d ms (press b to toggle)', [budgetMs]));
        lastModeNote := GetTickCount64;
      end;

      // budget: 0 vs 8（示范 move/resize 的合并与 pull 行为差异）
      n := term_events_collect(evs, Length(evs), budgetMs);

      // 处理事件
      for i := 0 to n - 1 do
      begin
        if IsEscKey(evs[i]) then
        begin
          running := False;
          Break;
        end
        else if IsCharKey(evs[i], 'b') then
        begin
          if budgetMs = 0 then budgetMs := 8 else budgetMs := 0;
          lastModeNote := 0; // 促使立即输出模式提示
        end
        else if IsCharKey(evs[i], 'h') then
          PrintHelp;
      end;

      // 简易帧标记（可观察在不同 budget 下的节奏差异）
      Inc(frame);
      if (frame mod 30) = 0 then
      begin
        term_writeln(Format('[frame=%d] collected=%d', [frame, Integer(n)]));
      end;

      // 轻微让出 CPU（演示用）
      Sleep(10);
    end;

    // 退出提示
    term_writeln('bye');
  finally
    term_mouse_enable(False);
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_alternate_screen_enable(False);
    term_done;
  end;
end.

