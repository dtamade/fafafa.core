unit fafafa.core.test.listener.console;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes, fafafa.core.test.core;

type
  TConsoleTestListener = class(TInterfacedObject, ITestListener)
  private
    FStartTick: QWord;
    FTotalSeen: Integer;
    FFailed: Integer;
  public
{$push}
{$warn 5024 off}
    procedure OnStart(ATotal: Integer);
    procedure OnTestStart(const AName: string);
    procedure OnTestSuccess(const AName: string; AElapsedMs: QWord);
    procedure OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
    procedure OnTestSkipped(const AName: string; AElapsedMs: QWord);
    procedure OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
{$pop}
  end;

implementation

const
  CONSOLE_TIME_COL_WIDTH = 5;


// Helpers to silence unused-parameter hints without changing behavior
procedure UnusedInt(const v: Integer); inline; begin end;
procedure UnusedQ(const v: QWord); inline; begin end;
procedure UnusedStr(const v: string); inline; begin end;

var
  GConsoleTimeColWidth: Integer = CONSOLE_TIME_COL_WIDTH;

function SplitCleanupMessage(const Msg: string; out MainMsg: string; out Cleanup: TStringList): boolean;
var p, i: Integer; head, tail: string; lines: TStringList;
begin
  Cleanup := TStringList.Create;
  Result := False;
  // prefer explicit [cleanup] marker
  p := Pos(LineEnding + '[cleanup]' + LineEnding, Msg);
  if p > 0 then
  begin
    head := Copy(Msg, 1, p-1);
    tail := Copy(Msg, p + Length(LineEnding + '[cleanup]' + LineEnding), MaxInt);
    MainMsg := Trim(head);
    lines := TStringList.Create;
    try
      lines.Text := tail;
      for i := 0 to lines.Count-1 do
        if Trim(lines[i]) <> '' then Cleanup.Add(Trim(lines[i]));
    finally
      lines.Free;
    end;
    Exit(True);
  end;
  // fallback: starts with 'cleanup errors:'
  if Pos('cleanup errors:', Msg) = 1 then
  begin
    MainMsg := 'cleanup errors';
    lines := TStringList.Create;
    try
      lines.Text := Copy(Msg, Length('cleanup errors:')+1, MaxInt);
      for i := 0 to lines.Count-1 do
        if Trim(lines[i]) <> '' then Cleanup.Add(Trim(lines[i]));
    finally
      lines.Free;
    end;
    Exit(True);
  end;
  MainMsg := Msg;
end;

procedure TConsoleTestListener.OnStart(ATotal: Integer);
var s: string; v: Integer;
begin
  UnusedInt(ATotal);
  FStartTick := GetTickCount64;
  FTotalSeen := 0;
  FFailed := 0;
  // 运行期可选覆盖列宽：FAFAFA_CONSOLE_TIME_COL_WIDTH（1..12）
  s := GetEnvironmentVariable('FAFAFA_CONSOLE_TIME_COL_WIDTH');
  if s <> '' then
  begin
    try
      v := StrToInt(s);
      if (v >= 1) and (v <= 12) then GConsoleTimeColWidth := v;
    except
      // ignore invalid values
    end;
  end;
  // Subtest数量在运行时才确定，起始不显示预估值
  WriteLn('== Running tests ==');
end;

procedure TConsoleTestListener.OnTestStart(const AName: string);
begin
  UnusedStr(AName);
  // no-op or could print starting message
end;

procedure TConsoleTestListener.OnTestSuccess(const AName: string; AElapsedMs: QWord);
begin
  Inc(FTotalSeen);
  // 统一列宽：右对齐耗时 5 列，便于扫描
  WriteLn(Format('[ OK ] %s (%*d ms)', [AName, GConsoleTimeColWidth, AElapsedMs]));
end;

procedure TConsoleTestListener.OnTestFailure(const AName, AMessage: string; AElapsedMs: QWord);
var main: string; cleanup: TStringList; i, digits: Integer;
begin
  Inc(FTotalSeen);
  Inc(FFailed);
  cleanup := nil;
  if SplitCleanupMessage(AMessage, main, cleanup) then
  begin
    // 对齐最佳实践：保持列稳定，方便肉眼扫描
    // 格式：[FAIL] name (00012 ms): message
    WriteLn(Format('[FAIL] %s (%*d ms): %s', [AName, GConsoleTimeColWidth, AElapsedMs, main]));
    if (cleanup <> nil) and (cleanup.Count > 0) then
    begin
      // 统一缩进：标题与条目均以 11 个空格起始，并与上行对齐
      WriteLn(Format('           cleanup (%d):', [cleanup.Count]));
      digits := Length(IntToStr(cleanup.Count));
      for i := 0 to cleanup.Count-1 do
        WriteLn(Format('           %*d) %s', [digits, i+1, cleanup[i]]));
    end;
    cleanup.Free;
  end
  else
    // 同上，对非 cleanup 情况也应用对齐
    WriteLn(Format('[FAIL] %s (%*d ms): %s', [AName, GConsoleTimeColWidth, AElapsedMs, AMessage]));
end;

procedure TConsoleTestListener.OnTestSkipped(const AName: string; AElapsedMs: QWord);
begin
  Inc(FTotalSeen);
  // 统一列宽：右对齐耗时 5 列
  WriteLn(Format('[SKIP] %s (%*d ms)', [AName, GConsoleTimeColWidth, AElapsedMs]));
end;

procedure TConsoleTestListener.OnEnd(ATotal, AFailed: Integer; AElapsedMs: QWord);
var TotalTime: QWord;
begin
  UnusedInt(ATotal);
  UnusedInt(AFailed);
  UnusedQ(AElapsedMs);
  TotalTime := GetTickCount64 - FStartTick;
  if FFailed = 0 then
    WriteLn(Format('== All %d test(s) passed in %d ms ==', [FTotalSeen, TotalTime]))
  else
    WriteLn(Format('== %d/%d test(s) failed in %d ms ==', [FFailed, FTotalSeen, TotalTime]));
end;

end.

