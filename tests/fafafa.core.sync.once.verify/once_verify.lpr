program once_verify;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.sync.once, fafafa.core.sync.once.base;

var
  Once: IOnce;
  Count: Integer = 0;

procedure IncCount;
begin
  Inc(Count);
end;

begin
  Writeln('once_verify: minimal once smoke test');
  Once := MakeOnce(@IncCount);
  Once.Execute;        // first time
  Once.Execute;        // no-op
  if Count <> 1 then
  begin
    Writeln('FAIL: expected Count=1, got ', Count);
    Halt(1);
  end;
  // poison path test: create a fresh once and raise
  Once := MakeOnce;
  try
    Once.Execute(
      procedure
      begin
        raise Exception.Create('boom');
      end
    );
  except
    on E: Exception do
      Writeln('Caught expected exception: ', E.Message);
  end;
  Writeln('State after exception: completed=', Once.Completed, ', poisoned=', Once.Poisoned);
  Writeln('OK');
end.

