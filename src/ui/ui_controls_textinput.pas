unit ui_controls_textinput;

{$mode objfpc}{$H+}

interface

uses
  SysUtils,
  fafafa.core.term,
  ui_types,
  ui_node,
  ui_surface,
  ui_app;

type
  { TTextInputNode - single-line text input }
  TTextInputNode = class(TInterfacedObject, IUiNode)
  private
    FRect: TUiRect;
    FText: UnicodeString;
    FPlaceholder: UnicodeString;
    FActive: boolean;
  public
    constructor Create(const APlaceholder: UnicodeString = '');
    procedure SetRect(const R: TUiRect);
    procedure Render;
    function HandleEvent(const E: term_event_t): boolean;
    function Text: UnicodeString;
    procedure SetText(const S: UnicodeString);
  end;

implementation

constructor TTextInputNode.Create(const APlaceholder: UnicodeString);
begin
  inherited Create;
  FPlaceholder := APlaceholder;
  FActive := True;
  FText := '';
end;

procedure TTextInputNode.SetRect(const R: TUiRect);
begin
  FRect := R;
end;

procedure TTextInputNode.Render;
var
  line: term_size_t;
  content: UnicodeString;
begin
  // Draw a single line input bar
  line := FRect.Y;
  if FRect.H > 0 then ; // (keep at top of rect)

  UiSetBg24(30,30,30);
  UiSetFg24(220,220,220);
  UiFillRect(FRect.X, line, FRect.W, 1, ' ');

  if (FText = '') and (FPlaceholder <> '') then
  begin
    UiSetFg24(130,130,130);
    content := FPlaceholder;
  end
  else
    content := FText;

  UiWriteAt(line, FRect.X, content);
  UiAttrReset;
end;

function TTextInputNode.HandleEvent(const E: term_event_t): boolean;
var
  changed: boolean;
begin
  Result := true;
  changed := false;

  if not FActive then Exit;

  if E.kind = tek_key then
  begin
    // Character input (basic wide char)
    if (E.key.char.wchar <> #0) and (E.key.key = KEY_UNKOWN) then
    begin
      FText := FText + E.key.char.wchar;
      changed := true;
    end
    else
    begin
      case E.key.key of
        KEY_BACKSPACE:
          if Length(FText) > 0 then
          begin
            Delete(FText, Length(FText), 1);
            changed := true;
          end;
        KEY_ESC:
          begin
            if FText <> '' then
            begin
              FText := '';
              changed := true;
            end;
          end;
      end;
    end;
  end;

  if changed then UiAppInvalidate;
end;

function TTextInputNode.Text: UnicodeString;
begin
  Result := FText;
end;

procedure TTextInputNode.SetText(const S: UnicodeString);
begin
  if FText <> S then
  begin
    FText := S;
    UiAppInvalidate;
  end;
end;

end.

