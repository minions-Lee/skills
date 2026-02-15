---
name: video-downloader
version: "1.0.0"
description: Download videos from YouTube and other sites using yt-dlp. Use when user provides a video URL and asks to download it.
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# Video Downloader Skill

Download videos from YouTube, Bilibili, Twitter, and 1000+ other sites using yt-dlp.

## Prerequisites

yt-dlp must be installed. Install via:

```bash
# macOS (recommended)
brew install yt-dlp

# or via pip
pip install yt-dlp

# or via pipx (isolated environment)
pipx install yt-dlp
```

## Usage

When user provides a video URL, download it using yt-dlp.

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
| `-P ~/Downloads` | Set download directory |
| `--cookies-from-browser chrome` | Use browser cookies (for login-required videos) |
| `--list-formats` | List available formats |
| `--write-subs` | Download subtitles |
| `--sub-lang en,zh` | Subtitle languages |

### Examples

**Download video to Downloads folder:**
```bash
yt-dlp -P ~/Downloads "https://www.youtube.com/watch?v=VIDEO_ID"
```

**Download audio only as MP3:**
```bash
yt-dlp --extract-audio --audio-format mp3 -P ~/Downloads "VIDEO_URL"
```

**Download with custom filename:**
```bash
yt-dlp -o "%(title)s-%(id)s.%(ext)s" -P ~/Downloads "VIDEO_URL"
```

**Download playlist:**
```bash
yt-dlp -P ~/Downloads "PLAYLIST_URL"
```

**List available formats:**
```bash
yt-dlp --list-formats "VIDEO_URL"
```

## Workflow

1. **Check if yt-dlp is installed:**
   ```bash
   which yt-dlp || echo "Please install: brew install yt-dlp"
   ```

2. **Parse user request for:**
   - Video URL
   - Preferred quality (if specified)
   - Audio-only preference
   - Output directory (default: ~/Downloads)

3. **Execute download:**
   ```bash
   yt-dlp [options] "VIDEO_URL"
   ```

4. **Report result:**
   - Filename downloaded
   - File location
   - File size (if available)

## Supported Sites

yt-dlp supports 1000+ sites including:
- YouTube (videos, playlists, channels)
- Bilibili
- Twitter/X
- TikTok
- Vimeo
- Twitch
- Instagram
- Facebook
- And many more...

Run `yt-dlp --list-extractors` to see all supported sites.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Video unavailable" | Try `--cookies-from-browser chrome` |
| Age-restricted content | Use browser cookies |
| Slow download | Normal for some sites |
| Format not available | Use `--list-formats` to see options |
| Permission denied | Check output directory permissions |
