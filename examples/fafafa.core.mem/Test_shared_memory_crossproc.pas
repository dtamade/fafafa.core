{$CODEPAGE UTF8}
unit Test_shared_memory_crossproc;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, process;

type
  TTestCase_SharedMemory_CrossProc = class(TTestCase)
  private
    function RunHelper(const Args: array of string; out Output: string): Integer;
    function BytesToHex(const buf: RawByteString): string;
  published
    procedure Test_Shared_Write_Read_CrossProcess;
  end;

implementation

function TTestCase_SharedMemory_CrossProc.RunHelper(const Args: array of string; out Output: string): Integer;
var
  P: TProcess;
  i: Integer;
  exePath, helperPath: string;
  s: TStringList;
  function ExecHelper(const AExe: string; const AUseHelperFlag: Boolean; out AOut: string): Integer;
  var Q: TProcess; j: Integer; tmp: TStringList;
  begin
    tmp := TStringList.Create;
    Q := TProcess.Create(nil);
    try
      Q.Executable := AExe;
      Q.CurrentDirectory := ExtractFilePath(AExe);
      Q.Options := [poUsePipes, poWaitOnExit];
      if AUseHelperFlag then Q.Parameters.Add('--helper-sharedmem=1');
      for j := Low(Args) to High(Args) do Q.Parameters.Add(Args[j]);
      try
        Q.Execute;
      except
        on E: Exception do
        begin
          AOut := 'ERR: ' + E.Message;
          Exit(1);
        end;
      end;
      tmp.LoadFromStream(Q.Output);
      AOut := TrimRight(tmp.Text);
      Result := Q.ExitStatus;
    finally
      tmp.Free;
      Q.Free;
    end;
  end;
begin
  s := TStringList.Create;
  P := nil;
  try
    // 优先用内置 helper（当前测试可执行）
    exePath := ExpandFileName(ParamStr(0));
    Result := ExecHelper(exePath, True, Output);

    // 如果失败，则回退到外部 helper 可执行文件（需已构建至 bin）
    if Result <> 0 then
    begin
      helperPath := ExpandFileName('..' + DirectorySeparator + '..' + DirectorySeparator + 'bin' + DirectorySeparator + 'helper_sharedmem.exe');
      if FileExists(helperPath) then
        Result := ExecHelper(helperPath, False, Output)
      else
        Output := Output + ' (fallback helper not found)';
    end;
  finally
    s.Free;
  end;
end;

function TTestCase_SharedMemory_CrossProc.BytesToHex(const buf: RawByteString): string;
const
  Hex: PChar = '0123456789ABCDEF';
var
  i: Integer;
  b: Byte;
begin
  SetLength(Result, Length(buf)*2);
  for i := 1 to Length(buf) do
  begin
    b := Byte(buf[i]);
    Result[2*i-1] := Hex[(b shr 4) and $0F];
    Result[2*i]   := Hex[b and $0F];
  end;
end;

procedure TTestCase_SharedMemory_CrossProc.Test_Shared_Write_Read_CrossProcess;
var
  name: string;
  data: RawByteString;
  hex: string;
  outS: string;
  rc: Integer;
  W: TProcess;
  exePath: string;
  retry: Integer;
begin
  name := 'UT_SharedMem_CP_' + IntToHex(Random(MaxInt), 8);
  {$IFDEF WINDOWS}
  name := 'Local\' + name;
  {$ENDIF}
  data := UTF8Encode('跨进程共享测试/CP');
  hex := BytesToHex(data);

  // 启动 writer（不等待退出），保持一段时间以便 reader 打开
  exePath := ExpandFileName(ParamStr(0));
  W := TProcess.Create(nil);
  try
    W.Executable := exePath;
    W.CurrentDirectory := ExtractFilePath(exePath);
    W.Options := []; // 不等待，不重定向
    W.Parameters.Add('--helper-sharedmem=1');
    W.Parameters.Add('--mode=writer');
    W.Parameters.Add('--name=' + name);
    W.Parameters.Add('--data=' + hex);
    W.Parameters.Add('--hold=1500');
    W.Execute;

    // 稍等片刻让 writer 完成创建并写入
    Sleep(100);

    // reader 读取（增加重试等待 writer 完成创建）
    rc := -1;
    outS := '';
    for retry := 1 to 20 do
    begin
      rc := RunHelper(['--mode=reader', '--name='+name], outS);
      if rc = 0 then Break;
      Sleep(100);
    end;
    AssertEquals('reader rc', 0, rc);
    AssertEquals('reader should output hex', hex, outS);

    // 等待 writer 自行退出
    W.WaitOnExit;
  finally
    W.Free;
  end;
end;

initialization
  RegisterTest(TTestCase_SharedMemory_CrossProc);

end.

