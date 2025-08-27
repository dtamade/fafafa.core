# Benchmark Template

约定
- .lpr 文件头部包含：
  - {$MODE OBJFPC}{$H+}
  - {$I ../../src/fafafa.core.settings.inc}
  - {$UNITPATH ../../src}
- 使用 Writeln 简洁输出，秒级以内完成

构建
- lazbuild --build-mode=Release sample.lpr
- 或 fpc -O2 -S2 -MObjFPC -Fu../../src -FEbin -FUlib sample.lpr

