{$CODEPAGE UTF8}
unit TestHelpers_Skip;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit;

// 显式“跳过”助手（保持接口不变，尽量用 FPCUnit 真正 Skip）：
// - 新版：若 fpcunit 提供 ESkipTest，则抛出以标记为 Skipped
// - 旧版：回退为“软跳过”，仅输出提示，调用处仍建议 Exit;
// - 用法不变：TestSkip(Self, 'reason');
procedure TestSkip(const aTestCase: TTestCase; const aReason: string);

implementation

procedure TestSkip(const aTestCase: TTestCase; const aReason: string);
begin
  {$if declared(ESkipTest)}
  raise ESkipTest.Create(aReason);
  {$else}
  // 回退：标记“软跳过”
  aTestCase.CheckTrue(True, 'SKIP: ' + aReason);
  {$endif}
end;

end.

