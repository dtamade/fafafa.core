unit Test_core_help_schema;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command, fafafa.core.args.schema, fafafa.core.args.help;

type
  { TTestCase_Core_Help_Schema }
  TTestCase_Core_Help_Schema = class(TTestCase)
  published
    procedure Test_RenderUsage_Includes_Flags_And_Args;
  end;

procedure RegisterTests;

implementation

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_Help_Schema);
end;

function H_Dummy(const A: IArgs): Integer; begin Exit(0); end;

procedure TTestCase_Core_Help_Schema.Test_RenderUsage_Includes_Flags_And_Args;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
  S: string;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('run', @H_Dummy, 'Run task');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('count', 'Number of times', True, 'int'));
  Spec.AddPositional(NewPositionalSpec('file', 'Input file', True, False));
  Cmd.SetSpec(Spec);
  Root.Register(Cmd);
  // Render usage for this command
  S := RenderUsage(Cmd);
  AssertTrue(Pos('Flags:', S)>0);
  AssertTrue(Pos('--count (required)', S)>0);
  AssertTrue(Pos('Args:', S)>0);
  AssertTrue(Pos('file (required)', S)>0);
  // Ensure descriptions appear
  AssertTrue(Pos('Number of times', S)>0);
  AssertTrue(Pos('Input file', S)>0);
end;

end.

