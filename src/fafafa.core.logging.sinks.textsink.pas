unit fafafa.core.logging.sinks.textsink;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.io,
  fafafa.core.logging.interfaces;

type
  // Flush 策略（可选）：按条数/时间批量 Flush；保持默认兼容
  TFlushPolicy = record
    Enabled: Boolean;
    MaxLines: Integer;     // 达到则 Flush
    MaxIntervalMs: Integer; // 预留
  end;

  { 通用适配器：ILogRecord -> ITextSink }
  TTextSinkLogSink = class(TInterfacedObject, ILogSink)
  private
    FOut: ITextSink;
    FFmt: ILogFormatter;
    FLock: ILock;
    FPolicy: TFlushPolicy;
    FPending: Integer;
    FLastFlushTick: QWord;
  public
    constructor Create(const AOut: ITextSink; const AFmt: ILogFormatter); overload;
    constructor Create(const AOut: ITextSink; const AFmt: ILogFormatter; const APolicy: TFlushPolicy); overload;
    procedure Write(const R: ILogRecord);
    procedure Flush;
  end;

  { 反向适配器：ITextSink -> ILogger （将 WriteLine 作为 Info 日志） }
  TLoggerTextSink = class(TInterfacedObject, ITextSink)
  private
    FLogger: ILogger;
  public
    constructor Create(const ALogger: ILogger);
    procedure WriteLine(const S: string);
    procedure Flush;
  end;

implementation

constructor TTextSinkLogSink.Create(const AOut: ITextSink; const AFmt: ILogFormatter);
begin
  inherited Create;
  FOut := AOut;
  FFmt := AFmt;
  FLock := TMutex.Create;
end;

procedure TTextSinkLogSink.Write(const R: ILogRecord);
var
  LAuto: TAutoLock; LLine: string;
begin
  if R = nil then Exit;
  if FFmt <> nil then LLine := FFmt.Format(R) else LLine := R.RenderedMessage;
  LAuto := TAutoLock.Create(FLock);
  try
    if FOut <> nil then FOut.WriteLine(LLine);
    Inc(FPending);
    if FPolicy.Enabled then
    begin
      // 条数阈值
      if (FPolicy.MaxLines > 0) and (FPending >= FPolicy.MaxLines) then
      begin
        if FOut <> nil then FOut.Flush;
        FPending := 0;
        FLastFlushTick := GetTickCount64;
      end
      else if (FPolicy.MaxIntervalMs > 0) then
      begin
        // 时间阈值：达到间隔则冲刷
        if (GetTickCount64 - FLastFlushTick) >= QWord(FPolicy.MaxIntervalMs) then
        begin
          if FOut <> nil then FOut.Flush;
          FPending := 0;
          FLastFlushTick := GetTickCount64;
        end;
      end;
    end;
  finally
    LAuto.Free;
  end;
end;

constructor TTextSinkLogSink.Create(const AOut: ITextSink; const AFmt: ILogFormatter; const APolicy: TFlushPolicy);
begin
  inherited Create;
  FOut := AOut;
  FFmt := AFmt;
  FLock := TMutex.Create;
  FPolicy := APolicy;
  FPending := 0;
  FLastFlushTick := GetTickCount64;
end;


constructor TLoggerTextSink.Create(const ALogger: ILogger);
begin
  inherited Create;
  FLogger := ALogger;
end;

procedure TLoggerTextSink.WriteLine(const S: string);
begin
  if FLogger <> nil then FLogger.Info('%s', [S]);
end;

procedure TLoggerTextSink.Flush;
begin
  // no-op
end;

procedure TTextSinkLogSink.Flush;
var LAuto: TAutoLock;
begin
  LAuto := TAutoLock.Create(FLock);
  try
    if FOut <> nil then FOut.Flush;
  finally
    LAuto.Free;
  end;
end;

end.

