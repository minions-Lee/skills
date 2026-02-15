---
name: linking-skills
description: 软链接 skill 到目标目录。触发词：映射 skill、链接 skill、ln skill、软链接、link skill。默认映射到 ~/.claude/skills/，支持 Codex、Cursor、Gemini 等平台。可映射单个 skill 或批量映射整个角色目录。刚创建完 skill 后可直接调用映射。
---

# Skill 软链接工具

将 skill 目录软链接到 AI 工具的配置目录，使 skill 生效。

## 目标平台

| 平台 | 全局目录 | 项目目录 |
|------|---------|---------|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| OpenAI Codex | `~/.codex/skills/` | `.codex/skills/` |
| Cursor | `~/.cursor/skills/` | `.cursor/skills/` |
| Gemini CLI | `~/.gemini/skills/` | `.gemini/skills/` |
| Windsurf | `~/.codeium/windsurf/skills/` | `.windsurf/skills/` |
| GitHub Copilot | `~/.copilot/skills/` | `.github/skills/` |

**默认目标**：`~/.claude/skills/`

## 映射方式

### 单个 Skill 映射

```bash
ln -s <skill源目录> <目标目录>
```

**示例**：
```bash
# 映射单个 skill 到 Claude
ln -s /Users/eamanc/Documents/pe/skills/maven-operating ~/.claude/skills/maven-operating

# 映射到 Codex
ln -s /Users/eamanc/Documents/pe/skills/maven-operating ~/.codex/skills/maven-operating
```

### 批量映射（角色目录下所有 skills）

```bash
ln -sf <角色skills目录>/*/ <目标目录>
```

**注意**：必须用 `*/` 而不是 `*`，确保只映射目录。

**示例**：
```bash
# 映射 backend 下所有 skills
ln -sf /Users/eamanc/Documents/pe/skills/fenxiang-skills/backend/skills/*/ ~/.claude/skills/

# 映射 frontend 下所有 skills
ln -sf /Users/eamanc/Documents/pe/skills/fenxiang-skills/frontend/skills/*/ ~/.claude/skills/

# 映射 common 下所有 skills
ln -sf /Users/eamanc/Documents/pe/skills/fenxiang-skills/common/skills/*/ ~/.claude/skills/
```

## 常用源目录

### 个人 Skills
```
/Users/eamanc/Documents/pe/skills/
```

### 粉象团队 Skills
```
/Users/eamanc/Documents/pe/skills/fenxiang-skills/
├── android/skills/
├── backend/skills/
├── common/skills/
├── design/skills/
├── devops/skills/
├── frontend/skills/
├── ios/skills/
├── product/skills/
└── test_engineer/skills/
```

## 使用流程

### 1. 确定映射范围

询问用户：
- 映射哪个 skill？（如果上下文中刚创建了 skill，默认映射新创建的）
- 是单个 skill 还是整个角色目录？
- 映射到哪个平台？（默认 Claude）
- 是全局映射还是项目级映射？

### 2. 判断映射类型

| 场景 | 命令格式 |
|-----|---------|
| 单个 skill | `ln -s 源目录 目标目录/skill名` |
| 角色下所有 skills | `ln -sf 源目录/*/ 目标目录` |

### 3. 执行映射

执行 ln 命令，并验证结果：
```bash
ls -la <目标目录> | grep <skill名>
```

## 注意事项

### 不要乱映射

- **项目专用 skill**：只映射到项目的 `.claude/skills/`，不要映射到全局
- **全局通用 skill**：映射到 `~/.claude/skills/`
- **遵从用户要求**：用户没说映射就不要自动映射

### 已存在处理

如果目标已存在同名链接：
```bash
# 强制覆盖
ln -sf <源目录> <目标目录>
```

### 验证映射

```bash
# 查看链接指向
ls -la ~/.claude/skills/<skill名>

# 确认 SKILL.md 存在
cat ~/.claude/skills/<skill名>/SKILL.md | head -5
```

## 快速命令

```bash
# 映射刚创建的 skill（替换 skill-name）
ln -s /Users/eamanc/Documents/pe/skills/<skill-name> ~/.claude/skills/<skill-name>

# 映射到 Codex
ln -s /Users/eamanc/Documents/pe/skills/<skill-name> ~/.codex/skills/<skill-name>

# 批量映射 backend skills
ln -sf /Users/eamanc/Documents/pe/skills/fenxiang-skills/backend/skills/*/ ~/.claude/skills/
```
