# fafafa.core.args.command

简述
- 基于子命令树（任意深度），与 Rust clap / Go Cobra / Java picocli 设计一致
- 路由从 argv 首个非选项 token 开始向下匹配；匹配成功后余下切片交由叶子命令解析
  - 为避免常见“值 token”被误判为命令名：当 `-`（stdin/stdout 标记）、负数（如 `-1`，在 TreatNegativeNumbersAsPositionals=True 时）或 Unix 绝对路径（如 `/tmp/a`，在 AllowSlashOptions=False 时）紧跟在选项 token 后出现时，路由会跳过它们继续寻找命令 token
- 支持别名（与主名等价，大小写敏感性由 ArgsOptions 控制）
- 支持 `--` 哨兵：其后的 token 全部作为位置参数传递给子命令

核心接口（摘要）
- IRootCommand
  - Register(Cmd): 合并命令树；若路径已存在，仅做别名与子树合并（不覆盖处理器）
  - Run(Args, Opts): 自动路由到最深匹配叶子并执行其处理器，返回整型错误码
  - RunPath(Path, Args, Opts): 指定路径执行
- ICommand
  - Name/Description/Aliases
  - AddAlias(string)
  - SetHandlerFunc(TCommandHandlerFunc)
  - Execute(IArgs): Integer

合并（Register）语义
- 以“先到先得”为准则：已存在节点的处理器不会被后注册同路径覆盖
- 别名采用并集；大小写去重；若别名与主名相同则忽略
- 若目标节点无处理器而源节点有处理器，本轮实现仅拷贝描述，不拷贝处理器（避免隐式副作用/耦合）
- 安全性：Register 不会执行任何处理器（此前实现有一次 `Execute(nil)` 的试探，已移除）

路由与大小写
- 名称/别名匹配是否忽略大小写由 ArgsOptions.CaseInsensitiveKeys 控制
- 处理 `--`：其后的 token 全视为位置参数，不再解析为选项

返回码建议
- 0: 成功（CMD_OK）
- 非 0：命令未找到、参数错误等（由具体处理器定义）


默认子命令（Default Subcommand）
- 为任意节点设置默认子命令名：SetDefaultChildName('list')
- 路由逻辑：当匹配到某节点后，如果后续没有非选项 token（或下一个 token 为选项），将回退到该节点的 DefaultChild 执行
- 该行为便于实现诸如 `git remote` → `git remote list`

Usage 生成
- 调用 Usage() 返回当前节点直接子命令的 “name: description” 列表（逐行）
- 用途：供调用方在 `-h/--help` 或错误时展示

诊断辅助
- GetBestMatchPath(Root, Args, Opts)：从首个非选项 token 起，按名称或别名逐层匹配，遇到选项即停止；若后续无非选项 token 且存在 DefaultChild，则回退到默认子命令。

注意
- 自动帮助（检测 -h/--help 或无效路径时自动打印）不在本模块实现范畴，应由调用方根据需要调用 Usage() 并控制返回码


调用方处理帮助/错误的最小示例（示意）

```pascal
// 假设 Root: IRootCommand 已构建完成
function ArgvHasHelp: boolean;
var i: Integer; s: string;
begin
  for i := 1 to ParamCount do begin s := ParamStr(i); if (s='-h') or (s='--help') then Exit(True); end;
  Exit(False);
end;

function ResolveNodeForHelp(const Root: IRootCommand; CaseInsensitive: boolean): IBaseCommand;
var i, idx: Integer; cur, nextC: ICommand; t: string;
begin
  Result := Root; cur := nil; idx := -1;
  for i := 1 to ParamCount do begin t := ParamStr(i); if (t<>'') and (t[1]<>'-') and (t[1]<>'/') then begin idx := i; Break; end; end;
  if idx<0 then Exit;
  while (idx<=ParamCount) do begin t := ParamStr(idx); if (t='') or (t[1]='-') or (t[1]='/') then Break;
    if cur=nil then nextC := Root.FindChild(t, CaseInsensitive) else nextC := cur.FindChild(t, CaseInsensitive);
    if nextC=nil then Break; cur := nextC; Inc(idx); end;
  if cur<>nil then Result := cur;
end;

var opts: TArgsOptions; code: Integer;
begin
  opts := ArgsOptionsDefault;
  if ArgvHasHelp then begin
    Writeln(ResolveNodeForHelp(Root, opts.CaseInsensitiveKeys).Usage);
    Halt(2);
  end;
  code := Root.Run(opts);
  if code<>0 then begin
    Writeln('Error code: ', code);
    Writeln(Root.Usage);
  end;
  Halt(code);
end;
```

测试覆盖
- Test_DeepPath_Positional_And_Literal：验证 `--` 后的 token 进入位置参数
- Test_Alias_Matching：别名与主名一致匹配
- Test_Unlimited_Depth_ThreeLevels：深路径匹配
- Test_RunPath_Disambiguated：RunPath 显式路径执行
- Test_AddChild_DuplicateName_Raises：重复名报错
- Test_Register_Alias_Union_Works：别名并集
- Test_Register_Handler_FirstWins：处理器先到先得
- Test_Register_NoExecuteOnMerge：Register 不执行处理器

后续演进（建议）
- 默认子命令（如仅 `remote` 时自动进入 `remote list`）
- 自动 Help/Usage 生成，与 fafafa.core.term 协作
- 更丰富的错误码与诊断

