/**
 * Regex-based RSS 2.0 / Atom 1.0 parser.
 * No XML library dependencies. Handles the common feed formats
 * from blogs, GitHub releases, podcasts, and news sites.
 */

export interface ParsedFeedItem {
  title: string
  link: string
  description: string
  pubDate: string | null
  guid: string
}

/**
 * Parse an RSS or Atom feed XML string into items.
 * Auto-detects format by looking for <feed> (Atom) vs <rss>/<channel> tags.
 */
export function parseFeed(xml: string): ParsedFeedItem[] {
  // Detect Atom vs RSS
  if (/<feed[\s>]/i.test(xml)) {
    return parseAtom(xml)
  }
  return parseRss(xml)
}

// ── RSS 2.0 ──

function parseRss(xml: string): ParsedFeedItem[] {
  const items: ParsedFeedItem[] = []
  const itemRegex = /<item>([\s\S]*?)<\/item>/gi
  let match: RegExpExecArray | null

  while ((match = itemRegex.exec(xml)) !== null) {
    const block = match[1]
    if (!block) continue

    const title = extractTag(block, "title")
    const link = extractTag(block, "link")
    const description = extractTag(block, "description") || extractTag(block, "content:encoded")
    const pubDate = extractTag(block, "pubDate")
    const guid = extractTag(block, "guid") || link

    if (!title && !link) continue

    items.push({
      title: decodeEntities(title),
      link,
      description: decodeEntities(stripHtml(description).slice(0, 500)),
      pubDate,
      guid: guid || `${link}#${title}`,
    })
  }

  return items
}

// ── Atom 1.0 ──

function parseAtom(xml: string): ParsedFeedItem[] {
  const items: ParsedFeedItem[] = []
  const entryRegex = /<entry>([\s\S]*?)<\/entry>/gi
  let match: RegExpExecArray | null

  while ((match = entryRegex.exec(xml)) !== null) {
    const block = match[1]
    if (!block) continue

    const title = extractTag(block, "title")
    const link = extractAtomLink(block)
    const description = extractTag(block, "summary") || extractTag(block, "content")
    const pubDate = extractTag(block, "published") || extractTag(block, "updated")
    const guid = extractTag(block, "id") || link

    if (!title && !link) continue

    items.push({
      title: decodeEntities(title),
      link,
      description: decodeEntities(stripHtml(description).slice(0, 500)),
      pubDate,
      guid: guid || `${link}#${title}`,
    })
  }

  return items
}

// ── Helpers ──

function extractTag(block: string, tag: string): string {
  // Handle CDATA: <tag><![CDATA[content]]></tag>
  const cdataRegex = new RegExp(`<${tag}[^>]*>\\s*<!\\[CDATA\\[([\\s\\S]*?)\\]\\]>\\s*</${tag}>`, "i")
  const cdataMatch = block.match(cdataRegex)
  if (cdataMatch?.[1]) return cdataMatch[1].trim()

  // Handle regular: <tag>content</tag>
  const regex = new RegExp(`<${tag}[^>]*>([\\s\\S]*?)</${tag}>`, "i")
  const match = block.match(regex)
  return match?.[1]?.trim() ?? ""
}

function extractAtomLink(block: string): string {
  // Prefer rel="alternate" or no rel attribute
  const altMatch = block.match(/<link[^>]*rel=["']alternate["'][^>]*href=["']([^"']+)["']/i)
  if (altMatch?.[1]) return altMatch[1]

  // Fallback: any link with href
  const hrefMatch = block.match(/<link[^>]*href=["']([^"']+)["']/i)
  return hrefMatch?.[1] ?? ""
}

function stripHtml(str: string): string {
  return str.replace(/<[^>]*>/g, "").replace(/\s+/g, " ").trim()
}

function decodeEntities(str: string): string {
  return str
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&apos;/g, "'")
    .replace(/&#x([0-9a-fA-F]+);/g, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, dec) => String.fromCodePoint(parseInt(dec, 10)))
}
