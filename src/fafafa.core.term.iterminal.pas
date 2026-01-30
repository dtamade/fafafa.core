unit fafafa.core.term.iterminal;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils,
  fafafa.core.term;

type
  ITerminal = interface
    ['{1B3C1E31-E0B1-47B8-81A2-0F0C9A3F5C8A}']
    // 基本信息
    function GetName: UnicodeString;
    procedure GetSize(out AWidth, AHeight: term_size_t);

    // 输出（直通底层 API）
    procedure Write(const S: UnicodeString);
    procedure WriteLn(const S: UnicodeString);

    // 事件
    function Poll(out E: term_event_t; TimeoutMs: UInt64): Boolean;

    // 模式/协议开关（直通，返回 False 表示不支持或失败）
    function EnableAltScreen(AEnable: Boolean): Boolean;
    function EnableRawMode(AEnable: Boolean): Boolean;
    function EnableMouse(AEnable: Boolean): Boolean;
    function EnableFocus(AEnable: Boolean): Boolean;
    function EnablePasteBracket(AEnable: Boolean): Boolean;
    function EnableSyncUpdate(AEnable: Boolean): Boolean;
  end;

  // 轻量守卫：构造启用、释放恢复；支持嵌套/异常路径安全
  IModeGuard = interface
    ['{D7E9D7E9-7A8E-4B7E-90D0-5D0D6E5B9B0C}']
  end;

// 工厂方法
function CreateTerminal: ITerminal;
function NewModeGuard(const AltScreen, Raw, Mouse, Focus, Paste, SyncUpdate: Boolean): IModeGuard;

implementation

type
  TTerminal = class(TInterfacedObject, ITerminal)
  public
    constructor Create;
    destructor Destroy; override;
  public
    // ITerminal
    function GetName: UnicodeString;
    procedure GetSize(out AWidth, AHeight: term_size_t);
    procedure Write(const S: UnicodeString);
    procedure WriteLn(const S: UnicodeString);
    function Poll(out E: term_event_t; TimeoutMs: UInt64): Boolean;
    function EnableAltScreen(AEnable: Boolean): Boolean;
    function EnableRawMode(AEnable: Boolean): Boolean;
    function EnableMouse(AEnable: Boolean): Boolean;
    function EnableFocus(AEnable: Boolean): Boolean;
    function EnablePasteBracket(AEnable: Boolean): Boolean;
    function EnableSyncUpdate(AEnable: Boolean): Boolean;
  end;

  TModeGuard = class(TInterfacedObject, IModeGuard)
  private
    FAltScreen, FRaw, FMouse, FFocus, FPaste, FSync: Boolean;
  public
    constructor Create(const AltScreen, Raw, Mouse, Focus, Paste, SyncUpdate: Boolean);
    destructor Destroy; override;
  end;

{ TTerminal }

constructor TTerminal.Create;
begin
  inherited Create;
  // 初始化底层；失败时保持对象存活，但大多数操作会返回 False
  // 语义：不抛异常，遵循底层 API 的风格
  term_init;
end;

destructor TTerminal.Destroy;
begin
  // 幂等恢复
  term_done;
  inherited Destroy;
end;

function TTerminal.GetName: UnicodeString;
begin
  Result := UnicodeString(term_name);
end;

procedure TTerminal.GetSize(out AWidth, AHeight: term_size_t);
begin
  AWidth := term_size_width;
  AHeight := term_size_height;
end;

procedure TTerminal.Write(const S: UnicodeString);
begin
  term_write(S);
end;

procedure TTerminal.WriteLn(const S: UnicodeString);
begin
  term_writeln(S);
end;

function TTerminal.Poll(out E: term_event_t; TimeoutMs: UInt64): Boolean;
begin
  FillByte(E, SizeOf(E), 0);
  Result := term_event_poll(E, TimeoutMs);
end;

function TTerminal.EnableAltScreen(AEnable: Boolean): Boolean;
begin
  Result := term_alternate_screen_enable(AEnable);
end;

function TTerminal.EnableRawMode(AEnable: Boolean): Boolean;
begin
  Result := term_raw_mode_enable(AEnable);
end;

function TTerminal.EnableMouse(AEnable: Boolean): Boolean;
begin
  Result := term_mouse_enable(AEnable);
end;

function TTerminal.EnableFocus(AEnable: Boolean): Boolean;
begin
  Result := term_focus_enable(AEnable);
end;

function TTerminal.EnablePasteBracket(AEnable: Boolean): Boolean;
begin
  Result := term_paste_bracket_enable(AEnable);
end;

function TTerminal.EnableSyncUpdate(AEnable: Boolean): Boolean;
begin
  Result := term_sync_update_enable(AEnable);
end;

{ TModeGuard }

constructor TModeGuard.Create(const AltScreen, Raw, Mouse, Focus, Paste, SyncUpdate: Boolean);
begin
  inherited Create;
  FAltScreen := AltScreen;
  FRaw := Raw;
  FMouse := Mouse;
  FFocus := Focus;
  FPaste := Paste;
  FSync := SyncUpdate;
  // 启用（失败无害，Result 由底层决定；这里不捕获返回值）
  if FAltScreen then term_alternate_screen_enable(True);
  if FFocus then term_focus_enable(True);
  if FPaste then term_paste_bracket_enable(True);
  if FSync then term_sync_update_enable(True);
  if FMouse then term_mouse_enable(True);
  if FRaw then term_raw_mode_enable(True);
end;

destructor TModeGuard.Destroy;
begin
  // 按相反顺序恢复，异常路径也安全
  if FRaw then term_raw_mode_enable(False);
  if FMouse then term_mouse_enable(False);
  if FSync then term_sync_update_enable(False);
  if FPaste then term_paste_bracket_enable(False);
  if FFocus then term_focus_enable(False);
  if FAltScreen then term_alternate_screen_enable(False);
  inherited Destroy;
end;

function CreateTerminal: ITerminal;
begin
  Result := TTerminal.Create;
end;

function NewModeGuard(const AltScreen, Raw, Mouse, Focus, Paste, SyncUpdate: Boolean): IModeGuard;
begin
  Result := TModeGuard.Create(AltScreen, Raw, Mouse, Focus, Paste, SyncUpdate);
end;

end.

