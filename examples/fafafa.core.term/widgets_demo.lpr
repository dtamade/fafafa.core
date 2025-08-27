{$CODEPAGE UTF8}
program widgets_demo;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, Math,
  fafafa.core.base, fafafa.core.term, fafafa.core.widgets;

procedure CenterIn(var R: TRect; const InRect: TRect; W, H: Integer);
begin
  R.Width := W;
  R.Height := H;
  R.X := InRect.X + Max(0, (InRect.Width - W) div 2);
  R.Y := InRect.Y + Max(0, (InRect.Height - H) div 2);
end;

type
  THandlers = class
  public
    procedure OnOk(Sender: TObject);
    procedure OnCancel(Sender: TObject);
  end;

var
  Term: ITerminal;
  Outp: ITerminalOutput;
  Info: ITerminalInfo;
  Root: TTerminalWidget;
  Title: TLabelWidget;
  BtnOk, BtnCancel: TButtonWidget;
  R, RootRect, BtnRect: TRect;
  Key: TKeyEvent;
  Running: Boolean = True;
  Handlers: THandlers;

procedure THandlers.OnOk(Sender: TObject);
begin
  Outp.MoveCursor(0, Info.GetSize.Height - 1);
  Outp.WriteLn('OK clicked! Press any key to exit...');
  Running := False;
end;

procedure THandlers.OnCancel(Sender: TObject);
begin
  Outp.MoveCursor(0, Info.GetSize.Height - 1);
  Outp.WriteLn('Cancel clicked! Press any key to exit...');
  Running := False;
end;

begin
  Term := CreateTerminal;
  Outp := Term.Output;
  Info := Term.Info;

  Handlers := THandlers.Create;

  // 布局根容器
  RootRect := MakeRect(0, 0, Info.GetSize.Width, Info.GetSize.Height);
  Root := TTerminalWidget.Create('root', RootRect);

  // 标题
  CenterIn(R, RootRect, 40, 3);
  Title := TLabelWidget.Create('title', MakeRect(R.X, R.Y, R.Width, 1), 'fafafa.core.widgets demo — 按Tab切换按钮, Enter确认');
  Root.AddChild(Title);

  // OK 按钮
  CenterIn(BtnRect, RootRect, 12, 3);
  BtnRect.Y := BtnRect.Y + 4;
  BtnOk := TButtonWidget.Create('ok', BtnRect, '  OK  ');
  BtnOk.OnClick := @Handlers.OnOk;
  Root.AddChild(BtnOk);

  // Cancel 按钮
  BtnRect.X := BtnRect.X + BtnRect.Width + 4;
  BtnCancel := TButtonWidget.Create('cancel', BtnRect, 'Cancel');
  BtnCancel.OnClick := @Handlers.OnCancel;
  Root.AddChild(BtnCancel);

  // 初始焦点
  Root.SetFocused(False);
  BtnOk.SetFocused(True);

  // 主循环（极简）
  Outp.ClearScreen(tctAll);
  Root.Render(Outp);

  while Running do
  begin
    // 简易输入处理
    Key := Term.Input.ReadKey;
    if Key.KeyType <> ktUnknown then
    begin
      case Key.KeyType of
        ktTab:
        begin
          if BtnOk.GetFocused then
          begin
            BtnOk.SetFocused(False);
            BtnCancel.SetFocused(True);
          end
          else
          begin
            BtnCancel.SetFocused(False);
            BtnOk.SetFocused(True);
          end;
          Root.Invalidate;
        end;
        ktEnter, ktChar:
        begin
          if TTerminalWidget(BtnOk).GetFocused then
            BtnOk.HandleKey(Key)
          else
            BtnCancel.HandleKey(Key);
        end;
        ktEscape:
          Break;
      end;
    end;

    // 重绘
    Root.Render(Outp);
  end;

  Outp.MoveCursor(0, Info.GetSize.Height - 1);
  Outp.WriteLn('Demo ended.');
end.

