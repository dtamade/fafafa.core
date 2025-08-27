program example_usage_default;

{$mode objfpc}{$H+}
{$I ../../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.args,
  fafafa.core.args.command;

function H_Remote_List(const A: IArgs): Integer;
begin
  Writeln('remote list executed');
  if A<>nil then
  begin
    if A.HasFlag('json') then Writeln('  --json = true');
    if Length(A.Positionals)>0 then
      Writeln('  positionals[0] = ', A.Positionals[0]);
  end;
  Exit(0);
end;

function H_Remote_Add(const A: IArgs): Integer;
begin
  Writeln('remote add executed');
  if A<>nil then
  begin
    if Length(A.Positionals)>=2 then
      Writeln('  add ', A.Positionals[0], ' ', A.Positionals[1]);
  end;
  Exit(0);
end;

function ArgvHasHelp: boolean;
var i: Integer; s: string;
begin
  Result := False;
  for i := 1 to ParamCount do
  begin
    s := ParamStr(i);
    if (s='-h') or (s='--help') then Exit(True);
  end;
end;

procedure PrintUsageForNode(const Node: IBaseCommand);
begin
  if Node=nil then Exit;
  Writeln(Node.Usage);
end;

// Walk down by first non-option tokens to find current node for help display
function ResolveNodeForHelp(const Root: IRootCommand; CaseInsensitive: boolean): IBaseCommand;
var i: Integer; idx: Integer; cur, nextC: ICommand; t: string;
begin
  Result := Root;
  cur := nil;
  // find first non-option
  idx := -1;
  for i := 1 to ParamCount do
  begin
    t := ParamStr(i);
    if (t<>'') and (t[1]<>'-') and (t[1]<>'/') then begin idx := i; Break; end;
  end;
  if idx<0 then Exit; // no path tokens
  // walk until option or end
  while (idx<=ParamCount) do
  begin
    t := ParamStr(idx);
    if (t='') or (t[1]='-') or (t[1]='/') then Break;
    if cur=nil then nextC := Root.FindChild(t, CaseInsensitive)
              else nextC := cur.FindChild(t, CaseInsensitive);
    if nextC=nil then Break;
    cur := nextC;
    Inc(idx);
  end;
  if cur<>nil then Result := cur;
end;

var
  Root: IRootCommand;
  remoteRoot: ICommand;
  code: Integer = 0;
  opts: TArgsOptions;
begin
  // build command tree
  Root := NewRootCommand;
  // remote list
  Root.Register(NewCommandPath(['remote','list'], @H_Remote_List, 'List remotes'));
  // remote add
  Root.Register(NewCommandPath(['remote','add'], @H_Remote_Add, 'Add a remote'));
  // set default subcommand for "remote": list
  remoteRoot := Root.FindChildByName('remote', True);
  if remoteRoot<>nil then remoteRoot.SetDefaultChildName('list');

  // caller-side help handling
  opts := ArgsOptionsDefault;
  if ArgvHasHelp then
  begin
    PrintUsageForNode(ResolveNodeForHelp(Root, opts.CaseInsensitiveKeys));
    Halt(2);
  end;

  // normal dispatch
  code := Root.Run(opts);
  if code<>0 then
  begin
    // if not found or error: show root usage
    Writeln('Error code: ', code);
    PrintUsageForNode(Root);
  end;
  Halt(code);
end.

