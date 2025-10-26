program test_treemap_only;

{$mode objfpc}{$H+}
{$I src/fafafa.core.settings.inc}
{$WARN 6058 OFF}  { Turn off warnings about unused lval }
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.treemap,
  fafafa.core.mem.allocator;

type
  TTestMap = specialize ITreeMap<Integer, String>;

function IntegerCompare(const aLeft, aRight: Integer; aData: Pointer): SizeInt;
begin
  if aLeft < aRight then
    Result := -1
  else if aLeft > aRight then
    Result := 1
  else
    Result := 0;
end;

var
  LTree: TTestMap;
  LValue: String;
  LSuccess: Boolean;
begin
  WriteLn('=== Testing TreeMap ===');

  { 创建 TreeMap，传入比较函数 }
  LTree := specialize TTreeMap<Integer, String>.Create(nil, @IntegerCompare);

  { 测试 Put }
  LTree.Put(1, 'One');
  LTree.Put(2, 'Two');
  LTree.Put(3, 'Three');
  WriteLn('Put 3 items');

  { 测试 Get }
  LSuccess := LTree.Get(2, LValue);
  if LSuccess then
    WriteLn('Get(2) = ', LValue)
  else
    WriteLn('Get(2) failed');

  { 测试 ContainsKey }
  if LTree.ContainsKey(1) then
    WriteLn('ContainsKey(1) = True')
  else
    WriteLn('ContainsKey(1) = False');

  { 测试 Remove }
  if LTree.Remove(1) then
    WriteLn('Remove(1) succeeded')
  else
    WriteLn('Remove(1) failed');

  if LTree.ContainsKey(1) then
    WriteLn('After Remove, ContainsKey(1) = True (ERROR!)')
  else
    WriteLn('After Remove, ContainsKey(1) = False (correct)');

  WriteLn('TreeMap test completed!');
end.
