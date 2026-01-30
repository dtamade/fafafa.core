# Darwin → macOS 版本映射（最佳努力）

说明：
- uname -r 返回 Darwin 内核版本，如 24.1.0；其主版本与 macOS 版本存在稳定对应关系。
- 本表为常见版本映射，供 `os_os_version_detailed` 在 macOS 下推断 Name/VersionString 参考。
- 注意：开发/测试版本可能出现尚未定名或中间版本号；本映射以“最佳努力”为原则，不保证完全覆盖。

对照表（节选）：
- Darwin 24.x → macOS 15 (Sequoia)
- Darwin 23.x → macOS 14 (Sonoma)
- Darwin 22.x → macOS 13 (Ventura)
- Darwin 21.x → macOS 12 (Monterey)
- Darwin 20.x → macOS 11 (Big Sur)
- Darwin 19.x → macOS 10.15 (Catalina)
- Darwin 18.x → macOS 10.14 (Mojave)
- Darwin 17.x → macOS 10.13 (High Sierra)
- Darwin 16.x → macOS 10.12 (Sierra)
- 更早版本：不建议依赖，若需要请扩展表项后提交 PR。

命名建议：
- Result.Name：推荐输出“macOS <Codename>”形式（如“macOS Sonoma”）；若未知则“macOS”。
- Result.VersionString：推荐输出主版本号（如“14”“15”或“10.15”）。
- Result.Build：可保留 Darwin release（uname -r）以便上层排查。

