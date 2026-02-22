# 配置优先级链

建立分层配置系统，让用户在不同层级自定义 skill 行为。

## 优先级顺序（高到低）

```
CLI 参数 > EXTEND.md > 环境变量 > 项目级 .env > 用户级 .env > 默认值
```

## EXTEND.md 两级目录

| 层级 | 路径 | 用途 |
|------|------|------|
| 项目级 | `.baoyu-skills/<skill-name>/EXTEND.md` | 团队/项目共享偏好 |
| 用户级 | `~/.baoyu-skills/<skill-name>/EXTEND.md` | 个人偏好 |

项目级优先于用户级。

## EXTEND.md 检查模板

在 SKILL.md 的 Step 0 中使用：

```markdown
### Step 0: 加载配置 (EXTEND.md)

用 Bash 检查：

\```bash
test -f .baoyu-skills/<skill-name>/EXTEND.md && echo "project"
test -f "$HOME/.baoyu-skills/<skill-name>/EXTEND.md" && echo "user"
\```

| 结果 | 操作 |
|------|------|
| 找到 | 读取、解析、展示摘要 |
| 未找到 | 用 AskUserQuestion 执行首次设置 |
```

## EXTEND.md 格式

使用 YAML frontmatter：

```yaml
---
version: 1
default_style: minimal
default_layout: bento-grid
default_aspect: landscape
language: zh
---
```

## .env 文件

存放 API key 等敏感配置：

| 层级 | 路径 |
|------|------|
| 项目级 | `.baoyu-skills/.env` |
| 用户级 | `~/.baoyu-skills/.env` |

```env
GOOGLE_API_KEY=your-key
OPENAI_API_KEY=your-key
```

## 在 SKILL.md 中声明

明确列出支持的配置项：

```markdown
**EXTEND.md 支持**: 默认风格 | 默认布局 | 默认尺寸 | 语言偏好
```

## 首次设置

当 EXTEND.md 不存在时触发首次设置流程：

1. 标记为 ⛔ BLOCKING（必须完成才能继续）
2. 用 AskUserQuestion 收集偏好
3. 写入 EXTEND.md
4. 继续正常流程

配置 schema 详情放在 `references/config/preferences-schema.md`。
