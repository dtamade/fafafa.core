program test_lockfree_iqueue_smoke;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.queue,
  fafafa.core.lockfree.spscQueue,
  fafafa.core.lockfree.michaelScottQueue,
  fafafa.core.lockfree.mpmcQueue;

procedure TestSPSC;
var Q: specialize TSPSCQueue<Integer>; v: Integer; ok: Boolean;
begin
  Writeln('SPSC:');
  Q := specialize TSPSCQueue<Integer>.Create(8);
  try
    Q.Push(1); Q.Push(2); Q.Push(3);
    ok := Q.Pop(v); Writeln('  Pop ok=', ok, ' v=', v);
    ok := Q.TryPeek(v); Writeln('  TryPeek ok=', ok);
    Writeln('  Count=', Q.Count, ' Empty=', Q.IsEmpty);
  finally
    Q.Free;
  end;
end;

procedure TestMPSC;
var Q: specialize TMichaelScottQueue<Integer>; v: Integer; ok: Boolean;
begin
  Writeln('MPSC:');
  Q := specialize TMichaelScottQueue<Integer>.Create;
  try
    Q.Push(10); Q.Push(20);
    ok := Q.Pop(v); Writeln('  Pop ok=', ok, ' v=', v);
    ok := Q.TryPeek(v); Writeln('  TryPeek ok=', ok);
    Writeln('  Count=', Q.Count, ' Empty=', Q.IsEmpty);
  finally
    Q.Free;
  end;
end;

procedure TestMPMC;
var Q: specialize TPreAllocMPMCQueue<Integer>; v: Integer; ok: Boolean;
begin
  Writeln('MPMC:');
  Q := specialize TPreAllocMPMCQueue<Integer>.Create(8);
  try
    Q.Push(100); Q.Push(200);
    ok := Q.TryPeek(v); Writeln('  TryPeek ok=', ok);
    ok := Q.Pop(v); Writeln('  Pop ok=', ok, ' v=', v);
    Writeln('  Count=', Q.Count, ' Empty=', Q.IsEmpty);
  finally
    Q.Free;
  end;
end;

begin
  TestSPSC;
  TestMPSC;
  TestMPMC;
end.

