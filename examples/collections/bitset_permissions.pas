program bitset_permissions;

{$mode objfpc}{$H+}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections,
  fafafa.core.collections.bitset;

{**
 * BitSet 权限管理示例
 * 演示如何使用位运算高效管理用户权限
 *}
const
  // 权限位定义
  PERM_READ    = 0;
  PERM_WRITE   = 1;
  PERM_EXECUTE = 2;
  PERM_DELETE  = 3;
  PERM_ADMIN   = 4;

  // 权限名称
  PERM_NAMES: array[0..4] of string = (
    'Read', 'Write', 'Execute', 'Delete', 'Admin'
  );

{ 辅助函数 }

procedure PrintPermissions(const aName: string; const aPerms: IBitSet);
var
  i: Integer;
  LHasAny: Boolean;
begin
  Write(aName, ' 权限: ');
  LHasAny := False;
  for i := 0 to High(PERM_NAMES) do
  begin
    if aPerms.Test(i) then
    begin
      if LHasAny then Write(', ');
      Write(PERM_NAMES[i]);
      LHasAny := True;
    end;
  end;
  if not LHasAny then
    Write('(无)');
  WriteLn(' [', aPerms.Cardinality, ' 项]');
end;

{ 主程序 }
var
  LUserPerms, LRequiredPerms, LResult: IBitSet;
begin
  WriteLn('=== BitSet 权限管理示例 ===');
  WriteLn;
  
  // 1. 创建用户权限
  WriteLn('1. 创建普通用户权限');
  LUserPerms := MakeBitSet();
  LUserPerms.SetBit(PERM_READ);
  LUserPerms.SetBit(PERM_WRITE);
  PrintPermissions('普通用户', LUserPerms);
  WriteLn;
  
  // 2. 创建必要权限要求
  WriteLn('2. 文件删除需要的权限');
  LRequiredPerms := MakeBitSet();
  LRequiredPerms.SetBit(PERM_WRITE);
  LRequiredPerms.SetBit(PERM_DELETE);
  PrintPermissions('必需权限', LRequiredPerms);
  WriteLn;
  
  // 3. 检查权限（交集）
  WriteLn('3. 检查用户是否拥有所有必需权限（AND）');
  LResult := LUserPerms.AndWith(LRequiredPerms);
  PrintPermissions('拥有的必需权限', LResult);
  if LResult.Cardinality = LRequiredPerms.Cardinality then
    WriteLn('  ✅ 权限充足')
  else
    WriteLn('  ❌ 权限不足（缺少 Delete 权限）');
  WriteLn;
  
  // 4. 提升用户权限
  WriteLn('4. 提升用户为管理员');
  LUserPerms.SetBit(PERM_DELETE);
  LUserPerms.SetBit(PERM_ADMIN);
  PrintPermissions('提升后的用户', LUserPerms);
  WriteLn;
  
  // 5. 合并权限（并集）
  WriteLn('5. 合并两个权限组（OR）');
  LResult := LUserPerms.OrWith(LRequiredPerms);
  PrintPermissions('合并权限', LResult);
  WriteLn;
  
  // 6. 权限差异（异或）
  WriteLn('6. 找出差异权限（XOR）');
  LResult := LUserPerms.XorWith(LRequiredPerms);
  PrintPermissions('差异权限', LResult);
  WriteLn;
  
  // 7. 撤销权限
  WriteLn('7. 撤销管理员权限');
  LUserPerms.ClearBit(PERM_ADMIN);
  PrintPermissions('撤销后的用户', LUserPerms);
  WriteLn;
  
  // 8. 性能演示 - 批量操作
  WriteLn('8. 性能演示：设置 10000 个权限位');
  var LLargeBitSet := MakeBitSet(10000);
  var i: Integer;
  var LStart, LEnd: TDateTime;
  
  LStart := Now;
  for i := 0 to 9999 do
    LLargeBitSet.SetBit(i);
  LEnd := Now;
  
  WriteLn('  设置 10000 位耗时: ', FormatDateTime('ss.zzz', LEnd - LStart), ' 秒');
  WriteLn('  置位数量: ', LLargeBitSet.Cardinality);
  WriteLn('  位容量: ', LLargeBitSet.BitCapacity);
  
  WriteLn;
  WriteLn('=== 示例完成 ===');
end.

