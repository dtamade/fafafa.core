unit yaml_diag_helper;

{$MODE OBJFPC}{$H+}

interface

uses SysUtils, TypInfo, fafafa.core.yaml, fafafa.core.yaml.types, fafafa.core.yaml.diag;

// 简单的测试辅助：把 diag 回调输出收集到内存列表

Type
  TDiagSink = class
  private
    FItems: array of string;
  public
    procedure Clear;
    procedure Add(const S: string);
    function ToText: string;
    function Count: Integer;
    class function FormatPos(line, col: SizeUInt; line2: SizeUInt = 0; col2: SizeUInt = 0): string; static;
  end;

procedure DiagCallback(userdata: Pointer; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
procedure DiagCallback2(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
// 扩展：带 end 位置信息的回调（用于测试输出范围）
procedure DiagCallback2Ex(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; line2, col2: SizeUInt; const msg: PChar); cdecl;

implementation



procedure TDiagSink.Clear;
begin
  SetLength(FItems, 0);
end;

class function TDiagSink.FormatPos(line, col: SizeUInt; line2: SizeUInt = 0; col2: SizeUInt = 0): string;
begin
  if (line2=0) and (col2=0) then
    Result := Format(' L%u C%u ', [QWord(line), QWord(col)])
  else
    Result := Format(' L%u C%u - L%u C%u ', [QWord(line), QWord(col), QWord(line2), QWord(col2)]);
end;



procedure TDiagSink.Add(const S: string);
var n: Integer;
begin
  n := Length(FItems);
  SetLength(FItems, n+1);
  FItems[n] := S;
end;

function TDiagSink.ToText: string;
var i: Integer;
begin
  Result := '';
  for i:=0 to High(FItems) do
  begin
    if i>0 then Result += LineEnding;
    Result += FItems[i];
  end;
end;

function TDiagSink.Count: Integer;
begin
  Result := Length(FItems);
end;

procedure DiagCallback2Ex(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; line2, col2: SizeUInt; const msg: PChar); cdecl;
var S: string; sink: TDiagSink;
begin
  if userdata=nil then Exit;
  sink := TDiagSink(userdata);
  S := Format('[%s][%d][%d]%s%s', [GetEnumName(TypeInfo(TFyDiagCode), Ord(code)), Ord(level), Ord(module),
    TDiagSink.FormatPos(line, col, line2, col2), string(msg)]);
  sink.Add(S);
end;



procedure DiagCallback(userdata: Pointer; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
var S: string; sink: TDiagSink;
begin
  if userdata=nil then Exit;
  sink := TDiagSink(userdata);
  S := Format('[%d][%d] L%u C%u %s', [Ord(level), Ord(module), QWord(line), QWord(col), string(msg)]);
  sink.Add(S);
end;

procedure DiagCallback2(userdata: Pointer; code: TFyDiagCode; level: TFyErrorType; module: TFyErrorModule; line, col: SizeUInt; const msg: PChar); cdecl;
var S: string; sink: TDiagSink;
begin
  if userdata=nil then Exit;
  sink := TDiagSink(userdata);
  S := Format('[%s][%d][%d] L%u C%u %s', [GetEnumName(TypeInfo(TFyDiagCode), Ord(code)), Ord(level), Ord(module), QWord(line), QWord(col), string(msg)]);
  sink.Add(S);
end;

end.

