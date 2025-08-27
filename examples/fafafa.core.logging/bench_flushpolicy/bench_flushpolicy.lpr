program bench_flushpolicy;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.io,
  fafafa.core.logging.sinks.textsink,
  fafafa.core.logging.sinks.rollingfile,
  fafafa.core.logging.sinks.async,
  fafafa.core.logging.formatters.text;

type
  TCountingTextSink = class(TInterfacedObject, ITextSink)
  private
    FInner: ITextSink;
    FFlushes: QWord;
  public
    constructor Create(const AInner: ITextSink);
    procedure WriteLine(const S: string);
    procedure Flush;
    property Flushes: QWord read FFlushes;
  end;

constructor TCountingTextSink.Create(const AInner: ITextSink);
begin
  inherited Create;
  FInner := AInner;
  FFlushes := 0;
end;

procedure TCountingTextSink.WriteLine(const S: string);
begin
  if FInner <> nil then FInner.WriteLine(S);
end;

procedure TCountingTextSink.Flush;
begin
  Inc(FFlushes);
  if FInner <> nil then FInner.Flush;
end;

procedure RunScenario(const AName: string; const APolicy: TFlushPolicy; N: Integer);
var
  baseDir, path: string;
  fmt: ILogFormatter;
  fileSink: ITextSink;
  counting: TCountingTextSink;
  sink: ILogSink;
  async: ILogSink;
  L: ILogger;
  i: Integer;
  t0, t1, dt: QWord;
begin
  baseDir := ExtractFilePath(ParamStr(0));
  path := baseDir + 'bench_' + AName + '.log';
  if FileExists(path) then DeleteFile(path);

  fmt := TTextLogFormatter.Create;
  fileSink := TRollingTextFileSink.Create(path, 32*1024*1024, 4, 0);
  counting := TCountingTextSink.Create(fileSink);
  sink := TTextSinkLogSink.Create(counting, fmt, APolicy);
  async := TAsyncLogSink.Create(sink, 8192, 256, ldpDropOld);

  Logging.SetFormatter(fmt);
  Logging.SetRootSink(async);

  L := GetLogger('bench');
  t0 := GetTickCount64;
  for i := 1 to N do
    L.Info('x%d', [i]);
  Logging.GetRootSink.Flush;
  t1 := GetTickCount64;
  Logging.SetRootSink(nil);

  dt := t1 - t0;
  if dt = 0 then dt := 1;
  Writeln(Format('%s: N=%d time=%dms thr=%.2f KLines/s flushes=%d', [
    AName, N, dt, (N / (dt/1000.0)) / 1000.0, counting.Flushes
  ]));
end;

function ParseN(defaultN: Integer): Integer;
var i, v: Integer; s: string;
begin
  Result := defaultN;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if Pos('N=', s) = 1 then
    begin
      v := StrToIntDef(Copy(s, 3+1, MaxInt), defaultN);
      if v > 0 then Exit(v);
    end;
  end;
end;

var
  pol: TFlushPolicy;
  N: Integer;
begin
  N := ParseN(20000);

  pol.Enabled := False; pol.MaxLines := 0; pol.MaxIntervalMs := 0;
  RunScenario('none', pol, N);

  pol.Enabled := True; pol.MaxLines := 64; pol.MaxIntervalMs := 0;
  RunScenario('count', pol, N);

  pol.Enabled := True; pol.MaxLines := 0; pol.MaxIntervalMs := 50;
  RunScenario('time', pol, N);

  pol.Enabled := True; pol.MaxLines := 64; pol.MaxIntervalMs := 50;
  RunScenario('both', pol, N);
end.

