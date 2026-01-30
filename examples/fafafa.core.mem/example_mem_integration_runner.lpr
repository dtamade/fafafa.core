program example_mem_integration_runner;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils, Classes, StrUtils,
  consoletestrunner,
  fafafa.core.mem.memoryMap,
  // 集成/跨域示例测试单元（已从 tests 迁移为示例）
  Test_memory_map,
  Test_memory_map_flushrange,
  Test_shared_memory,
  Test_shared_memory_crossproc,
  Test_shared_memory_crossproc_unix,

  // 暂不包含 enhanced_* 单元，待该系列稳定后再纳入
  Test_memory_performance;

{$I helper_sharedmem_main.inc}

var
  LApplication: TTestRunner;

function IsHelperSharedMemRequested: Boolean;
var
  LIndex: Integer;
  LParam: string;
  LPrefix: string;
begin
  Result := False;
  LPrefix := '--helper-sharedmem';
  for LIndex := 1 to ParamCount do
  begin
    LParam := ParamStr(LIndex);
    if SameText(LParam, LPrefix) or
      (LeftStr(LParam, Length(LPrefix) + 1) = LPrefix + '=') then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

begin
  if IsHelperSharedMemRequested then
  begin
    helper_sharedmem_main;
    Halt(0);
  end;

  DefaultFormat := fPlain;
  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'fafafa.core.mem 集成/示例测试 Runner';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
