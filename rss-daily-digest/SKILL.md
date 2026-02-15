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

**Smart Recommendations 选择标准：**
- 重大产品发布或更新（如新模型、重大功能）
- 有影响力的研究成果
- 行业趋势和深度分析
- AI 从业者深度访谈
- 重要的开源项目发布

**输出格式：** 将结果写入 `data/summarized-items.json`

```json
{
  "summarizedAt": "ISO timestamp",
  "totalItems": 139,
  "smartPickCount": 10,
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

报告输出到：`~/Documents/ai-digest-archive/YYYY-MM-DD-ai-digest.md`

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
