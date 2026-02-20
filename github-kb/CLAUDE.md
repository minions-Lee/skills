# Claude Code 知识库

本目录包含 AI 相关 GitHub 项目，涵盖 AI 助手、编码代理、LLM 框架、部署工具等领域，用于本地知识库管理 + 基于仓库给 AI 工具/产品构建建议。

默认克隆路径：`~/github`（可按你的服务器路径修改）

---

## AI & Assistants

### [clawdbot](/clawdbot)
个人 AI 助手 - 本地优先运行，支持 WhatsApp、Telegram、Slack 等多消息渠道，含 Gateway 控制平面、多代理路由、语音唤醒等功能，兼容 Anthropic Claude、OpenAI 模型。
核心技术栈：Python、LLM API 集成、消息协议适配
适用场景：个人多平台 AI 助手搭建、本地 AI 服务代理

### [open-interpreter](/open-interpreter)
开源代码执行助手 - 本地运行，支持自然语言调用代码执行、文件操作、系统命令，兼容 Claude/OpenAI，可直接操作本地文件与环境。
核心技术栈：Python、代码沙箱、LLM 函数调用
适用场景：本地代码自动化、文件批量处理、系统操作辅助

## AI Coding Agents

### [opencode](/opencode)
开源 AI 编码代理 - 提供 CLI + 桌面应用，支持 npm/brew 安装，基于 TypeScript/Node.js 构建，含终端 UI、Web 界面，可对接 Claude 完成代码生成/调试/重构。
核心技术栈：TypeScript、Node.js、LSP、前端 UI
适用场景：AI 辅助编码、代码审查、项目脚手架生成

### [oh-my-opencode](/oh-my-opencode)
OpenCode 增强版 - 社区驱动的配置与提示词集合，含后台代理、专业代理（Oracle/Librarian/前端工程师）、LSP/AST 工具、MCP 服务器，完整兼容 Claude Code。
核心技术栈：TypeScript、代理编排、提示词工程、AST 解析
适用场景：AI 编码代理定制化、多代理协作编码、复杂项目开发辅助

## LLM Frameworks & Core Libraries

### [langchain](/langchain)
大语言模型开发框架 - 支持 LLM 调用、向量存储、检索增强（RAG）、智能体编排，兼容 Claude/OpenAI 等主流模型，提供 Python/JS 双版本。
核心技术栈：Python/TypeScript、RAG、向量数据库、智能体框架
适用场景：AI 应用快速开发、RAG 系统搭建、多步骤 AI 任务编排

### [transformers](/transformers)
Hugging Face transformer 库 - 提供预训练模型（LLM/多模态）加载、微调、推理，支持 PyTorch/TensorFlow，覆盖 NLP/CV 等任务。
核心技术栈：Python、PyTorch/TensorFlow、预训练模型、微调
适用场景：本地 LLM 部署、模型微调、多模态 AI 开发

## Development & Deployment Tools

### [skills](/skills/github-kb)
GitHub 知识库管理工具 - 基于 gh CLI 实现仓库搜索、克隆、更新，维护 CLAUDE.md 目录，支持 Issues/PR 管理，适配本地 GitHub 知识库工作流。
核心技术栈：gh CLI、Shell/Python、Markdown 解析
适用场景：批量管理 GitHub 仓库、本地知识库维护、gh 命令自动化

### [llama.cpp](/llama.cpp)
本地 LLM 推理引擎 - 轻量、高性能，支持 CPU/GPU 推理，兼容 LLaMA/Mistral 等开源模型，无需复杂环境，可直接本地运行大模型。
核心技术栈：C/C++、GGUF 格式、模型量化、本地推理
适用场景：离线 LLM 部署、低资源设备 AI 运行、本地模型推理优化

---

## 知识库更新规则（给 Claude 看）

1. **新增仓库**：按「分类 → 项目名 → 描述 → 技术栈 → 适用场景」格式添加，路径为本地克隆的相对路径；
2. **分类规则**：按「AI 助手/编码代理/LLM 框架/部署工具」划分，新增领域可新建分类；
3. **信息更新**：定期用 gh 拉取仓库最新代码，同步 README 核心信息到描述中；
4. **提问规则**：基于本知识库，结合用户 AI 想法，匹配对应仓库，给出技术选型、实现步骤、产品化建议。
