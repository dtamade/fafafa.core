# fafafa.core.sync.namedEvent 示例

本目录包含 `fafafa.core.sync.namedEvent` 模块的完整使用示例，展示了命名事件在各种场景下的应用。

## 📁 示例文件

| 文件名 | 描述 | 适用场景 |
|--------|------|----------|
| `example_basic_usage.lpr` | 基本使用示例 | 学习基础API和概念 |
| `example_multithreading.lpr` | 多线程并发示例 | 线程间同步 |
| `example_crossprocess_producer.lpr` | 跨进程生产者 | 进程间通信 |
| `example_crossprocess_consumer.lpr` | 跨进程消费者 | 进程间通信 |

## 🚀 快速开始

### Windows
```batch
# 编译并运行所有示例
BuildAndRun.bat

# 或者手动编译单个示例
fpc -Mobjfpc -Sh -Fu../../src example_basic_usage.lpr
example_basic_usage.exe
```

### Linux/Unix
```bash
# 编译并运行所有示例
chmod +x BuildAndRun.sh
./BuildAndRun.sh

# 或者手动编译单个示例
fpc -Mobjfpc -Sh -Fu../../src example_basic_usage.lpr
./example_basic_usage
```

## 📖 示例详解

### 1. 基本使用示例 (`example_basic_usage.lpr`)

演示命名事件的基础功能：
- ✅ 创建和配置命名事件
- ✅ 手动重置 vs 自动重置事件
- ✅ RAII 模式的守卫使用
- ✅ 超时机制
- ✅ 错误处理

**关键概念：**
- `INamedEvent` - 命名事件接口
- `INamedEventGuard` - RAII 守卫
- `CreateNamedEvent()` - 创建事件
- `TryWaitFor()` - 带超时等待

### 2. 多线程示例 (`example_multithreading.lpr`)

展示多线程环境下的事件同步：
- 🔄 手动重置事件的广播机制
- 🎯 自动重置事件的竞争机制
- 📊 线程性能统计

**适用场景：**
- 生产者-消费者模式
- 工作线程池同步
- 任务分发系统

### 3. 跨进程通信示例

#### 生产者 (`example_crossprocess_producer.lpr`)
- 📦 模拟数据生产
- 📢 通知数据就绪
- ⏳ 等待处理完成确认

#### 消费者 (`example_crossprocess_consumer.lpr`)
- 👂 监听数据就绪事件
- ⚙️ 处理接收到的数据
- ✅ 发送处理完成通知

**运行方式：**
```bash
# 终端1：启动消费者
./example_crossprocess_consumer

# 终端2：启动生产者
./example_crossprocess_producer
```

## 🎯 最佳实践

### 1. RAII 模式使用
```pascal
var
  LGuard: INamedEventGuard;
begin
  LGuard := LEvent.Wait;
  try
    // 处理事件
  finally
    LGuard := nil; // 自动清理
  end;
end;
```

### 2. 选择合适的事件类型
- **手动重置**：状态通知，多个等待者同时响应
- **自动重置**：任务分发，只有一个等待者响应

### 3. 合理设置超时
```pascal
// 快速检查
LGuard := LEvent.TryWaitFor(0);

// 正常等待
LGuard := LEvent.TryWaitFor(5000);

// 无限等待（谨慎使用）
LGuard := LEvent.Wait;
```

### 4. 错误处理
```pascal
try
  LEvent := CreateNamedEvent('MyEvent');
except
  on E: EInvalidArgument do
    // 处理无效参数
  on E: ELockError do
    // 处理系统错误
end;
```

## 🔧 故障排除

### 常见问题

1. **编译错误：找不到单元**
   - 确保 `-Fu../../src` 参数正确
   - 检查 fafafa.core 源码路径

2. **运行时错误：权限不足**
   - Linux: 检查共享内存权限
   - Windows: 可能需要管理员权限

3. **跨进程示例无响应**
   - 确保先启动消费者，再启动生产者
   - 检查防火墙设置

4. **超时频繁发生**
   - 增加超时时间
   - 检查系统负载

### 调试技巧

1. **启用详细日志**
```pascal
{$IFDEF DEBUG}
WriteLn('事件状态: ', LEvent.IsSignaled);
WriteLn('事件类型: ', IfThen(LEvent.IsManualReset, '手动', '自动'));
{$ENDIF}
```

2. **性能监控**
```pascal
LStartTime := Now;
LGuard := LEvent.TryWaitFor(1000);
LElapsed := (Now - LStartTime) * 24 * 60 * 60 * 1000;
WriteLn('等待时间: ', LElapsed:0:1, ' ms');
```

## 📚 相关文档

- [API 参考](../../docs/fafafa.core.sync.namedEvent.md)
- [单元测试](../../tests/fafafa.core.sync.namedEvent/)
- [性能基准](../../benchmarks/fafafa.core.sync.namedEvent/)

## 🤝 贡献

欢迎提交新的示例或改进现有示例！请确保：
- 代码风格一致
- 包含详细注释
- 添加错误处理
- 更新相关文档
