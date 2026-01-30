unit fafafa.core.report.sink.intf;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils;

// Minimal report sink interface for forwarding test/bench events.
// Keep it simple to minimize coupling.

type
  IReportSink = interface
    ['{FE4D1E20-6F2B-4B2D-9B9E-5C3C6F4B7E90}']
    procedure SuiteStart(ATotal: Integer);
    procedure CaseStart(const AName: string);
    procedure CaseSuccess(const AName: string; AElapsedMs: QWord);
    procedure CaseFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure CaseSkipped(const AName: string; AElapsedMs: QWord);
    procedure SuiteEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
  end;

implementation

end.

