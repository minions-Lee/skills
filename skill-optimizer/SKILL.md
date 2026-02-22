---
name: skill-optimizer
description: Analyze and optimize Claude Code skills using proven design patterns. Assess skill maturity, identify improvement opportunities, and apply targeted optimizations. Use when user asks to "optimize skill", "improve skill", "review skill quality", "refactor skill", "upgrade skill structure", "优化skill", "改进skill", "skill诊断", "skill评估", or wants to apply best practices to an existing or new skill.
---

# Skill 优化器

分析 skill 的当前结构，应用针对性改进。不是每个 skill 都需要所有模式——优化程度匹配 skill 的复杂度和用途。

## 用法

```bash
/skill-optimizer path/to/skill/           # 分析并优化
/skill-optimizer path/to/SKILL.md         # 分析单个文件
/skill-optimizer --assess-only path/to/   # 仅评估，不修改
```

## 工作流

### Step 1: 阅读与评估

1. 读取 skill 的 SKILL.md 及所有附属资源
2. 按类型分类（见 Skill 类型表）
3. 按评估矩阵对每个维度打 1-5 分
4. 向用户展示评估结果

### Step 2: 推荐

根据评分，**仅推荐得分 1-2 的维度对应的模式**。通过单次 AskUserQuestion 展示：
- 建议应用的模式（每条附一句理由）
- 建议跳过的模式（每条附一句理由）
- 用户可覆盖

根据决策指南判断适用性。仅为要应用的模式读取对应的 `references/patterns/<pattern>.md`。

### Step 3: 实施

执行选中的优化。每项变更用一句话说明改了什么、为什么改。

### Step 4: 验证

重新评估。展示优化前后的评分对比表。

---

## 评估矩阵

对每个维度打 1-5 分。仅优化得分 1-2 的维度。

| 维度 | 1（待改进） | 3（合格） | 5（优秀） |
|------|-----------|----------|----------|
| **触发清晰度** | description 模糊，缺少关键词 | 描述清晰，有基本触发词 | 多语言触发词，明确的 "Use when" |
| **结构** | 大段文字，无分节 | 有分节但不一致 | 层次清晰，表格驱动，可快速扫描 |
| **工作流** | 步骤隐含或缺失 | 有列出但无检查点 | 步骤含输入/输出，阻断标记，ASCII 流程图 |
| **可配置性** | 硬编码值 | 有部分参数 | EXTEND.md + 优先级链 + 首次设置 |
| **可扩展性** | 单体结构，加变体需重写 | 有一定分离 | 维度组合系统，可组合的 references |
| **提示词质量** | 内联提示词 | 独立提示词段落 | 从 references 模板组装 |
| **上下文效率** | 全部塞在 SKILL.md | 部分内容拆出 | 渐进式披露，按需加载 |
| **安全性** | 无备份/冲突处理 | 有基本检查 | 备份规则，文件存在检查 |

## Skill 类型分类

| 类型 | 示例 | 典型优化重点 |
|------|------|------------|
| **简单工具** | compress-image, format-markdown | 触发词、结构 |
| **工作流 Skill** | deploy-to-vercel, git-commit | 工作流、检查点 |
| **生成类 Skill** | infographic, cover-image, xhs-images | 维度系统、提示词组装、references |
| **集成类 Skill** | image-gen, post-to-wechat | 配置链、Provider 模式、错误处理 |
| **组合类 Skill** | article-illustrator, requirement-dev | 跨 skill 引用、工作流 |

## 决策指南

| 模式 | 适用条件 | 跳过条件 |
|------|---------|---------|
| 三层分离 | 同时有指令和脚本 | 纯指令 skill，无脚本 |
| 维度组合 | 3 种以上风格/格式变体 | 固定输出，无变体 |
| 渐进式工作流 | 3 步以上且有用户决策 | 单步操作 |
| 配置优先级链 | 需要用户偏好或 API key | 无需配置 |
| 提示词组装 | AI 生成且风格可变 | 不涉及 AI 生成 |
| 参考文件系统 | SKILL.md 超 300 行或变体膨胀 | 200 行以内且内容完整 |
| 表格驱动 | 多选项/映射关系需传达 | 简单线性指令 |
| 备份与安全 | 会生成或修改文件 | 只读 skill |

## 模式参考

仅在应用某个模式时读取对应文件：

| 模式 | 文件 | 一句话说明 |
|------|------|----------|
| 三层分离 | `references/patterns/three-layer-separation.md` | 指令、知识、执行三层独立 |
| 维度组合 | `references/patterns/dimensional-combination.md` | 正交维度自由搭配的设计空间 |
| 渐进式工作流 | `references/patterns/progressive-workflow.md` | 步骤含输入输出、阻断标记、ASCII 流程图 |
| 配置优先级链 | `references/patterns/config-priority-chain.md` | CLI > EXTEND.md > env > .env > 默认值 |
| 提示词组装 | `references/patterns/prompt-assembly.md` | 从模板 + references + 内容组合提示词 |
| 参考文件系统 | `references/patterns/reference-system.md` | 自包含、可组合的参考文件 |
| 表格驱动 | `references/patterns/table-driven.md` | 用表格替代散文传递结构化信息 |
| Frontmatter 与触发词 | `references/patterns/frontmatter-triggers.md` | 编写有效的 name + description |
