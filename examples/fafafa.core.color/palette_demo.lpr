program palette_demo;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils,
  fafafa.core.color;

procedure PrintColor(const title: string; const c: color_rgba_t);
begin
  WriteLn(title, ': ', color_to_hex(c));
end;

var
  a, b, m_srgb, m_lin, m_lab, m_lch: color_rgba_t;
  p_eq, p_pos: color_rgba_t;
  lch: color_oklch_t;
  arr: array[0..2] of color_rgba_t;
begin
  function ReadAllText(const path: string): string;
  var f: TextFile; s,line: string;
  begin
    s := '';
    AssignFile(f, path);
    {$I-} Reset(f); {$I+}
    if IOResult<>0 then Exit('');
    while not Eof(f) do begin ReadLn(f, line); s := s + line; end;
    CloseFile(f);
    ReadAllText := s;
  end;

  // 基础颜色：OKLCH 最短路径跨 0°
  lch.L := 0.7; lch.C := 0.1; lch.h := 350; a := color_from_oklch(lch);
  lch.L := 0.7; lch.C := 0.1; lch.h := 10;  b := color_from_oklch(lch);

  // 四种插值空间（t=0.5）
  m_srgb := color_mix_srgb(a, b, 0.5);
  m_lin  := color_mix_linear(a, b, 0.5);
  m_lab  := color_mix_oklab(a, b, 0.5);
  m_lch  := color_mix_oklch(a, b, 0.5, True);

  WriteLn('== Mix comparison (t=0.5) ==');
  PrintColor('sRGB  ', m_srgb);
  PrintColor('Linear', m_lin);
  PrintColor('OKLab ', m_lab);
  PrintColor('OKLCH ', m_lch);

  // 多点调色板：等分 vs 非均匀 positions
  arr[0] := COLOR_RED; arr[1] := COLOR_GREEN; arr[2] := COLOR_BLUE;
  p_eq  := palette_sample_multi(arr, 0.6, PIM_SRGB);
  p_pos := palette_sample_multi_with_positions(arr, [10.0, 20.0, 70.0], 15.0, PIM_SRGB, False, True);

  WriteLn('\n== Palette sampling ==');
  PrintColor('Equal 3-stop t=0.6 (sRGB)', p_eq);
  PrintColor('Positions [10,20,70], t=15 norm', p_pos);

  // 结构化 Palette API 演示（等分）
  var ps: color_palette_t; pc: color_rgba_t;
  begin
  // 从文件加载策略（最佳实践：配置化/可共享）
  begin
    var json := ReadAllText('examples'+PathDelim+'fafafa.core.color'+PathDelim+'palette_strategy.json');
    var PS: IPaletteStrategy := palette_strategy_from_text(json);
    if PS<>nil then
    begin
      PrintColor('From JSON t=0.2', PS.Sample(0.2));
      WriteLn('Loaded strategy: count=', PS.Count, ', mode=', Ord(PS.Mode));
    end;
  end;
    // 使用带错误信息的 API
    begin
      var obj: IPaletteStrategy; var err: string;
      if not palette_strategy_from_text_ex(json, obj, err) then
        WriteLn('Load strategy error: ', err)
      else
        WriteLn('Load strategy ok: count=', obj.Count);
    end;


    palette_init_even(ps, PIM_OKLCH, arr, True);
    pc := palette_sample_struct(ps, 0.5);
    PrintColor('Struct API (OKLCH, t=0.5)', pc);
  end;

  // 策略对象化：构造 / 序列化 / 反序列化 / 采样
  var S, D: IPaletteStrategy; json: string; cs, cd: color_rgba_t;
  begin
    S := TPaletteStrategy.CreateWithPositions(PIM_OKLCH, arr, [0.0, 0.2, 1.0], True, False);
    cs := S.Sample(0.2);
    PrintColor('Strategy Sample t=0.2', cs);
    json := S.Serialize;
    if palette_strategy_deserialize(json, D) then
    begin
      cd := D.Sample(0.2);
      PrintColor('Strategy Deserialize t=0.2', cd);
    end;
  end;
  // 运行时编辑 + Validate 示例
  begin
    if D<>nil then begin
      D.AppendColor(COLOR_ORANGE);
      var msg: string;
      if not D.Validate(msg) then
        WriteLn('Validate failed: ', msg)
      else
        WriteLn('Validate OK. Colors=', D.Count);
    end;
  end;
end.

