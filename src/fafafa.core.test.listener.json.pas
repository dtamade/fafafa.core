unit fafafa.core.test.listener.json;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes, fafafa.core.test.core, fafafa.core.test.json.intf, fafafa.core.report.common;

type
  TJsonTestListener = class(TInterfacedObject, ITestListener)
  private
    FWriter: IJsonReportWriter;
    FOutFile: string;
    FStartTick: QWord;
    FFailures: Integer;
    FSeen: Integer;
    FHost: string;
    FTimestamp: string;
    FSkipped: Integer;
  public
    constructor Create(const AWriterFactory: TJsonWriterFactory; const AFileName: string);
{$push}
{$warn 5024 off}
    procedure OnStart(ATotal: Integer);
    procedure OnTestStart(const AName: string);
    procedure OnTestSuccess(const AName: string; AElapsedMs: QWord);
    procedure OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure OnTestSkipped(const AName: string; AElapsedMs: QWord);
    procedure OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
{$pop}
  end;

implementation

constructor TJsonTestListener.Create(const AWriterFactory: TJsonWriterFactory; const AFileName: string);
begin
  inherited Create;
  FOutFile := AFileName;
  if Assigned(AWriterFactory) then
    FWriter := AWriterFactory(AFileName)
  else
    FWriter := nil;
end;

procedure TJsonTestListener.OnStart(ATotal: Integer);
begin
  FStartTick := GetTickCount64;
  FFailures := 0;
  FSeen := 0;
  FSkipped := 0;
  FHost := GetHostNameCross;
  FTimestamp := FormatRFC3339Zulu(Now, False{sec}, True{UTC});
  if FWriter <> nil then
    FWriter.BeginSuite('fafafa.core.test', FTimestamp, FHost);
end;

procedure TJsonTestListener.OnTestStart(const AName: string);
begin
end;

procedure TJsonTestListener.OnTestSuccess(const AName: string; AElapsedMs: QWord);
var cls, nm: string;
begin
  Inc(FSeen);
  cls := ExtractFileDir(AName); if cls = '' then cls := 'default';
  nm := ExtractFileName(AName); if nm = '' then nm := AName;
  if FWriter <> nil then
    FWriter.AddTestSuccess(cls, nm, AElapsedMs/1000.0);
end;

procedure TJsonTestListener.OnTestSkipped(const AName: string; AElapsedMs: QWord);
var cls, nm: string;
begin
  Inc(FSeen);
  Inc(FSkipped);
  cls := ExtractFileDir(AName); if cls = '' then cls := 'default';
  nm := ExtractFileName(AName); if nm = '' then nm := AName;
  if FWriter <> nil then
    FWriter.AddTestSkipped(cls, nm, AElapsedMs/1000.0);
end;

procedure TJsonTestListener.OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
var cls, nm: string; main, details: string; p: SizeInt; sl: TStringList;
    writerV2: IJsonReportWriterV2;
begin
  Inc(FFailures);
  Inc(FSeen);
  cls := ExtractFileDir(AName); if cls = '' then cls := 'default';
  nm := ExtractFileName(AName); if nm = '' then nm := AName;
  // split message into main and cleanup details for structured writers
  main := AMessage; details := '';
  p := Pos(LineEnding+'[cleanup]'+LineEnding, AMessage);
  if p > 0 then
  begin
    main := Trim(Copy(AMessage, 1, p-1));
    details := Copy(AMessage, p + Length(LineEnding+'[cleanup]'+LineEnding), MaxInt);
  end
  else if Pos('cleanup errors:', AMessage) = 1 then
  begin
    main := 'cleanup errors';
    details := Copy(AMessage, Length('cleanup errors:')+1, MaxInt);
  end;
  if FWriter <> nil then
  begin
    // Try V2 first
    if Supports(FWriter, IJsonReportWriterV2, writerV2) and (details <> '') then
    begin
      sl := TStringList.Create;
      try
        sl.Text := details;
        writerV2.AddTestFailureEx(cls, nm, main, sl, AElapsedMs/1000.0);
      finally
        sl.Free;
      end;
    end
    else
    begin
      if details <> '' then main := main + LineEnding + details;
      FWriter.AddTestFailure(cls, nm, main, AElapsedMs/1000.0);
    end;
  end;
end;

procedure TJsonTestListener.OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
begin
  if FWriter <> nil then
  begin
    FWriter.EndSuite(FSeen, FFailures, FSkipped, (GetTickCount64 - FStartTick)/1000.0);
    FWriter.SaveToFile(FOutFile);
  end;
end;

end.

