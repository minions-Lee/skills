---
name: quality-website-search
description: |
  搜索优质网站和资源。聚合多来源（Hacker News、GitHub Awesome Lists、X/Twitter、
  Product Hunt、飞搜侠、CloudDocs、AI 工具目录等），帮助用户发现高质量网站、工具和资源。
  支持快速搜索、分类浏览和深度发现三种模式。
  触发词：搜索优质网站、找网站、找资源、找工具、推荐网站、好用的网站、
  AI 工具推荐、开发资源、设计资源、产品推荐、开源项目、中文资源、
  quality website、find tools、search resources、awesome list、
  有什么好用的、有没有替代品、alternative。
author: Claude Code
version: 1.0.0
date: 2026-02-18
tags: ["search", "discovery", "websites", "resources", "tools", "curation"]
---

# 优质网站/资源搜索

聚合多来源搜索，发现高质量网站、工具和资源。

## 报告输出

搜索完成后如果产生 Report 文件，**默认保存到** `/Users/eamanc/Documents/pe/jixiaxuegong/reports/` 目录下，文件命名格式：`{主题}-{YYYY-MM-DD}.md`。除非用户明确指定了其他存放地址。

## 触发条件

- "帮我找一下 XX 相关的网站/工具/资源"
- "有什么好用的 XX"、"推荐一些 XX 资源"
- "XX 的替代品"、"类似 XX 的工具"
- "搜索优质网站"、"find quality websites about XX"
- 用户提到具体分类（AI 工具、设计资源、开发工具等）

## 搜索来源

### Tier 1：核心来源（每次必搜，免费无认证）

| 来源 | 访问方式 | 内容类型 |
|------|---------|---------|
| **WebSearch** | Claude 内置工具 | 全网兜底搜索 |
| **Hacker News** | Algolia Search API（免费） | 技术/创业/前沿热门 |
| **GitHub Awesome Lists** | GitHub Search API（免费） | 全领域精选资源合集 |
| **X/Twitter** | WebSearch `site:x.com` | 社交媒体实时讨论热门 |
| **Reddit** | JSON API（免费，需 User-Agent） | 深度讨论/真实评价/推荐帖 |

### Tier 2：扩展来源（按分类触发）

| 来源 | 访问方式 | 适用分类 |
|------|---------|---------|
| **Product Hunt** | WebFetch | 创业产品/SaaS |
| **AlternativeTo** | WebFetch | 替代方案 |
| **Toolify** | WebFetch | AI 工具 |
| **飞搜侠 (feisoo.com)** | WebFetch | 中文/飞书文档资源 |
| **CloudDocs (cloudocs.top)** | WebFetch | 中文/多平台云文档 |
| **创造者日报 (creatorsdaily.com)** | WebFetch | 中文创客社区 |
| **Public APIs (publicapis.io)** | WebFetch | API 发现 |
| **DevHunt (devhunt.org)** | WebFetch | 开发者工具 |
| **Dribbble** | WebFetch | 设计资源 |
| **BetaList** | WebFetch | 预发布创业产品 |

### Tier 3：可选增强（需已安装对应 skill 或 API Key）

| 来源 | 前提条件 | 内容类型 |
|------|---------|---------|
| **Raindrop.io** | `raindrop-api` skill + API Key | 社区书签精选 |
| **Firecrawl** | `firecrawl` skill | 深度网页抓取 |
| **Resource Scout** | `resource-scout` skill | 资源探测 |
| **X Research** | `x-research` skill | X 平台深度研究 |
| **Twitter Skill** | `twitter` skill (413 安装) | X/Twitter 内容搜索 |

安装 Tier 3 来源的命令：
```bash
npx skills add intellectronica/agent-skills@raindrop-api -g -y
npx skills add vm0-ai/vm0-skills@firecrawl -g -y
npx skills add nicepkg/ai-workflow@resource-scout -g -y
npx skills add rohunvora/x-research-skill@x-research -g -y
npx skills add resciencelab/opc-skills@twitter -g -y
```

## 搜索分类

| 分类 | 匹配关键词 | 核心来源 | 扩展来源 |
|------|-----------|---------|---------|
| AI 工具 | AI、LLM、GPT、人工智能、机器学习 | HN + GitHub + X | Toolify, Product Hunt |
| 开发资源 | 开发、编程、框架、库、代码 | HN + GitHub | DevHunt, Public APIs |
| 设计资源 | UI、UX、设计、Figma、图标 | GitHub + WebSearch + Reddit | Dribbble |
| 创业产品 | 创业、SaaS、indie、产品、startup | HN + X + Reddit | Product Hunt, BetaList |
| 中文资源 | 中文、飞书、国内、知识库 | WebSearch | 飞搜侠, CloudDocs |
| 替代方案 | 替代、alternative、类似、像XX | HN + WebSearch + Reddit | AlternativeTo |
| API/接口 | API、接口、开放平台、SDK | GitHub + WebSearch | Public APIs |

## 三种搜索模式

### 模式一：快速搜索（默认）

关键词 → Tier 1 并行搜索 → 聚合去重 → Top 10 结果

### 模式二：分类浏览

用户选择分类 → Tier 1 + 该分类 Tier 2 → 分类展示

### 模式三：深度发现

用户明确要求"全面搜索"/"深度搜索" → 所有 Tier 1+2（+3 如已安装）→ 聚合去重评分 → Top 20

## 工作流程

### Step 0: 解析用户意图

从用户输入中提取：
1. **关键词**：核心搜索词（中文+英文翻译版本）
2. **分类**：匹配上方分类表，可多选
3. **模式**：默认快速搜索；用户说"全面/深度"则切换深度模式
4. **语言偏好**：如果关键词全中文，优先中文来源

### Step 1: 核心搜索（并行执行 Tier 1）

**重要：以下四个搜索必须用并行 tool call 同时发出。**

#### 1.1 WebSearch

```
WebSearch: "best {KEYWORD_EN} tools sites resources 2026"
```

如果用户偏好中文，额外搜：
```
WebSearch: "{KEYWORD_CN} 优质网站 推荐 2026"
```

#### 1.2 Hacker News（Algolia API）

```bash
curl -s "https://hn.algolia.com/api/v1/search?query=KEYWORD_EN&tags=story&hitsPerPage=10"
```

从 JSON 响应中提取：
- `hits[].title` — 标题
- `hits[].url` — 链接
- `hits[].points` — 赞数
- `hits[].num_comments` — 评论数
- `hits[].objectID` — 用于构建 HN 链接：`https://news.ycombinator.com/item?id={objectID}`

#### 1.3 GitHub Awesome Lists

```bash
curl -s "https://api.github.com/search/repositories?q=awesome+KEYWORD_EN&sort=stars&per_page=5"
```

从 JSON 响应中提取：
- `items[].full_name` — 仓库名
- `items[].description` — 描述
- `items[].stargazers_count` — Star 数
- `items[].html_url` — 仓库链接

对 Top 1-2 个 Awesome List，用 WebFetch 读取其 README 提取实际资源链接：
```
WebFetch: "https://raw.githubusercontent.com/{owner}/{repo}/main/README.md"
提示: "提取这个 awesome list 中与 {KEYWORD} 最相关的 10 个资源，返回名称、URL和一句话描述"
```

#### 1.4 X/Twitter 搜索

```
WebSearch: "site:x.com {KEYWORD_EN} best tools recommended"
```

如果已安装 `twitter` skill，优先使用该 skill 搜索。

#### 1.5 Reddit 搜索

```bash
curl -s -H "User-Agent: Claude-Code/1.0" "https://www.reddit.com/search.json?q=KEYWORD_EN+best+recommended&sort=relevance&t=year&limit=10"
```

从 JSON 响应中提取：
- `data.children[].data.title` — 帖子标题
- `data.children[].data.score` — 赞数
- `data.children[].data.subreddit` — 子版名称
- `data.children[].data.permalink` — 帖子路径（拼接 `https://www.reddit.com` 前缀）
- `data.children[].data.num_comments` — 评论数
- `data.children[].data.url` — 帖子中的外链（可能指向推荐的网站）

**重要**：必须设置 `User-Agent` 请求头，否则返回 403。

也可搜索特定子版获取更精准结果：
```bash
curl -s -H "User-Agent: Claude-Code/1.0" "https://www.reddit.com/r/{subreddit}/search.json?q=KEYWORD&restrict_sr=on&sort=top&t=year&limit=10"
```

常用子版对照表：

| 分类 | 推荐子版 |
|------|---------|
| AI 工具 | r/artificial, r/ChatGPT, r/LocalLLaMA |
| 开发资源 | r/webdev, r/programming, r/learnprogramming |
| 设计资源 | r/UI_Design, r/userexperience, r/web_design |
| 创业产品 | r/SaaS, r/startups, r/Entrepreneur |
| 替代方案 | r/selfhosted, r/degoogle, r/opensource |

### Step 2: 扩展搜索（按分类触发 Tier 2）

根据 Step 0 匹配的分类，选择对应的扩展来源。用 WebFetch 抓取：

#### Product Hunt（创业产品分类）
```
WebFetch URL: "https://www.producthunt.com/search?q=KEYWORD"
提示: "提取搜索结果中的产品名称、简介、投票数和链接，返回前 10 个"
```

#### AlternativeTo（替代方案分类）
```
WebFetch URL: "https://www.alternativeto.net/browse/search?q=KEYWORD"
提示: "提取搜索结果中的软件名称、描述、点赞数和支持平台，返回前 10 个"
```

#### Toolify（AI 工具分类）
```
WebFetch URL: "https://www.toolify.ai/search/KEYWORD"
提示: "提取 AI 工具名称、分类、描述和定价信息，返回前 10 个"
```

#### 飞搜侠（中文资源分类）
```
WebFetch URL: "https://www.feisoo.com/"
提示: "在这个飞书文档搜索引擎页面中，找到搜索功能，描述如何搜索 {KEYWORD} 相关的内容"
```

#### CloudDocs（中文资源分类）
```
WebFetch URL: "https://www.cloudocs.top/discover"
提示: "提取发现页面中与 {KEYWORD} 相关的云文档资源，包括标题、平台和链接"
```

注意：CloudDocs 可能不稳定，失败时跳过。

#### 创造者日报（中文资源分类）
```
WebFetch URL: "https://creatorsdaily.com"
提示: "提取首页或搜索结果中与 {KEYWORD} 相关的创客作品和资源"
```

#### Public APIs（API 分类）
```
WebFetch URL: "https://publicapis.io/"
提示: "提取与 {KEYWORD} 相关的公开 API，包括名称、描述、认证方式和链接"
```

#### DevHunt（开发工具分类）
```
WebFetch URL: "https://devhunt.org"
提示: "提取与 {KEYWORD} 相关的开发者工具，包括名称、描述和链接"
```

### Step 3: 聚合去重 + 质量评分

1. **去重**：按 domain/URL 去重，同一网站保留评分最高的条目
2. **质量评分**（满分 15 分）：

| 信号 | 分值 |
|------|------|
| HN 高赞 (>100 points) | +3 |
| GitHub 高星 (>1000 stars) | +3 |
| Reddit 高赞 (>100 score) | +3 |
| X 高讨论度 | +2 |
| 多来源重复出现 | +2/来源 |
| 有详细描述 | +1 |
| 最近更新 (<6个月) | +1 |

3. **排序**：按评分降序

### Step 4: 结果展示

使用以下模板输出：

```markdown
## 搜索结果：「{KEYWORD}」

共找到 {N} 个优质资源，来自 {M} 个来源。

### 精选推荐 (Top 5)

| # | 名称 | 简介 | 来源 | 热度 |
|---|------|------|------|------|
| 1 | [Name](URL) | 一句话简介 | HN 238↑ | ★★★ |
| 2 | [Name](URL) | 一句话简介 | GH 5.2k⭐ | ★★★ |
| 3 | [Name](URL) | 一句话简介 | PH 150↑ | ★★☆ |

### 完整列表

#### 来自 Hacker News
| 名称 | 简介 | 赞数 | 评论 |
|------|------|------|------|

#### 来自 GitHub Awesome Lists
| 仓库 | 描述 | Stars |
|------|------|-------|

#### 来自 X/Twitter
| 链接 | 内容摘要 | 互动 |
|------|---------|------|

#### 来自 {其他来源}
...

### 相关 Awesome Lists
- [awesome-xxx](github-url) - ⭐ {stars} - {description}
```

### Step 5: 用户交互

用 AskUserQuestion 询问用户：

| 选项 | 说明 |
|------|------|
| 深入了解某个结果 | WebFetch 该网站详情页 |
| 搜索更多来源 | 触发 Tier 2 / Tier 3 扩展搜索 |
| 换个关键词 | 重新执行 Step 0-4 |
| 搜索完毕 | 结束 |

## 降级策略

当某个来源请求失败时：

| 失败来源 | 降级方案 |
|---------|---------|
| HN Algolia API | WebSearch `site:news.ycombinator.com {keyword}` |
| GitHub API（限流） | WebSearch `site:github.com awesome {keyword}` |
| Reddit API（403） | 检查是否设置 User-Agent 头；降级为 WebSearch `site:reddit.com {keyword}` |
| WebFetch 被反爬 | WebSearch `site:{domain} {keyword}` |
| Product Hunt（403） | WebSearch `site:producthunt.com {keyword}` |
| AlternativeTo（403） | WebSearch `site:alternativeto.net {keyword}` |
| Toolify（403） | WebSearch `site:toolify.ai {keyword}` |
| Dribbble（页面过大） | WebSearch `site:dribbble.com {keyword}` |
| DevHunt（SPA 渲染） | WebSearch `site:devhunt.org {keyword}` |
| 创造者日报（502/关停） | WebSearch `site:creatorsdaily.com {keyword}`，可能无结果 |
| CloudDocs 宕机 | 跳过，不影响其他来源 |
| Tier 3 skill 未安装 | 跳过，提示用户可安装 |

**原则：任何单一来源失败不应中断整个搜索流程。**

## 注意事项

- GitHub API 未认证：60 次/小时；设置 `GITHUB_TOKEN` 环境变量后 5000 次/小时
- HN Algolia API：免费无限制
- Reddit JSON API：免费，**必须设置 User-Agent 请求头**（任意非空值即可），否则返回 403
- WebFetch 对部分站点被反爬阻止（Product Hunt、AlternativeTo、Toolify、Dribbble），自动降级为 WebSearch `site:` 搜索
- DevHunt 为 SPA 客户端渲染，WebFetch 无法获取动态数据，降级为 WebSearch
- 中文来源（飞搜侠、CloudDocs）可能不稳定，失败时静默跳过
- 创造者日报可能已关停（502 错误），降级为 WebSearch 或直接跳过
- 搜索中英文关键词都要覆盖，确保不遗漏

## 示例

### 示例 1：快速搜索 AI 编程工具

**用户**："帮我找一些 AI 编程工具"

**解析**：关键词="AI coding tools"，分类=AI工具+开发资源，模式=快速搜索

**执行**：
1. WebSearch "best AI coding tools 2026"
2. curl HN Algolia "AI coding assistant"
3. curl GitHub "awesome AI coding"
4. WebSearch "site:x.com AI coding tools best"
5. curl Reddit search "AI coding tools best"
6. WebSearch "site:toolify.ai AI coding"（Toolify WebFetch 403，降级）
7. WebSearch "site:producthunt.com AI coding"（Product Hunt WebFetch 403，降级）

### 示例 2：寻找替代方案

**用户**："有什么 Notion 的替代品"

**解析**：关键词="Notion"，分类=替代方案，模式=快速搜索

**执行**：
1. 核心搜索 + AlternativeTo "Notion"
2. 结果展示时突出替代品的对比信息

### 示例 3：中文资源搜索

**用户**："有什么好的中文 AI 学习资源"

**解析**：关键词="AI 学习"，分类=中文资源+AI工具，模式=快速搜索

**执行**：
1. WebSearch "AI 学习资源 中文 推荐 2026"
2. HN + GitHub 搜索 "learn AI chinese"
3. WebFetch 飞搜侠 搜索 "AI 学习"
4. WebFetch CloudDocs 搜索 "AI 学习"
5. WebFetch 创造者日报
