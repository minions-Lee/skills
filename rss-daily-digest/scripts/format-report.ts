/**
 * Format filtered/summarized items into a Markdown daily report.
 * Reads data/summarized-items.json (preferred) or data/filtered-items.json (fallback),
 * outputs an archived Markdown report file.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import type { FilteredOutput, SummarizedOutput, SummarizedItem, FeedItem, Settings } from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")
const DATA_DIR = resolve(SKILL_DIR, "data")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

function expandPath(p: string): string {
  if (p.startsWith("~/")) {
    return resolve(process.env.HOME || "/tmp", p.slice(2))
  }
  return p
}

function formatDate(d: Date): string {
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, "0")
  const dd = String(d.getDate()).padStart(2, "0")
  return `${yyyy}-${mm}-${dd}`
}

function escapeTableCell(s: string): string {
  return s.replace(/\|/g, "\\|").replace(/\n/g, " ").trim()
}

function formatPubDate(dateStr: string): string {
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr.slice(0, 10)
  const mm = String(d.getMonth() + 1).padStart(2, "0")
  const dd = String(d.getDate()).padStart(2, "0")
  const hh = String(d.getHours()).padStart(2, "0")
  const min = String(d.getMinutes()).padStart(2, "0")
  return `${mm}-${dd} ${hh}:${min}`
}

function truncate(s: string, max: number): string {
  if (s.length <= max) return s
  return s.slice(0, max - 3) + "..."
}

interface ReportData {
  date: string
  totalSources: number
  totalItems: number
  smartPicks: SummarizedItem[]
  podcastTop5?: SummarizedItem[]
  blogTop5?: SummarizedItem[]
  categorizedItems: Map<string, Array<SummarizedItem | FeedItem>>
  hasSummaries: boolean
}

function loadReportData(_settings: Settings): ReportData {
  const date = formatDate(new Date())
  const summarizedPath = resolve(DATA_DIR, "summarized-items.json")
  const filteredPath = resolve(DATA_DIR, "filtered-items.json")

  // Prefer summarized data (has AI summaries)
  if (existsSync(summarizedPath)) {
    const data: SummarizedOutput = JSON.parse(readFileSync(summarizedPath, "utf-8"))
    const smartPicks = data.items
      .filter(i => i.isSmartPick)
      .sort((a, b) => (a.smartPickRank ?? 999) - (b.smartPickRank ?? 999))

    const categorized = new Map<string, SummarizedItem[]>()
    for (const item of data.items) {
      const cat = item.categoryName
      if (!categorized.has(cat)) categorized.set(cat, [])
      categorized.get(cat)!.push(item)
    }

    return {
      date,
      totalSources: new Set(data.items.map(i => i.source)).size,
      totalItems: data.totalItems,
      smartPicks,
      podcastTop5: data.podcastTop5,
      blogTop5: data.blogTop5,
      categorizedItems: categorized as Map<string, Array<SummarizedItem | FeedItem>>,
      hasSummaries: true,
    }
  }

  // Fallback to filtered data (no summaries)
  if (!existsSync(filteredPath)) {
    console.error("No data found. Run fetch + filter first.")
    process.exit(1)
  }

  const data: FilteredOutput = JSON.parse(readFileSync(filteredPath, "utf-8"))
  const categorized = new Map<string, FeedItem[]>()
  for (const item of data.items) {
    const cat = item.categoryName
    if (!categorized.has(cat)) categorized.set(cat, [])
    categorized.get(cat)!.push(item)
  }

  return {
    date,
    totalSources: new Set(data.items.map(i => i.feedName)).size,
    totalItems: data.items.length,
    smartPicks: [],
    categorizedItems: categorized as Map<string, Array<SummarizedItem | FeedItem>>,
    hasSummaries: false,
  }
}

function generateReport(data: ReportData): string {
  const lines: string[] = []

  // Frontmatter
  lines.push("---")
  lines.push(`title: "AI 日报 | ${data.date}"`)
  lines.push(`date: ${data.date}`)
  lines.push(`total_sources: ${data.totalSources}`)
  lines.push(`total_items: ${data.totalItems}`)
  lines.push(`smart_picks: ${data.smartPicks.length}`)
  lines.push(`has_summaries: ${data.hasSummaries}`)
  lines.push(`generated_at: ${new Date().toISOString()}`)
  lines.push("---")
  lines.push("")

  // Header
  lines.push(`# AI 日报 | ${data.date}`)
  lines.push("")
  lines.push(`> ${data.totalSources} 个来源 | ${data.totalItems} 条新内容 | ${data.smartPicks.length} 条 AI 精选`)
  lines.push("")

  // Smart Recommendations
  if (data.smartPicks.length > 0) {
    lines.push("## Smart Recommendations")
    lines.push("")
    for (let i = 0; i < data.smartPicks.length; i++) {
      const item = data.smartPicks[i]!
      lines.push(`### ${i + 1}. ${item.title}`)
      lines.push("")
      lines.push(`**${item.source}** | ${item.categoryName}`)
      lines.push("")
      lines.push(item.summary)
      lines.push("")
      lines.push(`[阅读原文](${item.link})`)
      lines.push("")
    }
  }

  // Podcast Top 5
  if (data.podcastTop5 && data.podcastTop5.length > 0) {
    const podcastTop = data.podcastTop5
    lines.push("## 播客精选 Top 5")
    lines.push("")
    for (let i = 0; i < podcastTop.length; i++) {
      const item = podcastTop[i]!
      lines.push(`### ${i + 1}. ${item.title}`)
      lines.push("")
      lines.push(`**${item.source}** | ${item.categoryName}`)
      lines.push("")
      lines.push(item.summary)
      lines.push("")
      if (item.link) lines.push(`[阅读原文](${item.link})`)
      lines.push("")
    }
  }

  // Blog Top 5
  if (data.blogTop5 && data.blogTop5.length > 0) {
    const blogTop = data.blogTop5
    lines.push("## Blog 精选 Top 5")
    lines.push("")
    for (let i = 0; i < blogTop.length; i++) {
      const item = blogTop[i]!
      lines.push(`### ${i + 1}. ${item.title}`)
      lines.push("")
      lines.push(`**${item.source}** | ${item.categoryName}`)
      lines.push("")
      lines.push(item.summary)
      lines.push("")
      if (item.link) lines.push(`[阅读原文](${item.link})`)
      lines.push("")
    }
  }

  // Category sections
  let sectionNum = 0
  for (const [catName, items] of data.categorizedItems) {
    sectionNum++
    lines.push(`## ${sectionNum}. ${catName}`)
    lines.push("")
    lines.push(`> ${items.length} 条`)
    lines.push("")

    if (data.hasSummaries) {
      // Table with summaries + date
      lines.push("| 标题 | 来源 | 日期 | 摘要 |")
      lines.push("|------|------|------|------|")
      for (const item of items) {
        const si = item as SummarizedItem
        const title = escapeTableCell(truncate(si.title, 50))
        const source = escapeTableCell(si.source)
        const date = si.pubDate ? formatPubDate(si.pubDate) : ""
        const summary = escapeTableCell(truncate(si.summary, 80))
        lines.push(`| [${title}](${si.link}) | ${source} | ${date} | ${summary} |`)
      }
    } else {
      // Table without summaries
      lines.push("| 标题 | 来源 | 发布时间 |")
      lines.push("|------|------|----------|")
      for (const item of items) {
        const fi = item as FeedItem
        const title = escapeTableCell(truncate(fi.title, 50))
        const source = escapeTableCell(fi.feedName)
        const pubDate = fi.pubDate ? formatPubDate(fi.pubDate) : ""
        lines.push(`| [${title}](${fi.link}) | ${source} | ${pubDate} |`)
      }
    }
    lines.push("")
  }

  // Footer
  lines.push("---")
  lines.push("")
  lines.push(`*Generated at ${new Date().toISOString()} by [RSS Daily AI Digest](https://github.com)*`)

  return lines.join("\n")
}

function main() {
  const settings = loadSettings()
  const data = loadReportData(settings)
  const report = generateReport(data)

  // Write to archive directory
  const archiveDir = expandPath(settings.output.archiveDir)
  mkdirSync(archiveDir, { recursive: true })

  const filename = settings.output.filenamePattern.replace("YYYY-MM-DD", data.date)
  let outputPath = resolve(archiveDir, filename)

  // If main digest for today already exists and not forcing → use timestamp suffix
  const force = process.argv.includes("--force")
  if (!force && existsSync(outputPath)) {
    const hhmm = new Date().toTimeString().slice(0, 5).replace(":", "")
    const base = filename.replace("-ai-digest.md", "")
    const updateFilename = `${base}-${hhmm}-update.md`
    outputPath = resolve(archiveDir, updateFilename)
    console.log(`Today's digest already exists. Writing incremental update: ${updateFilename}`)
  }

  writeFileSync(outputPath, report, "utf-8")
  console.log(`Report written: ${outputPath}`)
  console.log(`Total items: ${data.totalItems}`)
  console.log(`Smart picks: ${data.smartPicks.length}`)
  console.log(`Categories: ${data.categorizedItems.size}`)
  console.log(`Has summaries: ${data.hasSummaries}`)

  // Also write to data/ for SKILL.md workflow to pick up
  writeFileSync(resolve(DATA_DIR, "latest-report.md"), report, "utf-8")
}

main()
