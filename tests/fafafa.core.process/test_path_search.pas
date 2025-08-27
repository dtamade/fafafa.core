unit test_path_search;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.base,
  fafafa.core.process;

type

  { TTestCase_PathSearch - PATH 搜索功能测试套件
  
    测试跨平台的 PATH 搜索功能，确保：
    1. Windows 平台正确处理 PATHEXT 扩展
    2. Unix 平台正确搜索 PATH 目录
    3. 可执行文件验证逻辑正确
    4. 边界情况处理正确
  }
  TTestCase_PathSearch = class(TTestCase)
  private
    FStartInfo: IProcessStartInfo;

  protected
    procedure SetUp; override;
    procedure TearDown; override;

  published
    // 基本 PATH 搜索测试
    procedure TestValidateWithKnownExecutable;
    procedure TestValidateWithUnknownExecutable;
    procedure TestValidateWithAbsolutePath;
    procedure TestValidateWithRelativePath;
    
    // Windows 特定测试
    {$IFDEF WINDOWS}
    procedure TestValidateWithoutExtension;
    procedure TestValidateWithWrongExtension;
    procedure TestValidateWithPathExt;
    {$ENDIF}
    
    // Unix 特定测试
    {$IFDEF UNIX}
    procedure TestValidateUnixExecutable;
    procedure TestValidateUnixNonExecutable;
    {$ENDIF}
    
    // 边界情况测试
    procedure TestValidateEmptyFileName;
    procedure TestValidateInvalidChars;
    procedure TestValidateWithWorkingDirectory;
  end;

implementation

{ TTestCase_PathSearch }

procedure TTestCase_PathSearch.SetUp;
begin
  inherited SetUp;
  FStartInfo := TProcessStartInfo.Create;
end;

procedure TTestCase_PathSearch.TearDown;
begin
  FStartInfo := nil;
  inherited TearDown;
end;

procedure TTestCase_PathSearch.TestValidateWithKnownExecutable;
begin
  // 测试已知存在的可执行文件
  {$IFDEF WINDOWS}
  FStartInfo.FileName := 'cmd.exe';
  {$ELSE}
  FStartInfo.FileName := '/bin/sh';
  {$ENDIF}

  // 须显式允许 PATH 搜索（默认关闭）
  FStartInfo.SetUsePathSearch(True);

  // 应该不会抛出异常
  FStartInfo.Validate;
  AssertTrue('验证应该成功', True);
end;

procedure TTestCase_PathSearch.TestValidateWithUnknownExecutable;
begin
  // 测试不存在的可执行文件
  FStartInfo.FileName := 'nonexistent_program_12345';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出找不到文件的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
      AssertTrue('错误消息应该包含文件名', Pos('nonexistent_program_12345', E.Message) > 0);
    end;
  end;
end;

procedure TTestCase_PathSearch.TestValidateWithAbsolutePath;
begin
  // 测试绝对路径
  {$IFDEF WINDOWS}
  FStartInfo.FileName := 'C:\Windows\System32\cmd.exe';
  {$ELSE}
  FStartInfo.FileName := '/bin/sh';
  {$ENDIF}
  
  // 应该不会抛出异常
  FStartInfo.Validate;
  AssertTrue('绝对路径验证应该成功', True);
end;

procedure TTestCase_PathSearch.TestValidateWithRelativePath;
begin
  // 测试相对路径（包含路径分隔符）
  {$IFDEF WINDOWS}
  FStartInfo.FileName := '.\nonexistent.exe';
  {$ELSE}
  FStartInfo.FileName := './nonexistent';
  {$ENDIF}
  
  try
    FStartInfo.Validate;
    Fail('应该抛出找不到文件的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
    end;
  end;
end;

{$IFDEF WINDOWS}
procedure TTestCase_PathSearch.TestValidateWithoutExtension;
begin
  // 测试没有扩展名的文件（应该通过 PATHEXT 找到）
  FStartInfo.FileName := 'cmd';

  // 须显式允许 PATH 搜索
  FStartInfo.SetUsePathSearch(True);

  // 应该不会抛出异常（通过 PATHEXT 找到 cmd.exe）
  FStartInfo.Validate;
  AssertTrue('无扩展名验证应该成功', True);
end;

procedure TTestCase_PathSearch.TestValidateWithWrongExtension;
begin
  // 测试错误扩展名的文件
  FStartInfo.FileName := 'cmd.wrong';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出找不到文件的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
    end;
  end;
end;

procedure TTestCase_PathSearch.TestValidateWithPathExt;
begin
  // 测试 PATHEXT 中的其他扩展名
  FStartInfo.FileName := 'notepad';

  // 须显式允许 PATH 搜索
  FStartInfo.SetUsePathSearch(True);

  // 应该不会抛出异常（通过 PATHEXT 找到 notepad.exe）
  FStartInfo.Validate;
  AssertTrue('PATHEXT 验证应该成功', True);
end;
{$ENDIF}

{$IFDEF UNIX}
procedure TTestCase_PathSearch.TestValidateUnixExecutable;
begin
  // 测试 Unix 可执行文件
  FStartInfo.FileName := 'ls';
  
  // 应该不会抛出异常
  FStartInfo.Validate;
  AssertTrue('Unix 可执行文件验证应该成功', True);
end;

procedure TTestCase_PathSearch.TestValidateUnixNonExecutable;
begin
  // 测试不存在的 Unix 文件
  FStartInfo.FileName := 'nonexistent_unix_program';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出找不到文件的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
    end;
  end;
end;
{$ENDIF}

procedure TTestCase_PathSearch.TestValidateEmptyFileName;
begin
  // 测试空文件名
  FStartInfo.FileName := '';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出文件名为空的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
      AssertTrue('错误消息应该提到文件名为空', Pos('空', E.Message) > 0);
    end;
  end;
end;

procedure TTestCase_PathSearch.TestValidateInvalidChars;
begin
  // 测试包含无效字符的文件名
  FStartInfo.FileName := 'invalid<file>name';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出无效字符的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
      AssertTrue('错误消息应该提到无效字符', Pos('无效字符', E.Message) > 0);
    end;
  end;
end;

procedure TTestCase_PathSearch.TestValidateWithWorkingDirectory;
begin
  // 测试工作目录验证
  {$IFDEF WINDOWS}
  FStartInfo.FileName := 'cmd.exe';
  {$ELSE}
  FStartInfo.FileName := '/bin/sh';
  {$ENDIF}
  FStartInfo.WorkingDirectory := '/nonexistent/directory';
  
  try
    FStartInfo.Validate;
    Fail('应该抛出工作目录不存在的异常');
  except
    on E: EProcessStartError do
    begin
      AssertTrue('应该是进程启动错误', True);
      AssertTrue('错误消息应该提到工作目录', Pos('工作目录', E.Message) > 0);
    end;
  end;
end;

initialization
  RegisterTest(TTestCase_PathSearch);

end.
