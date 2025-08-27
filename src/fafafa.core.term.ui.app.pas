unit fafafa.core.term.ui.app;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_app,
  fafafa.core.term.ui.node;

type
  // 复用底层定义（回调签名保持一致）
  TUiRenderProc = ui_app.TUiRenderProc;
  TUiEventProc  = ui_app.TUiEventProc;

// 应用层入口（转发到底层 ui_app）
procedure UiAppInvalidate;
procedure UiAppRun(Render: TUiRenderProc; HandleEvent: TUiEventProc);
procedure UiAppRunNode(const Root: IUiNode);
procedure UiAppSetOverlay(Overlay: TUiRenderProc);


implementation

procedure UiAppInvalidate;
begin
  ui_app.UiAppInvalidate;
end;

procedure UiAppRun(Render: TUiRenderProc; HandleEvent: TUiEventProc);
begin
  ui_app.UiAppRun(Render, HandleEvent);
end;

procedure UiAppRunNode(const Root: IUiNode);
begin
  ui_app.UiAppRunNode(Root);
end;

procedure UiAppSetOverlay(Overlay: TUiRenderProc);
begin
  ui_app.UiAppSetOverlay(Overlay);
end;

end.

