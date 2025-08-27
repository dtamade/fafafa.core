# fafafa.core.id.snowflake — 64 位 Snowflake ID（41/10/12）

## 布局
- 41 位时间戳（毫秒，基于 epoch）
- 10 位 workerId（节点/进程）
- 12 位序列号（同毫秒内递增）

默认 epoch：1288834974657（Twitter）。

## API
```pascal
// 构造与解析
function CreateSnowflake(AWorkerId: Word = 0; AEpochMs: Int64 = 1288834974657): ISnowflake;
function CreateSnowflakeEx(const Config: TSnowflakeConfig): ISnowflake;
function Snowflake_TimestampMs(AId: TSnowflakeID; AEpochMs: Int64 = 1288834974657): Int64;
function Snowflake_WorkerId(AId: TSnowflakeID): Word;
function Snowflake_Sequence(AId: TSnowflakeID): Word;
```

## 策略
- 线程安全：临界区保护，适合单进程多线程
- 回拨策略：wait-on-backward（等待时间追平）或 throw（抛出异常）
- 溢出策略：同毫秒内序列满 4095 时，等待下一毫秒

## 配置（TSnowflakeConfig）
- EpochMs: Int64（默认 1288834974657）
- WorkerId: Word（0..1023）
- BackwardPolicy: sbWait/sbThrow（默认 sbWait）

## 建议
- 配置 workerId 的来源（环境变量/配置中心/进程参数）
- 若部署在多进程/多机，确保 workerId 唯一
- 如需自定义 epoch/位宽布局，可在后续提供 TSnowflakeConfig 实现

## 部署建议
- 时钟同步：确保各节点启用 NTP/Chrony，漂移控制在毫秒级；监控时间回拨事件
- workerId 分配：集中配置或注册中心分配（避免冲突）；建议在应用启动时打印当前配置以便审计
- 回拨策略：
  - sbWait：出现回拨时阻塞等待；适合对可用性更敏感的服务
  - sbThrow：出现回拨时抛出异常并上报告警；适合对一致性要求极高的批处理任务
- 指标与告警：统计每秒生成量、等待次数、回拨触发次数、序列溢出等待次数



## 配置来源与最佳实践

- 配置来源优先级（建议）：
  1) 进程参数（--worker-id / --sf-epoch-ms）
  2) 环境变量（FA_SF_WORKER_ID / FA_SF_EPOCH_MS）
  3) 配置文件或配置中心（如未设置则使用默认）
- 启动打印：应用启动时打印当前 workerId、epoch 与回拨策略，便于审计与故障排查
- 冲突防护：部署/容器编排层面保证单 workerId 唯一；必要时可在启动阶段尝试注册占位
- 回拨策略建议：
  - 线上服务：sbWait（避免抛错中断）
  - 离线批处理/强一致任务：sbThrow（尽早感知并中止流程）
- 监控与压测：
  - 指标：每秒生成量、wait-on-backward 触发次数、序列溢出等待次数
  - 压测：同毫秒内大并发生成（>4096）是否会退避等待下一毫秒

### 伪代码示例（配置读取）
```pascal
var cfg: TSnowflakeConfig; wid: Integer; ep: Int64; pol: TSnowflakeBackwardPolicy;
begin
  // 进程参数/环境变量读取（伪代码）
  wid := ReadIntParamOrEnv('--worker-id', 'FA_SF_WORKER_ID', 0);
  ep  := ReadInt64ParamOrEnv('--sf-epoch-ms', 'FA_SF_EPOCH_MS', 1288834974657);
  pol := sbWait; // or sbThrow
  cfg.WorkerId := wid; cfg.EpochMs := ep; cfg.BackwardPolicy := pol;
  // 创建生成器
  CreateSnowflakeEx(cfg);
end;
```

## 示例工程
- Windows 一键脚本：examples/fafafa.core.id/BuildOrRun.bat
  - 将构建并运行 example_id.exe 与 example_snowflake_config.exe
  - 自定义参数示例：example_snowflake_config.exe --worker-id=2 --sf-epoch-ms=1288834974657
- Linux/macOS 一键脚本：examples/fafafa.core.id/BuildOrRun.sh
  - 运行：bash BuildOrRun.sh
  - 自定义参数：在脚本内或命令行设置 FA_SF_WORKER_ID / FA_SF_EPOCH_MS / FA_SF_THROW 或传参 --worker-id/--sf-epoch-ms

