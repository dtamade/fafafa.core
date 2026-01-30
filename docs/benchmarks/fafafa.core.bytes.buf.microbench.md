# Bytes/ByteBuf 微基准（v1 草案）

目标
- 评估以下路径的相对耗时与增长策略影响：
  1) BytesConcat vs TBytesBuilder.Append（小块/大块）
  2) ByteBuf EnsureWritable 增长策略（1.5x）对连续写的影响
  3) ByteBuf ReadBytes/WriteBytes 与 Compact 前后的行为

方法
- Lazarus 控制台工程，单线程，同一次进程内重复多次取中位数
- 数据规模：
  - 小块：每次 16B，累计 64KB
  - 大块：每次 4KB，累计 8MB
- 指标：平均耗时（ms），吞吐（MB/s），ops/s

注意
- 仅关注相对趋势，不追求绝对值
- 关闭调试符号可作为可选对照

结果记录模板
- BytesConcat(16B x 4k) vs Builder.Append(16B x 4k)
- EnsureWritable(1.5x growth) 连续写 8MB
- ReadBytes/WriteBytes + Compact 前后对比

