unit fafafa.core.benchmark.frontend.json;

{$codepage utf8}
{$mode objfpc}{$H+}
{$modeswitch anonymousfunctions}

interface

uses
  fafafa.core.benchmark,
  fafafa.core.benchmark.frontend;

type
  { JSON 前端：封装 Runner + JSON Reporter，默认写入文件（可选） }
  IJSONBenchmarkFrontend = interface(IBenchmarkFrontend)
    ['{9B3C7A9B-6B3D-4BE0-9A7B-1C9A0B1D7E31}']
    procedure SetOutputFile(const AFile: string);
    function GetOutputFile: string;
  end;

function CreateJSONFrontend(const AOutputFile: string = ''): IJSONBenchmarkFrontend;

implementation

uses
  SysUtils;

type
  TJSONBenchmarkFrontend = class(TInterfacedObject, IBenchmarkFrontend, IJSONBenchmarkFrontend)
  private
    FRunner: IBenchmarkRunner;
    FReporter: IBenchmarkReporter;
    FOutputFile: string;
  public
    constructor Create(const AOut: string);
    procedure SetReporter(const AReporter: IBenchmarkReporter);
    function GetReporter: IBenchmarkReporter;

    function RunOne(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunOne(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult; overload;
    function RunMany(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;

    procedure RenderOne(const aResult: IBenchmarkResult);
    procedure RenderMany(const aResults: TBenchmarkResultArray);

    // IJSONBenchmarkFrontend
    procedure SetOutputFile(const AFile: string);
    function GetOutputFile: string;
  end;

{ TJSONBenchmarkFrontend }

constructor TJSONBenchmarkFrontend.Create(const AOut: string);
begin
  inherited Create;
  FRunner := CreateBenchmarkRunner;
  FReporter := CreateJSONReporter(AOut);
  FOutputFile := AOut;
  if (FReporter <> nil) and (AOut <> '') then
    FReporter.SetOutputFile(AOut);
end;

procedure TJSONBenchmarkFrontend.SetReporter(const AReporter: IBenchmarkReporter);
begin
  FReporter := AReporter;
end;

function TJSONBenchmarkFrontend.GetReporter: IBenchmarkReporter;
begin
  Result := FReporter;
end;

function TJSONBenchmarkFrontend.RunOne(const aName: string; aFunc: TBenchmarkFunction; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := FRunner.RunFunction(aName, aFunc, aConfig);
end;

function TJSONBenchmarkFrontend.RunOne(const aName: string; aMethod: TBenchmarkMethod; const aConfig: TBenchmarkConfig): IBenchmarkResult;
begin
  Result := FRunner.RunMethod(aName, aMethod, aConfig);
end;

function TJSONBenchmarkFrontend.RunMany(const aTests: array of TQuickBenchmark): TBenchmarkResultArray;
begin
  Result := benchmarks(aTests);
end;

procedure TJSONBenchmarkFrontend.RenderOne(const aResult: IBenchmarkResult);
begin
  if FReporter <> nil then FReporter.ReportResult(aResult);
end;

procedure TJSONBenchmarkFrontend.RenderMany(const aResults: TBenchmarkResultArray);
begin
  if FReporter <> nil then FReporter.ReportResults(aResults);
end;

procedure TJSONBenchmarkFrontend.SetOutputFile(const AFile: string);
begin
  FOutputFile := AFile;
  if FReporter <> nil then FReporter.SetOutputFile(AFile);
end;

function TJSONBenchmarkFrontend.GetOutputFile: string;
begin
  Result := FOutputFile;
end;

function CreateJSONFrontend(const AOutputFile: string): IJSONBenchmarkFrontend;
begin
  Result := TJSONBenchmarkFrontend.Create(AOutputFile);
end;

end.

