# 参考文件系统

将详细知识从 SKILL.md 拆分到独立的参考文件中，按需加载。

## 何时拆分

- SKILL.md 超过 300 行
- 存在多个变体的详细定义（风格、布局、平台等）
- 同一信息被多个流程步骤引用

## 目录组织

```
references/
├── config/                   # 配置 schema 和设置指南
│   ├── preferences-schema.md
│   └── first-time-setup.md
├── base-prompt.md            # 提示词模板
├── auto-selection.md         # 内容信号 → 推荐值映射
├── analysis-framework.md     # 内容分析方法论
├── styles/                   # 每个风格一个文件
│   ├── minimal.md
│   └── watercolor.md
├── layouts/                  # 每个布局一个文件
│   ├── bento-grid.md
│   └── timeline.md
└── workflows/                # 可选：复杂工作流的子步骤
```

## 自包含原则

每个参考文件必须 **独立可读**，同时 **可提取片段注入提示词**。

一个风格文件应包含：

```markdown
# minimal

简洁、干净、留白为主。

## 色板
| 角色 | 颜色 | Hex |
|------|------|-----|
| 主色 | 墨黑 | #1A1A1A |

## 视觉元素
- 大量留白
- 细线条边框

## 适用场景
技术文档、产品说明、极简设计

## 兼容性
| 布局 | 匹配度 |
|------|--------|
| bento-grid | 最佳 |
| timeline | 良好 |
```

## 在 SKILL.md 中引用

SKILL.md 只放 **概览表格**，详情指向文件：

```markdown
## 风格画廊

| 风格 | 描述 | 适用 |
|------|------|------|
| `minimal` | 简洁干净 | 技术文档 |
| `watercolor` | 柔和手绘 | 叙事内容 |

完整定义见 `references/styles/<style>.md`
```

## 加载时机

- **SKILL.md 被触发时**：只加载 SKILL.md 本体
- **用户选择风格后**：加载对应的 `references/styles/<style>.md`
- **进入生成步骤时**：加载 `references/base-prompt.md`

这样确保上下文窗口只装载当前步骤需要的知识。

## 扩展规则

新增变体 = 新增一个 `.md` 文件 + 在 SKILL.md 画廊表中加一行。
