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
  - This interface inherits from ISynchronizable to stay consistent with the
    hierarchy used across fafafa.core.sync primitives.
  - Wait() returning False indicates a non-serial thread success (not an error).
  - The base barrier deliberately provides no timeout/reset/interruption semantics;
    use higher-level constructs (e.g., namedBarrier or a CyclicBarrier-style API)
    if such features are required.
}

interface

uses
  fafafa.core.sync.base;

type

  IBarrier = interface(ISynchronizable)
    ['{7C2A5B11-6E15-4D6B-9C6B-AB9A20E9F4A3}']
    // Wait blocks until all participants reach the barrier for the current phase.
    // Returns True for exactly one thread (the "serial" thread) per phase,
    // and False for all other threads. Both True and False indicate success;
    // False does NOT indicate an error or timeout.
    function Wait: Boolean;
    // Returns the fixed number of participants configured at construction time.
    function GetParticipantCount: Integer;
  end;

implementation

end.

