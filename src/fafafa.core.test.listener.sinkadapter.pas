unit fafafa.core.test.listener.sinkadapter;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, fafafa.core.test.core, fafafa.core.report.sink.intf;

type
  // Adapter: ITestListener -> IReportSink
  TTestListenerSinkAdapter = class(TInterfacedObject, ITestListener)
  private
    FSink: IReportSink;
  public
    constructor Create(const Sink: IReportSink);
    procedure OnStart(ATotal: Integer);
    procedure OnTestStart(const AName: string);
    procedure OnTestSuccess(const AName: string; AElapsedMs: QWord);
    procedure OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure OnTestSkipped(const AName: string; AElapsedMs: QWord);
    procedure OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
  end;

implementation

constructor TTestListenerSinkAdapter.Create(const Sink: IReportSink);
begin
  inherited Create;
  FSink := Sink;
end;

procedure TTestListenerSinkAdapter.OnStart(ATotal: Integer);
begin
  if FSink <> nil then FSink.SuiteStart(ATotal);
end;

procedure TTestListenerSinkAdapter.OnTestStart(const AName: string);
begin
  if FSink <> nil then FSink.CaseStart(AName);
end;

procedure TTestListenerSinkAdapter.OnTestSuccess(const AName: string; AElapsedMs: QWord);
begin
  if FSink <> nil then FSink.CaseSuccess(AName, AElapsedMs);
end;

procedure TTestListenerSinkAdapter.OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
begin
  if FSink <> nil then FSink.CaseFailure(AName, AMessage, AElapsedMs);
end;

procedure TTestListenerSinkAdapter.OnTestSkipped(const AName: string; AElapsedMs: QWord);
begin
  if FSink <> nil then FSink.CaseSkipped(AName, AElapsedMs);
end;

procedure TTestListenerSinkAdapter.OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
begin
  if FSink <> nil then FSink.SuiteEnd(ATotal, AFailed, AElapsedMs);
end;

end.

