# 表格驱动设计

用 Markdown 表格替代散文来传递结构化信息，提高扫描效率和精确度。

## 适用场景

| 信息类型 | 表格形式 |
|---------|---------|
| 参数和选项 | Options 表（参数 / 值 / 默认值 / 说明） |
| 变体列表 | Gallery 表（名称 / 描述 / 适用场景） |
| 内容→推荐映射 | Signal 表（关键词 / 推荐值） |
| 维度兼容性 | Matrix 表（行×列交叉标注匹配度） |
| 配置优先级 | Priority 表（来源 / 优先级） |
| 条件跳过 | Skip 表（条件 / 跳过步骤 / 仍需步骤） |
| 错误处理 | Error 表（错误类型 / 处理方式） |

## 表格类型示例

### Options 表

```markdown
| 选项 | 值 | 默认 | 说明 |
|------|---|------|------|
| `--style` | minimal, warm, bold... | craft-handmade | 视觉风格 |
| `--layout` | bento-grid, timeline... | bento-grid | 信息布局 |
| `--ar` | 16:9, 9:16, 1:1 | 16:9 | 宽高比 |
```

### Signal 映射表

```markdown
| 内容信号 | 推荐风格 | 推荐布局 |
|---------|---------|---------|
| 教程、步骤、指南 | ikea-manual | linear-progression |
| 对比、A vs B | corporate-memphis | binary-comparison |
| 历史、时间线 | aged-academia | linear-progression |
```

### 兼容性矩阵

```markdown
| 风格 \ 布局 | bento-grid | timeline | hub-spoke |
|------------|-----------|----------|----------|
| minimal | 最佳 | 良好 | 良好 |
| watercolor | 良好 | 最佳 | 避免 |
```

### 条件跳过表

```markdown
| 条件 | 跳过 | 仍需 |
|------|------|------|
| `--quick` | 用户确认 | 尺寸选择 |
| 所有选项已指定 | 推荐步骤 | 无 |
```

## 原则

- **一个表格传递一类决策信息**
- 表格比等长散文 **扫描速度快 3-5 倍**
- Agent 处理表格比段落更精确
- 保持列数 3-5 列，过多则拆分
