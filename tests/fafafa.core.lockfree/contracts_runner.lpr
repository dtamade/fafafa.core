program contracts_runner;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{ 独立入口：手动运行契约测试（不纳入默认 BuildOrTest） }

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, fpcunit, testregistry, consoletestrunner, testutils,
  // 契约单元（默认 TE；GI 可选）
  Test_Contracts_IQueue,
  Test_Contracts_IStack,
  Test_Contracts_IMap,
  Test_Contracts_IMap_StrInt,
  Contracts_Factories_StrInt_TE,
  Contracts_OAHashMap_CreateFallback_test in 'contracts\Contracts_OAHashMap_CreateFallback_test.pas'
  {$IFDEF FAFAFA_IFACE_GI}
  ,Contracts_Factories_GI_Impl // 仅触发链接，GI 工厂仍为占位
  {$ENDIF}
  ;

var
  Runner: TTestRunner;
begin
  DefaultRunAllTests := True;
  DefaultFormat := fPlain;
  Runner := TTestRunner.Create(nil);
  try
    Runner.Initialize;
    {$IFDEF FAFAFA_IFACE_GI}
    Runner.Title := 'fafafa.core.lockfree contracts (GI experimental)';
    {$ELSE}
    Runner.Title := 'fafafa.core.lockfree contracts (TE)';
    {$ENDIF}
    Runner.Run;
    // 打印汇总
    Writeln('Summary:');
    Writeln('  Ran (total unknown by API in this runner), see above');
    // fpcunit 没有稳定的全局计数 API，这里仅提示成功与否
    Writeln('  Completed without unhandled exceptions');
  finally
    Runner.Free;
  end;
end.

