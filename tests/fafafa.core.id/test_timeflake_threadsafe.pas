program test_timeflake_threadsafe;

{$MODE OBJFPC}{$H+}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils, SyncObjs,
  fafafa.core.id.timeflake;

const
  THREAD_COUNT = 8;
  IDS_PER_THREAD = 5000;

var
  GIdStrings: array[0..THREAD_COUNT * IDS_PER_THREAD - 1] of string;
  GIdIndex: Integer = 0;
  GLock: TCriticalSection;

type
  TTestThread = class(TThread)
  private
    FThreadIdx: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AThreadIdx: Integer);
  end;

constructor TTestThread.Create(AThreadIdx: Integer);
begin
  inherited Create(True);
  FThreadIdx := AThreadIdx;
  FreeOnTerminate := False;
end;

procedure TTestThread.Execute;
var
  I, Idx: Integer;
  S: string;
begin
  for I := 1 to IDS_PER_THREAD do
  begin
    S := TimeflakeToString(TimeflakeMonotonic);

    GLock.Acquire;
    try
      Idx := GIdIndex;
      Inc(GIdIndex);
      GIdStrings[Idx] := S;
    finally
      GLock.Release;
    end;
  end;
end;

procedure FindDuplicates;
var
  I, J, K: Integer;
  DupCount: Integer;
  DupSamples: array[0..9] of string;
  DupSampleIdx: Integer;
begin
  DupCount := 0;
  DupSampleIdx := 0;

  for I := 0 to GIdIndex - 1 do
  begin
    for J := I + 1 to GIdIndex - 1 do
    begin
      if GIdStrings[I] = GIdStrings[J] then
      begin
        Inc(DupCount);
        if DupSampleIdx < 10 then
        begin
          DupSamples[DupSampleIdx] := GIdStrings[I];
          Inc(DupSampleIdx);
        end;
        Break;
      end;
    end;
  end;

  WriteLn('Duplicate count: ', DupCount);
  if DupCount > 0 then
  begin
    WriteLn('Sample duplicates:');
    for K := 0 to DupSampleIdx - 1 do
      WriteLn('  ', DupSamples[K]);
  end;
end;

var
  Threads: array[0..THREAD_COUNT-1] of TTestThread;
  I: Integer;
begin
  WriteLn('Testing TimeflakeMonotonic thread safety...');
  WriteLn('Threads: ', THREAD_COUNT, ', IDs per thread: ', IDS_PER_THREAD);

  GLock := TCriticalSection.Create;
  try
    for I := 0 to THREAD_COUNT - 1 do
      Threads[I] := TTestThread.Create(I);

    for I := 0 to THREAD_COUNT - 1 do
      Threads[I].Start;

    for I := 0 to THREAD_COUNT - 1 do
    begin
      Threads[I].WaitFor;
      Threads[I].Free;
    end;

    WriteLn('Total IDs: ', GIdIndex);
    FindDuplicates;

    if GIdIndex = THREAD_COUNT * IDS_PER_THREAD then
      WriteLn('Total count: PASS')
    else
      WriteLn('Total count: FAIL');
  finally
    GLock.Free;
  end;
end.
