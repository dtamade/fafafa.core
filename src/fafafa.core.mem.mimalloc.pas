{
```text
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/  Studio

```
# fafafa.core.mem.mimalloc - Mimalloc C 库绑定门面

## Abstract 摘要

Mimalloc C library binding facade.
Mimalloc C 库绑定门面，没有 C 库返回 nil。

## Usage 使用

```pascal
uses fafafa.core.mem.mimalloc;

var
  Alloc: IAlloc;
begin
  Alloc := GetMimalloc;
  if Alloc = nil then
    WriteLn('mimalloc not available');
end;
```

## Declaration 声明

Author:    fafafaStudio
Contact:   dtamade@gmail.com | QQ Group: 685403987 | QQ:179033731
Copyright: (c) 2025 fafafaStudio. All rights reserved.
}

unit fafafa.core.mem.mimalloc;

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.mem.alloc;

{**
 * GetMimalloc
 *
 * @desc 获取 mimalloc C 库分配器
 *       Get mimalloc C library allocator
 *
 * @return IAlloc mimalloc 分配器，没有 C 库返回 nil
 *}
function GetMimalloc: IAlloc;

{**
 * IsMimallocAvailable
 *
 * @desc 检查 mimalloc C 库是否可用
 *       Check if mimalloc C library is available
 *
 * @return True 如果 C 库可用
 *}
function IsMimallocAvailable: Boolean;

implementation

uses
  fafafa.core.mem.mimalloc.binding;

var
  GMimalloc: IAlloc = nil;
  GChecked: Boolean = False;
  GMimallocLock: TRTLCriticalSection;  // 线程安全锁

function IsMimallocAvailable: Boolean;
begin
  Result := fafafa.core.mem.mimalloc.binding.IsMimallocAvailable;
end;

function GetMimalloc: IAlloc;
begin
  // 双重检查锁定 - 线程安全的单例初始化
  if not GChecked then
  begin
    EnterCriticalSection(GMimallocLock);
    try
      if not GChecked then
      begin
        if IsMimallocAvailable then
        begin
          try
            GMimalloc := GetMimallocBinding;
          except
            GMimalloc := nil;
          end;
        end;
        GChecked := True;  // 标记为已检查（即使失败）
      end;
    finally
      LeaveCriticalSection(GMimallocLock);
    end;
  end;
  Result := GMimalloc;
end;

initialization
  InitCriticalSection(GMimallocLock);

finalization
  DoneCriticalSection(GMimallocLock);
  GMimalloc := nil;

end.
