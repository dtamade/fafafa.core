unit fafafa.core.logging.sinks.composite;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.sync,
  fafafa.core.logging.interfaces;

type
  { 将日志转发到多个子 sink；遇异常采用 best-effort（不中断其他） }
  TCompositeLogSink = class(TInterfacedObject, ILogSink)
  private
    FSinks: array of ILogSink;
  public
    constructor Create(const ASinks: array of ILogSink);
    procedure Write(const R: ILogRecord);
    procedure Flush;
  end;

implementation

constructor TCompositeLogSink.Create(const ASinks: array of ILogSink);
var I, N: SizeInt;
begin
  inherited Create;

  N := Length(ASinks);
  SetLength(FSinks, N);
  for I := 0 to N - 1 do FSinks[I] := ASinks[I];
end;

procedure TCompositeLogSink.Write(const R: ILogRecord);
var
  I, N: SizeInt;
begin
  if R = nil then Exit;
  N := Length(FSinks);
  // 去除全局锁，交给下游 sink 自行同步；保证 best-effort
  for I := 0 to N - 1 do
  begin
    try
      if FSinks[I] <> nil then FSinks[I].Write(R);
    except
      // best-effort: 吞掉单个 sink 异常，不影响其他
    end;
  end;
end;

procedure TCompositeLogSink.Flush;
var
  I, N: SizeInt;
begin
  N := Length(FSinks);
  for I := 0 to N - 1 do
  begin
    try
      if FSinks[I] <> nil then FSinks[I].Flush;
    except
    end;
  end;
end;

end.

