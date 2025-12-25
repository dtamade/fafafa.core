# fafafa.core.id.cuid2 模块说明

CUID2 是 CUID 的改进版本，专为安全和抗碰撞设计的唯一 ID 生成器。

## 特性

- 默认 24 字符
- 只包含小写字母和数字
- 首字符保证是字母 (a-z)
- 基于哈希 (SHA256) 的安全设计
- 不可预测、抗碰撞
- 对标: https://github.com/paralleldrive/cuid2

## 快速开始

```pascal
uses fafafa.core.id.cuid2;

var
  Id: string;
begin
  // 默认 24 字符
  Id := Cuid2;  // "clh3am8q0000008mh3qwp3kqg"

  // 自定义长度 (2-32)
  Id := Cuid2(32);  // 更长的版本
  Id := Cuid2(8);   // 更短的版本
end;
```

## CUID2 结构

CUID2 的内部组成（哈希前）：

1. **时间戳**: Unix 毫秒时间戳
2. **计数器**: 原子递增计数器
3. **熵**: 密码学安全随机数据
4. **指纹**: 进程 ID + 随机机器标识

这些组件通过 SHA256 哈希后转换为 Base36 输出。

## 批量生成

```pascal
var
  Ids: TStringArray;
begin
  // 批量生成 100 个 CUID2
  Ids := Cuid2N(100);

  // 批量生成指定长度
  Ids := Cuid2N(100, 16);
end;
```

## 生成器模式

```pascal
var
  Gen: ICuid2Generator;
  Id: string;
  Ids: TStringArray;
begin
  // 创建生成器
  Gen := CreateCuid2Generator(24);

  // 生成单个 ID
  Id := Gen.Next;

  // 批量生成
  Ids := Gen.NextN(100);

  // 动态修改长度
  Gen.Length := 32;
end;
```

## 验证

```pascal
var
  Valid: Boolean;
begin
  // 检查是否为有效 CUID2
  Valid := IsCuid2('clh3am8q0000008mh3qwp3kqg');  // True

  // CUID2 验证规则:
  // - 长度 2-32
  // - 首字符必须是 a-z
  // - 其余字符是 a-z 或 0-9
  Valid := IsCuid2('1abc');  // False (首字符不是字母)
  Valid := IsCuid2('a');     // False (长度 < 2)
end;
```

## CUID2 vs 其他 ID

| 特性 | CUID2 | UUID v4 | NanoID |
|------|-------|---------|--------|
| 默认长度 | 24 | 36 | 21 |
| 字符集 | a-z0-9 | 0-9a-f- | A-Za-z0-9_- |
| 首字符 | 字母 | 任意 | 任意 |
| 可排序 | 否 | 否 | 否 |
| 安全性 | 哈希 + 熵 | 随机 | 随机 |
| 可预测性 | 低 | 低 | 低 |

## 长度与安全性

| 长度 | 建议用途 |
|------|----------|
| 2-7 | 仅内部短期使用 |
| 8-15 | 低冲突场景 |
| 16-23 | 一般用途 |
| 24+ | 推荐默认值，高安全性 |

## API 参考

### 类型

| 类型 | 说明 |
|------|------|
| `ICuid2Generator` | CUID2 生成器接口 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `CUID2_DEFAULT_LENGTH` | 24 | 默认长度 |
| `CUID2_MIN_LENGTH` | 2 | 最小长度 |
| `CUID2_MAX_LENGTH` | 32 | 最大长度 |

### 函数

| 函数 | 说明 |
|------|------|
| `Cuid2(ALength): string` | 生成 CUID2 |
| `Cuid2N(Count, ALength): TStringArray` | 批量生成 |
| `IsCuid2(S): Boolean` | 验证 CUID2 |
| `CreateCuid2Generator(ALength): ICuid2Generator` | 创建生成器 |

### ICuid2Generator 接口

| 方法/属性 | 说明 |
|-----------|------|
| `Next: string` | 生成单个 CUID2 |
| `NextN(Count): TStringArray` | 批量生成 |
| `Length: Integer` | 获取/设置 ID 长度 |
