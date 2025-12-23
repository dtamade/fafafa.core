unit fafafa.core.sync.barrier.base;

{$mode objfpc}
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
  {**
   * TBarrierWaitResult - Rust-style barrier wait result (value type)
   *
   * @desc
   *   Lightweight value type representing the result of a barrier wait operation.
   *   Zero heap allocation, stack-allocated like Rust's BarrierWaitResult.
   *
   * @rust_equivalent std::sync::BarrierWaitResult
   *
   * @example
   *   result := barrier.WaitEx;
   *   if result.IsLeader then
   *     WriteLn('I am the leader for generation ', result.Generation);
   *}
  TBarrierWaitResult = record
  private
    FIsLeader: Boolean;
    FGeneration: Cardinal;
  public
    {**
     * IsLeader - Check if current thread is the barrier leader
     *
     * @return True if this thread is the designated "leader" (serial thread)
     *         for this barrier phase. Exactly one thread returns True per phase.
     *
     * @rust_equivalent BarrierWaitResult::is_leader()
     *}
    function IsLeader: Boolean; inline;

    {**
     * Generation - Get the barrier generation/phase number
     *
     * @return The generation number of the barrier when wait completed.
     *         This increments each time all participants complete a phase.
     *}
    function Generation: Cardinal; inline;

    {**
     * Create a result for the leader thread
     *}
    class function Leader(AGeneration: Cardinal): TBarrierWaitResult; static; inline;

    {**
     * Create a result for a non-leader thread
     *}
    class function Follower(AGeneration: Cardinal): TBarrierWaitResult; static; inline;
  end;

  IBarrier = interface(ISynchronizable)
    ['{7C2A5B11-6E15-4D6B-9C6B-AB9A20E9F4A3}']
    {**
     * Wait - Legacy API: blocks until all participants reach the barrier
     *
     * @return True for exactly one thread (the "serial" thread) per phase,
     *         False for all other threads. Both True and False indicate success.
     *}
    function Wait: Boolean;

    {**
     * WaitEx - Modern API: blocks and returns a result value (Rust-style)
     *
     * @return TBarrierWaitResult containing leader status and generation info.
     *
     * @rust_equivalent Barrier::wait() -> BarrierWaitResult
     *
     * @example
     *   result := barrier.WaitEx;
     *   if result.IsLeader then
     *     // Perform single-threaded cleanup or transition logic
     *}
    function WaitEx: TBarrierWaitResult;

    // Returns the fixed number of participants configured at construction time.
    function GetParticipantCount: Integer;
  end;

implementation

{ TBarrierWaitResult }

function TBarrierWaitResult.IsLeader: Boolean;
begin
  Result := FIsLeader;
end;

function TBarrierWaitResult.Generation: Cardinal;
begin
  Result := FGeneration;
end;

class function TBarrierWaitResult.Leader(AGeneration: Cardinal): TBarrierWaitResult;
begin
  Result.FIsLeader := True;
  Result.FGeneration := AGeneration;
end;

class function TBarrierWaitResult.Follower(AGeneration: Cardinal): TBarrierWaitResult;
begin
  Result.FIsLeader := False;
  Result.FGeneration := AGeneration;
end;

end.

