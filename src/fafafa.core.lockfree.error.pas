unit fafafa.core.lockfree.error;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

{**
 * fafafa.core.lockfree.error - 无锁数据结构错误与异常类型
 *
 * 将无锁组件共用的异常类型集中在本单元，避免循环引用，
 * 供各子模块（queue/stack/hashmap 等）直接 uses 本单元。
 *}

interface

uses
  SysUtils,
  fafafa.core.base;  // ✅ LOCKFREE-001: 引入 ECore 基类

type
  // 无锁数据结构异常基类
  ELockFreeError = class(ECore);  // ✅ LOCKFREE-001: 继承自 ECore

  // 队列相关异常
  EQueueFullError = class(ELockFreeError);
  EQueueEmptyError = class(ELockFreeError);

  // 栈相关异常
  EStackEmptyError = class(ELockFreeError);

implementation

end.
