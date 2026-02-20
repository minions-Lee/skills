---
name: linear-dark-ui-style
description: |
  Linear 暗黑模式 UI 风格指南。基于 Linear Web App 的设计语言，
  提供完整的设计 token、布局规范和 React + Tailwind 组件代码示例。
  当需要按照 Linear 暗黑风格生成 UI 时使用此 skill。
  触发词：Linear 风格、Linear 暗黑、linear dark、暗黑极简风、
  dark minimal dashboard、项目管理风格 UI。
version: 1.0.0
date: 2026-02-19
tags: ["ui-style", "dark-mode", "linear", "minimal", "react", "tailwind"]
precision: medium (Claude Vision 视觉估算)
---

# Linear 暗黑模式 UI 风格指南

基于 Linear Web App 的设计语言提炼。适用于效率工具、项目管理、SaaS Dashboard 类项目。

## 设计来源

- 参考 App: Linear (Web 版)
- 来源: Mobbin (10 张截图)
- 截图路径: `./references/screenshots/`
- 设计 Token JSON: `./references/design-tokens.json`
- 精度: medium（Claude Vision 视觉估算，建议对照截图微调）

## 风格特征

- **中性暗黑**：纯灰色调背景，不带蓝/紫色倾向，不刺眼
- **极简克制**：最少边框，靠背景层级区分而非线条
- **紧凑信息密度**：13px 正文，42px 行高，适合数据密集场景
- **状态语义色**：橙色=进行中，灰色=待办，绿色=完成，红色=取消
- **键盘优先**：Cmd+K 命令面板、快捷键提示、极少鼠标依赖

---

## 1. 色彩系统

### CSS 变量定义

```css
:root {
  /* 背景层级（由深到浅） */
  --color-bg:             #1B1C1F;  /* 最底层背景 */
  --color-surface:        #18191C;  /* 侧边栏/面板背景 */
  --color-surface-hover:  #232428;  /* 悬浮态 */
  --color-surface-active: #2B2D31;  /* 选中/激活态 */
  --color-surface-raised: #2F3035;  /* 卡片/弹窗 */

  /* 边框 */
  --color-border:         #2E3035;  /* 默认分隔线 */
  --color-border-subtle:  #252629;  /* 更轻的分隔 */

  /* 文字层级 */
  --color-text:           #EDEDEF;  /* 主文字（标题、内容） */
  --color-text-secondary: #9B9CA0;  /* 次要文字（ID、导航） */
  --color-text-muted:     #5E5F63;  /* 弱化文字（时间、占位符） */

  /* 品牌/强调 */
  --color-accent:         #5E6AD2;  /* Linear 紫（品牌色） */
  --color-accent-hover:   #6E7AE2;
  --color-accent-dim:     #5E6AD233; /* 用于选区背景 */

  /* 语义色 */
  --color-success:        #4CB782;  /* 完成 */
  --color-warning:        #F2994A;  /* 进行中 */
  --color-danger:         #EB5757;  /* 取消/错误 */
}
```

### Tailwind CSS v4 @theme 写法

```css
@theme {
  --color-bg:             #1B1C1F;
  --color-surface:        #18191C;
  --color-surface-hover:  #232428;
  --color-surface-active: #2B2D31;
  --color-surface-raised: #2F3035;
  --color-border:         #2E3035;
  --color-border-subtle:  #252629;
  --color-text:           #EDEDEF;
  --color-text-secondary: #9B9CA0;
  --color-text-muted:     #5E5F63;
  --color-accent:         #5E6AD2;
  --color-accent-hover:   #6E7AE2;
  --color-success:        #4CB782;
  --color-warning:        #F2994A;
  --color-danger:         #EB5757;
}
```

### 状态色映射

| 状态 | 颜色 | 图标形态 | 用途 |
|------|------|---------|------|
| In Progress | `#F2994A` 橙 | 半填充圆 | 进行中的任务 |
| Todo | `#9B9CA0` 灰 | 空心圆 | 待办事项 |
| Backlog | `#5E5F63` 暗灰 | 虚线圆 | 积压 |
| Done | `#4CB782` 绿 | 实心勾圆 | 已完成 |
| Cancelled | `#EB5757` 红 | 实心叉圆 | 已取消 |

---

## 2. 字体系统

```css
body {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display",
               "Helvetica Neue", sans-serif;
  font-size: 13px;
  line-height: 1.5;
  letter-spacing: -0.01em;
  -webkit-font-smoothing: antialiased;
}
```

| 用途 | 大小 | 字重 | 行高 | 字间距 | 示例 |
|------|------|------|------|--------|------|
| 页面标题 | 14px | 600 (semibold) | 1.4 | -0.01em | "Active issues" |
| 正文/导航 | 13px | 500 (medium) | 1.5 | -0.01em | 导航项、列表标题 |
| 正文/内容 | 13px | 400 (regular) | 1.5 | -0.01em | Issue 标题 |
| 辅助文字 | 12px | 400 | 1.4 | 0 | 日期、计数 |
| 标签/分类 | 11px | 500 | 1.3 | 0.03em, uppercase | 分区标题 |

---

## 3. 间距与圆角

| Token | 值 | 用途 |
|-------|-----|------|
| `gap-1` / 4px | 图标与文字间距 |
| `gap-1.5` / 6px | 紧凑元素间距 |
| `gap-2` / 8px | 列表行内部间距 |
| `gap-3` / 12px | 区块内部间距 |
| `p-2.5` / 10px | 导航项内边距 |
| `p-3` / 12px | 卡片内边距 |
| `p-4` / 16px | 区域内边距 |
| `rounded-md` / 6px | 按钮、输入框、导航项 |
| `rounded-lg` / 8px | 卡片、弹窗 |

---

## 4. 布局模式

### 4.1 整体布局（参考截图 01-dark-mode-app）

三栏结构：固定侧边栏 + 弹性主区域 + 可折叠详情面板。

```tsx
interface AppLayoutProps {
  sidebar: React.ReactNode;
  main: React.ReactNode;
  detail?: React.ReactNode;
}

export function AppLayout({ sidebar, main, detail }: AppLayoutProps) {
  return (
    <div className="flex h-screen bg-[var(--color-bg)] text-[var(--color-text)]">
      {/* 侧边栏 */}
      <aside className="w-[210px] shrink-0 flex flex-col border-r border-[var(--color-border)] bg-[var(--color-surface)]">
        {sidebar}
      </aside>

      {/* 主内容区 */}
      <main className="flex-1 min-w-0 overflow-y-auto">
        {main}
      </main>

      {/* 详情面板（可选） */}
      {detail && (
        <aside className="w-[360px] shrink-0 border-l border-[var(--color-border)] bg-[var(--color-surface)] overflow-y-auto">
          {detail}
        </aside>
      )}
    </div>
  );
}
```

### 4.2 Tauri/Electron 桌面应用变体

增加沉浸式标题栏拖拽区域：

```tsx
export function DesktopAppLayout({ sidebar, main, detail }: AppLayoutProps) {
  return (
    <div className="flex flex-col h-screen bg-[var(--color-bg)] text-[var(--color-text)]">
      {/* 标题栏（macOS 沉浸式） */}
      <header
        data-tauri-drag-region
        className="h-[38px] shrink-0 flex items-center justify-center border-b border-[var(--color-border)]"
      >
        <div className="w-[70px] shrink-0" /> {/* traffic lights 占位 */}
        <span className="flex-1 text-center text-[12px] font-medium text-[var(--color-text-muted)] select-none pointer-events-none">
          AppName
        </span>
        <div className="w-[70px] shrink-0" />
      </header>

      {/* 三栏内容 */}
      <div className="flex flex-1 min-h-0">
        <aside className="w-[210px] shrink-0 flex flex-col border-r border-[var(--color-border)] bg-[var(--color-surface)] overflow-y-auto">
          {sidebar}
        </aside>
        <main className="flex-1 min-w-0 overflow-y-auto">
          {main}
        </main>
        {detail && (
          <aside className="w-[360px] shrink-0 border-l border-[var(--color-border)] bg-[var(--color-surface)] overflow-y-auto">
            {detail}
          </aside>
        )}
      </div>
    </div>
  );
}
```

---

## 5. 组件代码示例

### 5.1 侧边栏导航项（参考截图 01, 04）

Linear 的导航项：左侧图标 + 文字，选中态用浅灰背景，不用高亮边框。

```tsx
interface NavItemProps {
  icon: React.ReactNode;
  label: string;
  active?: boolean;
  count?: number;
  onClick?: () => void;
}

export function NavItem({ icon, label, active, count, onClick }: NavItemProps) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center gap-2.5 w-full px-2.5 py-[7px] rounded-md
        text-[13px] font-medium transition-colors duration-100 cursor-default text-left
        ${active
          ? "bg-[var(--color-surface-active)] text-[var(--color-text)]"
          : "text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-hover)] hover:text-[var(--color-text)]"
        }`}
    >
      <span className="shrink-0 w-4 h-4 flex items-center justify-center opacity-70">
        {icon}
      </span>
      <span className="flex-1 truncate">{label}</span>
      {count !== undefined && (
        <span className="text-[12px] text-[var(--color-text-muted)] tabular-nums">{count}</span>
      )}
    </button>
  );
}
```

### 5.2 可折叠分区标题（参考截图 01, 04 侧边栏分区）

```tsx
interface SectionHeaderProps {
  label: string;
  count?: number;
  expanded: boolean;
  onToggle: () => void;
}

export function SectionHeader({ label, count, expanded, onToggle }: SectionHeaderProps) {
  return (
    <button
      type="button"
      onClick={onToggle}
      className="flex items-center gap-1.5 w-full px-3 py-1.5 text-[11px]
        font-medium uppercase tracking-wider text-[var(--color-text-muted)]
        hover:text-[var(--color-text-secondary)] transition-colors"
    >
      <svg
        viewBox="0 0 16 16"
        fill="currentColor"
        className={`w-3 h-3 shrink-0 transition-transform duration-150 ${expanded ? "rotate-90" : ""}`}
      >
        <path fillRule="evenodd" d="M6.22 4.22a.75.75 0 0 1 1.06 0l3.25 3.25a.75.75 0 0 1 0 1.06l-3.25 3.25a.75.75 0 0 1-1.06-1.06L8.94 8 6.22 5.28a.75.75 0 0 1 0-1.06Z" clipRule="evenodd" />
      </svg>
      <span>{label}</span>
      {count !== undefined && (
        <span className="ml-auto text-[10px] tabular-nums opacity-60">{count}</span>
      )}
    </button>
  );
}
```

### 5.3 列表行（参考截图 01 的 Issue 行）

Linear 的列表行是扁平的：状态图标 + ID + 标题 + 标签 + 日期 + 头像。

```tsx
interface ListRowProps {
  id: string;
  title: string;
  status: "todo" | "inProgress" | "done" | "cancelled" | "backlog";
  labels?: { text: string; color: string }[];
  date?: string;
  selected?: boolean;
  onClick?: () => void;
}

const statusConfig = {
  todo:       { color: "#9B9CA0", icon: "○" },
  inProgress: { color: "#F2994A", icon: "◐" },
  done:       { color: "#4CB782", icon: "✓" },
  cancelled:  { color: "#EB5757", icon: "✕" },
  backlog:    { color: "#5E5F63", icon: "◌" },
};

export function ListRow({ id, title, status, labels, date, selected, onClick }: ListRowProps) {
  const cfg = statusConfig[status];
  return (
    <div
      role="button"
      tabIndex={0}
      onClick={onClick}
      className={`flex items-center gap-3 h-[42px] px-4 cursor-default transition-colors duration-100
        ${selected ? "bg-[var(--color-surface-active)]" : "hover:bg-[var(--color-surface-hover)]"}`}
    >
      {/* 状态指示器 */}
      <span
        className="shrink-0 w-4 h-4 flex items-center justify-center text-[12px]"
        style={{ color: cfg.color }}
      >
        {cfg.icon}
      </span>

      {/* ID */}
      <span className="shrink-0 w-[60px] text-[13px] text-[var(--color-text-muted)] tabular-nums">
        {id}
      </span>

      {/* 标题 */}
      <span className="flex-1 text-[13px] text-[var(--color-text)] truncate">
        {title}
      </span>

      {/* 标签 */}
      {labels?.map((l) => (
        <span
          key={l.text}
          className="shrink-0 px-1.5 py-px rounded text-[11px] font-medium"
          style={{ color: l.color, backgroundColor: `${l.color}18` }}
        >
          {l.text}
        </span>
      ))}

      {/* 日期 */}
      {date && (
        <span className="shrink-0 text-[12px] text-[var(--color-text-muted)]">{date}</span>
      )}
    </div>
  );
}
```

### 5.4 分组标题行（参考截图 01 的 "In Progress 1" / "Todo 11"）

```tsx
interface GroupHeaderRowProps {
  title: string;
  count: number;
  statusColor?: string;
}

export function GroupHeaderRow({ title, count, statusColor }: GroupHeaderRowProps) {
  return (
    <div className="flex items-center gap-2 h-[36px] px-4">
      {statusColor && (
        <span
          className="w-3.5 h-3.5 rounded-full border-2 shrink-0"
          style={{ borderColor: statusColor }}
        />
      )}
      <span className="text-[13px] font-medium text-[var(--color-text)]">{title}</span>
      <span className="text-[12px] text-[var(--color-text-muted)] tabular-nums">{count}</span>
      <div className="flex-1" />
      <button
        type="button"
        className="w-6 h-6 flex items-center justify-center rounded text-[var(--color-text-muted)]
          hover:bg-[var(--color-surface-hover)] hover:text-[var(--color-text-secondary)] transition-colors"
      >
        +
      </button>
    </div>
  );
}
```

### 5.5 命令面板 / Command Palette（参考截图 02-command-menu）

Linear 标志性的 Cmd+K 交互模式。

```tsx
interface CommandPaletteProps {
  open: boolean;
  onClose: () => void;
}

export function CommandPalette({ open, onClose }: CommandPaletteProps) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]" onClick={onClose}>
      {/* 遮罩 */}
      <div className="absolute inset-0 bg-black/50" />

      {/* 面板 */}
      <div
        className="relative w-[540px] rounded-xl bg-[var(--color-surface-raised)] border border-[var(--color-border)]
          shadow-2xl overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        {/* 搜索输入 */}
        <div className="px-4 py-3 border-b border-[var(--color-border)]">
          <input
            type="text"
            placeholder="Type a command or search..."
            autoFocus
            className="w-full bg-transparent text-[14px] text-[var(--color-text)]
              placeholder-[var(--color-text-muted)] outline-none"
          />
        </div>

        {/* 命令列表 */}
        <div className="py-2 max-h-[300px] overflow-y-auto">
          <div className="px-3 py-1.5 text-[11px] font-medium uppercase tracking-wider text-[var(--color-text-muted)]">
            Issue
          </div>
          <CommandItem icon="+" label="Create new issue..." shortcut="C" />
          <CommandItem icon="+" label="Create issue in fullscreen..." shortcut="V" />

          <div className="px-3 py-1.5 mt-1 text-[11px] font-medium uppercase tracking-wider text-[var(--color-text-muted)]">
            Project
          </div>
          <CommandItem icon="⊞" label="Create new project..." />

          <div className="px-3 py-1.5 mt-1 text-[11px] font-medium uppercase tracking-wider text-[var(--color-text-muted)]">
            Views
          </div>
          <CommandItem icon="≡" label="Create new view..." />
        </div>
      </div>
    </div>
  );
}

function CommandItem({ icon, label, shortcut }: { icon: string; label: string; shortcut?: string }) {
  return (
    <button
      type="button"
      className="flex items-center gap-3 w-full px-3 py-2 text-[13px] text-[var(--color-text)]
        hover:bg-[var(--color-surface-hover)] transition-colors cursor-default"
    >
      <span className="w-5 h-5 flex items-center justify-center text-[var(--color-text-secondary)]">
        {icon}
      </span>
      <span className="flex-1 text-left">{label}</span>
      {shortcut && (
        <kbd className="px-1.5 py-0.5 rounded bg-[var(--color-surface)] border border-[var(--color-border)]
          text-[11px] text-[var(--color-text-muted)] font-mono">
          {shortcut}
        </kbd>
      )}
    </button>
  );
}
```

### 5.6 状态下拉菜单（参考截图 09-change-status-options）

```tsx
const statuses = [
  { key: "backlog",    label: "Backlog",     color: "#5E5F63", shortcut: "⌘⇧⌥ 1" },
  { key: "todo",       label: "Todo",        color: "#9B9CA0", shortcut: "⌘⇧⌥ 2" },
  { key: "inProgress", label: "In Progress", color: "#F2994A", shortcut: "⌘⇧⌥ 3" },
  { key: "done",       label: "Done",        color: "#4CB782", shortcut: "⌘⇧⌥ 4" },
  { key: "cancelled",  label: "Cancelled",   color: "#EB5757", shortcut: "⌘⇧⌥ 5" },
];

export function StatusDropdown({ onSelect }: { onSelect: (key: string) => void }) {
  return (
    <div className="w-[240px] py-1.5 rounded-lg bg-[var(--color-surface-raised)] border border-[var(--color-border)] shadow-xl">
      <div className="px-3 py-2 border-b border-[var(--color-border)]">
        <input
          type="text"
          placeholder="Change status..."
          className="w-full bg-transparent text-[13px] text-[var(--color-text)]
            placeholder-[var(--color-text-muted)] outline-none"
        />
      </div>
      {statuses.map((s) => (
        <button
          key={s.key}
          type="button"
          onClick={() => onSelect(s.key)}
          className="flex items-center gap-2.5 w-full px-3 py-2 text-[13px] text-[var(--color-text)]
            hover:bg-[var(--color-surface-hover)] transition-colors cursor-default"
        >
          <span
            className="w-4 h-4 rounded-full border-2 shrink-0"
            style={{ borderColor: s.color }}
          />
          <span className="flex-1 text-left">{s.label}</span>
          <span className="text-[11px] text-[var(--color-text-muted)] font-mono">{s.shortcut}</span>
        </button>
      ))}
    </div>
  );
}
```

### 5.7 搜索/过滤栏（参考截图 01, 04 顶部区域）

```tsx
export function FilterBar({ title, onFilter }: { title: string; onFilter?: () => void }) {
  return (
    <div className="flex items-center gap-3 h-[44px] px-4 border-b border-[var(--color-border)]">
      <h1 className="text-[14px] font-semibold text-[var(--color-text)]">{title}</h1>
      <button
        type="button"
        onClick={onFilter}
        className="flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[12px]
          text-[var(--color-text-secondary)] hover:bg-[var(--color-surface-hover)]
          transition-colors cursor-default"
      >
        <span>+</span>
        <span>Filter</span>
      </button>
      <div className="flex-1" />
      {/* 视图切换按钮 */}
      <div className="flex items-center gap-0.5 p-0.5 rounded-md bg-[var(--color-surface)]">
        <button className="w-7 h-7 rounded flex items-center justify-center text-[var(--color-text)] bg-[var(--color-surface-active)]">
          ☰
        </button>
        <button className="w-7 h-7 rounded flex items-center justify-center text-[var(--color-text-muted)] hover:text-[var(--color-text-secondary)]">
          ⊞
        </button>
      </div>
    </div>
  );
}
```

---

## 6. 交互模式

| 交互 | 效果 | CSS |
|------|------|-----|
| 悬浮（列表行） | 背景变 `surface-hover` | `hover:bg-[var(--color-surface-hover)]` |
| 悬浮（按钮） | 背景 + 文字变亮 | `hover:bg-[var(--color-surface-hover)] hover:text-[var(--color-text)]` |
| 选中 | 背景变 `surface-active` | `bg-[var(--color-surface-active)]` |
| 聚焦输入框 | 边框变 accent | `focus:border-[var(--color-accent)]` |
| 过渡 | 100ms ease | `transition-colors duration-100` |
| 滚动条 | 6px 宽，圆角，透明轨道 | 见下方 CSS |

### 滚动条样式

```css
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--color-border); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--color-text-muted); }
```

### 选区样式

```css
::selection { background: var(--color-accent-dim); color: var(--color-accent); }
```

---

## 7. 全局样式模板

完整的 `globals.css` 起点（可直接复制到项目中）：

```css
@import "tailwindcss";

:root {
  --color-bg:             #1B1C1F;
  --color-surface:        #18191C;
  --color-surface-hover:  #232428;
  --color-surface-active: #2B2D31;
  --color-surface-raised: #2F3035;
  --color-border:         #2E3035;
  --color-border-subtle:  #252629;
  --color-text:           #EDEDEF;
  --color-text-secondary: #9B9CA0;
  --color-text-muted:     #5E5F63;
  --color-accent:         #5E6AD2;
  --color-accent-hover:   #6E7AE2;
  --color-accent-dim:     #5E6AD233;
  --color-success:        #4CB782;
  --color-warning:        #F2994A;
  --color-danger:         #EB5757;
}

* { margin: 0; padding: 0; box-sizing: border-box; }

body {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Helvetica Neue", sans-serif;
  font-size: 13px;
  line-height: 1.5;
  letter-spacing: -0.01em;
  background: var(--color-bg);
  color: var(--color-text);
  overflow: hidden;
  -webkit-font-smoothing: antialiased;
}

::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--color-border); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: var(--color-text-muted); }
::selection { background: var(--color-accent-dim); color: var(--color-accent); }
```

---

## 使用方式

1. **链接此 skill 到项目**：
   ```bash
   ln -s /Users/eamanc/Documents/pe/skills/linear-dark-ui-style <project>/.claude/skills/linear-dark-ui-style
   ```

2. **在项目中使用**：告诉 Claude Code —
   - "按照 Linear 暗黑风格生成侧边栏组件"
   - "用 linear-dark-ui-style 的 token 做一个列表页"
   - "参考 Linear 风格写一个命令面板"

3. **对照截图微调**：原始截图在 `./references/screenshots/`，可以让 Claude 读取截图对比实现效果。
