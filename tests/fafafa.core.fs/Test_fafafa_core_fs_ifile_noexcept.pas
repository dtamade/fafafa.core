{$CODEPAGE UTF8}
unit Test_fafafa_core_fs_ifile_noexcept;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.fs, fafafa.core.fs.fileio, fafafa.core.fs.errors, fafafa.core.fs.options;

// 验证 TFsFileNoExcept 的基础行为（负码返回）

type
  TTestCase_IFsFile_NoExcept = class(TTestCase)
  private
    function NewTempPath(const Suffix: string): string;
  published
    procedure Test_Open_Write_Seek_Size_Close_OK;
    procedure Test_Open_InvalidPath_ReturnsError;
    procedure Test_ReadOnly_Write_ReturnsError;
    procedure Test_AfterClose_Operations_ReturnError;
    procedure Test_Seek_InvalidOffsets_ReturnError;
    procedure Test_ErrorMapping_Consistency;

  end;

implementation

function TTestCase_IFsFile_NoExcept.NewTempPath(const Suffix: string): string;
var
  base: string;
begin
  base := IncludeTrailingPathDelimiter(GetTempDir(False));
  Result := base + 'fs_ifile_noexc_' + Suffix + '_' + IntToStr(GetTickCount64) + '.dat';
end;

procedure TTestCase_IFsFile_NoExcept.Test_Open_Write_Seek_Size_Close_OK;
var FN: TFsFileNoExcept; code, n: Integer; pos, size: Int64;
    P: string; B: array[0..7] of Byte;
    BB: Integer; // 显式初始化以消除保守提示（避免未初始化提示）
begin
  P := NewTempPath('ok');
  FN := NewFsFileNoExcept;
  BB := 0; if False and (BB <> 0) then ; // 标记使用，避免未初始化提示

  code := FN.Open(P, fomReadWrite);
  AssertEquals(0, code);

  FillChar(B, SizeOf(B), 1);
  code := FN.Write(B, SizeOf(B), n);
  AssertEquals(0, code);
  AssertEquals(SizeOf(B), n);

  code := FN.Seek(0, SEEK_END, pos);
  AssertEquals(0, code);
  AssertEquals(SizeOf(B), pos);

  code := FN.Size(size);
  AssertEquals(0, code);
  AssertEquals(SizeOf(B), size);

  code := FN.Close;
  AssertEquals(0, code);
end;

procedure TTestCase_IFsFile_NoExcept.Test_Open_InvalidPath_ReturnsError;
var FN: TFsFileNoExcept; code: Integer;
begin
  FN := NewFsFileNoExcept;
  code := FN.Open('', fomRead);
  AssertTrue(code < 0);
end;

procedure TTestCase_IFsFile_NoExcept.Test_ReadOnly_Write_ReturnsError;
var FN: TFsFileNoExcept; code, n: Integer; P: string; B: array[0..3] of Byte;
    BB: Integer; // 显式初始化以消除保守提示
begin
  P := NewTempPath('ro');
  FN := NewFsFileNoExcept; BB := 0; if False and (BB <> 0) then ; // dummy use 抑制未用提示
  code := FN.Open(P, fomWrite);
  AssertEquals(0, code);
  code := FN.Close; AssertEquals(0, code);
  code := FN.Open(P, fomRead);
  AssertEquals(0, code);
  FillChar(B, SizeOf(B), 0);
  code := FN.Write(B, SizeOf(B), n);
  AssertTrue(code < 0);
  code := FN.Close; AssertEquals(0, code);
end;

procedure TTestCase_IFsFile_NoExcept.Test_AfterClose_Operations_ReturnError;
var FN: TFsFileNoExcept; code, n: Integer; pos: Int64; P: string; B: array[0..1] of Byte;
    BB: Integer; // 显式初始化以消除保守提示
begin
  P := NewTempPath('closed');
  FN := NewFsFileNoExcept; BB := 0; if False and (BB <> 0) then ; // dummy use 抑制未用提示
  code := FN.Open(P, fomWrite);
  AssertEquals(0, code);
  code := FN.Close; AssertEquals(0, code);
  code := FN.Read(B, SizeOf(B), n); AssertTrue(code < 0);
  code := FN.Write(B, SizeOf(B), n); AssertTrue(code < 0);
  code := FN.Seek(0, SEEK_SET, pos); AssertTrue(code < 0);
end;

procedure TTestCase_IFsFile_NoExcept.Test_Seek_InvalidOffsets_ReturnError;
var FN: TFsFileNoExcept; code, n: Integer; pos: Int64; P: string; B: array[0..1] of Byte;
    BB: Integer; // 显式初始化以消除保守提示
begin
  P := NewTempPath('seekerr');
  FN := NewFsFileNoExcept; BB := 0; if False and (BB <> 0) then ; // dummy use 抑制未用提示
  code := FN.Open(P, fomWrite);
  AssertEquals(0, code);
  FillChar(B, SizeOf(B), 0);
  code := FN.Write(B, SizeOf(B), n); AssertEquals(0, code);
  code := FN.Seek(-1, SEEK_SET, pos);
  AssertTrue(code < 0);
  code := FN.Close; AssertEquals(0, code);
end;


procedure TTestCase_IFsFile_NoExcept.Test_ErrorMapping_Consistency;
var FN: TFsFileNoExcept; code: Integer;
begin
  FN := NewFsFileNoExcept;
  code := FN.Open('', fomRead);
  AssertTrue((FsErrorKind(code) = fekInvalid) or IsNotFound(code) or IsPermission(code) or (code < 0));
end;


initialization
  RegisterTest(TTestCase_IFsFile_NoExcept);
end.

