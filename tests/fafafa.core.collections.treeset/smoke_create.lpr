program smoke_create;
{$mode objfpc}{$H+}
{$I ../../src/fafafa.core.settings.inc}
uses
  SysUtils, fafafa.core.collections.orderedset.rb;
begin
  var S := specialize TRBTreeSet<Integer>.Create;
  try
    Writeln('created');
    if S.Insert(1) then Writeln('ins1 ok');
    if S.ContainsKey(1) then Writeln('has1 ok');
  finally
    S.Free;
  end;
end.

