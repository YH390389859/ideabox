# 项目技能与代理指令审计

日期：2026-09-07。范围：`/Users/nullecho/project/ideabox`。

## 依据与方法

阅读 eric provencher 的 [Rethinking skills and prompts for GPT-6 Astra](https://x.com/pvncher/status/2095991462416490862)。X 直接抓取返回 403，浏览器读取超时；随后通过 [FxTwitter 公开转存接口](https://api.fxtwitter.com/status/2095991462416490862) 取得英文正文，核对作者 `pvncher`、帖文 ID 与文章 ID `2095989703967125509`。

文章用于本次审计的原则：技能描述应简短、触发准确；详细工作流按需读取；常驻指令只保留必要内容；测试按改动需要选择；明确完成标准，避免无意增加审批或提前停止点。这些是作者的建议，不构成取消项目数据保护或用户授权边界的理由。

使用 `rg --files --hidden --no-ignore` 盘点，并通过不区分大小写的文件名检查交叉核对。包含隐藏文件、构建产物、第三方源码与 `.artifacts` 历史备份；另检查直接父目录与用户目录的 `AGENTS.md`。未扩展到全局 `~/.codex`、插件安装目录或其他项目。

## 盘点结果

| 对象 | 数量 / 状态 |
|---|---|
| 项目内 `AGENTS.md`（含大小写变体） | 0 |
| 项目内 `SKILL.md`（含大小写变体） | 0 |
| 项目级 `.codex`、`.agents`、`.claude`、`.cursor`、`skills` 目录 | 不存在 |
| `CLAUDE.md`、`GEMINI.md`、Copilot instructions、Cursor/Windsurf rules | 未发现 |
| `/Users/nullecho/project/AGENTS.md` 与 `/Users/nullecho/AGENTS.md` | 不存在，大小写变体也未发现 |

因此，没有可逐条精简、去重或修正触发条件的项目技能或 `AGENTS.md`。未发现这类文件造成的强制通读、重复测试、审批冲突或提前停止规则；该结论不覆盖会话或全局配置。

## 相关文档的审阅结论

| 文件 | 结论与处理建议 |
|---|---|
| [README.md](../../README.md) | 保留。当前产品说明、Xcode/XcodeGen/签名经验、测试命令与截图入口集中在此，具有项目价值。按任务需要读取，无需复制到多个技能。 |
| [design-notes.md](../../design/loom-20260906/design-notes.md) | 保留为开发前设计依据。开头已标明状态；具体像素、动效目标及本轮“不变更 schema”约束不应自动变成所有后续任务的永久规则。 |
| [product-direction.md](../../design/loom-20260906/product-direction.md) | 保留本轮产品方向与数据能力边界；后续需求变更时按实际目标更新。 |
| [当前品牌说明](../../design/loom-20260906/brand/README.md) | 保留资源生成说明，品牌任务按需读取。 |
| [旧品牌说明](../../design/brand-20260906/README.md)、[旧设计说明](../../design/redesign-20260906/README.md) | 属于历史阶段资料；当前入口由根 README 指向 loom 版本，不应将旧方案与当前方案同时作为实现要求。 |

`IdeaBox/Vendor/RichEditorSwiftUI/.github` 及历史备份中的同名目录包含第三方 PR 模板与构建、发布工作流。它们服务于 RichEditorSwiftUI，不是 IdeaBox 的代理规则或已配置的项目 CI。

## 后续指令的取舍

- 目前不需要新增技能集合。只有出现明确、重复且需要专门知识的工作流时，再考虑独立技能。
- 若以后需要 `AGENTS.md`，优先记录少量不易从代码发现的事实，并链接现有构建或测试说明，避免复制项目地图和通用开发常识。
- 保留真实工程约束：用户数据与录音保护、受影响功能的验证、模拟器签名要求。避免把“每次改动都跑全部测试”写成常驻要求。
- 当前用户要求的“先出设计图，再开发”是工作顺序；没有要求在第一版或每个阶段额外等待批准。完成标准仍应由具体任务决定。

## 本次变更与验证

仅新增此审计记录。未新增或修改技能、`AGENTS.md`、全局配置、应用源码及用户数据。检查了文档引用的本地路径；本次没有代码变动，因此未重新构建 App 或重复运行数据测试。
