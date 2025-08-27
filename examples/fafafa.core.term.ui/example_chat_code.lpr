program example_chat_code;
{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  sysutils,
  fafafa.core.term,
  fafafa.core.term.ui,
  fafafa.core.term.ui.style,
  fafafa.core.term.ui.controls.textinput,
  fafafa.core.term.ui.controls.listview,
  fafafa.core.term.ui.controls.tabs,
  fafafa.core.term.ui.controls.command_palette;

var
  Root: TStackRootNode;
  Banner, Status: IUiNode;
  VBox: TVBoxNode;
  Tabs: TTabsNode;
  LeftList: TListViewNode;
  Input: TTextInputNode;
  Cmd: TCommandPaletteNode;

procedure Render;
begin
  // 帧渲染由 UiApp 管理，示例仅通过节点树渲染
end;

function HandleEvent(const E: term_event_t): boolean;
begin
  if (E.kind = tek_key) and ((E.key.key = KEY_Q) or (E.key.char.wchar = 'q') or (E.key.char.wchar = 'Q')) then exit(false);
  Result := true;
end;

var i: Integer;
begin
  UiThemeUseDark;

  Banner := TBannerNode.Create(' Chat/Code Demo (press Q to quit, Ctrl+K palette) ');
  Status := TStatusBarNode.Create('Ready');

  LeftList := TListViewNode.Create;
  for i := 1 to 50 do LeftList.AddItem(Format('Session %d', [i]));

  Input := TTextInputNode.Create('Message...');
  Tabs := TTabsNode.Create;
  Tabs.AddTab('Chats', LeftList);
  Tabs.AddTab('Code', LeftList);

  VBox := TVBoxNode.Create;
  VBox.SetGap(1);
  VBox.AddFixed(Banner, 1);
  VBox.AddFlex(Tabs, 1);
  VBox.AddFixed(Input, 1);
  VBox.AddFixed(Status, 1);

  Cmd := TCommandPaletteNode.Create;
  Cmd.SetItems(['Open','New File','Save','Close','Find','Replace','Toggle Theme','Help','About']);

  Root := TStackRootNode.Create;
  Root.Add(VBox);
  Root.Add(Cmd);

  termui_run_node(Root);
end.

