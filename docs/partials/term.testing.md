# fafafa.core.term 测试最佳实践（可引用分片）

> 目标：在不同环境（交互/非交互、Windows/TTY仿真器）下，让依赖真实终端能力的测试“可运行、可跳过、不误报”。

## 一、统一的 Skip 与环境判定

- 使用 TestSkip(TestCase, Reason) 进行显式跳过
  - 新版 FPCUnit：内部抛出 ESkipTest，框架标记为 Skipped
  - 旧版 FPCUnit：回退为“软跳过”，输出 "SKIP: …" 提示
- 使用 TestEnv_AssumeInteractive(Self): Boolean 判定环境是否满足交互式终端
  - 判据顺序（任一不满足即跳过）：
    1) IsATTY 为真（若可用）
    2) term_init 成功
    3) term_size(w,h) 返回正数尺寸
    4) term_name 非空且不为 "unknown"

推荐模式
- 在用例开头：
  if not TestEnv_AssumeInteractive(Self) then Exit;
- 需要访问依赖 term_current 的调用链（如 GetCapabilities）时，务必在作用域内配对 term_init/term_done：
  term_init; try … finally term_done; end;

## 二、常见用例模板

- 简单路径（仅需交互环境）：
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init; try
    CheckTrue(term_clear);
  finally term_done; end;

- 功能切换（支持检测 + 容错）：
  if not TestEnv_AssumeInteractive(Self) then Exit;
  term_init; try
    if term_support_alternate_screen then begin
      CheckTrue(term_alternate_screen_enable(True));
      CheckTrue(term_alternate_screen_disable);
    end else
      CheckTrue(True, 'alt screen not supported: skipped');
  finally
    if term_support_alternate_screen then term_alternate_screen_disable;
    term_done;
  end;

## 三、Windows 特性与注意事项

- Quick Edit 防护：启用鼠标期间临时关闭 Quick Edit，退出恢复；测试用例仅验证幂等与不抛异常
- Unicode 输入：使用 ReadConsoleInputW 路径，测试中合成 Emoji/扩展平面字符，验证解析不崩
- ConsoleMode 切换：通过内部守卫恢复，避免对外暴露具体位级断言（必要时在专用用例覆盖）

## 四、非交互环境的行为预期

- 依赖真实终端的测试：应被“跳过”（Skipped 或软跳过），不计为失败
- 算法/结构测试：不依赖终端，可在任何环境稳定通过

## 五、运行与重建

- 一键重建并测试（Windows）：
  tests\\fafafa.core.term\\BuildOrTest.bat rebuild
  tests\\fafafa.core.term\\BuildOrTest.bat test

- PowerShell 脚本：
  cd tests\\fafafa.core.term
  powershell -ExecutionPolicy Bypass -File .\\run-tests.ps1 -Rebuild

## 六、排错要点

- aTerm is nil：通常是未在作用域内 term_init/term_done；或环境非交互
- term_size=0 或 term_name='unknown'：可能是伪TTY/非交互会话，应跳过
- 仍未跳过的漏网用例：在用例开头补 if not TestEnv_AssumeInteractive(Self) then Exit;

## 七、后续改进方向

- 将更多“软跳过”场景渐进切换为真正的 Skipped 统计
- 在测试 Runner 汇总 Skipped 数量，输出到日志摘要
- 针对 UI 帧循环与双缓冲 diff 的集成测试，分级分层（快速/慢速/交互）标注
