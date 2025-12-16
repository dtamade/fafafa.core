unit fafafa.core.benchmark.reporter.sinkadapter;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.benchmark,
  fafafa.core.report.sink.intf;

// Adapter: IBenchmarkReporter -> IReportSink
// Purpose: allow benchmark to reuse sink-based reporters (console/json)
// Behavior: opt-in; default reporters remain unchanged

type
  TBenchmarkReporterSinkAdapter = class(TInterfacedObject, IBenchmarkReporter)
  private
    FSink: IReportSink;
    FOutFile: string;
    function MsFromNs(const Ns: Double): QWord; inline;
  public
    constructor Create(const ASink: IReportSink; const AOutFile: string = '');
    // IBenchmarkReporter
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

// Factory helpers to build sink-backed reporters
function CreateSinkConsoleReporter: IBenchmarkReporter;
function CreateSinkJsonReporter(const AFileName: string): IBenchmarkReporter;

// Forwarder: keep env toggle path while ensuring JSON schema identical to TJSONReporter
// Instead of using test-report sink schema, we forward to the existing JSON reporter.
type
  TBenchmarkReporterForwardJSON = class(TInterfacedObject, IBenchmarkReporter)
  private
    FInner: IBenchmarkReporter;
  public
    constructor Create(const AFileName: string);
    procedure ReportResult(aResult: IBenchmarkResult);
    procedure ReportResults(const aResults: array of IBenchmarkResult);
    procedure ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
    procedure SetOutputFile(const aFileName: string);
    procedure SetFormat(const aFormat: string);
  end;

implementation

uses
  fafafa.core.report.sink.console,
  fafafa.core.report.sink.json,
  fafafa.core.test.json.intf,
  fafafa.core.test.json.rtl,
  fafafa.core.math;

constructor TBenchmarkReporterSinkAdapter.Create(const ASink: IReportSink; const AOutFile: string);
begin
  inherited Create;
  FSink := ASink;
  FOutFile := AOutFile;
end;

function TBenchmarkReporterSinkAdapter.MsFromNs(const Ns: Double): QWord;
begin
  if Ns <= 0 then Exit(0);
  Result := QWord(Round(Ns / 1e6));
end;

procedure TBenchmarkReporterSinkAdapter.ReportResult(aResult: IBenchmarkResult);
var
  ms: QWord;
  nm: string;
begin
  if aResult = nil then Exit;
  // Treat each result as a case; encode path as "benchmark/<name>"
  nm := 'benchmark/' + aResult.GetName;
  // use mean per-iteration as case time for readability
  ms := MsFromNs(aResult.GetTimePerIteration(buNanoSeconds));
  FSink.CaseStart(nm);
  FSink.CaseSuccess(nm, ms);
end;

procedure TBenchmarkReporterSinkAdapter.ReportResults(const aResults: array of IBenchmarkResult);
var
  i, total, failed: Integer;
  startTick: QWord;
  msSuite: QWord;
  r: IBenchmarkResult;
begin
  total := Length(aResults);
  failed := 0;
  FSink.SuiteStart(total);
  startTick := GetTickCount64;
  for i := 0 to total-1 do
  begin
    r := aResults[i];
    ReportResult(r);
  end;
  msSuite := GetTickCount64 - startTick;
  FSink.SuiteEnd(total, failed, msSuite);
end;

procedure TBenchmarkReporterSinkAdapter.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
var
  name: string;
  ms: QWord;
begin
  if (aBaseline = nil) or (aCurrent = nil) then Exit;
  name := 'benchmark.compare/' + aBaseline.GetName + ' vs ' + aCurrent.GetName;
  // use current mean time for the case duration
  ms := MsFromNs(aCurrent.GetTimePerIteration(buNanoSeconds));
  FSink.SuiteStart(1);
  FSink.CaseStart(name);
  FSink.CaseSuccess(name, ms);
  FSink.SuiteEnd(1, 0, ms);
end;

procedure TBenchmarkReporterSinkAdapter.SetOutputFile(const aFileName: string);
begin
  FOutFile := aFileName;
  // The underlying sink handles output itself; JSON sink uses its own file
end;

procedure TBenchmarkReporterSinkAdapter.SetFormat(const aFormat: string);
begin
  // No-op for sink adapter; formatting is handled by the sink implementation
end;

function CreateSinkConsoleReporter: IBenchmarkReporter;
begin
  Result := TBenchmarkReporterSinkAdapter.Create(TReportConsoleSink.Create);
end;

function CreateSinkJsonReporter(const AFileName: string): IBenchmarkReporter;
begin
  // Ensure bit-equal schema with the default JSON reporter by forwarding
  Result := TBenchmarkReporterForwardJSON.Create(AFileName);
end;

{ TBenchmarkReporterForwardJSON }

constructor TBenchmarkReporterForwardJSON.Create(const AFileName: string);
begin
  inherited Create;
  FInner := CreateJSONReporter(AFileName);
end;

procedure TBenchmarkReporterForwardJSON.ReportResult(aResult: IBenchmarkResult);
begin
  if FInner <> nil then FInner.ReportResult(aResult);
end;

procedure TBenchmarkReporterForwardJSON.ReportResults(const aResults: array of IBenchmarkResult);
begin
  if FInner <> nil then FInner.ReportResults(aResults);
end;

procedure TBenchmarkReporterForwardJSON.ReportComparison(aBaseline, aCurrent: IBenchmarkResult);
begin
  if FInner <> nil then FInner.ReportComparison(aBaseline, aCurrent);
end;

procedure TBenchmarkReporterForwardJSON.SetOutputFile(const aFileName: string);
begin
  if FInner <> nil then FInner.SetOutputFile(aFileName);
end;

procedure TBenchmarkReporterForwardJSON.SetFormat(const aFormat: string);
begin
  if FInner <> nil then FInner.SetFormat(aFormat);
end;

end.

