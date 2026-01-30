program example_help_schema;

{$mode objfpc}{$H+}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.schema,
  fafafa.core.args.help;

function H_Run(const A: IArgs): Integer;
begin
  // reference A to avoid unused-parameter hint
  if A=nil then ;
  Writeln('run executed');
  Exit(0);
end;

var
  Root: IRootCommand;
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  opts: TArgsOptions;
  ropts: TRenderUsageOptions;
  i: Integer; s: string;
  usage: string;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('run');
  Cmd.SetHandlerFunc(@H_Run);
  Cmd.SetDescription('Run a task');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('count', 'Number of times', True, 'int', '1'));
  Spec.AddFlag(NewFlagSpec('json', 'Output JSON', False, 'bool'));
  Spec.AddPositional(NewPositionalSpec('file', 'Input file path', True, False));
  Cmd.SetSpec(Spec);

  // Optional: map simple CLI flags to RenderUsage options
  // Supported: --nowrap, --no-sort, --no-default-mark, --no-aliases, --no-types, --width=N
  ropts := RenderUsageOptionsDefault;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if s='--nowrap' then ropts.wrap := False
    else if s='--no-sort' then ropts.sortSubcommands := False
    else if s='--no-default-mark' then ropts.markDefaultInChildren := False
    else if s='--no-aliases' then ropts.showAliases := False
    else if s='--no-types' then ropts.showTypes := False
    else if Pos('--width=', s)=1 then
      try ropts.width := StrToInt(Copy(s, 9, MaxInt)); except on E: Exception do ; end;
  end;

  // Render with options if any were provided; otherwise default overload
  if (ParamCount>0) then usage := RenderUsage(Cmd, ropts) else usage := RenderUsage(Cmd);
  Writeln(usage);

  // Normal dispatch as needed
  opts := ArgsOptionsDefault;
  Halt(Root.Run(opts));
end.

