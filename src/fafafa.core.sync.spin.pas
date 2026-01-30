unit fafafa.core.sync.spin;

{$mode objfpc}
{$I fafafa.core.settings.inc}
{鈹屸攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?鈹?                                                                             鈹?鈹?         ______   ______     ______   ______     ______   ______             鈹?鈹?        /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \            鈹?鈹?        \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \           鈹?鈹?         \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\          鈹?鈹?          \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/          鈹?鈹?                                                                             鈹?鈹?                               Studio                                        鈹?鈹斺攢鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹€鈹?
馃摝 椤圭洰锛歠afafa.core.sync.spin - 璺ㄥ钩鍙伴珮鎬ц兘鑷棆閿佸疄鐜?
馃摉 姒傝堪锛?  鐜颁唬鍖栥€佽法骞冲彴鐨?FreePascal 鑷棆閿佸疄鐜帮紝鎻愪緵缁熶竴鐨?API 鎺ュ彛銆?
馃敡 鐗规€э細
  鈥?璺ㄥ钩鍙版敮鎸侊細Windows銆丩inux銆乵acOS銆丗reeBSD 绛?  鈥?楂樻€ц兘瀹炵幇锛氫娇鐢ㄥ钩鍙板師鐢?API 鍜屽師瀛愭寚浠や紭鍖?  鈥?鑷€傚簲閫€閬匡細鏅鸿兘閫€閬跨瓥鐣ュ噺灏?CPU 鍗犵敤
  鈥?瓒呮椂鏀寔锛氬彲閰嶇疆鐨勮幏鍙栬秴鏃舵満鍒?  鈥?缁熻淇℃伅锛氳缁嗙殑鎬ц兘缁熻鍜岃皟璇曚俊鎭?  鈥?RAII 鏀寔锛氳嚜鍔ㄩ攣绠＄悊鍜屽紓甯稿畨鍏?
鈿狅笍  閲嶈璇存槑锛?  鑷棆閿侀€傜敤浜庣煭鏃堕棿鎸侀攣鍦烘櫙锛岄暱鏃堕棿鎸侀攣浼氬鑷?CPU 璧勬簮娴垂銆?  璇锋牴鎹叿浣撳満鏅€夋嫨鍚堥€傜殑閿佺被鍨嬪拰閫€閬跨瓥鐣ャ€?
馃У 绾跨▼瀹夊叏鎬э細
  鎵€鏈夎嚜鏃嬮攣鎿嶄綔閮芥槸绾跨▼瀹夊叏鐨勶紝鏀寔澶氱嚎绋嬪苟鍙戣闂€?
馃摐 澹版槑锛?  杞彂鎴栫敤浜庝釜浜?鍟嗕笟椤圭洰鏃讹紝璇蜂繚鐣欐湰椤圭洰鐨勭増鏉冨０鏄庛€?
馃懁 author  : fafafaStudio
馃摟 Email   : dtamade@gmail.com
馃挰 QQGroup : 685403987
馃挰 QQ      : 179033731

}

interface

uses
  fafafa.core.sync.spin.base;

type

  ISpin = fafafa.core.sync.spin.base.ISpin;

{**
 * MakeSpin - 鍒涘缓鑷棆閿佸疄渚? *
 * @return 鑷棆閿佹帴鍙ｅ疄渚? *
 * @desc
 *   鍒涘缓涓€涓嚜鏃嬮攣瀹炰緥锛岃嚜鍔ㄩ€夋嫨褰撳墠骞冲彴鐨勬渶浼樺疄鐜帮細
 *   - Windows: 鍩轰簬鍘熷瓙鎿嶄綔鐨勮交閲忕骇瀹炵幇
 *   - Unix: 鍩轰簬 pthread_spinlock_t 鐨勭郴缁熷疄鐜? *
 * @thread_safety
 *   杩斿洖鐨勫疄渚嬫槸绾跨▼瀹夊叏鐨勶紝浣嗛潪閲嶅叆銆? *
 * @usage
 *   var SpinLock := MakeSpin;
 *   // 浣跨敤 SpinLock...
 *}
function MakeSpin: ISpin;

implementation

uses
  {$IFDEF MSWINDOWS}
  fafafa.core.sync.spin.atomic
  {$ELSE}
  fafafa.core.sync.spin.unix
  {$ENDIF};

function MakeSpin: ISpin;
begin
  {$IFDEF MSWINDOWS}
  Result := fafafa.core.sync.spin.atomic.MakeSpin;
  {$ELSE}
  Result := fafafa.core.sync.spin.unix.MakeSpin;
  {$ENDIF}
end;

end.
