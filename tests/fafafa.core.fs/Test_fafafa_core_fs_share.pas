{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_share;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.highlevel;

{$IFNDEF WINDOWS}
{$WARN 5057 off}
{$ENDIF}

type
  TTestCase_Share = class(TTestCase)
  private
    FTempDir: string;
    FFile: string;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Share_ReadBlocksWrite_WhenReadOnlyShare;
    procedure Test_Share_ReadWrite_AllowsReadOnly;
    procedure Test_Share_DeleteBlocked_WhenNoDeleteShare;
  end;

implementation

procedure TTestCase_Share.SetUp;
begin
  inherited SetUp;
  FTempDir := 'share_root_' + IntToStr(Random(100000));
  if not DirectoryExists(FTempDir) then ForceDirectories(FTempDir);
  FFile := IncludeTrailingPathDelimiter(FTempDir) + 's.bin';
  with TStringList.Create do
  try
    Text := 'x';
    SaveToFile(FFile);
  finally
    Free;
  end;
end;

procedure TTestCase_Share.TearDown;
begin
  try
    DeleteFile(FFile);
    RemoveDir(FTempDir);
  except
  end;
  inherited TearDown;
end;

procedure TTestCase_Share.Test_Share_ReadBlocksWrite_WhenReadOnlyShare;
var
  F1, F2: IFsFile;
  Raised: Boolean;
begin
  {$IFNDEF WINDOWS}
  // 非 Windows 下忽略共享语义，仅验证不抛异常
  F1 := NewFsFile; F1.Open(FFile, fomRead, [fsmRead]);
  F1.Close;
  AssertTrue(True);
  Exit;
  {$ENDIF}

  // 1) 第一个只读打开，且只共享读取
  F1 := NewFsFile;
  F1.Open(FFile, fomRead, [fsmRead]);
  try
    // 2) 第二个尝试以写入打开，预期失败（共享冲突）
    F2 := NewFsFile;
    Raised := False;
    try
      F2.Open(FFile, fomWrite, []); // 未声明 share-write，应被拒
    except
      on E: EFsError do Raised := True;
    end;
    AssertTrue('second writer should fail when first only shares read', Raised);
  finally
    F1.Close;
  end;
end;

procedure TTestCase_Share.Test_Share_ReadWrite_AllowsReadOnly;
var
  F1, F2: IFsFile;
  Buf: array[0..0] of Byte;
  N: Integer;
begin
  {$IFNDEF WINDOWS}
  // 非 Windows 下忽略共享语义，直接通过
  AssertTrue(True);
  Exit;
  {$ENDIF}

  // 1) 第一个以读写打开，声明共享读写
  F1 := NewFsFile;
  F1.Open(FFile, fomReadWrite, [fsmRead, fsmWrite]);
  try
    // 2) 第二个以只读打开，预期成功
    F2 := NewFsFile;
    F2.Open(FFile, fomRead, [fsmRead]);

    // 读几字节确认句柄可用
    N := F2.Read(Buf, SizeOf(Buf));
    AssertTrue(N >= 0);
    // 关闭第二个
    F2.Close;
  finally
    F1.Close;

procedure TTestCase_Share.Test_Share_DeleteBlocked_WhenNoDeleteShare;
var
  F1: IFsFile;
  DelOK: Boolean;
begin
  {$IFNDEF WINDOWS}
  // 非 Windows 下共享删除语义不可用
  AssertTrue(True);
  Exit;
  {$ENDIF}

  // 第一个只读打开，但不共享删除
  F1 := NewFsFile;
  F1.Open(FFile, fomRead, [fsmRead]); // 无 fsmDelete
  try
    // 尝试删除，应失败
    DelOK := DeleteFile(FFile);
    AssertFalse('delete should be blocked without share delete', DelOK);
  finally
    F1.Close;
  end;
  // 关闭后再删，应成功
  DelOK := DeleteFile(FFile);
  AssertTrue('delete should succeed after close', DelOK);
end;

initialization
  RegisterTest(TTestCase_Share);
end.

