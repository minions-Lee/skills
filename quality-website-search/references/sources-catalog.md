# 搜索来源技术目录

每个来源的 API 端点、参数、响应字段和调用示例。

---

## 一、核心来源（Tier 1）

### 1. Hacker News — Algolia Search API

- **基础 URL**：`https://hn.algolia.com/api/v1`
- **认证**：无需认证，免费无限制
- **文档**：https://hn.algolia.com/api

#### 端点

| 端点 | 排序方式 |
|------|---------|
| `GET /search?query={q}` | 按相关性排序 |
| `GET /search_by_date?query={q}` | 按时间排序 |
| `GET /items/{id}` | 获取单条详情 |

#### 常用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `query` | 搜索关键词 | `AI coding tools` |
| `tags` | 内容类型过滤 | `story`, `comment`, `ask_hn`, `show_hn`, `job` |
| `hitsPerPage` | 每页结果数（默认 20） | `10` |
| `page` | 页码（从 0 开始） | `0` |
| `numericFilters` | 数值过滤 | `points>100`, `created_at_i>1700000000` |

#### curl 示例

```bash
# 搜索 AI coding tools 相关的高赞 story
curl -s "https://hn.algolia.com/api/v1/search?query=AI+coding+tools&tags=story&hitsPerPage=10"

# 搜索最近 30 天的内容（numericFilters 用 Unix 时间戳）
curl -s "https://hn.algolia.com/api/v1/search_by_date?query=AI+tools&tags=story&hitsPerPage=10&numericFilters=created_at_i>$(date -v-30d +%s)"
```

#### 响应字段（hits 数组）

| 字段 | 说明 |
|------|------|
| `title` | 标题 |
| `url` | 原文链接（可能为 null） |
| `points` | 赞数 |
| `num_comments` | 评论数 |
| `objectID` | HN ID，用于构建链接：`https://news.ycombinator.com/item?id={objectID}` |
| `created_at` | ISO 时间 |
| `author` | 作者 |

---

### 2. GitHub Search API

- **基础 URL**：`https://api.github.com`
- **认证**：可选。无认证 60 次/小时，设置 `GITHUB_TOKEN` 后 5000 次/小时
- **文档**：https://docs.github.com/en/rest/search

#### 端点

| 端点 | 用途 |
|------|------|
| `GET /search/repositories?q={q}` | 搜索仓库 |
| `GET /repos/{owner}/{repo}/readme` | 获取 README |

#### Awesome Lists 搜索策略

```bash
# 搜索 awesome 仓库，按 stars 排序
curl -s "https://api.github.com/search/repositories?q=awesome+AI+coding&sort=stars&per_page=5"

# 带认证（提高限额）
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/search/repositories?q=awesome+react&sort=stars&per_page=5"
```

#### 响应字段（items 数组）

| 字段 | 说明 |
|------|------|
| `full_name` | 仓库全名 (owner/repo) |
| `description` | 描述 |
| `stargazers_count` | Star 数 |
| `html_url` | 仓库链接 |
| `updated_at` | 最近更新时间 |
| `topics` | 标签数组 |

#### 获取 Awesome List 中的资源

找到 Awesome List 后，用 WebFetch 读取其 README：

```
WebFetch URL: "https://raw.githubusercontent.com/{owner}/{repo}/main/README.md"
提示: "提取这个 awesome list 中最相关的 10 个资源，返回名称、URL 和描述"
```

---

### 3. WebSearch（Claude 内置）

直接使用 Claude 的 WebSearch 工具，无需额外配置。

#### 查询优化模板

| 场景 | 查询模板 |
|------|---------|
| 通用英文 | `"best {keyword} tools sites 2026"` |
| 通用中文 | `"{keyword} 优质网站 推荐 2026"` |
| 替代方案 | `"best {keyword} alternatives 2026"` |
| 开源项目 | `"open source {keyword} 2026"` |

---

### 4. X/Twitter 搜索

#### 方式 A：WebSearch site 限定
```
WebSearch: "site:x.com {keyword} best tools recommended"
```

#### 方式 B：已安装 twitter skill
如果用户已安装 `resciencelab/opc-skills@twitter`（413 安装），优先调用该 skill 进行搜索。

#### 方式 C：已安装 x-research skill
如果已安装 `rohunvora/x-research-skill@x-research`（44 安装），用于深度 X 平台研究。

---

### 5. Reddit JSON API

- **基础 URL**：`https://www.reddit.com`
- **认证**：无需认证，**但必须设置 User-Agent 请求头**（否则 403）
- **文档**：https://www.reddit.com/dev/api/
- **限流**：未认证约 10 次/分钟；使用 OAuth2 token 后 60 次/分钟
- **测试状态**：✅ 2026-02-18 实测可用

#### 端点

| 端点 | 用途 |
|------|------|
| `GET /search.json?q={q}` | 全站搜索 |
| `GET /r/{subreddit}/search.json?q={q}&restrict_sr=on` | 子版内搜索 |
| `GET /r/{subreddit}/top.json?t=year` | 子版年度热帖 |

#### 常用参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `q` | 搜索关键词 | `AI coding tools best` |
| `sort` | 排序方式 | `relevance`, `hot`, `top`, `new`, `comments` |
| `t` | 时间范围 | `hour`, `day`, `week`, `month`, `year`, `all` |
| `limit` | 结果数量（最大 100） | `10` |
| `restrict_sr` | 是否限制在当前子版 | `on` / `off` |

#### curl 示例

```bash
# 全站搜索（必须带 User-Agent）
curl -s -H "User-Agent: Claude-Code/1.0" \
  "https://www.reddit.com/search.json?q=best+AI+tools&sort=relevance&t=year&limit=10"

# 子版搜索（更精准）
curl -s -H "User-Agent: Claude-Code/1.0" \
  "https://www.reddit.com/r/webdev/search.json?q=best+tools&restrict_sr=on&sort=top&t=year&limit=10"
```

#### 响应字段（data.children[].data）

| 字段 | 说明 |
|------|------|
| `title` | 帖子标题 |
| `score` | 赞数（upvotes - downvotes） |
| `subreddit` | 所在子版 |
| `permalink` | 帖子路径（需拼接 `https://www.reddit.com` 前缀） |
| `url` | 帖子中的外链（可能指向推荐网站） |
| `num_comments` | 评论数 |
| `selftext` | 帖子正文（自发帖时有值） |
| `created_utc` | 创建时间（UTC Unix 时间戳） |

#### 推荐子版对照表

| 搜索分类 | 推荐子版 |
|---------|---------|
| AI 工具 | r/artificial, r/ChatGPT, r/LocalLLaMA, r/MachineLearning |
| 开发资源 | r/webdev, r/programming, r/learnprogramming, r/javascript |
| 设计资源 | r/UI_Design, r/userexperience, r/web_design, r/graphic_design |
| 创业产品 | r/SaaS, r/startups, r/Entrepreneur, r/indiehackers |
| 替代方案 | r/selfhosted, r/degoogle, r/opensource, r/privacytoolsIO |
| 中文社区 | r/China_irl, r/real_China_irl |

#### OAuth2 认证（可选，提高限额）

如需更高限额（60 次/分钟），可使用 Reddit OAuth2：

1. 访问 https://www.reddit.com/prefs/apps 创建应用（选 "script" 类型）
2. 获取 `client_id` 和 `client_secret`
3. 获取 access token：

```bash
curl -s -X POST -d "grant_type=client_credentials" \
  -u "CLIENT_ID:CLIENT_SECRET" \
  -H "User-Agent: Claude-Code/1.0" \
  "https://www.reddit.com/api/v1/access_token"
```

4. 使用 token 搜索：

```bash
curl -s -H "Authorization: Bearer ACCESS_TOKEN" \
  -H "User-Agent: Claude-Code/1.0" \
  "https://oauth.reddit.com/search?q=keyword&limit=10"
```

---

## 二、扩展来源（Tier 2）

### 5. Product Hunt

- **URL**：`https://www.producthunt.com/search?q={keyword}`
- **方式**：WebFetch 抓取搜索结果页
- **官方 API**：GraphQL at `api.producthunt.com/v2/api/graphql`（需 OAuth token）
- **提取字段**：产品名、tagline、投票数、链接

```
WebFetch URL: "https://www.producthunt.com/search?q={keyword}"
提示: "提取搜索结果中的产品信息：名称、简介(tagline)、投票数、链接。返回前 10 个结果，格式为表格。"
```

---

### 6. AlternativeTo

- **URL**：`https://www.alternativeto.net/browse/search?q={keyword}`
- **方式**：WebFetch 抓取
- **适用场景**：用户问"有什么 XX 的替代品/类似 XX 的工具"
- **提取字段**：软件名、描述、点赞数、支持平台

```
WebFetch URL: "https://www.alternativeto.net/browse/search?q={keyword}"
提示: "提取搜索结果中的软件信息：名称、描述、点赞数、支持的平台列表。返回前 10 个。"
```

---

### 7. Toolify（AI 工具目录）

- **URL**：`https://www.toolify.ai/search/{keyword}`
- **方式**：WebFetch 抓取
- **覆盖**：5000+ AI 工具
- **提取字段**：工具名、分类、描述、定价

```
WebFetch URL: "https://www.toolify.ai/search/{keyword}"
提示: "提取 AI 工具列表：名称、分类、描述、定价(免费/付费)、链接。返回前 10 个。"
```

---

### 8. 飞搜侠 (feisoo.com)

- **URL**：`https://www.feisoo.com/`
- **方式**：WebFetch 抓取
- **内容**：飞书公开文档搜索引擎
- **分类**：软件教程、设计素材、AI 工具、个人成长等
- **语言**：中文

```
WebFetch URL: "https://www.feisoo.com/"
提示: "这是一个飞书文档搜索引擎。找到搜索框或搜索功能，描述如何搜索 {keyword} 相关内容。
如果页面有搜索结果或热门分类，提取相关资源列表。"
```

注意：feisoo.com 可能需要通过其搜索表单提交查询，WebFetch 可能只能获取首页。
降级方案：`WebSearch "site:feisoo.com {keyword}"`

---

### 9. CloudDocs (cloudocs.top)

- **URL**：`https://www.cloudocs.top/discover`
- **方式**：WebFetch 抓取
- **内容**：多平台云文档搜索（飞书、Notion、语雀、FlowUS）
- **语言**：中文
- **状态**：可能不稳定（2026-02 测试时 SSL 连接失败）

```
WebFetch URL: "https://www.cloudocs.top/discover"
提示: "提取发现页面中的资源分类和热门文档列表。如果有搜索功能，描述如何搜索 {keyword}。"
```

降级方案：`WebSearch "site:cloudocs.top {keyword}"` 或直接跳过。

---

### 10. 创造者日报 (creatorsdaily.com)

- **URL**：`https://creatorsdaily.com`
- **方式**：WebFetch 抓取
- **内容**：中文创客社区，产品分享和发现
- **特点**：开源项目（GitHub），社区驱动
- **语言**：中文

```
WebFetch URL: "https://creatorsdaily.com"
提示: "提取首页展示的创客作品和产品，包括名称、描述、链接。返回与 {keyword} 相关的内容。"
```

---

### 11. Public APIs (publicapis.io)

- **URL**：`https://publicapis.io/`
- **方式**：WebFetch 抓取
- **内容**：免费公开 API 目录
- **适用**：用户搜索可用 API 或开发资源

```
WebFetch URL: "https://publicapis.io/"
提示: "提取与 {keyword} 相关的公开 API 列表，包括 API 名称、描述、认证方式(apiKey/OAuth/无)、链接。"
```

---

### 12. DevHunt (devhunt.org)

- **URL**：`https://devhunt.org`
- **方式**：WebFetch 抓取
- **内容**：开发者工具发现平台（类似 Product Hunt 但专注开发工具）

```
WebFetch URL: "https://devhunt.org"
提示: "提取与 {keyword} 相关的开发者工具，包括名称、描述、投票数、链接。"
```

---

### 13. Dribbble（设计资源）

- **URL**：`https://dribbble.com/search/{keyword}`
- **方式**：WebFetch 抓取
- **内容**：设计作品展示，UI/UX 灵感
- **官方 API**：有（需注册应用）

```
WebFetch URL: "https://dribbble.com/search/{keyword}"
提示: "提取与 {keyword} 相关的设计作品和资源，包括标题、设计师、链接。"
```

---

### 14. BetaList

- **URL**：`https://betalist.com/search?q={keyword}`
- **方式**：WebFetch 抓取
- **内容**：预发布创业产品，early access

```
WebFetch URL: "https://betalist.com/search?q={keyword}"
提示: "提取搜索结果中的产品信息：名称、描述、状态(beta/launching)、链接。"
```

---

## 三、可选增强来源（Tier 3）

### 15. Raindrop.io

- **API 文档**：https://developer.raindrop.io
- **认证**：需要 API Token（在 https://app.raindrop.io/settings/integrations 创建）
- **Python 包**：`python-raindropio`
- **skill**：`intellectronica/agent-skills@raindrop-api`（64 安装）

```bash
# 安装 skill
npx skills add intellectronica/agent-skills@raindrop-api -g -y
```

API 能力：
- 搜索公共收藏集
- 按标签/分类浏览
- 获取热门书签

---

### 16. Firecrawl

- **skill**：`vm0-ai/vm0-skills@firecrawl`（27 安装）
- **用途**：当 WebFetch 无法获取某网站时，可用 Firecrawl 深度抓取

```bash
npx skills add vm0-ai/vm0-skills@firecrawl -g -y
```

---

### 17. Resource Scout

- **skill**：`nicepkg/ai-workflow@resource-scout`（72 安装）
- **用途**：资源探测，可作为搜索能力的扩展

```bash
npx skills add nicepkg/ai-workflow@resource-scout -g -y
```

---

### 18. Twitter / X Research Skills

| Skill | 安装量 | 安装命令 |
|-------|--------|---------|
| `resciencelab/opc-skills@twitter` | 413 | `npx skills add resciencelab/opc-skills@twitter -g -y` |
| `rohunvora/x-research-skill@x-research` | 44 | `npx skills add rohunvora/x-research-skill@x-research -g -y` |

---

## 四、来源可用性速查（2026-02-18 实测）

| # | 来源 | 免费 | 需认证 | API 类型 | 实测状态 | 备注 |
|---|------|------|--------|---------|---------|------|
| 1 | Hacker News | ✅ | ❌ | REST/JSON | ✅ 可用 | HTTP 200, ~1s |
| 2 | GitHub | ✅ (限流) | 可选 | REST/JSON | ✅ 可用 | HTTP 200, ~2s |
| 3 | WebSearch | ✅ | ❌ | 内置 | ✅ 可用 | 始终可用 |
| 4 | X/Twitter | ✅ | ❌ | WebSearch | ✅ 可用 | 通过 WebSearch 间接搜索 |
| 5 | **Reddit** | ✅ | ❌ | REST/JSON | ✅ 可用 | **必须设 User-Agent 头** |
| 6 | Product Hunt | ✅ | ❌ | WebFetch | ❌ 403 | 反爬阻止，降级 WebSearch |
| 7 | AlternativeTo | ✅ | ❌ | WebFetch | ❌ 403 | 严格反爬，降级 WebSearch |
| 8 | Toolify | ✅ | ❌ | WebFetch | ❌ 403 | 反爬阻止，降级 WebSearch |
| 9 | 飞搜侠 | ✅ | ❌ | WebFetch | ⚠️ 部分可用 | 首页可抓，搜索需表单提交 |
| 10 | CloudDocs | ✅ | ❌ | WebFetch | ⚠️ 部分可用 | 首页可抓，/discover 404 |
| 11 | 创造者日报 | ✅ | ❌ | WebFetch | ❌ 502 | 可能已关停 |
| 12 | Public APIs | ✅ | ❌ | WebFetch | ✅ 可用 | 正常返回 API 列表 |
| 13 | DevHunt | ✅ | ❌ | WebFetch | ⚠️ SPA | 客户端渲染，WebFetch 无数据 |
| 14 | Dribbble | ✅ | ❌ | WebFetch | ❌ 解析失败 | 页面过大，降级 WebSearch |
| 15 | BetaList | ✅ | ❌ | WebFetch | ✅ 可用 | 正常返回搜索结果 |
| 16 | Raindrop.io | ❌ | API Key | REST | 未测试 | 需 Skill + API Key |
| 17 | Firecrawl | ❌ | Skill | Skill | 未测试 | 需 Skill |
| 18 | Resource Scout | ❌ | Skill | Skill | 未测试 | 需 Skill |
| 19 | X Research | ❌ | Skill | Skill | 未测试 | 需 Skill |

### 不可用来源的 API 替代方案

| 来源 | 失败原因 | 有官方 API? | API 获取方式 |
|------|---------|-----------|------------|
| Product Hunt | WebFetch 403 反爬 | ✅ GraphQL API | 访问 https://www.producthunt.com/golden-kitty-awards → Settings → API Applications 创建应用获取 OAuth Token |
| AlternativeTo | WebFetch 403 严格反爬 | ❌ 无公开 API | 只能用 WebSearch 降级 |
| Toolify | WebFetch 403 反爬 | ❌ 无公开 API | 只能用 WebSearch 降级 |
| Dribbble | 页面过大解析失败 | ✅ REST API | 访问 https://developer.dribbble.com 注册应用获取 access token |
| DevHunt | SPA 客户端渲染 | ❌ 无公开 API | 只能用 WebSearch 降级 |
| 创造者日报 | 502 服务器错误 | ❌ 可能已关停 | 建议从来源列表中移除或降级 |
