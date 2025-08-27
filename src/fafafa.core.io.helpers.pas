unit fafafa.core.io.helpers;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.io;

procedure SinkWriteFmt(const S: ITextSink; const Fmt: string; const Args: array of const);
procedure SinkWriteLines(const S: ITextSink; const Lines: array of string);

implementation

procedure SinkWriteFmt(const S: ITextSink; const Fmt: string; const Args: array of const);
begin
  if S <> nil then S.WriteLine(Format(Fmt, Args));
end;

procedure SinkWriteLines(const S: ITextSink; const Lines: array of string);
var i: Integer;
begin
  if S = nil then Exit;
  for i := 0 to High(Lines) do
    S.WriteLine(Lines[i]);
end;

end.

