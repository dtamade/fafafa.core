unit Test_fafafa_core_logging_roll_count;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fpcunit, testregistry,
  fafafa.core.logging.interfaces,
  fafafa.core.logging.sinks.rollingfile.count;

type
  TTestCase_RollingCount = class(TTestCase)
  published
    procedure Test_Count_Rotate_At_N;
    procedure Test_Count_No_Rotate_Below_N;
  end;

implementation

procedure TTestCase_RollingCount.Test_Count_Rotate_At_N;
var
  tmp: string; base: string; N: QWord; SR: TSearchRec; hasRotate: Boolean;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'count.log';
  base := ChangeFileExt(tmp, '');
  if FileExists(tmp) then DeleteFile(tmp);
  // 清理历史
  if FindFirst(base + '.count-*', faAnyFile, SR) = 0 then begin repeat until FindNext(SR) <> 0; FindClose(SR); end;

  N := 3;
  with TRollingCountTextFileSink.Create(tmp, N, 9) do
  try
    WriteLine('a');
    WriteLine('b');
    WriteLine('c'); // 第 N 行写入后，下一次写应触发轮转
    WriteLine('d');
    Flush;
  finally
    Free;
  end;

  hasRotate := (FindFirst(base + '.count-*', faAnyFile, SR) = 0);
  if hasRotate then FindClose(SR);
  AssertTrue('should have rotated', hasRotate);
end;

procedure TTestCase_RollingCount.Test_Count_No_Rotate_Below_N;
var
  tmp: string; base: string; N: QWord; SR: TSearchRec; hasRotate: Boolean;
begin
  tmp := 'tests' + DirectorySeparator + 'fafafa.core.logging' + DirectorySeparator + 'bin' + DirectorySeparator + 'count2.log';
  base := ChangeFileExt(tmp, '');
  if FileExists(tmp) then DeleteFile(tmp);
  if FindFirst(base + '.count-*', faAnyFile, SR) = 0 then begin repeat until FindNext(SR) <> 0; FindClose(SR); end;

  N := 3;
  with TRollingCountTextFileSink.Create(tmp, N, 9) do
  try
    WriteLine('a');
    WriteLine('b');
    // 未达到 N，不应轮转
    Flush;
  finally
    Free;
  end;

  hasRotate := (FindFirst(base + '.count-*', faAnyFile, SR) = 0);
  if hasRotate then FindClose(SR);
  AssertFalse('should not rotate', hasRotate);
end;

initialization
  RegisterTest(TTestCase_RollingCount);
end.

