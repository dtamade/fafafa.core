{$CODEPAGE UTF8}
program events_collect_minimal;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, fafafa.core.term;

var
  evBuf: array[0..63] of term_event_t;
  n: SizeUInt;
  i: SizeUInt;
begin
  if not term_init then Halt(1);
  try
    // 建议：进入原始模式 + 启用常用协议（均会自动降级）
    term_raw_mode_enable(True);
    term_focus_enable(True);
    term_paste_bracket_enable(True);
    term_mouse_enable(True);
    term_mouse_sgr_enable(True);

    term_writeln('Collecting events with budget=50ms, buffer size=64. Press ESC to exit.');

    repeat
      n := term_events_collect(evBuf, Length(evBuf), 50);
      for i := 0 to n-1 do
      begin
        case evBuf[i].kind of
          tek_key:
            begin
              // 退出条件：ESC 键
              if evBuf[i].key.key = KEY_ESC then Exit;
            end;
          tek_mouse:
            ; // 这里只演示，不打印
          tek_sizeChange:
            ; // 会被合并到尾部，通常只看到最后一次
          tek_focus, tek_paste:
            ;
        else
          ;
        end;
      end;
      // 渲染/刷新逻辑应在这里执行（本例略过）
    until False;

  finally
    term_mouse_sgr_enable(False);
    term_mouse_enable(False);
    term_paste_bracket_enable(False);
    term_focus_enable(False);
    term_raw_mode_enable(False);
    term_done;
  end;
end.

