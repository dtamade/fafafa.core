# fafafa.core.time 快速改进实施指南

## 第一步：定义统一的错误类型

在 `fafafa.core.time.base.pas` 中添加：

```pascal
type
  TTimeErrorKind = (
    tekOverflow,      // 算术溢出
    tekUnderflow,     // 算术下溢  
    tekInvalidFormat, // 格式错误
    tekSystemError,   // 系统调用失败
    tekCancelled      // 操作被取消
  );

  // 使用已有的 Result 类型
  TDurationResult = specialize TResult<TDuration, TTimeErrorKind>;
  TInstantResult = specialize TResult<TInstant, TTimeErrorKind>;
```

## 第二步：为 Duration 添加安全方法

在 `fafafa.core.time.duration.pas` 中扩展：

```pascal
type
  TDuration = record
    // ... 现有成员 ...
    
    // 新增安全方法
    function TryAdd(const Other: TDuration): TDurationResult;
    function TrySub(const Other: TDuration): TDurationResult;
    function TryMul(Factor: UInt32): TDurationResult;
    
    // 饱和算术（永不失败）
    function SafeAdd(const Other: TDuration): TDuration;
    function SafeSub(const Other: TDuration): TDuration;
  end;

implementation

function TDuration.TryAdd(const Other: TDuration): TDurationResult;
begin
  if FNs > High(Int64) - Other.FNs then
    Result := TDurationResult.Err(tekOverflow)
  else
    Result := TDurationResult.Ok(TDuration.FromNs(FNs + Other.FNs));
end;

function TDuration.SafeAdd(const Other: TDuration): TDuration;
begin
  if FNs > High(Int64) - Other.FNs then
    Result := TDuration.FromNs(High(Int64))  // 饱和到最大值
  else
    Result := TDuration.FromNs(FNs + Other.FNs);
end;
```

## 第三步：测试新功能

创建测试用例：

```pascal
procedure TestSafeArithmetic;
var
  D1, D2, D3: TDuration;
  R: TDurationResult;
begin
  D1 := TDuration.FromSec(High(Int64) div 2);
  D2 := TDuration.FromSec(High(Int64) div 2 + 1);
  
  // 测试溢出检测
  R := D1.TryAdd(D2);
  Assert(R.IsErr);
  Assert(R.UnwrapErr = tekOverflow);
  
  // 测试饱和算术
  D3 := D1.SafeAdd(D2);
  Assert(D3.AsSec = High(Int64) div 1000000000);  // 饱和到最大值
end;
```

## 第四步：逐步迁移现有代码

示例迁移路径：

```pascal
// 旧代码（可能溢出）
var
  Total: TDuration;
begin
  Total := D1 + D2;  // 可能溢出
end;

// 新代码方案1：使用 Result
var
  Total: TDuration;
  R: TDurationResult;
begin
  R := D1.TryAdd(D2);
  if R.IsOk then
    Total := R.Unwrap
  else
    // 处理溢出
    raise ETimeError.Create('Duration overflow');
end;

// 新代码方案2：使用饱和算术
var
  Total: TDuration;
begin
  Total := D1.SafeAdd(D2);  // 永不失败，溢出时饱和
end;
```

## 快速验证清单

- [ ] 错误类型定义完成
- [ ] Duration.TryAdd/TrySub 实现
- [ ] Duration.SafeAdd/SafeSub 实现
- [ ] 基础单元测试通过
- [ ] 文档更新

## 注意事项

1. **保持兼容性**：不要修改现有的 `+` `-` 操作符行为
2. **命名一致**：使用 `Try` 前缀表示返回 Result，`Safe` 前缀表示饱和算术
3. **逐步推进**：先实现 Duration，成功后再扩展到 Instant

## 预期收益

- 🛡️ **更安全**：编译时和运行时都能捕获溢出错误
- 🎯 **更明确**：用户可以选择合适的错误处理策略
- ✅ **兼容性**：现有代码无需修改即可继续工作
