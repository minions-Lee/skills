# Frontmatter 与触发词

编写有效的 name + description，确保 skill 在正确时机被触发。

## Frontmatter 格式

```yaml
---
name: skill-name
description: 功能描述。包含触发关键词。Use when user asks to...
---
```

只有 `name` 和 `description` 两个字段。**不要加其他字段。**

## description 编写要点

description 是 skill 唯一的触发机制——Claude 根据它判断何时使用 skill。

### 必须包含

1. **功能描述**（1-2 句）：skill 做什么
2. **触发关键词**（中英双语）：用户可能说的话
3. **触发条件**：明确的 "Use when" 语句

### 示例

```yaml
description: >
  Generates professional infographics with 20 layout types and 17 visual styles.
  Analyzes content, recommends layout×style combinations, and generates
  publication-ready infographics. Use when user asks to create "infographic",
  "信息图", "visual summary", or "可视化".
```

```yaml
description: >
  AI image generation with OpenAI, Google and DashScope APIs. Supports
  text-to-image, reference images, aspect ratios. Use when user asks to
  generate, create, or draw images.
```

### 常见问题

| 问题 | 原因 | 修复 |
|------|------|------|
| Skill 不被触发 | description 缺少用户常用词 | 加入中英文触发词 |
| 错误触发 | description 太宽泛 | 加入 "Use when" 限定条件 |
| 与其他 skill 冲突 | 触发词重叠 | 用更具体的场景描述区分 |

## name 规范

- 全小写，kebab-case
- 2-4 个词
- 表意清晰：`cover-image` 比 `img-gen-cover` 好
