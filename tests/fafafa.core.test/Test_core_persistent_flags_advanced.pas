unit Test_core_persistent_flags_advanced;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command, fafafa.core.args.schema, fafafa.core.args.help;

type
  { TTestCase_Core_Persistent_Flags_Advanced }
  TTestCase_Core_Persistent_Flags_Advanced = class(TTestCase)
  published
    procedure Test_MultiAncestor_SameName_Alias_DeDup;
  end;

procedure RegisterTests;

implementation

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_Persistent_Flags_Advanced);
end;

function H_NoOp(const A: IArgs): Integer; begin Exit(0); end;

procedure TTestCase_Core_Persistent_Flags_Advanced.Test_MultiAncestor_SameName_Alias_DeDup;
var Root, P, G, C: ICommand; SpecP, SpecG: IArgsCommandSpec; gspec: IArgsCommandSpec;
    gf, pf: IArgsFlagSpec;
    i,j: Integer; found: Boolean; aliasP, aliasG: Boolean; varAls: TStringArray;
begin
  // Build: grand(parent)-parent-child
  G := NewCommand('grand');
  P := NewCommand('parent');
  C := NewCommand('child');
  P.AddChild(C); G.AddChild(P);

  // Grand defines persistent 'mode' with alias 'g'
  SpecG := NewCommandSpec;
  gf := NewFlagSpec('mode', 'grand mode', False, 'string');
  gf.AddAlias('g'); gf.SetPersistent(True);
  SpecG.AddFlag(gf); G.SetSpec(SpecG);

  // Parent defines persistent 'mode' with alias 'm'（同名）
  SpecP := NewCommandSpec;
  pf := NewFlagSpec('mode', 'parent mode', False, 'string');
  pf.AddAlias('m'); pf.SetPersistent(True);
  SpecP.AddFlag(pf); P.SetSpec(SpecP);

  // Register and fetch child's spec
  Root := NewCommand('root');
  Root.Register(G);
  gspec := Root.FindChildByName('grand', True).FindChildByName('parent', True).FindChildByName('child', True).GetSpec;
  AssertNotNull(gspec);

  // Dedup expectation: child should have one 'mode' with aliases {'g','m'} (order not enforced)
  found := False; aliasP := False; aliasG := False;
  for i := 0 to gspec.FlagCount-1 do
    if SameText(gspec.FlagAt(i).Name, 'mode') then
    begin
      found := True;
      // FPC doesn't support inline var; declare explicitly (declared in var section above)
      varAls := gspec.FlagAt(i).Aliases;
      for j := 0 to High(varAls) do begin if SameText(varAls[j],'m') then aliasP := True;
                                          if SameText(varAls[j],'g') then aliasG := True; end;
      Break;
    end;
  AssertTrue(found);
  AssertTrue(aliasP);
  AssertTrue(aliasG);
  // RenderUsage should include --mode (aliases not printed as names; treated as metadata)
  AssertTrue(Pos('--mode', RenderUsage(Root.FindChildByName('grand', True).FindChildByName('parent', True).FindChildByName('child', True)))>0);
end;

end.

