program example_hot_path_min;

{$MODE OBJFPC}{$H+}
{$CODEPAGE UTF8}
{$I fafafa.core.settings.inc}


uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json;

procedure Run;
var
  Reader: IJsonReader;
  Doc: IJsonDocument;
  Root, V: IJsonValue;
  Cnt: Int64;
  S: String;
begin
  // 示例数据包含对象、数组与数值
  Reader := NewJsonReader(GetRtlAllocator);
  Doc := Reader.ReadFromString('{"name":"Ada","count":42,"tags":["fp","yyjson"],"meta":{"lang":"pas"}}', []);
  Root := Doc.Root;

  // 1) 热路径：Raw-Key 对象遍历（不为 Key 分配 String）
  Writeln('Raw-Key iteration:');
  JsonObjectForEachRaw(Root,
    function(KeyPtr: PChar; KeyLen: SizeUInt; Val: IJsonValue): Boolean
    begin
      if (KeyLen=4) and (StrLComp(KeyPtr, 'name', 4)=0) then
        Writeln('  name=', Val.GetString)
      else
      if (KeyLen=5) and (StrLComp(KeyPtr, 'count', 5)=0) then
        Writeln('  count=', Val.GetInteger)
      else
      if (KeyLen=4) and (StrLComp(KeyPtr, 'tags', 4)=0) and Val.IsArray then
        Writeln('  tags.size=', Val.GetArraySize)
      else
      if (KeyLen=4) and (StrLComp(KeyPtr, 'meta', 4)=0) and Val.IsObject then
        Writeln('  meta.ok');
      Result := True;
    end);

  // 2) 非关键路径：TryGet/OrDefault 组合（避免异常）
  if JsonTryGetObjectValue(Root, 'count', V) and JsonTryGetInt(V, Cnt) then
    Writeln('TryGet count=', Cnt)
  else
    Writeln('TryGet count missing, default=0');

  S := JsonGetStrOrDefault(Root.GetObjectValue('none'), '<nil>');
  Writeln('OrDefault none=', S);
end;

begin
  Run;
end.

