unit Test_Trie;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.trie;

type
  TStringTrie = specialize TTrie<Integer>;

  { TTestTrie }
  TTestTrie = class(TTestCase)
  protected
    FTrie: TStringTrie;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    // 基本操作
    procedure Test_Empty_CountIsZero;
    procedure Test_Put_SingleKey;
    procedure Test_Put_MultipleKeys;
    procedure Test_Put_UpdateExisting;
    procedure Test_Get_ExistingKey;
    procedure Test_Get_NonExistingKey;
    procedure Test_ContainsKey_True;
    procedure Test_ContainsKey_False;
    procedure Test_Remove_ExistingKey;
    procedure Test_Remove_NonExistingKey;
    procedure Test_Clear_EmptiesAll;
    
    // 前缀查询
    procedure Test_HasPrefix_True;
    procedure Test_HasPrefix_False;
    procedure Test_KeysWithPrefix_ReturnsMatches;
    procedure Test_KeysWithPrefix_EmptyPrefix;
  end;

implementation

{ TTestTrie }

procedure TTestTrie.SetUp;
begin
  FTrie := TStringTrie.Create;
end;

procedure TTestTrie.TearDown;
begin
  FTrie.Free;
end;

procedure TTestTrie.Test_Empty_CountIsZero;
begin
  AssertEquals('Empty trie count', 0, FTrie.Count);
  AssertTrue('Empty trie IsEmpty', FTrie.IsEmpty);
end;

procedure TTestTrie.Test_Put_SingleKey;
begin
  FTrie.Put('hello', 42);
  AssertEquals('Count after put', 1, FTrie.Count);
  AssertFalse('Not empty after put', FTrie.IsEmpty);
end;

procedure TTestTrie.Test_Put_MultipleKeys;
begin
  FTrie.Put('apple', 1);
  FTrie.Put('app', 2);
  FTrie.Put('application', 3);
  FTrie.Put('banana', 4);
  
  AssertEquals('Count after multiple puts', 4, FTrie.Count);
end;

procedure TTestTrie.Test_Put_UpdateExisting;
var
  Value: Integer;
begin
  FTrie.Put('key', 100);
  FTrie.Put('key', 200);
  
  AssertEquals('Count unchanged', 1, FTrie.Count);
  AssertTrue('Get updated value', FTrie.Get('key', Value));
  AssertEquals('Value is updated', 200, Value);
end;

procedure TTestTrie.Test_Get_ExistingKey;
var
  Value: Integer;
begin
  FTrie.Put('test', 999);
  
  AssertTrue('Get returns true', FTrie.Get('test', Value));
  AssertEquals('Value correct', 999, Value);
end;

procedure TTestTrie.Test_Get_NonExistingKey;
var
  Value: Integer;
begin
  FTrie.Put('exists', 1);
  
  AssertFalse('Get non-existing returns false', FTrie.Get('notexists', Value));
end;

procedure TTestTrie.Test_ContainsKey_True;
begin
  FTrie.Put('present', 1);
  AssertTrue('Contains existing key', FTrie.ContainsKey('present'));
end;

procedure TTestTrie.Test_ContainsKey_False;
begin
  FTrie.Put('present', 1);
  AssertFalse('Does not contain missing key', FTrie.ContainsKey('absent'));
end;

procedure TTestTrie.Test_Remove_ExistingKey;
begin
  FTrie.Put('a', 1);
  FTrie.Put('ab', 2);
  FTrie.Put('abc', 3);
  
  AssertTrue('Remove returns true', FTrie.Remove('ab'));
  AssertEquals('Count after remove', 2, FTrie.Count);
  AssertFalse('Key no longer exists', FTrie.ContainsKey('ab'));
  // Siblings should still exist
  AssertTrue('Sibling a exists', FTrie.ContainsKey('a'));
  AssertTrue('Sibling abc exists', FTrie.ContainsKey('abc'));
end;

procedure TTestTrie.Test_Remove_NonExistingKey;
begin
  FTrie.Put('exists', 1);
  
  AssertFalse('Remove non-existing returns false', FTrie.Remove('notexists'));
  AssertEquals('Count unchanged', 1, FTrie.Count);
end;

procedure TTestTrie.Test_Clear_EmptiesAll;
begin
  FTrie.Put('one', 1);
  FTrie.Put('two', 2);
  FTrie.Put('three', 3);
  
  FTrie.Clear;
  
  AssertEquals('Count after clear', 0, FTrie.Count);
  AssertTrue('IsEmpty after clear', FTrie.IsEmpty);
end;

procedure TTestTrie.Test_HasPrefix_True;
begin
  FTrie.Put('application', 1);
  FTrie.Put('apple', 2);
  
  AssertTrue('Has prefix "app"', FTrie.HasPrefix('app'));
  AssertTrue('Has prefix "appl"', FTrie.HasPrefix('appl'));
  AssertTrue('Has prefix empty', FTrie.HasPrefix(''));
end;

procedure TTestTrie.Test_HasPrefix_False;
begin
  FTrie.Put('hello', 1);
  
  AssertFalse('No prefix "world"', FTrie.HasPrefix('world'));
  AssertFalse('No prefix "hex"', FTrie.HasPrefix('hex'));
end;

procedure TTestTrie.Test_KeysWithPrefix_ReturnsMatches;
var
  Keys: TStringTrie.TKeyArray;
begin
  FTrie.Put('car', 1);
  FTrie.Put('card', 2);
  FTrie.Put('care', 3);
  FTrie.Put('careful', 4);
  FTrie.Put('dog', 5);
  
  Keys := FTrie.KeysWithPrefix('car');
  
  AssertEquals('Prefix match count', 4, Length(Keys));
end;

procedure TTestTrie.Test_KeysWithPrefix_EmptyPrefix;
var
  Keys: TStringTrie.TKeyArray;
begin
  FTrie.Put('a', 1);
  FTrie.Put('b', 2);
  FTrie.Put('c', 3);
  
  Keys := FTrie.KeysWithPrefix('');
  
  AssertEquals('All keys returned', 3, Length(Keys));
end;

initialization
  RegisterTest(TTestTrie);
end.
