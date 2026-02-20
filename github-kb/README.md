# GitHub KB - AI 工具知识库

基于 gh CLI + Claude Code 实现的 AI 仓库知识库管理系统，用于学习研究 AI 项目并构建个性化 AI 工具/产品。

## 项目定位

结合 `gh` + `Claude` 实现一个功能：提供多个 AI 相关的 repository，当您有 AI 方面的想法时，让 Claude 基于这些仓库去学习研究，然后提供构建属于您自己的 AI 工具建议或产品方案。

### 核心功能

- 📚 **本地知识库管理**：通过 gh CLI 克隆、更新 AI 相关仓库
- 🔍 **智能仓库研究**：Claude 基于本地仓库深度学习理解
- 💡 **AI 产品建议**：根据您的想法，匹配仓库技术栈，提供技术选型和实现方案
- 📖 **结构化目录**：按技术栈、场景分类的 CLAUDE.md 目录

### 适用场景

1. **技术选型**：想实现某个 AI 功能，让 Claude 推荐最适合的仓库组合
2. **学习研究**：让 Claude 深度分析多个 AI 项目的架构和实现
3. **产品构建**：基于现有 AI 仓库，快速搭建自己的 AI 工具/产品
4. **方案设计**：让 Claude 结合多个仓库的优势，设计最佳技术方案

## 快速开始

### 1. 安装依赖

```bash
# 安装 GitHub CLI
bash skills/github-kb/install-gh.sh

# 认证 GitHub
gh auth login
```

### 2. 配置知识库路径

编辑 `CLAUDE.md`，修改默认克隆路径：

```markdown
默认克隆路径：`~/github`  # 改为您的路径，如 `/Volumes/P7000Z/Work/github/`
```

### 3. 添加 AI 仓库

方式 1：使用 Claude 添加
```
请帮我克隆 open-interpreter 仓库到知识库
```

方式 2：手动添加
```bash
cd ~/github
gh repo clone interpreter/open-interpreter
```

然后更新 `CLAUDE.md` 添加项目信息。

### 4. 向 Claude 咨询

添加仓库后，可以直接向 Claude 提问：

```
我想构建一个能够分析代码并给出优化建议的 AI 工具，
基于我知识库中的仓库，你有什么建议？
```

Claude 会：
1. 分析知识库中相关仓库（如 opencode、langchain）
2. 理解各仓库的核心能力和技术栈
3. 提供技术选型建议
4. 给出实现步骤和产品化建议

## 项目结构

```
github-kb/
├── .claude/
│   └── settings.local.json      # Claude Code 设置
├── skills/
│   └── github-kb/
│       ├── SKILL.md            # 技能说明文档（Claude 会读取）
│       └── install-gh.sh       # gh CLI 安装脚本
├── CLAUDE.md                   # AI 仓库知识库目录（核心文件）
├── README.md                   # 项目说明
├── SETUP.md                    # 设置指南
└── .gitignore
```

## CLAUDE.md 目录格式

知识库按以下结构组织：

```markdown
# Claude Code 知识库
本目录包含 X 个 AI 相关 GitHub 项目，涵盖...领域。
默认克隆路径：`~/github`

## 分类名称

### [项目名](/项目路径)
项目描述 - 一句话说明项目功能
核心技术栈：技术1、技术2
适用场景：场景1、场景2
```

### 分类示例

- **AI & Assistants**：AI 助手、聊天机器人
- **AI Coding Agents**：AI 编码代理、代码生成
- **LLM Frameworks**：LLM 开发框架、RAG 工具
- **Development & Deployment Tools**：开发部署工具

## 使用示例

### 示例 1：技术选型

```
我想做一个类似 OpenAI ChatGPT 的网页应用，
支持流式输出、函数调用，有什么推荐方案？
```

Claude 会基于知识库中的仓库（如 clawdbot、langchain）给出建议。

### 示例 2：产品构建

```
基于 opencode 和 langchain，
我想做一个能分析我整个代码库并生成文档的 AI 工具，
应该如何设计？如何实现？
```

Claude 会分析两个仓库的技术栈，设计技术方案。

### 示例 3：学习研究

```
请深入分析 clawdbot 和 open-interpreter 的架构设计，
对比它们的优缺点，我应该如何借鉴？
```

Claude 会深度研究代码结构和实现细节。

## 知识库更新规则

### 给 Claude 的指令

1. **新增仓库**：按「分类 → 项目名 → 描述 → 技术栈 → 适用场景」格式添加
2. **分类规则**：按「AI 助手/编码代理/LLM 框架/部署工具」划分
3. **信息更新**：定期用 gh 拉取最新代码，同步 README 核心信息
4. **提问规则**：基于知识库，结合用户 AI 想法，匹配对应仓库，给出技术选型、实现步骤、产品化建议

## 在其他服务器使用

```bash
# 1. Clone 项目
git clone https://github.com/goodniuniu/github-kb.git
cd github-kb

# 2. 安装 gh CLI
bash skills/github-kb/install-gh.sh

# 3. 认证
gh auth login

# 4. 配置路径
# 编辑 CLAUDE.md，修改默认克隆路径为您的服务器路径

# 5. 开始使用！
# 直接在目录下用 Claude Code 提问
```

## 推荐初始仓库

建议先克隆以下 AI 仓库到知识库：

```bash
cd ~/github

# AI 助手
gh repo clone clawdbot/clawdbot

# AI 编码代理
gh repo clone OpenInterpreter/open-interpreter
gh repo clone code-yeongyu/oh-my-opencode

# LLM 框架
gh repo clone langchain-ai/langchain

# 本地 LLM
gh repo clone ggerganov/llama.cpp
```

## 许可证

MIT

---

**作者**: goodniuniu
**仓库**: https://github.com/goodniuniu/github-kb
