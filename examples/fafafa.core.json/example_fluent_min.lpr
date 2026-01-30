program example_fluent_min;

{$MODE OBJFPC}{$H+}

uses
  SysUtils,
  fafafa.core.mem.allocator,
  fafafa.core.json.core,
  fafafa.core.json.fluent;

procedure Run;
var B: TJsonBuilderF; D: IJsonDocF; S: String;
begin
  // Build nested object
  B := JsonF.NewBuilder(nil).Obj
        .BeginObj('user').PutStr('name','a')
          .BeginArr('roles').AddStr('dev').ArrAddObj.PutStr('k','v').EndObj.EndArr
        .EndObj;

  // Output pretty JSON
  S := B.ToJson([jwfPretty], 0);
  Writeln(S);

  // Save to file
  B.SaveToFile('example_fluent_min.json', [jwfPretty], 0);

  // Parse back
  D := JsonF.ParseFile('example_fluent_min.json');
  Writeln(D.View('/user/name').AsStrOrDefault('<none>'));
end;

begin
  Run;
end.

