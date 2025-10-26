program test_lru_only;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.collections.lrucache,
  fafafa.core.collections;

{ 测试 LRU Cache }
procedure TestLruCache;
var
  LCache: specialize ILruCache<String, Integer>;
  LValue: Integer;
  i: Integer;
begin
  WriteLn('=== 测试 LRU Cache ===');
  LCache := specialize MakeLruCache<String, Integer>(5);

  { 插入数据 }
  for i := 1 to 7 do
  begin
    LCache.Put('Key' + IntToStr(i), i);
    WriteLn('Put Key', i, ' = ', i);
  end;

  WriteLn;
  WriteLn('缓存大小: ', LCache.GetSize, '/', LCache.GetMaxSize);

  { 测试 Get }
  if LCache.Get('Key1', LValue) then
    WriteLn('Get(Key1) = ', LValue, ' (应该被淘汰)')
  else
    WriteLn('Get(Key1) 未命中 (LRU 策略生效)');

  if LCache.Get('Key6', LValue) then
    WriteLn('Get(Key6) = ', LValue, ' (应该保留)')
  else
    WriteLn('Get(Key6) 未命中');

  WriteLn;
  WriteLn('命中次数: ', LCache.GetHitCount);
  WriteLn('未命中次数: ', LCache.GetMissCount);
  WriteLn('命中率: ', LCache.GetHitRate:0:2);

  { 测试 Peek }
  if LCache.Peek('Key6', LValue) then
    WriteLn('Peek(Key6) = ', LValue, ' (不更新访问顺序)');

  WriteLn('测试完成');
  WriteLn;
end;

{ 主程序 }
begin
  WriteLn('开始测试 LRU Cache...');
  WriteLn;

  try
    TestLruCache;

    WriteLn('所有测试完成！');
  except
    on E: Exception do
      WriteLn('测试出错: ', E.Message);
  end;

  ReadLn;
end.
