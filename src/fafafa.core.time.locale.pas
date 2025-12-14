unit fafafa.core.time.locale;

{
──────────────────────────────────────────────────────────────
   ______   ______     ______   ______     ______   ______
  /\  ___\ /\  __ \   /\  ___\ /\  __ \   /\  ___\ /\  __ \
  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \  \ \  __\ \ \  __ \
   \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\  \ \_\    \ \_\ \_\
    \/_/     \/_/\/_/   \/_/     \/_/\/_/   \/_/     \/_/\/_/
                          Studio
──────────────────────────────────────────────────────────────
📦 项目：fafafa.core.time.locale - 本地化支持

📖 概述：
  提供日期时间的本地化支持，包括：
  - 多语言月份名称（全名和缩写）
  - 多语言星期名称（全名和缩写）
  - AM/PM 本地化表示

🌍 支持的语言：
  - en    : 英语（默认）
  - zh-CN : 简体中文
  - ja    : 日语

📜 声明：
  转发或用于个人/商业项目时，请保留本项目的版权声明。

👤 author  : fafafaStudio
📧 Email   : dtamade@gmail.com
💬 QQGroup : 685403987
💬 QQ      : 179033731
──────────────────────────────────────────────────────────────
}

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}
{$I fafafa.core.settings.inc}

interface

type
  /// <summary>本地化数据</summary>
  TLocale = record
    /// <summary>语言代码（如 "en", "zh-CN", "ja"）</summary>
    Code: string;
    /// <summary>星期全名 (1=Sunday, 7=Saturday)</summary>
    WeekdayNames: array[1..7] of string;
    /// <summary>星期缩写</summary>
    WeekdayAbbrs: array[1..7] of string;
    /// <summary>月份全名 (1-12)</summary>
    MonthNames: array[1..12] of string;
    /// <summary>月份缩写</summary>
    MonthAbbrs: array[1..12] of string;
    /// <summary>上午标识</summary>
    AM: string;
    /// <summary>下午标识</summary>
    PM: string;
  end;
  PLocale = ^TLocale;

const
  /// <summary>英语 (English)</summary>
  LOCALE_EN: TLocale = (
    Code: 'en';
    WeekdayNames: ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 
                   'Thursday', 'Friday', 'Saturday');
    WeekdayAbbrs: ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    MonthNames: ('January', 'February', 'March', 'April', 'May', 'June',
                 'July', 'August', 'September', 'October', 'November', 'December');
    MonthAbbrs: ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    AM: 'AM';
    PM: 'PM';
  );

  /// <summary>简体中文 (Simplified Chinese)</summary>
  LOCALE_ZH_CN: TLocale = (
    Code: 'zh-CN';
    WeekdayNames: ('星期日', '星期一', '星期二', '星期三', 
                   '星期四', '星期五', '星期六');
    WeekdayAbbrs: ('日', '一', '二', '三', '四', '五', '六');
    MonthNames: ('一月', '二月', '三月', '四月', '五月', '六月',
                 '七月', '八月', '九月', '十月', '十一月', '十二月');
    MonthAbbrs: ('1月', '2月', '3月', '4月', '5月', '6月',
                 '7月', '8月', '9月', '10月', '11月', '12月');
    AM: '上午';
    PM: '下午';
  );

  /// <summary>日语 (Japanese)</summary>
  LOCALE_JA: TLocale = (
    Code: 'ja';
    WeekdayNames: ('日曜日', '月曜日', '火曜日', '水曜日', 
                   '木曜日', '金曜日', '土曜日');
    WeekdayAbbrs: ('日', '月', '火', '水', '木', '金', '土');
    MonthNames: ('1月', '2月', '3月', '4月', '5月', '6月',
                 '7月', '8月', '9月', '10月', '11月', '12月');
    MonthAbbrs: ('1月', '2月', '3月', '4月', '5月', '6月',
                 '7月', '8月', '9月', '10月', '11月', '12月');
    AM: '午前';
    PM: '午後';
  );

  /// <summary>韩语 (Korean)</summary>
  LOCALE_KO: TLocale = (
    Code: 'ko';
    WeekdayNames: ('일요일', '월요일', '화요일', '수요일', 
                   '목요일', '금요일', '토요일');
    WeekdayAbbrs: ('일', '월', '화', '수', '목', '금', '토');
    MonthNames: ('1월', '2월', '3월', '4월', '5월', '6월',
                 '7월', '8월', '9월', '10월', '11월', '12월');
    MonthAbbrs: ('1월', '2월', '3월', '4월', '5월', '6월',
                 '7월', '8월', '9월', '10월', '11월', '12월');
    AM: '오전';
    PM: '오후';
  );

  /// <summary>德语 (German)</summary>
  LOCALE_DE: TLocale = (
    Code: 'de';
    WeekdayNames: ('Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 
                   'Donnerstag', 'Freitag', 'Samstag');
    WeekdayAbbrs: ('So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa');
    MonthNames: ('Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
                 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember');
    MonthAbbrs: ('Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez');
    AM: 'vorm.';
    PM: 'nachm.';
  );

  /// <summary>法语 (French)</summary>
  LOCALE_FR: TLocale = (
    Code: 'fr';
    WeekdayNames: ('dimanche', 'lundi', 'mardi', 'mercredi', 
                   'jeudi', 'vendredi', 'samedi');
    WeekdayAbbrs: ('dim.', 'lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.');
    MonthNames: ('janvier', 'février', 'mars', 'avril', 'mai', 'juin',
                 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre');
    MonthAbbrs: ('janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
                 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.');
    AM: 'AM';
    PM: 'PM';
  );

  /// <summary>西班牙语 (Spanish)</summary>
  LOCALE_ES: TLocale = (
    Code: 'es';
    WeekdayNames: ('domingo', 'lunes', 'martes', 'miércoles', 
                   'jueves', 'viernes', 'sábado');
    WeekdayAbbrs: ('dom.', 'lun.', 'mar.', 'mié.', 'jue.', 'vie.', 'sáb.');
    MonthNames: ('enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
                 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre');
    MonthAbbrs: ('ene.', 'feb.', 'mar.', 'abr.', 'may.', 'jun.',
                 'jul.', 'ago.', 'sept.', 'oct.', 'nov.', 'dic.');
    AM: 'a. m.';
    PM: 'p. m.';
  );

  /// <summary>俄语 (Russian)</summary>
  LOCALE_RU: TLocale = (
    Code: 'ru';
    WeekdayNames: ('воскресенье', 'понедельник', 'вторник', 'среда', 
                   'четверг', 'пятница', 'суббота');
    WeekdayAbbrs: ('вс', 'пн', 'вт', 'ср', 'чт', 'пт', 'сб');
    MonthNames: ('январь', 'февраль', 'март', 'апрель', 'май', 'июнь',
                 'июль', 'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь');
    MonthAbbrs: ('янв.', 'фев.', 'мар.', 'апр.', 'май', 'июн.',
                 'июл.', 'авг.', 'сен.', 'окт.', 'ноя.', 'дек.');
    AM: 'ДП';
    PM: 'ПП';
  );

  /// <summary>繁体中文 (Traditional Chinese)</summary>
  LOCALE_ZH_TW: TLocale = (
    Code: 'zh-TW';
    WeekdayNames: ('星期日', '星期一', '星期二', '星期三', 
                   '星期四', '星期五', '星期六');
    WeekdayAbbrs: ('日', '一', '二', '三', '四', '五', '六');
    MonthNames: ('一月', '二月', '三月', '四月', '五月', '六月',
                 '七月', '八月', '九月', '十月', '十一月', '十二月');
    MonthAbbrs: ('1月', '2月', '3月', '4月', '5月', '6月',
                 '7月', '8月', '9月', '10月', '11月', '12月');
    AM: '上午';
    PM: '下午';
  );

  /// <summary>默认 locale（英语）</summary>
  LOCALE_DEFAULT: TLocale = (
    Code: 'en';
    WeekdayNames: ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 
                   'Thursday', 'Friday', 'Saturday');
    WeekdayAbbrs: ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
    MonthNames: ('January', 'February', 'March', 'April', 'May', 'June',
                 'July', 'August', 'September', 'October', 'November', 'December');
    MonthAbbrs: ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
    AM: 'AM';
    PM: 'PM';
  );

implementation

end.
