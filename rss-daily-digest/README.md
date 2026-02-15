# RSS Daily AI Digest

每日 AI 资讯摘要：从 254 个 RSS 源抓取 → AI 生成中文摘要 → Markdown 归档 → 钉钉推送。

## 快速开始

### 方式一：交互模式（推荐）

在 Claude Code 中输入：

```
/rss-digest
```

Claude 会自动执行抓取、过滤、生成 AI 摘要，输出 Markdown 报告。

### 方式二：命令行

```bash
cd ~/Documents/pe/skills/rss-daily-digest

# 单步执行
npm run parse     # 解析 rss-feeds.md → feeds.json
npm run fetch     # 抓取所有 RSS（~3分钟）
npm run filter    # 去重 + 48h 时间过滤 + 无日期条目过滤

# 或者用 run.sh
./scripts/run.sh fetch
./scripts/run.sh filter
./scripts/run.sh format    # 生成 Markdown（不含 AI 摘要）
```

### 方式三：全自动定时模式

需要两个环境变量：

```bash
export ANTHROPIC_API_KEY="sk-ant-..."        # Claude API 密钥
export DINGTALK_WEBHOOK_URL="https://oapi.dingtalk.com/robot/send?access_token=..."
export DINGTALK_SECRET="SEC..."              # 可选，钉钉签名密钥
```

手动测试全流程：

```bash
./scripts/run.sh pipeline
```

安装定时任务（每天 07:30 自动执行）：

```bash
# 先编辑 plist 填入环境变量
vim config/com.pe.rss-daily-digest.plist

# 安装
cp config/com.pe.rss-daily-digest.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.pe.rss-daily-digest.plist

# 查看状态
launchctl list | grep rss-daily-digest

# 卸载
launchctl unload ~/Library/LaunchAgents/com.pe.rss-daily-digest.plist
```

## 按分类筛选

支持 `--category` 参数，只抓取/过滤指定分类：

```bash
# 按分类 ID
npx tsx scripts/fetch-feeds.ts --category tech-blogs
npx tsx scripts/dedupe-filter.ts --category tech-blogs

# 按分类名模糊匹配（中文也行）
npx tsx scripts/fetch-feeds.ts --category "播客"
npx tsx scripts/fetch-feeds.ts --category "GitHub"
npx tsx scripts/fetch-feeds.ts --category "新闻"
```

当前 10 个分类：

| 分类 ID | 分类名 | Feed 数 |
|---------|--------|---------|
| `ai-company-blogs` | AI 公司官方博客 | 18 |
| `ai-tools` | AI 工具/产品 | 16 |
| `ai-research` | AI 研究 / arXiv 每日精选 | 9 |
| `ai-developers` | 知名 AI 个人开发者/研究者 | 15 |
| `news-media` | 新闻媒体 | 20 |
| `podcasts` | AI 从业者访谈 / 播客 | 16 |
| `youtube` | YouTube AI 频道 | 6 |
| `github-releases` | GitHub 开源项目 Releases | 49 |
| `tech-blogs` | 技术博客 / 开发者博客（Android Capacity 精选） | 88 |
| `ai-changelog` | AI 公司产品更新 / Changelog | 17 |

不传 `--category` 就是全量抓取。

## 输出

| 输出 | 位置 |
|------|------|
| Markdown 日报 | `~/Documents/ai-digest-archive/YYYY-MM-DD-ai-digest.md` |
| 钉钉消息 | 仅推送 Smart Recommendations（AI 精选 ≤10 条） |

报告中每条内容都带有发布日期（时间窗口为 48h，内容来自不同日期）。

## 配置

编辑 `config/settings.json`：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `fetch.concurrency` | 25 | 并行抓取数 |
| `fetch.timeoutMs` | 15000 | 单 feed 超时（ms） |
| `filter.timeWindowHours` | 48 | 只保留最近 N 小时内容 |
| `output.maxSmartRecommendations` | 10 | AI 精选条数 |
| `output.archiveDir` | `~/Documents/ai-digest-archive` | 报告归档目录 |

## 管理 RSS 源

RSS 源定义在：`~/Documents/pe/prompt/claude-code-docs-crawler/rss-feeds.md`

修改后重新解析：

```bash
npm run parse -- --force
```

## 过滤逻辑

1. RSS 协议不支持服务端过滤，每次全量拉取各 feed 最新条目（每个 feed 固定 10~50 条，总量恒定不会膨胀）
2. 丢弃无 `pubDate` 的条目（静态页面、坏 feed）
3. 48h 时间窗口过滤（可配置）
4. GUID 去重（持久化存储，30 天滚动清理）
5. 连续失败 7+ 次的 feed 自动跳过

## 数据文件

运行时数据在 `data/` 目录（已 gitignore）：

- `seen-guids.json` — 去重记录（30 天滚动清理）
- `feed-health.json` — Feed 健康度（连续失败 7+ 次自动跳过）
- `raw-items.json` / `filtered-items.json` / `summarized-items.json` — 中间数据
- `latest-report.md` — 最新报告副本
