# fafafa.core.process FAQ（Pipeline 常见问题与最佳实践）

本文补充 Pipeline 在实际使用中的注意事项与建议配置，配合主文档 `docs/fafafa.core.process.md` 一起阅读。

## 1. CaptureOutput 与 RedirectStdOutToFile 是否可以同时使用？
- 不建议同时使用。两者都是 stdout 的消费端：
  - CaptureOutput：将 stdout 收集到内存字符串，适合体量小、需要直接处理输出的场景；
  - RedirectStdOutToFile：将 stdout 直接落盘，适合体量大或需要持久化的场景。
- 如果确实要两者兼具，建议优先 Redirect 到文件，再由上层读文件处理；避免内存与文件双重消费导致语义混乱。

## 2. MergeStdErr 的行为与限制？
- MergeStdErr(True) 表示将 stderr 合流到 stdout；
  - 当 CaptureOutput=True：最终的 Output 会包含两者（按到达顺序）；
  - 当 Redirect 到文件：需要分别为 stdout/stderr 指定路径；MergeStdErr 对文件重定向不生效。
- 注意：合流后无法区分来源通道，如需区分，请不要合并，分别处理 stdout/stderr。

## 3. FailFast 的语义是什么？
- 任一阶段非零退出或启动失败时，管线会尽快终止其他阶段（KillAll），并设置 Success=False；
- 建议在 WaitForExit 之后读取：
  - Status（汇总状态）与 Success（是否整体成功）
  - Output（若 CaptureOutput=True 且可能 MergeStdErr=True）
- 对于长流水线，FailFast 可节约资源并缩短失败反馈时间。

## 4. WaitForExit 与“排水”（Auto-Drain）
- 默认开启宏 `FAFAFA_PROCESS_AUTO_DRAIN_ON_WAIT`：Wait 前会自动排水，避免因管道缓冲区满导致死锁；
- 若禁用该宏，需确保读取端持续消费输出；否则 Wait 可能阻塞。

## 5. Windows 与 Unix 的 PATH 搜索差异
- Windows：支持 PATHEXT（如 .EXE;.BAT;.CMD），`UsePathSearch(True)` 会附加扩展名尝试；
- Unix：不涉及 PATHEXT；必须具备可执行权限（`chmod +x`）。

## 6. 环境块（Environment Block）最佳实践
- Windows：内部构造 Unicode 环境块，排序、去重，并以双零终止结尾；尽量避免过大的单变量值与过多变量以免接近系统限制；
- Unix：使用键值对复制；注意变量名/值的转义需求由调用方保证。

## 7. 超时与中断
- WaitForExit(TimeoutMs)：在超时后返回 False，不会自动 Kill 进程；如需强制终止，调用 Kill/KillAll；
- 建议在高层封装中实现“超时→优雅终止→强杀”的分级策略（例如先发送 terminate，再等待，再 kill）。

## 8. 常见调试建议
- 启用宏 `FAFAFA_PROCESS_VERBOSE_LOGGING`（Debug 下自动）以获取启动参数、句柄、管道等信息；
- 发生“无输出/卡住”时，优先检查是否消费了 stdout/stderr；
- 遇到 PATH 搜索失败，打印 `PATH` 与 `PATHEXT`（Windows）并尝试绝对路径调用。

## 9. 示例参考
- example_pipeline_failfast：展示 CaptureOutput + MergeStdErr + FailFast 的组合与汇总状态读取；
- 更多示例可按需扩展：将输出重定向到文件、只捕获错误流等。



## 10. 示例：stdout 重定向到文件 + 仅捕获 stderr
- 参考 `examples/fafafa.core.process/example_redirect_file_and_capture_err.pas`
- 关键配置：
  - 使用 `RedirectStdOut(True)` + `RedirectStdErr(True)`；
  - 启用 `DrainOutput(True)`，避免无人消费导致阻塞；
  - 等待 `WaitForExit()` 后，从 `Child.StandardError` 读取错误输出，并将 `StandardOutput` 写入文件；
- Windows/Linux 均可运行，注意替换 shell 命令细节。
