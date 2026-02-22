# 三层分离

将 skill 拆分为三个独立关注点：指令、知识、执行。

## 三层定义

| 层 | 载体 | 职责 |
|---|------|------|
| **指令层** | `SKILL.md` | 工作流、用户交互、决策逻辑 |
| **知识层** | `references/` | 风格定义、模板、schema、领域规则 |
| **执行层** | `scripts/` | API 调用、文件处理、格式转换 |

## 分工原则

- Agent (Claude) 负责 **编排和决策**
- Scripts 负责 **确定性执行**（API 调用、文件 I/O、压缩）
- References 提供 **可组合的知识**（风格定义、提示词模板、schema）

## 如何应用

1. **识别每次运行都要重写的代码** → 移入 `scripts/`
2. **识别变体相关的详细定义**（风格、布局、平台文档）→ 移入 `references/`
3. **SKILL.md 只保留**：工作流步骤、决策逻辑、用户交互模式、指向 references/scripts 的引用

## 目录模板

```
skill-name/
├── SKILL.md              # 仅工作流 + 决策逻辑
├── scripts/              # 确定性执行
│   ├── main.ts           # 入口
│   └── providers/        # 平台特定模块（多 provider 时）
└── references/           # 可组合知识
    ├── config/           # 用户偏好 schema、设置指南
    ├── styles/           # 每个风格一个文件
    ├── layouts/          # 每个布局一个文件
    └── base-prompt.md    # 生成提示词模板
```

## 核心原则

**新增一个变体只需加一个 `.md` 文件**，无需修改 SKILL.md 或 scripts。

## 脚本设计规则

- 入口：`scripts/main.ts`
- 调用：`npx -y bun ${SKILL_DIR}/scripts/main.ts [args]`
- 输出：默认人类可读，`--json` 切换结构化输出
- 错误：`console.error()` + exit code 1
- 不依赖外部 CLI 库（不用 yargs/commander）——手写参数解析，零依赖

## Agent 与 Script 的边界

| Agent 负责 | Script 负责 |
|-----------|-----------|
| 理解用户意图 | 执行 API 调用 |
| 编排工作流步骤 | 处理文件/格式 |
| 做风格/变体决策 | 返回结构化结果 |
| 向用户展示结果 | 处理底层错误 |
