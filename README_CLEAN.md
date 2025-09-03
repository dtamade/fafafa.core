# 清理脚本使用说明

本项目提供了多个清理脚本来删除编译产生的 `.o` 和 `.ppu` 文件。

## 脚本文件

### 1. clean.bat (Windows 批处理)
- **用途**: Windows 系统下的清理脚本
- **使用方法**: 
  - 双击运行 `clean.bat`
  - 或在命令提示符中运行: `clean.bat`

### 2. clean.sh (Linux/macOS Shell)
- **用途**: Linux/macOS 系统下的清理脚本
- **使用方法**: 
  ```bash
  chmod +x clean.sh
  ./clean.sh
  ```

### 3. clean.ps1 (PowerShell)
- **用途**: 跨平台 PowerShell 脚本
- **使用方法**: 
  ```powershell
  powershell -ExecutionPolicy Bypass -File clean.ps1
  ```

## 手动清理命令

如果脚本无法运行，可以使用以下手动命令：

### Windows (命令提示符)
```cmd
del /s /q *.o *.ppu
```

### Windows (PowerShell)
```powershell
Get-ChildItem -Recurse -Include "*.o","*.ppu" | Remove-Item -Force
```

### Linux/macOS
```bash
find . -name "*.o" -o -name "*.ppu" -delete
```

## 清理的文件类型

- **`.o` 文件**: 目标文件 (Object files)
- **`.ppu` 文件**: Pascal 编译单元文件 (Pascal Compiled Unit files)

这些文件是编译过程中产生的中间文件，删除后不会影响源代码，重新编译时会自动生成。

## 注意事项

1. 清理前请确保没有正在进行的编译过程
2. 清理后需要重新编译项目
3. 建议在版本控制提交前进行清理，避免提交编译产物
