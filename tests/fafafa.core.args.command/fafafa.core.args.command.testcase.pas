{$CODEPAGE UTF8}
unit fafafa.core.args.command.testcase;
{**
 * fafafa.core.args.command 单元测试
 * 覆盖子命令路由、工厂函数、处理器、别名、默认子命令等
 *}

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args,
  fafafa.core.args.command,
  fafafa.core.args.schema;

type
  TTestCase_ArgsCommand = class(TTestCase)
  published
    // Factory function tests
    procedure Test_NewRootCommand_Create;
    procedure Test_NewRootCommand_WithCapacity;
    procedure Test_NewCommand_Create;
    procedure Test_NewCommand_WithCapacity;
    procedure Test_NewCommandPath_SingleName;
    procedure Test_NewCommandPath_MultipleNames;
    procedure Test_NewCommandPath_EmptyNames;

    // ICommand basic properties tests
    procedure Test_Command_Name;
    procedure Test_Command_Description_SetGet;
    procedure Test_Command_HasHandler_Initially_False;
    procedure Test_Command_SetHandlerFunc;
    procedure Test_Command_SetHandlerMethod;

    // Alias tests
    procedure Test_Command_AddAlias_Single;
    procedure Test_Command_AddAlias_Multiple;
    procedure Test_Command_AddAlias_Empty_Raises;
    procedure Test_Command_AddAlias_Duplicate_Raises;

    // Child management tests
    procedure Test_RootCommand_AddChild;
    procedure Test_RootCommand_ChildCount;
    procedure Test_RootCommand_ChildAt;
    procedure Test_RootCommand_AddChild_EmptyName_Raises;
    procedure Test_RootCommand_AddChild_Duplicate_Raises;
    procedure Test_RootCommand_EnsureCapacity;

    // FindChild tests
    procedure Test_FindChild_ByName;
    procedure Test_FindChild_ByAlias;
    procedure Test_FindChild_CaseInsensitive;
    procedure Test_FindChild_CaseSensitive;
    procedure Test_FindChild_NotFound;
    procedure Test_FindChildByName_ExcludesAlias;

    // Register tests
    procedure Test_Register_NewChild;
    procedure Test_Register_ExistingChild_MergesAliases;
    procedure Test_Register_AdoptsDescriptionIfMissing;
    procedure Test_Register_EmptyName_Raises;

    // UpsertChild tests
    procedure Test_UpsertChild_Creates_IfMissing;
    procedure Test_UpsertChild_Returns_Existing;

    // Default subcommand tests
    procedure Test_DefaultChildName_SetGet;
    procedure Test_DefaultChild_Returns_ChildByName;
    procedure Test_DefaultChild_Returns_Nil_IfNotSet;
    procedure Test_DefaultChild_Returns_Nil_IfChildNotFound;

    // Execute tests
    procedure Test_Execute_WithHandler_ReturnsHandlerResult;
    procedure Test_Execute_WithoutHandler_Returns_CMD_OK;

    // Run routing tests
    procedure Test_Run_SingleCommand;
    procedure Test_Run_NestedCommand;
    procedure Test_Run_WithAlias;
    procedure Test_Run_NotFound_Returns_CMD_NOT_FOUND;
    procedure Test_Run_CaseInsensitive;
    procedure Test_Run_WithOptions;
    procedure Test_Run_DefaultSubcommand_Fallback;
    procedure Test_Run_DefaultSubcommand_NegativeNumber_NoFallback;
    procedure Test_Run_DefaultSubcommand_DoubleDash_NoFallback;
    procedure Test_Run_DoubleDashBeforeCommand_Returns_CMD_NOT_FOUND;

    // RunPath tests
    procedure Test_RunPath_SingleLevel;
    procedure Test_RunPath_MultiLevel;
    procedure Test_RunPath_NotFound;

    // GetBestMatchPath tests
    procedure Test_GetBestMatchPath_SingleMatch;
    procedure Test_GetBestMatchPath_NestedMatch;
    procedure Test_GetBestMatchPath_WithDefaultChild;
    procedure Test_GetBestMatchPath_NoMatch;
    procedure Test_GetBestMatchPath_DefaultChild_NegativeNumber_NoDefaultChild;
    procedure Test_GetBestMatchPath_DefaultChild_DoubleDash_NoDefaultChild;
    procedure Test_GetBestMatchPath_DoubleDashBeforeCommand_EmptyPath;

    // Schema integration tests
    procedure Test_Command_Spec_SetGet;
    procedure Test_Register_PropagatesPersistentFlags;

    // Usage generation tests
    procedure Test_Usage_ListsChildren;
    procedure Test_Usage_Empty_WhenNoChildren;

    // Edge cases
    procedure Test_Run_EmptyArgs_Returns_CMD_NOT_FOUND;
    procedure Test_Run_OnlyOptions_Returns_CMD_NOT_FOUND;
    procedure Test_Run_OptionsBeforeCommand;
  end;

var
  HandlerCallCount: Integer;
  LastHandlerArgs: IArgs;

implementation

{ Test handlers }

function SimpleHandler(const A: IArgs): Integer;
begin
  Inc(HandlerCallCount);
  LastHandlerArgs := A;
  Result := 0;
end;

function ReturnCodeHandler(const A: IArgs): Integer;
begin
  Inc(HandlerCallCount);
  Result := 42;
end;

function SubCommandHandler(const A: IArgs): Integer;
begin
  Inc(HandlerCallCount);
  Result := 100;
end;

type
  TMethodHandlerObject = class
    CallCount: Integer;
    function Handle(const A: IArgs): Integer;
  end;

function TMethodHandlerObject.Handle(const A: IArgs): Integer;
begin
  Inc(CallCount);
  Result := 99;
end;

{ Factory function tests }

procedure TTestCase_ArgsCommand.Test_NewRootCommand_Create;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  CheckNotNull(Root, 'Root command should not be nil');
  CheckEquals(0, Root.ChildCount, 'New root should have no children');
end;

procedure TTestCase_ArgsCommand.Test_NewRootCommand_WithCapacity;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand(32);
  CheckNotNull(Root, 'Root command should not be nil');
  // Capacity is internal, just verify creation succeeds
end;

procedure TTestCase_ArgsCommand.Test_NewCommand_Create;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('test');
  CheckNotNull(Cmd, 'Command should not be nil');
  CheckEquals('test', Cmd.Name, 'Name should match');
  CheckEquals('', Cmd.Description, 'Description should be empty initially');
  CheckFalse(Cmd.HasHandler, 'Should not have handler initially');
end;

procedure TTestCase_ArgsCommand.Test_NewCommand_WithCapacity;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('test', 16);
  CheckNotNull(Cmd, 'Command should not be nil');
  CheckEquals('test', Cmd.Name);
end;

procedure TTestCase_ArgsCommand.Test_NewCommandPath_SingleName;
var
  Cmd: ICommand;
begin
  Cmd := NewCommandPath(['serve'], @SimpleHandler, 'Serve command');
  CheckNotNull(Cmd, 'Command should not be nil');
  CheckEquals('serve', Cmd.Name);
  CheckEquals('Serve command', Cmd.Description);
  CheckTrue(Cmd.HasHandler, 'Should have handler');
end;

procedure TTestCase_ArgsCommand.Test_NewCommandPath_MultipleNames;
var
  Cmd, Child, Grandchild: ICommand;
begin
  Cmd := NewCommandPath(['git', 'remote', 'add'], @SimpleHandler, 'Add remote');
  CheckEquals('git', Cmd.Name);
  CheckEquals(1, Cmd.ChildCount, 'git should have 1 child (remote)');

  Child := Cmd.ChildAt(0);
  CheckEquals('remote', Child.Name);
  CheckEquals(1, Child.ChildCount, 'remote should have 1 child (add)');

  Grandchild := Child.ChildAt(0);
  CheckEquals('add', Grandchild.Name);
  CheckTrue(Grandchild.HasHandler, 'Leaf node should have handler');
  CheckEquals('Add remote', Grandchild.Description);
end;

procedure TTestCase_ArgsCommand.Test_NewCommandPath_EmptyNames;
var
  Cmd: ICommand;
begin
  Cmd := NewCommandPath([], @SimpleHandler, 'Test');
  CheckNull(Cmd, 'Empty names should return nil');
end;

{ ICommand basic properties tests }

procedure TTestCase_ArgsCommand.Test_Command_Name;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('my-command');
  CheckEquals('my-command', Cmd.Name);
end;

procedure TTestCase_ArgsCommand.Test_Command_Description_SetGet;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('test');
  CheckEquals('', Cmd.Description, 'Initially empty');
  Cmd.SetDescription('Test description');
  CheckEquals('Test description', Cmd.Description);
end;

procedure TTestCase_ArgsCommand.Test_Command_HasHandler_Initially_False;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('test');
  CheckFalse(Cmd.HasHandler);
end;

procedure TTestCase_ArgsCommand.Test_Command_SetHandlerFunc;
var
  Cmd: ICommand;
begin
  Cmd := NewCommand('test');
  Cmd.SetHandlerFunc(@SimpleHandler);
  CheckTrue(Cmd.HasHandler, 'Should have handler after SetHandlerFunc');
end;

procedure TTestCase_ArgsCommand.Test_Command_SetHandlerMethod;
var
  Cmd: ICommand;
  Obj: TMethodHandlerObject;
begin
  Cmd := NewCommand('test');
  Obj := TMethodHandlerObject.Create;
  try
    Cmd.SetHandlerMethod(@Obj.Handle);
    CheckTrue(Cmd.HasHandler, 'Should have handler after SetHandlerMethod');
  finally
    Obj.Free;
  end;
end;

{ Alias tests }

procedure TTestCase_ArgsCommand.Test_Command_AddAlias_Single;
var
  Cmd: ICommand;
  Aliases: array of string;
begin
  Cmd := NewCommand('serve');
  Cmd.AddAlias('s');
  Aliases := Cmd.Aliases;
  CheckEquals(1, Length(Aliases), 'Should have 1 alias');
  CheckEquals('s', Aliases[0]);
end;

procedure TTestCase_ArgsCommand.Test_Command_AddAlias_Multiple;
var
  Cmd: ICommand;
  Aliases: array of string;
begin
  Cmd := NewCommand('install');
  Cmd.AddAlias('i');
  Cmd.AddAlias('add');
  Aliases := Cmd.Aliases;
  CheckEquals(2, Length(Aliases), 'Should have 2 aliases');
  CheckEquals('i', Aliases[0]);
  CheckEquals('add', Aliases[1]);
end;

procedure TTestCase_ArgsCommand.Test_Command_AddAlias_Empty_Raises;
var
  Cmd: ICommand;
  Raised: Boolean;
begin
  Cmd := NewCommand('test');
  Raised := False;
  try
    Cmd.AddAlias('');
  except
    on E: EArgumentException do
      Raised := True;
  end;
  CheckTrue(Raised, 'Empty alias should raise EArgumentException');
end;

procedure TTestCase_ArgsCommand.Test_Command_AddAlias_Duplicate_Raises;
var
  Cmd: ICommand;
  Raised: Boolean;
begin
  Cmd := NewCommand('test');
  Cmd.AddAlias('t');
  Raised := False;
  try
    Cmd.AddAlias('T'); // CI duplicate
  except
    on E: EArgumentException do
      Raised := True;
  end;
  CheckTrue(Raised, 'Duplicate alias (CI) should raise EArgumentException');
end;

{ Child management tests }

procedure TTestCase_ArgsCommand.Test_RootCommand_AddChild;
var
  Root: IRootCommand;
  Child: ICommand;
begin
  Root := NewRootCommand;
  Child := NewCommand('child');
  Root.AddChild(Child);
  CheckEquals(1, Root.ChildCount);
end;

procedure TTestCase_ArgsCommand.Test_RootCommand_ChildCount;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  CheckEquals(0, Root.ChildCount);
  Root.AddChild(NewCommand('a'));
  CheckEquals(1, Root.ChildCount);
  Root.AddChild(NewCommand('b'));
  CheckEquals(2, Root.ChildCount);
end;

procedure TTestCase_ArgsCommand.Test_RootCommand_ChildAt;
var
  Root: IRootCommand;
  Child: ICommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('first'));
  Root.AddChild(NewCommand('second'));

  Child := Root.ChildAt(0);
  CheckEquals('first', Child.Name);

  Child := Root.ChildAt(1);
  CheckEquals('second', Child.Name);
end;

procedure TTestCase_ArgsCommand.Test_RootCommand_AddChild_EmptyName_Raises;
var
  Root: IRootCommand;
  Raised: Boolean;
begin
  Root := NewRootCommand;
  Raised := False;
  try
    Root.AddChild(NewCommand(''));
  except
    on E: EArgumentException do
      Raised := True;
  end;
  CheckTrue(Raised, 'Empty command name should raise EArgumentException');
end;

procedure TTestCase_ArgsCommand.Test_RootCommand_AddChild_Duplicate_Raises;
var
  Root: IRootCommand;
  Raised: Boolean;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));
  Raised := False;
  try
    Root.AddChild(NewCommand('TEST')); // CI duplicate
  except
    on E: EArgumentException do
      Raised := True;
  end;
  CheckTrue(Raised, 'Duplicate command name (CI) should raise EArgumentException');
end;

procedure TTestCase_ArgsCommand.Test_RootCommand_EnsureCapacity;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand(0);
  Root.EnsureCapacity(100);
  // Just verify it doesn't crash - capacity is internal
  CheckEquals(0, Root.ChildCount, 'Should still have 0 children');
end;

{ FindChild tests }

procedure TTestCase_ArgsCommand.Test_FindChild_ByName;
var
  Root: IRootCommand;
  Found: ICommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));
  Root.AddChild(NewCommand('build'));

  Found := Root.FindChild('serve', False);
  CheckNotNull(Found, 'Should find by exact name');
  CheckEquals('serve', Found.Name);
end;

procedure TTestCase_ArgsCommand.Test_FindChild_ByAlias;
var
  Root: IRootCommand;
  Cmd, Found: ICommand;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.AddAlias('s');
  Root.AddChild(Cmd);

  Found := Root.FindChild('s', False);
  CheckNotNull(Found, 'Should find by alias');
  CheckEquals('serve', Found.Name);
end;

procedure TTestCase_ArgsCommand.Test_FindChild_CaseInsensitive;
var
  Root: IRootCommand;
  Found: ICommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('Serve'));

  Found := Root.FindChild('SERVE', True);
  CheckNotNull(Found, 'Should find case-insensitively');
  CheckEquals('Serve', Found.Name);
end;

procedure TTestCase_ArgsCommand.Test_FindChild_CaseSensitive;
var
  Root: IRootCommand;
  Found: ICommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('Serve'));

  Found := Root.FindChild('SERVE', False);
  CheckNull(Found, 'Should not find with wrong case when case-sensitive');

  Found := Root.FindChild('Serve', False);
  CheckNotNull(Found, 'Should find with exact case');
end;

procedure TTestCase_ArgsCommand.Test_FindChild_NotFound;
var
  Root: IRootCommand;
  Found: ICommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));

  Found := Root.FindChild('nonexistent', True);
  CheckNull(Found, 'Should return nil for nonexistent command');
end;

procedure TTestCase_ArgsCommand.Test_FindChildByName_ExcludesAlias;
var
  Root: IRootCommand;
  Cmd, Found: ICommand;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.AddAlias('s');
  Root.AddChild(Cmd);

  // FindChildByName should NOT match alias
  Found := Root.FindChildByName('s', True);
  CheckNull(Found, 'FindChildByName should not match alias');

  Found := Root.FindChildByName('serve', True);
  CheckNotNull(Found, 'FindChildByName should match name');
end;

{ Register tests }

procedure TTestCase_ArgsCommand.Test_Register_NewChild;
var
  Root: IRootCommand;
  Cmd, Result: ICommand;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('test');
  Cmd.SetDescription('Test command');

  Result := Root.Register(Cmd);
  CheckEquals(1, Root.ChildCount);
  CheckEquals('test', Result.Name);
end;

procedure TTestCase_ArgsCommand.Test_Register_ExistingChild_MergesAliases;
var
  Root: IRootCommand;
  Cmd1, Cmd2, Found: ICommand;
  Aliases: array of string;
begin
  Root := NewRootCommand;

  Cmd1 := NewCommand('serve');
  Cmd1.AddAlias('s');
  Root.AddChild(Cmd1);

  Cmd2 := NewCommand('serve');
  Cmd2.AddAlias('srv');
  Root.Register(Cmd2);

  Found := Root.FindChildByName('serve', True);
  Aliases := Found.Aliases;
  CheckEquals(2, Length(Aliases), 'Should have merged aliases');
end;

procedure TTestCase_ArgsCommand.Test_Register_AdoptsDescriptionIfMissing;
var
  Root: IRootCommand;
  Existing, NewCmd, Found: ICommand;
begin
  Root := NewRootCommand;

  Existing := NewCommand('test');
  // No handler, no description
  Root.AddChild(Existing);

  NewCmd := NewCommand('test');
  NewCmd.SetHandlerFunc(@SimpleHandler);
  NewCmd.SetDescription('New description');
  Root.Register(NewCmd);

  Found := Root.FindChildByName('test', True);
  CheckEquals('New description', Found.Description, 'Should adopt description from registered cmd with handler');
end;

procedure TTestCase_ArgsCommand.Test_Register_EmptyName_Raises;
var
  Root: IRootCommand;
  Raised: Boolean;
begin
  Root := NewRootCommand;
  Raised := False;
  try
    Root.Register(NewCommand(''));
  except
    on E: EArgumentException do
      Raised := True;
  end;
  CheckTrue(Raised, 'Register with empty name should raise');
end;

{ UpsertChild tests }

procedure TTestCase_ArgsCommand.Test_UpsertChild_Creates_IfMissing;
var
  Root: IRootCommand;
  Child: ICommand;
begin
  Root := NewRootCommand;
  CheckEquals(0, Root.ChildCount);

  Child := Root.UpsertChild('newcmd');
  CheckNotNull(Child, 'Should create new child');
  CheckEquals('newcmd', Child.Name);
  CheckEquals(1, Root.ChildCount);
end;

procedure TTestCase_ArgsCommand.Test_UpsertChild_Returns_Existing;
var
  Root: IRootCommand;
  Existing, Upserted: ICommand;
begin
  Root := NewRootCommand;

  Existing := NewCommand('cmd');
  Existing.SetDescription('Original');
  Root.AddChild(Existing);

  Upserted := Root.UpsertChild('CMD'); // CI match
  CheckEquals('Original', Upserted.Description, 'Should return existing child');
  CheckEquals(1, Root.ChildCount, 'Should not create duplicate');
end;

{ Default subcommand tests }

procedure TTestCase_ArgsCommand.Test_DefaultChildName_SetGet;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  CheckEquals('', Root.DefaultChildName, 'Initially empty');
  Root.SetDefaultChildName('help');
  CheckEquals('help', Root.DefaultChildName);
end;

procedure TTestCase_ArgsCommand.Test_DefaultChild_Returns_ChildByName;
var
  Root: IRootCommand;
  HelpCmd, Default: ICommand;
begin
  Root := NewRootCommand;

  HelpCmd := NewCommand('help');
  HelpCmd.SetDescription('Show help');
  Root.AddChild(HelpCmd);

  Root.SetDefaultChildName('help');
  Default := Root.DefaultChild;
  CheckNotNull(Default, 'Should find default child');
  CheckEquals('help', Default.Name);
end;

procedure TTestCase_ArgsCommand.Test_DefaultChild_Returns_Nil_IfNotSet;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));
  CheckNull(Root.DefaultChild, 'Should be nil when default not set');
end;

procedure TTestCase_ArgsCommand.Test_DefaultChild_Returns_Nil_IfChildNotFound;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));
  Root.SetDefaultChildName('nonexistent');
  CheckNull(Root.DefaultChild, 'Should be nil when default child not found');
end;

{ Execute tests }

procedure TTestCase_ArgsCommand.Test_Execute_WithHandler_ReturnsHandlerResult;
var
  Cmd: ICommand;
  Args: IArgs;
  Code: Integer;
begin
  Cmd := NewCommand('test');
  Cmd.SetHandlerFunc(@ReturnCodeHandler);

  HandlerCallCount := 0;
  Args := TArgs.FromArray([], ArgsOptionsDefault);
  Code := Cmd.Execute(Args);

  CheckEquals(42, Code, 'Should return handler result');
  CheckEquals(1, HandlerCallCount, 'Handler should be called once');
end;

procedure TTestCase_ArgsCommand.Test_Execute_WithoutHandler_Returns_CMD_OK;
var
  Cmd: ICommand;
  Args: IArgs;
  Code: Integer;
begin
  Cmd := NewCommand('test');
  Args := TArgs.FromArray([], ArgsOptionsDefault);
  Code := Cmd.Execute(Args);
  CheckEquals(CMD_OK, Code, 'Should return CMD_OK when no handler');
end;

{ Run routing tests }

procedure TTestCase_ArgsCommand.Test_Run_SingleCommand;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  HandlerCallCount := 0;
  Code := Root.Run(['serve'], ArgsOptionsDefault);

  CheckEquals(0, Code, 'Should return handler result');
  CheckEquals(1, HandlerCallCount, 'Handler should be called');
end;

procedure TTestCase_ArgsCommand.Test_Run_NestedCommand;
var
  Root: IRootCommand;
  GitCmd, RemoteCmd, AddCmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;

  GitCmd := NewCommand('git');
  RemoteCmd := NewCommand('remote');
  AddCmd := NewCommand('add');
  AddCmd.SetHandlerFunc(@SubCommandHandler);

  RemoteCmd.AddChild(AddCmd);
  GitCmd.AddChild(RemoteCmd);
  Root.AddChild(GitCmd);

  HandlerCallCount := 0;
  Code := Root.Run(['git', 'remote', 'add', 'origin', 'https://...'], ArgsOptionsDefault);

  CheckEquals(100, Code, 'Should return SubCommandHandler result');
  CheckEquals(1, HandlerCallCount, 'Handler should be called');
end;

procedure TTestCase_ArgsCommand.Test_Run_WithAlias;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('install');
  Cmd.AddAlias('i');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  HandlerCallCount := 0;
  Code := Root.Run(['i'], ArgsOptionsDefault);

  CheckEquals(0, Code);
  CheckEquals(1, HandlerCallCount, 'Handler should be called via alias');
end;

procedure TTestCase_ArgsCommand.Test_Run_NotFound_Returns_CMD_NOT_FOUND;
var
  Root: IRootCommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));

  Code := Root.Run(['nonexistent'], ArgsOptionsDefault);
  CheckEquals(CMD_NOT_FOUND, Code);
end;

procedure TTestCase_ArgsCommand.Test_Run_CaseInsensitive;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Opts: TArgsOptions;
  Code: Integer;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('Serve');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  Opts := ArgsOptionsDefault;
  Opts.CaseInsensitiveKeys := True;

  HandlerCallCount := 0;
  Code := Root.Run(['SERVE'], Opts);

  CheckEquals(0, Code);
  CheckEquals(1, HandlerCallCount, 'Should match case-insensitively');
end;

procedure TTestCase_ArgsCommand.Test_Run_WithOptions;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
  PortValue: string;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  HandlerCallCount := 0;
  LastHandlerArgs := nil;
  Code := Root.Run(['serve', '--port=8080', '--verbose'], ArgsOptionsDefault);

  CheckEquals(0, Code);
  CheckEquals(1, HandlerCallCount);
  CheckNotNull(LastHandlerArgs, 'Handler should receive args');
  CheckTrue(LastHandlerArgs.TryGetValue('port', PortValue), 'Should parse port option');
  CheckEquals('8080', PortValue, 'Port value should be 8080');
end;

procedure TTestCase_ArgsCommand.Test_Run_DefaultSubcommand_Fallback;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;

  ServeCmd := NewCommand('serve');
  DevCmd := NewCommand('dev');
  DevCmd.SetHandlerFunc(@SubCommandHandler);
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');

  Root.AddChild(ServeCmd);

  HandlerCallCount := 0;
  // Run 'serve' without subcommand - should fall back to 'dev'
  Code := Root.Run(['serve'], ArgsOptionsDefault);

  CheckEquals(100, Code, 'Should fall back to default subcommand');
  CheckEquals(1, HandlerCallCount);
end;

procedure TTestCase_ArgsCommand.Test_Run_DefaultSubcommand_NegativeNumber_NoFallback;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Code: Integer;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;

  ServeCmd := NewCommand('serve');
  ServeCmd.SetHandlerFunc(@SimpleHandler);

  DevCmd := NewCommand('dev');
  DevCmd.SetHandlerFunc(@SubCommandHandler);
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');

  Root.AddChild(ServeCmd);

  Opts := ArgsOptionsDefault;
  Opts.TreatNegativeNumbersAsPositionals := True;

  HandlerCallCount := 0;
  Code := Root.Run(['serve', '-1.2'], Opts);

  CheckEquals(0, Code, 'Negative number should be positional for routing (no default fallback)');
  CheckEquals(1, HandlerCallCount);
end;

procedure TTestCase_ArgsCommand.Test_Run_DefaultSubcommand_DoubleDash_NoFallback;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Code: Integer;
  Opts: TArgsOptions;
  Pos: TStringArray;
begin
  Root := NewRootCommand;

  ServeCmd := NewCommand('serve');
  ServeCmd.SetHandlerFunc(@SimpleHandler);

  DevCmd := NewCommand('dev');
  DevCmd.SetHandlerFunc(@SubCommandHandler);
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');

  Root.AddChild(ServeCmd);

  Opts := ArgsOptionsDefault;
  Opts.StopAtDoubleDash := True;

  HandlerCallCount := 0;
  LastHandlerArgs := nil;
  Code := Root.Run(['serve', '--', '-notAnOption'], Opts);

  CheckEquals(0, Code, '"--" should stop routing and NOT trigger default-child fallback');
  CheckEquals(1, HandlerCallCount);
  CheckNotNull(LastHandlerArgs, 'Handler should receive args');

  Pos := LastHandlerArgs.Positionals;
  CheckEquals(1, Length(Pos));
  CheckEquals('-notAnOption', Pos[0]);
end;

procedure TTestCase_ArgsCommand.Test_Run_DoubleDashBeforeCommand_Returns_CMD_NOT_FOUND;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  Opts := ArgsOptionsDefault;
  Opts.StopAtDoubleDash := True;

  HandlerCallCount := 0;
  Code := Root.Run(['--', 'serve'], Opts);

  CheckEquals(CMD_NOT_FOUND, Code, 'StopAtDoubleDash=True: routing must stop at "--"');
  CheckEquals(0, HandlerCallCount, 'Handler must not be called');
end;

{ RunPath tests }

procedure TTestCase_ArgsCommand.Test_RunPath_SingleLevel;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('test');
  Cmd.SetHandlerFunc(@ReturnCodeHandler);
  Root.AddChild(Cmd);

  HandlerCallCount := 0;
  Code := Root.RunPath(['test'], ['--flag'], ArgsOptionsDefault);

  CheckEquals(42, Code);
  CheckEquals(1, HandlerCallCount);
end;

procedure TTestCase_ArgsCommand.Test_RunPath_MultiLevel;
var
  Root: IRootCommand;
  Parent, Child: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Parent := NewCommand('parent');
  Child := NewCommand('child');
  Child.SetHandlerFunc(@SubCommandHandler);
  Parent.AddChild(Child);
  Root.AddChild(Parent);

  HandlerCallCount := 0;
  Code := Root.RunPath(['parent', 'child'], ['arg1', 'arg2'], ArgsOptionsDefault);

  CheckEquals(100, Code);
  CheckEquals(1, HandlerCallCount);
end;

procedure TTestCase_ArgsCommand.Test_RunPath_NotFound;
var
  Root: IRootCommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));

  Code := Root.RunPath(['nonexistent'], [], ArgsOptionsDefault);
  CheckEquals(CMD_NOT_FOUND, Code);
end;

{ GetBestMatchPath tests }

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_SingleMatch;
var
  Root: IRootCommand;
  Path: array of string;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));

  Path := GetBestMatchPath(Root, ['serve', '--port=8080'], ArgsOptionsDefault);
  CheckEquals(1, Length(Path));
  CheckEquals('serve', Path[0]);
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_NestedMatch;
var
  Root: IRootCommand;
  GitCmd, RemoteCmd: ICommand;
  Path: array of string;
begin
  Root := NewRootCommand;
  GitCmd := NewCommand('git');
  RemoteCmd := NewCommand('remote');
  GitCmd.AddChild(RemoteCmd);
  Root.AddChild(GitCmd);

  Path := GetBestMatchPath(Root, ['git', 'remote', 'origin'], ArgsOptionsDefault);
  CheckEquals(2, Length(Path));
  CheckEquals('git', Path[0]);
  CheckEquals('remote', Path[1]);
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_WithDefaultChild;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Path: array of string;
begin
  Root := NewRootCommand;
  ServeCmd := NewCommand('serve');
  DevCmd := NewCommand('dev');
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');
  Root.AddChild(ServeCmd);

  // When 'serve' is followed by option, default child should be included
  Path := GetBestMatchPath(Root, ['serve', '--port=8080'], ArgsOptionsDefault);
  CheckEquals(2, Length(Path), 'Should include default child');
  CheckEquals('serve', Path[0]);
  CheckEquals('dev', Path[1]);
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_NoMatch;
var
  Root: IRootCommand;
  Path: array of string;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));

  Path := GetBestMatchPath(Root, ['nonexistent'], ArgsOptionsDefault);
  CheckEquals(0, Length(Path), 'Should return empty path for no match');
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_DefaultChild_NegativeNumber_NoDefaultChild;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Path: array of string;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;

  ServeCmd := NewCommand('serve');
  DevCmd := NewCommand('dev');
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');
  Root.AddChild(ServeCmd);

  Opts := ArgsOptionsDefault;
  Opts.TreatNegativeNumbersAsPositionals := True;

  Path := GetBestMatchPath(Root, ['serve', '-1.2'], Opts);
  CheckEquals(1, Length(Path), 'Negative number should not trigger default child');
  CheckEquals('serve', Path[0]);
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_DefaultChild_DoubleDash_NoDefaultChild;
var
  Root: IRootCommand;
  ServeCmd, DevCmd: ICommand;
  Path: array of string;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;

  ServeCmd := NewCommand('serve');
  DevCmd := NewCommand('dev');
  ServeCmd.AddChild(DevCmd);
  ServeCmd.SetDefaultChildName('dev');
  Root.AddChild(ServeCmd);

  Opts := ArgsOptionsDefault;
  Opts.StopAtDoubleDash := True;

  Path := GetBestMatchPath(Root, ['serve', '--', 'dev'], Opts);
  CheckEquals(1, Length(Path), '"--" should not trigger default child');
  CheckEquals('serve', Path[0]);
end;

procedure TTestCase_ArgsCommand.Test_GetBestMatchPath_DoubleDashBeforeCommand_EmptyPath;
var
  Root: IRootCommand;
  Path: array of string;
  Opts: TArgsOptions;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('serve'));

  Opts := ArgsOptionsDefault;
  Opts.StopAtDoubleDash := True;

  Path := GetBestMatchPath(Root, ['--', 'serve'], Opts);
  CheckEquals(0, Length(Path), 'StopAtDoubleDash=True: routing must stop at "--"');
end;

{ Schema integration tests }

procedure TTestCase_ArgsCommand.Test_Command_Spec_SetGet;
var
  Cmd: ICommand;
  Spec: IArgsCommandSpec;
begin
  Cmd := NewCommand('test');
  CheckNull(Cmd.GetSpec, 'Initially nil');

  Spec := NewCommandSpec;
  Spec.SetDescription('Test spec');
  Cmd.SetSpec(Spec);

  CheckNotNull(Cmd.GetSpec, 'Should have spec');
  CheckEquals('Test spec', Cmd.GetSpec.Description);
end;

procedure TTestCase_ArgsCommand.Test_Register_PropagatesPersistentFlags;
var
  Root: IRootCommand;
  Parent, Child, Parent2, Found: ICommand;
  ParentSpec, ChildSpec: IArgsCommandSpec;
  Flag: IArgsFlagSpec;
begin
  Root := NewRootCommand;

  // First, add an empty parent with a child (no spec)
  Parent := NewCommand('parent');
  Child := NewCommand('child');
  Child.SetHandlerFunc(@SimpleHandler);
  Parent.AddChild(Child);
  Root.AddChild(Parent);

  // Now create another parent tree with persistent flag to merge
  Parent2 := NewCommand('parent');
  ParentSpec := NewCommandSpec;
  Flag := NewFlagSpec('verbose', 'Verbose output', False, 'bool', 'false');
  Flag.SetPersistent(True);
  ParentSpec.AddFlag(Flag);
  Parent2.SetSpec(ParentSpec);

  // Add child with handler to the second parent (this triggers description adoption)
  Child := NewCommand('child');
  Child.SetHandlerFunc(@SimpleHandler);
  Parent2.AddChild(Child);

  // Register to merge - this should propagate persistent flags
  Root.Register(Parent2);

  // After merge, child should have inherited persistent flag
  Found := Root.FindChild('parent', True);
  CheckNotNull(Found, 'Should find parent');

  Found := Found.FindChild('child', True);
  CheckNotNull(Found, 'Should find child');

  ChildSpec := Found.GetSpec;
  CheckNotNull(ChildSpec, 'Child should have spec after merge with persistent flags');
  CheckEquals(1, ChildSpec.FlagCount, 'Child should inherit persistent flag');
  CheckEquals('verbose', ChildSpec.FlagAt(0).Name);
end;

{ Usage generation tests }

procedure TTestCase_ArgsCommand.Test_Usage_ListsChildren;
var
  Root: IRootCommand;
  Cmd: ICommand;
  UsageStr: string;
begin
  Root := NewRootCommand;

  Cmd := NewCommand('serve');
  Cmd.SetDescription('Start the server');
  Root.AddChild(Cmd);

  Cmd := NewCommand('build');
  Cmd.SetDescription('Build the project');
  Root.AddChild(Cmd);

  UsageStr := Root.Usage;
  CheckTrue(Pos('serve', UsageStr) > 0, 'Usage should list serve');
  CheckTrue(Pos('build', UsageStr) > 0, 'Usage should list build');
  CheckTrue(Pos('Start the server', UsageStr) > 0, 'Usage should include description');
end;

procedure TTestCase_ArgsCommand.Test_Usage_Empty_WhenNoChildren;
var
  Root: IRootCommand;
begin
  Root := NewRootCommand;
  CheckEquals('', Root.Usage, 'Usage should be empty with no children');
end;

{ Edge cases }

procedure TTestCase_ArgsCommand.Test_Run_EmptyArgs_Returns_CMD_NOT_FOUND;
var
  Root: IRootCommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));

  Code := Root.Run([], ArgsOptionsDefault);
  CheckEquals(CMD_NOT_FOUND, Code);
end;

procedure TTestCase_ArgsCommand.Test_Run_OnlyOptions_Returns_CMD_NOT_FOUND;
var
  Root: IRootCommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Root.AddChild(NewCommand('test'));

  Code := Root.Run(['--help', '-v'], ArgsOptionsDefault);
  CheckEquals(CMD_NOT_FOUND, Code, 'Only options without command should return NOT_FOUND');
end;

procedure TTestCase_ArgsCommand.Test_Run_OptionsBeforeCommand;
var
  Root: IRootCommand;
  Cmd: ICommand;
  Code: Integer;
begin
  Root := NewRootCommand;
  Cmd := NewCommand('serve');
  Cmd.SetHandlerFunc(@SimpleHandler);
  Root.AddChild(Cmd);

  HandlerCallCount := 0;
  // Options before command - the routing scans for first non-option
  Code := Root.Run(['--verbose', 'serve', '--port=8080'], ArgsOptionsDefault);

  // Current implementation: first non-option is 'serve'
  CheckEquals(0, Code);
  CheckEquals(1, HandlerCallCount);
end;

initialization
  RegisterTest(TTestCase_ArgsCommand);
end.
