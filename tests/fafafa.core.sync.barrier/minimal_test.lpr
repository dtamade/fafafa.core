program minimal_test;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.sync.barrier;

var
  Barrier: IBarrier;
  
begin
  try
    WriteLn('Creating barrier...');
    Barrier := MakeBarrier(2);
    WriteLn('Barrier created');
    
    WriteLn('Participant count: ', Barrier.GetParticipantCount);
    
    WriteLn('Test completed successfully');
    
  except
    on E: Exception do
    begin
      WriteLn('Exception: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
