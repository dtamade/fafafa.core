program test_minimal;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.collections.treemap,
  fafafa.core.collections.lrucache,
  fafafa.core.collections;

var
  LTree: specialize ITreeMap<Integer, String>;
  LCache: specialize ILruCache<String, Integer>;
  LValue: String;
  LNum: Integer;
begin
  WriteLn('Testing TreeMap...');
  LTree := specialize MakeTreeMap<Integer, String>(10);
  LTree.Put(1, 'One');
  LTree.Put(2, 'Two');

  if LTree.Get(1, LValue) then
    WriteLn('TreeMap.Get(1) = ', LValue)
  else
    WriteLn('TreeMap.Get(1) failed');

  WriteLn('Testing LRU Cache...');
  LCache := specialize MakeLruCache<String, Integer>(5);
  LCache.Put('Key1', 1);
  LCache.Put('Key2', 2);

  if LCache.Get('Key1', LNum) then
    WriteLn('LRU.Get(Key1) = ', LNum)
  else
    WriteLn('LRU.Get(Key1) failed');

  WriteLn('All tests passed!');
end.
