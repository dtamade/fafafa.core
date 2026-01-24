program test_condvar_simple;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils,
  fafafa.core.sync.mutex,
  fafafa.core.sync.condvar;

var
  LMutex: IMutex;
  LCondVar: ICondVar;
  LCounter: Integer;
  LProducerDone: Boolean;

procedure ProducerThread(AData: Pointer);
var
  i: Integer;
begin
  WriteLn('[Producer] Started');
  for i := 1 to 5 do
  begin
    LMutex.Acquire;
    try
      Inc(LCounter);
      WriteLn('[Producer] Produced: ', LCounter);
      LCondVar.Signal;
    finally
      LMutex.Release;
    end;
    Sleep(100);
  end;
  
  LMutex.Acquire;
  try
    LProducerDone := True;
    LCondVar.Signal;
  finally
    LMutex.Release;
  end;
  WriteLn('[Producer] Done');
end;

procedure ConsumerThread(AData: Pointer);
var
  LLocalCount: Integer;
begin
  WriteLn('[Consumer] Started');
  LLocalCount := 0;
  
  repeat
    LMutex.Acquire;
    try
      while (LCounter = 0) and (not LProducerDone) do
      begin
        WriteLn('[Consumer] Waiting...');
        LCondVar.Wait(LMutex);
        WriteLn('[Consumer] Woke up');
      end;
      
      if LCounter > 0 then
      begin
        Dec(LCounter);
        Inc(LLocalCount);
        WriteLn('[Consumer] Consumed: ', LLocalCount, ' (remaining: ', LCounter, ')');
      end;
    finally
      LMutex.Release;
    end;
  until LProducerDone and (LCounter = 0);
  
  WriteLn('[Consumer] Done, consumed total: ', LLocalCount);
end;

var
  LProducerThread, LConsumerThread: TThreadID;
begin
  WriteLn('=== Simple CondVar Test ===');
  
  {$IFDEF UNIX}
  LMutex := MakePthreadMutex;  // 使用与 pthread_cond_* 兼容的 mutex
  {$ELSE}
  LMutex := MakeMutex;
  {$ENDIF}
  LCondVar := MakeCondVar;
  LCounter := 0;
  LProducerDone := False;
  
  WriteLn('Creating threads...');
  LProducerThread := BeginThread(@ProducerThread, nil);
  LConsumerThread := BeginThread(@ConsumerThread, nil);
  
  WriteLn('Waiting for threads...');
  WaitForThreadTerminate(LProducerThread, 0);
  WaitForThreadTerminate(LConsumerThread, 0);
  
  WriteLn('=== Test Complete ===');
  WriteLn('Final counter: ', LCounter);
end.
