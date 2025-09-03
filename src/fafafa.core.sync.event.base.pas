unit fafafa.core.sync.event.base;

{
📦 项目：fafafa.core.sync.event - 高性能事件同步原语实现

📖 概述：
  现代化、跨平台的 FreePascal 事件同步原语接口定义。

🔧 特性：
  • 接口定义：IEvent 事件同步接口
  • 跨平台：统一的接口，平台无关的抽象

⚠️  重要说明：
  本文件仅包含接口定义，具体实现在平台相关的文件中。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
}

{$I fafafa.core.settings.inc}

interface

uses
  fafafa.core.sync.base;

type

  IEvent = interface(ISynchronizable)
    ['{E8B9D5C6-7F6A-4D3E-8B9C-6A5D4E3F2B18}']

    { 基础事件操作 }
    procedure SetEvent;
    procedure ResetEvent;
    function WaitFor: TWaitResult; overload;
    function WaitFor(ATimeoutMs: Cardinal): TWaitResult; overload;

    { 扩展操作 }
    function TryWait: Boolean;           // 非阻塞等待
    function IsManualReset: Boolean;     // 是否手动重置
  end;

implementation

end.
