---
name: local-skills-creator
description: 本地 Skill 创建统一入口。当用户需要创建、编辑或管理 Claude Code Skills 时使用。自动路由到 skill-builder（Sub-Agent 迁移、Node.js/CLI 驱动）或 skill-creator（规范化流程、打包分发）。默认输出目录：/Users/eamanc/Documents/pe/skills/。粉象/fenxiang skill 自动分类到对应团队目录。所有 skill 内容使用中文编写。触发词：创建 skill、新建技能、skill 开发、技能工厂、粉象 skill、fenxiang skill、公司 skill。
---

# 本地 Skill 创建器

统一管理 skill 创建流程，根据场景自动选择合适的子 skill。

## 核心规范

### 中文优先

- SKILL.md 正文使用中文编写
- description 字段可中英混用（确保触发词覆盖）
- 代码注释使用中文

### 默认输出目录

```
/Users/eamanc/Documents/pe/skills/
```

用户未指定时，所有新 skill 创建在此目录下。

### 粉象 Skill 分类规则

当用户说"粉象 skill"、"fenxiang skill"、"公司 skill"时，输出到粉象分类目录。

**基础路径**：`/Users/eamanc/Documents/pe/skills/fenxiang-skills/`

根据 skill 内容自动判断分类：

| 分类 | 目录 | 判断依据 |
|------|------|---------|
| android | `android/skills/` | 安卓开发、Android Studio、Kotlin、安卓组件 |
| backend | `backend/skills/` | Java、Spring、MyBatis、数据库、后端服务、API 开发 |
| common | `common/skills/` | 通用工具、跨团队共享、Git、文档规范、Skill 管理 |
| design | `design/skills/` | UI 设计、Figma、Sketch、设计规范、视觉稿 |
| devops | `devops/skills/` | 部署、Docker、K8s、CI/CD、运维脚本、服务器 |
| frontend | `frontend/skills/` | H5、React、Vue、小程序、前端页面、CSS |
| ios | `ios/skills/` | iOS 开发、Swift、Xcode、苹果组件 |
| product | `product/skills/` | 产品文档、PRD、需求分析、原型、用户故事 |
| test_engineer | `test_engineer/skills/` | 测试用例、自动化测试、QA、bug 分析 |

**分类判断流程**：

1. 分析用户描述的 skill 功能
2. 匹配上表关键词
3. 如有多个匹配，优先选择更具体的分类
4. 无法判断时，询问用户或放入 `common/skills/`

## 路由决策

根据用户需求选择调用哪个子 skill：

| 场景 | 选择 | Skill 路径 |
|------|------|-----------|
| 将现有 Sub-Agent 转为 Skill | skill-builder | `./references/skill-builder-path.md` |
| 偏好 Node.js/CLI 驱动工作流 | skill-builder | `./references/skill-builder-path.md` |
| 从零开始规范化创建 | skill-creator | `./references/skill-creator-path.md` |
| 需要打包分发（.skill 文件） | skill-creator | `./references/skill-creator-path.md` |
| 不确定 / 通用创建 | skill-creator | `./references/skill-creator-path.md` |

## 工作流程

### 1. 收集需求

询问用户：
- 这个 skill 要做什么？
- 是粉象团队 skill 还是个人 skill？
- 是迁移现有 Sub-Agent 还是从零创建？
- 是否需要打包分发？

### 2. 选择子 skill

根据上述路由表决策。如果用户明确说出关键词（如"Sub-Agent"、"打包"），直接路由。

### 3. 调用子 skill

使用 Skill 工具调用对应的子 skill：

**调用 skill-builder：**
```
适用于：Sub-Agent 迁移、Node.js/CLI 偏好
```

**调用 skill-creator：**
```
适用于：规范化创建、需要打包
```

### 4. 确定输出目录

**目录选择逻辑**：

```
用户说"粉象/fenxiang/公司 skill"？
  ├─ 是 → 根据内容判断分类 → /fenxiang-skills/{分类}/skills/
  └─ 否 → 用户指定目录？
            ├─ 是 → 使用用户指定目录
            └─ 否 → /Users/eamanc/Documents/pe/skills/
```

### 5. 补充默认配置

无论调用哪个子 skill，确保：
- SKILL.md 正文使用中文
- 文件命名遵循 kebab-case
- 粉象 skill 分类正确

## 快速创建模板

如果用户只是想快速创建一个简单的本地 skill，可直接使用以下模板：

```yaml
---
name: skill-name-here
description: 描述这个 skill 做什么，以及何时使用。包含触发关键词。
---

# Skill 名称

## 功能说明

描述 skill 的核心功能。

## 使用步骤

1. 第一步
2. 第二步
3. 第三步

## 示例

具体使用示例。
```

## 子 Skill 路径参考

详细路径信息见：
- skill-builder: `./references/skill-builder-path.md`
- skill-creator: `./references/skill-creator-path.md`
