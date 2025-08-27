unit fafafa.core.report.sink.console;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes, fafafa.core.report.sink.intf
  {$IFDEF FAFAFA_REPORT_CONSOLE_USE_ITEXTSINK}
  , fafafa.core.io
  {$ENDIF}
  ;

type
  // A simple Console sink that prints human-friendly lines.
  TReportConsoleSink = class(TInterfacedObject, IReportSink)
  private
    FStartTick: QWord;
    FSeen: Integer;
    FFailed: Integer;
    FTimeCol: Integer;
  {$IFDEF FAFAFA_REPORT_CONSOLE_USE_ITEXTSINK}
    FSink: ITextSink;
    procedure OutLine(const S: string);
  {$ELSE}
    procedure OutLine(const S: string);
  {$ENDIF}
    function SplitCleanupMessage(const Msg: string; out MainMsg: string; out Cleanup: TStringList): boolean;
  public
    constructor Create;
{$push}
{$warn 5024 off}
    procedure SuiteStart(ATotal: Integer);
    procedure CaseStart(const AName: string);
    procedure CaseSuccess(const AName: string; AElapsedMs: QWord);
    procedure CaseFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure CaseSkipped(const AName: string; AElapsedMs: QWord);
    procedure SuiteEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
{$pop}
  end;

implementation

constructor TReportConsoleSink.Create;
begin
  inherited Create;
  FTimeCol := 5;
  FSeen := 0; FFailed := 0;
  {$IFDEF FAFAFA_REPORT_CONSOLE_USE_ITEXTSINK}
  FSink := TConsoleSink.Create;
  {$ENDIF}
end;

procedure TReportConsoleSink.SuiteStart({%H-}ATotal: Integer);
var s: string; v: Integer;
begin
  FStartTick := GetTickCount64;
  FSeen := 0; FFailed := 0;
  // optional runtime override for time column width
  s := GetEnvironmentVariable('FAFAFA_CONSOLE_TIME_COL_WIDTH');
  if s <> '' then
  begin
    try
      v := StrToInt(s);
      if (v >= 1) and (v <= 12) then FTimeCol := v;
    except
    end;
  end;
  OutLine('== Running tests ==');
end;

procedure TReportConsoleSink.CaseStart(const {%H-}AName: string);
begin
  // no-op for now
end;

procedure TReportConsoleSink.CaseSuccess(const AName: string; AElapsedMs: QWord);
begin
  Inc(FSeen);
  OutLine(Format('[ OK ] %s (%*d ms)', [AName, FTimeCol, AElapsedMs]));
end;

procedure TReportConsoleSink.CaseFailure(const AName, AMessage: string; AElapsedMs: QWord);
var main: string; cleanup: TStringList; i, digits: Integer;
begin
  Inc(FSeen); Inc(FFailed);
  cleanup := nil;
  if SplitCleanupMessage(AMessage, main, cleanup) then
  begin
    OutLine(Format('[FAIL] %s (%*d ms): %s', [AName, FTimeCol, AElapsedMs, main]));
    if (cleanup <> nil) and (cleanup.Count > 0) then
    begin
      OutLine(Format('           cleanup (%d):', [cleanup.Count]));
      digits := Length(IntToStr(cleanup.Count));
      for i := 0 to cleanup.Count-1 do
        OutLine(Format('           %*d) %s', [digits, i+1, cleanup[i]]));
    end;
    cleanup.Free;
  end
  else
    OutLine(Format('[FAIL] %s (%*d ms): %s', [AName, FTimeCol, AElapsedMs, AMessage]));
end;

procedure TReportConsoleSink.CaseSkipped(const AName: string; AElapsedMs: QWord);
begin
  Inc(FSeen);
  OutLine(Format('[SKIP] %s (%*d ms)', [AName, FTimeCol, AElapsedMs]));
end;

procedure TReportConsoleSink.SuiteEnd({%H-}ATotal, {%H-}AFailed: Integer; {%H-}AElapsedMs: QWord);
var total: QWord;
begin
  total := GetTickCount64 - FStartTick;
  if FFailed = 0 then
    OutLine(Format('== All %d test(s) passed in %d ms ==', [FSeen, total]))
  else
    OutLine(Format('== %d/%d test(s) failed in %d ms ==', [FFailed, FSeen, total]));
end;

function TReportConsoleSink.SplitCleanupMessage(const Msg: string; out MainMsg: string; out Cleanup: TStringList): boolean;
var p, i: Integer; head, tail: string; lines: TStringList;
begin
  Cleanup := TStringList.Create;
  Result := False;
  p := Pos(LineEnding + '[cleanup]' + LineEnding, Msg);
  if p > 0 then
  begin
    head := Copy(Msg, 1, p-1);
    tail := Copy(Msg, p + Length(LineEnding + '[cleanup]' + LineEnding), MaxInt);
    MainMsg := Trim(head);
    lines := TStringList.Create;
    try
      lines.Text := tail;
      for i := 0 to lines.Count-1 do
        if Trim(lines[i]) <> '' then Cleanup.Add(Trim(lines[i]));
    finally
      lines.Free;
    end;
    Exit(True);
  end;
  if Pos('cleanup errors:', Msg) = 1 then
  begin
    MainMsg := 'cleanup errors';
    lines := TStringList.Create;
    try
      lines.Text := Copy(Msg, Length('cleanup errors:')+1, MaxInt);
      for i := 0 to lines.Count-1 do
        if Trim(lines[i]) <> '' then Cleanup.Add(Trim(lines[i]));
    finally
      lines.Free;
    end;
    Exit(True);
  end;
  MainMsg := Msg;
end;

{$IFDEF FAFAFA_REPORT_CONSOLE_USE_ITEXTSINK}
procedure TReportConsoleSink.OutLine(const S: string);
begin
  if FSink <> nil then FSink.WriteLine(S) else WriteLn(S);
end;
{$ELSE}
procedure TReportConsoleSink.OutLine(const S: string);
begin
  WriteLn(S);
end;
{$ENDIF}


end.
