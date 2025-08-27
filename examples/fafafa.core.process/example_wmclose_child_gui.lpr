program example_wmclose_child_gui;

{$APPTYPE GUI}
{$mode objfpc}{$H+}

uses
  Windows, Messages;

const
  CLASS_NAME = 'WmCloseChildWindowClass';
  ID_FILE_EXIT = 1001;

var
  WndClass: WNDCLASS;
  Wnd: HWND;
  Msg: MSG;
  hMenuBar, hFileMenu: HMENU;

function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; stdcall;
begin
  case uMsg of
    WM_CLOSE:
      begin
        // 接收到 WM_CLOSE 立即退出
        PostQuitMessage(0);
        Result := 0;
        Exit;
      end;
    WM_COMMAND:
      begin
        if LOWORD(wParam) = ID_FILE_EXIT then
        begin
          SendMessage(hWnd, WM_CLOSE, 0, 0);
          Result := 0;
          Exit;
        end;
      end;
    WM_KEYDOWN:
      begin
        if wParam = VK_ESCAPE then
        begin
          SendMessage(hWnd, WM_CLOSE, 0, 0);
          Result := 0;
          Exit;
        end;
      end;
  end;
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;

begin
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.style := CS_HREDRAW or CS_VREDRAW;
  WndClass.lpfnWndProc := @WndProc;
  WndClass.hInstance := GetModuleHandle(nil);
  WndClass.hbrBackground := COLOR_WINDOW+1;
  WndClass.lpszClassName := CLASS_NAME;
  RegisterClass(WndClass);

  Wnd := CreateWindowEx(0, CLASS_NAME, 'WM_CLOSE demo window (Esc closes, File->Exit)', WS_OVERLAPPEDWINDOW,
    CW_USEDEFAULT, CW_USEDEFAULT, 480, 320, 0, 0, HINSTANCE(GetModuleHandle(nil)), nil);

  // 创建简单菜单：File -> Exit
  hMenuBar := CreateMenu();
  hFileMenu := CreatePopupMenu();
  AppendMenu(hFileMenu, MF_STRING, ID_FILE_EXIT, 'Exit');
  AppendMenu(hMenuBar, MF_POPUP, PtrUInt(hFileMenu), 'File');
  SetMenu(Wnd, hMenuBar);

  ShowWindow(Wnd, SW_SHOW);
  UpdateWindow(Wnd);

  while GetMessage(Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
  Halt(Msg.wParam);
end.

