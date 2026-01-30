program example_stop_when_done;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core;

var
  Doc: TJsonDocument; Err: TJsonError; S: AnsiString;
begin
  S := '123 456';
  // 默认严格：失败
  Doc := JsonReadOpts(PChar(S), Length(S), [], GetRtlAllocator(), Err);
  if Assigned(Doc) then begin Writeln('unexpected success'); Halt(1); end;
  // StopWhenDone：成功
  Doc := JsonReadOpts(PChar(S), Length(S), [jrfStopWhenDone], GetRtlAllocator(), Err);
  if not Assigned(Doc) then begin Writeln('stop-when-done failed'); Halt(2); end;
  Writeln('ok: stop-when-done');
  Doc.Free;
end.

