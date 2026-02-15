/**
 * Parallel RSS feed fetcher.
 * Reads config/feeds.json, fetches all enabled feeds concurrently,
 * outputs data/raw-items.json.
 */

import { readFileSync, writeFileSync, existsSync, mkdirSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { fetchUrl, withConcurrency } from "./utils/http-client.js"
import { parseFeed } from "./utils/rss-parser.js"
import type {
  FeedsConfig, FeedSource, FeedItem, FeedFetchResult,
  RawFetchOutput, FeedHealthMap, Settings,
} from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")
const DATA_DIR = resolve(SKILL_DIR, "data")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

function loadFeedsConfig(): FeedsConfig {
  const path = resolve(CONFIG_DIR, "feeds.json")
  if (!existsSync(path)) {
    console.error("feeds.json not found. Run `npm run parse` first.")
    process.exit(1)
  }
  return JSON.parse(readFileSync(path, "utf-8"))
}

function loadHealthMap(): FeedHealthMap {
  const path = resolve(DATA_DIR, "feed-health.json")
  if (existsSync(path)) {
    return JSON.parse(readFileSync(path, "utf-8"))
  }
  return {}
}

function ensureDataDir() {
  mkdirSync(DATA_DIR, { recursive: true })
}

async function fetchSingleFeed(
  feed: FeedSource,
  categoryId: string,
  categoryName: string,
  settings: Settings,
): Promise<FeedFetchResult> {
  const start = Date.now()

  const result = await fetchUrl(feed.url, {
    timeoutMs: settings.fetch.timeoutMs,
    retries: settings.fetch.retries,
    retryDelayMs: settings.fetch.retryDelayMs,
  })

  if (!result.ok) {
    return {
      feedUrl: feed.url,
      feedName: feed.name,
      success: false,
      items: [],
      error: result.error,
      durationMs: Date.now() - start,
    }
  }

  try {
    const parsed = parseFeed(result.body)
    const items: FeedItem[] = parsed.map(item => ({
      title: item.title,
      link: item.link,
      description: item.description,
      pubDate: item.pubDate,
      guid: item.guid,
      feedName: feed.name,
      feedUrl: feed.url,
      categoryId,
      categoryName,
    }))

    return {
      feedUrl: feed.url,
      feedName: feed.name,
      success: true,
      items,
      durationMs: Date.now() - start,
    }
  } catch (err) {
    return {
      feedUrl: feed.url,
      feedName: feed.name,
      success: false,
      items: [],
      error: `Parse error: ${(err as Error).message}`,
      durationMs: Date.now() - start,
    }
  }
}

function parseCategoryFilter(): string | null {
  const idx = process.argv.indexOf("--category")
  if (idx === -1) return null
  return process.argv[idx + 1] || null
}

async function main() {
  ensureDataDir()
  const settings = loadSettings()
  const config = loadFeedsConfig()
  const healthMap = loadHealthMap()
  const categoryFilter = parseCategoryFilter()

  if (categoryFilter) {
    console.log(`Category filter: "${categoryFilter}"`)
  }

  // Collect all enabled feeds with their category info
  const feedTasks: Array<{
    feed: FeedSource
    categoryId: string
    categoryName: string
  }> = []

  for (const cat of config.categories) {
    // Filter by category if specified (match by id or partial name)
    if (categoryFilter) {
      const q = categoryFilter.toLowerCase()
      if (!cat.id.toLowerCase().includes(q) && !cat.name.toLowerCase().includes(q)) {
        continue
      }
    }

    for (const feed of cat.feeds) {
      if (!feed.enabled) continue

      // Skip feeds with 7+ consecutive failures
      const health = healthMap[feed.url]
      if (health && health.consecutiveFailures >= 7) {
        console.log(`Skipping (7+ failures): ${feed.name}`)
        continue
      }

      feedTasks.push({
        feed,
        categoryId: cat.id,
        categoryName: cat.name,
      })
    }
  }

  console.log(`Fetching ${feedTasks.length} feeds (concurrency: ${settings.fetch.concurrency})...`)
  const start = Date.now()

  const results = await withConcurrency(
    feedTasks,
    settings.fetch.concurrency,
    task => fetchSingleFeed(task.feed, task.categoryId, task.categoryName, settings),
  )

  const elapsed = Date.now() - start
  const successCount = results.filter(r => r.success).length
  const failCount = results.filter(r => !r.success).length
  const totalItems = results.reduce((sum, r) => sum + r.items.length, 0)

  console.log(`Done in ${(elapsed / 1000).toFixed(1)}s: ${successCount} ok, ${failCount} failed, ${totalItems} items`)

  // Update health map
  const now = new Date().toISOString()
  for (const r of results) {
    const entry = healthMap[r.feedUrl] || {
      lastSuccess: null,
      lastFailure: null,
      consecutiveFailures: 0,
      totalAttempts: 0,
      totalSuccesses: 0,
    }
    entry.totalAttempts++
    if (r.success) {
      entry.lastSuccess = now
      entry.consecutiveFailures = 0
      entry.totalSuccesses++
      delete entry.lastError
    } else {
      entry.lastFailure = now
      entry.consecutiveFailures++
      entry.lastError = r.error
    }
    healthMap[r.feedUrl] = entry
  }

  // Print failures
  const failures = results.filter(r => !r.success)
  if (failures.length > 0) {
    console.log("\nFailed feeds:")
    for (const f of failures) {
      console.log(`  ${f.feedName}: ${f.error}`)
    }
  }

  // Write outputs
  const output: RawFetchOutput = {
    fetchedAt: now,
    totalFeeds: feedTasks.length,
    successCount,
    failCount,
    totalItems,
    results,
  }

  writeFileSync(resolve(DATA_DIR, "raw-items.json"), JSON.stringify(output, null, 2), "utf-8")
  writeFileSync(resolve(DATA_DIR, "feed-health.json"), JSON.stringify(healthMap, null, 2), "utf-8")

  console.log(`\nWritten: data/raw-items.json (${totalItems} items)`)
  console.log(`Written: data/feed-health.json`)
}

main()
