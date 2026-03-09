unit fafafa.core.test.listener.junit;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, DateUtils, fafafa.core.test.core, fafafa.core.base, fafafa.core.xml, fafafa.core.report.common;

type
  TJUnitTestListener = class(TInterfacedObject, ITestListener)
  private
    FStartTick: QWord;
    FFailures: Integer;
    FSkipped: Integer;
    FTotal: Integer;
    FOutFile: string;
    FOut: TStringList;
    FSeen: Integer;
    FHost: string;
    FTimestamp: string;
    FWriteSystemOut: Boolean;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
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

function JUnitXmlEscape(const S: string): string;
begin
  // Use strict mode to ensure XML 1.0 compliance for external tools
  Result := XmlEscapeXML10Strict(S);
end;

constructor TJUnitTestListener.Create(const AFileName: string);
begin
  inherited Create;
  FOutFile := AFileName;
  FOut := TStringList.Create;
  FWriteSystemOut := not SameText(GetEnvironmentVariable('FAFAFA_JUNIT_NO_SYSOUT'), '1');
end;

destructor TJUnitTestListener.Destroy;
begin
  FOut.Free;
  inherited Destroy;
end;

procedure TJUnitTestListener.OnStart(ATotal: Integer);
begin
  FStartTick := GetTickCount64;
  FFailures := 0;
  FSkipped := 0;
  FTotal := ATotal;
  FSeen := 0;
  // host & timestamp
  FHost := GetHostNameCross;
  // Always produce UTC Zulu timestamp for JUnit header
  FTimestamp := FormatRFC3339Zulu(Now, False{sec}, True{UTC});
  FOut.Clear;
  FOut.Add('<?xml version="1.0" encoding="UTF-8"?>');
  // placeholder for header, will be replaced in OnEnd
  FOut.Add('<<HEADER>>');
end;

procedure TJUnitTestListener.OnTestStart(const AName: string);
begin
  // no-op
end;

procedure TJUnitTestListener.OnTestSuccess(const AName: string; AElapsedMs: QWord);
var cls, nm, caseId: string;
begin
  Inc(FSeen);
  // split classname and name by last '/'
  cls := ExtractFileDir(AName);
  if cls = '' then cls := 'default';
  nm := ExtractFileName(AName);
  if nm = '' then nm := AName;
  if FWriteSystemOut then
  begin
    // write testcase with system-out containing CaseId
    caseId := GetEnvironmentVariable('FAFAFA_CURRENT_TEST_ID');
    if caseId = '' then caseId := AName; // fallback
    FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
      [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
    FOut.Add(Format('    <system-out>CaseId=%s</system-out>', [JUnitXmlEscape(caseId)]));
    FOut.Add('  </testcase>');
  end
  else
  begin
    FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f"/>',
      [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
  end;
end;

procedure TJUnitTestListener.OnTestSkipped(const AName: string; AElapsedMs: QWord);
var cls, nm: string;
begin
  Inc(FSeen);
  Inc(FSkipped);
  cls := ExtractFileDir(AName);
  if cls = '' then cls := 'default';
  nm := ExtractFileName(AName);
  if nm = '' then nm := AName;
  FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
    [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
  FOut.Add('    <skipped/>');
  FOut.Add('  </testcase>');
end;

procedure TJUnitTestListener.OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
var cls, nm, caseId: string;
    main: string; cleanup: TStringList; i: Integer; details: string; digits: Integer;
begin
  Inc(FFailures);
  Inc(FSeen);
  cls := ExtractFileDir(AName);
  if cls = '' then cls := 'default';
  nm := ExtractFileName(AName);
  if nm = '' then nm := AName;
  FOut.Add(Format('  <testcase classname="%s" name="%s" time="%.6f">',
    [JUnitXmlEscape(cls), JUnitXmlEscape(nm), AElapsedMs/1000.0]));
  // split message into main and cleanup details
  cleanup := TStringList.Create;
  try
    if Pos(LineEnding+'[cleanup]'+LineEnding, AMessage) > 0 then
    begin
      main := Trim(Copy(AMessage, 1, Pos(LineEnding+'[cleanup]'+LineEnding, AMessage)-1));
      details := Copy(AMessage, Pos(LineEnding+'[cleanup]'+LineEnding, AMessage)+Length(LineEnding+'[cleanup]'+LineEnding), MaxInt);
    end
    else if Pos('cleanup errors:', AMessage) = 1 then
    begin
      main := 'cleanup errors';
      details := Copy(AMessage, Length('cleanup errors:')+1, MaxInt);
    end
    else
    begin
      main := AMessage;
      details := '';
    end;
    if details <> '' then
    begin
      cleanup.Text := details;
      for i := cleanup.Count-1 downto 0 do if Trim(cleanup[i]) = '' then cleanup.Delete(i);
      FOut.Add(Format('    <failure message="%s">', [JUnitXmlEscape(main)]));
      FOut.Add('      <system-err><![CDATA[');
      // 轻微美化：与条目行缩进一致（2 空格）
      FOut.Add(Format('  cleanup (%d):', [cleanup.Count]));
      // 对齐编号宽度，便于人眼阅读
      digits := Length(IntToStr(cleanup.Count));
      for i := 0 to cleanup.Count-1 do
        FOut.Add(Format('  %*d) %s', [digits, i+1, cleanup[i]]));
      FOut.Add('      ]]></system-err>');
      FOut.Add('    </failure>');
    end
    else
      FOut.Add(Format('    <failure message="%s"/>', [JUnitXmlEscape(main)]));
  finally
    cleanup.Free;
  end;
  if FWriteSystemOut then
  begin
    caseId := GetEnvironmentVariable('FAFAFA_CURRENT_TEST_ID');
    if caseId = '' then caseId := AName;
    FOut.Add(Format('    <system-out>CaseId=%s</system-out>', [JUnitXmlEscape(caseId)]));
  end;
  FOut.Add('  </testcase>');
end;

procedure TJUnitTestListener.OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
var i: Integer; suiteHdr: string; totalSec: Double;
begin
  totalSec := (GetTickCount64 - FStartTick) / 1000.0;
  suiteHdr := Format(
    '<testsuite name="%s" tests="%d" failures="%d" skipped="%d" time="%.6f" timestamp="%s" hostname="%s">',
    [JUnitXmlEscape('fafafa.core.test'), FSeen, FFailures, FSkipped, totalSec,
     JUnitXmlEscape(FTimestamp), JUnitXmlEscape(FHost)]);
  // replace placeholder
  for i := 0 to FOut.Count-1 do
    if FOut[i] = '<<HEADER>>' then
    begin
      FOut[i] := suiteHdr;
      Break;
    end;
  FOut.Add('</testsuite>');
  if FOutFile <> '' then
    FOut.SaveToFile(FOutFile)
  else
    WriteLn(FOut.Text);
end;

end.

