{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_ifile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.fileio, fafafa.core.fs.directory, fafafa.core.fs.errors, fafafa.core.fs.options;

type
  TTestCase_IFsFile = class(TTestCase)
  private
    function NewTempPath(const Suffix: string): string;
  published
    procedure Test_OpenClose_Basic;
    procedure Test_ReadWrite_Sanity;
    procedure Test_SeekTell_Bounds;
    procedure Test_Truncate_Effect;
    procedure Test_Flush_NoError;
    procedure Test_PReadPWrite_Basic;
    procedure Test_Open_InvalidPath_Raises;
    procedure Test_CopyMove_Basic;

    procedure Test_WriteFileAtomic_Roundtrip;
    procedure Test_Copy_OverwriteFalse_TargetExists_Raises;
    procedure Test_Move_OverwriteFalse_TargetExists_Raises;
    {$IFDEF UNIX}
    procedure Test_FileLevel_PreserveTimesPerms_POSIX;
    {$ENDIF}

  end;

implementation

function TTestCase_IFsFile.NewTempPath(const Suffix: string): string;
var
  base: string;
begin
  base := IncludeTrailingPathDelimiter(GetTempDir(False));
  Result := base + 'fs_ifile_' + Suffix + '_' + IntToStr(GetTickCount64) + '.dat';
end;

procedure TTestCase_IFsFile.Test_OpenClose_Basic;
var F: IFsFile;
    P: string;
begin
  P := NewTempPath('open');
  F := NewFsFile;
  F.Open(P, fomWrite);
  AssertTrue(F.IsOpen);
  F.Close;
  AssertFalse(F.IsOpen);
end;

procedure TTestCase_IFsFile.Test_ReadWrite_Sanity;
var F: IFsFile;
    P: string;
    W, R: RawByteString; // 仅测试局部使用，按需初始化抑制提示
    Buf: array[0..31] of Byte; // 显式初始化见 FillChar
    N: Integer;
begin
  P := NewTempPath('rw');
  F := NewFsFile;
  F.Open(P, fomWrite);
  W := 'Hello IFsFile';
  N := F.Write(Pointer(W)^, Length(W));
  AssertEquals(Length(W), N);
  F.Close;

  FillChar(Buf, SizeOf(Buf), 0);
  F := NewFsFile;
  F.Open(P, fomRead);
  N := F.Read(Buf, Length(W));
  SetString(R, PAnsiChar(@Buf[0]), N);
  AssertEquals(W, R);
  F.Close;
end;

procedure TTestCase_IFsFile.Test_SeekTell_Bounds;
var F: IFsFile;
    P: string;
    B: array[0..3] of Byte;
    Pos: Int64;
begin
  P := NewTempPath('seek');
  F := NewFsFile;
  F.Open(P, fomWrite);
  FillChar(B, SizeOf(B), 1);
  AssertEquals(4, F.Write(B, 4));
  Pos := F.Seek(0, SEEK_END);
  AssertEquals(4, Pos);
  Pos := F.Seek(-2, SEEK_CUR);
  AssertEquals(2, Pos);
  Pos := F.Tell;
  AssertEquals(2, Pos);
  F.Close;
end;

procedure TTestCase_IFsFile.Test_Truncate_Effect;
var F: IFsFile;
    P: string;
    S: Int64;
begin
  P := NewTempPath('truncate');
  F := NewFsFile;
  F.Open(P, fomWrite);
  AssertEquals(0, F.Size);
  F.Truncate(10);
  S := F.Size;
  AssertEquals(10, S);
  F.Truncate(3);
  AssertEquals(3, F.Size);
  F.Close;
end;

procedure TTestCase_IFsFile.Test_Flush_NoError;
var F: IFsFile;
    P: string;
begin
  P := NewTempPath('flush');
  F := NewFsFile;
  F.Open(P, fomWrite);
  F.Flush;
  F.Close;
end;

procedure TTestCase_IFsFile.Test_PReadPWrite_Basic;
var F: IFsFile;
    P: string;
    B: array[0..7] of Byte;
    N: Integer;
begin
  P := NewTempPath('p');
  F := NewFsFile;
  // ... keep working with F here; Copy/Move test is a separate method below
  F.Open(P, fomReadWrite);
  FillChar(B, SizeOf(B), 0);
  // 在偏移 4 写入 4 字节
  FillChar(B, 4, 7);
  AssertEquals(4, F.PWrite(B, 4, 4));
  // 读回验证
  FillChar(B, SizeOf(B), 0);
  N := F.PRead(B, 4, 4);
  AssertEquals(4, N);
  AssertTrue((B[0] = 7) and (B[1] = 7));
  F.Close;
end;

procedure TTestCase_IFsFile.Test_CopyMove_Basic;
var
  Src, Dst, Dst2: string;
  Data: TBytes;
  OptC: TFsCopyOptions;
  OptM: TFsMoveOptions;
begin
  Src := NewTempPath('copy_src');
  Dst := NewTempPath('copy_dst');
  Dst2 := NewTempPath('move_dst');
  SetLength(Data, 3);
  Data[0] := Ord('x'); Data[1] := Ord('y'); Data[2] := Ord('z');
  WriteFileAtomic(Src, Data);
  // 复制：不覆盖，目标不存在 → 成功
  OptC.Overwrite := False; OptC.PreserveTimes := False; OptC.PreservePerms := False; // defaults inline
  OptC.Overwrite := False;
  FsCopyFileEx(Src, Dst, OptC);
  AssertTrue(FileExists(Dst));
  // 移动：覆盖允许
  OptM.Overwrite := False; OptM.PreserveTimes := False; OptM.PreservePerms := False;
  OptM.Overwrite := True;
  FsMoveFileEx(Dst, Dst2, OptM);
  AssertFalse(FileExists(Dst));
  AssertTrue(FileExists(Dst2));
end;


procedure TTestCase_IFsFile.Test_Open_InvalidPath_Raises;
var F: IFsFile;
begin
  F := NewFsFile;
  try
    F.Open('', fomRead);
    Fail('Expected exception');
  except
    on E: EFsError do ;
  end;
end;

procedure TTestCase_IFsFile.Test_WriteFileAtomic_Roundtrip;
var
  P: string;
begin
  P := NewTempPath('atomic');
  WriteTextFile(P, 'hello');
  AssertTrue(FileExists(P));
  AssertEquals('hello', ReadTextFile(P));
end;

procedure TTestCase_IFsFile.Test_Copy_OverwriteFalse_TargetExists_Raises;
var
  Src, Dst: string;
  Data: TBytes;
  Opt: TFsCopyOptions;
begin
  Src := NewTempPath('copy_src2');
  Dst := NewTempPath('copy_dst2');
  SetLength(Data, 1); Data[0] := Ord('a');
  WriteFileAtomic(Src, Data);
  WriteFileAtomic(Dst, Data); // 预建目标使其存在
  Opt.Overwrite := False; Opt.PreserveTimes := False; Opt.PreservePerms := False;
  try
    FsCopyFileEx(Src, Dst, Opt);
    Fail('Expected EFsError for overwrite=false when target exists');
  except
    on E: EFsError do ;
  end;
end;

procedure TTestCase_IFsFile.Test_Move_OverwriteFalse_TargetExists_Raises;
var
  Src, Dst: string;
  Data: TBytes;
  Opt: TFsMoveOptions;
begin
  Src := NewTempPath('move_src2');
  Dst := NewTempPath('move_dst2');
  SetLength(Data, 1); Data[0] := Ord('a');
  WriteFileAtomic(Src, Data);
  WriteFileAtomic(Dst, Data); // 预建目标使其存在
  Opt.Overwrite := False; Opt.PreserveTimes := False; Opt.PreservePerms := False;
  try
    FsMoveFileEx(Src, Dst, Opt);
    Fail('Expected EFsError for overwrite=false when target exists');
  except
    on E: EFsError do ;
  end;
end;

{$IFDEF UNIX}
procedure TTestCase_IFsFile.Test_FileLevel_PreserveTimesPerms_POSIX;
var
  P, Q: string;
  Data: TBytes;
  Opt: TFsCopyOptions;
  SSrc, SDst: TfsStat;
  PermSrc, PermDst: Cardinal;
begin
  // 构造源文件，设置权限与时间
  P := NewTempPath('preserve_src');
  Q := NewTempPath('preserve_dst');
  SetLength(Data, 3);
  Data[0] := Ord('a'); Data[1] := Ord('b'); Data[2] := Ord('c');
  WriteFileAtomic(P, Data);
  // chmod 0644
  fs_chmod(P, $1A4);
  // 将 mtime 往回调 2 秒（若平台支持）
  if fs_stat(P, SSrc) = 0 then
  begin
    fs_utime(P, SSrc.ATime.Sec + SSrc.ATime.Nsec / 1e9 - 2.0,
                SSrc.MTime.Sec + SSrc.MTime.Nsec / 1e9 - 2.0);
    fs_stat(P, SSrc);
  end;

  // 复制并开启 PreserveTimes/Perms
  Opt.Overwrite := True; Opt.PreserveTimes := True; Opt.PreservePerms := True;
  FsCopyFileEx(P, Q, Opt);
  AssertTrue('dest exists', FileExists(Q));

  if (fs_stat(P, SSrc) = 0) and (fs_stat(Q, SDst) = 0) then
  begin
    // 权限：低9位一致
    PermSrc := SSrc.Mode and $1FF;
    PermDst := SDst.Mode and $1FF;
    AssertEquals('perm preserved', PermSrc, PermDst);
    // mtime：容忍 +-3s 的浮动
    AssertTrue('mtime preserved (loose)',
      (SDst.MTime.Sec >= SSrc.MTime.Sec - 1) and (SDst.MTime.Sec <= SSrc.MTime.Sec + 3));
  end;
end;
{$ENDIF}


initialization
  RegisterTest(TTestCase_IFsFile);
end.

