program example_autodrain;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.process;

procedure RunBuilderVariant;
var
  outText: string;
begin
  WriteLn('--- Builder variant ---');
  outText := NewProcessBuilder
    .Command({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF})
    .Args({$IFDEF WINDOWS}['/c','for','/L','%i','in','(1,1,5)','do','@echo','line-%i']{$ELSE}['-c','for i in $(seq 1 5); do echo line-$i; done']{$ENDIF})
    .CaptureStdOut
    .DrainOutput(True)
    .Output;
  WriteLn(outText);
end;

procedure RunManualVariant;
var
  si: IProcessStartInfo;
  p: IProcess;
  S: TStringStream;
begin
  WriteLn('--- Manual variant ---');
  si := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  si.FileName := 'cmd.exe';
  si.Arguments := '/c for /L %i in (1,1,5) do @echo line-%i';
  {$ELSE}
  si.FileName := '/bin/sh';
  si.Arguments := '-c "for i in $(seq 1 5); do echo line-$i; done"';
  {$ENDIF}
  si.RedirectStandardOutput := True;
  si.SetDrainOutput(True);

  p := TProcess.Create(si);
  p.Start;
  if p.WaitForExit(5000) then
  begin
    // 等待后，标准流可能已被后台线程读走；此处用 CopyFrom 尝试再拷贝（若无数据则得到空串）
    if Assigned(p.StandardOutput) then
    begin
      S := TStringStream.Create('');
      try
        S.CopyFrom(p.StandardOutput, 0);
        WriteLn(S.DataString);
      finally
        S.Free;
      end;
    end;
  end;
end;

begin
  try
    RunBuilderVariant;
    RunManualVariant;
  except
    on E: Exception do
      WriteLn('Error: ', E.Message);
  end;
end.

