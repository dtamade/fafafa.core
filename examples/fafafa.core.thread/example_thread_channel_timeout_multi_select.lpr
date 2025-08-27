program example_thread_channel_timeout_multi_select;
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

function WaitOnChanWithToken(Data: Pointer): Boolean;
var
  P: PWaitParam;
  V: Pointer;
  start, nowTick: QWord;
begin
  Result := False;
  P := PWaitParam(Data);
  start := GetTickCount64;
  while True do
  begin
    // 小片段等待，利于响应取消/关闭
    if P^.Chan.RecvTimeout(V, 50) then
    begin
      Writeln('[recv-', P^.Id, '] got value=', PtrUInt(V));
      Exit(True);
    end;
    if Assigned(P^.Token) and P^.Token.IsCancellationRequested then
      Exit(False);
    // 可选：整体超时保护（1.5s），未命中也由外层 Select 控制
    nowTick := GetTickCount64;
    if (nowTick - start) > 1500 then Exit(False);
  end;
end;

procedure Demo_Channel_Timeout_Multi_Select;
var
  C1, C2, C3: IChannel;
  P1, P2, P3: PWaitParam;
  R1, R2, R3, S1, S2, S3: IFuture;
  Cts: ICancellationTokenSource;
  idx: Integer;
begin
  Writeln('Scenario: Channel + Timeout + Multi-Select');
  C1 := CreateChannel(0);
  C2 := CreateChannel(0);
  C3 := CreateChannel(0);
  Cts := CreateCancellationTokenSource;

  New(P1); P1^.Chan := C1; P1^.Token := Cts.Token; P1^.Id := 1;
  New(P2); P2^.Chan := C2; P2^.Token := Cts.Token; P2^.Id := 2;
  New(P3); P3^.Chan := C3; P3^.Token := Cts.Token; P3^.Id := 3;
  try
    // 三个接收者
    R1 := TThreads.Spawn(@WaitOnChanWithToken, P1, Cts.Token);
    R2 := TThreads.Spawn(@WaitOnChanWithToken, P2, Cts.Token);
    R3 := TThreads.Spawn(@WaitOnChanWithToken, P3, Cts.Token);

    // 三个发送者（不同延时，模拟部分通道超时）
    S1 := TThreads.Spawn(function: Boolean begin Sleep(150); C1.Send(Pointer(PtrUInt(101))); Exit(True); end);
    S2 := TThreads.Spawn(function: Boolean begin Sleep(800); C2.Send(Pointer(PtrUInt(202))); Exit(True); end);
    S3 := TThreads.Spawn(function: Boolean begin Sleep(1200); C3.Send(Pointer(PtrUInt(303))); Exit(True); end);

    // 只等 500ms，预期可能超时（返回 -1），或在 150ms 时 R1 先完成
    idx := Select([R1, R2, R3], 500);
    if idx >= 0 then
      Writeln('Select -> first receiver index = ', idx)
    else
      Writeln('Select -> timeout');

    // 取消其余未中选/未完成的接收者
    Cts.Cancel;

    // 等待发送者结束，避免悬挂
    Join([S1, S2, S3], 2000);
  finally
    if Assigned(P1) then begin P1^.Chan := nil; P1^.Token := nil; Dispose(P1); end;
    if Assigned(P2) then begin P2^.Chan := nil; P2^.Token := nil; Dispose(P2); end;
    if Assigned(P3) then begin P3^.Chan := nil; P3^.Token := nil; Dispose(P3); end;
    C1 := nil; C2 := nil; C3 := nil; Cts := nil;
  end;
end;

begin
  Demo_Channel_Timeout_Multi_Select;
end.

