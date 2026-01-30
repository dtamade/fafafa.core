program mini_menu_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

const
  ITEMS: array[0..12] of string = (
    '基础: clean_demo',
    '基础: final_demo',
    '基础: basic_test',
    'Unicode 测试 (unicode_test)',
    '调色板 (palette_demo)',
    '渐变演示 (gradient_demo)',
    '键盘输入 (keyboard_input_demo)',
    '鼠标输入 (mouse_input_demo)',
    '进度条 (progress_simple_demo)',
    '自适应布局 (resize_layout_demo)',
    '备用屏 (alt_screen_demo)',
    '能力自检 (capability_demo)',
    '退出'
  );

var
  filterText: string = '';
  filteredIdx: array of Integer;

procedure RebuildFiltered;
var i, n: Integer; pat, s: string;
begin
  pat := LowerCase(filterText);
  n := 0;
  // 预计算容量：最多等于 ITEMS 数量
  SetLength(filteredIdx, Length(ITEMS));
  for i := Low(ITEMS) to High(ITEMS) do
  begin
    s := LowerCase(ITEMS[i]);
    if (pat = '') or (Pos(pat, s) > 0) then
    begin
      filteredIdx[n] := i;
      Inc(n);
    end;
  end;
  SetLength(filteredIdx, n);
end;

function FilteredCount: Integer; inline;
begin
  Result := Length(filteredIdx);
end;


procedure DrawHeader(const width: Integer);
var bar: string;
    w: Integer;
begin
  if width < 0 then w := 0 else w := width;
  bar := StringOfChar(' ', w);
  term_cursor_home;
  term_attr_background_set(term_color_24bit_gray(40));
  term_attr_foreground_set(term_color_24bit_rgb(255,255,255));
  term_write(bar);
  term_cursor_home;
  term_write('  迷你菜单 (↑/↓/Home/End/PgUp/PgDn 导航, Enter 运行, q 退出)  |  搜索: ' + filterText);
  term_attr_reset;
end;

procedure DrawFooter(const width, sel, total: Integer);
var w, h: term_size_t;
    text, bar: string;
    y: term_size_t;
    pageInfo: string;
    displayTotal: Integer;
begin
  if not term_size(w, h) then Exit;
  pageInfo := Format('筛选后: %d 条', [total]);
  displayTotal := total;
  if displayTotal < 1 then displayTotal := 1;
  text := Format(' %d/%d  Enter运行  q退出  |  %s ', [sel+1, displayTotal, pageInfo]);
  if width > 0 then
    bar := StringOfChar(' ', width)
  else
    bar := StringOfChar(' ', w);
  if h > 0 then y := h-1 else y := 0;
  term_attr_background_set(term_color_24bit_gray(40));
  term_attr_foreground_set(term_color_24bit_rgb(255,255,255));
  term_cursor_line(y);
  term_cursor_col(0);
  term_write(bar);
  term_cursor_line(y);
  term_cursor_col(0);
  term_write(text);
  term_attr_reset;
end;

var
  cur: Integer;
  r: Integer;


function ExecExample(const name: string): Integer;
var
  exePath: string;
  base: string;
begin
  // 使用可执行所在目录作为基准，确保可跨目录调用
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
{$IFDEF WINDOWS}
  exePath := base + name + '.exe';
{$ELSE}
  exePath := base + name; // 需具备执行权限
{$ENDIF}
  try
    Result := ExecuteProcess(exePath, '');
  except
    on E: Exception do
    begin
      term_writeln('执行失败: ' + E.Message);
      Result := -1;
    end;
  end;
end;


procedure DrawMenu(sel: Integer);
var i, cnt: Integer;
    w, h: term_size_t;
    idx: Integer;
begin
  term_clear;
  if not term_size(w, h) then begin w := 80; h := 24; end;
  DrawHeader(w);
  term_cursor_line(1);
  cnt := FilteredCount;
  if cnt = 0 then
  begin
    term_writeln('（无匹配项）');
  end
  else
  begin
    for i := 0 to cnt-1 do
    begin
      idx := filteredIdx[i];
      if i = sel then
      begin
        term_attr_background_set(term_color_24bit_gray(64));
        term_attr_foreground_set(term_color_24bit_rgb(255,255,255));
        term_writeln('> ' + ITEMS[idx]);
        term_attr_reset;
      end
      else
        term_writeln('  ' + ITEMS[idx]);
    end;
  end;
  DrawFooter(w, sel, cnt);
end;

function RunOnce(sel: Integer): Integer;
var E: term_event_t; cnt: Integer; ch: Char;
begin
  Result := sel;
  if term_event_poll(E, 200) then
  begin
    case E.kind of
      tek_key:
        begin
          cnt := FilteredCount;
          case E.key.key of
            KEY_UP:        if Result > 0 then Dec(Result);
            KEY_DOWN:      begin if (cnt-1) >= 0 then if Result < (cnt-1) then Inc(Result); end;
            KEY_HOME:      Result := 0;
            KEY_END:       begin if cnt-1 < 0 then Result := 0 else Result := (cnt-1); end;
            KEY_PAGE_UP:   begin if Result - 5 < 0 then Result := 0 else Dec(Result, 5); end;
            KEY_PAGE_DOWN: begin
                              if cnt-1 < 0 then Result := 0
                              else
                              begin
                                if Result + 5 > (cnt-1) then Result := (cnt-1) else Inc(Result, 5);
                              end;
                            end;
            KEY_BACKSPACE:
              begin
                if Length(filterText) > 0 then
                begin
                  Delete(filterText, Length(filterText), 1);
                  RebuildFiltered;
                  if Result >= FilteredCount then
                  begin
                    if FilteredCount-1 < 0 then Result := 0 else Result := FilteredCount-1;
                  end;
                  DrawMenu(Result);
                end;
              end;
            KEY_ESC:
              begin
                if filterText <> '' then
                begin
                  filterText := '';
                  RebuildFiltered;
                  Result := 0;
                  DrawMenu(Result);
                end
                else
                  Exit(-2);
              end;
            KEY_ENTER:
              begin
                Exit(-1);
              end;
          else
            if (E.key.char.char <> #0) then
            begin
              ch := E.key.char.char;
              if ch >= #32 then // 可见字符，加入过滤
              begin
                filterText := filterText + ch;
                RebuildFiltered;
                Result := 0;
                DrawMenu(Result);
              end;
            end;
          end;
        end;
      tek_sizeChange:
        begin
          // 重绘以适配新尺寸
          DrawMenu(Result);
        end;
    else ;
    end;
  end;
end;

function NameByIndex(idx: Integer): string;
begin
  case idx of
    0: Result := 'clean_demo';
    1: Result := 'final_demo';
    2: Result := 'basic_test';
    3: Result := 'unicode_test';
    4: Result := 'palette_demo';
    5: Result := 'gradient_demo';
    6: Result := 'keyboard_input_demo';
    7: Result := 'mouse_input_demo';
    8: Result := 'progress_simple_demo';
    9: Result := 'resize_layout_demo';
    10: Result := 'alt_screen_demo';
    11: Result := 'capability_demo';
  else
    Result := '';
  end;
end;



procedure TryLaunch(sel: Integer);
var nm: string; idx: Integer;
begin
  if (sel < 0) or (sel >= FilteredCount) then Exit;
  idx := filteredIdx[sel];
  nm := NameByIndex(idx);
  if nm <> '' then
  begin
    term_writeln('启动示例: ' + nm);
    term_attr_reset;
    ExecExample(nm);
    DrawMenu(sel);
  end;
end;

begin
  if not term_init then
  begin
    WriteLn('term_init 失败'); Halt(1);
  end;

  RebuildFiltered;
  cur := 0;
  DrawMenu(cur);
  while True do
  begin
    r := RunOnce(cur);
    if r = -1 then
    begin
      if FilteredCount = 0 then Continue;
      if (cur >= 0) and (cur < FilteredCount) and (filteredIdx[cur] = High(ITEMS)) then begin term_writeln('退出'); term_done; Halt(0); end;
      TryLaunch(cur);
      Continue;
    end;
    if r = -2 then begin term_writeln('退出'); term_done; Halt(0); end;
    if r <> cur then begin cur := r; DrawMenu(cur); end;
  end;

  term_writeln('选择：' + ITEMS[cur]);
  term_writeln('按回车退出');
  ReadLn;
  term_done;
end.

