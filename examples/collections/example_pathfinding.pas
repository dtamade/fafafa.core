program example_pathfinding;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}
{$IFDEF WINDOWS}{$CODEPAGE UTF8}{$ENDIF}

uses
  SysUtils,
  fafafa.core.collections.base,
  fafafa.core.collections.priorityqueue,
  fafafa.core.collections.hashset;

type
  TPoint = record
    X, Y: Integer;
  end;

  TNode = record
    Pos: TPoint;
    Cost: Integer;
    Heuristic: Integer;
    
    function TotalCost: Integer;
  end;

function TNode.TotalCost: Integer;
begin
  Result := Cost + Heuristic;
end;

function MakePoint(aX, aY: Integer): TPoint;
begin
  Result.X := aX;
  Result.Y := aY;
end;

function MakeNode(const aPos: TPoint; aCost, aHeuristic: Integer): TNode;
begin
  Result.Pos := aPos;
  Result.Cost := aCost;
  Result.Heuristic := aHeuristic;
end;

function ManhattanDistance(const aFrom, aTo: TPoint): Integer;
begin
  Result := Abs(aFrom.X - aTo.X) + Abs(aFrom.Y - aTo.Y);
end;

function CompareNode(const aLeft, aRight: TNode; aData: Pointer): SizeInt;
begin
  if aLeft.TotalCost < aRight.TotalCost then
    Result := -1
  else if aLeft.TotalCost > aRight.TotalCost then
    Result := 1
  else
    Result := 0;
end;

function PointToString(const aPoint: TPoint): string;
begin
  Result := Format('(%d,%d)', [aPoint.X, aPoint.Y]);
end;

{ 简化的 A* 寻路演示 }
procedure FindPath(const aStart, aGoal: TPoint; const aObstacles: array of TPoint);
var
  LOpenSet: specialize TPriorityQueue<TNode>;
  LClosedSet: specialize IHashSet<string>;
  LCurrent: TNode;
  LNeighbors: array[0..3] of TPoint;
  LNeighbor: TPoint;
  LNewNode: TNode;
  i: Integer;
  LIsObstacle: Boolean;
  LObstacle: TPoint;
begin
  WriteLn('--- 开始寻路 ---');
  WriteLn(Format('起点: %s', [PointToString(aStart)]));
  WriteLn(Format('终点: %s', [PointToString(aGoal)]));
  WriteLn;
  
  LOpenSet := specialize TPriorityQueue<TNode>.Create(@CompareNode);
  LClosedSet := specialize MakeHashSet<string>();
  
  try
    // 添加起点
    LOpenSet.Push(MakeNode(aStart, 0, ManhattanDistance(aStart, aGoal)));
    
    while LOpenSet.GetCount > 0 do
    begin
      LCurrent := LOpenSet.Pop;
      
      WriteLn(Format('探索: %s (代价=%d, 启发=%d)', [
        PointToString(LCurrent.Pos),
        LCurrent.Cost,
        LCurrent.Heuristic
      ]));
      
      // 到达目标
      if (LCurrent.Pos.X = aGoal.X) and (LCurrent.Pos.Y = aGoal.Y) then
      begin
        WriteLn;
        WriteLn(Format('*** 找到路径！总代价: %d ***', [LCurrent.Cost]));
        Exit;
      end;
      
      LClosedSet.Add(PointToString(LCurrent.Pos));
      
      // 探索邻居（上下左右）
      LNeighbors[0] := MakePoint(LCurrent.Pos.X, LCurrent.Pos.Y - 1); // 上
      LNeighbors[1] := MakePoint(LCurrent.Pos.X, LCurrent.Pos.Y + 1); // 下
      LNeighbors[2] := MakePoint(LCurrent.Pos.X - 1, LCurrent.Pos.Y); // 左
      LNeighbors[3] := MakePoint(LCurrent.Pos.X + 1, LCurrent.Pos.Y); // 右
      
      for i := 0 to 3 do
      begin
        LNeighbor := LNeighbors[i];
        
        // 检查是否已访问
        if LClosedSet.Contains(PointToString(LNeighbor)) then
          Continue;
        
        // 检查是否是障碍物
        LIsObstacle := False;
        for LObstacle in aObstacles do
          if (LObstacle.X = LNeighbor.X) and (LObstacle.Y = LNeighbor.Y) then
          begin
            LIsObstacle := True;
            Break;
          end;
        
        if LIsObstacle then
          Continue;
        
        // 添加到开放集
        LNewNode := MakeNode(
          LNeighbor,
          LCurrent.Cost + 1,
          ManhattanDistance(LNeighbor, aGoal)
        );
        LOpenSet.Push(LNewNode);
      end;
    end;
    
    WriteLn;
    WriteLn('*** 未找到路径 ***');
  finally
    LOpenSet.Free;
  end;
end;

var
  LObstacles: array[0..2] of TPoint;
begin
  WriteLn('=== 路径查找示例（A* 算法）===');
  WriteLn;
  
  // 定义障碍物
  LObstacles[0] := MakePoint(1, 1);
  LObstacles[1] := MakePoint(1, 2);
  LObstacles[2] := MakePoint(1, 3);
  
  FindPath(MakePoint(0, 0), MakePoint(3, 3), LObstacles);
  WriteLn;
  
  WriteLn('=== 示例完成 ===');
  WriteLn('提示：PriorityQueue 是 A* 等最短路径算法的核心数据结构');
end.

