# UI 截图爬取模式

各来源站点的截图提取技术细节。

---

## 1. Mobbin

### 数据架构

- **前端框架**: Next.js App Router + React Server Components
- **数据库**: Supabase (PostgreSQL)
- **图片存储**: Supabase Storage + Bytescale CDN
- **数据传输**: RSC payload 嵌入 HTML

### URL 结构

```
应用页面: https://mobbin.com/apps/{app-slug}-{app-id}/{version-id}/screens
截图 CDN: https://bytescale.mobbin.com/FW25bBB/image/mobbin.com/prod/content/app_screens/{image-id}.png
截图原始: https://ujasntkfphywizsdaapi.supabase.co/storage/v1/object/public/content/app_screens/{image-id}.png
App Logo: https://ujasntkfphywizsdaapi.supabase.co/storage/v1/object/public/content/app_logos/{logo-id}.webp
```

### CDN 参数

| 参数 | 说明 | 推荐值 |
|------|------|-------|
| `f` | 输出格式 | `png` |
| `w` | 宽度 | `750`（标准）/ `1920`（高清） |
| `q` | 质量 | `80` |
| `fit` | 适配方式 | `shrink-cover` |

### 提取脚本

```python
import re

def extract_mobbin_screens(html_content):
    """从 Mobbin 页面 HTML 中提取截图数据"""

    # 方式 1: 从 RSC 数据中提取结构化信息（screenId + screenUrl + appName）
    screens = []
    for m in re.finditer(r'"screenId"\s*:\s*"([0-9a-f-]+)"', html_content):
        sid = m.group(1)
        after = html_content[m.end():m.end()+500]
        url_m = re.search(r'"screenUrl"\s*:\s*"([^"]+)"', after)
        name_m = re.search(r'"appName"\s*:\s*"([^"]+)"', after)
        tagline_m = re.search(r'"appTagline"\s*:\s*"([^"]*)"', after)

        if url_m:
            img_uuid = re.search(r'app_screens/([0-9a-f-]+)', url_m.group(1))
            screens.append({
                'screenId': sid,
                'imageId': img_uuid.group(1) if img_uuid else None,
                'appName': name_m.group(1) if name_m else None,
                'appTagline': tagline_m.group(1) if tagline_m else None,
            })

    # 方式 2: 直接提取 app_screens UUID（更宽泛）
    if not screens:
        pattern = r'app_screens(?:%2F|/|\\u002F)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'
        uuids = list(set(re.findall(pattern, html_content)))
        screens = [{'imageId': uid} for uid in uuids]

    return screens


def build_cdn_url(image_id, width=750, quality=80):
    """构建 Bytescale CDN URL"""
    return f"https://bytescale.mobbin.com/FW25bBB/image/mobbin.com/prod/content/app_screens/{image_id}.png?f=png&w={width}&q={quality}&fit=shrink-cover"
```

### 限制

- 每页约 20 张截图（RSC 推荐数据）
- 不是 App 的全部截图
- 无需登录即可获取页面内嵌的数据
- 必须带 User-Agent 头

---

## 2. Dribbble

### 图片 CDN 格式

```
原图: https://cdn.dribbble.com/userupload/{user-id}/file/original-{hash}.png
缩略: https://cdn.dribbble.com/userupload/{user-id}/file/still-{hash}.png?resize=400x300
```

### 提取方式

```
WebFetch URL: "https://dribbble.com/shots/{shot-id}"
提示: "提取页面中的设计作品图片 URL"
```

降级: `WebSearch "site:dribbble.com {keyword}"` 获取作品链接

### 限制

- WebFetch 可能因页面过大失败
- 降级为 WebSearch 获取链接

---

## 3. Behance

### 图片 CDN 格式

```
项目图: https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/{hash}.jpg
缩略图: https://mir-s3-cdn-cf.behance.net/project_modules/disp/{hash}.jpg
```

### 提取方式

```
WebFetch URL: "https://www.behance.net/gallery/{gallery-id}/{slug}"
提示: "提取项目中的所有设计图片 URL"
```

### 限制

- Behance 图片通常为展示图（含文字说明），非纯 UI 截图
- 需要从 Case Study 中筛选纯 UI 截图

---

## 4. Awwwards

### 提取方式

```
WebSearch "site:awwwards.com {keyword} web design"
```

Awwwards 展示的是真实网站链接，可以直接用浏览器截图或 Chrome DevTools MCP 自动截图。

### 限制

- 仅 Web 端设计
- 需要额外截图步骤

---

## 通用降级策略

当 WebFetch 无法获取页面内容时：

1. 尝试 `WebSearch "site:{domain} {keyword}"` 获取具体链接
2. 使用 Chrome DevTools MCP（如已配置）进行浏览器自动化
3. 提示用户手动截图并提供本地文件路径
