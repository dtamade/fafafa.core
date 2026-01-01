unit fafafa.core.args.command;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}
{$WARN 5024 off} // suppress unused parameter warnings in minimal impl
// CONTRACTS / BEST PRACTICES:
// - No implicit printing: library returns integer codes; caller owns help/error output
// - Register uses First-Wins: do not call Execute(nil); do not override existing handler
// - Aliases merge as CI union; aliases do not participate in identity
// - Default-subcommand fallback triggers when no more non-option tokens or next token is an option
// - Persistent flags propagate at registration-time from parent to child; same-name flags are not overridden (First Wins)

interface

uses
  SysUtils, fafafa.core.args, fafafa.core.args.utils, fafafa.core.collections.vec, fafafa.core.args.schema;

type
  TStringArray = array of string;

  // Command handler types (three callback kinds)
  TCommandHandler = function(const A: IArgs): Integer;
  TCommandHandlerFunc = function(const A: IArgs): Integer;
  TCommandHandlerMethod = function(const A: IArgs): Integer of object;
  {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
  TCommandHandlerRef = reference to function(const A: IArgs): Integer;
  {$ENDIF}

  // Forward declaration for cross-references
  ICommand = interface;

  // Base container interface (no name/handler)
  IBaseCommand = interface
    ['{67B9B2B2-7E0A-4B2F-A2C0-9D0F6B6E8F31}']
    function ChildCount: Integer;
    function ChildAt(Index: Integer): ICommand;
    // Add a direct child. Fails if a child with the same name (CI) already exists.
    // Best practice: names are identities; aliases do not participate here.
    procedure AddChild(const C: ICommand);
    procedure EnsureCapacity(Capacity: SizeUInt);
    // Find by name or alias
    function FindChild(const AName: string; CaseInsensitive: boolean): ICommand;
    // Register subtree by name (CI): upsert children; adopt handler/desc only if missing
    function Register(const Cmd: ICommand): ICommand;
    // Ensure child exists by name; create if missing and optionally reserve capacity
    function UpsertChild(const AName: string; InitialCapacity: SizeUInt = 0): ICommand;
    // Find child by name only (no alias), with CI option
    function FindChildByName(const AName: string; CaseInsensitive: boolean): ICommand;
    // Default subcommand support
    // Configure default subcommand by name (CI). The child may be added later.
    procedure SetDefaultChildName(const AName: string);
    function DefaultChildName: string;
    function DefaultChild: ICommand;
    // Usage generation for current node
    function Usage: string;
  end;

  // Root command: routing/entry only (no name/handler)
  IRootCommand = interface(IBaseCommand)
    ['{C2F88E0B-6D7F-4F9A-9C1F-1A2B3C4D5E6F}']
    // Run from process/array
    function Run: Integer; overload;
    function Run(const Opts: TArgsOptions): Integer; overload;
    // Route by scanning first non-option tokens as path; returns handler's code.
    function Run(const Args: array of string; const Opts: TArgsOptions): Integer; overload;
    // Explicit path + argv (disambiguated)
    // Route by explicit path; avoids ambiguity from argv; returns handler's code.
    function RunPath(const Path, Argv: array of string; const Opts: TArgsOptions): Integer;
  end;

  // Concrete command node with name/handler
  ICommand = interface(IBaseCommand)
    ['{B5D0B0B5-7D06-4D7E-8C93-81B0C32B0D7B}']
    function Name: string;
    function Aliases: TStringArray;
    procedure AddAlias(const AliasName: string);
    function Description: string;
    procedure SetDescription(const ADesc: string);
    function HasHandler: boolean;
    // Set handler overloads
    procedure SetHandlerFunc(const H: TCommandHandlerFunc);
    procedure SetHandlerMethod(const H: TCommandHandlerMethod);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure SetHandlerRef(const H: TCommandHandlerRef);
    {$ENDIF}
    // Schema attachment (optional)
    function GetSpec: IArgsCommandSpec;
    procedure SetSpec(const S: IArgsCommandSpec);

    {**
     * Execute the command handler with parsed arguments.
     *
     * @param A Parsed command line arguments (IArgs interface)
     * @returns Exit code following POSIX conventions:
     *          - CMD_OK (0): Success
     *          - CMD_NOT_FOUND (1): Command or subcommand not found
     *          - CMD_PARSE_ERROR (2): Argument parsing error / misuse
     *          - Other non-zero: Application-specific error codes
     *
     * @note If no handler is registered, returns CMD_OK (0).
     * @note The caller is responsible for help/error output; this library
     *       does not print to stdout/stderr.
     *
     * @see CMD_OK, CMD_NOT_FOUND, CMD_PARSE_ERROR constants
     * @see TCommandHandlerFunc, TCommandHandlerMethod, TCommandHandlerRef
     *}
    function Execute(const A: IArgs): Integer;
  end;

// Factories
const
  DEFAULT_ROOT_COMMAND_CAPACITY = 16;
  DEFAULT_COMMAND_CAPACITY = 4;
  CMD_OK = 0;
  CMD_NOT_FOUND = 1;
  CMD_PARSE_ERROR = 2;

function NewRootCommand(InitialCapacity: SizeUInt = DEFAULT_ROOT_COMMAND_CAPACITY): IRootCommand;
function NewCommand(const Name: string; InitialCapacity: SizeUInt = DEFAULT_COMMAND_CAPACITY): ICommand;
function NewCommandPath(const Names: array of string; const AHandler: TCommandHandler; const ADesc: string = ''; RootCapacity: SizeUInt = 0): ICommand;
// Diagnostics helper: returns the longest matched command path from Args (tokens), excluding options
function GetBestMatchPath(const Root: IRootCommand; const Args: array of string; const Opts: TArgsOptions): TStringArray;

implementation

type
   TCmdVec = specialize TVec<ICommand>;

  { TRootCommand: container + routing }
  TRootCommand = class(TInterfacedObject, IRootCommand)
  protected
    FChildren: TCmdVec;
    FDefaultChildName: string;
  protected
    function FindChildByNameCI(const AName: string): ICommand;
  public
    constructor Create(InitialCapacity: SizeUInt);
    // IBaseCommand
    function ChildCount: Integer;
    function ChildAt(Index: Integer): ICommand;
    procedure AddChild(const C: ICommand);
    procedure EnsureCapacity(Capacity: SizeUInt);
    function FindChild(const AName: string; CaseInsensitive: boolean): ICommand;
    function FindChildByName(const AName: string; CaseInsensitive: boolean): ICommand;
    function Register(const Cmd: ICommand): ICommand;
    function UpsertChild(const AName: string; InitialCapacity: SizeUInt = 0): ICommand;
    // Default subcommand
    procedure SetDefaultChildName(const AName: string);
    function DefaultChildName: string;
    function DefaultChild: ICommand;
    // Usage
    function Usage: string;
    // IRootCommand - routing
    function Run: Integer; overload;
    function Run(const Opts: TArgsOptions): Integer; overload;
    function Run(const Args: array of string; const Opts: TArgsOptions): Integer; overload;
    function RunPath(const Path, Argv: array of string; const Opts: TArgsOptions): Integer;
  end;

  { TCommand: named node with handler }
  TCommand = class(TRootCommand, ICommand)
  private
    type THandlerKind = (hkNone, hkFunc, hkMethod{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}, hkRef{$ENDIF});
  private
    FName: string;
    FAliases: TStringArray;
    FDesc: string;
    FHandlerKind: THandlerKind;
    FHandlerFunc: TCommandHandlerFunc;
    FHandlerMethod: TCommandHandlerMethod;
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    FHandlerRef: TCommandHandlerRef;
    {$ENDIF}
    FSpec: IArgsCommandSpec;
  public
    constructor Create(const AName: string; InitialCapacity: SizeUInt = 0);
    // ICommand
    function Name: string;
    function Aliases: TStringArray;
    procedure AddAlias(const S: string);
    function Description: string;
    procedure SetDescription(const ADesc: string);
    function HasHandler: boolean;
    procedure SetHandlerFunc(const H: TCommandHandlerFunc);
    procedure SetHandlerMethod(const H: TCommandHandlerMethod);
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    procedure SetHandlerRef(const H: TCommandHandlerRef);
    {$ENDIF}
    function GetSpec: IArgsCommandSpec;
    procedure SetSpec(const S: IArgsCommandSpec);
    function Execute(const A: IArgs): Integer;
  end;

{ Helpers }
procedure AddString(var Arr: TStringArray; const V: string);
begin
  SetLength(Arr, Length(Arr)+1);
  Arr[High(Arr)] := V;
end;

function IsRoutingStopToken(const S: string; const Opts: TArgsOptions): boolean; inline;
begin
  // Keep consistent with ParseArgs contract: "--" always stops parsing.
  // StopAtDoubleDash only controls whether the token is kept as a positional.
  Result := IsDoubleDashSentinel(S);
end;

function IsOptionLikeForRouting(const S: string; const Opts: TArgsOptions): boolean; inline;
begin
  Result := IsOptionLikeToken(S, Opts.AllowSlashOptions, Opts.TreatNegativeNumbersAsPositionals);
end;

function IsSkippableOptionValueTokenForRouting(const S: string; const Opts: TArgsOptions): boolean; inline;
begin
  // Heuristic for routing pre-scan only: some tokens are very likely to be option values
  // (and very unlikely to be command path segments).
  if S='-' then Exit(True);
  if Opts.TreatNegativeNumbersAsPositionals and IsNegativeNumberLike(S) then Exit(True);
  if (not Opts.AllowSlashOptions) and (Length(S)>0) and (S[1]='/') then Exit(True);
  Result := False;
end;

function FindFirstCommandTokenIndex(const Root: IBaseCommand; const Args: array of string; const Opts: TArgsOptions): Integer;
var
  i: Integer;
  caseInsensitive: boolean;
begin
  Result := -1;
  if Root=nil then Exit;
  caseInsensitive := Opts.CaseInsensitiveKeys;

  i := Low(Args);
  while i <= High(Args) do
  begin
    if IsRoutingStopToken(Args[i], Opts) then Exit;
    if IsOptionLikeForRouting(Args[i], Opts) then
    begin
      if (Pos('=', Args[i]) > 0) or (Pos(':', Args[i]) > 0) then
      begin
        // Inline assignment already contains the value.
        Inc(i);
        Continue;
      end;

      if (i+1 <= High(Args)) and (not IsRoutingStopToken(Args[i+1], Opts)) then
      begin
        // Special value tokens (stdin marker, negative numbers, unix paths) are never
        // treated as command tokens.
        if IsSkippableOptionValueTokenForRouting(Args[i+1], Opts) then
        begin
          Inc(i, 2);
          Continue;
        end;

        // Generic value token: skip if it isn't option-like and also isn't a command.
        if (not IsOptionLikeForRouting(Args[i+1], Opts))
          and (Root.FindChild(Args[i+1], caseInsensitive) = nil) then
        begin
          Inc(i, 2);
          Continue;
        end;
      end;

      Inc(i);
      Continue;
    end;

    Result := i;
    Exit;
  end;
end;



function Normalize(const S: string; CaseInsensitive: boolean): string;
begin
  if CaseInsensitive then Result := LowerCase(S) else Result := S;
end;

{ TRootCommand }
constructor TRootCommand.Create(InitialCapacity: SizeUInt);
begin
  inherited Create;
  FChildren := TCmdVec.Create(0);
  if InitialCapacity>0 then FChildren.Reserve(InitialCapacity);
  FDefaultChildName := '';
end;

function TRootCommand.ChildCount: Integer;
begin
  if FChildren<>nil then Result := FChildren.GetCount else Result := 0;
end;

function TRootCommand.ChildAt(Index: Integer): ICommand;
begin
  if FChildren<>nil then Result := FChildren.Get(Index) else Result := nil;
end;

procedure TRootCommand.EnsureCapacity(Capacity: SizeUInt);
begin
  if Capacity>0 then
  begin
    if FChildren=nil then FChildren := TCmdVec.Create(0);
    FChildren.Reserve(Capacity);
  end;
end;

procedure TRootCommand.AddChild(const C: ICommand);
var existing: ICommand; nm, parentLbl: string;
begin
  if C=nil then Exit;
  nm := C.Name;
  if nm='' then
    raise EArgumentException.Create('AddChild: command name cannot be empty');
  // prevent duplicate by name (CI) - aliases do not participate
  existing := FindChildByName(nm, True);
  if existing<>nil then
  begin
    if Self is TCommand then parentLbl := (Self as TCommand).Name else parentLbl := '<root>';
    raise EArgumentException.CreateFmt('AddChild: duplicate command name "%s" under "%s"', [nm, parentLbl]);
  end;
  if FChildren=nil then FChildren := TCmdVec.Create(0);
  FChildren.Push(C);
end;

function TRootCommand.DefaultChildName: string;
begin
  Result := FDefaultChildName;
end;

procedure TRootCommand.SetDefaultChildName(const AName: string);
begin
  FDefaultChildName := AName;
end;

function TRootCommand.DefaultChild: ICommand;
begin
  if FDefaultChildName='' then Exit(nil);
  Exit(FindChildByName(FDefaultChildName, True));
end;

function TRootCommand.Usage: string;
var i: Integer; s, d: string;
  function FirstDescendantDesc(const N: ICommand): string;
  var i, head, tail, cap: Integer; cur: ICommand;
      q: array of ICommand;
  begin
    q := nil;
    // BFS (iterative): prefer nearest descendant description, avoid deep recursion
    if N.Description<>'' then Exit(N.Description);
    // init queue with direct children
    cap := N.ChildCount;
    if cap=0 then Exit('');
    SetLength(q, cap);
    for i := 0 to cap-1 do q[i] := N.ChildAt(i);
    head := 0; tail := cap;
    while head < tail do
    begin
      cur := q[head]; Inc(head);
      if cur.Description<>'' then Exit(cur.Description);
      // append cur's children to queue
      cap := cur.ChildCount;
      if cap>0 then
      begin
        SetLength(q, tail + cap);
        for i := 0 to cap-1 do
        begin
          q[tail+i] := cur.ChildAt(i);
        end;
        Inc(tail, cap);
      end;
    end;
    Result := '';
  end;
begin
  s := '';
  for i := 0 to ChildCount-1 do
  begin
    if s<>'' then s := s + LineEnding;
    d := FirstDescendantDesc(ChildAt(i));
    s := s + Format('%s: %s', [ChildAt(i).Name, d]);
  end;
  Result := s;
end;

function TRootCommand.FindChildByNameCI(const AName: string): ICommand;
var i: Integer; n, cand: string;
begin
  Result := nil;
  if (FChildren=nil) or (AName='') then Exit;
  n := LowerCase(AName);
  for i := 0 to FChildren.GetCount-1 do
  begin
    cand := LowerCase(FChildren.Get(i).Name);
    if cand = n then Exit(FChildren.Get(i));
  end;
end;

function TRootCommand.FindChildByName(const AName: string; CaseInsensitive: boolean): ICommand;
var i: Integer;
begin
  if CaseInsensitive then Exit(FindChildByNameCI(AName))
  else begin
    // exact match (case-sensitive)
    Result := nil;
    if (FChildren=nil) or (AName='') then Exit;
    for i := 0 to FChildren.GetCount-1 do
      if FChildren.Get(i).Name = AName then Exit(FChildren.Get(i));
  end;
end;

function TRootCommand.FindChild(const AName: string; CaseInsensitive: boolean): ICommand;
var i, j: Integer; n, cand: string; arr: TStringArray; child: ICommand;
begin
  Result := nil;
  if (FChildren=nil) or (AName='') then Exit;
  n := Normalize(AName, CaseInsensitive);
  for i := 0 to FChildren.GetCount-1 do
  begin
    child := FChildren.Get(i);
    cand := Normalize(child.Name, CaseInsensitive);
    if cand = n then Exit(child);
    SetLength(arr, 0);
    arr := child.Aliases;
    for j := 0 to High(arr) do
      if Normalize(arr[j], CaseInsensitive) = n then Exit(child);
  end;
end;

function TRootCommand.Register(const Cmd: ICommand): ICommand;
var
  target, srcChild, dstChild: ICommand;
  i, k: Integer;
  srcAliases: TStringArray;
  found: Boolean;
  // added for persistent flag propagation
  pSpec: IArgsCommandSpec;
  dSpec: IArgsCommandSpec;
  j: Integer;
  pf: IArgsFlagSpec;
  nf: IArgsFlagSpec;
  k2: Integer;
  exists2: Boolean;
  al: TStringArray;
  aidx: Integer;
  nm: string; parentLbl: string;
begin
  Result := nil;
  if Cmd=nil then Exit(nil);
  nm := Cmd.Name;
  if nm='' then
  begin
    if Self is TCommand then parentLbl := (Self as TCommand).Name else parentLbl := '<root>';
    raise EArgumentException.CreateFmt('Register: command name cannot be empty under "%s"', [parentLbl]);
  end;
  // upsert target by name (CI)
  target := FindChildByName(nm, True);
  if target=nil then
  begin
    AddChild(Cmd);
    Exit(Cmd);
  end;
  // adopt description only if target lacks handler且源有处理器；处理器不在此处复制
  if (not target.HasHandler) and Cmd.HasHandler then
  begin
    // 不再执行 Cmd.Execute(nil) 以探测处理器，避免空参导致的潜在异常
    target.SetDescription(Cmd.Description);
  end;
  // merge aliases as union (CI de-dup); alias does not participate in identity
  srcAliases := Cmd.Aliases;
  for i := 0 to High(srcAliases) do
  begin
    if srcAliases[i]='' then Continue; // guard empty alias
    // skip if alias equals target name (CI)
    if LowerCase(srcAliases[i]) = LowerCase(target.Name) then Continue;
    // de-dup against current target aliases (CI)
    found := False;
    for k := 0 to High(target.Aliases) do
      if LowerCase(target.Aliases[k]) = LowerCase(srcAliases[i]) then begin found := True; Break; end;
    if not found then target.AddAlias(srcAliases[i]);
  end;
  // propagate persistent flags from parent (Cmd) to each child target (dstChild)
  // and recursively register children under target by name (CI)
  for i := 0 to Cmd.ChildCount-1 do
  begin
    srcChild := Cmd.ChildAt(i);
    dstChild := target.FindChildByName(srcChild.Name, True);
    if dstChild=nil then
    begin
      // create child first
      target.AddChild(srcChild);
      dstChild := srcChild;
    end
    else
      dstChild.Register(srcChild);
    // After we have dstChild, copy parent's persistent flags if missing
    // Gather parent spec
    if (Cmd.GetSpec<>nil) then
    begin
      pSpec := Cmd.GetSpec;
      // ensure dstChild has a spec container
      if dstChild.GetSpec=nil then dstChild.SetSpec(NewCommandSpec);
      dSpec := dstChild.GetSpec;
      // iterate parent flags, copy only persistent and not existing by name (CI)
      for j := 0 to pSpec.FlagCount-1 do
      begin
        pf := pSpec.FlagAt(j);
        if (pf<>nil) and pf.Persistent then
        begin
          // check duplicate by name (CI)
          exists2 := False;
          for k2 := 0 to dSpec.FlagCount-1 do
            if LowerCase(dSpec.FlagAt(k2).Name) = LowerCase(pf.Name) then begin exists2 := True; Break; end;
          if not exists2 then
          begin
            nf := NewFlagSpec(pf.Name, pf.Description, pf.Required, pf.ValueType, pf.DefaultValue);
            nf.SetPersistent(True);
            // copy aliases
            al := pf.Aliases;
            for aidx := 0 to High(al) do nf.AddAlias(al[aidx]);
            dSpec.AddFlag(nf);
          end;
        end;
      end;
    end;
  end;
  Result := target;
end;

function TRootCommand.UpsertChild(const AName: string; InitialCapacity: SizeUInt): ICommand;
begin
  Result := FindChildByName(AName, True);
  if Result<>nil then Exit;
  Result := TCommand.Create(AName, InitialCapacity);
  AddChild(Result);
end;

function TRootCommand.Run: Integer;
var arr: TStringArray; i: Integer;
begin
  SetLength(arr, 0);
  SetLength(arr, ParamCount);
  for i := 1 to ParamCount do arr[i-1] := ParamStr(i);
  Result := Run(arr, ArgsOptionsDefault);
end;

function TRootCommand.Run(const Opts: TArgsOptions): Integer;
var arr: TStringArray; i: Integer;
begin
  SetLength(arr, 0);
  SetLength(arr, ParamCount);
  for i := 1 to ParamCount do arr[i-1] := ParamStr(i);
  Result := Run(arr, Opts);
end;

function TRootCommand.Run(const Args: array of string; const Opts: TArgsOptions): Integer;
var i, depth, idx: Integer; cur, child: ICommand;
    subArgs: array of string; caseInsensitive: boolean; firstNonOpt: Integer;
    hasNextNonOpt: boolean;
begin
  Result := CMD_NOT_FOUND; // non-zero default
  cur := nil;
  SetLength(subArgs, 0);
  caseInsensitive := Opts.CaseInsensitiveKeys;
  // find first command token as path start
  depth := 0;
  firstNonOpt := FindFirstCommandTokenIndex(Self as IRootCommand, Args, Opts);
  if firstNonOpt<0 then Exit; // no command provided
  // walk down
  idx := firstNonOpt;
  while (idx <= High(Args)) and (not IsOptionLikeForRouting(Args[idx], Opts)) do
  begin
    if cur=nil then child := FindChild(Args[idx], caseInsensitive)
    else child := cur.FindChild(Args[idx], caseInsensitive);
    if child=nil then Break;
    cur := child; Inc(depth); Inc(idx);
  end;
  if (cur=nil) or (depth=0) then Exit; // not found (CMD_NOT_FOUND)
  // default-subcommand fallback when no more tokens OR next is an option
  hasNextNonOpt := (idx <= High(Args)) and (not IsOptionLikeForRouting(Args[idx], Opts));
  if (not hasNextNonOpt) then
  begin
    // "--" is a routing stop marker: do not trigger default-child fallback.
    if (idx <= High(Args)) and IsRoutingStopToken(Args[idx], Opts) then
    begin
      // keep cur as-is
    end
    else
    begin
      child := cur.DefaultChild;
      if child<>nil then cur := child;
    end;
  end;
  // Build argv for the selected command by removing only the matched command-path tokens.
  // This preserves options that appear before the command token (e.g. ENV/CONFIG merges).
  SetLength(subArgs, 0);
  for i := Low(Args) to High(Args) do
  begin
    if (i >= firstNonOpt) and (i < firstNonOpt + depth) then
      Continue; // skip routing path tokens
    SetLength(subArgs, Length(subArgs)+1);
    subArgs[High(subArgs)] := Args[i];
  end;
  Result := cur.Execute(TArgs.FromArray(subArgs, Opts));
end;

function TRootCommand.RunPath(const Path, Argv: array of string; const Opts: TArgsOptions): Integer;
var i: Integer; cur: ICommand;
begin
  Result := CMD_NOT_FOUND; cur := nil;
  for i := Low(Path) to High(Path) do
  begin
    if cur=nil then cur := FindChild(Path[i], Opts.CaseInsensitiveKeys)
    else cur := cur.FindChild(Path[i], Opts.CaseInsensitiveKeys);
    if cur=nil then Exit(CMD_NOT_FOUND);
  end;
  Result := cur.Execute(TArgs.FromArray(Argv, Opts));
end;

{ TCommand }
constructor TCommand.Create(const AName: string; InitialCapacity: SizeUInt);
begin
  inherited Create(InitialCapacity);
  FName := AName;
  FAliases := nil;
  FDesc := '';
  FHandlerKind := hkNone;
end;

function TCommand.Name: string; begin Result := FName; end;
function TCommand.Aliases: TStringArray; begin Result := FAliases; end;
procedure TCommand.AddAlias(const S: string);
var i: Integer;
begin
  if S='' then raise EArgumentException.CreateFmt('AddAlias: alias cannot be empty for command "%s"', [FName]);
  // prevent duplicate alias (CI) on the same command for better diagnostics
  for i := 0 to High(FAliases) do
    if LowerCase(FAliases[i]) = LowerCase(S) then
      raise EArgumentException.CreateFmt('AddAlias: duplicate alias "%s" for command "%s"', [S, FName]);
  AddString(FAliases, S);
end;
function TCommand.Description: string; begin Result := FDesc; end;
procedure TCommand.SetDescription(const ADesc: string); begin FDesc := ADesc; end;
function TCommand.HasHandler: boolean; begin Result := FHandlerKind<>hkNone; end;
procedure TCommand.SetHandlerFunc(const H: TCommandHandlerFunc); begin FHandlerKind := hkFunc; FHandlerFunc := H; end;
procedure TCommand.SetHandlerMethod(const H: TCommandHandlerMethod); begin FHandlerKind := hkMethod; FHandlerMethod := H; end;
{$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
procedure TCommand.SetHandlerRef(const H: TCommandHandlerRef); begin FHandlerKind := hkRef; FHandlerRef := H; end;
{$ENDIF}
function TCommand.GetSpec: IArgsCommandSpec; begin Result := FSpec; end;
procedure TCommand.SetSpec(const S: IArgsCommandSpec); begin FSpec := S; end;
function TCommand.Execute(const A: IArgs): Integer;
begin
  case FHandlerKind of
    hkFunc:   Exit(FHandlerFunc(A));
    hkMethod: Exit(FHandlerMethod(A));
    {$IFDEF FAFAFA_CORE_ANONYMOUS_REFERENCES}
    hkRef:    Exit(FHandlerRef(A));
    {$ENDIF}
  else
    Exit(CMD_OK);
  end;
end;


function GetBestMatchPath(const Root: IRootCommand; const Args: array of string; const Opts: TArgsOptions): TStringArray;
var i, firstNonOpt, depth: Integer; cur, child: ICommand; caseInsensitive, hasNextNonOpt: boolean; name: string;
begin
  SetLength(Result, 0);
  if Root=nil then Exit;
  caseInsensitive := Opts.CaseInsensitiveKeys;
  // find first command token as path start
  depth := 0; cur := nil;
  firstNonOpt := FindFirstCommandTokenIndex(Root, Args, Opts);
  if firstNonOpt<0 then Exit; // no command tokens
  // walk down greedily by name/alias
  name := Args[firstNonOpt];
  cur := Root.FindChild(name, caseInsensitive);
  if cur=nil then Exit;
  SetLength(Result, 1); Result[0] := cur.Name;
  depth := 1; i := firstNonOpt+1;
  while i <= High(Args) do
  begin
    if IsOptionLikeForRouting(Args[i], Opts) then Break;
    child := cur.FindChild(Args[i], caseInsensitive);
    if child=nil then
    begin
      // try alias match only (FindChild already checks aliases). If still nil, stop.
    end;
    if child=nil then Break;
    cur := child;
    SetLength(Result, Length(Result)+1);
    Result[High(Result)] := cur.Name;
    Inc(depth); Inc(i);
  end;
  // apply default-child fallback if next is option or no more tokens
  hasNextNonOpt := (i <= High(Args)) and (not IsOptionLikeForRouting(Args[i], Opts));
  if not hasNextNonOpt then
  begin
    // "--" is a routing stop marker: do not trigger default-child fallback.
    if (i <= High(Args)) and IsRoutingStopToken(Args[i], Opts) then
    begin
      // keep as-is
    end
    else
    begin
      child := cur.DefaultChild;
      if child<>nil then
      begin
        SetLength(Result, Length(Result)+1);
        Result[High(Result)] := child.Name;
      end;
    end;
  end;
end;

// Factories implementation
function NewRootCommand(InitialCapacity: SizeUInt = DEFAULT_ROOT_COMMAND_CAPACITY): IRootCommand;
begin
  Result := TRootCommand.Create(InitialCapacity);
end;

function NewCommand(const Name: string; InitialCapacity: SizeUInt = DEFAULT_COMMAND_CAPACITY): ICommand;
begin
  Result := TCommand.Create(Name, InitialCapacity);
end;

function NewCommandPath(const Names: array of string; const AHandler: TCommandHandler; const ADesc: string = ''; RootCapacity: SizeUInt = 0): ICommand;
var i: Integer; root, cur, nextNode: ICommand;
begin
  Result := nil;
  if Length(Names)=0 then Exit(nil);
  root := TCommand.Create(Names[Low(Names)], RootCapacity);
  cur := root;
  for i := Low(Names)+1 to High(Names) do
  begin
    nextNode := TCommand.Create(Names[i]);
    cur.AddChild(nextNode);
    cur := nextNode;
  end;
  cur.SetHandlerFunc(AHandler);
  cur.SetDescription(ADesc);
  Result := root;
end;

end.

