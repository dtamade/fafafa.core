program crossprocess_test;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, fafafa.core.sync.namedRWLock;

var
  LRWLock: INamedRWLock;
  LWriteGuard: INamedRWLockWriteGuard;
  LReadGuard: INamedRWLockReadGuard;
  LProcessType: string;
  I: Integer;

begin
  if ParamCount < 1 then
  begin
    WriteLn('用法: crossprocess_test <writer|reader>');
    Halt(1);
  end;
  
  LProcessType := ParamStr(1);
  
  try
    // 创建或打开命名读写锁
    LRWLock := MakeNamedRWLock('test_crossprocess_rwlock');
    WriteLn('成功创建/打开命名读写锁');
    
    if LProcessType = 'writer' then
    begin
      WriteLn('写者进程启动...');
      for I := 1 to 5 do
      begin
        WriteLn('尝试获取写锁 #', I);
        LWriteGuard := LRWLock.WriteLock;
        WriteLn('获取写锁成功，持有 2 秒...');
        Sleep(2000);
        LWriteGuard := nil; // 释放写锁
        WriteLn('释放写锁');
        Sleep(500);
      end;
    end
    else if LProcessType = 'reader' then
    begin
      WriteLn('读者进程启动...');
      for I := 1 to 10 do
      begin
        WriteLn('尝试获取读锁 #', I);
        LReadGuard := LRWLock.ReadLock;
        WriteLn('获取读锁成功，持有 1 秒...');
        Sleep(1000);
        LReadGuard := nil; // 释放读锁
        WriteLn('释放读锁');
        Sleep(200);
      end;
    end
    else
    begin
      WriteLn('无效的进程类型: ', LProcessType);
      Halt(1);
    end;
    
    WriteLn('进程完成');
    
  except
    on E: Exception do
    begin
      WriteLn('错误: ', E.Message);
      Halt(1);
    end;
  end;
end.
