unit ui_app;

{$mode objfpc}{$H+}

interface

uses
  fafafa.core.term,
  ui_node,
  ui_surface;

type
  TUiRenderProc = procedure;
  // Return false to request exit
  TUiEventProc = function(const E: term_event_t): boolean;

procedure UiAppInvalidate;
procedure UiAppRun(Render: TUiRenderProc; HandleEvent: TUiEventProc);
procedure UiAppRunNode(const Root: IUiNode);
// Optional per-frame overlay drawn after Render and before FrameEnd
procedure UiAppSetOverlay(Overlay: TUiRenderProc);

implementation
var
  GOverlay: TUiRenderProc = nil;

procedure UiAppSetOverlay(Overlay: TUiRenderProc);
begin
  GOverlay := Overlay;
end;


var
  GInvalidated: boolean = true;

procedure UiAppInvalidate;
begin
  GInvalidated := true;
end;

procedure UiAppRun(Render: TUiRenderProc; HandleEvent: TUiEventProc);
var
  E: term_event_t;
  keepRunning: boolean;
begin
  // Debug boot line to stdout (not via term API) to ensure visibility even if term_init fails
  System.Writeln('UiAppRun: enter');
  if not term_init then
  begin
    System.Writeln('UiAppRun: term_init failed');
    Exit;
  end;
  System.Writeln('UiAppRun: term_init ok');
  keepRunning := true;
  try
    // Switch to alternate screen if supported for a clean UI
    if term_support_alternate_screen then
      term_alternate_screen_enable;

    // Temporarily disable mouse to isolate keyboard input issues
    // if term_support_mouse then term_mouse_enable(true);

    // Initial render
    GInvalidated := true;
    System.Writeln('UiAppRun: loop start');
    while keepRunning do
    begin
      if GInvalidated then
      begin
        UiFrameBegin;
        Render();
        if Assigned(GOverlay) then GOverlay();
        UiFrameEnd;
        GInvalidated := false;
      end;

      // Zero-init event record (defensive; avoids uninitialized warnings in some toolchains)
      FillByte(E, SizeOf(E), 0);
      if term_event_poll(E, 100) then
      begin
        System.Writeln('UiAppRun: got event kind=', Ord(E.kind));
        // Resize invalidates: mark for full-screen redraw
        if E.kind = tek_sizeChange then
        begin
          GInvalidated := true;
          UiInvalidateAll;
        end;
        if Assigned(HandleEvent) then
        begin
          keepRunning := HandleEvent(E);
        end;
      end;
    end;
  finally
    if term_support_alternate_screen then
      term_alternate_screen_disable;
    term_done;
    System.Writeln('UiAppRun: exit');
  end;
end;


procedure UiAppRunNode(const Root: IUiNode);
var
  E: term_event_t;
  keepRunning: boolean;
begin
  System.Writeln('UiAppRunNode: enter');
  if not term_init then
  begin
    System.Writeln('UiAppRunNode: term_init failed');
    Exit;
  end;
  System.Writeln('UiAppRunNode: term_init ok');
  keepRunning := true;
  try
    // Switch to alternate screen if supported for a clean UI
    if term_support_alternate_screen then
      term_alternate_screen_enable;

    // Temporarily disable mouse to isolate keyboard input issues
    // if term_support_mouse then term_mouse_enable(true);

    GInvalidated := true;
    System.Writeln('UiAppRunNode: loop start');
    while keepRunning do
    begin
      if GInvalidated then
      begin
        if Assigned(Root) then
        begin
          UiFrameBegin;
          Root.Render;
          if Assigned(GOverlay) then GOverlay();
          UiFrameEnd;
        end;
        GInvalidated := false;
      end;

      // Zero-init event record (defensive; avoids uninitialized warnings in some toolchains)
      FillByte(E, SizeOf(E), 0);
      if term_event_poll(E, 100) then
      begin
        if E.kind = tek_sizeChange then begin GInvalidated := true; UiInvalidateAll; end;
        // Global quit on Q key for demos (handle both virtual-key and character)
        if (E.kind = tek_key) and (
             (E.key.key = KEY_Q) or
             (E.key.char.wchar = 'q') or (E.key.char.wchar = 'Q')
           ) then
          keepRunning := False
        else if Assigned(Root) then
        begin
          keepRunning := Root.HandleEvent(E);
        end;
      end;
    end;
  finally
    if term_support_alternate_screen then
      term_alternate_screen_disable;
    term_done;
    System.Writeln('UiAppRunNode: exit');
  end;
end;

end.
