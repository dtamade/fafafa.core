program example_redirect_file_and_capture_err;

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
  OutFile: string;
  Fs: TFileStream;
  ErrStr: string;
  ok: Boolean;
begin
  WriteLn('=== Redirect stdout to file, capture stderr in memory ===');
  OutFile := 'out_redirect.txt';

  {$IFDEF WINDOWS}
  // 产生 stdout + stderr + 非零退出
  B := NewProcessBuilder.Command('cmd.exe').Args([
    '/c','powershell','-NoProfile','-Command',
    'Write-Output "OUT1"; Write-Error "ERR1"; Write-Output "OUT2"; exit 3'
  ]);
  {$ELSE}
  B := NewProcessBuilder.Command('/bin/sh').Args(['-c','echo OUT1; echo ERR1 1>&2; echo OUT2; exit 3']);
  {$ENDIF}

  // 重定向 stdout/stderr；启用后台排水以避免阻塞
  B.RedirectStdOut(True).RedirectStdErr(True).DrainOutput(True);
  C := B.Start;

  ok := C.WaitForExit(5000);
  if not ok then
  begin
    WriteLn('Timeout waiting process, killing...');
    C.Kill;
    Halt(1);
  end;

  // 将 stdout 写入文件（使用后台排水后由缓冲替换流，保证可读取）
  Fs := TFileStream.Create(OutFile, fmCreate);
  try
    if C.StandardOutput <> nil then
      Fs.CopyFrom(C.StandardOutput, 0);
  finally
    Fs.Free;
  end;

  // 读取 stderr 内容到内存并打印
  ErrStr := StreamToString(C.StandardError);
  WriteLn('Captured stderr (memory):');
  WriteLn(ErrStr);

  WriteLn('ExitCode = ', C.ExitCode);
  WriteLn('Stdout redirected to: ', OutFile);
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

