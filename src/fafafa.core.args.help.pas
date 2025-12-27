unit fafafa.core.args.help;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, fafafa.core.args.schema, fafafa.core.args.command, fafafa.core.env;

type
  TGroupBy = (gbNone, gbRequired, gbAlpha);

  // ✅ P1-2: PascalCase 字段命名
  TRenderUsageOptions = record
    Width: Integer; // 0=auto (env COLUMNS or fallback)
    Wrap: Boolean;  // soft-wrap descriptions
    SortSubcommands: Boolean; // sort children by name
    MarkDefaultInChildren: Boolean; // append [default] to default child
    ShowAliases: Boolean; // show command/flag aliases
    ShowTypes: Boolean;   // show [type] tags for flags
    ShowSectionHeaders: Boolean; // show section headers like Aliases/Flags/Args
    GroupFlagsBy: TGroupBy;      // grouping/sorting strategy for flags
    GroupPositionalsBy: TGroupBy;// grouping/sorting strategy for positionals
  end;

function RenderUsage(const Node: IBaseCommand): string; overload;
function RenderUsage(const Node: IBaseCommand; const Opts: TRenderUsageOptions): string; overload;
function RenderUsageOptionsDefault: TRenderUsageOptions;
function CompareTextCI(const A, B: string): Integer; inline;

implementation

// ✅ P2-1: 抽取公共渲染项类型，减少重复代码
type
  TRenderableItem = record
    Label_: string;      // e.g. "--verbose" or "FILE"
    Meta: string;        // e.g. "[required] [default=x]"
    Description: string; // description text
  end;

function GetEnvWidth(Fallback: Integer): Integer;
var s: string; v: Integer;
begin
  s := env_get('COLUMNS');
  if s<>'' then
  begin
    Val(s, v);
    if v>20 then Exit(v);
  end;
  Exit(Fallback);
end;

// ✅ P2-1: 抽取公共的 word-wrap 渲染逻辑
procedure RenderItemLine(
  var Output: string;
  const Item: TRenderableItem;
  MaxLabelWidth: SizeInt;
  WrapWidth: Integer;
  DoWrap: Boolean
);
var
  pad, line, remaining, chunk: string;
  first: Boolean;
  limit, baseLen, budget, take, k: SizeInt;
begin
  // Build aligned line: "  label  meta"
  pad := StringOfChar(' ', MaxLabelWidth - Length(Item.Label_));
  line := '  ' + Item.Label_ + pad + '  ' + Trim(Item.Meta);

  if Item.Description = '' then
  begin
    Output := Output + LineEnding + line;
    Exit;
  end;

  // Append description with word-wrap
  if line <> '' then line := line + '  ';
  remaining := Item.Description;
  first := True;

  while Length(remaining) > 0 do
  begin
    // Calculate wrap limit
    if not DoWrap then
      limit := High(Integer)
    else if WrapWidth <= 0 then
      limit := GetEnvWidth(80)
    else
      limit := WrapWidth;

    baseLen := Length(line);
    budget := limit - baseLen;
    if budget < 20 then budget := 20; // ensure minimal budget

    take := budget;
    if take > Length(remaining) then take := Length(remaining);

    // Try break at last space
    k := take;
    while (k > 1) and (remaining[k] <> ' ') do Dec(k);
    if (k > 1) and (k >= take div 2) then take := k;

    chunk := Copy(remaining, 1, take);
    Delete(remaining, 1, take);

    if first then
    begin
      line := line + chunk;
      first := False;
      if Length(remaining) > 0 then
        Output := Output + LineEnding + '  ' + StringOfChar(' ', MaxLabelWidth) + '  ';
    end
    else
    begin
      Output := Output + chunk;
      if Length(remaining) > 0 then
        Output := Output + LineEnding + '  ' + StringOfChar(' ', MaxLabelWidth) + '  ';
    end;
  end;

  Output := Output + LineEnding + line;
end;

// ✅ P2-1: 移动到 BuildFlagItem 之前（避免前向引用）
function JoinAliases(const Arr: TStringArray): string;
var i: Integer; sep: string;
begin
  Result := '';
  sep := '';
  for i := 0 to High(Arr) do
  begin
    Result := Result + sep + Arr[i];
    sep := ', ';
  end;
end;

// ✅ P2-1: 辅助函数 - 从 Flag 构建可渲染项
function BuildFlagItem(
  const F: IArgsFlagSpec;
  const Opts: TRenderUsageOptions
): TRenderableItem;
begin
  Result.Label_ := '--' + F.Name;
  if (Length(F.Aliases) > 0) and Opts.ShowAliases then
    Result.Label_ := Result.Label_ + ' (aliases: ' + JoinAliases(F.Aliases) + ')';

  Result.Meta := '';
  if F.Required then Result.Meta := Result.Meta + ' [required]';
  if F.DefaultValue <> '' then Result.Meta := Result.Meta + ' [default=' + F.DefaultValue + ']';
  if Opts.ShowTypes and (F.ValueType <> '') then Result.Meta := Result.Meta + ' [' + F.ValueType + ']';

  Result.Description := F.Description;
end;

// ✅ P2-1: 辅助函数 - 从 Positional 构建可渲染项
function BuildPositionalItem(const P: IArgsPositionalSpec): TRenderableItem;
begin
  Result.Label_ := P.Name;

  Result.Meta := '';
  if P.Required then Result.Meta := Result.Meta + ' [required]';
  if P.Variadic then Result.Meta := Result.Meta + ' [variadic]';

  Result.Description := P.Description;
end;

function RenderUsageOptionsDefault: TRenderUsageOptions;
begin
  Result.Width := 0;
  Result.Wrap := True;
  Result.SortSubcommands := True;
  Result.MarkDefaultInChildren := True;
  Result.ShowAliases := True;
  Result.ShowTypes := True;
  Result.ShowSectionHeaders := True;
  Result.GroupFlagsBy := gbNone;
  Result.GroupPositionalsBy := gbNone;
end;

function CompareTextCI(const A, B: string): Integer; inline;
var LA, LB: string;
begin
  LA := LowerCase(A); LB := LowerCase(B);
  if LA = LB then Exit(0);
  if LA < LB then Exit(-1) else Exit(1);
end;

// ✅ P1 修复: 使用快速排序替代冒泡排序 O(n²) → O(n log n)

type
  TCommandCompareFunc = function(const A, B: ICommand): Integer;
  TFlagCompareFunc = function(const A, B: IArgsFlagSpec): Integer;
  TPositionalCompareFunc = function(const A, B: IArgsPositionalSpec): Integer;

// 快速排序 - ICommand 数组
procedure QuickSortCommands(var Arr: array of ICommand; L, R: Integer; Compare: TCommandCompareFunc);
var
  I, J: Integer;
  P, T: ICommand;
begin
  if L >= R then Exit;
  I := L;
  J := R;
  P := Arr[(L + R) div 2];
  repeat
    while Compare(Arr[I], P) < 0 do Inc(I);
    while Compare(Arr[J], P) > 0 do Dec(J);
    if I <= J then
    begin
      T := Arr[I];
      Arr[I] := Arr[J];
      Arr[J] := T;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if L < J then QuickSortCommands(Arr, L, J, Compare);
  if I < R then QuickSortCommands(Arr, I, R, Compare);
end;

// 快速排序 - IArgsFlagSpec 数组
procedure QuickSortFlags(var Arr: array of IArgsFlagSpec; L, R: Integer; Compare: TFlagCompareFunc);
var
  I, J: Integer;
  P, T: IArgsFlagSpec;
begin
  if L >= R then Exit;
  I := L;
  J := R;
  P := Arr[(L + R) div 2];
  repeat
    while Compare(Arr[I], P) < 0 do Inc(I);
    while Compare(Arr[J], P) > 0 do Dec(J);
    if I <= J then
    begin
      T := Arr[I];
      Arr[I] := Arr[J];
      Arr[J] := T;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if L < J then QuickSortFlags(Arr, L, J, Compare);
  if I < R then QuickSortFlags(Arr, I, R, Compare);
end;

// 快速排序 - IArgsPositionalSpec 数组
procedure QuickSortPositionals(var Arr: array of IArgsPositionalSpec; L, R: Integer; Compare: TPositionalCompareFunc);
var
  I, J: Integer;
  P, T: IArgsPositionalSpec;
begin
  if L >= R then Exit;
  I := L;
  J := R;
  P := Arr[(L + R) div 2];
  repeat
    while Compare(Arr[I], P) < 0 do Inc(I);
    while Compare(Arr[J], P) > 0 do Dec(J);
    if I <= J then
    begin
      T := Arr[I];
      Arr[I] := Arr[J];
      Arr[J] := T;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if L < J then QuickSortPositionals(Arr, L, J, Compare);
  if I < R then QuickSortPositionals(Arr, I, R, Compare);
end;

// 比较函数
function CompareFlagsByName(const A, B: IArgsFlagSpec): Integer;
begin
  Result := CompareTextCI(A.Name, B.Name);
end;

function ComparePositionalsByName(const A, B: IArgsPositionalSpec): Integer;
begin
  Result := CompareTextCI(A.Name, B.Name);
end;

// ✅ P1 修复: 命令比较函数（移到外部以便快速排序使用）
function CompareCmdNames(const A, B: ICommand): Integer;
begin
  if A=nil then Exit(-1);
  if B=nil then Exit(1);
  if A.Name = B.Name then Exit(0);
  if A.Name < B.Name then Exit(-1) else Exit(1);
end;


function RenderUsage(const Node: IBaseCommand): string;
begin
  Result := RenderUsage(Node, RenderUsageOptionsDefault);
end;

function RenderUsage(const Node: IBaseCommand; const Opts: TRenderUsageOptions): string;
var
  i, j: Integer;
  s: string;
  c: ICommand;
  spec: IArgsCommandSpec;
  defChild: string;
  // alignment helpers - ✅ P2-1: 简化变量声明（渲染逻辑已抽取）
  maxLabel, maxArg: SizeInt;
  width: Integer;
  // children rendering helpers
  arr: array of ICommand;
  name, d: string;
  // grouping arrays
  flags: array of IArgsFlagSpec;
  poss: array of IArgsPositionalSpec;

  // ✅ P1 修复: 移除未使用的变量 tmp, ftmp, ptmp, k（快速排序内部处理）

  function FirstDescendantDesc(const N: ICommand): string;
  var jj: Integer; child: ICommand; r: string;
  begin
    Result := N.Description;
    if Result<>'' then Exit;
    for jj := 0 to N.ChildCount-1 do
    begin
      child := N.ChildAt(jj);
      r := FirstDescendantDesc(child);
      if r<>'' then Exit(r);
    end;
    Result := '';
  end;

begin
  if Node=nil then Exit('');
  width := Opts.Width; // ✅ P2-1: 初始化 width（0 表示自动检测）

  // Commands list (children) with optional sorting and [default] marking
  s := '';
  if Node.ChildCount>0 then
  begin
    s := s + 'Commands:';
    // collect children
    SetLength(arr, 0);
    SetLength(arr, Node.ChildCount);
    for i := 0 to Node.ChildCount-1 do arr[i] := Node.ChildAt(i);
    // ✅ P1 修复: 使用快速排序 O(n log n) 替代冒泡排序 O(n²)
    if Opts.SortSubcommands and (Length(arr) > 1) then
      QuickSortCommands(arr, 0, High(arr), @CompareCmdNames);
    // render
    for i := 0 to High(arr) do
    begin
      name := arr[i].Name;
      if Opts.MarkDefaultInChildren and (Node.DefaultChildName<> '') and (LowerCase(Node.DefaultChildName)=LowerCase(name)) then
        name := name + ' [default]';
      // pick first descendant description
      d := FirstDescendantDesc(arr[i]);
      s := s + LineEnding + Format('  %s: %s', [name, d]);
    end;
  end;

  // default subcommand hint (if any)
  defChild := Node.DefaultChildName;
  if defChild<>'' then
    s := s + LineEnding + Format('Default subcommand: %s', [defChild]);

  // Append flags/positionals if spec is attached (only for ICommand nodes)
  if Supports(Node, ICommand, c) then
  begin
    // command aliases
    if Opts.ShowAliases and (Length(c.Aliases) > 0) then
    begin
      if Opts.ShowSectionHeaders then
        s := s + LineEnding + 'Aliases: ' + JoinAliases(c.Aliases)
      else
        s := s + LineEnding + JoinAliases(c.Aliases);
    end;
    spec := c.GetSpec;
    if spec<>nil then
    begin
      // flags with aligned description and soft wrap
      if spec.FlagCount>0 then
      begin
        if Opts.ShowSectionHeaders then
          s := s + LineEnding + 'Flags:'
        else
          s := s + LineEnding;
        // collect flags into arrays for grouping/sorting
        SetLength(flags, spec.FlagCount);
        for j := 0 to spec.FlagCount-1 do flags[j] := spec.FlagAt(j);
        // compute label width using helper - ✅ P2-1: 使用 BuildFlagItem
        maxLabel := 0;
        for j := 0 to High(flags) do
          if Length(BuildFlagItem(flags[j], Opts).Label_) > maxLabel then
            maxLabel := Length(BuildFlagItem(flags[j], Opts).Label_);
        // ✅ P1 修复: 使用快速排序 O(n log n) 替代冒泡排序 O(n²)
        if (Opts.GroupFlagsBy = gbAlpha) and (Length(flags) > 1) then
          QuickSortFlags(flags, 0, High(flags), @CompareFlagsByName);
        // render (optionally required-first grouping) - ✅ P2-1: 使用公共渲染函数
        for j := 0 to High(flags) do
        begin
          if (Opts.GroupFlagsBy = gbRequired) and (not flags[j].Required) then Continue;
          RenderItemLine(s, BuildFlagItem(flags[j], Opts), maxLabel, width, Opts.Wrap);
        end;
        // render optional (non-required) flags if required-first grouping
        if Opts.GroupFlagsBy = gbRequired then
          for j := 0 to High(flags) do
          begin
            if flags[j].Required then Continue;
            RenderItemLine(s, BuildFlagItem(flags[j], Opts), maxLabel, width, Opts.Wrap);
          end;
      end;
      // positionals with alignment
      if spec.PositionalCount>0 then
      begin
        if Opts.ShowSectionHeaders then
          s := s + LineEnding + 'Args:'
        else
          s := s + LineEnding;
        // collect positionals
        SetLength(poss, spec.PositionalCount);
        for j := 0 to spec.PositionalCount-1 do poss[j] := spec.PositionalAt(j);
        // compute label width using helper - ✅ P2-1: 使用 BuildPositionalItem
        maxArg := 0;
        for j := 0 to High(poss) do
          if Length(BuildPositionalItem(poss[j]).Label_) > maxArg then
            maxArg := Length(BuildPositionalItem(poss[j]).Label_);
        // ✅ P1 修复: 使用快速排序 O(n log n) 替代冒泡排序 O(n²)
        if (Opts.GroupPositionalsBy = gbAlpha) and (Length(poss) > 1) then
          QuickSortPositionals(poss, 0, High(poss), @ComparePositionalsByName);
        // render required first if requested - ✅ P2-1: 使用公共渲染函数
        for j := 0 to High(poss) do
        begin
          if (Opts.GroupPositionalsBy = gbRequired) and (not poss[j].Required) then Continue;
          RenderItemLine(s, BuildPositionalItem(poss[j]), maxArg, width, Opts.Wrap);
        end;
        if Opts.GroupPositionalsBy = gbRequired then
          for j := 0 to High(poss) do
          begin
            if poss[j].Required then Continue;
            RenderItemLine(s, BuildPositionalItem(poss[j]), maxArg, width, Opts.Wrap);
          end;

      end;
    end;
  end;
  Result := s;
end;

end.

