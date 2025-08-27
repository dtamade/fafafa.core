unit fafafa.core.color.jsonadapter;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpjson, jsonparser,
  fafafa.core.color;

// 尝试使用标准 JSON 解析策略对象（可选适配器）
// 输入：JSON 文本，支持以下字段：
//   mode: 数字(0..3)或字符串("SRGB"|"LINEAR"|"OKLAB"|"OKLCH")
//   shortest: 布尔或 0/1
//   usePos: 布尔或 0/1
//   norm: 布尔或 0/1
//   colors: ["#RRGGBB", ...]
//   positions: [number, ...]
function palette_strategy_try_deserialize_json(const s: string; out obj: IPaletteStrategy): Boolean;

implementation

function JsonBoolOrInt(const d: TJSONData; const def: Boolean): Boolean;
begin
  if d=nil then Exit(def);
  case d.JSONType of
    jtBoolean: Exit(d.AsBoolean);
    jtNumber: Exit(d.AsInteger<>0);
  else
    Exit(def);
  end;
end;

function JsonToMode(const d: TJSONData): palette_interp_mode_t;
var u: String; n: Integer;
begin
  if d=nil then Exit(PIM_SRGB);
  case d.JSONType of
    jtString:
      begin
        u := UpperCase(d.AsString);
        if u='OKLCH' then Exit(PIM_OKLCH)
        else if u='OKLAB' then Exit(PIM_OKLAB)
        else if u='LINEAR' then Exit(PIM_LINEAR)
        else Exit(PIM_SRGB);
      end;
    jtNumber:
      begin
        n := d.AsInteger;
        case n of
          0: Exit(PIM_SRGB);
          1: Exit(PIM_LINEAR);
          2: Exit(PIM_OKLAB);
          3: Exit(PIM_OKLCH);
        else
          Exit(PIM_SRGB);
        end;
      end;
  else
    Exit(PIM_SRGB);
  end;
end;

function palette_strategy_try_deserialize_json(const s: string; out obj: IPaletteStrategy): Boolean;
var j: TJSONData; o: TJSONObject; arr: TJSONArray;
    mode: palette_interp_mode_t; shortest, usePos, norm: Boolean;
    colors: array of color_rgba_t; positions: array of Single;
    i: Integer; cstr: String; msg: string;
begin
  obj := nil; Result := False;
  try
    j := GetJSON(s);
  except
    on E: Exception do Exit(False);
  end;
  try
    if (j=nil) or (j.JSONType<>jtObject) then Exit(False);
    o := TJSONObject(j);
    mode := JsonToMode(o.Find('mode'));
    shortest := JsonBoolOrInt(o.Find('shortest'), True);
    usePos := JsonBoolOrInt(o.Find('usePos'), False);
    norm := JsonBoolOrInt(o.Find('norm'), False);

    // colors
    arr := o.Arrays['colors'];
    if (arr<>nil) and (arr.Count>0) then begin
      SetLength(colors, arr.Count);
      for i:=0 to arr.Count-1 do begin
        cstr := arr.Items[i].AsString;
        if (Length(cstr)>0) and (cstr[1]='#') then Delete(cstr,1,1);
        colors[i] := color_from_hex(cstr);
      end;
    end else begin
      SetLength(colors, 0);
    end;

    // positions
    arr := o.Arrays['positions'];
    if (arr<>nil) and (arr.Count>0) then begin
      SetLength(positions, arr.Count);
      for i:=0 to arr.Count-1 do positions[i] := arr.Items[i].AsFloat;
    end else begin
      SetLength(positions, 0);
    end;

    if usePos then
      obj := TPaletteStrategy.CreateWithPositions(mode, colors, positions, shortest, norm)
    else
      obj := TPaletteStrategy.CreateEven(mode, colors, shortest);

    // 可选：基本校验
    if (obj<>nil) and obj.Validate(msg) then Result := True else begin obj := nil; Result := False; end;
  finally
    j.Free;
  end;
end;

end.

