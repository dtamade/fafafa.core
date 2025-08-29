program example_mpmc_queue;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}
  Classes, SysUtils,
  fafafa.core.sync.mutex, fafafa.core.sync.conditionVariable;

const
  CAPACITY = 5;
  N_PROD   = 3;
  N_CONS   = 2;
  ITEMS_PER_PROD = 10;

var
  M: IMutex;
  CV: IConditionVariable;
  Q: array of Integer;
  ProducersDone: Integer;

procedure Enqueue(const V: Integer);
begin
  SetLength(Q, Length(Q)+1);
  Q[High(Q)] := V;
end;

function Dequeue(out V: Integer): Boolean;
begin
  if Length(Q) = 0 then Exit(False);
  V := Q[0];
  Delete(Q, 0, 1);
  Exit(True);
end;

Type
  TProducer = class(TThread)
  private
    FId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AId: Integer);
  end;

  TConsumer = class(TThread)
  private
    FId: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AId: Integer);
  end;

constructor TProducer.Create(AId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FId := AId;
end;

procedure TProducer.Execute;
var i: Integer;
begin
  for i := 1 to ITEMS_PER_PROD do
  begin
    M.Acquire;
    try
      // 如果队列满，等待“有空位”
      while Length(Q) >= CAPACITY do
      begin
        if not CV.Wait(M, 100) then ; // 超时轮询避免阻塞
      end;
      Enqueue(FId*100 + i);
      Writeln('[生产者',FId,'] 生产: ', FId*100+i, ' (size=', Length(Q), ')');
      // 告知消费者有数据
      CV.Signal;
    finally
      M.Release;
    end;
    Sleep(10 + (FId mod 3)*10);
  end;

  // 标记该生产者结束
  M.Acquire;
  try
    Inc(ProducersDone);
    CV.Broadcast; // 可能唤醒因“空队列但未结束”而等待的消费者
  finally
    M.Release;
  end;
end;

constructor TConsumer.Create(AId: Integer);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FId := AId;
end;

procedure TConsumer.Execute;
var v: Integer; ok: Boolean;
begin
  while True do
  begin
    M.Acquire;
    try
      // 等到有数据或所有生产者结束
      while (Length(Q)=0) and (ProducersDone < N_PROD) do
      begin
        ok := CV.Wait(M, 200);
        if not ok then ;
      end;
      if (Length(Q)=0) and (ProducersDone = N_PROD) then Exit; // 真正结束
      if Dequeue(v) then
        Writeln('  [消费者',FId,'] 消费: ', v, ' (size=', Length(Q), ')');
      // 消费后可能让出空位，通知生产者
      CV.Signal;
    finally
      M.Release;
    end;
    Sleep(20 + (FId mod 2)*15);
  end;
end;

var i: Integer; Prod: array[1..N_PROD] of TProducer; Cons: array[1..N_CONS] of TConsumer;
begin
  M := MakeMutex;
  CV := MakeConditionVariable;
  SetLength(Q, 0);
  ProducersDone := 0;

  for i := 1 to N_PROD do begin Prod[i] := TProducer.Create(i); Prod[i].Start; end;
  for i := 1 to N_CONS do begin Cons[i] := TConsumer.Create(i); Cons[i].Start; end;

  for i := 1 to N_PROD do begin Prod[i].WaitFor; Prod[i].Free; end;
  for i := 1 to N_CONS do begin Cons[i].WaitFor; Cons[i].Free; end;

  Writeln('MPMC 示例完成。');
end.

