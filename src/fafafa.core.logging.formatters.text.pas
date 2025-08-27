unit fafafa.core.logging.formatters.text;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, DateUtils,
  fafafa.core.logging.interfaces;

type
  TTextLogFormatter = class(TInterfacedObject, ILogFormatter)
  public
    function Format(const R: ILogRecord): string;
  end;

implementation

function LevelToShortStr(aLevel: TLogLevel): string; inline;
begin
  case aLevel of
    llTrace: Result := 'TRC';
    llDebug: Result := 'DBG';
    llInfo:  Result := 'INF';
    llWarn:  Result := 'WRN';
    llError: Result := 'ERR';
  end;
end;

function TTextLogFormatter.Format(const R: ILogRecord): string;
var
  I, N: SizeInt;
  AttrsText: string;
begin
  // 基本前缀：时间、级别、logger 名称
  Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss.zzz', R.Timestamp) +
            ' [' + LevelToShortStr(R.Level) + '] ' + R.LoggerName + ' - ' +
            R.RenderedMessage;
  // 追加结构化属性（若有）
  N := R.GetAttrsCount;
  if N > 0 then
  begin
    AttrsText := '';
    for I := 0 to N - 1 do
    begin
      if I > 0 then AttrsText += ' ';
      case R.GetAttr(I).Kind of
        lakString: AttrsText += R.GetAttr(I).Key + '=' + R.GetAttr(I).ValueStr;
        lakNumber: AttrsText += R.GetAttr(I).Key + '=' + FloatToStr(R.GetAttr(I).ValueNum);
        lakBool:   if R.GetAttr(I).ValueBool then AttrsText += R.GetAttr(I).Key + '=true' else AttrsText += R.GetAttr(I).Key + '=false';
        lakNull:   AttrsText += R.GetAttr(I).Key + '=null';
      end;
    end;
    Result += ' ' + AttrsText;
  end;
end;

end.

