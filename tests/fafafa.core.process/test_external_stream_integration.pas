{$CODEPAGE UTF8}
unit test_external_stream_integration;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.process,
  test_support.process_cmds;

Type
  TTestCase_ExternalStream = class(TTestCase)
  published
    procedure Test_StdOut_Attach_FileStream_Writes_Large_Data;
  end;

implementation

procedure TTestCase_ExternalStream.Test_StdOut_Attach_FileStream_Writes_Large_Data;
var
  Bytes: Integer;
  OutFile: string;
  FS: TFileStream;
  B: IProcessBuilder;
  C: IChild;
  FSz: TFileStream;
  Size64: Int64;
begin
  Bytes := 5 * 1024 * 1024; // 5MB
  OutFile := GetTempDir(False) + 'fafafa_proc_ext_out.log';
  if FileExists(OutFile) then DeleteFile(OutFile);

  FS := TFileStream.Create(OutFile, fmCreate);
  try
    B := NewLargeOutputCommand(Bytes)
           .CaptureStdOut
           .DrainOutput(True);
    B.GetStartInfo.AttachStdOut(FS, False); // 不转移拥有权

    C := B.Start;
    CheckTrue(C.WaitForExit(60000), '应在 60s 内结束');
    FS.Free; // 先关闭文件
    FS := nil;

    CheckTrue(FileExists(OutFile), '输出文件应存在');
    // 用文件流读取大小，避免旧式 FileSize(File) 的 var 形参签名
    FSz := TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone);
    try
      Size64 := FSz.Size;
    finally
      FSz.Free;
    end;
    CheckTrue(Size64 >= (Bytes * 8 div 10), '输出文件大小至少应为期望的 80%');
  finally
    if FS <> nil then FS.Free;
    try DeleteFile(OutFile); except end;
  end;
end;

initialization
  RegisterTest(TTestCase_ExternalStream);

end.

