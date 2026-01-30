unit Test_Contracts_IMap;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ 契约测试：IMap（TE 版工厂；能力断言） }

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

{$I test_config.inc}

implementation

uses
  Contracts_Factories_TE_Clean;



type
  TTestCase_IMap_Contracts_IntStr = class(TTestCase)
  private
    M_OA: IMapIntStr;
    M_MM: IMapIntStr;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_Map_Put_Get_Remove_OA;
    procedure Test_Map_Put_Get_Remove_MM;
    procedure Test_Map_OA_Collision_Probe_Path;
    procedure Test_Map_Clear_Resets_State;
    procedure Test_Map_Capabilities_MM;
    {$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
    // procedure Test_Map_Concurrency_Smoke; // 暂不启用，避免未定义
    {$ENDIF}
  end;

procedure TTestCase_IMap_Contracts_IntStr.SetUp;
begin
  M_OA := GetDefaultMapFactory_IntStr_TE.MakeOA(8);
  M_MM := GetDefaultMapFactory_IntStr_TE.MakeMM(32);
end;

procedure TTestCase_IMap_Contracts_IntStr.TearDown;
begin
  M_OA := nil;
  M_MM := nil;
end;

procedure TTestCase_IMap_Contracts_IntStr.Test_Map_Put_Get_Remove_OA;
var v: string; replaced: Boolean;
begin
  AssertTrue(M_OA.Put(1, 'A', replaced)); AssertFalse(replaced);
  AssertTrue(M_OA.TryGetValue(1, v)); AssertEquals('A', v);
  AssertTrue(M_OA.Put(1, 'B', replaced)); AssertTrue(replaced);
  AssertTrue(M_OA.TryGetValue(1, v)); AssertEquals('B', v);
  AssertTrue(M_OA.Remove(1, v)); AssertEquals('B', v);
  AssertFalse(M_OA.ContainsKey(1));
end;

procedure TTestCase_IMap_Contracts_IntStr.Test_Map_Put_Get_Remove_MM;
var v: string; replaced: Boolean;
begin
  AssertTrue(M_MM.Put(1, 'A', replaced)); AssertFalse(replaced or false);
  AssertTrue(M_MM.TryGetValue(1, v)); AssertEquals('A', v);
  AssertTrue(M_MM.Put(1, 'B', replaced));
  AssertTrue(M_MM.TryGetValue(1, v)); AssertEquals('B', v);
  AssertTrue(M_MM.Remove(1, v));
  AssertFalse(M_MM.ContainsKey(1));
end;

procedure TTestCase_IMap_Contracts_IntStr.Test_Map_OA_Collision_Probe_Path;
var i: Integer; v: string; replaced: Boolean;
begin
  for i := 0 to 5 do AssertTrue(M_OA.Put(i*8, 'V'+IntToStr(i), {out}replaced));
  AssertTrue(M_OA.TryGetValue(16, v)); AssertEquals('V2', v);
  AssertFalse(M_OA.TryGetValue(999, v));
  AssertTrue(M_OA.Put(16, 'NEW', replaced)); AssertTrue(M_OA.TryGetValue(16, v)); AssertEquals('NEW', v);
end;

procedure TTestCase_IMap_Contracts_IntStr.Test_Map_Clear_Resets_State;
var v: string; replaced: Boolean;
begin
  AssertTrue(M_OA.Put(1, 'A', replaced));
  AssertTrue(M_OA.Put(2, 'B', replaced));
  M_OA.Clear;
  AssertFalse(M_OA.ContainsKey(1));
  AssertFalse(M_OA.ContainsKey(2));
end;

procedure TTestCase_IMap_Contracts_IntStr.Test_Map_Capabilities_MM;
begin
  // MM 实现提供装载因子、桶数与 max load factor 的能力（通过 TE 包装暴露 *1000 近似值）
  AssertTrue(M_MM.LoadFactorTimes1000 >= 0);
  AssertTrue(M_MM.BucketCount > 0);
  AssertTrue(M_MM.MaxLoadFactorTimes1000 > 0);
  AssertTrue(M_MM.SetMaxLoadFactorTimes1000(M_MM.MaxLoadFactorTimes1000));
end;

{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_TESTS}
{$IFDEF FAFAFA_CORE_ENABLE_CONCURRENCY_SMOKE}
procedure TTestCase_IMap_Contracts_IntStr.Test_Map_MM_Smoke_PutFind;
var i: Integer; v: string; replaced: Boolean;
begin
  for i := 1 to 50 do AssertTrue(M_MM.Put(i, 'V'+IntToStr(i), replaced));
  for i := 1 to 50 do begin AssertTrue(M_MM.TryGetValue(i, v)); AssertEquals('V'+IntToStr(i), v); end;
end;
{$ENDIF}

// 并发烟囱同前，略
{$ENDIF}

initialization
  RegisterTest(TTestCase_IMap_Contracts_IntStr);

end.

