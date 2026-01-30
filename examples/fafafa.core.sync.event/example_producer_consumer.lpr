program example_producer_consumer;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$modeswitch anonymousfunctions}

{
  Producer-Consumer Pattern Example
  
  This example demonstrates:
  1. Using events for producer-consumer coordination
  2. Thread-safe queue operations
  3. Graceful shutdown with events
  4. Multiple consumers with auto-reset events
}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, Classes, fafafa.core.sync.event, fafafa.core.sync.base;

type
  TWorkItem = record
    Id: Integer;
    Data: string;
  end;
  PWorkItem = ^TWorkItem;

  TProducerConsumerDemo = class
  private
    FWorkQueue: TThreadList;
    FWorkAvailable: IEvent;      // Auto-reset event for work notification
    FShutdown: IEvent;           // Manual-reset event for shutdown
    FProducerThread: TThread;
    FConsumerThreads: array of TThread;
    FItemsProduced: Integer;
    FItemsConsumed: Integer;
    
    procedure ProducerProc;
    procedure ConsumerProc(ConsumerId: Integer);
  public
    constructor Create(ConsumerCount: Integer = 2);
    destructor Destroy; override;
    
    procedure Start;
    procedure Stop;
    procedure WaitForCompletion;
  end;

constructor TProducerConsumerDemo.Create(ConsumerCount: Integer);
var
  i: Integer;
begin
  inherited Create;
  
  FWorkQueue := TThreadList.Create;
  FWorkAvailable := MakeEvent(False, False);  // Auto-reset event
  FShutdown := MakeEvent(True, False);        // Manual-reset event
  
  FItemsProduced := 0;
  FItemsConsumed := 0;
  
  // Create producer thread
  FProducerThread := TThread.CreateAnonymousThread(@ProducerProc);
  FProducerThread.FreeOnTerminate := False;
  
  // Create consumer threads
  SetLength(FConsumerThreads, ConsumerCount);
  for i := 0 to ConsumerCount - 1 do
  begin
    FConsumerThreads[i] := TThread.CreateAnonymousThread(
      procedure begin ConsumerProc(i + 1); end
    );
    FConsumerThreads[i].FreeOnTerminate := False;
  end;
end;

destructor TProducerConsumerDemo.Destroy;
var
  i: Integer;
begin
  // Clean up threads
  FProducerThread.Free;
  for i := 0 to High(FConsumerThreads) do
    FConsumerThreads[i].Free;
    
  FWorkQueue.Free;
  inherited Destroy;
end;

procedure TProducerConsumerDemo.ProducerProc;
var
  i: Integer;
  PItem: PWorkItem;
  Queue: TList;
begin
  WriteLn('[Producer] Started');
  
  for i := 1 to 10 do
  begin
    // Check for shutdown
    if FShutdown.TryWait then
    begin
      WriteLn('[Producer] Shutdown requested, stopping');
      Break;
    end;
    
    // Create work item (allocate on heap)
    New(PItem);
    PItem^.Id := i;
    PItem^.Data := Format('Work item #%d', [i]);
    
    // Add to queue
    Queue := FWorkQueue.LockList;
    try
      Queue.Add(PItem);
      Inc(FItemsProduced);
    finally
      FWorkQueue.UnlockList;
    end;
    
    WriteLn('[Producer] Produced: ', PItem^.Data);
    
    // Notify consumers that work is available
    FWorkAvailable.SetEvent;
    
    // Simulate work
    Sleep(100);
  end;
  
  WriteLn('[Producer] Finished, produced ', FItemsProduced, ' items');
end;

procedure TProducerConsumerDemo.ConsumerProc(ConsumerId: Integer);
var
  WorkItem: TWorkItem;
  PItem: PWorkItem;
  Queue: TList;
  HasWork: Boolean;
begin
  WriteLn('[Consumer ', ConsumerId, '] Started');
  
  while True do
  begin
    // Wait for work or shutdown
    case FWorkAvailable.WaitFor(1000) of
      wrSignaled:
      begin
        // Try to get work from queue
        HasWork := False;
        PItem := nil;
        Queue := FWorkQueue.LockList;
        try
          if Queue.Count > 0 then
          begin
            PItem := PWorkItem(Queue.Items[0]);
            Queue.Delete(0);
            HasWork := True;
          end;
        finally
          FWorkQueue.UnlockList;
        end;
        
        if HasWork and Assigned(PItem) then
        begin
          WorkItem := PItem^;
          WriteLn('[Consumer ', ConsumerId, '] Processing: ', WorkItem.Data);
          // Simulate processing time
          Sleep(200);
          WriteLn('[Consumer ', ConsumerId, '] Completed: ', WorkItem.Data);
          Dispose(PItem);
          Inc(FItemsConsumed);
        end;
      end;
      
      wrTimeout:
      begin
        // Check for shutdown
        if FShutdown.TryWait then
        begin
          WriteLn('[Consumer ', ConsumerId, '] Shutdown requested, stopping');
          Break;
        end;
        // Continue waiting
      end;
    end;
  end;
  
  WriteLn('[Consumer ', ConsumerId, '] Finished');
end;

procedure TProducerConsumerDemo.Start;
var
  i: Integer;
begin
  WriteLn('Starting producer-consumer demo...');
  
  // Start all threads
  FProducerThread.Start;
  for i := 0 to High(FConsumerThreads) do
    FConsumerThreads[i].Start;
end;

procedure TProducerConsumerDemo.Stop;
begin
  WriteLn('Requesting shutdown...');
  FShutdown.SetEvent;
end;

procedure TProducerConsumerDemo.WaitForCompletion;
var
  i: Integer;
begin
  // Wait for producer to finish
  FProducerThread.WaitFor;
  
  // Give consumers a moment to finish remaining work
  Sleep(500);
  
  // Signal shutdown
  Stop;
  
  // Wait for all consumers
  for i := 0 to High(FConsumerThreads) do
    FConsumerThreads[i].WaitFor;
    
  WriteLn('All threads completed');
  WriteLn('Items produced: ', FItemsProduced);
  WriteLn('Items consumed: ', FItemsConsumed);
end;

var
  Demo: TProducerConsumerDemo;
begin
  WriteLn('fafafa.core.sync.event Producer-Consumer Example');
  WriteLn('===============================================');
  WriteLn;
  
  try
    Demo := TProducerConsumerDemo.Create(3); // 3 consumers
    try
      Demo.Start;
      Demo.WaitForCompletion;
      
      WriteLn;
      WriteLn('Demo completed successfully!');
    finally
      Demo.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
