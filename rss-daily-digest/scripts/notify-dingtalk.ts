/**
 * Send Smart Recommendations to DingTalk group via Webhook.
 * Reads data/summarized-items.json and sends top picks as Markdown message.
 */

import { readFileSync, existsSync } from "node:fs"
import { resolve, dirname } from "node:path"
import { fileURLToPath } from "node:url"
import { createHmac } from "node:crypto"
import type { SummarizedOutput, Settings } from "./utils/types.js"

const __dirname = dirname(fileURLToPath(import.meta.url))
const SKILL_DIR = resolve(__dirname, "..")
const CONFIG_DIR = resolve(SKILL_DIR, "config")
const DATA_DIR = resolve(SKILL_DIR, "data")

function loadSettings(): Settings {
  return JSON.parse(readFileSync(resolve(CONFIG_DIR, "settings.json"), "utf-8"))
}

function formatDate(d: Date): string {
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, "0")
  const dd = String(d.getDate()).padStart(2, "0")
  return `${yyyy}-${mm}-${dd}`
}

/**
 * Generate DingTalk signed URL if secret is configured.
 */
function signWebhookUrl(webhookUrl: string, secret: string): string {
  const timestamp = Date.now()
  const stringToSign = `${timestamp}\n${secret}`
  const hmac = createHmac("sha256", secret)
  hmac.update(stringToSign)
  const sign = encodeURIComponent(hmac.digest("base64"))
  const separator = webhookUrl.includes("?") ? "&" : "?"
  return `${webhookUrl}${separator}timestamp=${timestamp}&sign=${sign}`
}

async function sendDingTalk(webhookUrl: string, markdown: { title: string; text: string }): Promise<void> {
  const body = {
    msgtype: "markdown",
    markdown: {
      title: markdown.title,
      text: markdown.text,
    },
  }

  const response = await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  })

  if (!response.ok) {
    throw new Error(`DingTalk API error: ${response.status} ${response.statusText}`)
  }

  const result = await response.json() as { errcode: number; errmsg: string }
  if (result.errcode !== 0) {
    throw new Error(`DingTalk error: ${result.errcode} ${result.errmsg}`)
  }
}

async function main() {
  const settings = loadSettings()

  if (!settings.dingtalk.enabled) {
    console.log("DingTalk notifications disabled in settings.")
    return
  }

  const webhookUrl = process.env[settings.dingtalk.webhookUrlEnvVar]
  if (!webhookUrl) {
    console.error(`Environment variable ${settings.dingtalk.webhookUrlEnvVar} not set.`)
    process.exit(1)
  }

  const secret = process.env[settings.dingtalk.secretEnvVar] || ""

  // Load summarized items
  const summarizedPath = resolve(DATA_DIR, "summarized-items.json")
  if (!existsSync(summarizedPath)) {
    console.error("summarized-items.json not found. Run summarization first.")
    process.exit(1)
  }

  const data: SummarizedOutput = JSON.parse(readFileSync(summarizedPath, "utf-8"))
  const smartPicks = data.items
    .filter(i => i.isSmartPick)
    .sort((a, b) => (a.smartPickRank ?? 999) - (b.smartPickRank ?? 999))

  if (smartPicks.length === 0) {
    console.log("No Smart Recommendations to send.")
    return
  }

  // Build Markdown message
  const date = formatDate(new Date())
  const lines: string[] = []
  lines.push(`## AI 日报精选 | ${date}`)
  lines.push("")
  lines.push(`> ${data.totalItems} 条新内容中精选 ${smartPicks.length} 条`)
  lines.push("")

  for (let i = 0; i < smartPicks.length; i++) {
    const item = smartPicks[i]!
    lines.push(`**${i + 1}. ${item.title}**`)
    lines.push(`${item.summary}`)
    lines.push(`[阅读原文](${item.link}) | ${item.source}`)
    lines.push("")
  }

  const text = lines.join("\n")
  const title = `AI 日报精选 | ${date}`

  // Sign URL if secret is configured
  const finalUrl = secret ? signWebhookUrl(webhookUrl, secret) : webhookUrl

  console.log(`Sending ${smartPicks.length} Smart Recommendations to DingTalk...`)
  await sendDingTalk(finalUrl, { title, text })
  console.log("DingTalk notification sent successfully.")
}

main()
