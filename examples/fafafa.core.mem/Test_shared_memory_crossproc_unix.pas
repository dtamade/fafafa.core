{$CODEPAGE UTF8}
unit Test_shared_memory_crossproc_unix;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry, process;

type
  TTestCase_SharedMemory_CrossProc_Unix = class(TTestCase)
  private
    function RunHelper(const Args: array of string; out Output: string): Integer;
    function BytesToHex(const buf: RawByteString): string;
  published
    procedure Test_Shared_Write_Read_CrossProcess_Unix;
  end;

implementation

function TTestCase_SharedMemory_CrossProc_Unix.RunHelper(const Args: array of string; out Output: string): Integer;
var
  P: TProcess;
  i: Integer;
  s: TStringList;
begin
  s := TStringList.Create;
  P := TProcess.Create(nil);
  try
    // 使用当前测试可执行文件作为 helper（与 Windows 版本一致）
    P.Executable := ParamStr(0);
    P.CurrentDirectory := ExtractFilePath(ParamStr(0));
    P.Options := [poUsePipes, poWaitOnExit, poNoConsole];
    P.Parameters.Add('--helper-sharedmem=1');
    for i := Low(Args) to High(Args) do
      P.Parameters.Add(Args[i]);
    try
      P.Execute;
    except
      on E: Exception do
      begin
        Output := 'ERR: ' + E.Message;
        Result := 1;
        Exit;
      end;
    end;
    s.LoadFromStream(P.Output);
    Output := TrimRight(s.Text);
    Result := P.ExitStatus;
  finally
    s.Free;
    P.Free;
  end;
end;

function TTestCase_SharedMemory_CrossProc_Unix.BytesToHex(const buf: RawByteString): string;
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

procedure TTestCase_SharedMemory_CrossProc_Unix.Test_Shared_Write_Read_CrossProcess_Unix;
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
  name := '/UT_SharedMem_CP_' + IntToHex(Random(MaxInt), 8);
  data := UTF8Encode('跨进程共享测试/Unix');
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
  RegisterTest(TTestCase_SharedMemory_CrossProc_Unix);

end.

