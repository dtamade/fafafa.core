program tests_collections;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

uses
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
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
  Test_PoolAllocator,
  Test_Algorithms_Advanced,
  Test_MultiSet,
  Test_SkipList,
  Test_Trie,
  Test_MultiMap,
  Test_HashMap_Retain,
  Test_Vec_RetainExtend,
  Test_Collections_Builder,
  Test_Collections_Drain,
  Test_HashSet_SetOperations,
  Test_RevIter,
  Test_Vec_SplitSplice,
  Test_Vec_Dedup,
  Test_Collections_Facade,
  Test_SmallVec,
  Test_BitSet_Performance,
  Test_List_Full,
  Test_VecDeque_Full,
  Test_Vec_Full,
  Test_HashMap_Full,
  Test_TreeMap_Full,
  Test_HashSet_Full,
  Test_CircularBuffer_Full,
  Benchmark_Collections;

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
