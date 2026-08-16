---
name: dsh-dev
description: 为 dsh（DeepSeek Harness）开发扩展时使用——创建 agent preset（角色化 Agent）、插件 bundle、接入 MCP server、网页端 UI 组件。用户说"给 dsh 做个插件/做个 Agent/加个工具/接 MCP/自定义模式"等时使用。提供 dshdev 脚手架 CLI 与官方文档导航；官方教程是唯一权威，本 skill 只做路径决策与脚手架。
---

# dsh 扩展开发（插件 / Agent preset / MCP）

dsh 一切皆插件。开发扩展的**权威文档在 harness 仓库内**，先读再动手——本 skill 不复述它们，只负责"选对路径 + 脚手架 + 坑位提醒"：

```text
官方教程地图（deepseek-harness 仓库）：
docs/user/develop/basic/index.md     第一个插件（三种形态、inject、ctx.effect）
docs/user/develop/basic/tool.md      工具 DSL（defineTool 全契约）
docs/user/develop/basic/config.md    插件配置（Config 字段）
docs/user/develop/basic/publish.md   打包安装（bundle/profile/层序/GitHub 安装坑）
docs/user/develop/framework/         插件生命周期、服务、事件
docs/cookbook/adding-a-conversation-node.md   网页端聊天流业务节点
packages/mcp/mcp-client/README.md    MCP 接入配置表
```

没有仓库检出时：`git clone https://github.com/deepseek-ai/deepseek-harness.git`（只读参考即可，开发产物不进仓库）。

## 第一步：选路径（决策树）

用户想要什么 → 走哪条路：

| 需求 | 路径 | 工具 |
|---|---|---|
| 一个角色化 Agent（人设/职责/工具组合，如"公司组织架构师"） | **agent preset**，无需写代码 | `dshdev preset-new` |
| 给模型一个新工具/能力（TypeScript/JS 插件） | **插件 bundle** | `dshdev plugin-new` |
| 接入现成的 MCP server（工具市场通用协议） | **mcp-client 行** | `dshdev mcp-snippet` |
| 换/加模型 provider | 网页端 Settings → Models（自定义 OpenAI 兼容端点） | 见 docs/user/guide/providers.md |
| 网页聊天流里插入业务卡片/行 | **客户端 ConversationNode**（进阶 TS） | 见 cookbook 指南 |
| 只给某个 Agent 加流程知识 | preset 的 `skills/<名>/SKILL.md` | 直接写文件 |

80% 的"帮我做个 Agent"需求 = **agent preset**：persona 文本 + 挂哪些工具行，零代码。

## agent preset（最常用路径）

```sh
dshdev preset-new my-analyst --name "数据分析师" --desc "描述"   # 默认基于 minimal
dshdev preset-new my-agent --from standard --name "全功能"       # 在线拉取 standard 真实组合
```

产物在 `~/.dsh/.agent-presets/<id>/`：
- `preset.yml` — 显示名/描述（网页端模式列表）
- `agent.cordis.yml` — 组合本体：改 `persona` 的 text（人设、职责、约束、工作方式、`{{model}}`/`{{cwd}}` 占位符可用），按需增删工具行
- `skills/<名>/SKILL.md` — 该 Agent 私有技能（可空）

**改完必须验证**：

```sh
dshdev preset-check <id>      # 结构/YAML/运行实例加载状态（broken 会报）
dshctl new <目录> -p <id>     # 建会话实测
dshctl send <sid> "你是做什么的？"   # 冒烟
```

预设创作也可以让 dsh 自己做：用 `cordis`（创造模式）开个会话让它写（它会读自己的 editing-cordis-compositions skill）。

### preset 的铁律（踩过会挂载失败/串会话）

- **发布型服务行必须放进带 `isolate` realm 的 `cordis:group` 组**——不在组里的 provide 是进程全局的，挂载直接被拒。纯注册型行（tool-*、persona）不需要。
- 组合里**不拥有**注册表本身、沙箱/审批栈、持久化、模型路由——那些在 Host 平面。
- 改系统 preset 的正确方式：复制组合到新 preset 再改，**绝不编辑**系统 preset 安装目录（升级会覆盖）。
- 会话一旦开跑，preset 锁定；换模式=新开会话。

## 插件 bundle

```sh
dshdev plugin-new dsh-my-plugin    # 零构建 JS 脚手架（index.js + dsh.bundle 声明 + patch）
cd .. && dsh plugin --profile web add ./dsh-my-plugin
dsh --profile web --dump-config | grep my-plugin   # 验证层已插入
```

TS 进阶用 [dsh-plugin-template](https://github.com/bugmaker2/dsh-plugin-template)（fork 即用）。工具 DSL、后台任务、UI 卡片（presentCall/presentResult）读 `docs/user/develop/basic/tool.md`——契约细节以它为准。

### 安装与层序的坑

- 层序：bundle（列表序）→ profile `cordis.patch.yml` → `$DSH_HOME/cordis.patch.yml` → `--patch`；**后层按 id 整行替换 config，不做深合并**——覆盖必须重写整行全部键。
- `github:` 安装拿到的是源码：作者须有自包含 `prepare` 构建脚本；用户须在 profile 的 `pnpm-workspace.yaml` 加 `allowBuilds: <包名>: true`（= 允许装时执行该包代码，只给自己信任的包放开，最好钉 commit）。免于此坑：发 npm 或发 tarball。
- 本地试验插件用 overlay（绝对路径）：`dsh web --patch ./my.yml`，yml 里 `name` 写**绝对路径**指向 `.ts/.js`。
- `!!js` 只允许出现在 `config` 值与 `disabled` 下，其余元数据必须字面量。

## MCP 接入

```sh
dshdev mcp-snippet github --command "npx -y @modelcontextprotocol/server-github"
dshdev mcp-snippet web --url http://localhost:3000/mcp
```

把输出行追加到 `~/.dsh/.agent-presets/<id>/agent.cordis.yml`（仅该 Agent 可用）或 profile 的 `cordis.patch.yml`（全局）。模型看到 `mcp__<server>__<tool>`。完整配置表（超时/重连/env）见 `packages/mcp/mcp-client/README.md`。

## 配套工具

- [dshctl](https://github.com/Qidianyan/dshctl)（兄弟项目）——终端指挥 dsh：建会话实测 preset、看模式列表。开发闭环 = `dshdev` 造 + `dshctl` 验。
- `dshdev doctor` 检查环境（DSH_HOME / Host 在线 / PyYAML / node / pnpm）。

## 进阶与生态

- 已发布插件的 slots/Typert remotes/凭证规则：[build-deepseek-harness-plugin](https://github.com/oil-oil/build-deepseek-harness-plugin)（英文进阶 skill）
- 插件发现：GitHub `dsh-plugin` topic、[awesome-dsh-plugin](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)
