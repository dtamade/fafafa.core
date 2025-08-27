unit Test_Contracts_IMap_StrInt;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ 契约测试：IMap（TE 版工厂；字符串键语义等价验证） }

interface

uses
  Classes, SysUtils, fpcunit, testregistry;

{$I test_config.inc}

implementation

uses
  Contracts_Factories_StrInt_TE;

type
  TTestCase_IMap_Contracts_StrInt = class(TTestCase)
  private
    M_OA: IMapStrInt;
    M_MM: IMapStrInt;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test_OA_StringKey_SemanticEquality_ShouldWork;
    procedure Test_MM_StringKey_SemanticEquality_ShouldWork;
  end;

procedure TTestCase_IMap_Contracts_StrInt.SetUp;
begin
  M_OA := GetDefaultMapFactory_StrInt_TE.MakeOA(32);
  M_MM := GetDefaultMapFactory_StrInt_TE.MakeMM(64);
end;

procedure TTestCase_IMap_Contracts_StrInt.TearDown;
begin
  M_OA := nil;
  M_MM := nil;
end;

// 构造两个内容相等但指针不同的字符串
procedure MakeTwoEqualButDistinctStrings(out S1, S2: string);
var tmp: string;
begin
  S1 := 'AlphaBetaGamma';
  tmp := S1 + 'x';      // 强制产生新分配
  Delete(tmp, Length(tmp), 1); // 回到相同内容
  S2 := tmp;
end;

procedure TTestCase_IMap_Contracts_StrInt.Test_OA_StringKey_SemanticEquality_ShouldWork;
var s1, s2: string; v: Integer; replaced: Boolean;
begin
  MakeTwoEqualButDistinctStrings(s1, s2);
  AssertTrue(M_OA.Put(s1, 42, replaced));
  // 语义等价应可命中；当前实现若基于指针比较将失败（用于暴露问题）
  AssertTrue('OA semantic equality failed (string key)', M_OA.TryGetValue(s2, v));
  AssertEquals(42, v);
end;

procedure TTestCase_IMap_Contracts_StrInt.Test_MM_StringKey_SemanticEquality_ShouldWork;
var s1, s2: string; v: Integer; replaced: Boolean;
begin
  MakeTwoEqualButDistinctStrings(s1, s2);
  AssertTrue(M_MM.Put(s1, 7, replaced));
  AssertTrue(M_MM.TryGetValue(s2, v));
  AssertEquals(7, v);
end;

initialization
  RegisterTest(TTestCase_IMap_Contracts_StrInt);

end.

