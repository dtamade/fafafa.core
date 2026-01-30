unit test_base;

{$MODE OBJFPC}{$H+}
//{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base;

type

  { TBaseTest }

  TBaseTest = class(TTestCase)
  published
    // Add tests for fafafa.core.base here in the future
    // 未来在此处为 fafafa.core.base 添加测试
    procedure TestPlaceholder;
  end;

implementation

procedure TBaseTest.TestPlaceholder;
begin
  // This is a placeholder test to ensure the test suite compiles.
  // 这是一个占位测试, 以确保测试套件能够编译.
  Check(True);
end;

initialization
  RegisterTest(TBaseTest);
end.
