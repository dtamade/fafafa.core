# 常见问题（FAQ）

本页集中回答使用者在各子系统中常见的问题。首批条目覆盖 fafafa.core.fs。

## fafafa.core.fs

### 1) WalkDir 开启 OnError=weaContinue 后，为什么 `WalkDir('invalid_root', ...)` 返回 0？
- 语义：`weaContinue` 表示忽略该错误并继续遍历；当根路径本身无效时，整体等价于“空遍历”，因此返回 0。
- 默认行为（OnError=nil）：保持旧语义，根路径无效时直接返回统一负错误码（便于调用方快速失败）。
- 建议：若需要记录错误但不中止，可在 `OnError` 回调中记录后返回 `weaContinue`；对特定目录返回 `weaSkipSubtree` 可跳过当前子树。

最小示例：

```pascal
function TWalker.OnErrContinue(const Path: string; Error, Depth: Integer): TFsWalkErrorAction;
begin
  Result := weaContinue;
end;

procedure TWalker.Run;
var Opts: TFsWalkOptions; Rc: Integer;
begin
  Opts := FsDefaultWalkOptions; Opts.OnError := @OnErrContinue;
  Rc := WalkDir('Z:\not_exists', Opts, @OnVisit);
  // Rc = 0（根无效但被 continue 策略忽略）
end;
```

### 2) OpenFileEx 的异常释放语义是什么？
- `OpenFileEx(Path, Opts): IFsFile` 使用给定选项打开并返回 IFsFile。
- 若打开失败会抛出 `EFsError`，并保证异常路径释放内部实例，避免资源泄漏（工厂内 `try..except` 处理）。
- 便捷构造：`FsOptsReadOnly / FsOptsWriteTruncate / FsOptsReadWrite` 为 `FsOpenOptions_*` 的简写别名。

### 3) Windows 共享模式（TFsShareMode）如何映射？
- Windows：映射到 CreateFileW 的共享标志（FILE_SHARE_READ/WRITE/DELETE）。
- Unix：无文件共享标志，`TFsShareMode` 当前被忽略；若需要共享语义，建议在更高层使用建议性锁（fcntl）。

更多内容：
- README_fafafa_core_fs.md（模块说明、使用示例、统计与错误模型）
- docs/API.md（API 参考，含 OnError 简述与 OpenFileEx/FsOpts*）
- docs/EXAMPLES.md（完整示例与 FAQ/Troubleshooting 片段）



## fafafa.core.socket

### 1) Windows 控制台/重定向下出现 EInOutError: Disk Full？
- 现象：运行示例（如 echo_client.exe）时，控制台打印异常消息后抛出 EInOutError: Disk Full
- 说明：这是控制台/管道 I/O 写入失败的通用文案，并非磁盘真实已满；常见于编码/重定向/管道场景
- 解决：
  - 确保测试工程与单元使用 {$CODEPAGE UTF8}（本仓库 socket 测试工程已设置）
  - 在 Windows 下设置 UTF-8 输出：SetConsoleOutputCP(65001) 且 SetTextCodePage(Output/StdErr, 65001)
  - 优先使用最小示例（非阻塞+轮询）：examples\\fafafa.core.socket\\run_example_min.bat（或 Linux/macOS 下 run_example_min.sh）

### 2) 如何快速验证非阻塞 + 轮询通路？
- 一键脚本：
  - Windows：examples\\fafafa.core.socket\\run_example_min.bat
  - Linux/macOS：./examples/fafafa.core.socket/run_example_min.sh
- 行为：若缺少可执行会自动构建，启动 echo_server（8080），并运行 example_echo_min_poll_nb（recv: hello）
