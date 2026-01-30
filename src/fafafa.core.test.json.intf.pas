unit fafafa.core.test.json.intf;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes;

type
  IJsonReportWriter = interface
    ['{B9454C0D-6B24-4E0C-A3F0-6A4E5F2F1C77}']
    procedure BeginSuite(const AName, ATimestamp, AHostname: string);
    procedure AddTestSuccess(const AClassName, AName: string; const AElapsedSec: Double);
    procedure AddTestFailure(const AClassName, AName, AMessage: string; const AElapsedSec: Double);
    procedure AddTestSkipped(const AClassName, AName: string; const AElapsedSec: Double);
    procedure EndSuite(const ATotal, AFailures, ASkipped: Integer; const AElapsedSec: Double);
    procedure SaveToFile(const AFileName: string);
  end;

  // Optional V2: structured cleanup array support
  IJsonReportWriterV2 = interface(IJsonReportWriter)
    ['{6C6B9B23-3F2F-47E3-9F9C-2C7C7B6B8E12}']
    // When provided, writer should add a `cleanup` JSON array with items
    procedure AddTestFailureEx(const AClassName, AName, AMessage: string; const ACleanupItems: TStrings; const AElapsedSec: Double);
  end;

  TJsonWriterFactory = function(const AFileName: string): IJsonReportWriter;

implementation

end.

