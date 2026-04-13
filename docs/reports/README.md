# docs reports archive pointer

`docs/reports/` 现在只保留仍然有 today 主题入口价值的子目录或说明页，不再承载 dated root-level fix / checkpoint / verification 报告正文。

- 历史 root-level 报告统一归档到：`archive/reports/docs-root/`
- 当前仍留在 `docs/reports/` 下的内容，应当是像 `docs/reports/time/` 这种主题子目录，而不是一次性 closeout 报告
- `docs/audits/`、`docs/reviews/` 和 `docs/plans/` 继续承担 current-entry 审计、评审和执行批次文档

如果你只是为了追溯旧 fix report、production audit 或 week-report，请直接去 `archive/reports/docs-root/`。

第七波 retained-refs absorbability 之后，`docs/reports/README.md` 本身也被固定成 sidecar/tail 的低风险 absorb landing zone 之一；如果 retained-refs inventory 再暴露这条路径，应优先视作 archive pointer residue，而不是新的 current-entry blocker。

与之相对，`docs/reports/time/` 下的主题文档仍然属于 live report topic surface，不应和 archive pointer 混成一类。
