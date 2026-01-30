# 进程模块：句柄所有权与清理顺序

- 设计目标：避免句柄重复关闭，保证异常/半初始化场景也能安全释放。
- 所有权模型：
  - 标准流包装使用 THandleStream；其本身不持有句柄所有权（不负责关闭系统句柄）。
  - 系统句柄的关闭由 TProcess.CleanupResources 统一负责。
- 析构顺序：
  1. 先释放 StandardInput/StandardOutput/StandardError 的流对象以及自动排水缓冲（如有）。
  2. 调用 CleanupResources：
     - 先关闭 AutoDrain 线程相关的读端以促使线程退出；等待线程收敛。
     - 关闭进程与线程句柄；关闭管道两端剩余系统句柄。
- 注意事项：
  - 不要在外部直接关闭内部句柄；如需主动关闭标准输入，请调用 CloseStandardInput（其会安全关闭写端并置位）。
  - AutoDrain 启用时，WaitForExit 会在完成后将缓冲切换为标准流供读取；若自行读取标准流，可能读到 0 字节（数据已在缓冲）。

