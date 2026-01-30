program example_sliding_window;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.vecdeque;

type
  { 滑动窗口统计器 }
  TSlidingWindowStats = class
  private
    FWindow: specialize IVecDeque<Double>;
    FMaxSize: SizeUInt;
  public
    constructor Create(aWindowSize: SizeUInt);
    procedure Add(aValue: Double);
    function GetAverage: Double;
    function GetMax: Double;
    function GetMin: Double;
    procedure Print;
  end;

constructor TSlidingWindowStats.Create(aWindowSize: SizeUInt);
begin
  FMaxSize := aWindowSize;
  FWindow := specialize MakeVecDeque<Double>(aWindowSize);
end;

procedure TSlidingWindowStats.Add(aValue: Double);
begin
  if FWindow.GetCount >= FMaxSize then
    FWindow.PopFront; // 移除最旧的值
  
  FWindow.PushBack(aValue);
end;

function TSlidingWindowStats.GetAverage: Double;
var
  LSum: Double;
  LValue: Double;
begin
  if FWindow.GetCount = 0 then
    Exit(0);
  
  LSum := 0;
  for LValue in FWindow do
    LSum := LSum + LValue;
  
  Result := LSum / FWindow.GetCount;
end;

function TSlidingWindowStats.GetMax: Double;
var
  LValue: Double;
begin
  if FWindow.GetCount = 0 then
    Exit(0);
  
  Result := FWindow[0];
  for LValue in FWindow do
    if LValue > Result then
      Result := LValue;
end;

function TSlidingWindowStats.GetMin: Double;
var
  LValue: Double;
begin
  if FWindow.GetCount = 0 then
    Exit(0);
  
  Result := FWindow[0];
  for LValue in FWindow do
    if LValue < Result then
      Result := LValue;
end;

procedure TSlidingWindowStats.Print;
var
  i: SizeUInt;
begin
  Write('窗口数据: [');
  for i := 0 to FWindow.GetCount - 1 do
  begin
    Write(Format('%.1f', [FWindow[i]]));
    if i < FWindow.GetCount - 1 then
      Write(', ');
  end;
  WriteLn(']');
  
  WriteLn(Format('  平均值: %.2f', [GetAverage]));
  WriteLn(Format('  最大值: %.1f', [GetMax]));
  WriteLn(Format('  最小值: %.1f', [GetMin]));
end;

var
  LStats: TSlidingWindowStats;
  LValues: array[0..9] of Double = (
    10.5, 12.3, 9.8, 15.2, 11.0,
    13.5, 8.9, 14.1, 10.2, 12.8
  );
  i: Integer;
begin
  WriteLn('=== 滑动窗口统计示例 ===');
  WriteLn('场景：监控最近5个数据点的统计信息');
  WriteLn;
  
  LStats := TSlidingWindowStats.Create(5); // 窗口大小为5
  try
    WriteLn('--- 逐步添加数据 ---');
    for i := 0 to High(LValues) do
    begin
      LStats.Add(LValues[i]);
      WriteLn(Format('添加 %.1f:', [LValues[i]]));
      LStats.Print;
      WriteLn;
    end;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：VecDeque 的两端操作都是 O(1)，非常适合滑动窗口场景');
  finally
    LStats.Free;
  end;
end.

