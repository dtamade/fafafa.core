program example_capture_stdout_redirect_err;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils, Classes,
  fafafa.core.process;

function StreamToString(S: TStream): string;
var
  RB: RawByteString;
begin
  if S = nil then Exit('');
  SetLength(RB, S.Size);
  if S.Size > 0 then
  begin
    S.Position := 0;
    S.ReadBuffer(Pointer(RB)^, S.Size);
  end;
  {$ifdef FPC_HAS_CPSTRING}
  SetCodePage(RB, CP_UTF8, False);
  {$endif}
  Result := string(RB);
end;

procedure RunDemo;
var
  B: IProcessBuilder;
  C: IChild;
  ErrFile: string;
  Fs: TFileStream;
  OutStr: string;
  ok: Boolean;
begin
  WriteLn('=== Capture stdout in memory, redirect stderr to file ===');
  ErrFile := 'err_redirect.txt';

  {$IFDEF WINDOWS}
  B := NewProcessBuilder.Command('cmd.exe').Args([
    '/c','powershell','-NoProfile','-Command',
    'Write-Output "OUT1"; Write-Error "ERR1"; Write-Output "OUT2"; exit 2'
  ]);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','echo OUT1; echo ERR1 1>&2; echo OUT2; exit 2']);
  {$ENDIF}

  // 重定向并启用后台排水（避免管道阻塞）
  B.RedirectStdOut(True).RedirectStdErr(True).DrainOutput(True);
  C := B.Start;

  ok := C.WaitForExit(5000);
  if not ok then
  begin
    WriteLn('Timeout waiting process, killing...');
    C.Kill;
    Halt(1);
  end;

  // 捕获 stdout 到内存
  OutStr := StreamToString(C.StandardOutput);
  WriteLn('Captured stdout (memory):');
  WriteLn(OutStr);

  // 将 stderr 写入文件
  Fs := TFileStream.Create(ErrFile, fmCreate);
  try
    if C.StandardError <> nil then
      Fs.CopyFrom(C.StandardError, 0);
  finally
    Fs.Free;
  end;

  WriteLn('ExitCode = ', C.ExitCode);
  WriteLn('Stderr redirected to: ', ErrFile);
end;

begin
  try
    RunDemo;
  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.ClassName, ': ', E.Message);
      Halt(1);
    end;
  end;
end.

