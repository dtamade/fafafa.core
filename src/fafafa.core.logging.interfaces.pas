unit fafafa.core.logging.interfaces;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils;

type
  TLogLevel = (llTrace, llDebug, llInfo, llWarn, llError);

  { 结构化键值对（M1 简化：字符串值） }
  TLogAttrKind = (lakString, lakNumber, lakBool, lakNull);

  TLogAttr = record
    Key: string;
    Kind: TLogAttrKind;
    ValueStr: string;
    ValueNum: Double;
    ValueBool: Boolean;
  end;

function LogAttr(const aKey, aValue: string): TLogAttr; inline; // 兼容：字符串
  function LogAttrS(const aKey, aValue: string): TLogAttr; inline;
  function LogAttrN(const aKey: string; const aValue: Double): TLogAttr; inline;
  function LogAttrB(const aKey: string; const aValue: Boolean): TLogAttr; inline;
  function LogAttrNull(const aKey: string): TLogAttr; inline;


  type

  { 不可变日志记录接口（便于 Formatter/Sink 处理） }
  ILogRecord = interface
    ['{3E3F1E80-7C1D-4A6F-8C39-6F3BA2E9C6B1}']
    function GetTimestamp: TDateTime;
    function GetLevel: TLogLevel;
    function GetLoggerName: string;
    function GetMessageTemplate: string;
    function GetRenderedMessage: string;
    function GetAttrsCount: SizeInt;
    function GetAttr(Index: SizeInt): TLogAttr;
    function GetThreadId: PtrUInt;
    property Timestamp: TDateTime read GetTimestamp;
    property Level: TLogLevel read GetLevel;
    property LoggerName: string read GetLoggerName;
    property MessageTemplate: string read GetMessageTemplate;
    property RenderedMessage: string read GetRenderedMessage;
    property ThreadId: PtrUInt read GetThreadId;
  end;

  ILogFormatter = interface
    ['{C9B5F9B7-58E8-4C99-9F26-AD7B4E22B3B7}']
    function Format(const R: ILogRecord): string;
  end;

  ILogSink = interface
    ['{2C5E7C29-7C67-4E9E-8B25-0E2A0B4BD9D8}']
    procedure Write(const R: ILogRecord);
    procedure Flush;
  end;

  TLogSinkStats = record
    Enqueued: QWord;
    Dequeued: QWord;
    DroppedNew: QWord;
    DroppedOld: QWord;
    WaitAttempts: QWord; // dpBlock 场景下的等待尝试次数
    MaxQueueSize: QWord;
  end;

  ILogSinkStats = interface
    ['{2F6B65C1-3D3E-4E8F-8E21-1D9B6C7FA1B2}']
    function GetStats: TLogSinkStats;
  end;

  ILogFilter = interface
    ['{A1E95E7B-78B8-4F63-9D8A-2A63E8F5D1D9}']
    function Allow(const R: ILogRecord): Boolean;
  end;

  ILogger = interface
    ['{8E5D53E2-2E42-45B0-9C4C-0C6C0D1A9C31}']
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

  ILoggerFactory = interface
    ['{F9B5D1C7-0C7F-4B9C-8C9E-1B3A0A8D7E21}']
    function GetLogger(const aName: string): ILogger;
    procedure SetMinimumLevel(aLevel: TLogLevel);
    function GetMinimumLevel: TLogLevel;
  end;

  ILogEnricher = interface
    ['{B3A4F659-6A3B-4B26-9A8F-5D8E2E6C1A24}']
    procedure Enrich(var Attrs: array of TLogAttr);
  end;


implementation

function LogAttr(const aKey, aValue: string): TLogAttr; inline;
begin
  Result.Key := aKey;
  Result.Kind := lakString;
  Result.ValueStr := aValue;
  Result.ValueNum := 0;
  Result.ValueBool := False;
end;

function LogAttrS(const aKey, aValue: string): TLogAttr; inline;
begin
  Result := LogAttr(aKey, aValue);
end;

function LogAttrN(const aKey: string; const aValue: Double): TLogAttr; inline;
begin
  Result.Key := aKey;
  Result.Kind := lakNumber;
  Result.ValueStr := '';
  Result.ValueNum := aValue;
  Result.ValueBool := False;
end;

function LogAttrB(const aKey: string; const aValue: Boolean): TLogAttr; inline;
begin
  Result.Key := aKey;
  Result.Kind := lakBool;
  Result.ValueStr := '';
  Result.ValueNum := 0;
  Result.ValueBool := aValue;
end;

function LogAttrNull(const aKey: string): TLogAttr; inline;
begin
  Result.Key := aKey;
  Result.Kind := lakNull;
  Result.ValueStr := '';
  Result.ValueNum := 0;
  Result.ValueBool := False;
end;

end.

