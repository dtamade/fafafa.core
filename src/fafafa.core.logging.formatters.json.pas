unit fafafa.core.logging.formatters.json;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils, StrUtils,
  fafafa.core.logging.interfaces;

type
  TJsonLogFormatter = class(TInterfacedObject, ILogFormatter)
  private
    FUseUTC: Boolean;
    function EscapeJsonString(const S: string): string;
    function LevelToStr(aLevel: TLogLevel): string;
    function FormatTs(const DT: TDateTime): string;
  public
    constructor Create(AUseUTC: Boolean = False);
    function Format(const R: ILogRecord): string;
  end;

implementation

constructor TJsonLogFormatter.Create(AUseUTC: Boolean);
begin
  inherited Create;
  FUseUTC := AUseUTC;
end;

function TJsonLogFormatter.EscapeJsonString(const S: string): string;
var
  I: Integer;
  Ch: Char;
begin
  Result := '';
  SetLength(Result, 0);
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    case Ch of
      '"': Result += '\"';
      '\': Result += '\\';
      #8:   Result += '\b';
      #9:   Result += '\t';
      #10:  Result += '\n';
      #12:  Result += '\f';
      #13:  Result += '\r';
    else
      if Ord(Ch) < 32 then
        Result += '\u' + IntToHex(Ord(Ch), 4)
      else
        Result += Ch;
    end;
  end;
end;

function TJsonLogFormatter.LevelToStr(aLevel: TLogLevel): string;
begin
  case aLevel of
    llTrace: Result := 'trace';
    llDebug: Result := 'debug';
    llInfo:  Result := 'info';
    llWarn:  Result := 'warn';
    llError: Result := 'error';
  end;
end;

function TJsonLogFormatter.FormatTs(const DT: TDateTime): string;
begin
  if FUseUTC then
    Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(DT))
  else
    Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss.zzz', DT);
end;

function TJsonLogFormatter.Format(const R: ILogRecord): string;
var
  I, N: SizeInt;
  TS: string;
begin
  // 固定字段顺序：time, level, logger, message, attrs, threadId
  TS := FormatTs(R.Timestamp);
  Result := '{' +
            '"time":"' + EscapeJsonString(TS) + '",' +
            '"level":"' + LevelToStr(R.Level) + '",' +
            '"logger":"' + EscapeJsonString(R.LoggerName) + '",' +
            '"message":"' + EscapeJsonString(R.RenderedMessage) + '",' +
            '"attrs":{';
  N := R.GetAttrsCount;
  for I := 0 to N - 1 do
  begin
    if I > 0 then Result += ',';
    // 根据属性类型输出 JSON 原生类型
    case R.GetAttr(I).Kind of
      lakString: Result += '"' + EscapeJsonString(R.GetAttr(I).Key) + '":"' + EscapeJsonString(R.GetAttr(I).ValueStr) + '"';
      lakNumber: Result += '"' + EscapeJsonString(R.GetAttr(I).Key) + '":' + StringReplace(FloatToStr(R.GetAttr(I).ValueNum), ',', '.', []);
      lakBool:   Result += '"' + EscapeJsonString(R.GetAttr(I).Key) + '":' + (IfThen(R.GetAttr(I).ValueBool, 'true', 'false'));
      lakNull:   Result += '"' + EscapeJsonString(R.GetAttr(I).Key) + '":null';
    end;
  end;
  Result += '},"threadId":' + IntToStr(R.ThreadId) + '}';
end;

end.

