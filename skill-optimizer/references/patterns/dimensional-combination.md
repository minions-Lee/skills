# 维度组合

将设计选择分解为独立、正交的维度，自由组合。

## 核心思路

不逐一枚举每种输出变体，而是定义 N 个独立维度。用户每个维度选一个值，组合即定义输出。

**示例**：9 种配色 × 6 种渲染 = 54 种组合，仅需 15 个定义文件。

## 如何设计维度

### 1. 识别轴

找到输出中独立变化的方面：

| 常见轴 | 控制什么 | 示例 |
|--------|---------|------|
| **布局/结构** | 信息架构 | bento-grid, timeline, hub-spoke, funnel |
| **风格/美学** | 视觉外观 | minimal, watercolor, chalkboard, pixel-art |
| **语调/氛围** | 情感基调 | warm, dramatic, neutral, energetic |
| **密度/复杂度** | 信息量 | sparse, balanced, dense |

### 2. 确保正交性

测试：改变一个维度不应迫使另一个维度跟着变。如果"选布局 X 就必须用风格 Y"，说明它们不独立——合并或加兼容性矩阵。

### 3. 为每个值建文档

每个值一个 reference 文件，必须 **自包含**：

```markdown
# warm（配色）

温暖、亲和、自然色调。

## 色板
| 角色 | 颜色 | Hex |
|------|------|-----|
| 主色 | 赤陶 | #C75B39 |
| 辅色 | 沙色 | #E8D5B7 |

## 视觉处理
- 圆角、柔和阴影
- 手绘线条质感

## 适用场景
生活方式、个人故事、健康内容

## 兼容性
| 其他维度 | 最佳匹配 | 避免 |
|---------|---------|------|
| 布局: sparse | 很好 | - |
| 渲染: pixel | - | 不搭 |
```

### 4. 添加兼容性矩阵（需要时）

仅当某些组合效果差时：

```markdown
| 风格 \ 布局 | bento-grid | timeline | hub-spoke |
|------------|-----------|----------|----------|
| minimal | 最佳 | 良好 | 良好 |
| watercolor | 良好 | 最佳 | 避免 |
| pixel-art | 良好 | 避免 | 良好 |
```

### 5. 添加自动选择规则

将内容信号（关键词、结构）映射到推荐值：

```markdown
| 内容信号 | 推荐风格 | 推荐布局 |
|---------|---------|---------|
| 教程、步骤、指南 | ikea-manual | linear-progression |
| 对比、A vs B | corporate-memphis | binary-comparison |
| 历史、时间线 | aged-academia | linear-progression |
```

### 6. 定义预设（可选）

高频组合封装为快捷名称：

```markdown
| 预设 | 等价于 | 特殊规则 |
|------|-------|---------|
| ohmsha | manga + neutral | 视觉隐喻，不要对话头像 |
| wuxia | ink-brush + action | 气效、战斗画面、氛围元素 |
```

## 文件组织

```
references/
├── styles/              # 每个风格值一个 .md
│   ├── minimal.md
│   ├── watercolor.md
│   └── chalkboard.md
├── layouts/             # 每个布局值一个 .md
│   ├── bento-grid.md
│   ├── timeline.md
│   └── hub-spoke.md
├── auto-selection.md    # 内容信号 → 值映射
└── presets/             # 可选命名组合
    └── ohmsha.md
```

## 在 SKILL.md 中

只保留 **画廊表格**（名称 + 一句描述 + 适用场景）和 **自动选择摘要**。完整定义放在 reference 文件中。

## 扩展规则

新增变体 = 加一个 `.md` 文件。不改代码，不改 SKILL.md。
