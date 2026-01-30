unit fafafa.core.logging;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.logging.interfaces;

type
  { 全局 Facade 的最小实现骨架 + 默认 Simple 实现 }
  IGlobalLoggerConfig = interface
    ['{4F2F57C6-6B75-4F77-9D55-8F2E8F1B1A21}']
    procedure SetFactory(const aFactory: ILoggerFactory);
    function GetFactory: ILoggerFactory;
    procedure SetRootSink(const aSink: ILogSink);
    function GetRootSink: ILogSink;
    procedure SetFormatter(const aFormatter: ILogFormatter);
    function GetFormatter: ILogFormatter;
    procedure SetMinimumLevel(aLevel: TLogLevel);
    function GetMinimumLevel: TLogLevel;
    procedure SetFilter(const AFilter: ILogFilter);
    function GetFilter: ILogFilter;
    procedure SetEnricher(const AEnricher: ILogEnricher);
    function GetEnricher: ILogEnricher;
  end;

function Logging: IGlobalLoggerConfig;
function GetLogger(const aName: string): ILogger;
// 便捷：启用异步根 Sink（如未提供则使用 Console+Text）
procedure EnableAsyncRoot(aCapacity: Integer = 1024; aBatchSize: Integer = 64);
// 便捷：启用异步 + 滚动文件根 Sink（TextFormatter）
procedure EnableAsyncRollingFileRoot(const APath: string; aMaxBytes: QWord; aCapacity: Integer = 4096; aBatchSize: Integer = 128);
// 便捷：Console + RollingFile 的复合根 Sink（Rolling 异步包装）
procedure EnableConsoleAndRollingRoot(const APath: string; aMaxBytes: QWord; aCapacity: Integer = 4096; aBatchSize: Integer = 128);
// 便捷：异步 + 按日滚动文件根（保留 MaxFiles）
procedure EnableAsyncDailyRollingFileRoot(const APath: string; aMaxFiles: Integer = 7; aCapacity: Integer = 4096; aBatchSize: Integer = 128); overload;
procedure EnableAsyncDailyRollingFileRoot(const APath: string; aMaxFiles: Integer; aMaxDays: Integer; aCapacity: Integer; aBatchSize: Integer); overload;
// 查询根 Sink 统计（如果支持）
function TryGetRootSinkStats(out AStats: TLogSinkStats): Boolean;

implementation

uses DateUtils, fafafa.core.logging.sinks.console, fafafa.core.logging.formatters.text,
  fafafa.core.logging.sinks.async, fafafa.core.logging.sinks.textsink, fafafa.core.io,
  fafafa.core.logging.sinks.rollingfile, fafafa.core.logging.sinks.composite,
  fafafa.core.logging.sinks.rollingfile.daily
  {$IFDEF WINDOWS}, Windows{$ENDIF};

type
  { 日志记录对象（不可变快照） }
  TLogRecordImpl = class(TInterfacedObject, ILogRecord)
  private
    FTimestamp: TDateTime;
    FLevel: TLogLevel;
    FLoggerName: string;
    FMsgTemplate: string;
    FRendered: string;
    FThreadId: PtrUInt;
    FAttrs: array of TLogAttr;
  private
    function GetTimestamp: TDateTime; inline;
    function GetLevel: TLogLevel; inline;
    function GetLoggerName: string; inline;
    function GetMessageTemplate: string; inline;
    function GetRenderedMessage: string; inline;
    function GetAttrsCount: SizeInt; inline;
    function GetAttr(Index: SizeInt): TLogAttr; inline;
    function GetThreadId: PtrUInt; inline;
  public
    constructor Create(aLevel: TLogLevel; const aName, aTpl: string; const aArgs: array of const; const aAttrs: array of TLogAttr);
  end;

  { 简单 Logger 与工厂 }
  TSimpleLogger = class(TInterfacedObject, ILogger)
  private
    FName: string;
    FAttrs: array of TLogAttr; // 上下文扩展 Attrs
  public
    constructor Create(const aName: string; const aCtxAttrs: array of TLogAttr);
    procedure Log(aLevel: TLogLevel; const aMsg: string; const aArgs: array of const);
    procedure LogAttrs(aLevel: TLogLevel; const aMsg: string; const aArgs: array of const; const aAttrs: array of TLogAttr);
    procedure Trace(const aMsg: string; const aArgs: array of const);
    procedure Debug(const aMsg: string; const aArgs: array of const);
    procedure Info(const aMsg: string; const aArgs: array of const);
    procedure Warn(const aMsg: string; const aArgs: array of const);
    procedure Error(const aMsg: string; const aArgs: array of const);
    function WithAttrs(const aAttrs: array of TLogAttr): ILogger;
    function Name: string;
  end;

  TSimpleLoggerFactory = class(TInterfacedObject, ILoggerFactory)
  private
    FMinLevel: TLogLevel;
  public
    constructor Create;
    function GetLogger(const aName: string): ILogger;
    procedure SetMinimumLevel(aLevel: TLogLevel);
    function GetMinimumLevel: TLogLevel;
  end;

  TGlobalLoggerConfig = class(TInterfacedObject, IGlobalLoggerConfig)
  private
    FFilter: ILogFilter;
    FEnricher: ILogEnricher;
    FLock: ILock;
    FFactory: ILoggerFactory;
    FRootSink: ILogSink;
    FFormatter: ILogFormatter;
    FMinLevel: TLogLevel;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetFactory(const aFactory: ILoggerFactory);
    function GetFactory: ILoggerFactory;
    procedure SetRootSink(const aSink: ILogSink);
    function GetRootSink: ILogSink;
    procedure SetFormatter(const aFormatter: ILogFormatter);
    function GetFormatter: ILogFormatter;
    procedure SetMinimumLevel(aLevel: TLogLevel);
    function GetMinimumLevel: TLogLevel;
    procedure SetFilter(const AFilter: ILogFilter);
    function GetFilter: ILogFilter;
    procedure SetEnricher(const AEnricher: ILogEnricher);
    function GetEnricher: ILogEnricher;
  end;

var
  GConfig: IGlobalLoggerConfig = nil;

function Logging: IGlobalLoggerConfig;
begin
  if GConfig = nil then
  begin
    GConfig := TGlobalLoggerConfig.Create;
    // 默认配置（M1）：Simple 工厂 + 控制台 Sink + 文本格式化 + 最小级别 Info
    GConfig.SetFactory(TSimpleLoggerFactory.Create);
    GConfig.SetRootSink(TConsoleLogSink.Create);
    GConfig.SetFormatter(TTextLogFormatter.Create);
    GConfig.SetMinimumLevel(llInfo);
  end;
  Result := GConfig;
end;

function GetLogger(const aName: string): ILogger;
var LFactory: ILoggerFactory;
begin
  LFactory := Logging.GetFactory;
  if LFactory <> nil then
    Exit(LFactory.GetLogger(aName));
  Result := nil;
end;

procedure EnableAsyncRoot(aCapacity: Integer; aBatchSize: Integer);
var
  InnerText: ITextSink;
  Inner: ILogSink;
  Async: ILogSink;
  Fmt: ILogFormatter;
begin
  InnerText := TConsoleSink.Create;
  Fmt := TTextLogFormatter.Create;
  Inner := TTextSinkLogSink.Create(InnerText, Fmt);
  Async := TAsyncLogSink.Create(Inner, aCapacity, aBatchSize, ldpDropOld);
  Logging.SetFormatter(Fmt);
  Logging.SetRootSink(Async);
end;

procedure EnableAsyncRollingFileRoot(const APath: string; aMaxBytes: QWord; aCapacity: Integer; aBatchSize: Integer);
var
  InnerText: ITextSink;
  Inner: ILogSink;
  Async: ILogSink;
  Fmt: ILogFormatter;
begin
  // Text -> RollingFile -> Async
  Fmt := TTextLogFormatter.Create;
  InnerText := TRollingTextFileSink.Create(APath, aMaxBytes, 0, 0);
  Inner := TTextSinkLogSink.Create(InnerText, Fmt);
  Async := TAsyncLogSink.Create(Inner, aCapacity, aBatchSize, ldpDropOld);
  Logging.SetFormatter(Fmt);
  Logging.SetRootSink(Async);
end;

procedure EnableConsoleAndRollingRoot(const APath: string; aMaxBytes: QWord; aCapacity: Integer; aBatchSize: Integer);
var
  ConsoleSink: ILogSink;
  FileAsyncSink: ILogSink;
  Comp: ILogSink;
  Fmt: ILogFormatter;
begin
  // Console(Text) + (Text -> RollingFile -> Async)
  Fmt := TTextLogFormatter.Create;
  ConsoleSink := TTextSinkLogSink.Create(TConsoleSink.Create, Fmt);
  FileAsyncSink := TAsyncLogSink.Create(
                    TTextSinkLogSink.Create(TRollingTextFileSink.Create(APath, aMaxBytes, 0, 0), Fmt),
                    aCapacity, aBatchSize, ldpDropOld);
  Comp := TCompositeLogSink.Create([ConsoleSink, FileAsyncSink]);
  Logging.SetFormatter(Fmt);
  Logging.SetRootSink(Comp);
end;

procedure EnableAsyncDailyRollingFileRoot(const APath: string; aMaxFiles: Integer; aCapacity: Integer; aBatchSize: Integer);
begin
  EnableAsyncDailyRollingFileRoot(APath, aMaxFiles, 0, aCapacity, aBatchSize);
end;

procedure EnableAsyncDailyRollingFileRoot(const APath: string; aMaxFiles: Integer; aMaxDays: Integer; aCapacity: Integer; aBatchSize: Integer);
var
  InnerText: ITextSink;
  Inner: ILogSink;
  Async: ILogSink;
  Fmt: ILogFormatter;
begin
  Fmt := TTextLogFormatter.Create;
  InnerText := TRollingDailyTextFileSink.Create(APath, aMaxFiles, nil, aMaxDays);
  Inner := TTextSinkLogSink.Create(InnerText, Fmt);
  Async := TAsyncLogSink.Create(Inner, aCapacity, aBatchSize, ldpDropOld);
  Logging.SetFormatter(Fmt);
  Logging.SetRootSink(Async);
end;

{ TLogRecordImpl }
constructor TLogRecordImpl.Create(aLevel: TLogLevel; const aName, aTpl: string; const aArgs: array of const; const aAttrs: array of TLogAttr);
var
  I, N: SizeInt;
begin
  FTimestamp := Now;
  FLevel := aLevel;
  FLoggerName := aName;
  FMsgTemplate := aTpl;
  try
    FRendered := SysUtils.Format(aTpl, aArgs);
  except
    on E: Exception do
      FRendered := aTpl + ' (format-error: ' + E.ClassName + ': ' + E.Message + ')';
  end;
  {$IFDEF WINDOWS}
  FThreadId := PtrUInt(Windows.GetCurrentThreadId);
  {$ELSE}
  FThreadId := PtrUInt(GetThreadID);
  {$ENDIF}
  N := Length(aAttrs);
  SetLength(FAttrs, N);
  for I := 0 to N - 1 do FAttrs[I] := aAttrs[I];
end;

function TLogRecordImpl.GetTimestamp: TDateTime; begin Result := FTimestamp; end;
function TLogRecordImpl.GetLevel: TLogLevel; begin Result := FLevel; end;
function TLogRecordImpl.GetLoggerName: string; begin Result := FLoggerName; end;
function TLogRecordImpl.GetMessageTemplate: string; begin Result := FMsgTemplate; end;
function TLogRecordImpl.GetRenderedMessage: string; begin Result := FRendered; end;
function TLogRecordImpl.GetAttrsCount: SizeInt; begin Result := Length(FAttrs); end;
function TLogRecordImpl.GetAttr(Index: SizeInt): TLogAttr; begin Result := FAttrs[Index]; end;
function TLogRecordImpl.GetThreadId: PtrUInt; begin Result := FThreadId; end;

{ TSimpleLogger }
constructor TSimpleLogger.Create(const aName: string; const aCtxAttrs: array of TLogAttr);
var I,N: SizeInt;
begin
  inherited Create;
  FName := aName;
  N := Length(aCtxAttrs);
  SetLength(FAttrs, N);
  for I := 0 to N - 1 do FAttrs[I] := aCtxAttrs[I];
end;

procedure TSimpleLogger.Log(aLevel: TLogLevel; const aMsg: string; const aArgs: array of const);
begin
  LogAttrs(aLevel, aMsg, aArgs, []);
end;

procedure TSimpleLogger.LogAttrs(aLevel: TLogLevel; const aMsg: string; const aArgs: array of const; const aAttrs: array of TLogAttr);
var
  LMin: TLogLevel;
  LAll: array of TLogAttr;
  I, N1, N2: SizeInt;
  R: ILogRecord;
  S: ILogSink;
  Flt: ILogFilter;
  Enr: ILogEnricher;
begin
  LMin := Logging.GetMinimumLevel;
  if Ord(aLevel) < Ord(LMin) then Exit;

  // 合并上下文 Attrs + 本次 Attrs
  N1 := Length(FAttrs); N2 := Length(aAttrs);
  SetLength(LAll, N1 + N2);
  for I := 0 to N1 - 1 do LAll[I] := FAttrs[I];
  for I := 0 to N2 - 1 do LAll[N1 + I] := aAttrs[I];

  // 过滤与增强（全局配置）
  Flt := Logging.GetFilter;
  if (Flt <> nil) then
  begin
    R := TLogRecordImpl.Create(aLevel, FName, aMsg, aArgs, LAll);
    if not Flt.Allow(R) then Exit;
  end;
  Enr := Logging.GetEnricher;
  if (Enr <> nil) then Enr.Enrich(LAll);

  R := TLogRecordImpl.Create(aLevel, FName, aMsg, aArgs, LAll);

  S := Logging.GetRootSink;
  if S <> nil then S.Write(R);
end;

procedure TSimpleLogger.Trace(const aMsg: string; const aArgs: array of const);
begin Log(llTrace, aMsg, aArgs); end;
procedure TSimpleLogger.Debug(const aMsg: string; const aArgs: array of const);
begin Log(llDebug, aMsg, aArgs); end;
procedure TSimpleLogger.Info(const aMsg: string; const aArgs: array of const);
begin Log(llInfo, aMsg, aArgs); end;
procedure TSimpleLogger.Warn(const aMsg: string; const aArgs: array of const);
begin Log(llWarn, aMsg, aArgs); end;
procedure TSimpleLogger.Error(const aMsg: string; const aArgs: array of const);
begin Log(llError, aMsg, aArgs); end;

function TSimpleLogger.WithAttrs(const aAttrs: array of TLogAttr): ILogger;
var
  N1, N2, I: SizeInt;
  NewCtx: array of TLogAttr;
begin
  N1 := Length(FAttrs); N2 := Length(aAttrs);
  SetLength(NewCtx, N1 + N2);
  for I := 0 to N1 - 1 do NewCtx[I] := FAttrs[I];
  for I := 0 to N2 - 1 do NewCtx[N1 + I] := aAttrs[I];
  Result := TSimpleLogger.Create(FName, NewCtx);
end;

function TSimpleLogger.Name: string;
begin
  Result := FName;
end;

{ TSimpleLoggerFactory }
constructor TSimpleLoggerFactory.Create;
begin
  inherited Create;
  FMinLevel := llInfo;
end;

function TSimpleLoggerFactory.GetLogger(const aName: string): ILogger;
begin
  Result := TSimpleLogger.Create(aName, []);
end;

procedure TSimpleLoggerFactory.SetMinimumLevel(aLevel: TLogLevel);
begin
  FMinLevel := aLevel;
  Logging.SetMinimumLevel(aLevel);
end;

function TSimpleLoggerFactory.GetMinimumLevel: TLogLevel;
begin
  Result := FMinLevel;
end;

{ TGlobalLoggerConfig }
constructor TGlobalLoggerConfig.Create;
begin
  inherited Create;
  FLock := TMutex.Create;
  FMinLevel := llInfo;
end;

destructor TGlobalLoggerConfig.Destroy;
begin
  FLock := nil;
  inherited Destroy;
end;

procedure TGlobalLoggerConfig.SetFactory(const aFactory: ILoggerFactory);
begin FLock.Acquire; try FFactory := aFactory; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetFactory: ILoggerFactory;
begin FLock.Acquire; try Result := FFactory; finally FLock.Release; end; end;
procedure TGlobalLoggerConfig.SetRootSink(const aSink: ILogSink);
begin FLock.Acquire; try FRootSink := aSink; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetRootSink: ILogSink;
begin FLock.Acquire; try Result := FRootSink; finally FLock.Release; end; end;
procedure TGlobalLoggerConfig.SetFilter(const AFilter: ILogFilter);
begin FLock.Acquire; try FFilter := AFilter; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetFilter: ILogFilter;
begin FLock.Acquire; try Result := FFilter; finally FLock.Release; end; end;
procedure TGlobalLoggerConfig.SetEnricher(const AEnricher: ILogEnricher);
begin FLock.Acquire; try FEnricher := AEnricher; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetEnricher: ILogEnricher;
begin FLock.Acquire; try Result := FEnricher; finally FLock.Release; end; end;

procedure TGlobalLoggerConfig.SetFormatter(const aFormatter: ILogFormatter);
begin FLock.Acquire; try FFormatter := aFormatter; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetFormatter: ILogFormatter;
begin FLock.Acquire; try Result := FFormatter; finally FLock.Release; end; end;
procedure TGlobalLoggerConfig.SetMinimumLevel(aLevel: TLogLevel);
begin FLock.Acquire; try FMinLevel := aLevel; finally FLock.Release; end; end;
function TGlobalLoggerConfig.GetMinimumLevel: TLogLevel;
begin FLock.Acquire; try Result := FMinLevel; finally FLock.Release; end; end;

function TryGetRootSinkStats(out AStats: TLogSinkStats): Boolean;
var S: ILogSink; StatsIntf: ILogSinkStats;
begin
  Result := False;
  FillChar(AStats, SizeOf(AStats), 0);
  S := Logging.GetRootSink;
  if (S <> nil) and (S.QueryInterface(ILogSinkStats, StatsIntf) = 0) then
  begin
    AStats := StatsIntf.GetStats;
    Exit(True);
  end;
end;

end.

