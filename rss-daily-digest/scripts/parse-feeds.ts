/**
 * Parse rss-feeds.md → config/feeds.json
 * Reads the master RSS feed list and generates structured feed configuration.
 */

import { readFileSync, writeFileSync, existsSync, statSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { parseRssFeedsMd } from "./utils/feed-config-parser.js"
import type { Settings } from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

function main() {
  const settings = loadSettings()
  const feedsSourcePath = settings.feedsSource
  const outputPath = resolve(CONFIG_DIR, "feeds.json")

  // Check if rss-feeds.md exists
  if (!existsSync(feedsSourcePath)) {
    console.error(`Feed source not found: ${feedsSourcePath}`)
    process.exit(1)
  }

  // Check if regeneration needed (skip if feeds.json is newer than rss-feeds.md)
  if (existsSync(outputPath)) {
    const sourceMtime = statSync(feedsSourcePath).mtimeMs
    const outputMtime = statSync(outputPath).mtimeMs
    if (outputMtime > sourceMtime && !process.argv.includes("--force")) {
      console.log("feeds.json is up to date (use --force to regenerate)")
      return
    }
  }

  console.log(`Parsing: ${feedsSourcePath}`)
  const content = readFileSync(feedsSourcePath, "utf-8")
  const config = parseRssFeedsMd(content)

  // Stats
  const totalFeeds = config.categories.reduce((sum, cat) => sum + cat.feeds.length, 0)
  const enabledFeeds = config.categories.reduce(
    (sum, cat) => sum + cat.feeds.filter(f => f.enabled).length,
    0,
  )

  writeFileSync(outputPath, JSON.stringify(config, null, 2), "utf-8")

  console.log(`Generated: ${outputPath}`)
  console.log(`Categories: ${config.categories.length}`)
  console.log(`Total feeds: ${totalFeeds} (${enabledFeeds} enabled)`)

  // Print per-category breakdown
  for (const cat of config.categories) {
    const enabled = cat.feeds.filter(f => f.enabled).length
    console.log(`  ${cat.name}: ${enabled}/${cat.feeds.length} feeds`)
  }
}

main()
