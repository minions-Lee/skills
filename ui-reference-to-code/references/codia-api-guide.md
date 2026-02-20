# Codia API 技术指南

## 认证配置

### 环境变量

```bash
# 在 ~/.zshrc 或 ~/.bashrc 中添加
export CODIA_API_KEY="sk-xxxxx"
```

### API Key 获取

1. 访问 https://developer.codia.ai/
2. 注册/登录
3. 创建 API Key
4. 复制 `sk-` 开头的密钥

---

## API 端点

### 1. 图像转设计（核心）

```
POST https://api.codia.ai/v1/open/image_to_design
```

**请求头：**
```
Authorization: Bearer {CODIA_API_KEY}
Content-Type: application/json
```

**请求体：**
```json
{
  "image_url": "https://example.com/screenshot.png"
}
```

**curl 示例：**
```bash
curl -s -X POST "https://api.codia.ai/v1/open/image_to_design" \
  -H "Authorization: Bearer ${CODIA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"image_url\": \"${IMAGE_URL}\"}"
```

**响应格式：** JSON Schema Object

包含：
- `layers[]` — 图层数组，每个图层包含：
  - `type` — 类型（frame, text, rectangle, image, group 等）
  - `name` — 图层名称
  - `x`, `y`, `width`, `height` — 位置和尺寸
  - `fills[]` — 填充颜色
  - `strokes[]` — 描边
  - `effects[]` — 阴影、模糊等效果
  - `children[]` — 子图层（递归结构）
  - `style` — 文字样式（fontSize, fontFamily, fontWeight, lineHeight 等）

### 2. PDF 转设计

```
POST https://api.codia.ai/v1/open/pdf_to_design
```

**请求体（multipart/form-data）：**
```bash
curl -s -X POST "https://api.codia.ai/v1/open/pdf_to_design" \
  -H "Authorization: Bearer ${CODIA_API_KEY}" \
  --form 'pdf_file=@"design.pdf"' \
  --form 'page_no=[0, 1]'
```

### 3. 背景移除

```
POST https://api.codia.ai/v1/open/remove_bg
```

---

## 批量处理脚本

```bash
#!/bin/bash
# batch-convert.sh — 批量将截图转为 Codia 设计 JSON

INPUT_DIR="${1:-.}"
OUTPUT_DIR="${2:-./codia-output}"

mkdir -p "$OUTPUT_DIR"

for img in "$INPUT_DIR"/*.png; do
    filename=$(basename "$img" .png)
    echo "Converting: $filename"

    # 如果图片是本地文件，需要先上传获取 URL
    # 如果已经有 CDN URL，直接使用

    curl -s -X POST "https://api.codia.ai/v1/open/image_to_design" \
      -H "Authorization: Bearer ${CODIA_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "{\"image_url\": \"${CDN_BASE_URL}/${filename}.png\"}" \
      > "$OUTPUT_DIR/${filename}.json"

    echo "  → $OUTPUT_DIR/${filename}.json"

    # 避免 rate limiting
    sleep 2
done

echo "Done! Converted $(ls "$OUTPUT_DIR"/*.json | wc -l) files."
```

---

## 设计 JSON → 代码转换映射

| Codia 图层类型 | 对应 HTML/React 元素 | Tailwind 映射 |
|--------------|-------------------|-------------|
| frame | `<div>` | flex/grid + padding |
| text | `<p>` / `<h1>-<h6>` / `<span>` | text-{size} font-{weight} |
| rectangle | `<div>` | bg-{color} rounded-{radius} |
| image | `<img>` | object-cover/contain |
| group | `<div>` | relative + children absolute |
| vector | `<svg>` | inline SVG |

### 颜色映射示例

```typescript
// 从 Codia JSON 提取的颜色 → Tailwind 自定义主题
const theme = {
  colors: {
    primary: '#1A1A2E',    // fills[0].color
    secondary: '#16213E',
    accent: '#0F3460',
    text: '#E4E4E4',
    muted: '#8B8B8B',
  }
}
```

### 间距映射示例

```typescript
// Codia 的 px 值 → Tailwind spacing
// 4px → p-1, 8px → p-2, 12px → p-3, 16px → p-4
// 20px → p-5, 24px → p-6, 32px → p-8
```
