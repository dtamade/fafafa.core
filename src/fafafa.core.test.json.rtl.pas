unit fafafa.core.test.json.rtl;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses SysUtils, Classes, DateUtils, fpjson, jsonparser, fafafa.core.test.json.intf;

type
  TRtlJsonReportWriter = class(TInterfacedObject, IJsonReportWriter)
  protected
    FRoot: TJSONObject;
    FTests: TJSONArray;
    FOutFile: string;
    FName: string;
    FTimestamp: string;
    FHostname: string;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;
    procedure BeginSuite(const AName, ATimestamp, AHostname: string);
    procedure AddTestSuccess(const AClassName, AName: string; const AElapsedSec: Double);
    procedure AddTestFailure(const AClassName, AName, AMessage: string; const AElapsedSec: Double);
    procedure AddTestSkipped(const AClassName, AName: string; const AElapsedSec: Double);
    procedure EndSuite(const ATotal, AFailures, ASkipped: Integer; const AElapsedSec: Double);
    procedure SaveToFile(const AFileName: string);
  end;

function CreateRtlJsonWriter(const AFileName: string): IJsonReportWriter;
function CreateRtlJsonWriterV2(const AFileName: string): IJsonReportWriter;

implementation

function FormatCleanupTimestampRFC3339(const ALocalNow: TDateTime): string;
{$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS_TZ_LOCAL_OFFSET}
const
  BASE_FMT_SEC = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss';
  BASE_FMT_MS  = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz';
{$ELSE}
const
  BASE_FMT_SEC = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"Z"';
  BASE_FMT_MS  = 'yyyy"-"mm"-"dd"T"hh":"nn":"ss"."zzz"Z"';
{$ENDIF}
var
  dt: TDateTime;
{$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS_TZ_LOCAL_OFFSET}
  offsetMin, absMin, hh, mm: Integer;
  sign: Char;
{$ENDIF}
begin
{$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS_TZ_LOCAL_OFFSET}
  // 本地偏移：不转换到 UTC，输出 +HH:MM/-HH:MM
  dt := ALocalNow;
  {$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS_PRECISION_SEC}
  Result := FormatDateTime(BASE_FMT_SEC, dt);
  {$ELSE}
  Result := FormatDateTime(BASE_FMT_MS, dt);
  {$ENDIF}
  offsetMin := GetLocalTimeOffset();
  if offsetMin < 0 then sign := '-' else sign := '+';
  absMin := Abs(offsetMin);
  hh := absMin div 60; mm := absMin mod 60;
  Result := Result + Format('%s%.2d:%.2d', [sign, hh, mm]);
{$ELSE}
  // UTC：转换到 UTC 并以 Z 结尾
  dt := IncMinute(ALocalNow, -GetLocalTimeOffset());
  {$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS_PRECISION_SEC}
  Result := FormatDateTime(BASE_FMT_SEC, dt);
  {$ELSE}
  Result := FormatDateTime(BASE_FMT_MS, dt);
  {$ENDIF}
{$ENDIF}
end;


type
  TRtlJsonReportWriterV2 = class(TRtlJsonReportWriter, IJsonReportWriterV2)
  public
    procedure AddTestFailureEx(const AClassName, AName, AMessage: string; const ACleanupItems: TStrings; const AElapsedSec: Double);
  end;

constructor TRtlJsonReportWriter.Create(const AFileName: string);
begin
  inherited Create;
  FOutFile := AFileName;
  FRoot := TJSONObject.Create;
  FTests := nil;
end;

destructor TRtlJsonReportWriter.Destroy;
begin
  // FRoot owns FTests via Add(), so only free FRoot
  FRoot.Free;
  inherited Destroy;
end;

procedure TRtlJsonReportWriter.BeginSuite(const AName, ATimestamp, AHostname: string);
begin
  FName := AName; FTimestamp := ATimestamp; FHostname := AHostname;
  FRoot.Clear;
  // create a fresh tests array for this suite
  FTests := TJSONArray.Create;
  FRoot.Add('name', AName);
  FRoot.Add('timestamp', ATimestamp);
  FRoot.Add('hostname', AHostname);
  FRoot.Add('tests', FTests);
end;

procedure TRtlJsonReportWriter.AddTestSuccess(const AClassName, AName: string; const AElapsedSec: Double);
var o: TJSONObject;
begin
  o := TJSONObject.Create;
  o.Add('classname', AClassName);
  o.Add('name', AName);
  o.Add('time', AElapsedSec);
  o.Add('status', 'passed');
  FTests.Add(o);
end;

procedure TRtlJsonReportWriter.AddTestFailure(const AClassName, AName, AMessage: string; const AElapsedSec: Double);
var o: TJSONObject;
begin
  o := TJSONObject.Create;
  o.Add('classname', AClassName);
  o.Add('name', AName);
  o.Add('time', AElapsedSec);
  o.Add('status', 'failed');
  o.Add('message', AMessage);
  FTests.Add(o);
end;

procedure TRtlJsonReportWriter.AddTestSkipped(const AClassName, AName: string; const AElapsedSec: Double);
var o: TJSONObject;
begin
  o := TJSONObject.Create;
  o.Add('classname', AClassName);
  o.Add('name', AName);
  o.Add('time', AElapsedSec);
  o.Add('status', 'skipped');
  FTests.Add(o);
end;

procedure TRtlJsonReportWriter.EndSuite(const ATotal, AFailures, ASkipped: Integer; const AElapsedSec: Double);
begin
  FRoot.Add('total', ATotal);
  FRoot.Add('failures', AFailures);
  FRoot.Add('skipped', ASkipped);
  FRoot.Add('elapsed', AElapsedSec);
end;

procedure TRtlJsonReportWriter.SaveToFile(const AFileName: string);
var sl: TStringList;
begin
  sl := TStringList.Create;
  try
    sl.Text := FRoot.FormatJSON();
    if AFileName <> '' then sl.SaveToFile(AFileName)
    else if FOutFile <> '' then sl.SaveToFile(FOutFile);
  finally
    sl.Free;
  end;
end;

{ TRtlJsonReportWriterV2 }
procedure TRtlJsonReportWriterV2.AddTestFailureEx(const AClassName, AName, AMessage: string; const ACleanupItems: TStrings; const AElapsedSec: Double);
var o, arrItem: TJSONObject; arr: TJSONArray; i: Integer;
begin
  o := TJSONObject.Create;
  o.Add('classname', AClassName);
  o.Add('name', AName);
  o.Add('time', AElapsedSec);
  o.Add('status', 'failed');
  o.Add('message', AMessage);
  if Assigned(ACleanupItems) and (ACleanupItems.Count > 0) then
  begin
    arr := TJSONArray.Create;
    for i := 0 to ACleanupItems.Count-1 do
    begin
      arrItem := TJSONObject.Create;
      arrItem.Add('text', ACleanupItems[i]);
      {$IFDEF FAFAFA_TEST_JSON_CLEANUP_TS}
      // 可选：记录每个 cleanup 的时间戳（RFC3339，可配置：UTC/本地偏移、秒/毫秒）
      arrItem.Add('ts', FormatCleanupTimestampRFC3339(Now));
      {$ENDIF}
      arr.Add(arrItem);
    end;
    // find tests array and add extra field
    if (FRoot <> nil) and (FTests <> nil) then
      o.Add('cleanup', arr)
    else
      arr.Free;
  end;
  FTests.Add(o);
end;

function CreateRtlJsonWriterV2(const AFileName: string): IJsonReportWriter;
begin
  Result := TRtlJsonReportWriterV2.Create(AFileName);
end;

function CreateRtlJsonWriter(const AFileName: string): IJsonReportWriter;
begin
  Result := TRtlJsonReportWriter.Create(AFileName);
end;

end.

