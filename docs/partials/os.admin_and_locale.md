# 管理员判断与 Locale 标准化（实现摘要）

- Windows 管理员判断（os_is_admin）
  - 构造 Administrators 组 SID（S-1-5-32-544）
  - 调用 OpenProcessToken + GetTokenInformation(TokenGroups)，EqualSid 判断成员关系
  - 失败时返回 False，不抛异常

- Unix Locale 标准化（os_locale_current）
  - 取 LANG → LC_ALL → LC_MESSAGES → LC_CTYPE 的首个非空值
  - 去除 ':' 之后的其他候选，去除 '@' 修饰符，去除 '.' 后的编码标识
  - 将 '_' 统一为 '-'，示例：zh_CN.UTF-8@modifier:other → zh-CN

