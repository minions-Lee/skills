---
name: video-downloader
version: "4.0.0"
description: Download videos/audio from YouTube, Bilibili, 小宇宙 and 1000+ other sites, with transcript extraction using Whisper, auto-analyze core topic and organize into themed folders. Use when user provides a video/audio URL and asks to download it, or asks for transcript/逐字稿 extraction. 触发词：下载视频、下载音频、逐字稿、transcript、小宇宙下载、小宇宙音频、xiaoyuzhou、播客下载、播客转文字。
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# Video & Audio Downloader Skill

下载视频/音频，自动提取逐字稿，分析核心主题，创建主题文件夹并归档所有文件。支持 YouTube、Bilibili、小宇宙、Twitter 等 1000+ 站点。

## Prerequisites

```bash
# 检查依赖
which yt-dlp && which ffmpeg && echo "基础依赖已就绪" || echo "缺少基础依赖"
which whisper && echo "Whisper 已就绪（可提取逐字稿）" || echo "Whisper 未安装（逐字稿功能不可用）"

# 安装基础依赖
# brew install yt-dlp ffmpeg

# 安装 Whisper（逐字稿功能需要）
# pip3 install openai-whisper
```

## 完整流程概览

```
① 检查依赖
② 解析用户请求（URL、偏好）
③ URL 路由 → 下载内容
④ Whisper 提取逐字稿（默认执行）
⑤ 分析核心主题 → 创建主题文件夹 → 归档所有文件
```

**核心变化**：逐字稿提取和主题归档现在是**默认行为**，无需用户额外指定。每次下载都会自动完成全流程。

## Workflow

### 1. Check dependencies

```bash
which yt-dlp && which ffmpeg && echo "基础依赖已就绪" || echo "缺少基础依赖"
which whisper && echo "Whisper 已就绪" || echo "Whisper 未安装，请先安装: pip3 install openai-whisper"
```

### 2. Parse user request

- 提取 URL
- 偏好画质（如有指定）
- 是否仅下载音频
- 输出目录（用户指定 > 默认平台目录）

### 3. 确定输出目录

**如用户未明确指定输出目录，根据 URL 来源自动路由到对应平台目录**：

| URL 来源 | 默认归档目录 |
|----------|-------------|
| `xiaoyuzhoufm.com` | `~/Documents/pe/jixiaxuegong/xiaoyuzhou/` |
| `bilibili.com` / `b23.tv` | `~/Documents/pe/jixiaxuegong/bilibili/` |
| `youtube.com` / `youtu.be` | `~/Documents/pe/jixiaxuegong/youtube/` |
| 其他站点 | 当前工作目录 |

```bash
# 自动创建目录（如不存在）
mkdir -p "$OUTPUT_DIR"
```

> 用户明确指定了输出目录时，以用户指定为准，忽略上述默认规则。

### 4. URL 路由

**根据 URL 自动选择下载通道**：

```
URL 匹配 xiaoyuzhoufm.com/episode/ → 走「小宇宙专用流程」
其他 URL                           → 走「yt-dlp 标准流程」
      ↓
两条路都汇入 →「Whisper 逐字稿」（默认执行）
      ↓
「分析主题 → 创建文件夹 → 归档」
```

---

## yt-dlp 标准流程

适用于 YouTube、Bilibili、Twitter/X、TikTok 等 yt-dlp 支持的站点。

### Basic Download

```bash
yt-dlp "VIDEO_URL"
```

### Common Options

| Option | Description |
|--------|-------------|
| `-o "%(title)s.%(ext)s"` | Custom output filename template |
| `-f best` | Download best quality |
| `-f "bestvideo+bestaudio"` | Best video + audio (merge) |
| `-f "bestvideo[height<=1080]+bestaudio"` | Limit to 1080p max |
| `--extract-audio` | Extract audio only |
| `--audio-format mp3` | Convert audio to mp3 |
| `-P .` | Set download directory (current working directory) |
| `--cookies-from-browser chrome` | Use browser cookies (for login-required videos) |
| `--list-formats` | List available formats |
| `--write-subs` | Download subtitles |
| `--sub-lang en,zh` | Subtitle languages |

### Examples

**Download video to current directory:**
```bash
yt-dlp -P . "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Download audio only as MP3:**
```bash
yt-dlp --extract-audio --audio-format mp3 -P . "VIDEO_URL"
```

**Download with custom filename:**
```bash
yt-dlp -o "%(title)s-%(id)s.%(ext)s" -P . "VIDEO_URL"
```

**Download playlist:**
```bash
yt-dlp -P . "PLAYLIST_URL"
```

**List available formats:**
```bash
yt-dlp --list-formats "VIDEO_URL"
```

### 下载完成

下载完成后，自动继续执行「逐字稿提取」和「主题分析与文件归档」。

---

## 小宇宙专用流程

适用于 `xiaoyuzhoufm.com/episode/` 链接。小宇宙不被 yt-dlp 支持，使用 curl + og:audio 专用通道。

### 步骤 1：获取页面并提取元信息

```bash
EPISODE_URL="用户提供的小宇宙链接"
OUTPUT_DIR="."

# 获取页面 HTML
PAGE_HTML=$(curl -sL -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" "$EPISODE_URL")

# 提取 og 标签
TITLE=$(echo "$PAGE_HTML" | grep -oE 'property="og:title" content="[^"]*"' | sed 's/property="og:title" content="//;s/"$//')
AUDIO_URL=$(echo "$PAGE_HTML" | grep -oE 'property="og:audio" content="[^"]*"' | sed 's/property="og:audio" content="//;s/"$//')
IMAGE_URL=$(echo "$PAGE_HTML" | grep -oE 'property="og:image" content="[^"]*"' | sed 's/property="og:image" content="//;s/"$//')

# 验证
if [ -z "$AUDIO_URL" ]; then
  echo "错误：无法提取音频链接，请检查 URL 是否有效"
  # 页面标题为"找不到了"表示链接已失效
fi
```

### 步骤 2：提取 Shownotes（平台文本）

从页面内嵌的 `__NEXT_DATA__` JSON 中提取 description 和 shownotes（播主撰写的带时间戳内容大纲，秒级完成）：

```bash
SAFE_TITLE=$(echo "$TITLE" | tr '/:*?"<>|' '_')

python3 -c "
import json, re, html, sys
with open('/dev/stdin', 'r') as f:
    content = f.read()
m = re.search(r'__NEXT_DATA__.*?>(.*?)</script>', content)
if not m:
    print('无法提取页面数据', file=sys.stderr)
    sys.exit(1)
data = json.loads(m.group(1))
ep = data['props']['pageProps']['episode']
title = ep.get('title', '')
desc = ep.get('description', '')
duration = ep.get('duration', 0)
podcast_name = ep.get('podcast', {}).get('title', '')
shownotes_html = ep.get('shownotes', '')
shownotes = re.sub(r'<[^>]+>', '\n', html.unescape(shownotes_html))
shownotes = re.sub(r'\n{3,}', '\n\n', shownotes).strip()

print(f'# {title}')
print(f'播客: {podcast_name}')
print(f'时长: {duration // 60}分{duration % 60}秒')
print()
print('## Shownotes')
print()
print(desc if desc else shownotes)
" <<< "\$PAGE_HTML" > "${OUTPUT_DIR}/${SAFE_TITLE}_shownotes.md"

echo "Shownotes 已保存到：${OUTPUT_DIR}/${SAFE_TITLE}_shownotes.md"
```

### 步骤 3：下载音频

```bash
# 获取文件扩展名
EXT="${AUDIO_URL##*.}"
EXT="${EXT%%\?*}"
[[ "$EXT" != "mp3" && "$EXT" != "m4a" ]] && EXT="m4a"

AUDIO_FILE="${OUTPUT_DIR}/${SAFE_TITLE}.${EXT}"

echo "正在下载音频..."
curl -L --progress-bar -o "$AUDIO_FILE" "$AUDIO_URL"

FILE_SIZE=$(ls -lh "$AUDIO_FILE" | awk '{print $5}')
echo "下载完成：$AUDIO_FILE ($FILE_SIZE)"
```

下载完成后，自动继续执行「逐字稿提取」和「主题分析与文件归档」。

---

## 逐字稿提取（Whisper）— 默认执行

**每次下载都自动执行逐字稿提取**。适用于所有来源（yt-dlp 下载的视频、小宇宙下载的音频）。

### 步骤 1：提取音频

从已下载的视频中提取音频文件（如果下载的已经是音频如 m4a/mp3 则跳过此步）：

```bash
VIDEO_FILE="已下载的视频文件路径"
AUDIO_FILE="${VIDEO_FILE%.*}.wav"

ffmpeg -i "$VIDEO_FILE" -ar 16000 -ac 1 -c:a pcm_s16le "$AUDIO_FILE" -y
echo "音频提取完成：$AUDIO_FILE"
```

### 步骤 2：Whisper 生成逐字稿

```bash
echo "正在用 Whisper 生成逐字稿..."
whisper "$AUDIO_FILE" \
  --model small \
  --language zh \
  --initial_prompt "以下是普通话的句子。" \
  --output_format txt \
  --output_dir .

echo "逐字稿已保存"
```

**关键参数说明**：
- `--language zh`：指定中文（如为英文视频改为 `en`，或不指定由 Whisper 自动检测）
- `--initial_prompt "以下是普通话的句子。"`：引导输出简体中文（不加则可能输出繁体）
- `--output_format txt`：纯文本。可改为 `srt`（带时间戳字幕）或 `all`（所有格式）

**如需带时间戳的逐字稿**（SRT 格式）：
```bash
whisper "$AUDIO_FILE" \
  --model small \
  --language zh \
  --initial_prompt "以下是普通话的句子。" \
  --output_format srt \
  --output_dir .
```

### Whisper 模型选择

| 模型 | 大小 | 速度 | 精度 | 推荐场景 |
|------|------|------|------|----------|
| `tiny` | 39M | 最快 | 一般 | 快速预览 |
| `base` | 74M | 快 | 一般 | 快速预览 |
| `small` | 244M | 中等 | 较好 | **默认推荐** |
| `medium` | 769M | 慢 | 好 | 长视频、多人对话 |
| `large` | 1550M | 最慢 | 最好 | 需要最高精度 |

### 注意事项

- Whisper 首次运行会下载模型文件（small 约 244MB），之后会缓存
- 10 分钟视频用 `small` 模型大约需要 1-3 分钟转录（Apple Silicon Mac）
- `--initial_prompt "以下是普通话的句子。"` 是确保输出简体中文的关键参数
- 如果视频已有平台字幕，优先用 `--write-subs` 下载（更快更准），Whisper 作为备选

---

## 主题分析与文件归档 — 默认执行

**每次下载完成并生成逐字稿后，自动执行以下归档流程**。

### 步骤 1：分析核心主题

使用 Read 工具读取已生成的逐字稿文件（.txt）和 shownotes 文件（如有），然后分析内容，提取一个简短的**核心主题名称**。

**分析规则**：
- 主题名称控制在 **2-8 个中文字**，简洁概括内容核心
- 优先从内容本身提炼，而非使用原标题（原标题可能很长或含营销用语）
- 示例：`AI编程实践`、`独立开发者心路`、`创业融资策略`、`远程办公管理`、`播客商业化`
- 如果内容涉及特定人物/产品且是核心话题，可纳入：`马斯克与SpaceX`、`GPT深度解析`
- 避免过于宽泛（如 `科技`、`生活`）或过于具体（如 `2024年3月15日的一次对话`）

### 步骤 2：创建主题文件夹并归档

```bash
# TOPIC_NAME 由上一步分析得出
TOPIC_NAME="分析得出的核心主题"
OUTPUT_DIR="当前工作目录"

# 清理文件夹名（移除文件系统不支持的字符）
FOLDER_NAME=$(echo "$TOPIC_NAME" | tr '/:*?"<>|\\' '_')

# 创建主题文件夹
mkdir -p "${OUTPUT_DIR}/${FOLDER_NAME}"

# 移动所有相关文件到主题文件夹
# 包括：视频文件、音频文件、逐字稿、shownotes、WAV 中间文件等
mv "${OUTPUT_DIR}"/相关文件 "${OUTPUT_DIR}/${FOLDER_NAME}/"

echo "已归档到文件夹：${OUTPUT_DIR}/${FOLDER_NAME}/"
```

**归档的文件类型**：
- 视频文件（.mp4、.webm、.mkv 等）
- 音频文件（.m4a、.mp3 等）
- 逐字稿文件（.txt、.srt）
- Shownotes 文件（_shownotes.md）
- 中间音频文件（.wav）— 转录完成后可选删除以节省空间

### 步骤 3：清理与报告

转录完成后，删除中间产生的 WAV 文件以节省磁盘空间：

```bash
# 删除转录用的 WAV 中间文件
rm -f "${OUTPUT_DIR}/${FOLDER_NAME}"/*.wav
```

**最终输出报告**：

```
✅ 下载完成

📂 主题文件夹：{FOLDER_NAME}/
├── {原始标题}.m4a          （音频）
├── {原始标题}.txt           （逐字稿）
└── {原始标题}_shownotes.md  （Shownotes，如有）

🏷️ 核心主题：{TOPIC_NAME}
📍 位置：{OUTPUT_DIR}/{FOLDER_NAME}/
```

### 完整流程示例

用户输入：`下载 https://www.xiaoyuzhoufm.com/episode/xxx`

执行过程：
1. 检查依赖 → 全部就绪
2. 识别为小宇宙链接 → 走专用流程
3. 提取元信息 + 下载音频 → `EP123_独立开发者的一天.m4a`
4. 提取 Shownotes → `EP123_独立开发者的一天_shownotes.md`
5. Whisper 转录 → `EP123_独立开发者的一天.txt`
6. 分析逐字稿内容 → 核心主题：`独立开发者日常`
7. 创建文件夹 `独立开发者日常/` → 移入所有文件
8. 清理 WAV 中间文件
9. 输出完成报告

---

## Supported Sites

**yt-dlp 通道**（1000+ 站点）：
- YouTube (videos, playlists, channels)
- Bilibili
- Twitter/X
- TikTok
- Vimeo
- Twitch
- Instagram
- Facebook
- And many more... Run `yt-dlp --list-extractors` to see all.

**专用通道**：
- 小宇宙 (xiaoyuzhoufm.com) — curl + og:audio，不走 yt-dlp

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Video unavailable" | Try `--cookies-from-browser chrome` |
| Age-restricted content | Use browser cookies |
| Slow download | Normal for some sites |
| Format not available | Use `--list-formats` to see options |
| Permission denied | Check output directory permissions |
| 小宇宙链接返回"找不到了" | 链接已失效或 episode_id 无效，请检查 URL |
| 小宇宙提取不到 og:audio | 页面结构可能变更，检查 curl 返回内容 |
| Whisper 输出繁体中文 | 确保加了 `--initial_prompt "以下是普通话的句子。"` |
