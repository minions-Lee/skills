/**
 * HTTP client with retry, timeout, and optional proxy support.
 * Uses Node.js native fetch (20+) with undici ProxyAgent when https_proxy is set.
 */
import { ProxyAgent } from "undici"

const proxyUrl = process.env.https_proxy || process.env.HTTPS_PROXY || process.env.http_proxy || process.env.HTTP_PROXY
const proxyDispatcher = proxyUrl ? new ProxyAgent(proxyUrl) : undefined

export interface FetchOptions {
  timeoutMs?: number
  retries?: number
  retryDelayMs?: number
  headers?: Record<string, string>
}

export interface FetchResult {
  ok: boolean
  status: number
  body: string
  error?: string
}

const DEFAULT_UA = "ai-digest-bot/1.0"

export async function fetchUrl(url: string, options: FetchOptions = {}): Promise<FetchResult> {
  const {
    timeoutMs = 15_000,
    retries = 2,
    retryDelayMs = 2_000,
    headers = {},
  } = options

  let lastError = ""

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const controller = new AbortController()
      const timer = setTimeout(() => controller.abort(), timeoutMs)

      const resp = await fetch(url, {
        headers: {
          "User-Agent": DEFAULT_UA,
          Accept: "application/rss+xml, application/atom+xml, application/xml, text/xml, */*",
          ...headers,
        },
        signal: controller.signal,
        redirect: "follow",
        // @ts-ignore - undici dispatcher for proxy support
        dispatcher: proxyDispatcher,
      })

      clearTimeout(timer)

      if (resp.status === 429) {
        const retryAfter = resp.headers.get("retry-after")
        const waitMs = retryAfter ? parseInt(retryAfter, 10) * 1000 : 60_000
        if (attempt < retries) {
          await sleep(Math.min(waitMs, 60_000))
          continue
        }
        return { ok: false, status: 429, body: "", error: "rate limited" }
      }

      if (!resp.ok) {
        lastError = `HTTP ${resp.status}`
        if (attempt < retries) {
          await sleep(retryDelayMs * attempt)
          continue
        }
        return { ok: false, status: resp.status, body: "", error: lastError }
      }

      const body = await resp.text()
      return { ok: true, status: resp.status, body }
    } catch (err) {
      const e = err as Error
      lastError = e.name === "AbortError" ? `timeout after ${timeoutMs}ms` : e.message
      if (attempt < retries) {
        await sleep(retryDelayMs * attempt)
      }
    }
  }

  return { ok: false, status: 0, body: "", error: lastError }
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

/**
 * Run multiple async tasks with a concurrency limit.
 */
export async function withConcurrency<T, R>(
  items: T[],
  concurrency: number,
  fn: (item: T) => Promise<R>,
): Promise<R[]> {
  const results: R[] = []
  const executing = new Set<Promise<void>>()

  for (const item of items) {
    const p = (async () => {
      results.push(await fn(item))
    })()
    executing.add(p)
    p.finally(() => executing.delete(p))
    if (executing.size >= concurrency) {
      await Promise.race(executing)
    }
  }
  await Promise.all(executing)
  return results
}
