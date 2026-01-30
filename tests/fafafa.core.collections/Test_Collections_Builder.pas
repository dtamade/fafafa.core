unit Test_Collections_Builder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.builder,
  fafafa.core.collections.vec,
  fafafa.core.collections.hashmap;

type

  { TTestVecBuilder }
  TTestVecBuilder = class(TTestCase)
  published
    // === 基础构建测试 ===
    procedure Test_Build_Empty;
    procedure Test_Build_WithCapacity;
    procedure Test_Build_WithElements;
    procedure Test_Build_WithElements_Multiple;
    
    // === 链式调用测试 ===
    procedure Test_Chain_CapacityAndElements;
    procedure Test_Chain_MultipleWithCalls;
    
    // === 类型测试 ===
    procedure Test_Build_IntegerVec;
    procedure Test_Build_StringVec;
  end;

  { TTestHashMapBuilder }
  TTestHashMapBuilder = class(TTestCase)
  published
    // === 基础构建测试 ===
    procedure Test_Build_Empty;
    procedure Test_Build_WithCapacity;
    procedure Test_Build_WithEntry;
    procedure Test_Build_WithEntries_Multiple;
    
    // === 链式调用测试 ===
    procedure Test_Chain_CapacityAndEntries;
  end;

implementation

{ TTestVecBuilder }

procedure TTestVecBuilder.Test_Build_Empty;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>.Build;
  
  AssertEquals('Empty vec count', 0, Vec.Count);
end;

procedure TTestVecBuilder.Test_Build_WithCapacity;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>.WithCapacity(100).AndBuild;
  
  AssertEquals('Vec count', 0, Vec.Count);
  AssertTrue('Capacity >= 100', Vec.Capacity >= 100);
end;

procedure TTestVecBuilder.Test_Build_WithElements;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>.WithElement(42).AndBuild;
  
  AssertEquals('Vec count', 1, Vec.Count);
  AssertEquals('Element 0', 42, Vec.Get(0));
end;

procedure TTestVecBuilder.Test_Build_WithElements_Multiple;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>
    .WithElement(1)
    .AndWithElement(2)
    .AndWithElement(3)
    .AndBuild;
  
  AssertEquals('Vec count', 3, Vec.Count);
  AssertEquals('Element 0', 1, Vec.Get(0));
  AssertEquals('Element 1', 2, Vec.Get(1));
  AssertEquals('Element 2', 3, Vec.Get(2));
end;

procedure TTestVecBuilder.Test_Chain_CapacityAndElements;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>
    .WithCapacity(50)
    .AndWithElement(10)
    .AndWithElement(20)
    .AndBuild;
  
  AssertEquals('Vec count', 2, Vec.Count);
  AssertTrue('Capacity >= 50', Vec.Capacity >= 50);
  AssertEquals('Element 0', 10, Vec.Get(0));
  AssertEquals('Element 1', 20, Vec.Get(1));
end;

procedure TTestVecBuilder.Test_Chain_MultipleWithCalls;
var
  Vec: specialize IVec<Integer>;
  i: Integer;
begin
  Vec := specialize TVecBuilder<Integer>
    .WithElement(1)
    .AndWithElement(2)
    .AndWithElement(3)
    .AndWithElement(4)
    .AndWithElement(5)
    .AndBuild;
  
  AssertEquals('Vec count', 5, Vec.Count);
  for i := 0 to 4 do
    AssertEquals('Element ' + IntToStr(i), i + 1, Vec.Get(i));
end;

procedure TTestVecBuilder.Test_Build_IntegerVec;
var
  Vec: specialize IVec<Integer>;
begin
  Vec := specialize TVecBuilder<Integer>
    .WithElement(-1)
    .AndWithElement(0)
    .AndWithElement(MaxInt)
    .AndBuild;
  
  AssertEquals('Vec count', 3, Vec.Count);
  AssertEquals('Element 0', -1, Vec.Get(0));
  AssertEquals('Element 1', 0, Vec.Get(1));
  AssertEquals('Element 2', MaxInt, Vec.Get(2));
end;

procedure TTestVecBuilder.Test_Build_StringVec;
var
  Vec: specialize IVec<String>;
begin
  Vec := specialize TVecBuilder<String>
    .WithElement('Hello')
    .AndWithElement('World')
    .AndBuild;
  
  AssertEquals('Vec count', 2, Vec.Count);
  AssertEquals('Element 0', 'Hello', Vec.Get(0));
  AssertEquals('Element 1', 'World', Vec.Get(1));
end;

{ TTestHashMapBuilder }

procedure TTestHashMapBuilder.Test_Build_Empty;
var
  Map: specialize IHashMap<String, Integer>;
begin
  Map := specialize THashMapBuilder<String, Integer>.Build;
  
  AssertEquals('Empty map count', 0, Map.Count);
end;

procedure TTestHashMapBuilder.Test_Build_WithCapacity;
var
  Map: specialize IHashMap<String, Integer>;
begin
  Map := specialize THashMapBuilder<String, Integer>.WithCapacity(100).AndBuild;
  
  AssertEquals('Map count', 0, Map.Count);
  AssertTrue('Capacity >= 100', Map.Capacity >= 100);
end;

procedure TTestHashMapBuilder.Test_Build_WithEntry;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize THashMapBuilder<String, Integer>
    .WithEntry('key1', 100)
    .AndBuild;
  
  AssertEquals('Map count', 1, Map.Count);
  AssertTrue('Contains key1', Map.TryGetValue('key1', Value));
  AssertEquals('Value for key1', 100, Value);
end;

procedure TTestHashMapBuilder.Test_Build_WithEntries_Multiple;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize THashMapBuilder<String, Integer>
    .WithEntry('a', 1)
    .AndWithEntry('b', 2)
    .AndWithEntry('c', 3)
    .AndBuild;
  
  AssertEquals('Map count', 3, Map.Count);
  
  AssertTrue('Contains a', Map.TryGetValue('a', Value));
  AssertEquals('Value for a', 1, Value);
  
  AssertTrue('Contains b', Map.TryGetValue('b', Value));
  AssertEquals('Value for b', 2, Value);
  
  AssertTrue('Contains c', Map.TryGetValue('c', Value));
  AssertEquals('Value for c', 3, Value);
end;

procedure TTestHashMapBuilder.Test_Chain_CapacityAndEntries;
var
  Map: specialize IHashMap<String, Integer>;
  Value: Integer;
begin
  Map := specialize THashMapBuilder<String, Integer>
    .WithCapacity(50)
    .AndWithEntry('x', 10)
    .AndWithEntry('y', 20)
    .AndBuild;
  
  AssertEquals('Map count', 2, Map.Count);
  AssertTrue('Capacity >= 50', Map.Capacity >= 50);
  
  AssertTrue('Contains x', Map.TryGetValue('x', Value));
  AssertEquals('Value for x', 10, Value);
end;

initialization
  RegisterTest(TTestVecBuilder);
  RegisterTest(TTestHashMapBuilder);

end.
