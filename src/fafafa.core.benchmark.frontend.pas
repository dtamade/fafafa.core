unit fafafa.core.benchmark.frontend;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

interface

uses
  fafafa.core.benchmark;

type
  { 面向使用者的门面：组织 Runner 与 Reporter，不直接依赖控制台 }
  IBenchmarkFrontend = interface
    ['{C0B3B3E4-1B3A-4C3E-8C7E-6C9B6F6B7A10}']
    procedure SetReporter(const AReporter: IBenchmarkReporter);
    function GetReporter: IBenchmarkReporter;

    function RunOne(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunOne(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunMany(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;

    procedure RenderOne(const aResult: IBenchmarkResult);
    procedure RenderMany(const aResults: TBenchmarkResultArray);
  end;

function CreateConsoleFrontend: IBenchmarkFrontend;

implementation

uses
  SysUtils;

type
  TConsoleBenchmarkFrontend = class(TInterfacedObject, IBenchmarkFrontend)
  private
    FRunner: IBenchmarkRunner;
    FReporter: IBenchmarkReporter;
  public
    constructor Create;
    procedure SetReporter(const AReporter: IBenchmarkReporter);
    function GetReporter: IBenchmarkReporter;

    function RunOne(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunOne(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunMany(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;

    procedure RenderOne(const aResult: IBenchmarkResult);
    procedure RenderMany(const aResults: TBenchmarkResultArray);
  end;

{ TConsoleBenchmarkFrontend }

constructor TConsoleBenchmarkFrontend.Create;
begin
  inherited Create;
  FRunner := CreateBenchmarkRunner;
  // 默认使用 ConsoleReporter，但这属于前端职责，库层依然不直接输出
  FReporter := CreateConsoleReporter;
end;

procedure TConsoleBenchmarkFrontend.SetReporter(const AReporter: IBenchmarkReporter);
begin
  FReporter := AReporter;
end;

function TConsoleBenchmarkFrontend.GetReporter: IBenchmarkReporter;
begin
  Result := FReporter;
end;

function TConsoleBenchmarkFrontend.RunOne(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := FRunner.RunFunction(aName, aFunc, aConfig);
end;

function TConsoleBenchmarkFrontend.RunOne(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := FRunner.RunMethod(aName, aMethod, aConfig);
end;

function TConsoleBenchmarkFrontend.RunMany(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;
begin
  Result := benchmarks(aTests);
end;

procedure TConsoleBenchmarkFrontend.RenderOne(const aResult: IBenchmarkResult);
begin
  if FReporter <> nil then FReporter.ReportResult(aResult);
end;

procedure TConsoleBenchmarkFrontend.RenderMany(const aResults: TBenchmarkResultArray);
begin
  if FReporter <> nil then FReporter.ReportResults(aResults);
end;

function CreateConsoleFrontend: IBenchmarkFrontend;
begin
  Result := TConsoleBenchmarkFrontend.Create;
end;

end.

