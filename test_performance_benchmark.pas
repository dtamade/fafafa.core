program test_performance_benchmark;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TTestResult = record
    FTestName: string;
    FTimeMicroseconds: Double;
    FOperations: SizeUInt;
    FBytesProcessed: SizeUInt;
  end;

  TPerformanceReport = record
    FResults: array of TTestResult;
    FCount: Integer;
  end;

procedure AddResult(var AReport: TPerformanceReport; const AName: string; ATime: Double; AOps: SizeUInt; ABytes: SizeUInt);
procedure PrintReport(const AReport: TPerformanceReport);
function GetMicroTime: Double;

implementation

var
  FStartTime: QWord;
  FFrequency: QWord;

function GetMicroTime: Double;
var
  LCounter: QWord;
begin
  if not QueryPerformanceFrequency(FFrequency) then
    Exit(0);
  QueryPerformanceCounter(LCounter);
  Result := (LCounter / FFrequency) * 1000000; // 转换为微秒
end;

procedure AddResult(var AReport: TPerformanceReport; const AName: string; ATime: Double; AOps: SizeUInt; ABytes: SizeUInt);
begin
  if AReport.FCount >= Length(AReport.FResults) then
    SetLength(AReport.FResults, AReport.FCount + 8);

  with AReport.FResults[AReport.FCount] do
  begin
    FTestName := AName;
    FTimeMicroseconds := ATime;
    FOperations := AOps;
    FBytesProcessed := ABytes;
  end;
  Inc(AReport.FCount);
end;

procedure PrintReport(const AReport: TPerformanceReport);
var
  I: Integer;
begin
  WriteLn;
  WriteLn('╔═══════════════════════════════════════════════════════════╗');
  WriteLn('║        fafafa.core.collections 性能基准测试报告            ║');
  WriteLn('╚═══════════════════════════════════════════════════════════╝');
  WriteLn;

  for I := 0 to AReport.FCount - 1 do
  begin
    with AReport.FResults[I] do
    begin
      WriteLn('测试: ', FTestName);
      WriteLn('  时间: ', FTimeMicroseconds:0:2, ' μs');
      WriteLn('  操作: ', FOperations, ' 次');
      WriteLn('  吞吐: ', (FOperations / (FTimeMicroseconds / 1000000)):0:0, ' ops/sec');
      if FBytesProcessed > 0 then
        WriteLn('  带宽: ', (FBytesProcessed / (FTimeMicroseconds / 1000000) / 1024 / 1024):0:2, ' MB/s');
      WriteLn;
    end;
  end;
end;

end.
