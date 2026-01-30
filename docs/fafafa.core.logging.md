# fafafa.core.logging — 设计与用法（M1）

目标
- 结构化、可扩展、跨平台的日志框架；接口优先
- 借鉴 Rust tracing、Go slog、Java SLF4J/Logback
- M1：最小可用（接口 + Facade + ConsoleSink + TextFormatter + SimpleLogger）

核心概念
- ILogger：应用调用入口（Trace/Debug/Info/Warn/Error；WithAttrs）
- ILogRecord：不可变记录对象（时间/级别/名称/模板/渲染/attrs/线程）
- ILogSink：写出目标（M1 提供 Console）
- ILogFormatter：格式化（M1 提供 Text/JSON）
- ILoggerFactory：按名称获取 logger；配置最小级别

快速开始
```pascal
uses fafafa.core.logging, fafafa.core.logging.interfaces;
var L: ILogger;
begin
  Logging.SetMinimumLevel(llDebug);
  L := GetLogger('app');
  L.Info('hello %s', ['world']);
end.
```

结构化属性
- TextFormatter 会追加 `key=value` 列表；JsonFormatter 输出到 attrs 对象
- 构造属性：`LogAttr('user','alice')`；可用 `WithAttrs` 绑定上下文属性

扩展点
- Sink：自定义 ILogSink（Async/Rolling/File/Composite）
- Formatter：自定义 ILogFormatter（JSON/自定义文本）

便捷用法
- 异步 Console 根：`EnableAsyncRoot(1024, 64)`
- 异步滚动文件根：`EnableAsyncRollingFileRoot('app.log', 10*1024*1024, 4096, 128)`
- Console + 滚动文件复合：`EnableConsoleAndRollingRoot('app.log', 10*1024*1024, 4096, 128)`
- 统计查询：`TryGetRootSinkStats(stats)`（若当前根支持 ILogSinkStats）

设计约束
- 库内不输出中文文本；测试/示例可用 UTF-8
- 线程安全：ConsoleSink 以临界区保护 WriteLn；异步 Sink 有界队列+后台线程（使用“可用空间/非空”信号量，避免忙等）

清理策略（Rolling）
- Size Rolling（TRollingTextFileSink）：
  - MaxFiles：保留的历史文件个数（默认 0 关闭）
  - MaxTotalBytes：所有历史文件总大小上限（默认 0 关闭）
  - 两者并行生效：先满足 MaxFiles（从旧到新删除），再按 MaxTotalBytes（从旧到新删除至不超限）
- Daily Rolling（TRollingDailyTextFileSink）：
  - 命名：base.log.YYYYMMDD（建议 size/daily 不混用同前缀，以免清理范围混淆）
  - MaxFiles：保留最近 N 个文件（默认 7）
  - MaxDays：仅保留最近 N 天（默认 0 关闭），与 MaxFiles 并行生效；阈值计算为保留 [Today-(MaxDays-1), Today]，删除更早的文件

统计与退出建议（异步 Sink）
- Enqueued、Dequeued、DroppedNew、DroppedOld、WaitAttempts、MaxQueueSize
- WaitAttempts：ldpBlock 下等待次数（使用容量信号量，不忙等）
- 退出建议：程序退出前调用 `Logging.GetRootSink.Flush; Logging.SetRootSink(nil)` 以确保后台线程与句柄释放
- 退出建议：程序退出前调用 `Logging.GetRootSink.Flush; Logging.SetRootSink(nil)` 以确保后台线程与句柄释放
- 通过 TryGetRootSinkStats(out stats) 获取；便于做健康度观测与告警

示例（便捷函数）
- EnableAsyncRoot(1024, 64)
- EnableAsyncRollingFileRoot('app.log', 10*1024*1024, 4096, 128)
- EnableAsyncDailyRollingFileRoot('app.log', 7, 4096, 128)

实用示例（FlushPolicy 与结构化属性）
  // 也可用时间窗触发
  pol.Enabled := True; pol.MaxLines := 0; pol.MaxIntervalMs := 100;
  inner := TTextSinkLogSink.Create(TRollingTextFileSink.Create('app.log', 10*1024*1024, 5, 0), fmt, pol);
  ```

便捷函数 + FlushPolicy 的配方
- 若想保留便捷函数的同时使用 FlushPolicy，可按如下方式“拼装”根 sink：
  ```pascal
  var pol: TFlushPolicy; fmt: ILogFormatter; inner: ILogSink; async: ILogSink;
  begin
    pol.Enabled := True; pol.MaxLines := 64; pol.MaxIntervalMs := 50;
    fmt := TTextLogFormatter.Create;
    inner := TTextSinkLogSink.Create(TRollingTextFileSink.Create('app.log', 10*1024*1024, 5, 0), fmt, pol);
    async := TAsyncLogSink.Create(inner, 4096, 128, ldpDropOld);
    Logging.SetFormatter(fmt);
    Logging.SetRootSink(async);
  end.
  ```

- FlushPolicy（按条数批量冲刷）
  ```pascal
  uses fafafa.core.logging.sinks.textsink, fafafa.core.logging.formatters.text;
  var pol: TFlushPolicy; fmt: ILogFormatter; inner: ILogSink; root: ILogSink;
  begin
    pol.Enabled := True; pol.MaxLines := 50; pol.MaxIntervalMs := 0;
    fmt := TTextLogFormatter.Create;
    inner := TTextSinkLogSink.Create(TRollingTextFileSink.Create('app.log', 10*1024*1024, 5, 0), fmt, pol);
    root := TAsyncLogSink.Create(inner, 4096, 128, ldpDropOld);
    Logging.SetFormatter(fmt);
    Logging.SetRootSink(root);
  end.
  ```
- 结构化属性（数字/布尔/null）
  ```pascal
  L := GetLogger('svc').WithAttrs([
    LogAttrS('user','alice'),
    LogAttrN('cost_ms', 12.5),
    LogAttrB('ok', True),
    LogAttrNull('trace')
  ]);

过滤与增强（Filter & Enricher）
- 目的
  - Filter：在格式化/输出之前按规则丢弃记录（例如级别、logger 前缀等）
  - Enricher：在最终构建记录前，就地规范/补充属性（当前版本支持“就地修改”，不追加新键）
- 使用
  - 设置：Logging.SetFilter(Obj) / Logging.SetEnricher(Obj)
  - 生效时机：TSimpleLogger.LogAttrs 在合并上下文 + 本次属性后，先 Filter 后 Enricher，再创建最终记录
- 示例
  ```pascal
  type
    TLevelPrefixFilter = class(TInterfacedObject, ILogFilter)

滚动策略：按条数（Count）
- 使用场景：日志行长度波动较大时，希望以“条”为单位进行归档，避免受单行超长影响滚动节奏
- 类型：TRollingCountTextFileSink（base.count-TS）
- 创建示例：
  ```pascal
  var sink: ITextSink;
  sink := TRollingCountTextFileSink.Create('app.log', 10000, 7);
  Logging.SetRootSink(TTextSinkLogSink.Create(sink, TTextLogFormatter.Create));
  ```
- 与 FlushPolicy 配合：
  - FlushPolicy 只影响何时 flush，不影响“按条数”判断；按条数的判断在 WriteLine 时间点进行
- 与 Size/Daily 并行：
  - Count/Size/Daily 为对等策略；建议不同策略使用不同命名前缀，避免清理串扰

    private
      FMin: TLogLevel; FPrefix: string;
    public

写缓冲（可选，默认关闭）
- 目的：减少 WriteBuffer 调用次数，提高吞吐
- 开启方式：TRollingTextFileSink.Create 的最后一个参数 ABufferBytes > 0（例如 16*1024）
- 语义保证：阈值判断会考虑“已落盘 + 缓冲内 + 即将写入”的总和，确保不越界；Flush/Rotate 会优先冲刷缓冲
- 建议：按大小滚动要严控不越界时，缓冲可设为 8–64KB；若非常敏感（每行都要即刻可见），保持 0（禁用）

      constructor Create(AMin: TLogLevel; const APrefix: string);
      function Allow(const R: ILogRecord): Boolean;
    end;
  constructor TLevelPrefixFilter.Create(AMin: TLogLevel; const APrefix: string);
  begin FMin := AMin; FPrefix := APrefix; end;
  function TLevelPrefixFilter.Allow(const R: ILogRecord): Boolean;
  begin
    Result := (Ord(R.Level) >= Ord(FMin)) and
              ((FPrefix = '') or (Pos(FPrefix + '.', R.LoggerName) = 1) or (R.LoggerName = FPrefix));
  end;

  type
    TTraceIdEnricher = class(TInterfacedObject, ILogEnricher)
    private
      FTrace: string;
    public
      constructor Create(const ATrace: string);
      procedure Enrich(var Attrs: array of TLogAttr);
    end;
  constructor TTraceIdEnricher.Create(const ATrace: string);
  begin FTrace := ATrace; end;
  procedure TTraceIdEnricher.Enrich(var Attrs: array of TLogAttr);
  var i: Integer;
  begin
    // 就地修改（示例：将 trace_id=null 填成具体值）
    for i := 0 to High(Attrs) do
      if SameText(Attrs[i].Key, 'trace_id') and (Attrs[i].Kind = lakNull) then
      begin
        Attrs[i].Kind := lakString;
        Attrs[i].ValueStr := FTrace;
        Break;
      end;
  end;

  // 配置：仅允许 svc.* 且级别>=Info；为 trace_id 预留占位，由 Enricher 填写
  Logging.SetFilter(TLevelPrefixFilter.Create(llInfo, 'svc'));
  Logging.SetEnricher(TTraceIdEnricher.Create('demo-123'));
  GetLogger('svc.api').WithAttrs([LogAttrNull('trace_id')]).Info('hello', []);
  ```
- 备注
  - 追加新键的 Enricher 将在后续版本开放（需要调整接口以支持扩容）；当前建议在 WithAttrs 预留占位键并由 Enricher 填值

  L.Info('done', []);
  ```


性能调参建议
- 异步队列
  - capacity：建议至少高于单帧/批次峰值，常见 1K~16K；batch：64~256 观察吞吐/延迟
  - ldpDropOld 更稳态；追求可靠可用 ldpBlock（配合监控 WaitAttempts）
- FlushPolicy
  - MaxLines：在 Console/文件 IO 繁忙时可显著降低 Flush 次数
  - MaxIntervalMs：避免低频写时长时间无 Flush（建议 50~200ms 级别）
- 滚动
  - Size 与 Daily 不混用同前缀；Size 采用 .size- 命名，避免清理串扰

压测脚本
- examples/fafafa.core.logging/bench_flushpolicy
  - 运行 build.bat 构建；支持参数 N=20000 指定写入条数
  - 脚本将输出各策略的吞吐（KLines/s）与 Flush 次数对比

- EnableAsyncDailyRollingFileRoot('app.log', 7, 14, 4096, 128)
- EnableConsoleAndRollingRoot('app.log', 10*1024*1024, 4096, 128)

