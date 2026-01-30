# fafafa.core.term 终端 I/O 模块设计蓝图 (term.md)

本文档旨在规划和指导 `fafafa.core.term` 模块的实现。该模块的目标是提供一个全功能的、跨平台的框架，用于构建复杂的、现代化的终端用户界面 (TUI) 应用。

---

## 核心设计哲学

*   **事件驱动**: 所有输入（键盘、鼠标、窗口事件）都作为结构化的事件，通过 `TLoop` 进行异步分发。
*   **声明式渲染**: 鼓励用户描述“界面应该是什么样子”，而不是手动执行一系列光标移动和写入命令。
*   **性能优先**: 通过双缓冲和智能差异更新，最大限度地减少实际的终端 I/O，避免闪烁，提升响应速度。
*   **跨平台抽象**: 封装 Windows Console API, POSIX termios 以及 ANSI/VT100 控制序列的复杂性。

---

## 开发路线图

### 阶段一: 底层控制与事件读取

*目标: 建立与终端进行底层交互的能力，并能将原始输入流解析为结构化事件。*

- [ ] **1.1. 设计 `TTerminal` 核心类**
    - `unit fafafa.core.term.pas`
    - `TTerminal` 继承自 `THandle`，并提供模式切换、尺寸获取等基础功能。
    ```pascal
    type
      TTerminal = class(THandle)
      public
        procedure SetRawMode(aEnabled: Boolean);
        function GetWindowSize(out aWidth, aHeight: Integer): Boolean;
        procedure ReadStart;
        procedure ReadStop;
      end;
    ```

- [ ] **1.2. 设计输入事件模型**
    - @desc: 定义一系列记录体来描述不同的输入事件。
    ```pascal
    type
      TKeyEvent = record Key: Word; Char: WideChar; Modifiers: TShiftState; end;
      TMouseEvent = record X, Y: Integer; Button: (mbLeft, mbRight, ...); EventType: (meDown, meUp, meMove, ...); end;
      TResizeEvent = record Width, Height: Integer; end;

      TInputEvent = record
        EventType: (etKey, etMouse, etResize);
        case EventType of
          etKey: (Key: TKeyEvent);
          etMouse: (Mouse: TMouseEvent);
          etResize: (Resize: TResizeEvent);
      end;

      TInputEventCallback = procedure(const aEvent: TInputEvent) of object;
    
    // 在 TTerminal 中添加事件回调
    property OnInputEvent: TInputEventCallback read FOnInputEvent write FOnInputEvent;
    ```
    - @remark: `TTerminal` 的 `ReadStart` 内部将包含一个解析器，它消费原始字节流，并触发结构化的 `OnInputEvent`。

---

### 阶段二: 高级输出与画布 (Canvas) API

*目标: 提供一个高级的、声明式的 API 用于在终端上绘制内容。*

- [ ] **2.1. 设计 `TTermCell` 和 `TTermCanvas`**
    - `TTermCell`: 一个 `record`，代表终端上的一个字符单元格，包含 `Char`, `ForegroundColor`, `BackgroundColor`, `Style` 等信息。
    - `TTermCanvas`: 一个二维的 `TTermCell` 数组，代表一个离屏的后端缓冲区。
    ```pascal
    type
      TTermCanvas = class
      public
        procedure Resize(aWidth, aHeight: Integer);
        procedure SetCell(aX, aY: Integer; const aCell: TTermCell);
        procedure DrawText(aX, aY: Integer; const aText: string; aFg, aBg: TColor);
        procedure Clear;
      end;
    ```

- [ ] **2.2. 设计 `TTermRenderer` (渲染器)**
    - @desc: **(核心渲染机制)** 负责比较两个 `TTermCanvas` (当前屏幕状态和新的后端缓冲区)，计算出最小的差异，并生成最优的 ANSI 指令序列来更新屏幕。
    - **API 设计**:
    ```pascal
    type
      TTermRenderer = class
      private
        FCurrentCanvas: TTermCanvas;
      public
        procedure Render(aNewCanvas: TTermCanvas);
      end;
    ```

---

### 阶段三: 便捷的 UI 工具集

*目标: 提供一组更高层次的工具，进一步简化 TUI 应用的开发。*

- [ ] **3.1. 设计 `TTermWriter` (链式调用)**
    - @desc: 一个辅助 `record` 或类，提供流畅的、链式调用的 API 来直接写入 ANSI 序列，用于简单的、不需要双缓冲的场景。
    - **用法示例**:
    ```pascal
    TTermWriter.New
      .SetForegroundColor(clRed)
      .Write('Error: ')
      .ResetStyles
      .WriteLine('File not found.')
      .Flush;
    ```

- [ ] **3.2. (可选) 设计一个简单的组件模型**
    - @desc: 规划一些基础的 UI 组件，如 `TLabel`, `TButton`, `TWindow`，它们内部都使用 `TTermCanvas` 进行绘制。