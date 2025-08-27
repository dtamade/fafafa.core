unit Test_core_persistent_flags;

{$mode ObjFPC}{$H+}
{$CODEPAGE UTF8}

interface

uses
  SysUtils, fpcunit, testregistry,
  fafafa.core.args, fafafa.core.args.command, fafafa.core.args.schema, fafafa.core.args.help;

type
  { TTestCase_Core_Persistent_Flags }
  TTestCase_Core_Persistent_Flags = class(TTestCase)
  published
    procedure Test_ParentFlags_Propagate_To_Child;
    procedure Test_Child_SameName_Flag_Not_Overridden;
    procedure Test_Persistent_Aliases_Propagate_MultiLevel;
    procedure Test_Child_Owns_Flag_And_Aliases_When_Parent_Persistent_SameName;
  end;



procedure RegisterTests;

implementation

procedure RegisterTests;
begin
  testregistry.RegisterTest(TTestCase_Core_Persistent_Flags);
end;

function H_Dummy(const A: IArgs): Integer; begin Exit(0); end;

procedure TTestCase_Core_Persistent_Flags.Test_ParentFlags_Propagate_To_Child;
var
  Root, Tree, child: ICommand;
  SpecP, SpecC: IArgsCommandSpec;
  S: string;
  f: IArgsFlagSpec;
  i: Integer;
  found: Boolean;
begin
  // Build tree: parent -> child (handler on child)
  Tree := NewCommandPath(['parent','child'], @H_Dummy, 'child desc');
  // Attach persistent flag to parent
  SpecP := NewCommandSpec;
  f := NewFlagSpec('verbose', 'enable verbose', False, 'bool');
  f.SetPersistent(True);
  SpecP.AddFlag(f);
  (Tree as ICommand).SetSpec(SpecP);
  // Register under root
  Root := NewCommand('root');
  Root.Register(Tree);
  // child should have inherited "verbose"
  child := Root.FindChildByName('parent', True).FindChildByName('child', True);
  SpecC := child.GetSpec;
  AssertNotNull(SpecC);
  found := False;
  for i := 0 to SpecC.FlagCount-1 do
    if SameText(SpecC.FlagAt(i).Name, 'verbose') then begin found := True; Break; end;
  AssertTrue(found);
  // Render usage should include Flags: --verbose
  S := RenderUsage(child);
  AssertTrue(Pos('--verbose', S)>0);
end;

procedure TTestCase_Core_Persistent_Flags.Test_Child_SameName_Flag_Not_Overridden;
var
  Root, Tree, child: ICommand;
  SpecP, SpecC, sSpec: IArgsCommandSpec;
  pf: IArgsFlagSpec;
  i: Integer;
  found: Boolean;
  hasParentDefault: Boolean;
begin
  // Build tree: parent -> child (handler on child)
  Tree := NewCommandPath(['parent','child'], @H_Dummy, 'child desc');
  // parent persistent flag
  SpecP := NewCommandSpec;
  pf := NewFlagSpec('mode', 'parent mode', False, 'string','p');
  pf.SetPersistent(True);
  SpecP.AddFlag(pf);
  (Tree as ICommand).SetSpec(SpecP);
  // child defines same name flag; should win (first wins) -> we don't override
  child := Tree.FindChildByName('child', True);
  SpecC := NewCommandSpec;
  SpecC.AddFlag(NewFlagSpec('mode', 'child mode', False, 'string','c'));
  child.SetSpec(SpecC);
  // register
  Root := NewCommand('root');
  Root.Register(Tree);
  // After register, child's spec should keep its own 'mode' (not replaced by parent)
  sSpec := Root.FindChildByName('parent', True).FindChildByName('child', True).GetSpec;
  found := False;
  hasParentDefault := False;
  for i := 0 to sSpec.FlagCount-1 do
  begin
    if SameText(sSpec.FlagAt(i).Name, 'mode') then
    begin
      found := True;
      hasParentDefault := sSpec.FlagAt(i).DefaultValue = 'p';
      Break;
    end;
  end;
  AssertTrue(found);
  AssertFalse(hasParentDefault);
end;
procedure TTestCase_Core_Persistent_Flags.Test_Persistent_Aliases_Propagate_MultiLevel;
var
  Root, Tree, child, grand, g: ICommand;
  SpecP, gs: IArgsCommandSpec;
  S: string;
  pf: IArgsFlagSpec;
  i, j: Integer;
  found, aliasC, aliasConf: Boolean;
  als: TStringArray;
begin
  // Build: parent -> child -> grand
  Tree := NewCommand('parent');
  child := NewCommand('child');
  grand := NewCommand('grand');
  child.AddChild(grand);
  Tree.AddChild(child);
  // Parent has persistent flag with aliases
  SpecP := NewCommandSpec;
  pf := NewFlagSpec('config', 'config path', False, 'string');
  pf.AddAlias('c');
  pf.AddAlias('conf');
  pf.SetPersistent(True);
  SpecP.AddFlag(pf);
  Tree.SetSpec(SpecP);
  // Register under root
  Root := NewCommand('root');
  Root.Register(Tree);
  // Verify on grandchild
  g := Root.FindChildByName('parent', True).FindChildByName('child', True).FindChildByName('grand', True);
  gs := g.GetSpec;
  AssertNotNull(gs);
  found := False; aliasC := False; aliasConf := False;
  for i := 0 to gs.FlagCount-1 do
    if SameText(gs.FlagAt(i).Name, 'config') then
    begin
      found := True;
      als := gs.FlagAt(i).Aliases;
      for j := 0 to High(als) do
      begin
        if SameText(als[j], 'c') then aliasC := True;
        if SameText(als[j], 'conf') then aliasConf := True;
      end;
      Break;
    end;
  AssertTrue(found);
  AssertTrue(aliasC);
  AssertTrue(aliasConf);
  // Render should also include --config and recognize aliases from spec (shown as name; aliases are metadata)
  S := RenderUsage(g);
  AssertTrue(Pos('--config', S)>0);
end;

procedure TTestCase_Core_Persistent_Flags.Test_Child_Owns_Flag_And_Aliases_When_Parent_Persistent_SameName;
var
  Root, P, C: ICommand;
  SpecP, SpecC, gs: IArgsCommandSpec;
  pf, cf: IArgsFlagSpec;
  i, j: Integer;
  found, hasC, hasM, hasP: Boolean;
  als: TStringArray;
begin
  // Parent persistent 'mode' with aliases; child defines same flag with its own aliases
  P := NewCommand('parent');
  C := NewCommand('child'); P.AddChild(C);
  SpecP := NewCommandSpec;
  pf := NewFlagSpec('mode', 'parent mode', False, 'string','p'); pf.SetPersistent(True);
  pf.AddAlias('m'); pf.AddAlias('pmode');
  SpecP.AddFlag(pf); P.SetSpec(SpecP);
  // Child's own spec overrides by First-Wins (child kept); aliases should come from child only
  SpecC := NewCommandSpec;
  cf := NewFlagSpec('mode', 'child mode', False, 'string','c');
  cf.AddAlias('cmode'); SpecC.AddFlag(cf); C.SetSpec(SpecC);
  Root := NewCommand('root'); Root.Register(P);
  gs := Root.FindChildByName('parent', True).FindChildByName('child', True).GetSpec;
  // Find 'mode' and verify aliases are child's (cmode) and not parent's (m/pmode)
  found := False; hasC := False; hasM := False; hasP := False;
  for i := 0 to gs.FlagCount-1 do
    if SameText(gs.FlagAt(i).Name, 'mode') then
    begin
      found := True;
      als := gs.FlagAt(i).Aliases;
      for j := 0 to High(als) do begin if SameText(als[j],'cmode') then hasC := True;
                                      if SameText(als[j],'m') then hasM := True;
                                      if SameText(als[j],'pmode') then hasP := True; end;
      Break;
    end;
  AssertTrue(found);
  AssertTrue(hasC);
  AssertFalse(hasM);
  AssertFalse(hasP);
end;

end.

