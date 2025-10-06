program test_string_ultra_simple;

{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.collections.simplehashmap;

type
  TStringIntMap = specialize TSimpleHashMap<string, Integer>;

var
  Map: TStringIntMap;
  Value: Integer;

begin
  WriteLn('Creating map...');
  Map := TStringIntMap.Create(16, 0.75, @DefaultHashString, @DefaultEqualsString);
  
  WriteLn('Putting value...');
  Map.Put('hello', 42);
  
  WriteLn('Getting value...');
  if Map.TryGetValue('hello', Value) then
    WriteLn('Success! Value = ', Value)
  else
    WriteLn('Failed to get value');
    
  Map.Free;
  WriteLn('Done!');
end.
