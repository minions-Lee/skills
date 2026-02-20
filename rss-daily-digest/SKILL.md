---
name: rss-digest
description: |
  每日 AI 资讯摘要。从 254 个 RSS 源抓取最新内容，用 AI 生成中文摘要和智能推荐，
  输出 Markdown 归档文件，并将精选推荐发送到钉钉群。支持按分类筛选。
  触发词：/rss-digest、AI 日报、RSS 摘要、今日 AI 资讯、播客订阅、技术博客
author: Claude Code
version: 1.0.0
date: 2026-02-08
tags: ["rss", "ai-news", "digest", "daily-briefing", "dingtalk"]
---

# RSS Daily AI Digest

每日 AI 资讯摘要 Skill：抓取 → 过滤 → AI 摘要 → 报告 → 通知。

## 触发条件

- `/rss-digest` 或 `/rss-digest full`（全量完整流程）
- `/rss-digest summary`（跳过抓取，只对已有数据生成摘要）
- "生成 AI 日报"、"今日 AI 资讯"、"RSS 摘要"
- **按分类**："播客订阅"、"技术博客摘要"、"GitHub 更新"、"AI 新闻" 等自然语言

当用户提到具体分类关键词时，自动识别并只抓取对应分类。

## 分类列表

| 分类 ID | 分类名 | 匹配关键词示例 |
|---------|--------|---------------|
| `ai-company-blogs` | AI 公司官方博客 | 公司博客、官方博客 |
| `ai-tools` | AI 工具/产品 | 工具、产品 |
| `ai-research` | AI 研究 / arXiv 每日精选 | 研究、arXiv、论文 |
| `ai-developers` | 知名 AI 个人开发者/研究者 | 开发者、研究者 |
| `news-media` | 新闻媒体 | 新闻、媒体 |
| `podcasts` | AI 从业者访谈 / 播客 | 播客、访谈、podcast |
| `youtube` | YouTube AI 频道 | YouTube、视频 |
| `github-releases` | GitHub 开源项目 Releases | GitHub、开源、releases |
| `tech-blogs` | 技术博客 / 开发者博客 | 技术博客、博客 |
| `ai-changelog` | AI 公司产品更新 / Changelog | 产品更新、changelog、版本更新 |

## 目录

```
~/Documents/pe/skills/rss-daily-digest/
```

## 工作流程

### Step 0: 识别分类（如果用户指定了）

如果用户说了具体分类（如"播客订阅"、"看看技术博客"、"GitHub 有什么更新"），
根据上方分类列表匹配对应的分类 ID，后续所有脚本都加 `--category <id>` 参数。
如果用户没指定分类或说"全部"，则不加参数（全量）。

### Step 1: 抓取 RSS 源

运行 TypeScript 脚本抓取 RSS 源（`CATEGORY_FLAG` 为空或 `--category <id>`）：

```bash
cd ~/Documents/pe/skills/rss-daily-digest
npx tsx scripts/parse-feeds.ts                    # 解析 rss-feeds.md → feeds.json（有缓存）
npx tsx scripts/fetch-feeds.ts CATEGORY_FLAG      # 并行抓取 → data/raw-items.json
npx tsx scripts/dedupe-filter.ts CATEGORY_FLAG    # 去重过滤 → data/filtered-items.json
```

运行完成后，检查输出并向用户报告抓取结果（成功/失败数、总条目数）。

### Step 2: AI 摘要生成

读取 `data/filtered-items.json`，为每个条目生成中文摘要。

**处理规则：**
1. 读取 filtered-items.json 中所有 items
2. 按 categoryName 分组
3. 对每个条目基于 title + description 生成 2-3 句中文摘要
4. 保留英文专有名词（如 Claude、GPT-4、Transformer）
5. 从所有条目中选出最多 10 条 Smart Recommendations（最有价值/影响力的内容）
6. 为 Smart Recommendations 写更详细的摘要（3-5 句）

**Smart Recommendations 评分体系：**

对每个条目按 4 个维度打分（1-5 分），加权计算总分，取 Top 10。

| 维度 | 权重 | 5 分 | 4 分 | 3 分 | 2 分 | 1 分 |
|------|------|------|------|------|------|------|
| **应用相关性** | 35% | 核心工具链更新（Claude Code, Codex, Cursor, Copilot, Windsurf） | 直接相关（LLM API 更新, AI Agent 框架, 图像模型） | 间接相关（部署工具, 向量数据库, 云服务） | 泛 AI 应用新闻 | 纯学术/一般科技新闻 |
| **信息源质量** | 25% | 官方博客/Changelog/创始人亲写 | GitHub Release/README | 独立开发者深度体验 | 独立媒体原创报道 | 营销号/二次转述 |
| **内容价值类型** | 25% | 新产品/功能首发、开源项目创新首发 | 模型更新/重大版本发布 | 深度技术实践/教程/最佳实践 | 行业趋势分析/融资新闻 | 二手总结/泛泛概述 |
| **可操作性** | 15% | 现在就能用/集成到项目 | 短期内可以尝试 | 值得收藏/关注后续 | 了解即可 | 与工作无直接关系 |

**计算公式：** 总分 = 应用相关性×0.35 + 信息源质量×0.25 + 内容价值类型×0.25 + 可操作性×0.15

**降权规则：**
- **衍生跟进类内容大幅降权**：当 A 公司发布了新模型/功能后，B/C/D 说"我们也支持了"属于衍生消息（如"Copilot 支持 Sonnet 4.6"、"SDK 新增 XX 模型支持"、"XX 平台已接入"），这类内容的「内容价值类型」最高 2 分。只有**原始发布方的首发公告**才算 5 分
- 同理，媒体对官方发布的转述/解读也属于衍生内容，不应占据 Top 10

**硬约束：**
- Top 10 中 arXiv 论文**最多 1 篇**（仅保留真正突破性的、能影响应用层的论文）
- 同一产品/公司的内容最多 2 条
- **衍生跟进内容不进 Top 10**（第三方适配/支持公告、媒体转述官方发布）

**用户画像（评分参考）：**
- 身份：AI 应用开发者 + 全栈 + 后端
- 核心工具：Claude Code（最常用）、Codex、Cursor、Copilot、Windsurf
- 关注领域：LLM API、AI 编程/生成工具、图像模型、AI Agent 创新、部署基础设施
- 信息偏好：一手信息 > 技术原理 > 二手媒体。优先关注能直接用的、有交互创新的内容

**分类 Top 榜单：**
- **播客 Top 5**：仅从 `podcasts` 分类中按总分排序取 Top 5
- **Blog Top 5**：从 `tech-blogs` + `ai-company-blogs` + `ai-developers` 分类中按总分排序取 Top 5
- 分类 Top 与全局 Top 10 可以重叠（同一条可以同时出现在两个榜单）

**输出格式：** 将结果写入 `data/summarized-items.json`

```json
{
  "summarizedAt": "ISO timestamp",
  "totalItems": 139,
  "smartPickCount": 10,
  "podcastTop5": [{ "title": "...", "smartPickRank": 1, "scores": {...}, ... }],
  "blogTop5": [{ "title": "...", "smartPickRank": 1, "scores": {...}, ... }],
  "items": [
    {
      "title": "原标题",
      "link": "原链接",
      "source": "来源名称",
      "categoryId": "分类ID",
      "categoryName": "分类名",
      "pubDate": "原始发布日期字符串（来自 filtered-items.json）",
      "summary": "中文摘要...",
      "isSmartPick": true,
      "smartPickRank": 1
    }
  ]
}
```

### Step 3: 生成报告

```bash
cd ~/Documents/pe/skills/rss-daily-digest
npx tsx scripts/format-report.ts
```

报告输出到：`~/Documents/pe/jixiaxuegong/ai-digest-archive/YYYY-MM-DD-ai-digest.md`

### Step 4: 钉钉通知（可选）

如果配置了钉钉 Webhook（环境变量 `DINGTALK_WEBHOOK_URL`），发送 Smart Recommendations：

```bash
cd ~/Documents/pe/skills/rss-daily-digest
npx tsx scripts/notify-dingtalk.ts
```

仅发送 Smart Recommendations 部分（≤10 条），不发送完整报告。

### Step 5: 完成

向用户展示：
1. 抓取统计（总源数、成功/失败、总条目）
2. Smart Recommendations 列表（标题 + 一句话摘要）
3. 报告文件路径
4. 钉钉发送状态（如果启用）

## 配置

配置文件: `config/settings.json`

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| fetch.concurrency | 25 | 并行抓取数 |
| fetch.timeoutMs | 15000 | 单个 feed 超时 |
| filter.timeWindowHours | 48 | 时间窗口 |
| output.maxSmartRecommendations | 10 | Smart Picks 数量 |
| output.archiveDir | ~/Documents/ai-digest-archive | 归档目录 |

Feed 来源: `rss-feeds.md` (由 `config/settings.json` 中 `feedsSource` 指定)

## 数据文件

| 文件 | 说明 |
|------|------|
| `data/raw-items.json` | 原始抓取结果 |
| `data/filtered-items.json` | 去重过滤后 |
| `data/summarized-items.json` | AI 摘要后 |
| `data/seen-guids.json` | 去重 GUID 持久存储 |
| `data/feed-health.json` | Feed 健康度追踪 |
| `data/latest-report.md` | 最新报告副本 |

## 自动化执行

### 定时任务（launchd）

每日 08:00 自动执行完整 pipeline：

```bash
# 安装
cp config/com.pe.rss-daily-digest.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.pe.rss-daily-digest.plist

# 查看状态
launchctl list | grep rss-daily-digest

# 手动触发
./scripts/run.sh pipeline

# 卸载
launchctl unload ~/Library/LaunchAgents/com.pe.rss-daily-digest.plist
```

### 命令行执行

```bash
./scripts/run.sh pipeline           # 完整 pipeline（用 Claude CLI 做摘要）
./scripts/run.sh summarize-claude   # 仅用 Claude CLI 做摘要+评分
./scripts/run.sh summarize          # 仅用 Anthropic API 做摘要（需要 ANTHROPIC_API_KEY）
```
