program progress_simple_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  fafafa.core.term;

procedure SleepMs(ms: Integer);
begin
  Sleep(ms);
end;

procedure PrintProgress(const Title: string; Percent: Integer);
var W,H: term_size_t; BarLen, Filled: Integer; S: string;
begin
  if not term_size(W, H) then W := 60;
  BarLen := W - 20;
  if BarLen < 10 then BarLen := 10;
  if BarLen > 60 then BarLen := 60;
  if Percent < 0 then Percent := 0 else if Percent > 100 then Percent := 100;
  Filled := (BarLen * Percent) div 100;
  S := StringOfChar('=', Filled) + StringOfChar(' ', BarLen - Filled);
  term_write(Format('%s [%s] %3d%%\r', [Title, S, Percent]));
end;

var i: Integer;
begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  term_writeln('进度条演示，按 Ctrl+C 可中断');
  for i := 0 to 100 do
  begin
    PrintProgress('Processing', i);
    SleepMs(30);
  end;
  term_writeln('');
  term_writeln('完成！');
  term_done;
end.

