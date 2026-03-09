unit fafafa.core.logging.sinks.console;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.io,
  fafafa.core.logging.interfaces;

type
  TConsoleLogSink = class(TInterfacedObject, ILogSink)
  private
    class var GLock: ILock;
    class var GOut: ITextSink;
  public
    class constructor Create;
    class destructor Destroy;
    procedure Write(const R: ILogRecord);
    procedure Flush;
  end;

implementation

uses
  fafafa.core.logging, fafafa.core.logging.formatters.text;

class constructor TConsoleLogSink.Create;
begin
  GLock := TMutex.Create;
  GOut := TConsoleSink.Create; // 复用通用 I/O sink
end;

class destructor TConsoleLogSink.Destroy;
begin
  GOut := nil;
  GLock := nil;
end;

procedure TConsoleLogSink.Write(const R: ILogRecord);
var
  LFormatter: ILogFormatter;
  LLine: string;
begin
  // 优先使用全局配置中的 Formatter
  LFormatter := Logging.GetFormatter;
  if LFormatter <> nil then
    LLine := LFormatter.Format(R)
  else
    LLine := R.RenderedMessage; // 最小回退

  GLock.Acquire;
  try
    if GOut <> nil then GOut.WriteLine(LLine) else WriteLn(LLine);
  finally
    GLock.Release;
  end;
end;

procedure TConsoleLogSink.Flush;
begin
  if GOut <> nil then GOut.Flush;
end;

end.

