# fafafa.core.mem.mimalloc - Mimalloc 跨平台库文档

## 库版本
- **mimalloc**: 2.2.6
- **构建日期**: 2025-01-13

## 平台支持

| 平台 | 架构 | 目录 |
|------|------|------|
| Windows | x86_64, i386, ARM64 | `lib/{x86_64-win64,i386-win32,aarch64-win64}/` |
| Linux | x86_64, i386, ARM64, ARM | `lib/{x86_64,i386,aarch64,arm}-linux/` |
| macOS | x86_64, ARM64 | `lib/{x86_64,aarch64}-darwin/` |
| Android | x86_64, ARM, ARM64 | `lib/{x86_64,arm,aarch64}-android/` |

## 依赖关系

### Windows x86_64/i386 (MinGW-w64)
```
KERNEL32.dll, ADVAPI32.dll, msvcrt.dll (系统自带)
```
**优势**: 所有依赖均为 Windows 系统自带，无需额外分发任何 DLL。

### Windows ARM64 (LLVM-MinGW)
```
KERNEL32.dll, ADVAPI32.dll, api-ms-win-crt-*.dll (UCRT)
```
**优势**: 使用 UCRT，Windows 10+ 系统自带。

### Linux (glibc)
```
libc.so.6 - 需要 GLIBC 2.34+
```
**兼容**: Ubuntu 22.04+, Debian 12+, RHEL 9+, Fedora 35+
**不兼容**: Ubuntu 20.04, Debian 11, CentOS 7/8

### macOS
```
libSystem.B.dylib - 需要 macOS 15.0+
```

### Android (Bionic)
```
libc.so, libm.so, libdl.so - API 21+
```

## 使用方法

### 静态链接（推荐）
```pascal
// fafafa.core.settings.inc
{$DEFINE FAFAFA_CORE_MIMALLOC_STATIC}
```
```bash
fpc -Fl./lib/x86_64-linux -Fu./src myapp.pas
```

### 动态链接
默认模式，运行时自动检测库是否可用。

**部署**:
- Linux: 复制 `libmimalloc.so*` 到 `/usr/local/lib/` 并运行 `ldconfig`
- Windows: 复制 `mimalloc.dll` 到应用目录
- Android: 放入 `jniLibs/{arm64-v8a,armeabi-v7a,x86_64}/`

## 构建工具链

| 平台 | 编译器 | C 运行时 |
|------|--------|----------|
| Windows x86_64/i386 | MinGW-w64 GCC 14.2.0 | msvcrt |
| Windows ARM64 | LLVM-MinGW Clang 21.1.8 | UCRT |
| Linux | GCC 14.2.0 | glibc 2.34 |
| macOS | osxcross Clang 19.1.6 | libSystem |
| Android | NDK r27c Clang 18.0.3 | Bionic |

## 常见问题

**Q: 如何支持更旧的 Linux?**
使用静态链接或在目标系统重新编译。

**Q: Android 库为什么大?**
NDK 包含调试信息，可用 `llvm-strip --strip-unneeded` 减小。

**Q: 如何验证依赖?**
```bash
# Linux/Android
readelf -d libmimalloc.so | grep NEEDED
# Windows
objdump -p mimalloc.dll | grep "DLL Name"
```
