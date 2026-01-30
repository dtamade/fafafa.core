program ui_showcase;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  fafafa.core.term,
  fafafa.core.term.ui,
  fafafa.core.term.ui.controls.textinput,
  fafafa.core.term.ui.controls.scrollcontainer,
  fafafa.core.term.ui.controls.listview,
  fafafa.core.term.ui.controls.tabs,
  fafafa.core.term.ui.controls.command_palette,
  fafafa.core.term.ui.style;

var
  Root: TStackRootNode;
  Banner: IUiNode;
  Status: IUiNode;
  Input: IUiNode;

function HandleNodeEvent(const E: term_event_t): boolean;
begin
  Result := true;
  if E.kind = tek_key then
  begin
    if (E.key.key = KEY_Q) or (E.key.char.wchar = 'q') or (E.key.char.wchar = 'Q') then Exit(false);
  end;
  if E.kind = tek_sizeChange then termui_invalidate;
end;

var
  VBox: TVBoxNode;
  HBox: THBoxNode;
  LeftPane, RightPane: IUiNode;
  ScrollLeft: TScrollContainerNode;
  List: TListViewNode;
  Tabs: TTabsNode;
  Cmd: TCommandPaletteNode;
  i: Integer;
begin
  Banner := TBannerNode.Create(' Minimal UI Layer Showcase (VBox/HBox + padding/gap) ');
  Status := TStatusBarNode.Create('按 Q 退出。  Ctrl+K 打开命令面板');

  // Middle content: HBox with padding/gap
  // Input at top
  Input := TTextInputNode.Create('Type to filter (demo placeholder)');

  // Build a long list in the left pane to demonstrate virtualization + scroll
  List := TListViewNode.Create;
  for i := 0 to 499 do
    List.AddItem(Format('Item #%d  —  Quick brown fox jumps over the lazy dog', [i]));
  // Example of custom row formatting and styling
  List.SetFormatItem(@FormatItem);
  List.SetStyleForRow(@StyleForRow);

  LeftPane := List;
  ScrollLeft := TScrollContainerNode.Create(LeftPane);
  ScrollLeft.SetContentSize(0, 2000); // pretend content is very tall

  RightPane := TPanelNode.Create(60,40,20,' ');
  HBox := THBoxNode.Create;
  HBox.SetPadding(1,1,1,1);
  HBox.SetGap(1);
  HBox.AddFlex(ScrollLeft, 1);
  HBox.AddFixed(RightPane, 20);

  Tabs := TTabsNode.Create;
  Tabs.AddTab('Home', HBox);
  Tabs.AddTab('Logs', ScrollLeft);

  VBox := TVBoxNode.Create;
  VBox.SetPadding(0,0,0,0);
  VBox.SetGap(1);
  VBox.AddFixed(Banner, 1);
  VBox.AddFixed(Input, 1);
  VBox.AddFlex(Tabs, 1);
  VBox.AddFixed(Status, 1);

  // Command palette
  Cmd := TCommandPaletteNode.Create;
  Cmd.SetItems(['Open File','New File','Save','Save As','Close','Find','Replace','Toggle Theme','Preferences','Help','About']);

  Root := TStackRootNode.Create;
  Root.Add(VBox);
  Root.Add(Cmd); // overlay on top
  termui_run_node(Root);
end.

