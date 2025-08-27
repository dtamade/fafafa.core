unit fafafa.core.report.sink.junit;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes, fafafa.core.report.sink.intf, fafafa.core.base, fafafa.core.report.common;

type
  // Sink that writes JUnit XML using the same formatting as TJUnitTestListener
  TReportJUnitSink = class(TInterfacedObject, IReportSink)
  private
    FOutFile: string;
    FOut: TStringList;
    FStartTick: QWord;
    FFailures: Integer;
    FSkipped: Integer;
    FSeen: Integer;
    FHost: string;
    FTimestamp: string;
    FWriteSystemOut: Boolean;
    function JUnitXmlEscape(const S: string): string; inline;
    procedure EnsureHeaderPlaceholder;
    procedure ReplaceHeader(const ATotalFailed: Integer);
    procedure SplitMessage(const AMessage: string; out AMain, ADetails: string);
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
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

constructor TReportJUnitSink.Create(const AFileName: string);
begin
  inherited Create;
  FOutFile := AFileName;
  FOut := TStringList.Create;
  FWriteSystemOut := not SameText(GetEnvironmentVariable('FAFAFA_JUNIT_NO_SYSOUT'), '1');
end;

destructor TReportJUnitSink.Destroy;
begin
  FOut.Free;
  inherited Destroy;
end;

function TReportJUnitSink.JUnitXmlEscape(const S: string): string;
begin
  Result := XmlEscapeXML10Strict(S);
end;

procedure TReportJUnitSink.EnsureHeaderPlaceholder;
begin
  if (FOut.Count = 0) or (FOut[0] <> '<?xml version="1.0" encoding="UTF-8"?>') then
  begin
    FOut.Clear;
    FOut.Add('<?xml version="1.0" encoding="UTF-8"?>');
    FOut.Add('<<HEADER>>');
  end;
end;

procedure TReportJUnitSink.ReplaceHeader(const ATotalFailed: Integer);
var i: Integer; totalSec: Double; suiteHdr: string;
begin
  totalSec := (GetTickCount64 - FStartTick) / 1000.0;
  suiteHdr := Format(
    '<testsuite name="%s" tests="%d" failures="%d" skipped="%d" time="%.6f" timestamp="%s" hostname="%s">',
    [JUnitXmlEscape('fafafa.core.test'), FSeen, FFailures, FSkipped, totalSec,
     JUnitXmlEscape(FTimestamp), JUnitXmlEscape(FHost)]);
  for i := 0 to FOut.Count-1 do
    if FOut[i] = '<<HEADER>>' then begin FOut[i] := suiteHdr; Break; end;
end;

procedure TReportJUnitSink.SplitMessage(const AMessage: string; out AMain, ADetails: string);
var p: SizeInt;
begin
  p := Pos(LineEnding+'[cleanup]'+LineEnding, AMessage);
  if p > 0 then
  begin
    AMain := Trim(Copy(AMessage, 1, p-1));
    ADetails := Copy(AMessage, p + Length(LineEnding+'[cleanup]'+LineEnding), MaxInt);
  end
  else if Pos('cleanup errors:', AMessage) = 1 then
  begin
    AMain := 'cleanup errors';
    ADetails := Copy(AMessage, Length('cleanup errors:')+1, MaxInt);
  end
  else
  begin
    AMain := AMessage; ADetails := '';
  end;
end;

procedure TReportJUnitSink.SuiteStart({%H-}ATotal: Integer);
begin
  FStartTick := GetTickCount64;
  FFailures := 0; FSkipped := 0; FSeen := 0;
  FHost := GetHostNameCross;
  FTimestamp := FormatRFC3339Zulu(Now, False{sec}, True{UTC});
  EnsureHeaderPlaceholder;
end;

procedure TReportJUnitSink.CaseStart(const {%H-}AName: string);
begin
  // no-op
end;

procedure TReportJUnitSink.CaseSuccess(const AName: string; AElapsedMs: QWord);
var cls, nm, caseId: string;
begin
  Inc(FSeen);
  cls := ExtractFileDir(AName); if cls = '' then cls := 'default';
  nm := ExtractFileName(AName); if nm = '' then nm := AName;
  if FWriteSystemOut then
  begin
    caseId := GetEnvironmentVariable('FAFAFA_CURRENT_TEST_ID'); if caseId='' then caseId := AName;
    FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
      [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
    FOut.Add(Format('    <system-out>CaseId=%s</system-out>', [JUnitXmlEscape(caseId)]));
    FOut.Add('  </testcase>');
  end
  else
    FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f"/>',
      [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
end;

procedure TReportJUnitSink.CaseSkipped(const AName: string; AElapsedMs: QWord);
var cls, nm: string;
begin
  Inc(FSeen); Inc(FSkipped);
  cls := ExtractFileDir(AName); if cls='' then cls := 'default';
  nm := ExtractFileName(AName); if nm='' then nm := AName;
  FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
    [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
  FOut.Add('    <skipped/>');
  FOut.Add('  </testcase>');
end;

procedure TReportJUnitSink.CaseFailure(const AName, AMessage: string; AElapsedMs: QWord);
var cls, nm, caseId, main, details: string; lines: TStringList; i, digits: Integer;
begin
  Inc(FSeen); Inc(FFailures);
  cls := ExtractFileDir(AName); if cls='' then cls := 'default';
  nm := ExtractFileName(AName); if nm='' then nm := AName;
  FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
    [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
  SplitMessage(AMessage, main, details);
  if details <> '' then
  begin
    lines := TStringList.Create;
    try
      lines.Text := details;
      for i := lines.Count-1 downto 0 do if Trim(lines[i])='' then lines.Delete(i);
      FOut.Add(Format('    <failure message="%s">', [JUnitXmlEscape(main)]));
      FOut.Add('      <system-err><![CDATA[');
      FOut.Add(Format('  cleanup (%d):', [lines.Count]));
      digits := Length(IntToStr(lines.Count));
      for i := 0 to lines.Count-1 do
        FOut.Add(Format('  %*d) %s', [digits, i+1, lines[i]]));
      FOut.Add('      ]]></system-err>');
      FOut.Add('    </failure>');
    finally
      lines.Free;
    end;
  end
  else
    FOut.Add(Format('    <failure message="%s"/>', [JUnitXmlEscape(main)]));
  if FWriteSystemOut then
  begin
    caseId := GetEnvironmentVariable('FAFAFA_CURRENT_TEST_ID'); if caseId='' then caseId := AName;
    FOut.Add(Format('    <system-out>CaseId=%s</system-out>', [JUnitXmlEscape(caseId)]));
  end;
  FOut.Add('  </testcase>');
end;

procedure TReportJUnitSink.SuiteEnd({%H-}ATotal, {%H-}AFailed: Integer; {%H-}AElapsedMs: QWord);
begin
  ReplaceHeader(AFailed);
  FOut.Add('</testsuite>');
  if FOutFile <> '' then FOut.SaveToFile(FOutFile) else WriteLn(FOut.Text);
end;

end.

