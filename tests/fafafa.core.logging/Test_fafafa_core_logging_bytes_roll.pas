unit Test_fafafa_core_logging_bytes_roll;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.logging, fafafa.core.logging.interfaces,
  fafafa.core.logging.sinks.textsink, fafafa.core.logging.sinks.rollingfile,
  fafafa.core.logging.formatters.text;

type
  TTestCase_RollingBytes = class(TTestCase)
  published
    procedure Test_ExactBoundary_UTF8_CRLF;
    procedure Test_Boundary_PlusMinus_One;
  end;

implementation

uses Test_helpers_io;

procedure TTestCase_RollingBytes.Test_ExactBoundary_UTF8_CRLF;
var
  tmp: string; s: string; size: QWord; fs: TFileStream; actual: QWord;
  SR: TSearchRec; pat: string; hasRotate: Boolean;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'roll_utf8.txt';
  if FileExists(tmp) then DeleteFile(tmp);
  // 清理历史轮转文件
  pat := tmp + '.size-*';
  if FindFirst(pat, faAnyFile, SR) = 0 then
  begin
    repeat
      SysUtils.DeleteFile(ExtractFilePath(tmp) + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // UTF-8: '中' 占 3 字节；LineEnding 跨平台长度
  size := 3 + QWord(Length(LineEnding));
  s := '中';
  with TRollingTextFileSink.Create(tmp, size, 9, 0) do
  try
    WriteLine(s);
    Flush;
  finally
    Free;
  end;

  // 断言：文件大小等于 size，不产生任何 .size-* 轮转
  fs := TFileStream.Create(tmp, fmOpenRead or fmShareDenyNone);
  try
    actual := fs.Size;
  finally
    fs.Free;
  end;
  AssertTrue(Format('unexpected size: actual=%d expected<=%d',[actual, size]),
    (actual <= size) and (actual > 0));

  hasRotate := (FindFirst(pat, faAnyFile, SR) = 0);
  if hasRotate then FindClose(SR);
  AssertFalse('rotated unexpectedly', hasRotate);
end;

procedure TTestCase_RollingBytes.Test_Boundary_PlusMinus_One;
var
  tmp: string; L: ILogger; s: string; size: QWord; content1, content2: string;
  roll1, roll2: string;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'roll_pm1.txt';
  if FileExists(tmp) then DeleteFile(tmp);
  // 选择英文'X'，UTF-8 1 字节；CRLF 变量
  s := 'X';
  // size = (1 + EOL) 时恰好写入一行
  with TRollingTextFileSink.Create(tmp, 1 + QWord(Length(LineEnding)), 9, 0) do
  try
    WriteLine(s);
    Flush;
  finally
    Free;
  end;
  content1 := ReadAllText(tmp);
  AssertTrue(Pos(s, content1) > 0);

  // 重新用更小阈值（仅 EOL），应触发轮转后写入新文件
  with TRollingTextFileSink.Create(tmp, QWord(Length(LineEnding)), 9, 0) do
  try
    WriteLine(s);
    Flush;
  finally
    Free;
  end;
  roll1 := tmp + '.size-';
  content2 := ReadAllText(tmp);
  AssertTrue(Length(content2) > 0);
end;

initialization
  RegisterTest(TTestCase_RollingBytes);
end.

