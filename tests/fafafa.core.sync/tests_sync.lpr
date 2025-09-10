program tests_sync;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, CustApp, fpcunit, testregistry, consoletestrunner,
  fafafa.core.base,
  fafafa.core.sync,
  Test_sync_modern;

type

  { TTestApplication }

  TTestApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ TTestApplication }

procedure TTestApplication.DoRun;
var
  LTestRunner: TTestRunner;
  I: Integer;
  IsXml: Boolean;
  S, Key, Val: String;
begin
  // 检测是否请求 XML 输出（--format=xml 或 --format xml）
  IsXml := False;
  for I := 1 to ParamCount do
  begin
    S := ParamStr(I);
    if Copy(S,1,9) = '--format=' then
    begin
      Val := LowerCase(Copy(S,10,Length(S)-9));
      if Val = 'xml' then IsXml := True;
    end
    else if (S = '--format') and (I < ParamCount) then
    begin
      Val := LowerCase(ParamStr(I+1));
      if Val = 'xml' then IsXml := True;
    end;
  end;

  // 创建测试运行器
  LTestRunner := TTestRunner.Create(nil);
  try
    // 配置测试运行器
    LTestRunner.Initialize;

    // 运行测试
    if not IsXml then
    begin
      WriteLn('');
      WriteLn('========================================');
      WriteLn('fafafa.core.sync 模块测试套件');
      WriteLn('========================================');
      WriteLn('');
    end;

    LTestRunner.Run;

    if not IsXml then
    begin
      WriteLn('');
      WriteLn('========================================');
      WriteLn('测试完成');
      WriteLn('========================================');
    end;

  finally
    LTestRunner.Free;
  end;

  // 终止应用程序
  Terminate;
end;

constructor TTestApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TTestApplication.Destroy;
begin
  inherited Destroy;
end;

var
  LApplication: TTestApplication;

begin
  LApplication := TTestApplication.Create(nil);
  try
    LApplication.Title := 'fafafa.core.sync Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.
