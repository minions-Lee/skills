// ── Feed Configuration ──

export interface FeedSource {
  id: string
  name: string
  url: string
  status: "official" | "community" | "rsshub" | "broken"
  enabled: boolean
}

export interface FeedCategory {
  id: string
  name: string
  feeds: FeedSource[]
}

export interface FeedsConfig {
  generatedFrom: string
  generatedAt: string
  categories: FeedCategory[]
}

// ── Fetched Items ──

export interface FeedItem {
  title: string
  link: string
  description: string
  pubDate: string | null
  guid: string
  feedName: string
  feedUrl: string
  categoryId: string
  categoryName: string
}

export interface FeedFetchResult {
  feedUrl: string
  feedName: string
  success: boolean
  items: FeedItem[]
  error?: string
  durationMs: number
}

export interface RawFetchOutput {
  fetchedAt: string
  totalFeeds: number
  successCount: number
  failCount: number
  totalItems: number
  results: FeedFetchResult[]
}

// ── Filtered Items ──

export interface FilteredOutput {
  filteredAt: string
  timeWindowHours: number
  totalBefore: number
  totalAfter: number
  newItems: number
  items: FeedItem[]
}

// ── Summarized Items ──

export interface SummarizedItem {
  title: string
  link: string
  source: string
  categoryId: string
  categoryName: string
  pubDate: string | null
  summary: string
  isSmartPick: boolean
  smartPickRank?: number
}

export interface SummarizedOutput {
  summarizedAt: string
  totalItems: number
  smartPickCount: number
  podcastTop5?: SummarizedItem[]
  blogTop5?: SummarizedItem[]
  items: SummarizedItem[]
}

// ── Feed Health ──

export interface FeedHealthEntry {
  lastSuccess: string | null
  lastFailure: string | null
  consecutiveFailures: number
  totalAttempts: number
  totalSuccesses: number
  lastError?: string
}

export type FeedHealthMap = Record<string, FeedHealthEntry>

// ── Settings ──

export interface Settings {
  fetch: {
    concurrency: number
    timeoutMs: number
    retries: number
    retryDelayMs: number
    userAgent: string
  }
  filter: {
    timeWindowHours: number
    dedupeStoreMaxDays: number
  }
  output: {
    archiveDir: string
    filenamePattern: string
    maxSmartRecommendations: number
  }
  dingtalk: {
    enabled: boolean
    webhookUrlEnvVar: string
    secretEnvVar: string
  }
  summarization: {
    model: string
    batchSize: number
  }
  feedsSource: string
}
