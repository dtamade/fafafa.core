program fafafa.core.sync.mutex.parkinglot.test;

{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner,
  fafafa.core.sync.mutex.parkinglot.testcase;

type
  { TMyTestRunner }
  TMyTestRunner = class(TTestRunner)
  protected
    procedure WriteCustomHelp; override;
  end;

procedure TMyTestRunner.WriteCustomHelp;
begin
  inherited WriteCustomHelp;
  WriteLn('');
  WriteLn('fafafa.core.sync.mutex.parkinglot 测试套件');
  WriteLn('');
  WriteLn('测试类别:');
  WriteLn('  TTestCase_Global           - 全局工厂函数测试');
  WriteLn('  TTestCase_IParkingLotMutex - 基本接口功能测试');
  WriteLn('  TTestCase_Concurrency      - 并发和压力测试');
  WriteLn('  TTestCase_Performance      - 性能基准测试');
  WriteLn('  TTestCase_EdgeCases        - 边界条件和异常测试');
  WriteLn('  TTestCase_Platform         - 平台特定功能测试');
  WriteLn('');
  WriteLn('示例用法:');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' --suite=TTestCase_Global');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' --suite=TTestCase_Concurrency');
  WriteLn('  ', ExtractFileName(ParamStr(0)), ' --format=junit --file=results.xml');
end;

var
  Application: TMyTestRunner;

begin
  Application := TMyTestRunner.Create(nil);
  try
    Application.Title := 'fafafa.core.sync.mutex.parkinglot Test Suite';
    Application.Initialize;
    Application.Run;
  finally
    Application.Free;
  end;
end.
