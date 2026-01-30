unit fafafa.core.benchmark.frontend.gui;

{$codepage utf8}
{$mode objfpc}{$H+}

interface

uses
  fafafa.core.benchmark;

type
  { GUI 前端接口占位：不依赖具体图形库，仅定义约定 }
  IGUIBenchmarkFrontend = interface
    ['{0B9B6F0A-AB35-4C8C-9C8F-8E9DE8A7E7B1}']
    procedure SetReporter(const AReporter: IBenchmarkReporter);
    function GetReporter: IBenchmarkReporter;
    procedure BindOnResult(const ACallback: procedure(const R: IBenchmarkResult));
    procedure BindOnResults(const ACallback: procedure(const Arr: TBenchmarkResultArray));
  end;

{ 工厂仅占位，方便未来接入具体 GUI 框架（LCL/FMX/VCL/自绘等） }
function CreateGUIFrontendPlaceholder: IGUIBenchmarkFrontend;

implementation

uses
  SysUtils;

type
  TGUIFrontendPlaceholder = class(TInterfacedObject, IGUIBenchmarkFrontend)
  private
    FReporter: IBenchmarkReporter;
    FOnResult: procedure(const R: IBenchmarkResult);
    FOnResults: procedure(const Arr: TBenchmarkResultArray);
  public
    procedure SetReporter(const AReporter: IBenchmarkReporter);
    function GetReporter: IBenchmarkReporter;
    procedure BindOnResult(const ACallback: procedure(const R: IBenchmarkResult));
    procedure BindOnResults(const ACallback: procedure(const Arr: TBenchmarkResultArray));
  end;

procedure TGUIFrontendPlaceholder.SetReporter(const AReporter: IBenchmarkReporter);
begin
  FReporter := AReporter;
end;

function TGUIFrontendPlaceholder.GetReporter: IBenchmarkReporter;
begin
  Result := FReporter;
end;

procedure TGUIFrontendPlaceholder.BindOnResult(const ACallback: procedure(const R: IBenchmarkResult));
begin
  FOnResult := ACallback;
end;

procedure TGUIFrontendPlaceholder.BindOnResults(const ACallback: procedure(const Arr: TBenchmarkResultArray));
begin
  FOnResults := ACallback;
end;

function CreateGUIFrontendPlaceholder: IGUIBenchmarkFrontend;
begin
  Result := TGUIFrontendPlaceholder.Create;
end;

end.

