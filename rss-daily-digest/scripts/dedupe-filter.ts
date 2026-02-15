/**
 * Deduplication and time-window filtering.
 * Reads data/raw-items.json, filters to recent items,
 * deduplicates using persistent GUID store, outputs data/filtered-items.json.
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import type { RawFetchOutput, FeedItem, FilteredOutput, Settings } from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")
const DATA_DIR = resolve(SKILL_DIR, "data")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

type SeenGuids = Record<string, string> // guid → ISO timestamp

function loadSeenGuids(): SeenGuids {
  const path = resolve(DATA_DIR, "seen-guids.json")
  if (existsSync(path)) {
    return JSON.parse(readFileSync(path, "utf-8"))
  }
  return {}
}

function saveSeenGuids(guids: SeenGuids): void {
  writeFileSync(resolve(DATA_DIR, "seen-guids.json"), JSON.stringify(guids, null, 2), "utf-8")
}

/**
 * Parse various date formats into a timestamp.
 * Returns null if unparseable.
 */
function parseDate(dateStr: string | null): number | null {
  if (!dateStr) return null
  const d = new Date(dateStr)
  return isNaN(d.getTime()) ? null : d.getTime()
}

function parseCategoryFilter(): string | null {
  const idx = process.argv.indexOf("--category")
  if (idx === -1) return null
  return process.argv[idx + 1] || null
}

function main() {
  const settings = loadSettings()
  const windowHours = settings.filter.timeWindowHours
  const maxDays = settings.filter.dedupeStoreMaxDays
  const categoryFilter = parseCategoryFilter()

  if (categoryFilter) {
    console.log(`Category filter: "${categoryFilter}"`)
  }

  // Load raw items
  const rawPath = resolve(DATA_DIR, "raw-items.json")
  if (!existsSync(rawPath)) {
    console.error("raw-items.json not found. Run `npm run fetch` first.")
    process.exit(1)
  }
  const raw: RawFetchOutput = JSON.parse(readFileSync(rawPath, "utf-8"))

  // Flatten all items, optionally filter by category
  let allItems: FeedItem[] = raw.results.flatMap(r => r.items)
  if (categoryFilter) {
    const q = categoryFilter.toLowerCase()
    allItems = allItems.filter(i =>
      i.categoryId.toLowerCase().includes(q) || i.categoryName.toLowerCase().includes(q)
    )
  }
  console.log(`Total items from fetch: ${allItems.length}`)

  // Time-window filter
  const now = Date.now()
  const cutoff = now - windowHours * 60 * 60 * 1000

  const recentItems = allItems.filter(item => {
    const ts = parseDate(item.pubDate)
    // Skip items without a valid date (static pages, broken feeds)
    if (ts === null) return false
    return ts >= cutoff
  })
  console.log(`After ${windowHours}h time filter: ${recentItems.length}`)

  // Deduplication
  const seenGuids = loadSeenGuids()
  const newItems: FeedItem[] = []

  for (const item of recentItems) {
    const guid = item.guid || item.link || `${item.feedUrl}#${item.title}`
    if (seenGuids[guid]) continue

    seenGuids[guid] = new Date().toISOString()
    newItems.push(item)
  }
  console.log(`After dedup: ${newItems.length} new items`)

  // Prune old entries from seen-guids store
  const pruneCutoff = now - maxDays * 24 * 60 * 60 * 1000
  let pruned = 0
  for (const [guid, timestamp] of Object.entries(seenGuids)) {
    const ts = new Date(timestamp).getTime()
    if (ts < pruneCutoff) {
      delete seenGuids[guid]
      pruned++
    }
  }
  if (pruned > 0) {
    console.log(`Pruned ${pruned} old entries from seen-guids (>${maxDays} days)`)
  }

  // Sort by date (newest first), then by category
  newItems.sort((a, b) => {
    const ta = parseDate(a.pubDate) ?? 0
    const tb = parseDate(b.pubDate) ?? 0
    return tb - ta
  })

  // Output
  const output: FilteredOutput = {
    filteredAt: new Date().toISOString(),
    timeWindowHours: windowHours,
    totalBefore: allItems.length,
    totalAfter: newItems.length,
    newItems: newItems.length,
    items: newItems,
  }

  writeFileSync(resolve(DATA_DIR, "filtered-items.json"), JSON.stringify(output, null, 2), "utf-8")
  saveSeenGuids(seenGuids)

  console.log(`\nWritten: data/filtered-items.json (${newItems.length} items)`)
  console.log(`Seen guids store: ${Object.keys(seenGuids).length} entries`)

  // Per-category breakdown
  const byCat = new Map<string, number>()
  for (const item of newItems) {
    byCat.set(item.categoryName, (byCat.get(item.categoryName) ?? 0) + 1)
  }
  console.log("\nPer category:")
  for (const [cat, count] of byCat) {
    console.log(`  ${cat}: ${count}`)
  }
}

main()
