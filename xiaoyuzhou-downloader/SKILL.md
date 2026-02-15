---
name: xiaoyuzhou-downloader
version: "2.0.0"
description: 下载小宇宙播客音频并提取逐字稿。用户提供小宇宙链接即可自动下载音频、提取 Shownotes、生成完整逐字稿。触发词：小宇宙下载、小宇宙音频、播客下载、xiaoyuzhou、小宇宙逐字稿、播客转文字。
user-invocable: true
allowed-tools:
  - Bash
  - Read
  - Write
---

# 小宇宙播客下载 & 逐字稿提取 Skill

从小宇宙 (xiaoyuzhoufm.com) 链接自动下载音频、提取 Shownotes、生成完整逐字稿。

## 前置依赖

```bash
# 检查依赖（执行前必须运行）
which curl && which ffmpeg && which whisper && echo "依赖已就绪" || echo "缺少依赖"

# 安装缺失的依赖
# brew install ffmpeg
# pip3 install openai-whisper
```

## 支持的 URL 格式

```
https://www.xiaoyuzhoufm.com/episode/{episode_id}
https://xiaoyuzhoufm.com/episode/{episode_id}
```

## 执行流程

收到用户的小宇宙链接后，按以下 4 步执行：

### 第 1 步：获取页面并提取元信息

```bash
EPISODE_URL="用户提供的链接"
OUTPUT_DIR="$HOME/Downloads"

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

### 第 2 步：提取 Shownotes（平台文本）

从页面内嵌的 `__NEXT_DATA__` JSON 中提取 description 和 shownotes。这是播主撰写的带时间戳内容大纲，**不需要安装额外依赖，秒级完成**。

```bash
# 提取 __NEXT_DATA__ 中的 description（带时间戳大纲）
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

# 输出
print(f'# {title}')
print(f'播客: {podcast_name}')
print(f'时长: {duration // 60}分{duration % 60}秒')
print()
print('## Shownotes')
print()
print(desc if desc else shownotes)
" <<< "$PAGE_HTML" > "${OUTPUT_DIR}/${SAFE_TITLE}_shownotes.md"

echo "Shownotes 已保存到：${OUTPUT_DIR}/${SAFE_TITLE}_shownotes.md"
```

### 第 3 步：下载音频

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

### 第 4 步：Whisper 生成完整逐字稿

使用 OpenAI Whisper 对下载的音频进行本地语音识别，生成完整的逐字稿。

```bash
# Whisper 转录（与 video-downloader 的字幕提取方式一致）
echo "正在用 Whisper 生成逐字稿..."
whisper "$AUDIO_FILE" \
  --model small \
  --language zh \
  --initial_prompt "以下是普通话的句子。" \
  --output_format txt \
  --output_dir "$OUTPUT_DIR"

echo "逐字稿已保存到：${OUTPUT_DIR}/${SAFE_TITLE}.txt"
```

**Whisper 模型选择**：

| 模型 | 大小 | 速度 | 精度 | 推荐场景 |
|------|------|------|------|----------|
| `tiny` | 39M | 最快 | 一般 | 快速预览 |
| `base` | 74M | 快 | 一般 | 快速预览 |
| `small` | 244M | 中等 | 较好 | **默认推荐** |
| `medium` | 769M | 慢 | 好 | 长播客、多人对话 |
| `large` | 1550M | 最慢 | 最好 | 需要最高精度 |

**关键参数说明**：
- `--language zh`：指定中文
- `--initial_prompt "以下是普通话的句子。"`：引导输出简体中文（不加则可能输出繁体）
- `--output_format txt`：纯文本。可改为 `srt`（带时间戳字幕）或 `all`（所有格式）

**如需带时间戳的逐字稿**（SRT 格式）：
```bash
whisper "$AUDIO_FILE" \
  --model small \
  --language zh \
  --initial_prompt "以下是普通话的句子。" \
  --output_format srt \
  --output_dir "$OUTPUT_DIR"
```

## 完整输出文件

执行完成后，`~/Downloads` 目录下会有：

```
~/Downloads/
├── {标题}.m4a              # 音频文件
├── {标题}_shownotes.md     # 播主撰写的 Shownotes（秒级完成）
└── {标题}.txt              # Whisper 生成的完整逐字稿（需等待转录）
```

## 注意事项

- 音频托管在 `media.xyzcdn.net`，无需登录即可下载
- 音频格式通常为 m4a，部分为 mp3
- 页面返回"找不到了"说明链接已失效
- Whisper 首次运行会下载模型文件（small 约 244MB），之后会缓存
- 30 分钟播客用 `small` 模型大约需要 3-5 分钟转录（Apple Silicon Mac）
- `--initial_prompt "以下是普通话的句子。"` 是确保输出简体中文的关键参数
