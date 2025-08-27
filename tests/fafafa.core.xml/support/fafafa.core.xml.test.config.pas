{$CODEPAGE UTF8}
unit fafafa.core.xml.test.config;

{$mode objfpc}{$H+}

interface

uses
  consoletestrunner;

procedure ConfigureRunner(AApp: TTestRunner);

implementation

procedure ConfigureRunner(AApp: TTestRunner);
begin
  // 最小配置：默认使用 plain 输出；进度与其它参数由命令行控制（-p/--all 等）
  DefaultFormat := fPlain;
end;

end.

