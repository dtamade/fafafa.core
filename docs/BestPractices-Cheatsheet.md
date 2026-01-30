# fafafa.core.fs 最佳实践 Cheatsheet

简明可复制的代码模板与要点，覆盖 WalkDir、IFsFile、共享模式、错误处理、路径安全与性能。

## WalkDir 快速指引
- 大目录，省内存：UseStreaming=True，Sort=False（非稳定顺序）
- 需要稳定顺序：Sort=True（使用缓冲+排序）
- 剪枝优先：PreFilter 过滤整棵子树（如 .git、node_modules）
- 结果筛选：PostFilter（不影响递归）
- 控制规模：合理设置 MaxDepth
- 统计：传入 Stats 指针收集 Dirs/Files/Errors

模板：流式遍历（不排序）
```pascal
function OnVisit(const APath: string; const AStat: TfsStat; ADepth: Integer): Boolean;
begin
  // TODO: 处理文件/目录；返回 False 可早停
  Result := True;
end;

function PreSkipHidden(const APath: string; ABasic: TfsDirEntType; ADepth: Integer): Boolean;
var name: string;
begin
  name := ExtractFileName(APath);
  Result := (name = '') or (name[1] <> '.');
end;

var opts: TFsWalkOptions; rc: Integer;
begin
  opts := FsDefaultWalkOptions;
  opts.UseStreaming := True;   // 流式
  opts.Sort := False;          // 不排序
  opts.PreFilter := @PreSkipHidden; // 剪枝
  rc := WalkDir('root', opts, @OnVisit);
end;
```

模板：缓冲+稳定排序
```pascal
var opts: TFsWalkOptions; rc: Integer;
begin
  opts := FsDefaultWalkOptions;
  opts.Sort := True; // 稳定排序
  rc := WalkDir('root', opts, @OnVisit);
end;
```

## IFsFile 快速指引
- 打开模式：
  - fomRead（只读）
  - fomWrite（只写+截断）
  - fomReadWrite（读写，若无则创建）
  - fomAppend（追加写）
- 字符串/编码：显式 TEncoding，避免隐式转换
- 随机 I/O：优先 PRead/PWrite（未实现则自动回退到 Seek+Read/Write）

模板：基本读写
```pascal
var F: IFsFile; buf: array[0..4095] of Byte; n: Integer;
begin
  F := NewFsFile;
  F.Open('data.bin', fomReadWrite);
  try
    n := F.Read(buf, SizeOf(buf));
    // ...处理...
    F.Write(buf, n);
    F.Flush;
  finally
    F.Close;
  end;
end;
```

## 共享模式（Windows）
- 集合语义：set of (fsmRead, fsmWrite, fsmDelete)
- Windows：映射到 CreateFileW 的 FILE_SHARE_READ/WRITE/DELETE
- Unix：当前忽略共享标志（无等价共享位）
- 兼容：传 [] 时默认“全共享”（READ|WRITE|DELETE）

常用组合
```pascal
// 只读并仅共享读：拒绝其他写者
F.Open('x.bin', fomRead, [fsmRead]);

// 读写并共享读写：允许另一个只读句柄并存
F.Open('x.bin', fomReadWrite, [fsmRead, fsmWrite]);

// 禁止被删除：不要包含 fsmDelete
F.Open('x.bin', fomReadWrite, [fsmRead, fsmWrite]);
```

## 错误处理
- 异常语义（推荐）：捕获 EFsError，基于 ErrorCode 分类（NotFound/Permission/Exists/Invalid/IO）
```pascal
try
  F.Open('maybe.bin', fomRead);
except
  on E: EFsError do
  begin
    // case E.ErrorCode of ...
  end;
end;
```
- 无异常语义：TFsFileNoExcept 返回统一负码；使用 IsNotFound/IsPermission 等工具函数

## 路径安全
- 永远 ValidatePath；外部输入先 SanitizePath / SanitizeFileName
- 组合路径用 Join/Normalize/ToNativePath；避免手工拼接分隔符
- 比较路径用 PathsEqual（Windows 不区分大小写）

## Symlink 与深度控制
- 默认不跟随符号链接；需要时显式 FollowSymlinks
- 配合 MaxDepth 使用；避免陷入深链或环

## 性能建议
- WalkDir：UseStreaming=True + PreFilter 剪枝；仅需文件或目录时关闭另一类（IncludeFiles/IncludeDirs）
- I/O：合并小写入；必要时用带缓冲的实现；避免热路径分配
- 字符串：复用缓冲；避免频繁编码转换

## 测试建议（fpcunit）
- 临时目录：随机名 + try-finally 清理
- 条件编译：符号链接与共享模式在 Windows/Unix 分支下分别断言
- 稳定性比较：集合一致用排序后比较，避免顺序敏感
- 启用 heaptrc（FPC）检测泄漏

## 终端测试（fafafa.core.term）速查
- 交互判定：TestEnv_AssumeInteractive(Self)；不满足则 TestSkip 并 Exit
- 初始化作用域：term_init; try ... finally term_done; end;
- 常见判据：IsATTY → term_size>0 → term_name 非空且非 unknown
- 功能检测：term_support_* 判真再调用；并做好恢复（如 alt screen/mouse）
- Skip 兼容：优先 ESkipTest；旧版回退软 Skip（输出 "SKIP: ..."）

模板：最小交互用例
```pascal
if not TestEnv_AssumeInteractive(Self) then Exit;
term_init; try
  CheckTrue(term_clear);
finally
  term_done;
end;
```

## JSON（Reader/Pointer）小抄
- Reader Flags：AllowComments/AllowTrailingCommas/AllowBOM/StopWhenDone 按需组合
- Pointer 注意：空指针 "" 返回根；单独 "/" 与双斜杠空 token（如 "/a//x"）非法返回 nil；~0→~，~1→/（详见 docs/fafafa.core.json.md）

---
本 Cheatsheet 搭配 docs/API.md 与 docs/fafafa.core.fs.ifile.md 使用，涵盖更多选项与平台差异说明。
