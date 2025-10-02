program test_sync_compile;

{$mode objfpc}{$H+}

uses
  SysUtils,
  // Core sync units
  fafafa.core.sync,
  fafafa.core.sync.base,
  fafafa.core.sync.mutex,
  fafafa.core.sync.spin,
  fafafa.core.sync.rwlock,
  fafafa.core.sync.once,
  fafafa.core.sync.condvar,
  fafafa.core.sync.barrier,
  fafafa.core.sync.sem,
  fafafa.core.sync.event,
  // Named sync units
  fafafa.core.sync.namedMutex,
  fafafa.core.sync.namedEvent,
  fafafa.core.sync.namedSemaphore,
  fafafa.core.sync.namedBarrier,
  fafafa.core.sync.namedCondvar,
  fafafa.core.sync.namedRWLock;

var
  Mutex: IMutex;
  Spin: ISpin;
  RWLock: IRWLock;
  Once: IOnce;
  CondVar: ICondVar;
  Barrier: IBarrier;
  Sem: ISem;
  Event: IEvent;
  NamedMutex: INamedMutex;
  NamedEvent: INamedEvent;
  NamedSem: INamedSemaphore;
  NamedBarrier: INamedBarrier;
  NamedCondVar: INamedCondVar;
  NamedRWLock: INamedRWLock;

begin
  WriteLn('Testing sync library compilation...');
  
  try
    // Test factory functions
    WriteLn('Creating sync primitives...');
    
    Mutex := MakeMutex;
    WriteLn('  Mutex: OK');
    
    Spin := MakeSpin;
    WriteLn('  Spin: OK');
    
    RWLock := MakeRWLock;
    WriteLn('  RWLock: OK');
    
    Once := MakeOnce;
    WriteLn('  Once: OK');
    
    CondVar := MakeCondVar;
    WriteLn('  CondVar: OK');
    
    Barrier := MakeBarrier(2);
    WriteLn('  Barrier: OK');
    
    Sem := MakeSem(1, 1);
    WriteLn('  Semaphore: OK');
    
    Event := MakeEvent(False, False);
    WriteLn('  Event: OK');
    
    // Test named sync primitives
    WriteLn('Creating named sync primitives...');
    
    NamedMutex := MakeNamedMutex('TestMutex');
    WriteLn('  NamedMutex: OK');
    
    NamedEvent := MakeNamedEvent('TestEvent');
    WriteLn('  NamedEvent: OK');
    
    NamedSem := MakeNamedSemaphore('TestSem');
    WriteLn('  NamedSemaphore: OK');
    
    NamedBarrier := MakeNamedBarrier('TestBarrier', 2);
    WriteLn('  NamedBarrier: OK');
    
    NamedCondVar := MakeNamedCondVar('TestCondVar');
    WriteLn('  NamedCondVar: OK');
    
    NamedRWLock := MakeNamedRWLock('TestRWLock');
    WriteLn('  NamedRWLock: OK');
    
    WriteLn;
    WriteLn('All sync primitives created successfully!');
    WriteLn('Compilation test PASSED.');
    
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      WriteLn('Compilation test FAILED.');
      ExitCode := 1;
    end;
  end;
end.