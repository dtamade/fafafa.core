unit fafafa.core.sync.barrier;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base, fafafa.core.sync.barrier.base
  {$IFDEF WINDOWS}, fafafa.core.sync.barrier.windows{$ENDIF}
  {$IFDEF UNIX},    fafafa.core.sync.barrier.unix{$ENDIF};

type
  // Map TBarrier to platform-specific implementation (same pattern as mutex)
  {$IFDEF WINDOWS}
  TBarrier = fafafa.core.sync.barrier.windows.TBarrier;
  {$ENDIF}

  {$IFDEF UNIX}
  TBarrier = fafafa.core.sync.barrier.unix.TBarrier;
  {$ENDIF}

// Factory function: create platform-specific barrier instance
function MakeBarrier(AParticipantCount: Integer): IBarrier;

implementation

function MakeBarrier(AParticipantCount: Integer): IBarrier;
begin
  {$IFDEF UNIX}
  Result := fafafa.core.sync.barrier.unix.TBarrier.Create(AParticipantCount);
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := fafafa.core.sync.barrier.windows.TBarrier.Create(AParticipantCount);
  {$ENDIF}
end;

end.

