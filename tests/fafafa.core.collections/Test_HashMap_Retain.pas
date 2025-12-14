unit Test_HashMap_Retain;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

{**
 * TDD 测试用例: HashMap.Retain
 * 
 * 测试目标:
 * 1. Retain - 保留满足条件的键值对，删除不满足条件的
 *}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base,
  fafafa.core.collections.hashmap,
  fafafa.core.collections;

type
  TStringIntMap = specialize THashMap<String, Integer>;
  IStringIntMap = specialize IHashMap<String, Integer>;
  TStringIntEntry = specialize TMapEntry<String, Integer>;

  { TTestHashMapRetain }
  TTestHashMapRetain = class(TTestCase)
  published
    // Retain 基本测试
    procedure Test_Retain_KeepEvenValues;
    procedure Test_Retain_KeepAllElements;
    procedure Test_Retain_KeepNoElements;
    procedure Test_Retain_Empty;
    procedure Test_Retain_WithUserData;
    procedure Test_Retain_KeyPredicate;
    procedure Test_Retain_NoLeak;
  end;

implementation

{ Callback functions }

function IsValueEven(const aEntry: TStringIntEntry; aData: Pointer): Boolean;
begin
  Result := (aEntry.Value mod 2) = 0;
end;

function IsValuePositive(const aEntry: TStringIntEntry; aData: Pointer): Boolean;
begin
  Result := aEntry.Value > 0;
end;

function IsValueGreaterThan(const aEntry: TStringIntEntry; aData: Pointer): Boolean;
var
  Threshold: PInteger;
begin
  Threshold := PInteger(aData);
  Result := aEntry.Value > Threshold^;
end;

function IsKeyStartsWithA(const aEntry: TStringIntEntry; aData: Pointer): Boolean;
begin
  Result := (Length(aEntry.Key) > 0) and (aEntry.Key[1] = 'a');
end;

{ TTestHashMapRetain }

procedure TTestHashMapRetain.Test_Retain_KeepEvenValues;
var
  Map: IStringIntMap;
  V: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('one', 1);
  Map.Put('two', 2);
  Map.Put('three', 3);
  Map.Put('four', 4);
  Map.Put('five', 5);
  Map.Put('six', 6);
  
  Map.Retain(@IsValueEven, nil);
  
  AssertEquals('Count after retain', 3, Map.Count);
  AssertTrue('two exists', Map.ContainsKey('two'));
  AssertTrue('four exists', Map.ContainsKey('four'));
  AssertTrue('six exists', Map.ContainsKey('six'));
  AssertFalse('one removed', Map.ContainsKey('one'));
  AssertFalse('three removed', Map.ContainsKey('three'));
  AssertFalse('five removed', Map.ContainsKey('five'));
end;

procedure TTestHashMapRetain.Test_Retain_KeepAllElements;
var
  Map: IStringIntMap;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('a', 2);
  Map.Put('b', 4);
  Map.Put('c', 6);
  
  Map.Retain(@IsValueEven, nil);
  
  AssertEquals('All elements kept', 3, Map.Count);
end;

procedure TTestHashMapRetain.Test_Retain_KeepNoElements;
var
  Map: IStringIntMap;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('a', 1);
  Map.Put('b', 3);
  Map.Put('c', 5);
  
  Map.Retain(@IsValueEven, nil);
  
  AssertEquals('No elements kept', 0, Map.Count);
end;

procedure TTestHashMapRetain.Test_Retain_Empty;
var
  Map: IStringIntMap;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  Map.Retain(@IsValueEven, nil);
  
  AssertEquals('Empty stays empty', 0, Map.Count);
end;

procedure TTestHashMapRetain.Test_Retain_WithUserData;
var
  Map: IStringIntMap;
  Threshold: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('a', 5);
  Map.Put('b', 10);
  Map.Put('c', 15);
  Map.Put('d', 20);
  Map.Put('e', 25);
  
  Threshold := 12;
  Map.Retain(@IsValueGreaterThan, @Threshold);
  
  AssertEquals('Count after retain', 3, Map.Count);
  AssertTrue('c exists', Map.ContainsKey('c'));
  AssertTrue('d exists', Map.ContainsKey('d'));
  AssertTrue('e exists', Map.ContainsKey('e'));
end;

procedure TTestHashMapRetain.Test_Retain_KeyPredicate;
var
  Map: IStringIntMap;
begin
  Map := specialize MakeHashMap<String, Integer>;
  Map.Put('apple', 1);
  Map.Put('banana', 2);
  Map.Put('avocado', 3);
  Map.Put('cherry', 4);
  Map.Put('apricot', 5);
  
  Map.Retain(@IsKeyStartsWithA, nil);
  
  AssertEquals('Count after retain', 3, Map.Count);
  AssertTrue('apple exists', Map.ContainsKey('apple'));
  AssertTrue('avocado exists', Map.ContainsKey('avocado'));
  AssertTrue('apricot exists', Map.ContainsKey('apricot'));
  AssertFalse('banana removed', Map.ContainsKey('banana'));
  AssertFalse('cherry removed', Map.ContainsKey('cherry'));
end;

procedure TTestHashMapRetain.Test_Retain_NoLeak;
var
  Map: IStringIntMap;
  i: Integer;
begin
  Map := specialize MakeHashMap<String, Integer>;
  
  // Create many entries
  for i := 1 to 1000 do
    Map.Put('key' + IntToStr(i), i);
  
  // Retain only even values
  Map.Retain(@IsValueEven, nil);
  
  AssertEquals('Half elements retained', 500, Map.Count);
  // HeapTrc will report leaks if any
end;

initialization
  RegisterTest(TTestHashMapRetain);

end.
