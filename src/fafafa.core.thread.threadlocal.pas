unit fafafa.core.thread.threadlocal;

{**
 * fafafa.core.thread.threadlocal - 线程本地存储模块
 *
 * @desc 提供线程安全的本地存储功能，包括：
 *       - IThreadLocal 接口：线程本地存储的标准接口
 *       - TThreadLocal 类：高性能的线程本地存储实现
 *       - 基于线程ID的隔离机制
 *       - 自动资源清理
 *
 * @author fafafa.core 开发团队
 * @version 1.0.0
 * @since 2025-08-08
 *}

{$mode objfpc}{$H+}
{$I fafafa.core.settings.inc}

interface

uses
  SysUtils, Classes,
  fafafa.core.sync;

type

  {**
   * 线程本地存储值类型
   *}
  TThreadLocalValue = Pointer;

  {**
   * 线程本地存储条目
   *}
  PThreadLocalEntry = ^TThreadLocalEntry;
  TThreadLocalEntry = record
    ThreadId: TThreadID;
    Value: TThreadLocalValue;
  end;

  {**
   * IThreadLocal
   *
   * @desc 线程本地存储接口
   *       提供线程安全的本地存储，每个线程有独立的值
   *}
  IThreadLocal = interface
    ['{D1E2F3A4-B5C6-7D8E-9F0A-B1C2D3E4F5A6}']

    {**
     * GetValue
     *
     * @desc 获取当前线程的值
     *
     * @return 返回当前线程存储的值，如果未设置则返回 nil
     *}
    function GetValue: TThreadLocalValue;

    {**
     * SetValue
     *
     * @desc 设置当前线程的值
     *
     * @params
     *    AValue: TThreadLocalValue 要存储的值
     *}
    procedure SetValue(AValue: TThreadLocalValue);

    {**
     * HasValue
     *
     * @desc 检查当前线程是否有值
     *
     * @return 有值返回 True，否则返回 False
     *}
    function HasValue: Boolean;

    {**
     * RemoveValue
     *
     * @desc 移除当前线程的值
     *}
    procedure RemoveValue;

    // 属性访问器
    property Value: TThreadLocalValue read GetValue write SetValue;
  end;

  {**
   * TThreadLocal
   *
   * @desc 线程本地存储实现类
   *       基于平台特定的线程本地存储API实现
   *}
  TThreadLocal = class(TInterfacedObject, IThreadLocal)
  private
    // 使用简单的线程安全字典实现，基于线程ID
    FValues: TList;
    FLock: ILock;

    function GetCurrentThreadId: TThreadID;
    function FindValueForThread(AThreadId: TThreadID): TThreadLocalValue;
    procedure SetValueForThread(AThreadId: TThreadID; AValue: TThreadLocalValue);
    procedure RemoveValueForThread(AThreadId: TThreadID);

  public
    constructor Create;
    destructor Destroy; override;

    function GetValue: TThreadLocalValue;
    procedure SetValue(AValue: TThreadLocalValue);
    function HasValue: Boolean;
    procedure RemoveValue;
  end;

implementation

{ TThreadLocal }

constructor TThreadLocal.Create;
begin
  inherited Create;
  FValues := TList.Create;
  FLock := TMutex.Create;
end;

destructor TThreadLocal.Destroy;
var
  LEntry: PThreadLocalEntry;
  I: Integer;
begin
  // 清理所有存储的值
  FLock.Acquire;
  try
    for I := 0 to FValues.Count - 1 do
    begin
      LEntry := PThreadLocalEntry(FValues[I]);
      Dispose(LEntry);
    end;
    FValues.Clear;
  finally
    FLock.Release;
  end;

  FreeAndNil(FValues);
  FLock := nil;
  inherited Destroy;
end;

function TThreadLocal.GetCurrentThreadId: TThreadID;
begin
  Result := TThread.CurrentThread.ThreadID;
end;

function TThreadLocal.FindValueForThread(AThreadId: TThreadID): TThreadLocalValue;
var
  LEntry: PThreadLocalEntry;
  I: Integer;
begin
  Result := nil;

  FLock.Acquire;
  try
    for I := 0 to FValues.Count - 1 do
    begin
      LEntry := PThreadLocalEntry(FValues[I]);
      if LEntry^.ThreadId = AThreadId then
      begin
        Result := LEntry^.Value;
        Exit;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

procedure TThreadLocal.SetValueForThread(AThreadId: TThreadID; AValue: TThreadLocalValue);
var
  LEntry: PThreadLocalEntry;
  I: Integer;
  LFound: Boolean;
begin
  LFound := False;

  FLock.Acquire;
  try
    // 查找现有条目
    for I := 0 to FValues.Count - 1 do
    begin
      LEntry := PThreadLocalEntry(FValues[I]);
      if LEntry^.ThreadId = AThreadId then
      begin
        LEntry^.Value := AValue;
        LFound := True;
        Break;
      end;
    end;

    // 如果没找到，创建新条目
    if not LFound then
    begin
      New(LEntry);
      LEntry^.ThreadId := AThreadId;
      LEntry^.Value := AValue;
      FValues.Add(LEntry);
    end;
  finally
    FLock.Release;
  end;
end;

procedure TThreadLocal.RemoveValueForThread(AThreadId: TThreadID);
var
  LEntry: PThreadLocalEntry;
  I: Integer;
begin
  FLock.Acquire;
  try
    for I := FValues.Count - 1 downto 0 do
    begin
      LEntry := PThreadLocalEntry(FValues[I]);
      if LEntry^.ThreadId = AThreadId then
      begin
        FValues.Delete(I);
        Dispose(LEntry);
        Break;
      end;
    end;
  finally
    FLock.Release;
  end;
end;

function TThreadLocal.GetValue: TThreadLocalValue;
begin
  Result := FindValueForThread(GetCurrentThreadId);
end;

procedure TThreadLocal.SetValue(AValue: TThreadLocalValue);
begin
  SetValueForThread(GetCurrentThreadId, AValue);
end;

function TThreadLocal.HasValue: Boolean;
begin
  Result := FindValueForThread(GetCurrentThreadId) <> nil;
end;

procedure TThreadLocal.RemoveValue;
begin
  RemoveValueForThread(GetCurrentThreadId);
end;

end.
