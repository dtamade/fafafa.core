program test_api_aliases;

{$mode objfpc}{$H+}

uses
  SysUtils,
  // OA & MM
  fafafa.core.lockfree.hashmap.openAddressing,
  fafafa.core.lockfree.hashmap;

procedure AssertTrue(Cond: Boolean; const Msg: string);
begin
  if not Cond then
    raise Exception.Create('AssertTrue failed: ' + Msg);
end;

procedure AssertFalse(Cond: Boolean; const Msg: string);
begin
  if Cond then
    raise Exception.Create('AssertFalse failed: ' + Msg);
end;

procedure Test_OA_Aliases_And_Tombstone;
var
  MOA: specialize TLockFreeHashMap<string, Integer>;
  ok: Boolean;
  outV: Integer;
begin
  WriteLn('== OA: API aliases and tombstone basic check ==');
  MOA := specialize TLockFreeHashMap<string, Integer>.Create(16);
  try
    // Put / insert（新建）
    ok := MOA.Put('k1', 1);
    AssertTrue(ok, 'OA.Put first insert should succeed');
    ok := MOA.insert('k2', 2);
    AssertTrue(ok, 'OA.insert first insert should succeed');

    // 重复键：insert 返回 False（InsertOnly 语义），Put 为 Upsert（覆盖返回 True）
    ok := MOA.insert('k1', 111);
    AssertFalse(ok, 'OA.insert on existing key should be False');
    ok := MOA.Put('k2', 222);
    AssertTrue(ok, 'OA.Put on existing key should be True (upsert)');

    // find/Get 一致
    AssertTrue(MOA.find('k1', outV) and (outV = 1), 'OA.find k1=1');
    AssertTrue(MOA.Get('k2', outV) and (outV = 222), 'OA.Get k2=222 after upsert');

    // 删除与墓碑：
    AssertTrue(MOA.erase('k1'), 'OA.erase k1');
    AssertFalse(MOA.find('k1', outV), 'OA.find k1 after erase should be False');

    // 删除后可插入新键（线性探测跨越 Deleted 不影响后续插入/查找）
    ok := MOA.insert('k3', 3);
    AssertTrue(ok, 'OA.insert k3 after erase path');

    // Remove 与 erase 等价
    AssertTrue(MOA.Remove('k2'), 'OA.Remove k2');
    AssertFalse(MOA.ContainsKey('k2'), 'OA.ContainsKey k2 after remove');
  finally
    MOA.Free;
  end;
  WriteLn('.. OK');
end;

procedure Test_MM_Aliases_Basic;
var
  MMM: specialize TMichaelHashMap<string, Integer>;
  ok: Boolean;
  outV: Integer;
begin
  WriteLn('== MM: API aliases basic check ==');
  MMM := specialize TMichaelHashMap<string, Integer>.Create(32, @DefaultStringHash, @DefaultStringComparer);
  try
    // insert 新建
    ok := MMM.insert('a', 10);
    AssertTrue(ok, 'MM.insert a=10');
    // 重复键 insert 返回 False
    ok := MMM.insert('a', 99);
    AssertFalse(ok, 'MM.insert existing key should be False');

    // update 修改
    ok := MMM.update('a', 20);
    AssertTrue(ok, 'MM.update a=20');

    // find/Get 一致
    AssertTrue(MMM.find('a', outV) and (outV = 20), 'MM.find a=20');
    AssertTrue(MMM.Get('a', outV) and (outV = 20), 'MM.Get alias a=20');

    // erase/Remove 等价
    AssertTrue(MMM.erase('a'), 'MM.erase a');
    AssertFalse(MMM.Remove('a'), 'MM.Remove a again should be False');
    AssertFalse(MMM.ContainsKey('a'), 'MM.ContainsKey a after erase');
  finally
    MMM.Free;
  end;
  WriteLn('.. OK');
end;

begin
  try
    Test_OA_Aliases_And_Tombstone;
    Test_MM_Aliases_Basic;
    WriteLn('All alias/tombstone tests passed.');
  except
    on E: Exception do
    begin
      WriteLn('FAILED: ', E.Message);
      Halt(1);
    end;
  end;
end.

