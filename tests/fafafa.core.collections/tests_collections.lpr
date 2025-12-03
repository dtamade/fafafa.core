program tests_collections;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry, consoletestrunner,
  // 被测门面
  fafafa.core.collections,
  Test_fafafa_core_collections,
  Test_fafafa_core_collections_tree_structures,
  Test_HashMap_API_Consistency,
  Test_Collections_Boundary,
  Test_Stack_Full,
  Test_ForwardList_Full,
  Test_Queue_Full,
  Test_LinkedHashMap_Order,
  Test_LruCache_Eviction,
  Test_PriorityQueue_Interface,
  Test_Iterators_Adapters,
  Test_Algorithms,
  Test_HashMap_Entry,
  Test_TreeMap_Entry,
  Test_PoolAllocator;

var
  LApplication: TTestRunner;
begin
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'tests_collections';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
