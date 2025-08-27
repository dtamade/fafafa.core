unit test_useshellexecute;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.process;

type

  { TTestCase_UseShellExecute - UseShellExecute 语义测试套件
  
    测试 UseShellExecute 属性的当前语义，确保：
    1. 属性可以正常设置和获取
    2. UseShellExecute=True 时跳过文件存在性检查
    3. UseShellExecute=False 时进行文件存在性检查
    4. 两种模式都使用相同的底层启动机制
    5. 文档化当前的设计限制
  }
  TTestCase_UseShellExecute = class(TTestCase)
  private
    FStartInfo: IProcessStartInfo;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基本属性测试
    procedure TestUseShellExecuteProperty;
    procedure TestUseShellExecuteDefaultValue;
    
    // 验证行为测试
    procedure TestValidationWithUseShellExecuteFalse;
    procedure TestValidationWithUseShellExecuteTrue;
    procedure TestValidationSkipsFileCheckWhenTrue;
    
    // 进程启动行为测试
    procedure TestProcessStartWithUseShellExecuteFalse;
    procedure TestProcessStartWithUseShellExecuteTrue;
    procedure TestBothModesUseSameStartMechanism;
    
    // Builder 模式测试
    procedure TestProcessBuilderUseShell;
    
    // 边界情况测试
    procedure TestUseShellExecuteWithInvalidFile;
    procedure TestUseShellExecuteWithValidFile;
  end;

implementation

{ TTestCase_UseShellExecute }

procedure TTestCase_UseShellExecute.SetUp;
begin
  inherited SetUp;
  FStartInfo := TProcessStartInfo.Create;
end;

procedure TTestCase_UseShellExecute.TearDown;
begin
  FStartInfo := nil;
  inherited TearDown;
end;

procedure TTestCase_UseShellExecute.TestUseShellExecuteProperty;
begin
  // 测试属性的基本功能
  FStartInfo.UseShellExecute := True;
  AssertTrue('UseShellExecute 应该为 True', FStartInfo.UseShellExecute);
  
  FStartInfo.UseShellExecute := False;
  AssertFalse('UseShellExecute 应该为 False', FStartInfo.UseShellExecute);
end;

procedure TTestCase_UseShellExecute.TestUseShellExecuteDefaultValue;
begin
  // 测试默认值
  AssertFalse('UseShellExecute 默认值应该为 False', FStartInfo.UseShellExecute);
end;

procedure TTestCase_UseShellExecute.TestValidationWithUseShellExecuteFalse;
begin
  // UseShellExecute=False 时应该检查文件存在性
  FStartInfo.FileName := 'nonexistent_program_12345';
  FStartInfo.UseShellExecute := False;
  
  try
    FStartInfo.Validate;
    Fail('UseShellExecute=False 时应该抛出文件不存在异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
      AssertTrue('错误消息应该包含文件名', Pos('nonexistent_program_12345', E.Message) > 0);
    end;
  end;
end;

procedure TTestCase_UseShellExecute.TestValidationWithUseShellExecuteTrue;
begin
  // UseShellExecute=True 时应该跳过文件存在性检查
  FStartInfo.FileName := 'nonexistent_program_12345';
  FStartInfo.UseShellExecute := True;
  
  // 应该不会抛出文件不存在异常
  FStartInfo.Validate;
  AssertTrue('UseShellExecute=True 时应该跳过文件存在性检查', True);
end;

procedure TTestCase_UseShellExecute.TestValidationSkipsFileCheckWhenTrue;
begin
  // 验证 UseShellExecute=True 确实跳过了文件检查
  FStartInfo.FileName := 'definitely_nonexistent_file_xyz123';
  FStartInfo.UseShellExecute := True;
  
  // 这应该不会抛出异常
  FStartInfo.Validate;
  
  // 但是如果设置为 False，应该抛出异常
  FStartInfo.UseShellExecute := False;
  try
    FStartInfo.Validate;
    Fail('UseShellExecute=False 时应该抛出异常');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出文件不存在异常', True);
  end;
end;

procedure TTestCase_UseShellExecute.TestProcessStartWithUseShellExecuteFalse;
var
  LProcess: IProcess;
begin
  // 测试 UseShellExecute=False 的进程启动
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};
  FStartInfo.UseShellExecute := False;
  FStartInfo.RedirectStandardOutput := True;
  
  LProcess := TProcess.Create(FStartInfo);
  try
    LProcess.Start;
    AssertTrue('进程应该启动成功', LProcess.ProcessId > 0);
    AssertTrue('进程应该能正常结束', LProcess.WaitForExit(5000));
  finally
    LProcess := nil;
  end;
end;

procedure TTestCase_UseShellExecute.TestProcessStartWithUseShellExecuteTrue;
var
  LProcess: IProcess;
begin
  // 测试 UseShellExecute=True 的进程启动
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  FStartInfo.Arguments := {$IFDEF WINDOWS}'/c echo test'{$ELSE}'test'{$ENDIF};
  FStartInfo.UseShellExecute := True;
  {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  // 最小 ShellExecuteEx 模式下不允许重定向
  FStartInfo.RedirectStandardOutput := False;
  {$ELSE}
  // 传统语义下允许重定向
  FStartInfo.RedirectStandardOutput := True;
  {$ENDIF}
  
  LProcess := TProcess.Create(FStartInfo);
  try
    LProcess.Start;
    AssertTrue('进程应该启动成功', LProcess.ProcessId > 0);
    AssertTrue('进程应该能正常结束', LProcess.WaitForExit(5000));
  finally
    LProcess := nil;
  end;
end;

procedure TTestCase_UseShellExecute.TestBothModesUseSameStartMechanism;
var
  LProcessFalse, LProcessTrue: IProcess;
  LStartInfoFalse, LStartInfoTrue: IProcessStartInfo;
begin
  {$IFNDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
  // 验证两种模式使用相同的启动机制（传统设计）

  // UseShellExecute=False
  LStartInfoFalse := TProcessStartInfo.Create;
  LStartInfoFalse.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  LStartInfoFalse.Arguments := {$IFDEF WINDOWS}'/c echo false_mode'{$ELSE}'false_mode'{$ENDIF};
  LStartInfoFalse.UseShellExecute := False;
  LStartInfoFalse.RedirectStandardOutput := True;

  // UseShellExecute=True
  LStartInfoTrue := TProcessStartInfo.Create;
  LStartInfoTrue.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF};
  LStartInfoTrue.Arguments := {$IFDEF WINDOWS}'/c echo true_mode'{$ELSE}'true_mode'{$ENDIF};
  LStartInfoTrue.UseShellExecute := True;
  LStartInfoTrue.RedirectStandardOutput := True;

  LProcessFalse := TProcess.Create(LStartInfoFalse);
  LProcessTrue := TProcess.Create(LStartInfoTrue);

  try
    LProcessFalse.Start;
    LProcessTrue.Start;

    // 两个进程都应该能正常启动和结束
    AssertTrue('UseShellExecute=False 进程应该启动', LProcessFalse.ProcessId > 0);
    AssertTrue('UseShellExecute=True 进程应该启动', LProcessTrue.ProcessId > 0);

    AssertTrue('UseShellExecute=False 进程应该结束', LProcessFalse.WaitForExit(5000));
    AssertTrue('UseShellExecute=True 进程应该结束', LProcessTrue.WaitForExit(5000));

    // 两个进程都应该能重定向输出（证明使用相同机制）
    AssertNotNull('UseShellExecute=False 应该有输出流', LProcessFalse.StandardOutput);
    AssertNotNull('UseShellExecute=True 应该有输出流', LProcessTrue.StandardOutput);

  finally
    LProcessFalse := nil;
    LProcessTrue := nil;
  end;
  {$ELSE}
  // 最小 ShellExecuteEx 模式下，机制不同且不允许重定向，这里跳过
  AssertTrue(True);
  {$ENDIF}
end;

procedure TTestCase_UseShellExecute.TestProcessBuilderUseShell;
var
  LBuilder: IProcessBuilder;
  LProcess: IProcess;
begin
  // 测试 ProcessBuilder 的 UseShell 方法
  LBuilder := TProcessBuilder.Create;
  LBuilder.Exe({$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/echo'{$ENDIF})
          .Args([{$IFDEF WINDOWS}'/c', 'echo', 'builder_test'{$ELSE}'builder_test'{$ENDIF}])
          .UseShell(True)
          {$IFDEF FAFAFA_PROCESS_SHELLEXECUTE_MINIMAL}
          .RedirectStdOut(False)
          {$ELSE}
          .RedirectStdOut(True)
          {$ENDIF}
          ;
  
  LProcess := LBuilder.Build;
  try
    LProcess.Start;
    AssertTrue('Builder 创建的进程应该启动成功', LProcess.ProcessId > 0);
    AssertTrue('Builder 创建的进程应该能结束', LProcess.WaitForExit(10000));
  finally
    LProcess := nil;
  end;
end;

procedure TTestCase_UseShellExecute.TestUseShellExecuteWithInvalidFile;
begin
  // 测试无效文件的处理
  FStartInfo.FileName := '';
  FStartInfo.UseShellExecute := True;
  
  try
    FStartInfo.Validate;
    Fail('空文件名应该抛出异常，即使 UseShellExecute=True');
  except
    on E: EProcessStartError do
      AssertTrue('应该抛出文件名为空异常', Pos('空', E.Message) > 0);
  end;
end;

procedure TTestCase_UseShellExecute.TestUseShellExecuteWithValidFile;
begin
  // 测试有效文件的处理
  FStartInfo.FileName := {$IFDEF WINDOWS}'cmd.exe'{$ELSE}'/bin/sh'{$ENDIF};
  FStartInfo.UseShellExecute := True;
  
  // 应该不会抛出异常
  FStartInfo.Validate;
  AssertTrue('有效文件应该通过验证', True);
end;

initialization
  RegisterTest(TTestCase_UseShellExecute);

end.
