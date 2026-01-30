program fafafa_core_lockfree_tests;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner, DOM,
  fafafa.core.base,
  // 原子统一：tests 不再引用 fafafa.core.sync

  fafafa.core.lockfree,
  ifaces_factories.testcase,
  Test_lockfree,
  test_strict_factories,
  test_oa_record_key_strict,
  bench_blocking_policy,
  test_channel_basic;

type
  { TLockFreeTestRunner }
  TLockFreeTestRunner = class(TTestRunner)
  protected
    procedure ExtendXmlDocument(Doc: TXMLDocument); override;
  end;

procedure TLockFreeTestRunner.ExtendXmlDocument(Doc: TXMLDocument);
begin
  inherited ExtendXmlDocument(Doc);
end;

var
  LApplication: TLockFreeTestRunner;
  backoff: String;

begin
  WriteLn('fafafa.core.lockfree 单元测试');
  WriteLn('============================');
  WriteLn;

  // 启用详细输出，便于定位卡死测试
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;

  if GetEnvironmentVariable('FAFAFA_BENCH') <> '' then
  begin
    // Optional: select backoff variant
    backoff := GetEnvironmentVariable('FAFAFA_BENCH_BACKOFF');
    if (backoff <> '') and (CompareText(backoff, 'Aggressive') = 0) then
    begin
      RunBlockingPolicyMicroBench_Aggressive;
      RunBlockingPolicyMicroBench_MultiModels_Aggressive;
    end
    else
    begin
      RunBlockingPolicyMicroBench;
      RunBlockingPolicyMicroBench_MultiModels;
    end;
    RunMapMicroBench;
    Halt(0);
  end;

  LApplication := TLockFreeTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'fafafa.core.lockfree Unit Tests';
    {$IFDEF DEBUG}
    WriteLn('>> Before TTestRunner.Run');
    {$ENDIF}
    LApplication.Run;
    {$IFDEF DEBUG}
    WriteLn('>> After TTestRunner.Run');
    {$ENDIF}
  finally
    LApplication.Free;
  end;
end.
