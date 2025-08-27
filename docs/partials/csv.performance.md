# CSV 性能最佳实践

## Reader：BufferSize 与读取策略
- 默认 64KB；常见建议 256KB 作为起点，NVMe/顺序读可试 1MB
- 大文件建议优先使用 ReadNext 流式处理；仅在可控规模使用 ReadAll
- 混合换行/多行字段已走快路径；仍建议合理的 BufferSize 以降低 I/O 次数

## UTF-8 策略的权衡
- StrictUTF8=True：
  - 优点：数据质量可控；非法序列立即抛错
  - 代价：全量校验开销↑；对极端长字段会更敏感
- ReplaceInvalidUTF8=True：
  - 优点：鲁棒性；不因单个坏字节中断流程
  - 代价：内容被替换；需要上层做好告警/统计
- 默认（两者 False）：
  - 可能依赖 RTL 的宽容行为；生产建议二选一以消除不确定性

## Writer：批量与内存复用
- 复用 Writer 实例与内部行缓冲；避免每行创建/销毁对象
- 批量写（WriteAll/WriteAllU）优先于逐行写；单行较长时一次性写入
- 终止符：Terminator 显式配置优先于 UseCRLF；跨平台建议统一使用 LF（csvTermLF）


## 零拷贝与记录复用（实现）
- 单行连续缓冲 + offset/len 索引：解析时将每个字段的 UTF-8 字节追加到单条记录缓冲中
- ICSVRecord.GetFieldSlice(Index, out PAnsiChar, out Len)：零拷贝返回该字段切片；仅在“下一次 ReadNext 前”有效
- ICSVRecord.TryGetFieldBytes(Index, out RawByteString)：创建字节副本，可跨记录持有
- CSVReaderBuilder.ReuseRecord(True)：复用同一记录实例，减少对象分配；注意复用会使旧切片在下一次 ReadNext 后立即失效
- 实践建议：
  - 热路径尽量用切片，跨记录或跨线程前再复制
  - 严格区分“读完即处理”与“需要保留”的业务片段
  - 大字段场景配合合理的 BufferSize 以平衡 I/O 与内存

## 未来：零拷贝与记录复用（规划）
- ReuseRecord（Reader）与零拷贝字段访问接口将提供更低分配路径
- 使用提醒：启用复用后，跨次 ReadNext 若需保留值需主动复制

## 工具与基准
- play/fafafa.core.csv/ 下提供生成/读取微基准工具
- 建议在真实数据规模上验证 BufferSize 与 UTF-8 策略的影响

