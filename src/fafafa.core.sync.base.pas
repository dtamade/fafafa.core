unit fafafa.core.sync.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.base;

type
  // ===== Exceptions =====
  ESyncError = class(ECore);
  ELockError = class(ESyncError);
  ETimeoutError = class(ESyncError);
  EDeadlockError = class(ESyncError);

  // ===== Enums =====
  TLockState = (
    lsUnlocked,
    lsLocked,
    lsAbandoned
  );

  TWaitResult = (
    wrSignaled,
    wrTimeout,
    wrAbandoned,
    wrError
  );

  // ===== Interfaces =====
  ILock = interface
    ['{B8F5A2E1-4C3D-4F2A-9B1E-8D7C6A5F4E3D}']
    procedure Acquire;
    procedure Release;
    function TryAcquire: Boolean;
  end;

implementation


end.

