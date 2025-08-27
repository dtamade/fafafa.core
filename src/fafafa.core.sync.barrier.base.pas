unit fafafa.core.sync.barrier.base;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

{
  IBarrier - Cross-platform barrier synchronization interface (base unit)

  Design goals:
  - Follow the same modular pattern as other sync primitives (e.g., mutex, spin):
    define the interface in a dedicated *base* unit, keep factories/platform
    implementations in their own units.
  - Greatest common denominator API between Windows and Unix/Linux native barriers:
    * Windows:   SYNCHRONIZATION_BARRIER (InitializeSynchronizationBarrier,
                 EnterSynchronizationBarrier, DeleteSynchronizationBarrier)
    * Unix/POSIX: pthread_barrier_* (pthread_barrier_init, pthread_barrier_wait,
                 pthread_barrier_destroy)
  - Avoid features that require heavy emulation on either platform (e.g., timeouts
    or dynamic wait-count queries). This keeps semantics clean and performance high.

  Contract:
  - Wait() blocks until all participants reach the barrier for the current phase.
    It returns True exactly for one thread (the "serial" thread) in each phase,
    and False for all other threads. This matches:
      * Windows:  EnterSynchronizationBarrier return value
      * POSIX:    pthread_barrier_wait returns PTHREAD_BARRIER_SERIAL_THREAD for
                  the serial thread (mapped here to True)
  - GetParticipantCount() returns the fixed number of participants configured at
    construction time by implementations. Implementations need not expose any
    transient waiting counts.

  Notes:
  - This interface inherits from ILock to stay consistent with the hierarchy used
    across fafafa.core.sync primitives. Typical barrier implementations may simply
    forward ILock methods to an internal mutex as an implementation detail.
}

interface

uses
  fafafa.core.sync.base; // for ILock

type
  // Barrier interface (greatest common denominator across platforms)
  IBarrier = interface(ILock)
    ['{7C2A5B11-6E15-4D6B-9C6B-AB9A20E9F4A3}']
    { Arrive and wait until all participants have reached the barrier for the
      current phase. Exactly one thread per phase should receive True (the
      "serial" thread). Others receive False. }
    function Wait: Boolean;

    { Return the configured participant count for this barrier. }
    function GetParticipantCount: Integer;
  end;

implementation

end.

