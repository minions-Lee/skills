# 渐进式工作流

设计多步工作流，明确输入、输出、检查点和决策点。

## 步骤模板

每个工作流步骤应包含：

```markdown
### Step N: [操作名称]

**跳过条件**: [何时可跳过此步]

**输入**: [此步接收什么]
**输出**: [此步产出什么 → 文件名]

[步骤指令]
```

## 三个必备组件

### 1. 进度清单

可复制的 checkbox 列表：

```markdown
### 进度

- [ ] Step 0: 加载配置 (EXTEND.md) ⛔ BLOCKING
- [ ] Step 1: 分析内容 → analysis.md
- [ ] Step 2: 用户确认 ⚠️ REQUIRED
- [ ] Step 3: 生成结构化内容 → structured-content.md
- [ ] Step 4: 组装提示词 → prompts/output.md
- [ ] Step 5: 生成输出
- [ ] Step 6: 总结
```

### 2. ASCII 流程图

展示决策分支：

```
输入 → [Step 0: 配置] ─┬─ 找到 → 继续
                       └─ 未找到 → 首次设置 ⛔
                                    └─ 保存 → 继续
                                               │
分析 → [确认] → 结构化 → 组装 → 生成 → 完成
```

### 3. 阻断与条件标记

| 标记 | 含义 | 行为 |
|------|------|------|
| ⛔ BLOCKING | 后续步骤必须等此步完成 | 硬性阻断，展示设置指引 |
| ⚠️ REQUIRED | 用户必须确认后才继续 | AskUserQuestion，不可跳过 |
| （可选） | 可跳过 | 满足条件时跳过 |

## 用户交互规则

### AskUserQuestion 最佳实践

- **每轮确认一次调用** — 将所有问题合并到单次 AskUserQuestion
- **每问题 2-4 个选项**，始终包含推荐默认项
- **按决策类别标注问题**，不要用 Q1/Q2

```markdown
单次 AskUserQuestion：
- 风格：3 个推荐组合附理由
- 尺寸：横版 / 竖版 / 方形
- 语言：仅当源语言 ≠ 用户语言时问
```

### 跳过条件

定义何时可跳过步骤：

```markdown
| 条件 | 跳过步骤 |
|------|---------|
| `--quick` 模式 | 用户确认 |
| 所有选项已指定 | 推荐步骤 |
| 输入已处理过 | 分析步骤 |
```

## 步骤产出约定

每个非平凡步骤产出一个命名文件：

```
Step 1: 分析 → analysis.md
Step 2: 结构化 → structured-content.md
Step 3: 组装 → prompts/output.md
Step 4: 生成 → output.png
```

这使工作流 **可恢复** — 如果生成失败，从 Step 4 用已有 prompt 文件重新开始。

## 备份规则

skill 创建的每个文件：

```
如果 {file} 已存在 → 重命名为 {file}-backup-YYYYMMDD-HHMMSS.{ext}
```
