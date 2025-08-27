program tests_crypto_smoke;
{$mode objfpc}{$H+}

uses
  SysUtils, Process;

function RepoRootFromBin: string;
var
  binDir: string;
begin
  binDir := ExtractFilePath(ParamStr(0));
  // binDir: tests/fafafa.core.crypto.examples_smoke/bin/
  // repo root: bin/../../..
  Result := ExpandFileName(IncludeTrailingPathDelimiter(binDir) + '..' + DirectorySeparator + '..' + DirectorySeparator + '..' + DirectorySeparator);
end;

function RunAndWait(const Cwd, Cmd: string; const Params: array of string): Integer;
var
  P: TProcess;
  i: Integer;
begin
  P := TProcess.Create(nil);
  try
    P.Options := [poUsePipes, poNoConsole];
    P.CurrentDirectory := Cwd;
    P.Executable := Cmd;
    for i := Low(Params) to High(Params) do P.Parameters.Add(Params[i]);
    P.Execute;
    P.WaitOnExit;
    Result := P.ExitStatus;
  finally
    P.Free;
  end;
end;

function OnWindows: Boolean; inline;
begin
  {$ifdef windows}
  Result := True;
  {$else}
  Result := False;
  {$endif}
end;

var
  root, scriptPath: string;
  code: Integer;
begin
  try
    root := RepoRootFromBin;
    if OnWindows then begin
      scriptPath := 'cmd';
      code := RunAndWait(root, scriptPath, ['/c', 'scripts\verify-crypto-examples.bat']);
    end else begin
      scriptPath := '/bin/sh';
      code := RunAndWait(root, scriptPath, ['-c', './scripts/verify-crypto-examples.sh']);
    end;
    if code = 0 then
      WriteLn('Crypto smoke tests: OK')
    else
      WriteLn('Crypto smoke tests: FAILED (exit code ', code, ')');
    Halt(code);
  except
    on E: Exception do begin
      WriteLn('Runner error: ', E.ClassName, ': ', E.Message);
      Halt(2);
    end;
  end;
end.

