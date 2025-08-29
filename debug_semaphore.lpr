program debug_semaphore;

{$mode objfpc}{$H+}
{$CODEPAGE UTF8}

uses
  SysUtils, BaseUnix, Unix, UnixType;

type
  PSem = Pointer;

function sem_open(name: PAnsiChar; oflag: cint): PSem; cdecl; external 'c';
function sem_open_mode(name: PAnsiChar; oflag: cint; mode: mode_t; value: cuint): PSem; cdecl; external 'c' name 'sem_open';
function sem_close(sem: PSem): cint; cdecl; external 'c';
function sem_unlink(name: PAnsiChar): cint; cdecl; external 'c';

const
  SEM_FAILED = PSem(-1);

var
  LSem1, LSem2: PSem;
  LName: AnsiString;
  LFlags: cint;
  LError: cint;

begin
  LName := '/debug_test_mutex';
  
  WriteLn('调试 POSIX named semaphore 行为');
  WriteLn('================================');
  
  // 清理可能存在的信号量
  sem_unlink(PAnsiChar(LName));
  
  WriteLn('1. 创建第一个信号量实例...');
  LFlags := O_CREAT or O_EXCL;
  LSem1 := sem_open_mode(PAnsiChar(LName), LFlags, S_IRUSR or S_IWUSR, 1);
  
  if LSem1 = SEM_FAILED then
  begin
    LError := fpGetErrno;
    WriteLn('   失败: ', SysErrorMessage(LError));
    if LError = ESysEEXIST then
      WriteLn('   信号量已存在，尝试打开...')
    else
      Exit;
  end
  else
    WriteLn('   成功创建，应该是创建者');
  
  WriteLn('2. 创建第二个信号量实例...');
  LFlags := O_CREAT or O_EXCL;
  LSem2 := sem_open_mode(PAnsiChar(LName), LFlags, S_IRUSR or S_IWUSR, 1);
  
  if LSem2 = SEM_FAILED then
  begin
    LError := fpGetErrno;
    WriteLn('   创建失败: ', SysErrorMessage(LError));
    if LError = ESysEEXIST then
    begin
      WriteLn('   信号量已存在（正确），尝试打开现有的...');
      LSem2 := sem_open(PAnsiChar(LName), 0);
      if LSem2 = SEM_FAILED then
        WriteLn('   打开失败: ', SysErrorMessage(fpGetErrno))
      else
        WriteLn('   成功打开现有信号量，不是创建者');
    end;
  end
  else
    WriteLn('   意外：第二次创建成功了！这不应该发生');
  
  // 清理
  if LSem1 <> SEM_FAILED then
    sem_close(LSem1);
  if LSem2 <> SEM_FAILED then
    sem_close(LSem2);
  sem_unlink(PAnsiChar(LName));
  
  WriteLn('调试完成');
end.
