unit fafafa.core.time.testutils;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I ..\..\src\fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.time.timer;

function PushTimerExceptionHandler(const H: TTimerExceptionHandler): TTimerExceptionHandler;
procedure PopTimerExceptionHandler(const OldHandler: TTimerExceptionHandler);

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}

type
  TTestProc = reference to procedure;

procedure RunWithTimerExceptionHandler(const H: TTimerExceptionHandler; const Body: TTestProc);

{$ENDIF}

implementation

function PushTimerExceptionHandler(const H: TTimerExceptionHandler): TTimerExceptionHandler;
begin
  Result := GetTimerExceptionHandler;
  SetTimerExceptionHandler(H);
end;

procedure PopTimerExceptionHandler(const OldHandler: TTimerExceptionHandler);
begin
  SetTimerExceptionHandler(OldHandler);
end;

{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}

procedure RunWithTimerExceptionHandler(const H: TTimerExceptionHandler; const Body: TTestProc);
var
  OldHandler: TTimerExceptionHandler;
begin
  OldHandler := PushTimerExceptionHandler(H);
  try
    if Assigned(Body) then
      Body();
  finally
    PopTimerExceptionHandler(OldHandler);
  end;
end;

{$ENDIF}

end.
