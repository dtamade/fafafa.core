unit Test_fafafa_core_logging_filter_enricher;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.logging.sinks.textsink, fafafa.core.logging.formatters.text,
  fafafa.core.io;

type
  // 简易字符串 sink（测试用）：收集文本
  TStringSink = class(TInterfacedObject, ITextSink)
  public
    Value: string;
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

  TLevelPrefixFilter = class(TInterfacedObject, ILogFilter)
  private
    FMin: TLogLevel; FPrefix: string;
  public
    constructor Create(AMin: TLogLevel; const APrefix: string);
    function Allow(const R: ILogRecord): Boolean;
  end;

  TTraceIdEnricher = class(TInterfacedObject, ILogEnricher)
  public
    procedure Enrich(var Attrs: array of TLogAttr);
  end;

  TTestCase_FilterEnricher = class(TTestCase)
  published
    procedure Test_Filter_Drops_NonMatching;
    procedure Test_Enricher_Fills_TraceId;
  end;

implementation

uses
  Test_helpers_io;

{ TStringSink }
procedure TStringSink.WriteLine(const S: string);
begin
  Value := Value + S + LineEnding;
end;

procedure TStringSink.Flush;
begin
end;

{ TLevelPrefixFilter }
constructor TLevelPrefixFilter.Create(AMin: TLogLevel; const APrefix: string);
begin
  inherited Create;
  FMin := AMin; FPrefix := APrefix;
end;

function TLevelPrefixFilter.Allow(const R: ILogRecord): Boolean;
begin
  Result := (Ord(R.Level) >= Ord(FMin)) and
            ((FPrefix = '') or (Pos(FPrefix + '.', R.LoggerName) = 1) or (R.LoggerName = FPrefix));
end;

{ TTraceIdEnricher }
procedure TTraceIdEnricher.Enrich(var Attrs: array of TLogAttr);
var i: Integer;
begin
  for i := 0 to High(Attrs) do
    if SameText(Attrs[i].Key, 'trace_id') and (Attrs[i].Kind = lakNull) then
    begin
      Attrs[i].Kind := lakString;
      Attrs[i].ValueStr := 'unit-test-trace';
      Exit;
    end;
end;

procedure TTestCase_FilterEnricher.Test_Filter_Drops_NonMatching;
var
  S: TStringSink; L: ILogger;
begin
  // 收集到字符串 sink，避免控制台干扰
  S := TStringSink.Create;
  Logging.SetRootSink(TTextSinkLogSink.Create(S, TTextLogFormatter.Create));
  Logging.SetMinimumLevel(llInfo);
  Logging.SetFilter(TLevelPrefixFilter.Create(llInfo, 'svc'));
  Logging.SetEnricher(nil);

  GetLogger('app').Info('should drop', []);
  L := GetLogger('svc.api');
  L.Info('keep', []);
  Logging.GetRootSink.Flush;

  AssertTrue(Pos('keep', S.Value) > 0);
  AssertTrue(Pos('should drop', S.Value) = 0);
end;

procedure TTestCase_FilterEnricher.Test_Enricher_Fills_TraceId;
var
  S: TStringSink; L: ILogger;
begin
  S := TStringSink.Create;
  Logging.SetRootSink(TTextSinkLogSink.Create(S, TTextLogFormatter.Create));
  Logging.SetMinimumLevel(llInfo);
  Logging.SetFilter(nil);
  Logging.SetEnricher(TTraceIdEnricher.Create);

  L := GetLogger('svc');
  L.WithAttrs([LogAttrNull('trace_id')]).Info('x', []);
  Logging.GetRootSink.Flush;

  AssertTrue(Pos('trace_id=unit-test-trace', S.Value) > 0);
end;

initialization
  RegisterTest(TTestCase_FilterEnricher);
end.

