---
name: project-knowledge-builder
description: |
  扫描项目代码，识别业务逻辑模糊点和噪声区域，自动生成结构化问卷文档（选择题+描述题+确认题），
  交由了解项目的人回答后，合成为高质量的项目知识库文档，供 AI 进行精准开发。
  触发词：生成项目知识库、补全知识库、项目问卷、扫描项目问题、知识库构建、
  帮我整理项目知识、生成问题文档、项目模糊点分析。
  适用场景：(1) 新项目接入 AI 开发前的知识准备，(2) 已有项目知识库不完整需要补全，
  (3) 多人协作项目需要统一认知，(4) 希望 AI 对项目有深度理解后再开发。
---

# Project Knowledge Builder — 项目知识库构建器

**扫码出题，人工答题，机器合成。**

AI 不猜测业务意图。通过代码扫描发现"不确定的地方"，转化为精准问题，让了解业务的人回答，再与代码事实合成为知识库。

## 参考文档

| 资源 | 路径 | 何时使用 |
|------|------|---------|
| 多语言扫描策略 | `references/scan-strategies.md` | 扫描特定语言/框架项目时查阅扫描入口和重点 |
| 知识库文档模板 | `references/knowledge-base-template.md` | 生成知识库文档时选用章节模板 |

### 与 project-rediscovery 的关系

| 维度 | project-rediscovery | project-knowledge-builder |
|------|-------------------|--------------------------|
| 交互 | 实时对话 | 离线问卷，可异步传递 |
| 适用 | 项目本人在场 | 专家不在场 |
| 输出 | 项目概览文档 | 结构化知识库 + 问卷 + 答案 |
| 目的 | 恢复认知 | 让 AI 具备深度理解 |

可先用 rediscovery 建立基础认知，再用本 skill 深入补全。

---

## 执行流程

```
用户触发
  ↓
Phase 0: 已有文档发现（README/wiki/注释/知识库检查）
  ↓
Phase 1: 六层扫描分析（骨架 → 数据 → API → 流程 → 集成 → 边缘）
  ↓
Phase 2: 问卷生成 → 人工填写
  ↓
Phase 3: 知识合成 → 输出知识库 → 与开发流程集成
```

---

## Phase 0：已有文档发现

**在动手扫描之前，先看项目已有什么。** 避免问出"文档里已经写了"的问题。

### 扫描路径规范

以项目根目录为基准，按以下**固定路径**依次扫描（存在则读取，不存在则跳过）：

**第一轮：项目根目录文件**

```
README.md
README
CLAUDE.md
CHANGELOG.md
HISTORY.md
CONTRIBUTING.md
ARCHITECTURE.md
```

**第二轮：文档目录（递归扫描 `*.md` `*.txt` `*.rst`）**

```
docs/
doc/
wiki/
.github/
```

**第三轮：已有知识库（精确路径）**

```
PROJECT_KNOWLEDGE/README.md
PROJECT_KNOWLEDGE/architecture.md
PROJECT_KNOWLEDGE/data-model.md
PROJECT_KNOWLEDGE/modules/*.md
PROJECT_KNOWLEDGE/ai-guide.md
PROJECT_KNOWLEDGE/open-questions.md
.project-knowledge/questionnaire-*/
```

**第四轮：API 文档（精确文件名）**

```
swagger.json
swagger.yaml
openapi.json
openapi.yaml
docs/api/**/*.{json,yaml,yml}
```

**第五轮：CI/CD 配置**

```
.github/workflows/*.yml
Jenkinsfile
.gitlab-ci.yml
.circleci/config.yml
docker-compose*.yml
Dockerfile
```

**第六轮：AI 配置**

```
.claude/
.cursorrules
.cursor/rules/
copilot-instructions.md
```

### 扫描结果输出

扫描完成后输出发现清单，让用户确认：

```
📄 已有文档发现：

  文件                              内容摘要                    状态
  ─────────────────────────────────────────────────────────────
  README.md                        项目介绍 + 启动方式         将纳入知识库
  docs/architecture.md             架构说明                    将纳入知识库
  CLAUDE.md                        AI 开发规则                 作为知识库基础
  PROJECT_KNOWLEDGE/               已有知识库（6 文件）        进入增量模式
  swagger.json                     42 个 API 定义              不再出接口相关问题

  未发现：CHANGELOG、CI/CD 配置、wiki 目录
```

### 处理规则

- 已有文档覆盖的内容 → **不再出题**，直接纳入知识库（标 🟢）
- 文档描述与代码不一致 → 出**确认题**让人判断哪个对
- 有 CLAUDE.md → 读取并作为知识库的基础，增量补全
- 有已回答的问卷 → 进入增量模式，只补充未覆盖的部分

---

## Phase 1：六层扫描分析

扫描有优先级，但**最终必须完整扫描**。优先级决定的是"先扫什么"，不是"扫不扫"。

### 扫描层级与顺序

| 层级 | 扫描内容 | 目的 | 产出 |
|------|---------|------|------|
| L1 骨架层 | 目录结构、模块划分、依赖关系 | 建立全局地图 | 模块清单 + 依赖图 |
| L2 数据层 | 实体/表结构、枚举、状态机、常量 | 理解数据模型 | 实体关系 + 状态流转 |
| L3 API 层 | 路由/Controller、入参出参、鉴权 | 理解对外接口 | API 清单 |
| L4 核心流程层 | 主要业务流程、分支逻辑、事务边界 | 理解业务规则 | 流程图 + 规则清单 |
| L5 集成层 | 第三方调用、MQ、定时任务、缓存 | 理解外部依赖 | 集成清单 |
| L6 边缘/遗留层 | 注释代码、TODO/FIXME、废弃 API、hack | 识别技术债 | 遗留问题清单 |

### 层级间依赖

```
L1 骨架 ─→ 为 L2-L6 提供模块上下文
L2 数据 ─→ 为 L4 流程分析提供实体定义
L3 API  ─→ 为 L4 流程分析提供入口
L4 流程 ─→ 独立分析（但依赖 L2/L3 的结果）
L5 集成 ─→ 补充 L4 中的外部调用细节
L6 边缘 ─→ 最后扫描，标记技术债
```

### 扫描进度输出

每完成一层，向用户报告进度：

```
✅ L1 骨架层扫描完成：发现 6 个模块，2 个外部依赖
✅ L2 数据层扫描完成：18 个实体，4 个状态字段，12 个枚举
⏳ L3 API 层扫描中...
```

### 项目类型识别

| 识别标志 | 项目类型 |
|---------|---------|
| `pom.xml` / `build.gradle` + `src/main/java` | Java 后端 |
| `pom.xml` + `AndroidManifest.xml` | Android |
| `package.json` + (`next.config` / `nuxt.config` / `vite.config`) | 前端 |
| `package.json` + (`nest-cli.json` / `express` / `koa`) | Node.js 后端 |
| `requirements.txt` / `pyproject.toml` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `*.sln` / `*.csproj` | .NET/C# |
| `pubspec.yaml` | Flutter |
| 多种特征共存 | Monorepo — 按子项目分别识别 |

各语言/框架的详细扫描入口和重点见 [references/scan-strategies.md](references/scan-strategies.md)。

### 模糊点识别（五类）

| 类型 | 识别目标 | 示例 |
|------|---------|------|
| A 命名歧义 | 含义不明的命名、缩写、同义词 | `handleData`、`biz`、User vs Member |
| B 逻辑噪声 | 注释代码、TODO、空 catch、冗余判断 | `// FIXME`、`catch(e) {}` |
| C 隐式规则 | 魔法数字、硬编码参数、复杂条件 | `status == 3`、`rate = 0.05` |
| D 架构疑点 | 违反分层、未用依赖、多方案并存 | Controller 直接操作 DB |
| E 流程断点 | 未调用方法、空实现、缺失错误路径 | 有创建无删除 |

---

## Phase 2：问卷生成

### 问题类型

| 类型 | 适用场景 | 格式要点 |
|------|---------|---------|
| **选择题** | 状态含义、是/否、枚举 | 选项互斥，必含"其他" |
| **描述题** | 业务流程、设计原因、历史背景 | 附 AI 观察到的部分流程，请人补充 |
| **确认题** | AI 有把握但需验证 | 展示 AI 分析，请人确认/纠正 |

**比例不固定**——根据扫描发现的模糊点类型自然决定。状态/枚举多则选择题多，流程复杂则描述题多。

### 问题格式要求

每个问题必须包含：**标题**（`[模块名] + 问题`）、**代码位置**（文件:行号）、**上下文**（代码片段或 AI 观察）。

- **选择题**：选项互斥，必含"其他：___"兜底
- **描述题**：先展示 AI 观察到的部分，标出 ❓ 不确定处，请人补充/纠正
- **确认题**：展示 AI 分析，提供 "正确 / 部分正确，补充 / 不正确，实际是" 三个选项

### 问题优先级

| 优先级 | 类型 | 说明 |
|-------|------|------|
| P0 | 核心业务流程 | 不理解无法正确开发 |
| P1 | 状态/枚举含义 | 影响逻辑判断 |
| P2 | 架构决策 | 影响扩展方向 |
| P3 | 命名约定 | 影响一致性 |
| P4 | 历史遗留 | 了解背景 |

### 数量控制

- 单次 **15-40 题**，不超过 50
- 超过 50 个模糊点 → 按优先级分批，P0/P1 先出
- 每个模块 3-8 题
- 每题必须附**代码位置**和**上下文**
- 不问代码已能回答的问题

### 问卷结构

问卷按模块拆分为多个文件（与知识库 `modules/` 对应），放在 `.project-knowledge/questionnaire-v{N}/` 目录下。

每个问卷文件头部统一格式：

```markdown
# {项目名称} — {模块名/全局} 知识问卷

> 版本：v1 | 生成时间：YYYY-MM-DD | 问题数：N 题
> 填写说明：选择题打 [x]，描述题尽量详细，不确定标注"不确定"，AI 分析有误直接纠正
```

---

## Phase 3：知识合成

### 3.1 答案解析

1. **读取回答文档**
2. **交叉验证**：
   - 答案与代码一致 → 标 🟢 纳入知识库
   - 答案与代码矛盾 → 标 🔴，输出矛盾点让用户澄清
   - 回答"不确定" → 纳入开放问题
3. **关联推导**：A 的回答可能隐含 B 的答案，自动补全（标 🟡）
4. **合并已有文档**：Phase 0 发现的文档内容与问卷答案合并

### 3.2 知识库生成

按问卷对应的维度，将答案写入 `PROJECT_KNOWLEDGE/` 目录中的对应文件：

- `global.md` 的答案 → 写入 `README.md`、`architecture.md`、`data-model.md` 等全局文件
- `{module}.md` 的答案 → 写入 `modules/{module}.md`
- 跨模块的规则 → 写入 `ai-guide.md`
- 未解决的问题 → 写入 `open-questions.md`

文件按需创建，不生硬套用全部模板。各文件模板详见 [references/knowledge-base-template.md](references/knowledge-base-template.md)。

### 3.3 置信度标记

| 标记 | 含义 | 来源 |
|------|------|------|
| 🟢 | 已确认 | 人工回答 + 代码验证一致 |
| 🟡 | AI 推断 | 代码分析得出，未经人工确认 |
| 🔴 | 存疑 | 答案与代码矛盾 / 回答不确定 |

### 3.4 与开发流程集成

知识库不是生成就完事了——它要在开发中被使用。

**集成方式**：

| 方式 | 做法 | 效果 |
|------|------|------|
| 写入 CLAUDE.md | 将关键规则和命名约定追加到项目的 CLAUDE.md | Claude Code 每次启动自动加载 |
| 引用路径 | 在知识库中标注代码位置，Claude 可直接跳转 | 开发时快速定位 |
| 规则清单 | 提取"AI 开发指南"章节为独立检查清单 | Code Review 时对照检查 |

**知识库生成后自动执行**：
1. 检查项目是否有 CLAUDE.md
2. 有 → 提议将核心规则（业务规则、命名约定、容易踩的坑）追加到 CLAUDE.md
3. 无 → 提议基于知识库生成 CLAUDE.md 的业务规则部分

---

## 增量模式

当项目已有知识库时执行增量更新，不从头再来。

### 触发条件

- 用户说"补全知识库"
- 知识库中有 🟡 / 🔴 条目
- 代码有大变更（新增模块 / 重构）
- 用户指定模块需要深入

### 增量流程

```
读取 PROJECT_KNOWLEDGE/ 下所有文件
  ↓
扫描代码变更（git diff 或全量重扫）
  ↓
排除已覆盖的知识点
  ↓
只针对新增模糊点生成增量问卷（.project-knowledge/questionnaire-v{N+1}/）
  ↓
合并答案到已有文件（保留原有 🟢 条目），新增模块则创建新的 modules/*.md
```

---

## 文件输出约定

### 知识库目录结构

```
{项目根目录}/
├── PROJECT_KNOWLEDGE/                       # 知识库目录（与 README.md 同级）
│   ├── README.md                            # 索引：项目概述 + 文件导航 + 覆盖度统计
│   ├── architecture.md                      # 技术架构、技术栈、架构决策
│   ├── data-model.md                        # 实体关系、枚举速查表、状态机
│   ├── integrations.md                      # 第三方服务、MQ、定时任务、缓存
│   ├── permissions.md                       # 角色定义、权限矩阵、鉴权流程
│   ├── ai-guide.md                          # AI 开发规则、踩坑清单、命名约定
│   ├── open-questions.md                    # 未解决的问题
│   └── modules/                             # 业务模块（每模块一文件）
│       ├── user.md
│       ├── order.md
│       └── payment.md
│
└── .project-knowledge/                      # 工作目录（问卷等中间产物）
    ├── questionnaire-v1/                    # 第 1 次问卷（按模块拆分）
    │   ├── global.md                        # 全局 + 架构问题
    │   ├── user.md                          # 用户模块问题
    │   └── order.md                         # 订单模块问题
    └── questionnaire-v2/                    # 第 2 次增量问卷
        └── ...
```

### 拆分原则

**知识库**按两个维度拆分文件：

| 维度 | 文件 | 增长特征 |
|------|------|---------|
| 宏观/全局 | `README.md`、`architecture.md` | 稳定，低频更新 |
| 全局数据 | `data-model.md`、`integrations.md`、`permissions.md` | 随集成/实体增加 |
| **业务细节** | `modules/{module}.md` | **主要增长点**，一个模块一个文件 |
| 实操 | `ai-guide.md` | 随经验积累 |
| 动态 | `open-questions.md` | 先增后减 |

核心思路：**全局性内容在顶层，业务细节按模块拆到 `modules/`**。开发某个模块时只需加载 `README.md` + `architecture.md` + `modules/{module}.md`。

**问卷**也按模块拆分：

- 每次问卷是一个目录 `questionnaire-v{N}/`
- 全局/架构问题放 `global.md`
- 各业务模块的问题各自一个文件
- 好处：可以把不同模块的问卷分发给不同的人回答

### 文件按需创建

| 文件 | 创建条件 |
|------|---------|
| `README.md` | 始终创建 |
| `architecture.md` | 始终创建 |
| `modules/*.md` | 始终创建（至少一个模块） |
| `ai-guide.md` | 始终创建 |
| `open-questions.md` | 有未解决问题时 |
| `data-model.md` | 有数据库 / ORM 时 |
| `integrations.md` | 有第三方调用 / MQ / 定时任务时 |
| `permissions.md` | 有权限/角色体系时 |

### 模块文件命名

模块文件名取自扫描发现的模块名（小写，短横线分隔）：

| 扫描发现 | 文件名 |
|---------|--------|
| `UserController` / `routes/user.ts` / `user/` 包 | `modules/user.md` |
| `OrderController` / `routes/order.ts` | `modules/order.md` |
| `PaymentService`（独立模块） | `modules/payment.md` |
| `管理后台`（admin 相关路由） | `modules/admin.md` |

各文件的详细模板见 [references/knowledge-base-template.md](references/knowledge-base-template.md)。

---

## 启动流程

1. 检查项目根目录是否已有 `PROJECT_KNOWLEDGE/` → 有则进入增量模式
2. 确认扫描范围（全项目 / 指定模块）
3. 执行 Phase 0 → Phase 1 → Phase 2
4. 输出问卷，引导用户：

```
问卷已生成：.project-knowledge/questionnaire-v1/
  ├── global.md     (8 题)
  ├── user.md       (6 题)
  ├── order.md      (10 题)
  └── payment.md    (4 题)
📋 共 28 题 | ⏱ 预计 20 分钟
可将不同模块的问卷分发给对应负责人。填完后告诉我"问卷填好了"。
```

5. 用户回复后执行 Phase 3，生成/更新 `PROJECT_KNOWLEDGE/` 目录
6. 提议将 `ai-guide.md` 中的核心规则集成到 CLAUDE.md

---

## 质量检查

### 问卷质量

- 每题有代码位置引用
- 选择题选项互斥
- 描述题有足够上下文
- 不问代码已能回答的问题
- 总题数 15-40

### 知识库质量

- 每条标注置信度
- 代码位置准确
- 无与代码矛盾的描述
- 开放问题单独列出
- AI 开发指南可直接指导开发

---

## 反模式

1. **AI 猜答案**：不确定就问，不要猜。用 🟡 标推断，🔴 标矛盾
2. **问题太宽泛**："这个项目怎么设计的？" → 拆成可回答的小问题
3. **无代码上下文**：问题没附代码，回答者不知道在问什么
4. **问卷太长**：超 50 题回答者疲劳，按优先级分批
5. **只问不验证**：回答不与代码交叉验证，可能纳入错误信息
6. **知识库不更新**：代码变了知识库没变，比没有知识库更危险
7. **生成即结束**：知识库没有集成到开发流程中（CLAUDE.md），等于白做
