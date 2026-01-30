unit test_resource_cleanup;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.process;

type

  { TTestCase_ResourceCleanup - 资源清理测试套件
  
    专门测试进程对象的资源清理行为，确保：
    1. 流对象正确释放
    2. 底层句柄正确关闭
    3. 没有内存泄漏
    4. 没有重复关闭句柄
  }
  TTestCase_ResourceCleanup = class(TTestCase)
  private
    FStartInfo: IProcessStartInfo;
    FProcess: IProcess;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基本资源清理测试
    procedure TestBasicResourceCleanup;
    procedure TestCloseStandardInputBeforeDestroy;
    procedure TestMultipleCloseStandardInput;
    procedure TestDestroyWithoutStart;
    procedure TestDestroyAfterProcessExit;
    
    // 异常情况测试
    procedure TestResourceCleanupWithException;
    procedure TestResourceCleanupAfterKill;
  end;

implementation

{ TTestCase_ResourceCleanup }

procedure TTestCase_ResourceCleanup.SetUp;
begin
  inherited SetUp;
  
  // 创建基本的进程配置
  FStartInfo := TProcessStartInfo.Create;
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};
  FStartInfo.RedirectStandardInput := True;
  FStartInfo.RedirectStandardOutput := True;
  FStartInfo.RedirectStandardError := True;
  
  FProcess := nil;
end;

procedure TTestCase_ResourceCleanup.TearDown;
begin
  // 清理进程（如果还在运行）
  if Assigned(FProcess) and not FProcess.HasExited then
  begin
    try
      FProcess.Kill;
    except
      // 忽略清理时的异常
    end;
  end;
  FProcess := nil;
  FStartInfo := nil;
  inherited TearDown;
end;

procedure TTestCase_ResourceCleanup.TestBasicResourceCleanup;
begin
  // 创建并启动进程
  FProcess := TProcess.Create(FStartInfo);
  FProcess.Start;
  
  // 验证流对象已创建
  AssertNotNull('标准输入流应该已创建', FProcess.StandardInput);
  AssertNotNull('标准输出流应该已创建', FProcess.StandardOutput);
  AssertNotNull('标准错误流应该已创建', FProcess.StandardError);
  
  // 等待进程结束
  AssertTrue('进程应该能正常结束', FProcess.WaitForExit(5000));
  
  // 进程对象会在作用域结束时自动释放，这里测试不会有异常
  // 实际的资源清理测试通过内存泄漏检测来验证
end;

procedure TTestCase_ResourceCleanup.TestCloseStandardInputBeforeDestroy;
begin
  // 创建并启动进程
  FProcess := TProcess.Create(FStartInfo);
  FProcess.Start;
  
  // 验证标准输入流存在
  AssertNotNull('标准输入流应该已创建', FProcess.StandardInput);
  
  // 手动关闭标准输入
  FProcess.CloseStandardInput;
  
  // 验证标准输入流已被清理
  AssertNull('标准输入流应该已被清理', FProcess.StandardInput);
  
  // 等待进程结束
  AssertTrue('进程应该能正常结束', FProcess.WaitForExit(5000));
  
  // 进程对象释放时不应该有异常（因为标准输入已经关闭）
end;

procedure TTestCase_ResourceCleanup.TestMultipleCloseStandardInput;
begin
  // 创建并启动进程
  FProcess := TProcess.Create(FStartInfo);
  FProcess.Start;
  
  // 验证标准输入流存在
  AssertNotNull('标准输入流应该已创建', FProcess.StandardInput);
  
  // 多次关闭标准输入应该不会有异常
  FProcess.CloseStandardInput;
  FProcess.CloseStandardInput;  // 第二次调用应该安全
  FProcess.CloseStandardInput;  // 第三次调用应该安全
  
  // 验证标准输入流已被清理
  AssertNull('标准输入流应该已被清理', FProcess.StandardInput);
  
  // 等待进程结束
  AssertTrue('进程应该能正常结束', FProcess.WaitForExit(5000));
end;

procedure TTestCase_ResourceCleanup.TestDestroyWithoutStart;
begin
  // 创建进程但不启动
  FProcess := TProcess.Create(FStartInfo);
  
  // 验证流对象未创建
  AssertNull('标准输入流不应该存在', FProcess.StandardInput);
  AssertNull('标准输出流不应该存在', FProcess.StandardOutput);
  AssertNull('标准错误流不应该存在', FProcess.StandardError);
  
  // 释放进程对象应该不会有异常
  FProcess := nil;
end;

procedure TTestCase_ResourceCleanup.TestDestroyAfterProcessExit;
begin
  // 创建并启动进程
  FProcess := TProcess.Create(FStartInfo);
  FProcess.Start;
  
  // 等待进程结束
  AssertTrue('进程应该能正常结束', FProcess.WaitForExit(5000));
  AssertTrue('进程应该已退出', FProcess.HasExited);
  
  // 释放进程对象应该不会有异常
  FProcess := nil;
end;

procedure TTestCase_ResourceCleanup.TestResourceCleanupWithException;
var
  LInvalidStartInfo: IProcessStartInfo;
  LInvalidProcess: IProcess;
begin
  // 创建一个无效的进程配置
  LInvalidStartInfo := TProcessStartInfo.Create;
  LInvalidStartInfo.FileName := 'nonexistent_program_12345';
  LInvalidStartInfo.RedirectStandardInput := True;
  LInvalidStartInfo.RedirectStandardOutput := True;
  LInvalidStartInfo.RedirectStandardError := True;
  
  LInvalidProcess := TProcess.Create(LInvalidStartInfo);
  
  try
    // 尝试启动无效进程应该抛出异常
    LInvalidProcess.Start;
    Fail('启动无效进程应该抛出异常');
  except
    on E: EProcessStartError do
    begin
      // 预期的异常
      AssertTrue('应该是进程启动错误', True);
    end;
  end;
  
  // 即使启动失败，释放进程对象也应该安全
  LInvalidProcess := nil;
end;

procedure TTestCase_ResourceCleanup.TestResourceCleanupAfterKill;
begin
  // 创建一个长时间运行的进程
  FStartInfo.FileName := {$IFDEF WINDOWS}'C:\Windows\System32\ping.exe'{$ELSE}'/bin/sleep'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'127.0.0.1 -n 10'{$ELSE}'5'{$ENDIF};
  
  FProcess := TProcess.Create(FStartInfo);
  FProcess.Start;
  
  // 验证进程正在运行
  AssertTrue('进程应该正在运行', FProcess.State = psRunning);
  
  // 强制终止进程
  FProcess.Kill;
  
  // 验证进程已被终止
  AssertTrue('进程应该已被终止', FProcess.HasExited);
  AssertTrue('进程状态应该是已终止', FProcess.State = psTerminated);
  
  // 释放进程对象应该不会有异常
  FProcess := nil;
end;

initialization
  RegisterTest(TTestCase_ResourceCleanup);

end.
