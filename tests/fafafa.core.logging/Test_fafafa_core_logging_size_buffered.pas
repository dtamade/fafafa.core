unit Test_fafafa_core_logging_size_buffered;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.logging.sinks.rollingfile;

type
  TTestCase_SizeBuffered = class(TTestCase)
  published
    procedure Test_SizeBuffered_NoRotate_ExactBoundary_ASCII;
    procedure Test_SizeBuffered_Aggregate_NoOverflow_NoRotate;
  end;

implementation

procedure CleanPattern(const ABase, ASuffixMask: string);
var SR: TSearchRec; pat, dir: string;
begin
  dir := ExtractFilePath(ABase);
  pat := ChangeFileExt(ABase, '') + ASuffixMask;
  if FindFirst(pat, faAnyFile, SR) = 0 then
  begin
    repeat
      SysUtils.DeleteFile(dir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

procedure TTestCase_SizeBuffered.Test_SizeBuffered_NoRotate_ExactBoundary_ASCII;
var
  tmp, base: string; size: QWord; fs: TFileStream; actual: QWord;
  buf: Integer;
  SR: TSearchRec;
  hasRotate: Boolean;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'size_buf.log';
  base := ChangeFileExt(tmp, '');
  if FileExists(tmp) then DeleteFile(tmp);
  CleanPattern(tmp, '.size-*');

  // ASCII 安全，避免编码差异；'abc' 3 字节 + EOL
  size := 3 + QWord(Length(LineEnding));
  buf := 16 * 1024;
  with TRollingTextFileSink.Create(tmp, size, 9, 0, buf) do
  try
    WriteLine('abc');
    Flush;
  finally
    Free;
  end;

  fs := TFileStream.Create(tmp, fmOpenRead or fmShareDenyNone);
  try
    actual := fs.Size;
  finally
    fs.Free;
  end;
  AssertTrue(Format('unexpected size: actual=%d expected<=%d',[actual, size]), (actual > 0) and (actual <= size));

  // 不应发生滚动
  hasRotate := (FindFirst(base + '.size-*', faAnyFile, SR) = 0);
  if hasRotate then FindClose(SR);
  AssertFalse('rotated unexpectedly', hasRotate);
end;

procedure TTestCase_SizeBuffered.Test_SizeBuffered_Aggregate_NoOverflow_NoRotate;
var
  tmp, base: string; size: QWord; fs: TFileStream; actual: QWord;
  buf: Integer; i: Integer;
  SR: TSearchRec;
  hasRotate: Boolean;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'size_buf2.log';
  base := ChangeFileExt(tmp, '');
  if FileExists(tmp) then DeleteFile(tmp);
  CleanPattern(tmp, '.size-*');

  // 聚合 4 行，每行 'x' => 1 字节 + EOL；设置阈值 = 3 行容量（确保写 3 行仍不转，写第 4 行需要判断/冲刷但最终不越界）
  size := (1 + QWord(Length(LineEnding))) * 3;
  buf := 16 * 1024;
  with TRollingTextFileSink.Create(tmp, size, 9, 0, buf) do
  try
    for i := 1 to 3 do WriteLine('x');
    // 第 4 行先不写，验证当前状态
    Flush;
  finally
    Free;
  end;

  fs := TFileStream.Create(tmp, fmOpenRead or fmShareDenyNone);
  try
    actual := fs.Size;
  finally
    fs.Free;
  end;

  AssertEquals(size, actual); // 恰好等于 3 行容量
  hasRotate := (FindFirst(base + '.size-*', faAnyFile, SR) = 0);
  if hasRotate then FindClose(SR);
  AssertFalse('rotated unexpectedly', hasRotate);
end;

initialization
  RegisterTest(TTestCase_SizeBuffered);
end.

