/**
 * Standalone AI summarization using Claude API.
 * Used in scheduled/unattended mode (not interactive Claude Code).
 * Reads data/filtered-items.json, generates summaries via Claude API,
 * outputs data/summarized-items.json.
 */

import { readFileSync, writeFileSync, existsSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import type { FilteredOutput, SummarizedItem, SummarizedOutput, Settings } from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")
const DATA_DIR = resolve(SKILL_DIR, "data")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

interface ClaudeMessage {
  role: "user" | "assistant"
  content: string
}

interface ClaudeResponse {
  content: Array<{ type: "text"; text: string }>
}

async function callClaude(
  apiKey: string,
  model: string,
  messages: ClaudeMessage[],
  systemPrompt: string,
): Promise<string> {
  const baseUrl = (process.env.ANTHROPIC_BASE_URL ?? "https://api.anthropic.com").replace(/\/$/, "")
  const response = await fetch(`${baseUrl}/v1/messages`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model,
      max_tokens: 8192,
      system: systemPrompt,
      messages,
    }),
  })

  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(`Claude API error: ${response.status} ${errorText}`)
  }

  const result = (await response.json()) as ClaudeResponse
  return result.content[0]?.text ?? ""
}

const SYSTEM_PROMPT = `你是一个 AI 资讯摘要助手。你的任务是：
1. 为每条 AI 资讯生成简洁的中文摘要（2-3 句话）
2. 保留英文专有名词（如 Claude、GPT-4、Transformer、LLM）
3. 从所有条目中选出最有价值的内容作为 Smart Recommendations
4. Smart Recommendations 应该是重大产品发布、有影响力的研究、深度分析或重要的开源项目

请严格按照指定的 JSON 格式输出。`

async function summarizeBatch(
  items: Array<{ title: string; description: string; link: string; feedName: string; categoryId: string; categoryName: string; pubDate: string | null }>,
  batchIndex: number,
  totalBatches: number,
  apiKey: string,
  settings: Settings,
): Promise<SummarizedItem[]> {
  const itemsText = items.map((item, i) => {
    const desc = item.description ? item.description.slice(0, 500) : ""
    return `[${i}] 标题: ${item.title}\n来源: ${item.feedName}\n分类: ${item.categoryName}\n描述: ${desc}`
  }).join("\n\n---\n\n")

  const prompt = `以下是第 ${batchIndex + 1}/${totalBatches} 批 AI 资讯（共 ${items.length} 条）。
请为每条生成中文摘要，并标记是否推荐为 Smart Pick。

${itemsText}

请以 JSON 数组格式输出，每个元素包含：
- index: 原始序号
- summary: 中文摘要（2-3句）
- isSmartPick: 是否推荐（boolean）

输出格式：
\`\`\`json
[{"index": 0, "summary": "...", "isSmartPick": false}, ...]
\`\`\``

  const response = await callClaude(apiKey, settings.summarization.model, [
    { role: "user", content: prompt },
  ], SYSTEM_PROMPT)

  // Extract JSON from response
  const jsonMatch = response.match(/```json\s*([\s\S]*?)```/) || response.match(/\[[\s\S]*\]/)
  if (!jsonMatch) {
    console.error(`Failed to parse batch ${batchIndex} response`)
    return items.map(item => ({
      title: item.title,
      link: item.link,
      source: item.feedName,
      categoryId: item.categoryId,
      categoryName: item.categoryName,
      pubDate: item.pubDate,
      summary: item.description?.slice(0, 200) || item.title,
      isSmartPick: false,
    }))
  }

  const jsonStr = jsonMatch[1] || jsonMatch[0]!
  const parsed = JSON.parse(jsonStr) as Array<{ index: number; summary: string; isSmartPick: boolean }>

  return parsed.map(p => {
    const item = items[p.index]!
    return {
      title: item.title,
      link: item.link,
      source: item.feedName,
      categoryId: item.categoryId,
      categoryName: item.categoryName,
      pubDate: item.pubDate,
      summary: p.summary,
      isSmartPick: p.isSmartPick,
    }
  })
}

async function main() {
  const settings = loadSettings()

  const apiKey = process.env.ANTHROPIC_API_KEY || process.env.ANTHROPIC_AUTH_TOKEN
  if (!apiKey) {
    console.error("ANTHROPIC_API_KEY environment variable not set.")
    process.exit(1)
  }

  const filteredPath = resolve(DATA_DIR, "filtered-items.json")
  if (!existsSync(filteredPath)) {
    console.error("filtered-items.json not found. Run fetch + filter first.")
    process.exit(1)
  }

  const data: FilteredOutput = JSON.parse(readFileSync(filteredPath, "utf-8"))
  console.log(`Summarizing ${data.items.length} items...`)

  // Batch items
  const batchSize = settings.summarization.batchSize
  const batches: typeof data.items[] = []
  for (let i = 0; i < data.items.length; i += batchSize) {
    batches.push(data.items.slice(i, i + batchSize))
  }

  console.log(`Processing ${batches.length} batches (size: ${batchSize})...`)

  const allItems: SummarizedItem[] = []
  for (let i = 0; i < batches.length; i++) {
    console.log(`  Batch ${i + 1}/${batches.length}...`)
    const items = await summarizeBatch(batches[i]!, i, batches.length, apiKey, settings)
    allItems.push(...items)
  }

  // Select top Smart Picks
  const smartPicks = allItems.filter(i => i.isSmartPick)
  const maxPicks = settings.output.maxSmartRecommendations

  if (smartPicks.length > maxPicks) {
    // Keep only top N, mark rest as non-picks
    const keepSet = new Set(smartPicks.slice(0, maxPicks))
    for (const item of allItems) {
      if (item.isSmartPick && !keepSet.has(item)) {
        item.isSmartPick = false
      }
    }
  }

  // Assign ranks to smart picks
  let rank = 0
  for (const item of allItems) {
    if (item.isSmartPick) {
      item.smartPickRank = ++rank
    }
  }

  const output: SummarizedOutput = {
    summarizedAt: new Date().toISOString(),
    totalItems: allItems.length,
    smartPickCount: allItems.filter(i => i.isSmartPick).length,
    items: allItems,
  }

  writeFileSync(resolve(DATA_DIR, "summarized-items.json"), JSON.stringify(output, null, 2), "utf-8")
  console.log(`\nWritten: data/summarized-items.json`)
  console.log(`Total items: ${allItems.length}`)
  console.log(`Smart picks: ${output.smartPickCount}`)
}

main()
