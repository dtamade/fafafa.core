{$CODEPAGE UTF8}
program slab_pool_tests;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, consoletestrunner,
  fafafa.core.mem.pool.slab.testcase;

var
  Application: TTestRunner;

begin
  DefaultFormat := fPlain;
  Application := TTestRunner.Create(nil);
  Application.Initialize;
  Application.Title := 'fafafa.core.mem.pool.slab 模块测试';
  Application.Run;
  Application.Free;
end.

