unit fafafa.core.report.sink.json;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes, fafafa.core.report.sink.intf, fafafa.core.report.common,
     fafafa.core.test.json.intf;

type
  // Sink that writes JSON report using existing IJsonReportWriter/WriterV2
  TReportJsonSink = class(TInterfacedObject, IReportSink)
  private
    FWriter: IJsonReportWriter;
    FWriterV2: IJsonReportWriterV2;
    FOutFile: string;
    FHost: string;
    FTs: string;
    FTotal: Integer;
    FFailures: Integer;
    FSkipped: Integer;
    function SecondsOfMs(const ms: QWord): Double; inline;
    function ClassNameOf(const FullName: string): string;
    function CaseNameOf(const FullName: string): string;
  public
    constructor Create(const AFactory: TJsonWriterFactory; const AFileName: string);
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

constructor TReportJsonSink.Create(const AFactory: TJsonWriterFactory; const AFileName: string);
begin
  inherited Create;
  FWriter := AFactory(AFileName);
  if Supports(FWriter, IJsonReportWriterV2, FWriterV2) then ;
  FOutFile := AFileName;
  FHost := GetHostNameCross;
  FTs := FormatRFC3339Zulu(Now, False{sec}, True{UTC});
  FTotal := 0; FFailures := 0; FSkipped := 0;
end;

function TReportJsonSink.SecondsOfMs(const ms: QWord): Double;
begin
  Result := ms / 1000.0;
end;

function TReportJsonSink.ClassNameOf(const FullName: string): string;
var p: SizeInt;
begin
  p := LastDelimiter('/', FullName);
  if p > 0 then Result := Copy(FullName, 1, p-1)
  else Result := '';
end;

function TReportJsonSink.CaseNameOf(const FullName: string): string;
var p: SizeInt;
begin
  p := LastDelimiter('/', FullName);
  if p > 0 then Result := Copy(FullName, p+1, MaxInt)
  else Result := FullName;
end;

procedure TReportJsonSink.SuiteStart(ATotal: Integer);
begin
  // consume possibly unused param to keep hints clean
  FTotal := ATotal;
  FWriter.BeginSuite('suite', FTs, FHost);
end;

procedure TReportJsonSink.CaseStart(const AName: string);
begin
  // consume possibly unused param to keep hints clean
  if AName='' then; // no-op
end;

procedure TReportJsonSink.CaseSuccess(const AName: string; AElapsedMs: QWord);
var cls, name: string;
begin
  cls := ClassNameOf(AName); name := CaseNameOf(AName);
  FWriter.AddTestSuccess(cls, name, SecondsOfMs(AElapsedMs));
end;

procedure TReportJsonSink.CaseFailure(const AName, AMessage: string; AElapsedMs: QWord);
var cls, name, main, tail: string; cleanup, lines: TStringList; i: Integer; p: SizeInt;
begin
  Inc(FFailures);
  cls := ClassNameOf(AName); name := CaseNameOf(AName);
  cleanup := nil;
  if Assigned(FWriterV2) then
  begin
    cleanup := TStringList.Create;
    // 解析 message 中的 cleanup 列表（与 Console sink 相同约定）
    // 格式：<main> + LineEnding + '[cleanup]' + LineEnding + lines...
    // 若无 cleanup 段，cleanup 将保持空
    // 简化实现：当未检测到标记则不添加 cleanup 数组
    p := Pos(LineEnding + '[cleanup]' + LineEnding, AMessage);
    if p > 0 then
    begin
      main := Trim(Copy(AMessage, 1, p-1));
      tail := Copy(AMessage, p + Length(LineEnding + '[cleanup]' + LineEnding), MaxInt);
      lines := TStringList.Create;
      try
        lines.Text := tail;
        for i := 0 to lines.Count-1 do
          if Trim(lines[i]) <> '' then cleanup.Add(Trim(lines[i]));
      finally
        lines.Free;
      end;
      FWriterV2.AddTestFailureEx(cls, name, main, cleanup, SecondsOfMs(AElapsedMs));
      cleanup.Free; cleanup := nil;
      Exit;
    end;
  end;
  // fallback: V1 或未检测到 cleanup 段
  FWriter.AddTestFailure(cls, name, AMessage, SecondsOfMs(AElapsedMs));
end;

procedure TReportJsonSink.CaseSkipped(const AName: string; AElapsedMs: QWord);
var cls, name: string;
begin
  Inc(FSkipped);
  cls := ClassNameOf(AName); name := CaseNameOf(AName);
  FWriter.AddTestSkipped(cls, name, SecondsOfMs(AElapsedMs));
end;

procedure TReportJsonSink.SuiteEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
begin
  // consume possibly unused params to keep hints clean
  if ATotal<0 then; if AFailed<0 then; // no-op markers
  FWriter.EndSuite(FTotal, FFailures, FSkipped, SecondsOfMs(AElapsedMs));
  FWriter.SaveToFile(FOutFile);
end;

end.

