program example_event_scheduler;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.treemap;

type
  TEvent = record
    Name: string;
    Description: string;
  end;

{ 事件调度器（按时间排序） }
procedure ScheduleEvents;
var
  LSchedule: specialize ITreeMap<TDateTime, TEvent>;
  LPair: specialize TPair<TDateTime, TEvent>;
  LEvent: TEvent;
  LTime: TDateTime;
  LNow: TDateTime;
begin
  LNow := Now;
  LSchedule := specialize MakeTreeMap<TDateTime, TEvent>();
  
  WriteLn('--- 添加事件 ---');
  
  // 添加事件（乱序插入）
  LTime := LNow + (2 / 24); // 2小时后
  LEvent.Name := '团队会议';
  LEvent.Description := '讨论Q4规划';
  LSchedule.Put(LTime, LEvent);
  
  LTime := LNow + (0.5 / 24); // 30分钟后
  LEvent.Name := '代码审查';
  LEvent.Description := '审查PR #123';
  LSchedule.Put(LTime, LEvent);
  
  LTime := LNow + (4 / 24); // 4小时后
  LEvent.Name := '客户演示';
  LEvent.Description := '展示新功能';
  LSchedule.Put(LTime, LEvent);
  
  LTime := LNow + (1 / 24); // 1小时后
  LEvent.Name := '午餐';
  LEvent.Description := '团队聚餐';
  LSchedule.Put(LTime, LEvent);
  
  WriteLn(Format('已添加 %d 个事件', [LSchedule.GetCount]));
  WriteLn;
  
  // 按时间顺序打印（TreeMap 自动排序）
  WriteLn('--- 日程表（按时间排序）---');
  for LPair in LSchedule do
    WriteLn(Format('%s - %s: %s', [
      FormatDateTime('hh:nn', LPair.Key),
      LPair.Value.Name,
      LPair.Value.Description
    ]));
  WriteLn;
  
  // 查询最近的事件
  WriteLn('--- 最近的事件 ---');
  if LSchedule.GetCount > 0 then
  begin
    LPair := LSchedule.First;
    WriteLn(Format('下一个事件: %s (%s)', [
      LPair.Value.Name,
      FormatDateTime('hh:nn', LPair.Key)
    ]));
  end;
end;

begin
  WriteLn('=== 事件调度器示例 ===');
  WriteLn;
  
  ScheduleEvents;
  WriteLn;
  
  WriteLn('=== 示例完成 ===');
  WriteLn('提示：TreeMap 自动按键排序，非常适合时间线、日程表等场景');
end.

