{$CODEPAGE UTF8}
program benchmark_paste_backends;

{$mode objfpc}{$H+}

uses
  SysUtils, DateUtils,
  {$IFDEF MSWINDOWS}Windows{$ENDIF},
  fafafa.core.term;

procedure Bench(const backend: string; N: Integer; keepLast: SizeUInt; maxBytes: SizeUInt);
var
  i: Integer;
  t0, t1: TDateTime;
  dur_ms: Int64;
begin
  {$IFDEF MSWINDOWS}
  Windows.SetEnvironmentVariable('FAFAFA_TERM_PASTE_BACKEND', PChar(backend));
  {$ELSE}
  fpSetEnv(PChar('FAFAFA_TERM_PASTE_BACKEND='+backend));
  {$ENDIF}
  term_paste_clear_all;
  term_paste_set_auto_keep_last(keepLast);
  term_paste_set_max_bytes(maxBytes);

  t0 := Now;
  for i := 1 to N do
    term_paste_store_text('abcdefg');
  t1 := Now;
  dur_ms := MilliSecondsBetween(t1, t0);
  WriteLn(backend, ': append x', N, ' in ', dur_ms, ' ms; count=', term_paste_get_count, ' total=', term_paste_get_total_bytes);

  // trim keep last
  t0 := Now;
  term_paste_trim_keep_last(keepLast);
  t1 := Now;
  dur_ms := MilliSecondsBetween(t1, t0);
  WriteLn(backend, ': trim_keep_last(', keepLast, ') in ', dur_ms, ' ms; count=', term_paste_get_count, ' total=', term_paste_get_total_bytes);
end;

var
  N: Integer = 200000;
begin
  if ParamCount >= 1 then N := StrToIntDef(ParamStr(1), N);
  WriteLn('Benchmark paste backends with N=', N);

  // legacy
  Bench('', N, 0, 0);
  // ring
  Bench('ring', N, 0, 0);
  Bench('ring', N, 128, 1 shl 20);
end.

