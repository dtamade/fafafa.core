program test_new_containers;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}

uses
  SysUtils, Classes,
  fafafa.core.collections.treemap,
  // fafafa.core.collections.treeset,
  fafafa.core.collections.lrucache,
  fafafa.core.collections;

{ 比较函数 }
function CompareInteger(const aLeft, aRight: Integer; aData: Pointer): SizeInt;
begin
  if aLeft < aRight then
    Result := -1
  else if aLeft > aRight then
    Result := 1
  else
    Result := 0;
end;

{ 测试 TreeMap }
procedure TestTreeMap;
var
  LMap: specialize ITreeMap<Integer, String>;
  LValue: String;
  i: Integer;
begin
  WriteLn('=== 测试 TreeMap ===');
  LMap := specialize MakeTreeMap<Integer, String>(0, @CompareInteger);

  { 插入数据 }
  for i := 1 to 10 do
    LMap.Put(i, 'Value' + IntToStr(i));

  WriteLn('插入了 10 个元素');

  { 测试 Get }
  if LMap.Get(5, LValue) then
    WriteLn('Get(5) = ', LValue)
  else
    WriteLn('Get(5) 失败');

  { 测试 LowerBound }
  if LMap.GetLowerBound(7, LValue) then
    WriteLn('LowerBound(7) = ', LValue)
  else
    WriteLn('LowerBound(7) 失败');

  { 测试 Floor/Ceiling }
  if LMap.Floor(8, LValue) then
    WriteLn('Floor(8) = ', LValue);

  if LMap.Ceiling(3, LValue) then
    WriteLn('Ceiling(3) = ', LValue);

  { 测试 Contains }
  if LMap.ContainsKey(10) then
    WriteLn('ContainsKey(10) = True')
  else
    WriteLn('ContainsKey(10) = False');

  { 测试 Remove }
  // if LMap.Remove(5) then
  //   WriteLn('Remove(5) 成功')
  // else
  //   WriteLn('Remove(5) 失败');

  WriteLn('测试完成');
  WriteLn;
end;

{ 测试 TreeSet }
//procedure TestTreeSet;
//var
//  LSet: specialize ITreeSet<Integer>;
//  LValue: Integer;
//  i: Integer;
//begin
//  WriteLn('=== 测试 TreeSet ===');
//  LSet := specialize MakeTreeSet<Integer>;
//
//  { 插入数据 }
//  for i := 1 to 10 do
//    LSet.Add(i);
//
//  WriteLn('插入了 10 个元素');
//
//  { 测试 Contains }
//  if LSet.Contains(7) then
//    WriteLn('Contains(7) = True')
//  else
//    WriteLn('Contains(7) = False');
//
//  { 测试 LowerBound }
//  if LSet.GetLowerBound(7, LValue) then
//    WriteLn('LowerBound(7) = ', LValue)
//  else
//    WriteLn('LowerBound(7) 失败');
//
//  { 测试 Remove }
//  if LSet.Remove(5) then
//    WriteLn('Remove(5) 成功')
//  else
//    WriteLn('Remove(5) 失败');
//
//  WriteLn('测试完成');
//  WriteLn;
//end;

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
  WriteLn('开始测试新实现的容器...');
  WriteLn;

  try
    TestTreeMap;
    // TestTreeSet;
    TestLruCache;

    WriteLn('所有测试完成！');
  except
    on E: Exception do
      WriteLn('测试出错: ', E.Message);
  end;

  ReadLn;
end.
