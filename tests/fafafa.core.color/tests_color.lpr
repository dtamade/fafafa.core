program tests_color;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  consoletestrunner,
  fafafa.core.color.testcase,
  fafafa.core.color.resultadapter.testcase,
  fafafa.core.color.named.testcase,
  fafafa.core.color.named.css.testcase,
  fafafa.core.color.advanced.testcase,
  fafafa.core.color.advanced.props.testcase,
  fafafa.core.color.oklab.testcase,
  fafafa.core.color.oklab.mix.testcase,
  fafafa.core.color.oklab.props.testcase,
  fafafa.core.color.oklch.props.testcase,
  fafafa.core.color.palette.testcase,
  fafafa.core.color.jsonadapter.testcase,
  fafafa.core.color.palette.multi.testcase,
  fafafa.core.color.palette.positions.testcase,
  fafafa.core.color.palette.positions.norm.testcase,
  fafafa.core.color.palette.props.testcase,
  fafafa.core.color.hex.safe.testcase,
  fafafa.core.color.hex.ext.testcase,
  fafafa.core.color.oklch.lightdark.testcase,
  fafafa.core.color.term.reverse.testcase,
  fafafa.core.color.oklch.gamut.testcase,
  fafafa.core.color.oklch.gamut.props.testcase,
  fafafa.core.color.oklch.gamut.props.extra.testcase,
  fafafa.core.color.oklch.gamut.props.edge.testcase,
  fafafa.core.color.gamma.roundtrip.testcase,
  fafafa.core.color.palette.struct.testcase,
  fafafa.core.color.contrast.enforced.testcase,
  fafafa.core.color.palette.struct.props.testcase,
  fafafa.core.color.palette.strategy.testcase,
  fafafa.core.color.palette.strategy.props.testcase,
  fafafa.core.color.palette.strategy.edit.testcase,
  fafafa.core.color.palette.strategy.mode_string.testcase,
  fafafa.core.color.palette.strategy.fixup.testcase,
  fafafa.core.color.hex.parse.strict.testcase,
  fafafa.core.color.lightdark.single.testcase;

var
  LApplication: TTestRunner;

begin
  WriteLn('========================================');
  WriteLn('fafafa.core.color 单元测试');
  WriteLn('========================================');
  WriteLn;

  LApplication := TTestRunner.Create(nil);
  try
    LApplication.Initialize;
    LApplication.Title := 'Color Tests';
    LApplication.Run;
  finally
    LApplication.Free;
  end;
end.

