// Runtime toggles (coalesce/debounce) setters/getters implementation

procedure term_set_coalesce_move(aEnable: Boolean);
begin
  G_TERM_COALESCE_MOVE := aEnable;
end;

procedure term_set_coalesce_wheel(aEnable: Boolean);
begin
  G_TERM_COALESCE_WHEEL := aEnable;
end;

procedure term_set_debounce_resize(aEnable: Boolean);
begin
  G_TERM_DEBOUNCE_RESIZE := aEnable;
end;

function term_get_coalesce_move: Boolean;
begin
  Result := G_TERM_COALESCE_MOVE;
end;

function term_get_coalesce_wheel: Boolean;
begin
  Result := G_TERM_COALESCE_WHEEL;
end;

function term_get_debounce_resize: Boolean;
begin
  Result := G_TERM_DEBOUNCE_RESIZE;
end;

