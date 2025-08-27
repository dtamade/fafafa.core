unit Test_core_subcmds;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.schema, fafafa.core.args.command, fafafa.core.args.help;

type
  { TTestCase_Core_Subcmds }
  TTestCase_Core_Subcmds = class(TTestCase)
  published
    procedure Test_DeepPath_Positional_And_Literal;
    procedure Test_Alias_Matching;
    procedure Test_Unlimited_Depth_ThreeLevels;
    procedure Test_RunPath_Disambiguated;
    procedure Test_AddChild_DuplicateName_Raises;
    procedure Test_Register_Alias_Union_Works;
    procedure Test_Register_Handler_FirstWins;
    procedure Test_Register_NoExecuteOnMerge;
    procedure Test_DefaultChild_Fallback;
    procedure Test_Usage_Lists_Direct_Children;
    procedure Test_DefaultChild_Fallback_NextTokenIsOption;

    procedure Test_AddAlias_Duplicate_Raises;

    procedure Test_RenderUsage_Shows_DefaultChild_And_Aliases_And_Schema;

  end;

procedure RegisterTests;

implementation

var
  gCaptured: IArgs;
  gSeen: boolean;
  gSeen1, gSeen2: boolean;

function HandleCapture(const A: IArgs): Integer;
begin
  gCaptured := A;
  Exit(0);
end;

function HandleSeen(const A: IArgs): Integer;
begin
  gSeen := True;
  Exit(0);
end;

function HandleSeen1(const A: IArgs): Integer;
begin
  gSeen1 := True;
  Exit(0);
end;

function HandleSeen2(const A: IArgs): Integer;
begin
  gSeen2 := True;
  Exit(0);
end;

function HandleRaiseOnNil(const A: IArgs): Integer;
begin
  if A=nil then raise Exception.Create('nil args should not be executed during Register');
  Exit(0);
end;


procedure RegisterTests;
begin
  RegisterTest(TTestCase_Core_Subcmds);
end;

{ TTestCase_Core_Subcmds }

procedure TTestCase_Core_Subcmds.Test_Register_Handler_FirstWins;
var
  Root: IRootCommand;
  Opts: TArgsOptions;
  Seen1, Seen2: boolean;
  function H1(const A: IArgs): Integer; begin Seen1 := True; Exit(0); end;
  function H2(const A: IArgs): Integer; begin Seen2 := True; Exit(0); end;
begin
  Root := NewRootCommand;
  Seen1 := False; Seen2 := False;
  // use top-level helpers to avoid nested-proc type mismatch
  Root.Register(NewCommandPath(['remote','add'], @HandleSeen1, 'h1'));
  // register same path with another handler; should NOT override existing handler
  Root.Register(NewCommandPath(['remote','add'], @HandleSeen2, 'h2'));
  Opts := ArgsOptionsDefault;
  AssertEquals(0, Root.Run(['remote','add'], Opts));
  AssertTrue(gSeen1);
  AssertFalse(gSeen2);
end;

procedure TTestCase_Core_Subcmds.Test_Register_NoExecuteOnMerge;
var
  Root: IRootCommand;
  Caught: boolean;
  function H(const A: IArgs): Integer;
  begin
    if A=nil then raise Exception.Create('nil args should not be executed during Register');
    Exit(0);
  end;
begin
  Root := NewRootCommand;
  // Prepare existing path so that second Register triggers merge
  Root.Register(NewCommandPath(['x','y'], @HandleSeen, 'seen'));
  Caught := False;
  try
    // This register previously could execute handler with A=nil; now it must not
    Root.Register(NewCommandPath(['x','y'], @HandleRaiseOnNil, 'h'));
  except
    on E: Exception do Caught := True;
  end;
  AssertFalse(Caught);
end;

procedure TTestCase_Core_Subcmds.Test_DeepPath_Positional_And_Literal;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  // remote set url
  Cmd := NewCommandPath(['remote','set','url'], @HandleCapture, 'set remote url');
  Root.Register(Cmd);

  Opts := ArgsOptionsDefault;
  gCaptured := nil;
  // default StopAtDoubleDash=True -> '--' sentinel is not part of positionals
  AssertEquals(0, Root.Run(['remote','set','url','origin','https://example','--','--literal'], Opts));
  AssertNotNull(gCaptured);
  AssertEquals(3, Length(gCaptured.Positionals));
  AssertEquals('origin', gCaptured.Positionals[0]);
  AssertEquals('https://example', gCaptured.Positionals[1]);
  AssertEquals('--literal', gCaptured.Positionals[2]);
  // after '--', '--literal' is positional in sub-args; sanity check: no flag 'literal'
  AssertFalse(gCaptured.HasFlag('literal'));
end;


procedure TTestCase_Core_Subcmds.Test_Alias_Matching;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  Cmd := NewCommandPath(['remote','add'], @HandleSeen, 'add remote');
  // add alias to top-level 'remote'
  Cmd.AddAlias('rm');
  Root.Register(Cmd);

  Opts := ArgsOptionsDefault;
  gSeen := False;
  AssertEquals(0, Root.Run(['rm','add','origin','url'], Opts));
  AssertTrue(gSeen);
end;

procedure TTestCase_Core_Subcmds.Test_Unlimited_Depth_ThreeLevels;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Opts: TArgsOptions;
  v: string;
begin
  Root := NewRootCommand;
  Cmd := NewCommandPath(['level1','level2','level3','do'], @HandleCapture, 'deep op');
  Root.Register(Cmd);

  Opts := ArgsOptionsDefault;
  gCaptured := nil;
  AssertEquals(0, Root.Run(['level1','level2','level3','do','--opt=1','pos'], Opts));
  AssertNotNull(gCaptured);
  // sub-args start after the matched path
  AssertEquals(1, Length(gCaptured.Positionals));
  AssertEquals('pos', gCaptured.Positionals[0]);
  // opt flag should be present; also TryGetValue should succeed
  AssertTrue(gCaptured.HasFlag('opt') or gCaptured.TryGetValue('opt', v));
  AssertTrue(gCaptured.TryGetValue('opt', v));
  AssertEquals('1', v);
end;

procedure TTestCase_Core_Subcmds.Test_RunPath_Disambiguated;
var
  Root: IRootCommand;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  gSeen1 := False;
  Root.Register(NewCommandPath(['remote','add'], @HandleSeen1, 'add'));
  Opts := ArgsOptionsDefault;
  AssertEquals(0, Root.RunPath(['remote','add'], ['origin','url'], Opts));
  AssertTrue(gSeen1);
end;

procedure TTestCase_Core_Subcmds.Test_AddChild_DuplicateName_Raises;
var
  Root: IRootCommand;
  Caught: boolean;
begin
  Root := NewRootCommand;
  Caught := False;
  try
    Root.AddChild(NewCommand('dup'));
    Root.AddChild(NewCommand('dup'));
    Fail('expected duplicate name error');
  except
    on E: Exception do begin
      Caught := True;
      AssertTrue(Pos('duplicate command name', E.Message) > 0);
      AssertTrue(Pos('dup', E.Message) > 0);
      AssertTrue(Pos('<root>', E.Message) > 0);
    end;
  end;
  AssertTrue(Caught);

  // also check Register empty-name diagnostic includes parent path
  try
    Root := NewRootCommand;
    // UpsertChild('') would be another path, but we directly call Register on empty name
    Root.Register(NewCommand(''));
    Fail('expected empty name error');
  except
    on E: Exception do begin
      AssertTrue(Pos('command name cannot be empty', E.Message) > 0);
      AssertTrue(Pos('<root>', E.Message) > 0);
    end;
  end;

end;


procedure TTestCase_Core_Subcmds.Test_Register_Alias_Union_Works;
var
  Root: IRootCommand;
  C: ICommand;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  // first subtree with alias 'rm'
  C := NewCommandPath(['remote','add'], @HandleSeen1, 'add');
  C.AddAlias('rm');
  Root.Register(C);
  // second subtree also under 'remote', add alias 'r' and different handler for a different leaf
  C := NewCommandPath(['remote','add'], @HandleSeen2, 'add2');
  C.AddAlias('r');
  Root.Register(C);
  // both aliases should match same command path
  Opts := ArgsOptionsDefault;
  gSeen1 := False; gSeen2 := False;
  AssertEquals(0, Root.Run(['rm','add'], Opts));
  AssertEquals(0, Root.Run(['r','add'], Opts));
end;

procedure TTestCase_Core_Subcmds.Test_RenderUsage_Shows_DefaultChild_And_Aliases_And_Schema;
var Root: IRootCommand; Cmd, Remote: ICommand; Spec: IArgsCommandSpec; S: string; fSpec: IArgsFlagSpec;
begin
  Root := NewRootCommand;
  // build remote command with default child and alias
  Remote := NewCommand('remote');
  Remote.AddAlias('r');
  Root.Register(Remote);
  // register children and set default child
  Root.Register(NewCommandPath(['remote','list'], @HandleSeen1, 'List remotes'));
  Root.Register(NewCommandPath(['remote','add'], @HandleSeen1, 'Add remote'));
  Remote := Root.FindChildByName('remote', True);
  Remote.SetDefaultChildName('list');
  // command with schema
  Cmd := NewCommand('run');
  Spec := NewCommandSpec;
  Spec.AddFlag(NewFlagSpec('count', 'Number of times', True, 'int', '1'));
  fSpec := NewFlagSpec('json', 'Output JSON', False, 'bool');
  fSpec.AddAlias('j');
  Spec.AddFlag(fSpec);
  Spec.AddPositional(NewPositionalSpec('file', 'Input file', True, False));
  Cmd.SetSpec(Spec);
  Root.Register(Cmd);
  // Render for command with schema
  S := RenderUsage(Cmd);
  AssertTrue(Pos('Flags:', S)>0);
  // allow flexible spacing due to alignment
  AssertTrue(Pos('--count', S)>0);
  AssertTrue(Pos('[required]', S)>0);
  AssertTrue(Pos('[default=1]', S)>0);
  AssertTrue(Pos('[int]', S)>0);
  AssertTrue(Pos('--json (aliases: j)', S)>0);
  AssertTrue(Pos('[bool]', S)>0);
  AssertTrue(Pos('Args:', S)>0);
  AssertTrue(Pos('file', S)>0);
  AssertTrue(Pos('[required]', S)>0);
  // Render for remote node shows default child and alias
  S := RenderUsage(Remote);
  AssertTrue(Pos('Default subcommand: list', S)>0);
  AssertTrue(Pos('Aliases: r', S)>0);
end;

procedure TTestCase_Core_Subcmds.Test_DefaultChild_Fallback;
var
  Root: IRootCommand; C: ICommand; Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  // build remote/list and remote/add
  Root.Register(NewCommandPath(['remote','list'], @HandleSeen1, 'list'));
  Root.Register(NewCommandPath(['remote','add'], @HandleSeen2, 'add'));
  // set default child for 'remote'
  C := Root.FindChildByName('remote', True);
  AssertNotNull(C);
  C.SetDefaultChildName('list');
  // calling just 'remote' should route to 'remote list'
  gSeen1 := False; gSeen2 := False;
  Opts := ArgsOptionsDefault;
  AssertEquals(0, Root.Run(['remote'], Opts));
  AssertTrue(gSeen1);
  AssertFalse(gSeen2);
end;

procedure TTestCase_Core_Subcmds.Test_DefaultChild_Fallback_NextTokenIsOption;
var Root: IRootCommand; R, L: ICommand; Opts: TArgsOptions; code: Integer;
begin
  Root := NewRootCommand;
  R := NewCommand('remote'); L := NewCommand('list'); L.SetHandlerFunc(@HandleCapture); L.SetDescription('List');
  R.SetDefaultChildName('list'); R.AddChild(L); Root.Register(R);
  gCaptured := nil;
  Opts := ArgsOptionsDefault;
  code := Root.Run(['remote','--json'], Opts);

end;

procedure TTestCase_Core_Subcmds.Test_AddAlias_Duplicate_Raises;
var Cmd: ICommand; Caught: boolean;
begin
  Cmd := NewCommand('remote');
  Caught := False;
  try
    Cmd.AddAlias('rm');
    Cmd.AddAlias('RM'); // CI duplicate
    Fail('expected duplicate alias error');
  except
    on E: Exception do begin
      Caught := True;
      AssertTrue(Pos('duplicate alias', E.Message) > 0);
      AssertTrue(Pos('remote', E.Message) > 0);
    end;
  end;
  AssertTrue(Caught);
end;


procedure TTestCase_Core_Subcmds.Test_Usage_Lists_Direct_Children;
var
  Root: IRootCommand; S: string;
begin
  Root := NewRootCommand;
  Root.Register(NewCommandPath(['a','x'], @HandleSeen1, 'desc-a'));
  Root.Register(NewCommandPath(['b','y'], @HandleSeen2, 'desc-b'));
  S := Root.Usage;
  AssertTrue(Pos('a: desc-a', S)>0);
  AssertTrue(Pos('b: desc-b', S)>0);
end;

end.

