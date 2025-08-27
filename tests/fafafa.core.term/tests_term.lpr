{$CODEPAGE UTF8}
program tests_term;

{**
 * fafafa.core.term 模块测试程序
 *
 * 这个程序运行 fafafa.core.term 模块的所有单元测试
 * 使用 FPCUnit 测试框架
 *}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp,
  fpcunit, testregistry, consoletestrunner,
  Test_term,
  Test_term_event_queue,
  Test_term_color_degrade,
  Test_term_input_semantics,
  {$IFDEF UNIX}
  Test_term_unix_sequences,
  {$ENDIF}
  Test_term_core_smoke,
  Test_term_events_collect,
  Test_term_events_collect_edgecases,
  Test_term_events_wheel_boundaries,
  Test_term_resize_storm_debounce_interrupt,
  Test_term_modeguard_nesting,
  Test_term_events_feature_toggles,
  Test_term_protocol_toggles_smoke;

type

  { TTermTestApplication }

  TTermTestApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TTermTestApplication }

procedure TTermTestApplication.DoRun;
var
  ErrorMsg: String;
  LTestRunner: TTestRunner;
begin


  // 解析参数（保留 -h/--help）
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  WriteLn('fafafa.core.term 模块测试');
  WriteLn('==========================');
  WriteLn;

  // 创建并运行测试
  LTestRunner := TTestRunner.Create(nil);
  try
    LTestRunner.Initialize;
    LTestRunner.Run;
  finally
    LTestRunner.Free;
  end;

  // 停止程序循环
  Terminate;
end;

constructor TTermTestApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TTermTestApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TTermTestApplication.WriteHelp;
begin
  WriteLn('用法: ', ExeName, ' -h');
  WriteLn;
  WriteLn('  -h --help   显示此帮助信息');
  WriteLn;
  WriteLn('这个程序运行 fafafa.core.term 模块的所有单元测试。');
end;

var
  Application: TTermTestApplication;
begin
  Application := TTermTestApplication.Create(nil);
  Application.Title := 'fafafa.core.term Tests';
  Application.Run;
  Application.Free;
end.
