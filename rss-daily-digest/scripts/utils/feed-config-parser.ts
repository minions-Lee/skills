/**
 * Parse rss-feeds.md Markdown tables into structured feed configuration.
 * Extracts feed URLs, names, and categories from the document's table format.
 */

import type { FeedCategory, FeedSource, FeedsConfig } from "./types.js"

// Section ID mapping from Chinese headings
const SECTION_MAP: Record<string, string> = {
  "一": "ai-company-blogs",
  "二": "ai-tools",
  "三": "ai-research",
  "四": "ai-developers",
  "五": "news-media",
  "六": "podcasts",
  "七": "youtube",
  "八": "github-releases",
  "九": "tech-blogs",
  "十": "ai-changelog",
}

// Sections to skip (meta-resources, tools, not actual feeds)
const SKIP_SECTIONS = ["十一", "十二"]

/**
 * Parse the rss-feeds.md file content into a FeedsConfig object.
 */
export function parseRssFeedsMd(content: string): FeedsConfig {
  const categories: FeedCategory[] = []
  const lines = content.split("\n")

  let currentCategory: FeedCategory | null = null
  let currentSubName = ""
  let feedCounter = 0

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!

    // Match top-level sections: ## 一、AI 公司官方博客
    const sectionMatch = line.match(/^## ([一二三四五六七八九十]+)、(.+)/)
    if (sectionMatch) {
      const numeral = sectionMatch[1]!
      const name = sectionMatch[2]!.trim()

      // Skip meta sections (tools, resources)
      if (SKIP_SECTIONS.includes(numeral)) {
        if (currentCategory && currentCategory.feeds.length > 0) {
          categories.push(currentCategory)
        }
        currentCategory = null
        continue
      }

      // Save previous category
      if (currentCategory && currentCategory.feeds.length > 0) {
        categories.push(currentCategory)
      }

      const id = SECTION_MAP[numeral] || `section-${numeral}`
      currentCategory = { id, name, feeds: [] }
      currentSubName = ""
      continue
    }

    // Match sub-sections: ### 编程助手
    const subMatch = line.match(/^### (.+)/)
    if (subMatch && currentCategory) {
      currentSubName = subMatch[1]!.trim()
      continue
    }

    // Skip if we're in a skipped section
    if (!currentCategory) continue

    // Skip header rows and separator rows of tables
    if (line.match(/^\|[\s-]+\|/) || line.match(/^\| #/)) continue

    // Skip "无官方 RSS" / "无 RSS" info tables
    if (line.includes("无官方 RSS") || line.includes("无 RSS")) {
      // Skip until next section or subsection
      continue
    }

    // Match table rows containing backtick-wrapped URLs (any column count)
    const feedMatch = line.match(/^\|\s*\d+\s*\|([^|]+)\|.*?`([^`]+)`/)
    if (feedMatch && currentCategory) {
      const rawName = feedMatch[1]!.trim()
      const url = feedMatch[2]!.trim()
      // Extract notes from last column if available
      const columns = line.split("|").filter(c => c.trim())
      const notes = columns.length > 3 ? columns[columns.length - 1]!.trim() : ""

      // Skip non-feed URLs (website URLs, blog URLs without /rss, /feed, /atom)
      if (!isFeedUrl(url)) continue

      const name = cleanName(rawName)
      const status = detectStatus(notes)

      feedCounter++
      currentCategory.feeds.push({
        id: `feed-${feedCounter}`,
        name: currentSubName ? `${currentSubName} - ${name}` : name,
        url,
        status,
        enabled: status !== "broken",
      })
    }
  }

  // Save last category
  if (currentCategory && currentCategory.feeds.length > 0) {
    categories.push(currentCategory)
  }

  return {
    generatedFrom: "rss-feeds.md",
    generatedAt: new Date().toISOString(),
    categories,
  }
}

function isFeedUrl(url: string): boolean {
  const lower = url.toLowerCase()
  return (
    lower.includes("/rss") ||
    lower.includes("/feed") ||
    lower.includes("/atom") ||
    lower.includes(".xml") ||
    lower.includes(".rss") ||
    lower.includes("format=rss") ||
    lower.includes("releases.atom") ||
    lower.includes("videos.xml") ||
    lower.includes("substack.com/feed") ||
    lower.includes("rsshub.app/") ||
    lower.includes("megaphone.fm/") ||
    lower.includes("fireside.fm/") ||
    lower.includes("captivate.fm/") ||
    lower.includes("transistor.fm/") ||
    lower.includes("libsyn.com/") ||
    lower.includes("anchor.fm/") ||
    lower.includes("flightcast.com/") ||
    lower.includes("buttondown.com/") ||
    lower.includes("beehiiv.com/feed") ||
    lower.includes("feeddd.org/") ||
    lower.includes("anyfeeder.com/") ||
    lower.includes("raw.githubusercontent.com/")
  )
}

function cleanName(name: string): string {
  // Remove Markdown links: [text](url) → text
  return name.replace(/\[([^\]]+)\]\([^)]+\)/g, "$1").replace(/[*_`]/g, "").trim()
}

function detectStatus(notes: string): FeedSource["status"] {
  const lower = notes.toLowerCase()
  if (lower.includes("已损坏") || lower.includes("broken") || lower.includes("已坏")) return "broken"
  if (lower.includes("rsshub") || lower.includes("第三方")) return "rsshub"
  if (lower.includes("社区") || lower.includes("community")) return "community"
  return "official"
}
