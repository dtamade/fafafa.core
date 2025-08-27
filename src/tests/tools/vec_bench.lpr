program vec_bench;

{$mode objfpc}{$H+}
{$I ../../fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.vec;

function BenchPushInt(const aName: string; aCount: SizeUInt; aAligned: Boolean): QWord;
var
  i: SizeUInt;
  t0, t1: QWord;
  v: specialize TVec<Integer>;
begin
  v := specialize TVec<Integer>.Create;
  try
    if aAligned then
      v.EnableAlignedGrowth(64);
    t0 := GetTickCount64;
    for i := 0 to aCount - 1 do
      v.Push(Integer(i));
    t1 := GetTickCount64;

    Writeln(Format('%s: count=%d capacity=%d elapsed_ms=%d',
      [aName, v.Count, v.Capacity, t1 - t0]));
    Result := t1 - t0;
  finally
    v.Free;
  end;
end;

var
  n: SizeUInt;
  t_def, t_aln: QWord;
begin
  if ParamCount >= 1 then
    n := StrToQWordDef(ParamStr(1), 500000)
  else
    n := 500000;

  Writeln('==== TVec push benchmark (Integer), N=', n, ' ====');
  t_def := BenchPushInt('default(1.5x)', n, False);
  t_aln := BenchPushInt('aligned(1.5x + 64B*elements)', n, True);

  if t_aln <= t_def then
    Writeln(Format('aligned faster or equal by %.2f%%', [ (t_def - t_aln) * 100.0 / Max(1, t_def) ]))
  else
    Writeln(Format('aligned slower by %.2f%%', [ (t_aln - t_def) * 100.0 / Max(1, t_def) ]));
end.

