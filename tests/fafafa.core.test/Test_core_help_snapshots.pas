unit Test_core_help_snapshots;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command, fafafa.core.args.schema, fafafa.core.args.help,
  fafafa.core.test.snapshot;

type
  TTestCase_Core_Help_Snapshots = class(TTestCase)
  published
    procedure Test_Snapshots;
  end;

procedure RegisterTests;

implementation

procedure TTestCase_Core_Help_Snapshots.Test_Snapshots;
var
  Root: IRootCommand; Cmd: ICommand; Spec: IArgsCommandSpec;
  S: string; Opts: TRenderUsageOptions;
  Update: boolean;
begin
  // Prepare command with aliases/types
  Root := NewRootCommand;
  Cmd := NewCommand('run');
  Cmd.AddAlias('r');
  Cmd.SetDescription('Run a task');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('count', 'Number of times', True, 'int', '1'));
  Spec.AddFlag(NewFlagSpec('json', 'Output JSON', False, 'bool'));
  Spec.AddPositional(NewPositionalSpec('file', 'Input file path', True, False));
  Cmd.SetSpec(Spec);
  Root.Register(Cmd);

  // Stable width for snapshot by forcing Options.width
  // Avoid relying on environment specific API here
  Opts := RenderUsageOptionsDefault;
  Opts.width := 80;
  S := RenderUsage(Cmd, Opts);
  Update := GetEnvironmentVariable('TEST_SNAPSHOT_UPDATE') <> '';
  AssertTrue(CompareTextSnapshot('../../snapshots', 'usage_default', S, Update));

  // 2) hide aliases and types at width=80 to keep alignment consistent
  Opts := RenderUsageOptionsDefault;
  Opts.width := 80;
  Opts.showAliases := False;
  Opts.showTypes := False;
  S := RenderUsage(Cmd, Opts);
  AssertTrue(CompareTextSnapshot('../../snapshots', 'usage_no_aliases_no_types', S, Update));

  // 3) nowrap + width=40
  Opts := RenderUsageOptionsDefault;
  Opts.wrap := False;
  Opts.width := 40;
  S := RenderUsage(Cmd, Opts);
  AssertTrue(CompareTextSnapshot('../../snapshots', 'usage_nowrap_w40', S, Update));

  // 4) no section headers + width=80
  Opts := RenderUsageOptionsDefault;
  Opts.width := 80;
  Opts.showSectionHeaders := False;
  S := RenderUsage(Cmd, Opts);
  AssertTrue(CompareTextSnapshot('../../snapshots', 'usage_no_headers_w80', S, Update));
end;

procedure RegisterTests;
begin
  RegisterTest(TTestCase_Core_Help_Snapshots);
end;

end.

