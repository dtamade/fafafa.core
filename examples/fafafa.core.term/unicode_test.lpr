program unicode_test;

{$CODEPAGE UTF8}
{$mode objfpc}{$H+}

uses
  SysUtils,
  fafafa.core.term;

procedure TestBasicUnicode;
begin
  WriteLn('=== 基础 Unicode 测试 ===');
  WriteLn;

  if not term_init then
  begin
    WriteLn('错误：无法初始化终端');
    Exit;
  end;

  term_writeln('ASCII 文本：Hello World!');
  term_writeln('中文文本：你好世界！');
  term_writeln('日文文本：こんにちは世界！');
  term_writeln('韩文文本：안녕하세요 세계!');
  term_writeln('俄文文本：Привет мир!');
  term_writeln('阿拉伯文文本：مرحبا بالعالم!');
  term_writeln('特殊符号：★☆♠♣♥♦♪♫');
  term_writeln('数学符号：∑∏∫∞≠≤≥±×÷');
  term_writeln('箭头符号：←↑→↓↔↕⇐⇑⇒⇓');
  term_writeln('货币符号：$€£¥₹₽₩₪');
  WriteLn;
end;

procedure TestEmojiSupport;
begin
  WriteLn('=== Emoji 支持测试 ===');
  WriteLn;
  term_writeln('基础 Emoji：😀😃😄😁😆😅😂🤣');
  term_writeln('动物 Emoji：🐶🐱🐭🐹🐰🦊🐻🐼');
  term_writeln('食物 Emoji：🍎🍌🍇🍓🥝🍅🥕🌽');
  term_writeln('交通 Emoji：🚗🚕🚙🚌🚎🏎️🚓🚑');
  term_writeln('旗帜 Emoji：🇺🇸🇨🇳🇯🇵🇰🇷🇬🇧🇫🇷🇩🇪🇷🇺');
  WriteLn;
end;

procedure TestColoredUnicode;
var
  LRedColor, LGreenColor, LBlueColor: term_color_24bit_t;
begin
  WriteLn('=== 彩色 Unicode 测试 ===');
  WriteLn;
  LRedColor := term_color_24bit_rgb(255, 0, 0);
  LGreenColor := term_color_24bit_rgb(0, 255, 0);
  LBlueColor := term_color_24bit_rgb(0, 0, 255);

  term_attr_foreground_set(LRedColor);
  term_write('红色中文：');
  term_attr_reset;
  term_writeln('这是红色的中文文本');

  term_attr_foreground_set(LGreenColor);
  term_write('绿色日文：');
  term_attr_reset;
  term_writeln('これは緑色の日本語テキストです');

  term_attr_foreground_set(LBlueColor);
  term_write('蓝色韩文：');
  term_attr_reset;
  term_writeln('이것은 파란색 한국어 텍스트입니다');

  term_attr_foreground_set(LRedColor);
  term_write('红色 Emoji：');
  term_attr_reset;
  term_writeln('❤️💖💕💗💓💝');

  term_attr_foreground_set(LGreenColor);
  term_write('绿色 Emoji：');
  term_attr_reset;
  term_writeln('💚🌿🌱🍀🌳🌲');

  term_attr_foreground_set(LBlueColor);
  term_write('蓝色 Emoji：');
  term_attr_reset;
  term_writeln('💙🌊🌀💎🔵🟦');
  WriteLn;
end;

procedure TestComplexUnicode;
begin
  WriteLn('=== 复杂 Unicode 测试 ===');
  WriteLn;
  term_writeln('组合字符：é è ê ë ñ ü ç');
  term_writeln('双宽字符：全角ＡＢＣ１２３');
  term_writeln('零宽字符测试：a‌b‍c‎d‏e');
  term_writeln('RTL 文本：العربية עברית');
  term_writeln('混合文本：Hello 世界 🌍 مرحبا');
  WriteLn;
end;

begin
  WriteLn('fafafa.core.term Unicode 支持测试');
  WriteLn('===================================');
  WriteLn;
  TestBasicUnicode;
  WriteLn('按回车键继续 Emoji 测试...'); ReadLn;
  TestEmojiSupport;
  WriteLn('按回车键继续彩色 Unicode 测试...'); ReadLn;
  TestColoredUnicode;
  WriteLn('按回车键继续复杂 Unicode 测试...'); ReadLn;
  TestComplexUnicode;
  WriteLn('=== 测试完成 ===');
  WriteLn('按回车键退出...'); ReadLn;
end.

