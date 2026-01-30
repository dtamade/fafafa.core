unit test_autodrain_wait0_finalize;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process;

type
  TTestCase_AutoDrain_Wait0 = class(TTestCase)
  published
    procedure Test_Wait0_Path_Finalizes_Buffer;
  end;

implementation

procedure TTestCase_AutoDrain_Wait0.Test_Wait0_Path_Finalizes_Buffer;
var
  SI: IProcessStartInfo;
  P: IProcess;
  Done: Boolean;
  Attempts: Integer;
  S: TStringStream;
  OutText: string;
begin
  SI := TProcessStartInfo.Create;
  {$IFDEF WINDOWS}
  SI.FileName := 'cmd.exe';
  SI.Arguments := '/c for /L %i in (1,1,10) do @echo L-%i';
  {$ELSE}
  SI.FileName := '/bin/sh';
  SI.Arguments := '-c "for i in $(seq 1 10); do echo L-$i; done"';
  {$ENDIF}
  SI.RedirectStandardOutput := True;
  SI.RedirectStandardError := True;
  SI.SetDrainOutput(True);

  P := TProcess.Create(SI);
  P.Start;

  // 多次 WaitForExit(0) 直到完成，模拟快速探测路径
  Attempts := 0;
  repeat
    Done := P.WaitForExit(0);
    Inc(Attempts);
    if not Done then
      Sleep(5);
  until Done or (Attempts > 200);

  CheckTrue(Done, 'Process should eventually finish');

  // 完成后，标准输出应可被复制（可能来自内存缓冲）
  OutText := '';
  if Assigned(P.StandardOutput) then
  begin
    S := TStringStream.Create('');
    try
      S.CopyFrom(P.StandardOutput, 0);
      OutText := S.DataString;
    finally
      S.Free;
    end;
  end;

  CheckNotEquals(0, Pos('L-', OutText), 'Output should contain drained lines');
end;

initialization
  RegisterTest(TTestCase_AutoDrain_Wait0);

end.

