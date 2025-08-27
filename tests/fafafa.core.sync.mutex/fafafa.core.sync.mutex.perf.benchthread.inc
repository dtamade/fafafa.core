type
  TBenchThread = class(TThread)
  private
    FM: IMutex; FCountIdx: PInteger;
  public
    constructor Create(AM: IMutex; ACountIdx: PInteger);
    procedure Execute; override;
  end;

constructor TBenchThread.Create(AM: IMutex; ACountIdx: PInteger);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FM := AM; FCountIdx := ACountIdx;
end;

procedure TBenchThread.Execute;
var k: Integer;
begin
  for k := 1 to 20000 do begin FM.Acquire; FM.Release; end;
  InterlockedIncrement(FCountIdx^);
end;

