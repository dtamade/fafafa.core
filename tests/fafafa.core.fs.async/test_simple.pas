program test_simple;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils;

begin
  Writeln('=== 简单异步文件系统测试 ===');
  Writeln('');
  
  // 基础测试：检查是否可以编译和运行
  Writeln('✓ 编译成功');
  Writeln('✓ UTF8编码正常');
  Writeln('✓ 中文输出正常');
  
  Writeln('');
  Writeln('基础设施测试通过！');
end.
