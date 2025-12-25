# fafafa.core.id.nanoid 模块说明

NanoID 是一个小巧、安全、URL 友好的唯一字符串 ID 生成器。

## 特性

- 默认 21 个字符 (vs UUID 36 字符)
- URL 安全字母表: `A-Za-z0-9_-`
- 密码学安全随机
- 可自定义字母表和长度
- 对标 Rust: https://docs.rs/nanoid/latest/nanoid/

## 快速开始

```pascal
uses fafafa.core.id.nanoid;

var
  Id: string;
begin
  // 默认 21 字符
  Id := NanoId;  // "V1StGXR8_Z5jdHi6B-myT"

  // 自定义长度
  Id := NanoId(10);  // "IRFa-VaY2b"

  // 自定义字母表
  Id := NanoIdCustom('abc123', 8);  // "1a2b3c1a"

  // 使用预设字母表
  Id := NanoIdWithAlphabet(naAlphanumeric, 16);  // 无特殊字符
  Id := NanoIdWithAlphabet(naNoDoppelganger, 21);  // 无歧义字符
end;
```

## 预设字母表

| 常量 | 说明 | 字符 |
|------|------|------|
| `naUrlSafe` | 默认，URL 安全 | A-Za-z0-9_- (64 字符) |
| `naAlphanumeric` | 字母数字 | A-Za-z0-9 (62 字符) |
| `naAlphaLower` | 小写字母数字 | a-z0-9 (36 字符) |
| `naAlphaUpper` | 大写字母数字 | A-Z0-9 (36 字符) |
| `naHexLower` | 小写十六进制 | 0-9a-f (16 字符) |
| `naHexUpper` | 大写十六进制 | 0-9A-F (16 字符) |
| `naNoDoppelganger` | 无歧义字符 | 去除 l1I0O (57 字符) |
| `naNumbers` | 纯数字 | 0-9 (10 字符) |

## 批量生成

```pascal
var
  Ids: TStringArray;
begin
  // 批量生成 100 个 NanoID
  Ids := NanoIdN(100);

  // 批量生成指定长度
  Ids := NanoIdN(100, 16);
end;
```

## 生成器模式

长期使用时，使用生成器可获得更好的配置复用：

```pascal
var
  Gen: INanoIdGenerator;
  Id: string;
  Ids: TStringArray;
begin
  // 创建生成器
  Gen := CreateNanoIdGenerator(naAlphanumeric, 16);

  // 生成单个 ID
  Id := Gen.Next;

  // 批量生成
  Ids := Gen.NextN(100);

  // 动态修改长度
  Gen.Size := 24;
end;
```

## 验证

```pascal
var
  Valid: Boolean;
begin
  // 检查是否为有效 NanoID (默认 URL 安全字母表)
  Valid := IsValidNanoId('V1StGXR8_Z5jdHi6B-myT');  // True

  // 检查指定长度
  Valid := IsValidNanoId('abc', naUrlSafe, 21);  // False (长度不符)

  // 检查指定字母表
  Valid := IsValidNanoId('abc123', naNumbers, 6);  // False (含字母)
end;
```

## 碰撞概率

NanoID 默认 21 字符提供约 126 位熵，碰撞概率极低：

| 长度 | 熵 (bits) | 每秒 10^9 ID 需要多少年才可能碰撞 |
|------|-----------|----------------------------------|
| 21 | 126 | ~149 年 |
| 16 | 96 | ~2 小时 |
| 10 | 60 | ~1 秒 |

建议至少使用 16 字符以获得足够的唯一性保证。

## API 参考

### 函数

| 函数 | 说明 |
|------|------|
| `NanoId: string` | 生成默认 NanoID (21 字符) |
| `NanoId(Size): string` | 生成指定长度的 NanoID |
| `NanoIdCustom(Alphabet, Size): string` | 使用自定义字母表 |
| `NanoIdWithAlphabet(Alphabet, Size): string` | 使用预设字母表 |
| `NanoIdN(Count, Size): TStringArray` | 批量生成 |
| `CreateNanoIdGenerator(...): INanoIdGenerator` | 创建生成器 |
| `IsValidNanoId(S, Alphabet, ExpectedSize): Boolean` | 验证 NanoID |
| `GetAlphabetString(Alphabet): string` | 获取预设字母表字符串 |

### INanoIdGenerator 接口

| 方法/属性 | 说明 |
|-----------|------|
| `Next: string` | 生成单个 NanoID |
| `NextN(Count): TStringArray` | 批量生成 |
| `Alphabet: string` | 获取当前字母表 |
| `Size: Integer` | 获取/设置 ID 长度 |
