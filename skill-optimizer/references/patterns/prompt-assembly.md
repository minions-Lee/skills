# 提示词组装

将最终提示词从多个可复用文件组装而成，而非一次性内联编写。

## 核心思路

```
base-prompt.md（骨架模板，含占位符）
  + references/layouts/<选中布局>.md
  + references/styles/<选中风格>.md
  + structured-content.md（结构化后的用户内容）
  = 最终提示词
```

## base-prompt.md 模板

```markdown
Create a professional [TYPE] following these specifications:

## Image Specifications
- **Type**: {{TYPE}}
- **Layout**: {{LAYOUT}}
- **Style**: {{STYLE}}
- **Aspect Ratio**: {{ASPECT_RATIO}}
- **Language**: {{LANGUAGE}}

## Layout Guidelines
{{LAYOUT_GUIDELINES}}

## Style Guidelines
{{STYLE_GUIDELINES}}

---

Generate based on the content below:

{{CONTENT}}

Text labels (in {{LANGUAGE}}):
{{TEXT_LABELS}}
```

## 组装流程

### Step 1: 读取模板
从 `references/base-prompt.md` 读取骨架。

### Step 2: 注入维度定义
- 读取 `references/layouts/<layout>.md`，提取布局规则
- 读取 `references/styles/<style>.md`，提取风格规则
- 替换 `{{LAYOUT_GUIDELINES}}` 和 `{{STYLE_GUIDELINES}}`

### Step 3: 注入内容
从前面步骤生成的 `structured-content.md` 提取：
- 标题、分区内容、数据点
- 文字标签（Headline、Labels）
- 替换 `{{CONTENT}}` 和 `{{TEXT_LABELS}}`

### Step 4: 保存提示词
保存到 `prompts/output.md`，方便后续复用或调整。

## 结构化内容格式

每个 section 遵循统一格式：

```markdown
## Section N: [标题]

**Key Concept**: [一句话概括]

**Content**:
- [要点1 — 原文逐字引用]
- [要点2]

**Visual Element**:
- Type: [icon/chart/diagram]
- Subject: [描绘什么]

**Text Labels**:
- Headline: "[标题文字]"
- Labels: "[标签1]", "[标签2]"
```

## 关键规则

- 所有源数据 **逐字保留**，不改写、不概括
- 提示词文件必须在生成前保存（可复用、可调试）
- 语言跟随用户确认的语言设置

## 参考图像链（多图系列）

生成系列图片时确保视觉一致：

```
图1（无参考）→ 生成，建立视觉锚点
图2（--ref 图1）→ 生成
图3（--ref 图1）→ 生成
...
```

第一张图锚定角色/配色/画风，后续所有图都引用第一张。
