program cancel_best_practices_with_token_struct;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.base,
  fafafa.core.thread;

type
  PTaskArg = ^TTaskArg;
  TTaskArg = record
    Token: ICancellationToken;
    WorkMs: Integer;
  end;

function BusyChunk(Ms: Integer): Boolean;
begin
  Sleep(Ms);
  Result := True;
end;

function CancellableTaskWithArg(Data: Pointer): Boolean;
var
  Arg: PTaskArg;
  I: Integer;
begin
  Arg := PTaskArg(Data);
  if Arg = nil then Exit(False);
  for I := 1 to 200 do
  begin
    if Assigned(Arg^.Token) and Arg^.Token.IsCancellationRequested then
      Exit(False);
    BusyChunk(Arg^.WorkMs);
  end;
  Result := True;
end;

var
  P: IThreadPool;
  F: IFuture;
  Src: ICancellationTokenSource;
  Arg: TTaskArg;
begin
  Writeln('=== 取消最佳实践（结构体传 Token） ===');
  P := CreateThreadPool(2, 2, 60000, 64, TRejectPolicy.rpCallerRuns);

  Src := CreateCancellationTokenSource;
  Arg.Token := Src.Token;
  Arg.WorkMs := 5;
  F := P.Submit(@CancellableTaskWithArg, @Arg);

  // 过一段时间取消
  Sleep(50);
  Src.Cancel;
  Writeln('Wait=', F.WaitFor(2000), ' Cancelled=', F.IsCancelled);

  P.Shutdown; P.AwaitTermination(3000);
end.

