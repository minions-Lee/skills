---
name: ui-reference-to-code
description: |
  从高质量 UI/UX 参考网站搜索设计灵感，爬取截图，通过 Codia API 转换为 Figma 可编辑设计，
  最终生成一个「UI 风格 Skill」——包含设计 token、布局模式、组件代码示例的独立 skill 目录。
  这个 skill 可被任何项目链接使用，让 Claude Code 按照该风格生成 UI 代码。
  完整链路：需求描述 → 搜索参考 → 用户选择 → 爬取截图 → Codia 转 Figma →
  用户审核 → 输出 UI 风格 Skill。
  触发词：UI 参考生成代码、设计参考转代码、找 UI 生成代码、UI to code、
  design reference to code、从设计图生成代码、参考 App 出码、生成 UI 风格 skill。
author: Claude Code
version: 2.0.0
date: 2026-02-19
tags: ["ui", "ux", "design", "figma", "code-generation", "codia", "screenshot-to-code", "skill-output"]
---

# UI 参考 → Figma 设计 → UI 风格 Skill

从顶级 App/网站的真实 UI 截图出发，经 Codia AI 转为可编辑 Figma 设计（可人工微调），
最终产出一个**独立的 UI 风格 Skill 目录**。

**核心理念**：本 skill 不直接修改任何工程代码。它的产物是一个 skill，
该 skill 包含设计 token、布局规范、组件代码示例。
用户在具体项目中链接这个 skill 后，Claude Code 即可按照该风格生成 UI 代码。

## 环境变量配置

在使用前，用户需设置以下环境变量（在 `~/.zshrc` 或 `~/.bashrc` 中添加）：

```bash
export CODIA_API_KEY="sk-xxxxx"   # Codia API Key，从 https://developer.codia.ai/ 获取
```

## 触发条件

- "帮我找个 XX 风格的 UI，生成代码"
- "我要做一个 XX 项目，找设计参考出码"
- "参考 XX App 的设计生成 UI 风格 skill"
- "暗黑风格 Dashboard UI 转代码"
- "生成一个 Linear 风格的 UI skill"

---

## 工作流程

### Step 1: 需求澄清

用 AskUserQuestion 一次性问清楚所有关键信息：

**问题 1 — 项目类型**（必问）
```
你的项目是什么类型？
选项：SaaS/Dashboard、电商、社交、内容/媒体、工具/效率、金融、其他（用户自填）
```

**问题 2 — 目标平台**（必问）
```
目标平台是什么？
选项：Web 响应式、Mobile App (iOS/Android)、Desktop App、Web + Mobile 都要
```

**问题 3 — 技术栈**（必问）
```
前端技术栈？
选项：React + Tailwind (推荐)、Vue + Tailwind、Next.js + Tailwind、HTML + Tailwind、React Native (Mobile)
```

**问题 4 — 设计风格**（可选，用户可在需求描述中已提及）

如果用户在初始描述中已提供了部分信息（如"暗黑风格 Dashboard"），则跳过已知项，只问缺失的。

将用户需求整理为结构化搜索条件：

```
项目类型: SaaS Dashboard
平台: Web
技术栈: React + Tailwind
风格关键词: dark mode, minimal, data-heavy
```

---

### Step 2: 搜索 UI 参考

从以下 **3-5 个高质量站点** 并行搜索，每个站点取 2-3 个最匹配结果，合计 5-10 个：

#### 搜索来源（按质量排序）

| 优先级 | 来源 | 搜索方式 | 内容类型 |
|--------|------|---------|---------|
| 1 | **Mobbin** | `WebSearch "site:mobbin.com {关键词}"` | 真实 App 截图，可爬取 |
| 2 | **Dribbble** | `WebSearch "site:dribbble.com {关键词}"` | 设计师概念作品 |
| 3 | **Behance** | `WebSearch "site:behance.net {关键词}"` | 完整 Case Study |
| 4 | **Awwwards** | `WebSearch "site:awwwards.com {关键词}"` | 获奖网站，Web 端为主 |
| 5 | **SaaS Design** | `WebSearch "site:saasdesign.io {关键词}"` | SaaS 专属（仅 SaaS 类项目） |

#### 搜索关键词构造

将用户需求翻译为英文搜索词，组合搜索：

```
核心词: {项目类型} + {风格}
平台词: ios / android / web / responsive
修饰词: UI design, app design, dashboard, dark mode 等

示例: "site:mobbin.com dark dashboard data analytics ios"
```

**重要：必须用并行 tool call 同时搜索所有来源。**

#### 结果展示

用表格展示搜索结果，每个结果包含：

```markdown
## 找到 {N} 个匹配的 UI 参考

| # | 来源 | 项目/App 名称 | 风格匹配度 | 链接 |
|---|------|-------------|-----------|------|
| 1 | Mobbin | Spotify iOS | ★★★ 暗黑+音乐 | [查看](url) |
| 2 | Dribbble | Dashboard Concept | ★★★ 暗黑+数据 | [查看](url) |
| 3 | Behance | Analytics App | ★★☆ 暗黑+图表 | [查看](url) |
...

请查看每个链接，选择最合适的编号（可多选）。
```

---

### Step 3: 用户选择

用 AskUserQuestion 让用户选择：

```
你看完了吗？选择最合适的参考（可多选）：
选项：#1 {名称}、#2 {名称}、#3 {名称}、... 、都不合适（重新搜索）
```

如果用户选"都不合适"，回到 Step 2 换关键词重搜。

---

### Step 4: 爬取截图

根据用户选择的参考，爬取高清 UI 截图。

#### 4.1 Mobbin 来源

Mobbin 每个独立屏幕页的 OG meta 标签中包含该屏幕的真实图片 UUID。

**推荐提取流程（按屏幕页逐个提取，避免拿到推荐列表的脏数据）：**

```python
import subprocess, re, json

screen_ids = [
    ("screen-uuid-1", "Screen Name 1"),
    ("screen-uuid-2", "Screen Name 2"),
    # ... 从 WebSearch 结果中提取的 /explore/screens/{uuid} 路径
]

results = []
for screen_id, name in screen_ids:
    url = f"https://mobbin.com/explore/screens/{screen_id}"
    r = subprocess.run(
        ["curl", "-s", "-H", "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", url],
        capture_output=True, text=True, timeout=30
    )
    # 从 OG image meta 标签提取 app_screens/{uuid}
    og_match = re.search(
        r'app_screens(?:%2F|/)([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
        r.stdout
    )
    if og_match:
        image_id = og_match.group(1)
        results.append({
            'screenId': screen_id,
            'imageId': image_id,
            'name': name,
            'cdn_url': f"https://bytescale.mobbin.com/FW25bBB/image/mobbin.com/prod/content/app_screens/{image_id}.png?f=png&w=1920&q=85&fit=shrink-cover"
        })
```

**CDN URL 格式：**
- Bytescale（CDN 加速）: `https://bytescale.mobbin.com/FW25bBB/image/mobbin.com/prod/content/app_screens/{imageId}.png?f=png&w=1920&q=85&fit=shrink-cover`
- Supabase（原始）: `https://ujasntkfphywizsdaapi.supabase.co/storage/v1/object/public/content/app_screens/{imageId}.png`

**关键注意事项：**
- 每个屏幕页面嵌入了约 20 张「相似推荐」截图，这些是其他 App 的截图，不是目标 App 的
- 仅 OG meta 标签中的 `app_screens/{uuid}` 才是当前屏幕的真实图片
- 必须带 User-Agent 请求头
- Mobbin ToS 禁止爬取，此 skill 仅供个人学习参考使用

#### 4.2 Dribbble / Behance / Awwwards 来源

这些站点的图片通常可通过 WebFetch 或直接从页面 HTML 中提取 `<img>` 标签的 `src` 属性。

```bash
# Dribbble: 图片通常在 CDN
# 格式: https://cdn.dribbble.com/userupload/xxxxx/file/original-xxxxx.png

# Behance: 图片在 Adobe CDN
# 格式: https://mir-s3-cdn-cf.behance.net/project_modules/max_1200/xxxxx.jpg
```

降级方案：如果 WebFetch 被阻止，可用 Chrome DevTools MCP（如已配置）进行浏览器自动化截图。

#### 4.3 截图确认

下载完成后，**用 Read 工具打开截图文件让 Claude 看到图片内容**，逐张确认是否是目标 App 的截图（而非其他推荐 App）。展示确认结果：

```
已下载并确认 {N} 张 {App名} 截图：
- 01-dark-mode-app.png (1920x1080) ✓ 确认是 Linear 主界面
- 02-command-menu.png (1920x1080) ✓ 确认是 Linear 命令面板
- ...

继续调用 Codia 转换为 Figma 设计？
```

---

### Step 5: Codia API → Figma 设计 + 审核 ✋

#### 5.1 调用 Codia API

对每张截图调用 Codia 的图像转设计 API：

```bash
source ~/.zshrc  # 加载 CODIA_API_KEY

curl -s -X POST "https://api.codia.ai/v1/open/image_to_design" \
  -H "Authorization: Bearer ${CODIA_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://bytescale.mobbin.com/FW25bBB/image/mobbin.com/prod/content/app_screens/{imageId}.png?f=png&w=1920&q=85&fit=shrink-cover"
  }' > /tmp/ui-ref-screens/design-{imageId}.json
```

**Codia API 返回格式：** JSON Schema Object，包含：
- 图层树结构（layer hierarchy）
- 每个元素的精确尺寸、位置（x, y, width, height）
- 颜色值（#hex）
- 字体信息（font-family, size, weight）
- 间距和对齐（padding, margin, alignment）

#### 5.2 分析设计结构

从 Codia JSON + 原始截图（多模态视觉分析）中提取设计系统：

```markdown
## Codia 转换结果

### 截图 1: 首页
- 识别了 {N} 个图层
- 主色调: #1B1C1F, #18191C, #2B2D31
- 字体: SF Pro Display (标题), SF Pro Text (正文)
- 布局: 左侧边栏 240px + 主内容 flex + 右侧详情 360px
- 关键组件: 导航列表、搜索框、分组列表、状态指示器

### 截图 2: 详情页
- ...

⚠️ 请审核以上结构是否符合预期。
```

#### 5.3 用户审核

用 AskUserQuestion 确认：

```
Codia 转换的设计结构正确吗？
选项：
  - 确认，开始生成 UI 风格 Skill
  - 基本正确，有小问题但可以接受
  - 结构有问题，换一个参考图重来
  - 我需要在 Figma 中手动调整后再继续（暂停，等我调整完告诉你）
```

---

### Step 6: 生成 UI 风格 Skill ⭐

**这是核心产出步骤。** 不直接修改任何工程代码，而是生成一个独立的 skill 目录。

#### 6.1 产出物结构

在 `/Users/eamanc/Documents/pe/skills/` 下创建新的 skill 目录：

```
{style-name}-ui-style/
├── SKILL.md                    # UI 风格 Skill 主文件
├── references/
│   ├── screenshots/            # 原始截图（供开发时视觉对照）
│   │   ├── 01-main-view.png
│   │   ├── 02-detail-view.png
│   │   └── ...
│   ├── codia-designs/          # Codia 设计 JSON（精确数值参考）
│   │   ├── 01-main-view.json
│   │   └── 02-detail-view.json
│   └── design-tokens.json      # 提取的设计 token 汇总
```

#### 6.2 SKILL.md 内容模板

生成的 UI 风格 Skill 的 SKILL.md 必须包含以下部分：

```markdown
---
name: {style-name}-ui-style
description: |
  {风格名称} UI 风格指南。基于 {参考来源 App 名} 的设计语言，
  提供完整的设计 token、布局规范和 {技术栈} 组件代码示例。
  当需要按照此风格生成 UI 时使用此 skill。
  触发词：{风格名} 风格、{参考App名} 风格、{关键词}。
tags: ["ui-style", "{style-keyword}", "{tech-stack}"]
---

# {风格名称} UI 风格指南

基于 {参考 App 名} 的设计语言提炼。适用于 {项目类型} 类项目的 {平台} 端。

## 设计来源

- 参考 App: {App名}
- 来源: {Mobbin/Dribbble/Behance}
- 截图数量: {N} 张
- 原始截图路径: `./references/screenshots/`
- Codia 设计 JSON: `./references/codia-designs/`

---

## 1. 色彩系统

### CSS 变量定义

（从 Codia JSON + 截图视觉分析中提取精确色值）

\```css
:root {
  /* 背景层级 */
  --color-bg:             {#hex};  /* 最底层背景 */
  --color-surface:        {#hex};  /* 卡片/面板背景 */
  --color-surface-hover:  {#hex};  /* 悬浮态 */
  --color-surface-active: {#hex};  /* 选中/激活态 */

  /* 边框 */
  --color-border:         {#hex};  /* 默认边框 */
  --color-border-subtle:  {#hex};  /* 更淡的边框 */

  /* 文字层级 */
  --color-text:           {#hex};  /* 主文字 */
  --color-text-secondary: {#hex};  /* 次要文字 */
  --color-text-muted:     {#hex};  /* 弱化文字 */

  /* 语义色 */
  --color-accent:         {#hex};  /* 品牌强调色 */
  --color-success:        {#hex};
  --color-warning:        {#hex};
  --color-danger:         {#hex};
}
\```

### Tailwind 主题扩展

\```typescript
// tailwind.config.ts 或 CSS @theme 块
const theme = {
  colors: {
    bg:      '{#hex}',
    surface: '{#hex}',
    // ...
  }
}
\```

---

## 2. 字体系统

| 用途 | 字体族 | 大小 | 字重 | 行高 | 字间距 |
|------|--------|------|------|------|--------|
| 标题 H1 | {font} | {px} | {weight} | {lh} | {ls} |
| 标题 H2 | {font} | {px} | {weight} | {lh} | {ls} |
| 正文 | {font} | {px} | {weight} | {lh} | {ls} |
| 辅助文字 | {font} | {px} | {weight} | {lh} | {ls} |
| 标签/徽章 | {font} | {px} | {weight} | {lh} | {ls} |

---

## 3. 间距与圆角

| Token | 值 | 用途 |
|-------|-----|------|
| spacing-xs | {px} | 元素内紧凑间距 |
| spacing-sm | {px} | 按钮内边距 |
| spacing-md | {px} | 卡片内边距 |
| spacing-lg | {px} | 区块间距 |
| radius-sm | {px} | 按钮、输入框 |
| radius-md | {px} | 卡片 |
| radius-lg | {px} | 弹窗 |

---

## 4. 布局模式

### 4.1 整体布局

（描述整体页面结构，附代码示例）

\```tsx
// 示例：三栏布局（参考截图 01）
export function AppLayout({ sidebar, main, detail }) {
  return (
    <div className="flex h-screen bg-[var(--color-bg)]">
      <aside className="w-[240px] border-r border-[var(--color-border)] bg-[var(--color-surface)]">
        {sidebar}
      </aside>
      <main className="flex-1 overflow-y-auto">
        {main}
      </main>
      <aside className="w-[360px] border-l border-[var(--color-border)] bg-[var(--color-surface)]">
        {detail}
      </aside>
    </div>
  );
}
\```

### 4.2 侧边栏导航

（描述导航项样式，附代码示例）

### 4.3 列表/卡片

（描述列表行或卡片的结构，附代码示例）

---

## 5. 组件代码示例

为每个关键 UI 模式提供 **完整可运行的 {技术栈} 代码**：

### 5.1 导航项

\```tsx
// NavItem.tsx — 参考截图中的侧边栏导航
function NavItem({ icon, label, active, onClick }) {
  return (
    <button
      onClick={onClick}
      className={`flex items-center gap-2.5 px-2.5 py-[7px] rounded-md text-[13px]
        font-medium transition-colors w-full text-left
        ${active
          ? 'bg-[var(--color-surface-active)] text-[var(--color-text)]'
          : 'text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-hover)]'
        }`}
    >
      {icon}
      {label}
    </button>
  );
}
\```

### 5.2 列表行 / 卡片

（代码示例）

### 5.3 搜索/过滤栏

（代码示例）

### 5.4 状态指示器

（代码示例）

### 5.5 弹窗/下拉菜单

（代码示例，如果截图中有相关模式）

---

## 6. 交互模式

- 悬浮: {描述悬浮效果}
- 选中: {描述选中状态}
- 过渡: {描述 transition 参数}
- 快捷键: {如果参考 App 有 Cmd+K 等模式，在此描述}

---

## 使用方式

1. 将此 skill 链接到目标项目：
   \```bash
   ln -s /path/to/{style-name}-ui-style <project>/.claude/skills/{style-name}-ui-style
   \```
2. 在项目中告诉 Claude Code："按照 {风格名} 风格生成 XX 页面/组件"
3. Claude Code 会参考本 skill 中的设计 token 和代码示例生成代码
```

#### 6.3 design-tokens.json

同时生成一份机器可读的 token 文件：

```json
{
  "source": "{App名}",
  "platform": "{Web/iOS/Android}",
  "techStack": "{React + Tailwind}",
  "colors": {
    "bg": "#hex",
    "surface": "#hex",
    "surfaceHover": "#hex",
    "surfaceActive": "#hex",
    "border": "#hex",
    "text": "#hex",
    "textSecondary": "#hex",
    "textMuted": "#hex",
    "accent": "#hex",
    "success": "#hex",
    "warning": "#hex",
    "danger": "#hex"
  },
  "typography": {
    "fontFamily": "...",
    "heading": { "size": "px", "weight": "number", "lineHeight": "number" },
    "body": { "size": "px", "weight": "number", "lineHeight": "number" },
    "small": { "size": "px", "weight": "number", "lineHeight": "number" }
  },
  "spacing": { "xs": "px", "sm": "px", "md": "px", "lg": "px", "xl": "px" },
  "radius": { "sm": "px", "md": "px", "lg": "px" }
}
```

#### 6.4 链接 Skill

生成完毕后，提示用户链接：

```
UI 风格 Skill 已生成：/Users/eamanc/Documents/pe/skills/{style-name}-ui-style/

包含：
- SKILL.md（设计 token + 布局规范 + {N} 个组件代码示例）
- references/screenshots/（{M} 张原始截图）
- references/codia-designs/（{M} 份 Codia 设计 JSON）
- references/design-tokens.json（机器可读 token）

是否立即链接到用户级 skill？
```

如果用户确认，执行：
```bash
ln -s /Users/eamanc/Documents/pe/skills/{style-name}-ui-style ~/.claude/skills/{style-name}-ui-style
```

---

## 搜索来源详细配置

### Mobbin 爬取技术细节

**页面结构**：Next.js App Router + React Server Components
**截图存储**：
- CDN: Bytescale (`bytescale.mobbin.com/FW25bBB/image/...`)
- 原始: Supabase Storage (`ujasntkfphywizsdaapi.supabase.co/storage/v1/object/public/...`)

**关键经验（2026-02 实测）：**
- Mobbin 页面内嵌约 20 张 `app_screens` UUID，但其中绝大部分是「相似推荐」的其他 App 截图
- 只有 `<meta property="og:image">` 中的 `app_screens/{uuid}` 才是当前屏幕的真实图片
- 必须逐页面提取 OG 标签，不能批量提取页面内所有 UUID
- Bytescale CDN 支持参数调整：`?f=png&w={width}&q={quality}&fit=shrink-cover`
- 必须带 User-Agent 请求头

### Codia API 配置

- **端点**: `POST https://api.codia.ai/v1/open/image_to_design`
- **认证**: `Authorization: Bearer {CODIA_API_KEY}`
- **输入**: JSON body `{"image_url": "https://..."}`
- **输出**: JSON Schema Object（设计图层树）
- **限流**: 取决于账户计划
- **402 错误**: 额度用完，降级到 Claude Vision 直接分析截图

---

## 降级策略

| 失败环节 | 降级方案 |
|---------|---------|
| Mobbin 爬取失败 | 改用 WebSearch 搜索替代站点的截图 |
| Codia API 失败/额度用完 | 直接用 Claude Vision 分析截图提取设计 token（跳过 Codia，精度略降但流程不中断） |
| 截图质量不佳 | 尝试更高分辨率（w=1920）或换 Supabase 原始 URL |
| 整个 Codia + Vision 都不可用 | 手动分析截图，输出纯文字描述的风格规范（无精确数值） |

**降级时的 Skill 质量标记：**
- Codia 转换成功：在 SKILL.md 标注 `precision: high（Codia API 精确提取）`
- Claude Vision 降级：标注 `precision: medium（Claude Vision 视觉估算）`
- 纯手动分析：标注 `precision: low（人工视觉估算，建议对照截图微调）`

## 报告输出

搜索和转换过程的报告默认保存到 `/Users/eamanc/Documents/pe/jixiaxuegong/reports/` 目录下，
文件命名格式：`ui-ref-{项目名}-{YYYY-MM-DD}.md`。除非用户明确指定了其他存放地址。

---

## 示例

### 示例 1: Linear 暗黑风格 Skill

**用户**: "我要做一个 Skill 管理桌面工具，参考 Linear 暗黑风格"

**Step 1 澄清**:
- 项目类型: 工具/效率
- 平台: Desktop App (Tauri)
- 技术栈: React + Tailwind
- 风格: dark mode, minimal, Linear-style

**Step 2 搜索**:
```
WebSearch "site:mobbin.com linear web dark mode screens"
WebSearch "site:dribbble.com linear app dark UI design"
```

**Step 3**: 用户选择 Mobbin 上的 Linear Web

**Step 4**: 逐页提取 OG 标签，下载 10 张 Linear Web 暗黑截图

**Step 5**: Codia 转换 → 展示设计 token + 布局结构 → 用户确认

**Step 6**: 生成 `linear-dark-ui-style/` skill 目录：

```
linear-dark-ui-style/
├── SKILL.md                      # 包含完整色彩系统、字体规范、6 个组件代码示例
├── references/
│   ├── screenshots/              # 10 张 Linear 原始截图
│   ├── codia-designs/            # 10 份 Codia JSON
│   └── design-tokens.json        # 提取的设计 token
```

用户在 SkillPilot 项目中链接此 skill 后，只需说"按照 Linear 暗黑风格生成侧边栏"，
Claude Code 就会参考 skill 中的代码示例和设计 token 生成代码。
