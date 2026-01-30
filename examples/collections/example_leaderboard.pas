program example_leaderboard;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.treeset;

type
  TPlayer = record
    Name: string;
    Score: Integer;
  end;

function ComparePlayerByScore(const aLeft, aRight: TPlayer; aData: Pointer): SizeInt;
begin
  // 按分数降序排序（分数高的排前面）
  if aLeft.Score > aRight.Score then
    Result := -1
  else if aLeft.Score < aRight.Score then
    Result := 1
  else
    // 分数相同时按名字排序
    Result := CompareStr(aLeft.Name, aRight.Name);
end;

function MakePlayer(const aName: string; aScore: Integer): TPlayer;
begin
  Result.Name := aName;
  Result.Score := aScore;
end;

{ 排行榜系统 }
procedure DemoLeaderboard;
var
  LLeaderboard: specialize TTreeSet<TPlayer>;
  LPlayer: TPlayer;
  LRank: Integer;
begin
  WriteLn('=== 游戏排行榜示例 ===');
  WriteLn;
  
  LLeaderboard := specialize TTreeSet<TPlayer>.Create(@ComparePlayerByScore);
  try
    // 场景1：添加玩家分数
    WriteLn('--- 场景1：添加玩家分数 ---');
    LLeaderboard.Add(MakePlayer('Alice', 1250));
    LLeaderboard.Add(MakePlayer('Bob', 980));
    LLeaderboard.Add(MakePlayer('Charlie', 1500));
    LLeaderboard.Add(MakePlayer('David', 1100));
    LLeaderboard.Add(MakePlayer('Eve', 1500)); // 同分
    LLeaderboard.Add(MakePlayer('Frank', 850));
    WriteLn(Format('已添加 %d 名玩家', [LLeaderboard.GetCount]));
    WriteLn;
    
    // 场景2：显示排行榜（自动按分数降序）
    WriteLn('--- 场景2：完整排行榜 ---');
    LRank := 1;
    for LPlayer in LLeaderboard do
    begin
      WriteLn(Format('#%d  %s%s - %d 分', [
        LRank,
        LPlayer.Name,
        StringOfChar(' ', 12 - Length(LPlayer.Name)),
        LPlayer.Score
      ]));
      Inc(LRank);
    end;
    WriteLn;
    
    // 场景3：获取前三名
    WriteLn('--- 场景3：前三名玩家 ---');
    LRank := 1;
    for LPlayer in LLeaderboard do
    begin
      if LRank > 3 then Break;
      
      case LRank of
        1: Write('🥇 ');
        2: Write('🥈 ');
        3: Write('🥉 ');
      end;
      
      WriteLn(Format('%s - %d 分', [LPlayer.Name, LPlayer.Score]));
      Inc(LRank);
    end;
    WriteLn;
    
    // 场景4：更新分数
    WriteLn('--- 场景4：Bob 获得新分数 ---');
    LLeaderboard.Remove(MakePlayer('Bob', 980)); // 移除旧记录
    LLeaderboard.Add(MakePlayer('Bob', 1600));   // 添加新分数
    WriteLn('Bob 的新分数: 1600');
    WriteLn;
    
    WriteLn('--- 更新后的前三名 ---');
    LRank := 1;
    for LPlayer in LLeaderboard do
    begin
      if LRank > 3 then Break;
      WriteLn(Format('#%d  %s - %d 分', [LRank, LPlayer.Name, LPlayer.Score]));
      Inc(LRank);
    end;
    WriteLn;
    
    WriteLn('=== 示例完成 ===');
    WriteLn('提示：TreeSet 自动排序，非常适合排行榜、积分榜等场景');
  finally
    LLeaderboard.Free;
  end;
end;

begin
  DemoLeaderboard;
end.

