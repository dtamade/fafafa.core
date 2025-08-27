unit Test_thread_facade_smoke;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.thread;

type
  { TTestCase_TThread_FacadeSmoke }
  TTestCase_TThread_FacadeSmoke = class(TTestCase)
  published
    procedure Test_Global_vs_TThreads_Spawn_Join_Equivalence;
    procedure Test_TThreads_Join_NoRecursion;
  end;

implementation

function Work(Data: Pointer): Boolean; begin Result := True; end;

procedure TTestCase_TThread_FacadeSmoke.Test_Global_vs_TThreads_Spawn_Join_Equivalence;
var F1, F2: IFuture; ok1, ok2: Boolean;
begin
  // 全局函数路径
  F1 := Spawn(@Work, nil);
  ok1 := Join([F1], 1000);
  // TThreads 路径
  F2 := TThreads.Spawn(@Work, nil);
  ok2 := TThreads.Join([F2], 1000);
  AssertTrue('global spawn/join ok', ok1);
  AssertTrue('tthreads spawn/join ok', ok2);
end;

procedure TTestCase_TThread_FacadeSmoke.Test_TThreads_Join_NoRecursion;
var F: IFuture; ok: Boolean;
begin
  // 若存在递归缺陷，这里会触发栈溢出；正常应返回 True
  F := TThreads.Spawn(@Work, nil);
  ok := TThreads.Join([F], 1000);
  AssertTrue('tthreads join no recursion', ok);
end;

initialization
  RegisterTest(TTestCase_TThread_FacadeSmoke);
end.

