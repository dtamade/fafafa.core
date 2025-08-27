{$CODEPAGE UTF8}
program play_ui_frame_loop;

{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}

uses
  SysUtils,
  fafafa.core.term,
  ui_surface,
  ui_app,
  ui_node,
  ui_style;

var
  Root: IUiNode;
  Banner: TBannerNode;
  Panel: TPanelNode;
  Status: TStatusBarNode;
  Frames: QWord = 0;
  Tick0: QWord = 0;

procedure Render;
var
  W,H: term_size_t;
  s: UnicodeString;
begin
  Inc(Frames);
  if not term_size(W,H) then Exit;
  // 顶部横幅文本
  Banner.SetText(Format('fafafa.core.term UI Loop — size: %dx%d  frames: %d  (Q to quit)', [W,H, Frames]));
  // 状态栏文本
  s := Format('Use drag/resize to test diff; events will invalidate. frames:%d', [Frames]);
  Status.SetText(s);
  // 根节点驱动渲染（UiFrameBegin/End 由 UiAppRun 管理）
  Root.Render;
end;

function HandleEvent(const E: term_event_t): boolean;
begin
  // ESC 或 Q 退出（同时支持虚拟键和字符）
  if (E.kind = tek_key) and (
       (E.key.key = KEY_ESC) or
       (E.key.key = KEY_Q) or
       (E.key.char.wchar = 'q') or (E.key.char.wchar = 'Q')
     ) then Exit(false);
  // Resize 事件：无条件标记重绘（UiAppRun 已处理 sizeChange->InvalidateAll）
  if E.kind = tek_sizeChange then UiAppInvalidate;
  Result := true;
end;

begin
  // 构建一个简单的 VBox：顶部 Banner + 中间 Panel + 底部 StatusBar
  Banner := TBannerNode.Create('');
  Panel := TPanelNode.Create(20,20,40,' ');
  Status := TStatusBarNode.Create('');
  var RootStack := TStackRootNode.Create;
  RootStack.Add(Banner);
  RootStack.Add(Panel);
  RootStack.Add(Status);
  Root := RootStack;

  // UI 风格：可根据主题设置不同样式
  UiStyleReset;
  UiSetCursorAfterFramePolicy(ucpToOrigin);

  // 启动应用帧循环：内部负责 term_init/alt screen/UiFrameBegin/End/term_done
  UiAppRun(@Render, @HandleEvent);
end.

