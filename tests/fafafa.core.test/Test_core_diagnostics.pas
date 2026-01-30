unit Test_core_diagnostics;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}
{$I ../../src/fafafa.core.settings.inc}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command;

procedure RegisterTests;

implementation

type
  TTestCase_Core_Diagnostics = class(TTestCase)
  published
    procedure Test_GetBestMatchPath_DefaultChild_Fallback; reintroduce;
    procedure Test_GetBestMatchPath_Alias_CanonicalNames; reintroduce;
    procedure Test_GetBestMatchPath_NoDefaultChild_NoFallback; reintroduce;
    procedure Test_GetBestMatchPath_DeepPath; reintroduce;
    procedure Test_GetBestMatchPath_CaseInsensitive_On; reintroduce;
    procedure Test_GetBestMatchPath_CaseInsensitive_Off; reintroduce;
    procedure Test_GetBestMatchPath_HeadOptionOrEmpty_EmptyPath; reintroduce;
    procedure Test_GetBestMatchPath_Alias_DeepPath; reintroduce;
    procedure Test_GetBestMatchPath_MixedCase_Alias_DefaultChild; reintroduce;
    procedure Test_GetBestMatchPath_PartialLongestMatch; reintroduce;
    procedure Test_GetBestMatchPath_AliasCanonical_MixedDeepPath; reintroduce;

  end;



procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_DefaultChild_Fallback;
var Root: IRootCommand; Remote, List: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Root.Register(Remote);
  List := NewCommand('list');
  Remote.AddChild(List);
  Remote.SetDefaultChildName('list');
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['remote','--json'], Opts);
  AssertEquals(2, Length(path));
  AssertEquals('remote', path[0]);
  AssertEquals('list', path[1]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_Alias_CanonicalNames;
var Root: IRootCommand; Remote, Add: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  // remote (alias rm) -> add
  Remote := NewCommand('remote'); Remote.AddAlias('rm'); Root.Register(Remote);
  Add := NewCommand('add'); Remote.AddChild(Add);
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['rm','add','--opt'], Opts);
  AssertEquals(2, Length(path));
  // path should contain canonical names, not alias
  AssertEquals('remote', path[0]);
  AssertEquals('add', path[1]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_NoDefaultChild_NoFallback;
var Root: IRootCommand; Remote: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Root.Register(Remote);
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['remote','--json'], Opts);
  AssertEquals(1, Length(path));
  AssertEquals('remote', path[0]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_DeepPath;
var Root: IRootCommand; L1,L2,L3,DoCmd: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  L1 := NewCommand('level1'); Root.Register(L1);
  L2 := NewCommand('level2'); L1.AddChild(L2);
  L3 := NewCommand('level3'); L2.AddChild(L3);
  DoCmd := NewCommand('do'); L3.AddChild(DoCmd);
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['level1','level2','level3','do','--x'], Opts);
  AssertEquals(4, Length(path));
  AssertEquals('level1', path[0]);
  AssertEquals('level2', path[1]);
  AssertEquals('level3', path[2]);
  AssertEquals('do', path[3]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_CaseInsensitive_On;
var Root: IRootCommand; Remote, Add: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Root.Register(Remote);
  Add := NewCommand('add'); Remote.AddChild(Add);
  Opts := ArgsOptionsDefault; Opts.CaseInsensitiveKeys := True;
  path := GetBestMatchPath(Root, ['REMOTE','ADD','--X'], Opts);
  AssertEquals(2, Length(path));
  AssertEquals('remote', path[0]);
  AssertEquals('add', path[1]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_CaseInsensitive_Off;
var Root: IRootCommand; Remote, Add: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Root.Register(Remote);
  Add := NewCommand('add'); Remote.AddChild(Add);
  Opts := ArgsOptionsDefault; Opts.CaseInsensitiveKeys := False;
  path := GetBestMatchPath(Root, ['REMOTE','ADD','--X'], Opts);
  AssertEquals(0, Length(path));
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_PartialLongestMatch;
var Root: IRootCommand; Remote, Add: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Root.Register(Remote);
  Add := NewCommand('add'); // not registered under remote to force partial break
  // deliberately do not add 'add' as child
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['remote','add','--x'], Opts);
  AssertEquals(1, Length(path));

  end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_HeadOptionOrEmpty_EmptyPath;
var Root: IRootCommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['--help','remote'], Opts);
  AssertEquals(0, Length(path));
  SetLength(path, 0);
  path := GetBestMatchPath(Root, [], Opts);
  AssertEquals(0, Length(path));
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_Alias_DeepPath;
var Root: IRootCommand; Remote, SetCmd, Url: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  Remote := NewCommand('remote'); Remote.AddAlias('rm'); Root.Register(Remote);
  SetCmd := NewCommand('set'); Remote.AddChild(SetCmd);
  Url := NewCommand('url'); SetCmd.AddChild(Url);
  Opts := ArgsOptionsDefault;
  path := GetBestMatchPath(Root, ['rm','set','url','--json'], Opts);
  AssertEquals(3, Length(path));
  AssertEquals('remote', path[0]);
  AssertEquals('set', path[1]);
  AssertEquals('url', path[2]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_MixedCase_Alias_DefaultChild;
var Root: IRootCommand; Remote, SetCmd, Url, ListCmd: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  // remote (alias rm) -> set -> url; also default child 'list' under remote
  Remote := NewCommand('remote'); Remote.AddAlias('rm'); Root.Register(Remote);
  SetCmd := NewCommand('set'); Remote.AddChild(SetCmd);
  Url := NewCommand('url'); SetCmd.AddChild(Url);
  ListCmd := NewCommand('list'); Remote.AddChild(ListCmd);
  Remote.SetDefaultChildName('list');
  // CaseInsensitive ON, mixed-case tokens and alias at head, with trailing option
  Opts := ArgsOptionsDefault; Opts.CaseInsensitiveKeys := True;
  path := GetBestMatchPath(Root, ['RM','SeT','URL','--flag'], Opts);
  AssertEquals(3, Length(path));
  AssertEquals('remote', path[0]);
  AssertEquals('set', path[1]);
  AssertEquals('url', path[2]);
end;

procedure TTestCase_Core_Diagnostics.Test_GetBestMatchPath_AliasCanonical_MixedDeepPath;
var Root: IRootCommand; A,B,C,D,E: ICommand; Opts: TArgsOptions; path: TStringArray;
begin
  Root := NewRootCommand;
  A := NewCommand('alpha'); A.AddAlias('a'); Root.Register(A);
  B := NewCommand('bravo'); A.AddChild(B);
  C := NewCommand('charlie'); B.AddChild(C);
  D := NewCommand('delta'); C.AddChild(D);
  E := NewCommand('echo'); D.AddChild(E);
  Opts := ArgsOptionsDefault; Opts.CaseInsensitiveKeys := True;
  // mixed: alias at head, canonical in middle, mixed case, and an option at tail to stop
  path := GetBestMatchPath(Root, ['A','Bravo','CHARLIE','delta','ECHO','--stop'], Opts);
  AssertEquals(5, Length(path));
  AssertEquals('alpha', path[0]);
  AssertEquals('bravo', path[1]);
  AssertEquals('charlie', path[2]);
  AssertEquals('delta', path[3]);
  AssertEquals('echo', path[4]);
end;


procedure RegisterTests;
begin
  RegisterTest(TTestCase_Core_Diagnostics);
end;

end.

