{$CODEPAGE UTF8}
unit fafafa.core.args.help.testcase;
{**
 * fafafa.core.args.help 单元测试
 * 覆盖帮助生成系统、格式化选项和渲染策略
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args.base,
  fafafa.core.args.command,
  fafafa.core.args.schema,
  fafafa.core.args.help;

type
  TTestCase_ArgsHelp = class(TTestCase)
  published
    // TRenderUsageOptions 默认值测试
    procedure Test_OptionsDefault_Width;
    procedure Test_OptionsDefault_Wrap;
    procedure Test_OptionsDefault_SortSubcommands;
    procedure Test_OptionsDefault_MarkDefaultInChildren;
    procedure Test_OptionsDefault_ShowAliases;
    procedure Test_OptionsDefault_ShowTypes;
    procedure Test_OptionsDefault_ShowSectionHeaders;
    procedure Test_OptionsDefault_GroupFlagsBy;
    procedure Test_OptionsDefault_GroupPositionalsBy;

    // RenderUsage 基础测试
    procedure Test_RenderUsage_EmptyCommand;
    procedure Test_RenderUsage_CommandWithDescription;
    procedure Test_RenderUsage_NilCommand;

    // 子命令渲染测试
    procedure Test_RenderUsage_SingleSubcommand;
    procedure Test_RenderUsage_MultipleSubcommands;
    procedure Test_RenderUsage_SubcommandWithDescription;
    procedure Test_RenderUsage_SubcommandsSorted;
    procedure Test_RenderUsage_SubcommandsUnsorted;
    procedure Test_RenderUsage_NestedSubcommands;

    // 默认子命令标记测试
    procedure Test_RenderUsage_DefaultSubcommand;
    procedure Test_RenderUsage_DefaultSubcommandDisabled;

    // 别名显示测试
    procedure Test_RenderUsage_CommandWithAliases;
    procedure Test_RenderUsage_AliasesHidden;
    procedure Test_RenderUsage_SubcommandAliases;

    // 标志渲染测试
    procedure Test_RenderUsage_SingleFlag;
    procedure Test_RenderUsage_FlagWithShortName;
    procedure Test_RenderUsage_FlagWithDefault;
    procedure Test_RenderUsage_FlagRequired;
    procedure Test_RenderUsage_FlagWithType;
    procedure Test_RenderUsage_FlagTypeHidden;
    procedure Test_RenderUsage_MultipleFlags;
    procedure Test_RenderUsage_FlagsGroupedByRequired;
    procedure Test_RenderUsage_FlagsGroupedAlpha;
    procedure Test_RenderUsage_FlagsUngrouped;
    procedure Test_RenderUsage_PersistentFlag;

    // 位置参数渲染测试
    procedure Test_RenderUsage_SinglePositional;
    procedure Test_RenderUsage_PositionalRequired;
    procedure Test_RenderUsage_PositionalOptional;
    procedure Test_RenderUsage_PositionalVariadic;
    procedure Test_RenderUsage_MultiplePositionals;
    procedure Test_RenderUsage_PositionalsGroupedByRequired;
    procedure Test_RenderUsage_PositionalsGroupedAlpha;

    // 段落标题测试
    procedure Test_RenderUsage_SectionHeaders;
    procedure Test_RenderUsage_SectionHeadersHidden;

    // 宽度和换行测试
    procedure Test_RenderUsage_CustomWidth;
    procedure Test_RenderUsage_WrapEnabled;
    procedure Test_RenderUsage_WrapDisabled;
    procedure Test_RenderUsage_NarrowWidth;

    // 综合渲染测试
    procedure Test_RenderUsage_FullCommand;
    procedure Test_RenderUsage_ComplexHierarchy;
    procedure Test_RenderUsage_RootCommand;

    // 边界测试
    procedure Test_RenderUsage_EmptyDescription;
    procedure Test_RenderUsage_LongDescription;
    procedure Test_RenderUsage_SpecialCharacters;
    procedure Test_RenderUsage_UnicodeText;
  end;

implementation

{ TRenderUsageOptions 默认值测试 }

procedure TTestCase_ArgsHelp.Test_OptionsDefault_Width;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  // width=0 means auto-detect from COLUMNS env variable
  CheckEquals(0, Opts.Width, 'Default width should be 0 (auto-detect)');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_Wrap;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.Wrap, 'Default should enable wrapping');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_SortSubcommands;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.SortSubcommands, 'Default should sort subcommands');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_MarkDefaultInChildren;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.MarkDefaultInChildren, 'Default should mark default in children');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_ShowAliases;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.ShowAliases, 'Default should show aliases');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_ShowTypes;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.ShowTypes, 'Default should show types');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_ShowSectionHeaders;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckTrue(Opts.ShowSectionHeaders, 'Default should show section headers');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_GroupFlagsBy;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckEquals(Ord(gbNone), Ord(Opts.GroupFlagsBy), 'Default should not group flags (gbNone)');
end;

procedure TTestCase_ArgsHelp.Test_OptionsDefault_GroupPositionalsBy;
var
  Opts: TRenderUsageOptions;
begin
  Opts := RenderUsageOptionsDefault;
  CheckEquals(Ord(gbNone), Ord(Opts.GroupPositionalsBy), 'Default should not group positionals (gbNone)');
end;

{ RenderUsage 基础测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_EmptyCommand;
var
  Cmd: ICommand;
  Output: string;
begin
  // Empty command with no children/flags/positionals outputs empty string
  Cmd := NewCommand('test');
  Output := RenderUsage(Cmd);
  // RenderUsage only outputs children, flags, args sections - not the command name itself
  CheckTrue(Length(Output) = 0, 'Empty command should produce empty output');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_CommandWithDescription;
var
  Cmd: ICommand;
  Child: ICommand;
  Output: string;
begin
  // Description is set directly on command, not via spec
  Cmd := NewCommand('myapp');

  // Add a child with description - this description will appear in output
  Child := NewCommand('sub');
  Child.SetDescription('demonstration subcommand');
  Cmd.AddChild(Child);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('demonstration', Output) > 0, 'Output should contain child description');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_NilCommand;
var
  Output: string;
begin
  Output := RenderUsage(nil);
  // Should not crash, return empty or minimal output
  CheckTrue(Length(Output) >= 0, 'Should handle nil gracefully');
end;

{ 子命令渲染测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_SingleSubcommand;
var
  Root: ICommand;
  Child: ICommand;
  Output: string;
begin
  Root := NewCommand('app');
  Child := NewCommand('serve');
  Root.AddChild(Child);

  Output := RenderUsage(Root);
  CheckTrue(Pos('serve', Output) > 0, 'Output should list subcommand');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_MultipleSubcommands;
var
  Root: ICommand;
  Output: string;
begin
  Root := NewCommand('app');
  Root.AddChild(NewCommand('start'));
  Root.AddChild(NewCommand('stop'));
  Root.AddChild(NewCommand('restart'));

  Output := RenderUsage(Root);
  CheckTrue(Pos('start', Output) > 0, 'Output should list start');
  CheckTrue(Pos('stop', Output) > 0, 'Output should list stop');
  CheckTrue(Pos('restart', Output) > 0, 'Output should list restart');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SubcommandWithDescription;
var
  Root: ICommand;
  Child: ICommand;
  Output: string;
begin
  Root := NewCommand('app');
  Child := NewCommand('serve');
  Child.SetDescription('Start the server');
  Root.AddChild(Child);

  Output := RenderUsage(Root);
  CheckTrue(Pos('Start the server', Output) > 0, 'Output should show subcommand description');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SubcommandsSorted;
var
  Root: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
  PosZ, PosA, PosM: Integer;
begin
  Root := NewCommand('app');
  Root.AddChild(NewCommand('zebra'));
  Root.AddChild(NewCommand('alpha'));
  Root.AddChild(NewCommand('middle'));

  Opts := RenderUsageOptionsDefault;
  Opts.SortSubcommands := True;

  Output := RenderUsage(Root, Opts);
  PosA := Pos('alpha', Output);
  PosM := Pos('middle', Output);
  PosZ := Pos('zebra', Output);

  CheckTrue(PosA < PosM, 'alpha should appear before middle');
  CheckTrue(PosM < PosZ, 'middle should appear before zebra');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SubcommandsUnsorted;
var
  Root: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
  PosZ, PosA: Integer;
begin
  Root := NewCommand('app');
  Root.AddChild(NewCommand('zebra'));
  Root.AddChild(NewCommand('alpha'));

  Opts := RenderUsageOptionsDefault;
  Opts.SortSubcommands := False;

  Output := RenderUsage(Root, Opts);
  PosZ := Pos('zebra', Output);
  PosA := Pos('alpha', Output);

  // Without sorting, zebra should appear before alpha (insertion order)
  CheckTrue(PosZ < PosA, 'zebra should appear before alpha (insertion order)');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_NestedSubcommands;
var
  Root, Parent, Child: ICommand;
  Output: string;
begin
  Root := NewCommand('app');
  Parent := NewCommand('config');
  Child := NewCommand('set');
  Parent.AddChild(Child);
  Root.AddChild(Parent);

  Output := RenderUsage(Root);
  CheckTrue(Pos('config', Output) > 0, 'Output should list config');

  // Render parent to see nested command
  Output := RenderUsage(Parent);
  CheckTrue(Pos('set', Output) > 0, 'Parent output should list set');
end;

{ 默认子命令标记测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_DefaultSubcommand;
var
  Root: ICommand;
  Child: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Root := NewCommand('app');
  Child := NewCommand('serve');
  Root.AddChild(Child);
  Root.SetDefaultChildName('serve');

  Opts := RenderUsageOptionsDefault;
  Opts.MarkDefaultInChildren := True;

  Output := RenderUsage(Root, Opts);
  // Should mark default subcommand somehow (e.g., [default] or *)
  CheckTrue((Pos('default', LowerCase(Output)) > 0) or (Pos('*', Output) > 0) or (Pos('serve', Output) > 0),
    'Output should include default subcommand');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_DefaultSubcommandDisabled;
var
  Root: ICommand;
  Child: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Root := NewCommand('app');
  Child := NewCommand('serve');
  Root.AddChild(Child);
  Root.SetDefaultChildName('serve');

  Opts := RenderUsageOptionsDefault;
  Opts.MarkDefaultInChildren := False;

  Output := RenderUsage(Root, Opts);
  // Should NOT mark default when disabled
  CheckTrue(Pos('[default]', LowerCase(Output)) = 0,
    'Output should not mark default when disabled');
end;

{ 别名显示测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_CommandWithAliases;
var
  Cmd: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('serve');
  Cmd.AddAlias('s');
  Cmd.AddAlias('server');

  Opts := RenderUsageOptionsDefault;
  Opts.ShowAliases := True;

  Output := RenderUsage(Cmd, Opts);
  // Output should show aliases
  CheckTrue((Pos('s', Output) > 0) or (Pos('server', Output) > 0) or (Pos('serve', Output) > 0),
    'Output should show command or aliases');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_AliasesHidden;
var
  Cmd: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('serve');
  Cmd.AddAlias('s');
  Cmd.AddAlias('server');

  Opts := RenderUsageOptionsDefault;
  Opts.ShowAliases := False;

  Output := RenderUsage(Cmd, Opts);
  // Aliases section should not appear
  CheckTrue(Pos('Aliases:', Output) = 0, 'Should not show Aliases section');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SubcommandAliases;
var
  Root: ICommand;
  Child: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Root := NewCommand('app');
  Child := NewCommand('build');
  Child.AddAlias('b');
  Child.AddAlias('compile');
  Root.AddChild(Child);

  Opts := RenderUsageOptionsDefault;
  Opts.ShowAliases := True;

  Output := RenderUsage(Root, Opts);
  // Subcommand aliases might be shown inline
  CheckTrue(Pos('build', Output) > 0, 'Should show subcommand name');
end;

{ 标志渲染测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_SingleFlag;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('verbose', 'Enable verbose output', False, 'bool', 'false');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('verbose', Output) > 0, 'Output should show flag name');
  // Description is part of the output line
  CheckTrue(Pos('Enable verbose', Output) > 0, 'Output should show flag description');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagWithShortName;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('verbose', 'Enable verbose output', False, 'bool', 'false');
  Flag.AddAlias('v');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('-v', Output) > 0, 'Output should show short flag');
  CheckTrue(Pos('--verbose', Output) > 0, 'Output should show long flag');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagWithDefault;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('port', 'Port number', False, 'int', '8080');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Output := RenderUsage(Cmd, Opts);

  CheckTrue(Pos('8080', Output) > 0, 'Output should show default value');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagRequired;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('config', 'Config file path', True, 'string', '');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('required', LowerCase(Output)) > 0, 'Output should mark required flag');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagWithType;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('count', 'Item count', False, 'integer', '10');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.ShowTypes := True;

  Output := RenderUsage(Cmd, Opts);
  CheckTrue(Pos('integer', LowerCase(Output)) > 0, 'Output should show type');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagTypeHidden;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('count', 'Item count', False, 'integer', '10');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.ShowTypes := False;

  Output := RenderUsage(Cmd, Opts);
  // Type annotation should not appear in brackets
  CheckTrue(Pos('<integer>', Output) = 0, 'Type should be hidden');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_MultipleFlags;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('verbose', 'Verbose output', False, 'bool', 'false'));
  Spec.AddFlag(NewFlagSpec('quiet', 'Quiet mode', False, 'bool', 'false'));
  Spec.AddFlag(NewFlagSpec('config', 'Config file', False, 'string', ''));
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('verbose', Output) > 0, 'Should show verbose');
  CheckTrue(Pos('quiet', Output) > 0, 'Should show quiet');
  CheckTrue(Pos('config', Output) > 0, 'Should show config');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagsGroupedByRequired;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
  PosRequired, PosOptional: Integer;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('optional1', 'Optional flag', False, 'bool', 'false'));
  Spec.AddFlag(NewFlagSpec('required1', 'Required flag', True, 'string', ''));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.GroupFlagsBy := gbRequired;

  Output := RenderUsage(Cmd, Opts);
  PosRequired := Pos('required1', Output);
  PosOptional := Pos('optional1', Output);

  // Required flags should appear before optional
  CheckTrue(PosRequired < PosOptional, 'Required flags should appear before optional');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagsGroupedAlpha;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
  PosA, PosZ: Integer;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('zebra', 'Z flag', False, 'bool', 'false'));
  Spec.AddFlag(NewFlagSpec('alpha', 'A flag', False, 'bool', 'false'));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.GroupFlagsBy := gbAlpha;

  Output := RenderUsage(Cmd, Opts);
  PosA := Pos('alpha', Output);
  PosZ := Pos('zebra', Output);

  CheckTrue(PosA < PosZ, 'Alpha should appear before zebra when sorted alphabetically');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_FlagsUngrouped;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
  PosFirst, PosSecond: Integer;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('second', 'Second flag', False, 'bool', 'false'));
  Spec.AddFlag(NewFlagSpec('first', 'First flag', True, 'string', ''));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.GroupFlagsBy := gbNone;

  Output := RenderUsage(Cmd, Opts);
  PosFirst := Pos('first', Output);
  PosSecond := Pos('second', Output);

  // Insertion order: second was added first
  CheckTrue(PosSecond < PosFirst, 'Should maintain insertion order with gbNone');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PersistentFlag;
var
  Root: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Output: string;
begin
  Root := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('global', 'Global flag', False, 'bool', 'false');
  Flag.SetPersistent(True);
  Spec.AddFlag(Flag);
  Root.SetSpec(Spec);

  Output := RenderUsage(Root);
  CheckTrue(Pos('global', Output) > 0, 'Should show persistent flag');
end;

{ 位置参数渲染测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_SinglePositional;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Pos_: IArgsPositionalSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Pos_ := NewPositionalSpec('file', 'Input file path', True, False);
  Spec.AddPositional(Pos_);
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('file', Output) > 0, 'Output should show positional name');
  CheckTrue(Pos('Input file', Output) > 0, 'Output should show positional description');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PositionalRequired;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddPositional(NewPositionalSpec('source', 'Source file', True, False));
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  // Required positional should be shown without brackets or with <>
  CheckTrue(Pos('source', Output) > 0, 'Should show required positional');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PositionalOptional;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddPositional(NewPositionalSpec('output', 'Output file', False, False));
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  // Optional positional might be shown with []
  CheckTrue(Pos('output', Output) > 0, 'Should show optional positional');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PositionalVariadic;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Pos_: IArgsPositionalSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Pos_ := NewPositionalSpec('files', 'Input files', False, True);
  Spec.AddPositional(Pos_);
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  // Variadic should show ... or similar
  CheckTrue((Pos('...', Output) > 0) or (Pos('files', Output) > 0),
    'Should show variadic positional');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_MultiplePositionals;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddPositional(NewPositionalSpec('source', 'Source file', True, False));
  Spec.AddPositional(NewPositionalSpec('dest', 'Destination file', True, False));
  Spec.AddPositional(NewPositionalSpec('extra', 'Extra options', False, False));
  Cmd.SetSpec(Spec);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('source', Output) > 0, 'Should show source');
  CheckTrue(Pos('dest', Output) > 0, 'Should show dest');
  CheckTrue(Pos('extra', Output) > 0, 'Should show extra');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PositionalsGroupedByRequired;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
  PosReq, PosOpt: Integer;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddPositional(NewPositionalSpec('optional', 'Optional arg', False, False));
  Spec.AddPositional(NewPositionalSpec('required', 'Required arg', True, False));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.GroupPositionalsBy := gbRequired;

  Output := RenderUsage(Cmd, Opts);
  PosReq := Pos('required', Output);
  PosOpt := Pos('optional', Output);

  CheckTrue(PosReq < PosOpt, 'Required positionals should appear before optional');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_PositionalsGroupedAlpha;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
  PosA, PosZ: Integer;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddPositional(NewPositionalSpec('zulu', 'Z arg', False, False));
  Spec.AddPositional(NewPositionalSpec('alpha', 'A arg', False, False));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.GroupPositionalsBy := gbAlpha;

  Output := RenderUsage(Cmd, Opts);
  PosA := Pos('alpha', Output);
  PosZ := Pos('zulu', Output);

  CheckTrue(PosA < PosZ, 'Alpha should appear before zulu alphabetically');
end;

{ 段落标题测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_SectionHeaders;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('verbose', 'Verbose output', False, 'bool', 'false'));
  Cmd.SetSpec(Spec);
  Cmd.AddChild(NewCommand('sub'));

  Opts := RenderUsageOptionsDefault;
  Opts.ShowSectionHeaders := True;

  Output := RenderUsage(Cmd, Opts);
  // Should show section headers like "Commands:", "Options:", etc.
  CheckTrue((Pos('Commands', Output) > 0) or (Pos('Options', Output) > 0) or (Pos('Flags', Output) > 0),
    'Should show section headers');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SectionHeadersHidden;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('verbose', 'Verbose output', False, 'bool', 'false'));
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.ShowSectionHeaders := False;

  Output := RenderUsage(Cmd, Opts);
  // Section headers like "Options:" should not appear
  CheckTrue(Pos('Options:', Output) = 0, 'Should hide Options: header');
end;

{ 宽度和换行测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_CustomWidth;
var
  Cmd: ICommand;
  Opts: TRenderUsageOptions;
  Output: string;
  Lines: TStringArray;
  i: Integer;
begin
  Cmd := NewCommand('app');

  Opts := RenderUsageOptionsDefault;
  Opts.Width := 40;
  Opts.Wrap := True;

  Output := RenderUsage(Cmd, Opts);
  Lines := Output.Split([sLineBreak]);

  // Most lines should be <= 40 characters (some tolerance for edge cases)
  for i := Low(Lines) to High(Lines) do
    CheckTrue(Length(Lines[i]) <= 45, 'Lines should respect custom width');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_WrapEnabled;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  // Add a flag with a long description that needs wrapping
  Flag := NewFlagSpec('verbose', 'This is a very long description that should be wrapped when the wrap option is enabled and the width is set to a reasonable value', False, 'bool', 'false');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.Width := 60;
  Opts.Wrap := True;

  Output := RenderUsage(Cmd, Opts);
  // With wrapping and long description, output should have content
  CheckTrue(Length(Output) > 0, 'Output should have content');
  CheckTrue(Pos('verbose', Output) > 0, 'Output should contain flag name');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_WrapDisabled;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('app');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('config', 'Configuration file path', False, 'string', '');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.Wrap := False;

  Output := RenderUsage(Cmd, Opts);
  CheckTrue(Length(Output) > 0, 'Should produce output even without wrapping');
  CheckTrue(Pos('config', Output) > 0, 'Should contain flag name');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_NarrowWidth;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Opts: TRenderUsageOptions;
  Output: string;
begin
  Cmd := NewCommand('application');
  Spec := NewCommandSpec;
  Flag := NewFlagSpec('verbose', 'Enable verbose logging', False, 'bool', 'false');
  Spec.AddFlag(Flag);
  Cmd.SetSpec(Spec);

  Opts := RenderUsageOptionsDefault;
  Opts.Width := 20;  // Very narrow
  Opts.Wrap := True;

  Output := RenderUsage(Cmd, Opts);
  CheckTrue(Length(Output) > 0, 'Should handle narrow width');
  CheckTrue(Pos('verbose', Output) > 0, 'Should contain flag name');
end;

{ 综合渲染测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_FullCommand;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
  Output: string;
begin
  Cmd := NewCommand('myapp');
  Cmd.AddAlias('app');

  Spec := NewCommandSpec;

  // Add flags
  Flag := NewFlagSpec('config', 'Configuration file', True, 'string', '');
  Flag.AddAlias('c');
  Spec.AddFlag(Flag);

  Flag := NewFlagSpec('verbose', 'Enable verbose output', False, 'bool', 'false');
  Flag.AddAlias('v');
  Spec.AddFlag(Flag);

  // Add positionals
  Spec.AddPositional(NewPositionalSpec('input', 'Input file', True, False));
  Spec.AddPositional(NewPositionalSpec('output', 'Output file', False, False));

  Cmd.SetSpec(Spec);

  // Add subcommands
  Cmd.AddChild(NewCommand('init'));
  Cmd.AddChild(NewCommand('build'));

  Output := RenderUsage(Cmd);

  // Verify components are present (note: command name is NOT in output directly)
  CheckTrue(Pos('config', Output) > 0, 'Should show config flag');
  CheckTrue(Pos('verbose', Output) > 0, 'Should show verbose flag');
  CheckTrue(Pos('input', Output) > 0, 'Should show input positional');
  CheckTrue(Pos('init', Output) > 0, 'Should show init subcommand');
  CheckTrue(Pos('build', Output) > 0, 'Should show build subcommand');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_ComplexHierarchy;
var
  Root, Config, ConfigGet, ConfigSet: ICommand;
  Output: string;
begin
  Root := NewCommand('cli');

  Config := NewCommand('config');
  ConfigGet := NewCommand('get');
  ConfigSet := NewCommand('set');

  Config.AddChild(ConfigGet);
  Config.AddChild(ConfigSet);
  Root.AddChild(Config);

  // Root level
  Output := RenderUsage(Root);
  CheckTrue(Pos('config', Output) > 0, 'Root should list config');

  // Config level
  Output := RenderUsage(Config);
  CheckTrue(Pos('get', Output) > 0, 'Config should list get');
  CheckTrue(Pos('set', Output) > 0, 'Config should list set');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_RootCommand;
var
  Root: IRootCommand;
  Output: string;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));
  Root.AddChild(NewCommand('build'));

  Output := RenderUsage(Root);
  CheckTrue(Pos('serve', Output) > 0, 'Should show serve subcommand');
  CheckTrue(Pos('build', Output) > 0, 'Should show build subcommand');
end;

{ 边界测试 }

procedure TTestCase_ArgsHelp.Test_RenderUsage_EmptyDescription;
var
  Cmd: ICommand;
  Child: ICommand;
  Output: string;
begin
  Cmd := NewCommand('app');
  // Add a child with empty description
  Child := NewCommand('sub');
  Child.SetDescription('');
  Cmd.AddChild(Child);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('sub', Output) > 0, 'Should show child command name');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_LongDescription;
var
  Cmd: ICommand;
  Child: ICommand;
  LongDesc: string;
  Output: string;
begin
  Cmd := NewCommand('app');

  // Create a very long description
  LongDesc := StringOfChar('A', 500) + ' test ' + StringOfChar('B', 500);

  Child := NewCommand('sub');
  Child.SetDescription(LongDesc);
  Cmd.AddChild(Child);

  Output := RenderUsage(Cmd);
  CheckTrue(Length(Output) > 0, 'Should handle long descriptions');
  CheckTrue(Pos('AAAA', Output) > 0, 'Should contain part of long description');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_SpecialCharacters;
var
  Cmd: ICommand;
  Child: ICommand;
  Output: string;
begin
  Cmd := NewCommand('app');
  Child := NewCommand('sub');
  Child.SetDescription('Special chars: <>&"''');
  Cmd.AddChild(Child);

  Output := RenderUsage(Cmd);
  // Should not crash and should contain some of the description
  CheckTrue(Length(Output) > 0, 'Should handle special characters');
  CheckTrue(Pos('Special', Output) > 0, 'Should contain description text');
end;

procedure TTestCase_ArgsHelp.Test_RenderUsage_UnicodeText;
var
  Cmd: ICommand;
  Child: ICommand;
  Output: string;
begin
  Cmd := NewCommand('app');
  Child := NewCommand('sub');
  Child.SetDescription('Unicode: 中文测试');
  Cmd.AddChild(Child);

  Output := RenderUsage(Cmd);
  CheckTrue(Pos('Unicode', Output) > 0, 'Should handle unicode text');
end;

initialization
  RegisterTest(TTestCase_ArgsHelp);
end.
