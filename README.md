# Skills 仓库 - Claude Code 技能索引

> 汇集多个开源 Skill 仓库的 Claude Code 技能集合，涵盖开发工具、营销、内容创作、文档处理、效率提升等领域。

---

## 仓库概览

| 仓库 | 来源 | Skill 数量 | 说明 |
|------|------|-----------|------|
| **自建 Skills** | 本仓库根目录 | ~18 | 团队自用工具链（Git、Maven、部署、RSS 等） |
| [superpowers](https://github.com/obra/superpowers) | @obra | 14 | 开发流程最佳实践（TDD、Code Review、调试、计划等） |
| [marketingskills](https://github.com/coreyhaines31/marketingskills) | @coreyhaines31 | 26 | 营销全栈技能（CRO、SEO、文案、广告、增长） |
| [NanoBanana-PPT-Skills](https://github.com/op7418/NanoBanana-PPT-Skills) | @op7418 (歸藏) | 1 | AI 自动生成高质量 PPT 图片+视频，支持智能转场 |
| [baoyu-skills](https://github.com/JimLiu/baoyu-skills) | @JimLiu (宝玉) | 15 | 自媒体内容创作全家桶（小红书、封面图、漫画、发布） |
| [awesome-claude-skills](https://github.com/ComposioHQ/awesome-claude-skills) | @ComposioHQ | 500+ | Claude Skills 大合集 + 500+ App 自动化集成 |
| [onewave-ai-claude-skills](./onewave-ai-claude-skills/) | @onewave-ai | ~107 | 多领域 Skill 合集（品牌、播客、分析、社交等） |
| [SkillFiveSonRide_skills](./SkillFiveSonRide_skills/) | 子模块 | 6 | Vercel 部署、Cartier UI、会议纪要、子模块管理等 |
| [ai-dev-standards](./ai-dev-standards/) | 子模块 | 大量 | AI 开发标准、MCP Server 集合、集成指南 |

---

## 分类索引

### 1. 开发工具与流程

> 编码、构建、部署、Git 等开发日常工具

| Skill | 所属仓库 | 简介 | 适用场景 |
|-------|---------|------|---------|
| `committing-git-changes` | 自建 | 自动暂存、生成提交信息、推送远程 | 提交代码时 |
| `docker-bluegreen-deploy` | 自建 | 生成 Docker 蓝绿部署脚本，零停机切换 | 新项目需要部署脚本、需要零停机发布 |
| `linux-server-bootstrap` | 自建 | 阿里云服务器初始化（Docker、JRE17、Nginx 等） | 新服务器环境搭建 |
| `maven-operating` | 自建 | Maven 构建部署，含本机路径和 Nexus 认证 | mvn 打包/部署/编译 |
| `linking-skills` | 自建 | 软链接 Skill 到 Codex/Cursor/Gemini 等平台 | 跨平台共享 Skill |
| `local-skills-creator` | 自建 | 本地 Skill 统一创建入口 | 创建新 Skill |
| `find-skill` | 子模块 | 从生态中发现和安装 Skill | "有没有 XXX 的 skill" |
| `prd-taskmaster` | 子模块 | PRD 生成器 + TaskMaster 任务分解 | 需求文档驱动开发 |
| `planning-with-files` | 子模块 | 基于文件的复杂任务计划管理 | 多步骤复杂任务 |

### 2. 开发最佳实践（superpowers）

> obra 出品的 14 个工程实践 Skill，覆盖开发全流程

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `brainstorming` | 创意工作前的意图/需求/设计探索 | 新功能开发前的需求梳理 |
| `writing-plans` | 根据需求编写结构化实现计划 | 拿到需求后制定技术方案 |
| `executing-plans` | 在会话中执行已编写的实现计划 | 按计划逐步实现 |
| `test-driven-development` | TDD：先写测试再写实现 | 任何功能开发或 Bug 修复 |
| `systematic-debugging` | 系统化调试：遇到 Bug 先诊断再修复 | 遇到任何 Bug 或异常行为 |
| `subagent-driven-development` | 并行 Sub-Agent 驱动开发 | 有多个独立任务可并行 |
| `dispatching-parallel-agents` | 分派独立并行任务 | 2+ 个无依赖任务 |
| `using-git-worktrees` | Git Worktree 隔离开发 | 需要隔离环境的功能开发 |
| `finishing-a-development-branch` | 完成分支：合并/PR/清理引导 | 功能开发完成准备合入 |
| `requesting-code-review` | 发起 Code Review | 完成功能或合并前验证 |
| `receiving-code-review` | 收到 Review 反馈后处理 | 收到 Review 意见时 |
| `verification-before-completion` | 完成前验证：先跑测试再声称完成 | 准备提交或 claim 完成前 |
| `writing-skills` | 创建/编辑/验证 Skill | 开发新 Skill |
| `using-superpowers` | 会话启动时发现和加载 Skill | 每次对话开始 |

### 3. 营销增长（marketingskills）

> Corey Haines 出品的 26 个营销 Skill，覆盖 CRO、SEO、文案、广告、增长

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `page-cro` | 页面转化率优化（首页、落地页等） | 页面转化率低、需要优化 |
| `signup-flow-cro` | 注册/试用激活流程优化 | 优化注册转化率 |
| `form-cro` | 表单转化率优化（非注册表单） | 优化线索收集表单 |
| `onboarding-cro` | 用户激活与 Onboarding 优化 | 提升新用户激活率 |
| `popup-cro` | 弹窗/浮层转化优化 | 设计转化弹窗 |
| `paywall-upgrade-cro` | 付费墙/升级页面优化 | 提升付费转化 |
| `copywriting` | 营销页面文案（首页、落地页、产品页） | 写营销文案 |
| `copy-editing` | 营销文案编辑与润色 | 修改已有文案 |
| `cold-email` | B2B 冷启动邮件和跟进序列 | 写开发信 |
| `email-sequence` | 邮件自动化序列/滴灌营销 | 设计自动邮件流 |
| `seo-audit` | 技术和页面 SEO 审计 | SEO 问题诊断 |
| `programmatic-seo` | 规模化生成 SEO 页面 | 批量生成 SEO 内容 |
| `schema-markup` | 结构化数据/Schema 标记优化 | 添加搜索结果富文本 |
| `paid-ads` | 付费广告（Google/Meta/LinkedIn/X） | 投放广告 |
| `content-strategy` | 内容策略规划 | 制定内容计划 |
| `social-content` | 社交媒体内容创作 | 发社交媒体内容 |
| `competitor-alternatives` | 竞品对比页面 | 制作竞品对比页 |
| `ab-test-setup` | A/B 测试设计与实施 | 需要做 A/B 测试 |
| `analytics-tracking` | 数据追踪与埋点 | 设置数据分析 |
| `pricing-strategy` | 定价策略与包装设计 | 定价决策 |
| `launch-strategy` | 产品发布策略 | 新产品/功能发布 |
| `marketing-ideas` | 营销灵感与策略建议 | 需要营销灵感 |
| `marketing-psychology` | 营销心理学/行为科学应用 | 运用心理学做营销 |
| `referral-program` | 推荐/邀请机制设计 | 设计裂变增长机制 |
| `free-tool-strategy` | 免费工具策略（获客/SEO） | 用免费工具获客 |
| `product-marketing-context` | 产品营销上下文文档 | 统一营销信息 |

### 4. 内容创作与自媒体（baoyu-skills）

> 宝玉老师出品的 15 个内容创作 Skill，从创作到发布一站式

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `baoyu-xhs-images` | 生成 1-10 张小红书风格信息图（9 种风格 × 6 种布局） | 做小红书图文内容 |
| `baoyu-infographic` | 专业信息图生成（20 种布局 × 17 种风格） | 制作数据可视化信息图 |
| `baoyu-cover-image` | 文章封面图生成（9 配色 × 6 风格 = 54 种组合） | 给文章配封面图 |
| `baoyu-slide-deck` | 从文章生成专业幻灯片图片（16 种风格） | 快速做演示幻灯片 |
| `baoyu-comic` | 知识漫画创作（多画风/色调） | 做教育/科普类漫画内容 |
| `baoyu-article-illustrator` | 文章智能配图 | 给长文自动配插图 |
| `baoyu-post-to-wechat` | 一键发布到微信公众号 | 发微信公众号文章 |
| `baoyu-post-to-x` | 发布推文（支持图片和长文） | 发 Twitter/X |
| `baoyu-image-gen` | 默认图像生成后端 | 需要 AI 生成图片时 |
| `baoyu-danger-gemini-web` | Gemini API 封装（文本 + 图像） | AI 文本/图像生成底层 |
| `baoyu-url-to-markdown` | URL 内容转 Markdown | 抓取网页转 Markdown |
| `baoyu-danger-x-to-markdown` | X/Twitter 内容转 Markdown | 抓取推文内容 |
| `baoyu-compress-image` | 图片压缩 | 压缩图片体积 |
| `baoyu-format-markdown` | Markdown 格式化 | 统一 Markdown 格式 |
| `baoyu-markdown-to-html` | Markdown 转 HTML | 转换格式 |

### 5. PPT 与演示（NanoBanana-PPT-Skills）

> 歸藏出品的 AI PPT 生成工具

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `ppt-generator-pro` | AI 自动生成 PPT 图片 + 转场视频。使用 Nano Banana Pro 生成 2K/4K 图片，可灵 AI 生成转场动画，内置渐变毛玻璃和矢量插画两种风格，带交互式播放器 | 需要快速制作高质量 PPT、产品演示、商务汇报 |

### 6. 文档处理（awesome-claude-skills）

> ComposioHQ 的 Skills 大合集中的文档处理能力

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `docx` | Word 文档：创建、编辑、追踪修改、批注、格式化 | 处理 Word 文档 |
| `pdf` | PDF：提取文本/表格、合并、拆分、加注释 | 处理 PDF 文件 |
| `pptx` | PPT：读取、生成、调整布局和模板 | 处理 PPT 文件 |
| `xlsx` | Excel：公式、图表、数据转换、格式化 | 处理 Excel 表格 |

### 7. 开发与代码工具（awesome-claude-skills）

> 开发者效率工具精选

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `artifacts-builder` | 用 React + Tailwind + shadcn/ui 构建复杂 HTML 组件 | 制作复杂前端组件 |
| `mcp-builder` | MCP Server 创建指南（Python/TypeScript） | 开发 MCP 集成 |
| `webapp-testing` | Playwright 自动化测试本地 Web 应用 | 前端 UI 测试 |
| `skill-creator` | Skill 创建指南和最佳实践 | 创建新 Skill |
| `changelog-generator` | 从 Git 提交自动生成用户友好的 Changelog | 发版时生成更新日志 |
| `connect` | 连接 500+ 应用（Gmail/Slack/GitHub/Notion 等） | 需要跨应用自动化 |

### 8. 商业与分析（awesome-claude-skills）

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `brand-guidelines` | 品牌色彩/字体规范应用 | 统一品牌视觉 |
| `competitive-ads-extractor` | 竞品广告分析 | 研究竞品广告策略 |
| `domain-name-brainstormer` | 域名创意生成 + 可用性检查 | 注册新域名 |
| `internal-comms` | 内部沟通文档（周报、FAQ、项目更新） | 写内部文档 |
| `lead-research-assistant` | 线索研究与潜客分析 | B2B 获客研究 |
| `developer-growth-analysis` | 开发者增长分析 | 分析开发者社区增长 |

### 9. 创意与设计（awesome-claude-skills）

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `canvas-design` | 高保真视觉设计（海报、艺术、平面） | 制作海报/视觉设计 |
| `slack-gif-creator` | Slack 专用 GIF 动画制作 | 制作 Slack 表情/GIF |
| `theme-factory` | 10 套预设主题 + 自定义主题生成 | 给文档/页面换主题 |
| `image-enhancer` | 图片增强与优化 | 提升图片质量 |
| `video-downloader` | 视频/音频下载（YouTube/Bilibili/1000+ 站点） | 下载视频 |

### 10. 效率与知识管理

> 日常效率工具

| Skill | 所属仓库 | 简介 | 适用场景 |
|-------|---------|------|---------|
| `rss-daily-digest` | 自建 | 254 个 RSS 源 AI 摘要 + 钉钉推送 | 每日 AI 资讯速览 |
| `quality-website-search` | 自建 | 聚合多源搜索优质网站/工具/资源 | 找好用的工具和网站 |
| `project-rediscovery` | 自建 | 结构化重新了解遗忘的项目 | 接手旧项目、重新熟悉 |
| `guided-learning` | 自建 | 引导式学习，从零到精通 | 学习新概念 |
| `notebooklm-skill` | 子模块 | 直接查询 NotebookLM 笔记本 | 需要文档溯源的答案 |
| `style-extractor` | 子模块 | 从网页提取 UI 风格和动效指南 | 分析网站设计风格 |
| `video-downloader` | 自建 | 视频/音频下载 + Whisper 转写 | 下载视频、提取逐字稿 |
| `xiaoyuzhou-downloader` | 自建 | 小宇宙播客下载 + 完整转录 | 下载播客、提取文字 |
| `fish-tank` | 自建 | 虚拟 ASCII 鱼缸（趣味彩蛋） | 摸鱼放松 |

### 11. 500+ App 自动化（awesome-claude-skills）

> Composio 驱动的应用集成，让 Claude 能操作真实应用

覆盖主流 SaaS 平台，包括但不限于：

| 类别 | 代表应用 |
|------|---------|
| **CRM & 销售** | Salesforce, HubSpot, Pipedrive, Close, Apollo |
| **项目管理** | Jira, Asana, Linear, Monday, Trello, ClickUp |
| **通讯协作** | Slack, Discord, Telegram, Microsoft Teams |
| **邮件营销** | Mailchimp, SendGrid, Brevo, ConvertKit |
| **云存储** | Google Drive, Dropbox, OneDrive, Box |
| **代码托管** | GitHub, GitLab, Bitbucket |
| **支付财务** | Stripe, QuickBooks, Xero |
| **社交媒体** | Twitter/X, LinkedIn, Instagram, Facebook, Reddit |
| **AI 服务** | OpenAI, Anthropic, Replicate, ElevenLabs |
| **数据分析** | Google Analytics, Mixpanel, PostHog, Amplitude |

### 12. onewave-ai 多领域合集（107 个 Skill）

> 涵盖品牌、播客、社交、分析等多个垂直领域

| 代表 Skill | 简介 |
|-----------|------|
| `brand-consistency-checker` | 品牌一致性检查 |
| `podcast-studio` | 播客工作室 |
| `reddit-analyzer` | Reddit 内容分析 |
| `linkedin-post-optimizer` | LinkedIn 帖子优化 |
| `landing-page-copywriter` | 落地页文案 |
| `contract-analyzer` | 合同分析 |
| `color-palette-extractor` | 配色方案提取 |
| `quiz-maker` | 问卷/测试制作 |
| `meeting-intelligence` | 会议智能分析 |
| `stock-photo-finder` | 图库搜索 |
| *...等 107 个 Skill* | |

### 13. SkillFiveSonRide 补充合集

| Skill | 简介 | 适用场景 |
|-------|------|---------|
| `deploy-to-vercel` | Vercel 部署全流程指南 | 部署前端应用到 Vercel |
| `generating-cartier-ui` | Cartier 奢侈品风格 UI 组件 | 高端品牌网页设计 |
| `git-submodule-manager` | Git 子模块自动化管理 | 管理多仓库子模块 |
| `meeting-minutes` | 会议录音转结构化纪要 | 会后整理会议记录 |
| `nextjs-migration` | React 迁移 Next.js App Router 指南 | 升级到 Next.js |
| `notebooklm` | NotebookLM 笔记本查询 | 查询笔记获取答案 |

---

## 快速开始

### 安装单个 Skill

```bash
# 方式一：直接复制到项目
cp -r <skill-path> .claude/skills/

# 方式二：使用 npx skills CLI
npx skills add coreyhaines31/marketingskills --skill page-cro
npx skills add jimliu/baoyu-skills

# 方式三：软链接（推荐，方便更新）
ln -s /path/to/skill ~/.claude/skills/skill-name
```

### 克隆完整仓库

```bash
git clone --recurse-submodules git@github.com:minions-Lee/skills.git
```

### 更新所有子模块

```bash
git submodule update --remote --merge
```

---

## 统计

| 指标 | 数量 |
|------|------|
| 仓库总数 | 9 个 |
| 自建 Skill | ~18 个 |
| 第三方 Skill | 680+ 个 |
| App 自动化集成 | 500+ 个 |
| **总计** | **~1200+** |
