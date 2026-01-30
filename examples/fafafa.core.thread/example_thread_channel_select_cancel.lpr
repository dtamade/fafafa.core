program example_thread_channel_select_cancel;
{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.thread;

type
  PWaitParam = ^TWaitParam;
  TWaitParam = record
    Chan: IChannel;
    Token: ICancellationToken;
    Id: Integer;
  end;

function WaitOnChan(Data: Pointer): Boolean;
var
  P: PWaitParam;
  V: Pointer;
begin
  Result := False;
  P := PWaitParam(Data);
  while True do
  begin
    // 以短超时片段等待，便于响应取消
    if P^.Chan.RecvTimeout(V, 50) then
    begin
      Writeln('[recv-', P^.Id, '] got value=', PtrUInt(V));
      Exit(True);
    end;
    if Assigned(P^.Token) and P^.Token.IsCancellationRequested then
      Exit(False);
  end;
end;

procedure Demo_Channel_Select_Cancel;
var
  C1, C2: IChannel;
  P1, P2: PWaitParam;
  F1, F2, S1, S2: IFuture;
  Cts: ICancellationTokenSource;
  Idx: Integer;
begin
  Writeln('Scenario: Channel + Select + Cancellation');
  C1 := CreateChannel(0);
  C2 := CreateChannel(0);
  Cts := CreateCancellationTokenSource;
  New(P1); P1^.Chan := C1; P1^.Token := Cts.Token; P1^.Id := 1;
  New(P2); P2^.Chan := C2; P2^.Token := Cts.Token; P2^.Id := 2;
  try
    // 启动两个接收者
    F1 := TThreads.Spawn(@WaitOnChan, P1, Cts.Token);
    F2 := TThreads.Spawn(@WaitOnChan, P2, Cts.Token);

    // 启动两个发送者，错开时间
    S1 := TThreads.Spawn(function: Boolean begin Sleep(200); C1.Send(Pointer(PtrUInt(111))); Exit(True); end);
    S2 := TThreads.Spawn(function: Boolean begin Sleep(500); C2.Send(Pointer(PtrUInt(222))); Exit(True); end);

    // 选择最先完成的接收者
    Idx := Select([F1, F2], 2000);
    Writeln('Select -> first receiver index = ', Idx);

    // 取消另一个接收者，避免长时间等待
    Cts.Cancel;

    // 等待发送者结束
    Join([S1, S2], 2000);
  finally
    // 清理：先断开接口，再释放记录
    if Assigned(P1) then begin P1^.Chan := nil; P1^.Token := nil; Dispose(P1); end;
    if Assigned(P2) then begin P2^.Chan := nil; P2^.Token := nil; Dispose(P2); end;
    C1 := nil; C2 := nil; Cts := nil;
  end;
end;

begin
  Demo_Channel_Select_Cancel;
end.

