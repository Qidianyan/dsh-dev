# dsh-dev — DeepSeek Harness 扩展开发脚手架 + Claude Code Skill

[![CI](https://github.com/Qidianyan/dsh-dev/actions/workflows/ci.yml/badge.svg)](https://github.com/Qidianyan/dsh-dev/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**一句话**：让"给 [dsh](https://github.com/deepseek-ai/deepseek-harness) 做个插件 / 做个 Agent"从读半天文档变成一条命令起步——`dshdev` 脚手架 CLI + 面向 Claude Code 的中文导航 Skill。

> 社区项目，与 DeepSeek 官方无关联。

## 为什么需要它（调研结论）

dsh 的扩展开发资料其实很全，但分散且面向人类读者：

- **官方教程在仓库里**（`docs/user/develop/`、`docs/cookbook/`），权威且完整——本仓库**不复述**它们，只做引用导航
- 社区已有 [dsh-plugin-template](https://github.com/bugmaker2/dsh-plugin-template)（插件模板）和 [build-deepseek-harness-plugin](https://github.com/oil-oil/build-deepseek-harness-plugin)（**已发布插件**的进阶 skill：slots/Typert/凭证）
- 空白处在于：**"我要做什么 → 走哪条路径"的决策、agent preset 的脚手架与校验、从零到跑通的闭环**——本仓库补这一段，与上面两者互补

## 能力 → 路径决策树

| 你想要 | 路径 | 一条命令起步 |
|---|---|---|
| 角色化 Agent（人设+工具组合） | agent preset（零代码） | `dshdev preset-new my-agent --from standard` |
| 给模型一个新工具/能力 | 插件 bundle | `dshdev plugin-new dsh-my-plugin` |
| 接现成 MCP server | mcp-client 配置行 | `dshdev mcp-snippet github --command "npx -y …"` |
| 网页聊天流插业务卡片 | ConversationNode（进阶 TS） | 读官方 cookbook（SKILL 内有链接） |
| 加模型 provider | 网页 Settings → Models | 见官方 providers 指南 |

## dshdev 命令

```text
dshdev doctor                    环境检查（DSH_HOME / Host 在线 / PyYAML / node / pnpm / dshctl）
dshdev preset-new <id> [--name --desc] [--from minimal|standard|code|cordis] [--offline]
                                 创建 ~/.dsh/.agent-presets/<id>/ 脚手架；
                                 在线时从运行实例拉取基模板的真实组合（版本永远对齐）
dshdev preset-list [--json]      本地 + 运行实例的 preset（含 broken 状态）
dshdev preset-check <id>         结构/YAML/!!js 语法/运行实例加载状态检查（坏 YAML 会被抓住）
dshdev plugin-new <pkg名> [--dir] 零构建 JS 插件 bundle（package.json[dsh.bundle] + cordis.patch.yml + index.js）
dshdev mcp-snippet <名> --command "…" | --url …    生成 MCP 接入 YAML 片段
```

开发闭环（与兄弟项目 [dshctl](https://github.com/Qidianyan/dshctl) 配合）：

```sh
dshdev preset-new my-analyst --name "数据分析师" --desc "…"
$EDITOR ~/.dsh/.agent-presets/my-analyst/agent.cordis.yml   # 改 persona
dshdev preset-check my-analyst                               # 校验
dshctl new ~/myproject -p my-analyst                         # 建会话实测
dshctl send <sid> "你是做什么的？"                            # 冒烟
```

## 安装

```sh
git clone https://github.com/Qidianyan/dsh-dev.git
cd dsh-dev && ./install.sh    # skill 装到 ~/.claude/skills/dsh-dev/，dshdev 链接到 ~/.local/bin
```

- 依赖：Python 3.9+（标准库即可）；可选 PyYAML（启用 YAML 深校验）、运行中的 `dsh web`（在线拉模板/在线校验，离线自动降级）
- 不装 skill 也可以单独用 `dshdev`（把 `scripts/dshdev` 放进 PATH）

## Claude Code Skill

`SKILL.md` 教 Claude 在你说"给 dsh 做个 Agent/插件"时自动：查官方文档地图 → 走对路径 → 用 dshdev 脚手架 → preset-check/dshctl 验证闭环。内置浓缩的坑位清单（isolate realm、层序整行替换、`!!js` 位置限制、GitHub 安装的 prepare/allowBuilds、preset 会话锁定等），全部提炼自官方文档与实测。

## 已验证

对 dsh 0.1.0-rc.6 实测：preset-new 在线拉取真实组合、preset-check 通过（含 `!!js` 语法、负例坏 YAML 被正确捕获）、生成的 preset 在运行实例加载成功并可 `dshctl new -p` 建会话使用、mcp-snippet stdio/http 两态、plugin-new 脚手架结构完整。

## License

MIT © 2026 Qidianyan。DeepSeek Harness 及其商标归 DeepSeek AI 所有。
