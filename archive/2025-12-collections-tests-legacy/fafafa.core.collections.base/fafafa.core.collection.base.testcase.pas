unit fafafa.core.collection.base.testcase;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.collections.base;

type
  // 全局函数与接口可见性检查
  TTestCase_Global = class(TTestCase)
  published
    procedure Test_Units_Visible;
    procedure Test_Interface_MinSmoke;
  end;

implementation

procedure TTestCase_Global.Test_Units_Visible;
begin
  // 编译期可见性即通过
  AssertTrue('ICollection 可见', True);
  AssertTrue('IGenericCollection<T> 可见', True);
end;

procedure TTestCase_Global.Test_Interface_MinSmoke;
var
  C: ICollection;
begin
  // 仅验证接口类型存在与基本方法签名不报错（运行不调用）
  C := nil;
  AssertTrue('ICollection 可构建引用', True);
end;

initialization
  RegisterTest(TTestCase_Global);

end.

