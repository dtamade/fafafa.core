program fafafa.core.simd.v2.test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils,
  fpcunit, testregistry, consoletestrunner,
  // 测试单元
  fafafa.core.simd.v2.testcase;

var
  App: TTestRunner;
begin
  // 显示系统信息
  WriteLn('=== fafafa.core.simd 2.0 测试系统 ===');
  WriteLn('');
  WriteLn('系统信息:');
  {$IFDEF CPUX86_64}
  WriteLn('  架构: x86_64');
  {$ENDIF}
  {$IFDEF CPUAARCH64}
  WriteLn('  架构: AArch64');
  {$ENDIF}
  {$IFDEF WINDOWS}
  WriteLn('  操作系统: Windows');
  {$ENDIF}
  {$IFDEF LINUX}
  WriteLn('  操作系统: Linux');
  {$ENDIF}
  {$IFDEF DARWIN}
  WriteLn('  操作系统: macOS');
  {$ENDIF}
  WriteLn('  编译器: Free Pascal 3.3.1');
  WriteLn('');

  // 创建并运行标准测试运行器
  App := TTestRunner.Create(nil);
  try
    App.Initialize;
    App.Title := 'fafafa.core.simd 2.0 测试';
    App.Run;
  finally
    App.Free;
  end;
end.
