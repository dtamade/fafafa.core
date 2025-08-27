program benchmark_micro_spsc_mpmc;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fafafa.core.lockfree;

type
  TAtomicFlag = record
    F: LongInt;
  end;

var
  GStartTick, GEndTick: QWord;

function NowMs: QWord; inline;
begin
  Result := GetTickCount64;
end;

function ModeName: string;
begin
  Result := 'PadOff';
  {$IFDEF FAFAFA_LOCKFREE_CACHELINE_PAD}
  Result := 'PadOn';
  {$ENDIF}
  {$IFDEF FAFAFA_LOCKFREE_BACKOFF}
  Result := 'BackoffOn';
  {$ENDIF}
end;

procedure SleepYield;
begin
  {$IFDEF MSWINDOWS}
  Sleep(0);
  {$ELSE}
  Sleep(0);
  {$ENDIF}
end;

// ---------------- SPSC ----------------
type
  TSPSCProd = class(TThread)
  private
    FQ: TIntegerSPSCQueue;
    FCount: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AQ: TIntegerSPSCQueue);
    property Count: QWord read FCount;
  end;

  TSPSCCons = class(TThread)
  private
    FQ: TIntegerSPSCQueue;
    FCount: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AQ: TIntegerSPSCQueue);
    property Count: QWord read FCount;
  end;

constructor TSPSCProd.Create(AQ: TIntegerSPSCQueue);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FQ := AQ;
  FCount := 0;
end;

procedure TSPSCProd.Execute;
var
  v, i: Integer;
begin
  v := 0;
  while NowMs < GStartTick do SleepYield;
  while NowMs < GEndTick do
  begin
    // simple batch to reduce loop overhead
    for i := 1 to 256 do
    begin
      if FQ.Enqueue(v) then Inc(FCount);
      Inc(v);
    end;
  end;
end;

constructor TSPSCCons.Create(AQ: TIntegerSPSCQueue);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FQ := AQ;
  FCount := 0;
end;

procedure TSPSCCons.Execute;
var
  val, i: Integer;
begin
  while NowMs < GStartTick do SleepYield;
  while NowMs < GEndTick do
  begin
    for i := 1 to 256 do
      if FQ.Dequeue(val) then Inc(FCount);
  end;
end;

procedure RunSPSC(const ACapacity: Integer; const ADurationMs: Integer; const ARunIndex: Integer);
var
  Q: TIntegerSPSCQueue;
  Prod: TSPSCProd;
  Cons: TSPSCCons;
  Ops, Dur: QWord;
  OpsPerSec: Double;
begin
  Q := CreateIntSPSCQueue(ACapacity);
  try
    Prod := TSPSCProd.Create(Q);
    Cons := TSPSCCons.Create(Q);
    try
      GStartTick := NowMs + 200; // warmup align
      GEndTick := GStartTick + ADurationMs;
      Prod.WaitFor;
      Cons.WaitFor;
      Ops := Prod.Count + Cons.Count;
      Dur := ADurationMs;
      if Dur = 0 then Dur := 1;
      OpsPerSec := (Ops * 1000.0) / Dur;
      WriteLn(Format('algo=SPSC,mode=%s,capacity=%d,producers=1,consumers=1,duration_ms=%d,ops=%d,ops_per_sec=%.0f,run=%d',
        [ModeName, ACapacity, ADurationMs, Ops, OpsPerSec, ARunIndex]));
    finally
      Prod.Free;
      Cons.Free;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------- MPMC ----------------
type
  TMPMCProd = class(TThread)
  private
    FQ: TIntMPMCQueue;
    FCount: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AQ: TIntMPMCQueue);
    property Count: QWord read FCount;
  end;

  TMPMCCons = class(TThread)
  private
    FQ: TIntMPMCQueue;
    FCount: QWord;
  protected
    procedure Execute; override;
  public
    constructor Create(AQ: TIntMPMCQueue);
    property Count: QWord read FCount;
  end;

constructor TMPMCProd.Create(AQ: TIntMPMCQueue);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FQ := AQ;
  FCount := 0;
end;

procedure TMPMCProd.Execute;
var
  v, i: Integer;
begin
  v := 0;
  while NowMs < GStartTick do SleepYield;
  while NowMs < GEndTick do
  begin
    for i := 1 to 128 do
    begin
      if FQ.Enqueue(v) then Inc(FCount);
      Inc(v);
    end;
  end;
end;

constructor TMPMCCons.Create(AQ: TIntMPMCQueue);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FQ := AQ;
  FCount := 0;
end;

procedure TMPMCCons.Execute;
var
  val, i: Integer;
begin
  while NowMs < GStartTick do SleepYield;
  while NowMs < GEndTick do
  begin
    for i := 1 to 128 do
      if FQ.Dequeue(val) then Inc(FCount);
  end;
end;

procedure RunMPMC(const ACapacity, AProducers, AConsumers: Integer; const ADurationMs: Integer; const ARunIndex: Integer);
var
  Q: TIntMPMCQueue;
  Prods: array of TMPMCProd;
  Cons: array of TMPMCCons;
  i: Integer;
  OpsEnq, OpsDeq, Ops, Dur: QWord;
  OpsPerSec: Double;
begin
  Q := CreateIntMPMCQueue(ACapacity);
  try
    SetLength(Prods, AProducers);
    SetLength(Cons, AConsumers);
    for i := 0 to High(Prods) do Prods[i] := TMPMCProd.Create(Q);
    for i := 0 to High(Cons) do Cons[i] := TMPMCCons.Create(Q);
    try
      GStartTick := NowMs + 200;
      GEndTick := GStartTick + ADurationMs;
      for i := 0 to High(Prods) do Prods[i].WaitFor;
      for i := 0 to High(Cons) do Cons[i].WaitFor;
      OpsEnq := 0; OpsDeq := 0;
      for i := 0 to High(Prods) do Inc(OpsEnq, Prods[i].Count);
      for i := 0 to High(Cons) do Inc(OpsDeq, Cons[i].Count);
      Ops := OpsEnq + OpsDeq;
      Dur := ADurationMs; if Dur = 0 then Dur := 1;
      OpsPerSec := (Ops * 1000.0) / Dur;
      WriteLn(Format('algo=MPMC,mode=%s,capacity=%d,producers=%d,consumers=%d,duration_ms=%d,ops=%d,ops_per_sec=%.0f,run=%d',
        [ModeName, ACapacity, AProducers, AConsumers, ADurationMs, Ops, OpsPerSec, ARunIndex]));
    finally
      for i := 0 to High(Prods) do Prods[i].Free;
      for i := 0 to High(Cons) do Cons[i].Free;
    end;
  finally
    Q.Free;
  end;
end;

// ---------------- Main ----------------
function GetIntArg(const Key: string; const Default: Integer): Integer;
var
  i, p: Integer;
  s: string;
begin
  Result := Default;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    p := Pos(Key + '=', s);
    if p = 1 then
    begin
      Result := StrToIntDef(Copy(s, Length(Key)+2, MaxInt), Default);
      Exit;
    end;
  end;
end;

function GetStrArg(const Key, Default: string): string;
var
  i, p: Integer;
  s: string;
begin
  Result := Default;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    p := Pos(Key + '=', s);
    if p = 1 then
    begin
      Result := Copy(s, Length(Key)+2, MaxInt);
      Exit;
    end;
  end;
end;

var
  durationMs, repeats, capacity, producers, consumers, run: Integer;
  algo: string;
begin
  durationMs := GetIntArg('duration_ms', 3000);
  repeats    := GetIntArg('repeats', 3);
  capacity   := GetIntArg('capacity', 1 shl 16);
  producers  := GetIntArg('producers', 2);
  consumers  := GetIntArg('consumers', 2);
  algo       := GetStrArg('algo', 'both'); // spsc|mpmc|both

  // CSV header
  WriteLn('algo,mode,capacity,producers,consumers,duration_ms,ops,ops_per_sec,run');

  for run := 1 to repeats do
  begin
    if (algo = 'spsc') or (algo = 'both') then
      RunSPSC(capacity, durationMs, run);
    if (algo = 'mpmc') or (algo = 'both') then
      RunMPMC(capacity, producers, consumers, durationMs, run);
  end;
end.

