program gradient_demo;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

function clamp(v, lo, hi: Integer): Integer;
begin
  if v < lo then Exit(lo);
  if v > hi then Exit(hi);
  Result := v;
end;

procedure HGrad;
var i: Integer;
begin
  term_writeln('水平渐变:');
  for i := 0 to 63 do
  begin
    term_attr_foreground_set(term_color_24bit_rgb(clamp(255 - i*4,0,255), clamp(i*4,0,255), 128));
    term_write('█');
  end;
  term_attr_reset; term_writeln('');
end;

procedure VGrad;
var i: Integer;
begin
  term_writeln('垂直渐变:');
  for i := 0 to 20 do
  begin
    term_attr_foreground_set(term_color_24bit_rgb(clamp(i*12,0,240), 80, clamp(255 - i*10,0,255)));
    term_writeln('████████████████████████████████████████████████████████████');
  end;
  term_attr_reset;
end;

begin
  if not term_init then
  begin
    WriteLn('term_init 失败');
    Halt(1);
  end;

  HGrad;
  VGrad;

  term_attr_reset;
  term_writeln('完成');
  term_done;
end.

