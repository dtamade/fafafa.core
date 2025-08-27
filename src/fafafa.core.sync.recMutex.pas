unit fafafa.core.sync.recMutex;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base,
  fafafa.core.sync.recMutex.base
  {$IFDEF WINDOWS}, fafafa.core.sync.recMutex.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.recMutex.unix{$ENDIF}
  ;

type
  IRecMutex = fafafa.core.sync.recMutex.base.IRecMutex;

  {$IFDEF WINDOWS}
  TRecMutex = fafafa.core.sync.recMutex.windows.TRecMutex;
  {$ENDIF}

  {$IFDEF UNIX}
  TRecMutex = fafafa.core.sync.recMutex.unix.TRecMutex;
  {$ENDIF}

function MakeRecMutex: IRecMutex; overload;
{$IFDEF WINDOWS}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex; overload;
{$ENDIF}

implementation

function MakeRecMutex: IRecMutex;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.recMutex.unix.TRecMutex.Create;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.recMutex.windows.TRecMutex.Create;
  {$ENDIF}
end;

{$IFDEF WINDOWS}
function MakeRecMutex(ASpinCount: DWORD): IRecMutex;
begin
  Result := fafafa.core.sync.recMutex.windows.TRecMutex.Create(ASpinCount);
end;
{$ENDIF}

end.

