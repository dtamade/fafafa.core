program bench_color;
{$APPTYPE CONSOLE}

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.color;

type
  TBenchProc = procedure;

function bench(const name: string; N: Int64; proc: TBenchProc): QWord;
var t0, t1: QWord;
begin
  t0 := GetTickCount64;
  proc();
  t1 := GetTickCount64;
  Writeln(Format('%s: %d iters in %d ms', [name, N, t1 - t0]));
  Result := t1 - t0;
end;

procedure run_bench_srgb(N: Int64);
var i: Int64; c: color_rgba_t; v: Single;
begin
  c := color_rgba(128, 64, 255, 255);
  bench('srgb->linear->srgb', N, procedure begin
    for i := 1 to N do begin
      v := linear_to_srgb(srgb_to_linear(c.r/255.0));
    end;
  end);
end;

procedure run_bench_oklab(N: Int64);
var i: Int64; a,b: color_rgba_t; o: color_rgba_t;
begin
  a := color_rgba(12, 200, 150, 255);
  b := color_rgba(200, 50, 10, 255);
  bench('oklab mix', N, procedure begin
    for i := 1 to N do begin
      o := color_mix_oklab(a, b, 0.37);
    end;
  end);
end;

procedure run_bench_palette(N: Int64);
var i: Int64; pal: array[0..5] of color_rgba_t; o: color_rgba_t;
begin
  pal[0]:=color_rgba(255,0,0,255); pal[1]:=color_rgba(255,128,0,255); pal[2]:=color_rgba(255,255,0,255);
  pal[3]:=color_rgba(0,255,0,255); pal[4]:=color_rgba(0,0,255,255); pal[5]:=color_rgba(128,0,255,255);
  bench('palette multi', N, procedure begin
    for i := 1 to N do begin
      o := palette_sample_multi(pal, Frac(i*0.12345), PIM_OKLAB, True);
    end;
  end);
end;

var N: Int64;
begin
  if ParamCount >= 1 then N := StrToInt64Def(ParamStr(1), 1000000) else N := 1000000;
  Writeln('Running color micro-benchmarks...');
  run_bench_srgb(N);
  run_bench_oklab(N);
  run_bench_palette(N);
end.

