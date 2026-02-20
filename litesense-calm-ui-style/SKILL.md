---
name: litesense-calm-ui-style
description: |
  LiteSense Calm UI 风格指南。基于 Headspace 的设计语言提炼，
  为 AI 引导式对话/学习 App 打造干净、专注、极简、有呼吸感的 UI。
  提供完整的设计 token、布局规范和 React Native 组件代码示例。
  当需要为 LiteSense 生成 UI 代码时使用此 skill。
  触发词：LiteSense 风格、calm UI、Headspace 风格、极简对话、
  breathable UI、冥想风格 UI。
tags: ["ui-style", "calm", "minimal", "react-native", "litesense", "headspace"]
---

# LiteSense Calm UI 风格指南

基于 Headspace (iOS + Web) 的设计语言提炼。适用于 AI 引导式对话/学习类 Mobile App。

**设计精度**: medium（Claude Vision 视觉分析，建议对照截图微调）

## 设计来源

- 参考 App: Headspace (iOS + Web)
- 来源: Mobbin + headspace.com
- 截图数量: 6 张
- 原始截图路径: `./references/screenshots/`
- 设计 Token JSON: `./references/design-tokens.json`

## 核心设计原则

1. **呼吸感** — 大量留白，元素之间保持充足间距，让用户感到放松而非被信息压迫
2. **温暖极简** — 使用暖色调的中性色（米白、暖灰），而非冰冷的纯白纯灰
3. **柔和圆润** — 大圆角（16-20px）、pill 形按钮，避免锐利的直角
4. **清晰层级** — 通过字重和颜色深浅区分主次，而非过多的边框和分割线
5. **克制动效** — 过渡平滑但不花哨，150-250ms 的微妙动画
6. **专注引导** — 每屏只有一个核心 CTA，减少决策焦虑

---

## 1. 色彩系统

### React Native 主题常量

```typescript
// theme/colors.ts
export const Colors = {
  // 背景层级（从浅到深的温暖色调）
  bg:              '#FFFFFF',     // 最底层，纯白
  bgWarm:          '#F9F4F2',     // 温暖米白，用于页面背景
  bgMuted:         '#F5F2ED',     // 更深的暖底，用于区分区域

  // 卡片/面板
  surface:         '#FFFFFF',     // 卡片背景
  surfaceHover:    '#F5F2ED',     // 按压态（RN: pressed state）
  surfaceActive:   '#EDE8E3',     // 选中态背景
  surfaceSelected: '#2D2C2B',     // 深色选中背景（如已选标签）

  // 边框
  border:          '#E2DED9',     // 默认边框
  borderSubtle:    '#EEEBE7',     // 极淡边框

  // 文字层级
  text:            '#2D2C2B',     // 主文字（深炭色，非纯黑）
  textSecondary:   '#6B6560',     // 次要文字
  textMuted:       '#A09A94',     // 弱化文字/占位符
  textOnDark:      '#FFFFFF',     // 深色背景上的文字
  textOnSelected:  '#FFFFFF',     // 选中态文字

  // 品牌强调色
  accent:          '#0061EF',     // 主 CTA 蓝（沉稳而非刺眼）
  accentLight:     '#E8F0FD',     // 蓝色淡背景

  // 温暖强调色（用于图标、进度、情感化元素）
  accentWarm:      '#F47D31',     // 温暖橙（Headspace 标志色）
  accentWarmLight: '#FEF0E5',     // 橙色淡背景

  // 沉浸式背景（用于专注/对话/冥想场景）
  immersiveBg:     '#2B1A5E',     // 深紫靛
  immersiveAccent: '#6B4FA0',     // 紫色装饰

  // 语义色
  success:         '#2EAD6B',
  successLight:    '#E6F7EF',
  warning:         '#F5A623',
  warningLight:    '#FEF5E5',
  danger:          '#E5484D',
  dangerLight:     '#FEE8E8',
} as const;
```

### 使用建议

| 场景 | 颜色 |
|------|------|
| 主页面背景 | `bgWarm` (#F9F4F2) |
| 卡片背景 | `surface` (#FFFFFF) |
| 对话页面背景 | `bgWarm` 或 `immersiveBg`（夜间） |
| 用户气泡 | `surfaceActive` (#EDE8E3) |
| AI 气泡 | `surface` (#FFFFFF) + border |
| 主题卡片 | `surface` with `shadow.sm` |
| CTA 按钮 | `accent` (#0061EF) |
| 次要按钮 | `surface` + `border` |
| 标签（未选） | `bgMuted` (#F5F2ED) |
| 标签（已选） | `surfaceSelected` (#2D2C2B) |

---

## 2. 字体系统

### React Native 字体配置

```typescript
// theme/typography.ts
import { Platform } from 'react-native';

// 字体族：优先 DM Sans（标题），Inter（正文），回退 System
const FontFamily = {
  heading: Platform.select({
    ios: 'DM Sans',
    android: 'DMSans-Bold',
    default: 'System',
  }),
  headingMedium: Platform.select({
    ios: 'DM Sans',
    android: 'DMSans-SemiBold',
    default: 'System',
  }),
  body: Platform.select({
    ios: 'Inter',
    android: 'Inter-Regular',
    default: 'System',
  }),
  bodyMedium: Platform.select({
    ios: 'Inter',
    android: 'Inter-Medium',
    default: 'System',
  }),
};

export const Typography = {
  // 大标题 — 页面级标题（"How your trial works"）
  h1: {
    fontFamily: FontFamily.heading,
    fontSize: 32,
    fontWeight: '700' as const,
    lineHeight: 38,      // 1.2x
    letterSpacing: -0.5,
    color: '#2D2C2B',
  },

  // 区块标题（"Managing everyday anxiety & stress"）
  h2: {
    fontFamily: FontFamily.heading,
    fontSize: 24,
    fontWeight: '700' as const,
    lineHeight: 30,      // 1.25x
    letterSpacing: -0.3,
    color: '#2D2C2B',
  },

  // 小标题 / 卡片标题（"Start here", "Featured"）
  h3: {
    fontFamily: FontFamily.headingMedium,
    fontSize: 20,
    fontWeight: '600' as const,
    lineHeight: 26,      // 1.3x
    letterSpacing: -0.2,
    color: '#2D2C2B',
  },

  // 大正文（引导文字 "Relax your mind with meditations..."）
  bodyLarge: {
    fontFamily: FontFamily.body,
    fontSize: 17,
    fontWeight: '400' as const,
    lineHeight: 26,      // 1.5x
    letterSpacing: 0,
    color: '#6B6560',
  },

  // 默认正文
  body: {
    fontFamily: FontFamily.body,
    fontSize: 15,
    fontWeight: '400' as const,
    lineHeight: 22,      // 1.5x
    letterSpacing: 0,
    color: '#2D2C2B',
  },

  // 中等正文（按钮文字、导航项）
  bodyMedium: {
    fontFamily: FontFamily.bodyMedium,
    fontSize: 15,
    fontWeight: '500' as const,
    lineHeight: 22,
    letterSpacing: 0,
    color: '#2D2C2B',
  },

  // 说明文字（时间戳、辅助信息）
  caption: {
    fontFamily: FontFamily.body,
    fontSize: 13,
    fontWeight: '400' as const,
    lineHeight: 18,      // 1.4x
    letterSpacing: 0.1,
    color: '#A09A94',
  },

  // 中等说明文字（标签内文字）
  captionMedium: {
    fontFamily: FontFamily.bodyMedium,
    fontSize: 13,
    fontWeight: '500' as const,
    lineHeight: 18,
    letterSpacing: 0.1,
    color: '#6B6560',
  },

  // 小标签（数字徽章）
  label: {
    fontFamily: FontFamily.bodyMedium,
    fontSize: 12,
    fontWeight: '600' as const,
    lineHeight: 16,
    letterSpacing: 0.5,
    color: '#6B6560',
  },

  // 大写标注（"RUN STREAK GOALS"）
  overline: {
    fontFamily: FontFamily.bodyMedium,
    fontSize: 11,
    fontWeight: '600' as const,
    lineHeight: 14,
    letterSpacing: 1.5,
    textTransform: 'uppercase' as const,
    color: '#A09A94',
  },
} as const;
```

---

## 3. 间距与圆角

### 间距 Token

```typescript
// theme/spacing.ts
export const Spacing = {
  xs:   4,     // 极小间距（图标与文字之间）
  sm:   8,     // 小间距（相关元素之间）
  md:   12,    // 中间距（表单元素之间）
  base: 16,    // 基础间距（列表项之间）
  lg:   20,    // 大间距（卡片内边距）
  xl:   24,    // 页面左右边距 (screenPadding)
  '2xl': 32,   // 区块之间
  '3xl': 48,   // 大区块之间
  '4xl': 64,   // 页面顶部/底部安全留白
} as const;

// 快捷引用
export const ScreenPadding = Spacing.xl; // 24px — 所有页面的水平内边距
```

### 圆角 Token

```typescript
// theme/radius.ts
export const Radius = {
  sm:   8,     // 小按钮、输入框
  md:   12,    // 一般按钮、小卡片
  lg:   16,    // 主题卡片
  xl:   20,    // 大卡片、底部弹窗
  pill: 999,   // pill 形按钮和标签
} as const;
```

### 阴影 Token

```typescript
// theme/shadows.ts
import { Platform } from 'react-native';

export const Shadows = {
  sm: Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.06,
      shadowRadius: 3,
    },
    android: { elevation: 1 },
  }),

  md: Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.08,
      shadowRadius: 12,
    },
    android: { elevation: 3 },
  }),

  lg: Platform.select({
    ios: {
      shadowColor: '#000',
      shadowOffset: { width: 0, height: 8 },
      shadowOpacity: 0.10,
      shadowRadius: 24,
    },
    android: { elevation: 6 },
  }),
} as const;
```

---

## 4. 布局模式

### 4.1 页面整体结构

LiteSense 的页面结构遵循「呼吸感」原则 — 上下留白慷慨，内容区域有明确边界。

```tsx
// layouts/ScreenLayout.tsx
// 参考截图: 03-main-screen.png, 05-trial-details.png
import React from 'react';
import { View, ScrollView, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '../theme/colors';
import { Spacing } from '../theme/spacing';

interface ScreenLayoutProps {
  children: React.ReactNode;
  /** 页面背景色，默认 bgWarm */
  bg?: string;
  /** 是否可滚动，默认 true */
  scrollable?: boolean;
  /** 头部区域（可放插图/渐变） */
  header?: React.ReactNode;
}

export function ScreenLayout({
  children,
  bg = Colors.bgWarm,
  scrollable = true,
  header,
}: ScreenLayoutProps) {
  const insets = useSafeAreaInsets();
  const Container = scrollable ? ScrollView : View;

  return (
    <View style={[styles.root, { backgroundColor: bg }]}>
      {header}
      <Container
        style={styles.content}
        contentContainerStyle={[
          styles.contentInner,
          { paddingBottom: insets.bottom + Spacing['3xl'] },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {children}
      </Container>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
  contentInner: {
    paddingHorizontal: Spacing.xl,  // 24px 左右边距
    paddingTop: Spacing['2xl'],     // 32px 顶部留白
  },
});
```

### 4.2 内容卡片区域

```tsx
// layouts/ContentSection.tsx
// 参考截图: 06-meditation-detail.png 的 "Start here" 区域
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';

interface ContentSectionProps {
  title: string;
  children: React.ReactNode;
}

export function ContentSection({ title, children }: ContentSectionProps) {
  return (
    <View style={styles.section}>
      <Text style={styles.title}>{title}</Text>
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  section: {
    marginBottom: Spacing['2xl'],  // 32px 区块间距
  },
  title: {
    ...Typography.h3,
    marginBottom: Spacing.base,    // 16px 标题与内容间距
  },
});
```

---

## 5. 组件代码示例

### 5.1 主题卡片（Topic Card）

LiteSense 的核心 UI — AI 拆解的可探索主题卡片。

```tsx
// components/TopicCard.tsx
// 参考截图: 06-meditation-detail.png 的水平滚动卡片
import React from 'react';
import { View, Text, Pressable, Image, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';
import { Radius } from '../theme/radius';
import { Shadows } from '../theme/shadows';

interface TopicCardProps {
  title: string;
  subtitle?: string;
  imageUrl?: string;
  /** 卡片背景渐变色（可选） */
  accentColor?: string;
  onPress: () => void;
}

export function TopicCard({
  title,
  subtitle,
  imageUrl,
  accentColor,
  onPress,
}: TopicCardProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.card,
        pressed && styles.cardPressed,
      ]}
    >
      {/* 卡片顶部色块/插图区 */}
      <View style={[
        styles.imageArea,
        accentColor ? { backgroundColor: accentColor } : undefined,
      ]}>
        {imageUrl && (
          <Image source={{ uri: imageUrl }} style={styles.image} />
        )}
      </View>

      {/* 卡片文字区 */}
      <View style={styles.textArea}>
        <Text style={styles.title} numberOfLines={2}>
          {title}
        </Text>
        {subtitle && (
          <Text style={styles.subtitle} numberOfLines={1}>
            {subtitle}
          </Text>
        )}
      </View>
    </Pressable>
  );
}

const CARD_WIDTH = 160;

const styles = StyleSheet.create({
  card: {
    width: CARD_WIDTH,
    backgroundColor: Colors.surface,
    borderRadius: Radius.lg,      // 16px
    overflow: 'hidden',
    ...Shadows.sm,
  },
  cardPressed: {
    opacity: 0.85,
    transform: [{ scale: 0.98 }],
  },
  imageArea: {
    width: CARD_WIDTH,
    height: CARD_WIDTH * 0.65,    // ~104px
    backgroundColor: Colors.bgMuted,
  },
  image: {
    width: '100%',
    height: '100%',
    resizeMode: 'cover',
  },
  textArea: {
    padding: Spacing.md,          // 12px
  },
  title: {
    ...Typography.bodyMedium,
    marginBottom: Spacing.xs,
  },
  subtitle: {
    ...Typography.caption,
  },
});
```

### 5.2 选项 Pill 按钮

用于目标选择、兴趣标签等场景。

```tsx
// components/PillOption.tsx
// 参考截图: 03-main-screen.png 的目标选择按钮
import React from 'react';
import { Text, Pressable, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';
import { Radius } from '../theme/radius';

interface PillOptionProps {
  label: string;
  selected?: boolean;
  onPress: () => void;
}

export function PillOption({ label, selected = false, onPress }: PillOptionProps) {
  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.pill,
        selected ? styles.pillSelected : styles.pillDefault,
      ]}
    >
      <Text style={[
        styles.label,
        selected ? styles.labelSelected : styles.labelDefault,
      ]}>
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  pill: {
    paddingHorizontal: Spacing.lg,   // 20px
    paddingVertical: Spacing.md,     // 12px
    borderRadius: Radius.pill,       // 全圆角
    alignItems: 'center',
    justifyContent: 'center',
  },
  pillDefault: {
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  pillSelected: {
    backgroundColor: Colors.surfaceSelected,
  },
  label: {
    ...Typography.bodyMedium,
  },
  labelDefault: {
    color: Colors.text,
  },
  labelSelected: {
    color: Colors.textOnSelected,
  },
});
```

### 5.3 对话气泡（Chat Bubble）

LiteSense 核心交互 — AI 引导式对话。

```tsx
// components/ChatBubble.tsx
// 融合 Headspace 温暖风格，适配 AI 对话场景
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';
import { Radius } from '../theme/radius';

interface ChatBubbleProps {
  message: string;
  /** 'ai' = AI 提问方, 'user' = 用户回答方 */
  sender: 'ai' | 'user';
  timestamp?: string;
}

export function ChatBubble({ message, sender, timestamp }: ChatBubbleProps) {
  const isAI = sender === 'ai';

  return (
    <View style={[styles.row, isAI ? styles.rowAI : styles.rowUser]}>
      <View style={[styles.bubble, isAI ? styles.bubbleAI : styles.bubbleUser]}>
        <Text style={[styles.message, isAI ? styles.messageAI : styles.messageUser]}>
          {message}
        </Text>
      </View>
      {timestamp && (
        <Text style={[styles.time, isAI ? styles.timeAI : styles.timeUser]}>
          {timestamp}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    marginBottom: Spacing.base,
    maxWidth: '80%',
  },
  rowAI: {
    alignSelf: 'flex-start',
  },
  rowUser: {
    alignSelf: 'flex-end',
  },
  bubble: {
    paddingHorizontal: Spacing.base,   // 16px
    paddingVertical: Spacing.md,       // 12px
  },
  bubbleAI: {
    backgroundColor: Colors.surface,
    borderRadius: Radius.lg,           // 16px
    borderTopLeftRadius: Radius.sm,    // 8px — 来源方向
    borderWidth: 1,
    borderColor: Colors.borderSubtle,
  },
  bubbleUser: {
    backgroundColor: Colors.surfaceSelected,  // 深色 #2D2C2B
    borderRadius: Radius.lg,
    borderTopRightRadius: Radius.sm,
  },
  message: {
    ...Typography.body,
  },
  messageAI: {
    color: Colors.text,
  },
  messageUser: {
    color: Colors.textOnDark,
  },
  time: {
    ...Typography.caption,
    marginTop: Spacing.xs,
  },
  timeAI: {
    textAlign: 'left',
  },
  timeUser: {
    textAlign: 'right',
  },
});
```

### 5.4 主 CTA 按钮

```tsx
// components/PrimaryButton.tsx
// 参考截图: 03-main-screen.png 的 "Continue" 蓝色按钮
import React from 'react';
import { Text, Pressable, ActivityIndicator, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';
import { Radius } from '../theme/radius';

interface PrimaryButtonProps {
  title: string;
  onPress: () => void;
  loading?: boolean;
  disabled?: boolean;
  /** 'primary' = 蓝色, 'warm' = 橙色, 'outline' = 边框 */
  variant?: 'primary' | 'warm' | 'outline';
}

export function PrimaryButton({
  title,
  onPress,
  loading = false,
  disabled = false,
  variant = 'primary',
}: PrimaryButtonProps) {
  const bgColor = {
    primary: Colors.accent,
    warm: Colors.accentWarm,
    outline: 'transparent',
  }[variant];

  const textColor = variant === 'outline' ? Colors.text : Colors.textOnDark;

  return (
    <Pressable
      onPress={onPress}
      disabled={disabled || loading}
      style={({ pressed }) => [
        styles.button,
        { backgroundColor: bgColor },
        variant === 'outline' && styles.outline,
        pressed && styles.pressed,
        disabled && styles.disabled,
      ]}
    >
      {loading ? (
        <ActivityIndicator color={textColor} size="small" />
      ) : (
        <Text style={[styles.text, { color: textColor }]}>
          {title}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    height: 52,
    borderRadius: Radius.md,        // 12px
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.xl,   // 24px
  },
  outline: {
    borderWidth: 1,
    borderColor: Colors.border,
  },
  pressed: {
    opacity: 0.85,
    transform: [{ scale: 0.99 }],
  },
  disabled: {
    opacity: 0.5,
  },
  text: {
    ...Typography.bodyMedium,
    fontSize: 16,
    fontWeight: '600',
  },
});
```

### 5.5 进度时间线

用于展示计划进度、学习路径。

```tsx
// components/ProgressTimeline.tsx
// 参考截图: 05-trial-details.png 的时间线
import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';

interface TimelineItem {
  icon: React.ReactNode;
  title: string;
  description: string;
  completed?: boolean;
}

interface ProgressTimelineProps {
  items: TimelineItem[];
}

export function ProgressTimeline({ items }: ProgressTimelineProps) {
  return (
    <View style={styles.container}>
      {items.map((item, index) => (
        <View key={index} style={styles.item}>
          {/* 左侧指示器 + 连线 */}
          <View style={styles.indicator}>
            <View style={[
              styles.dot,
              item.completed && styles.dotCompleted,
            ]}>
              {item.icon}
            </View>
            {index < items.length - 1 && (
              <View style={[
                styles.line,
                item.completed && styles.lineCompleted,
              ]} />
            )}
          </View>

          {/* 右侧内容 */}
          <View style={styles.content}>
            <Text style={styles.title}>{item.title}</Text>
            <Text style={styles.description}>{item.description}</Text>
          </View>
        </View>
      ))}
    </View>
  );
}

const DOT_SIZE = 36;

const styles = StyleSheet.create({
  container: {
    paddingLeft: Spacing.sm,
  },
  item: {
    flexDirection: 'row',
    minHeight: 72,
  },
  indicator: {
    alignItems: 'center',
    width: DOT_SIZE,
    marginRight: Spacing.base,
  },
  dot: {
    width: DOT_SIZE,
    height: DOT_SIZE,
    borderRadius: DOT_SIZE / 2,
    backgroundColor: Colors.bgMuted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dotCompleted: {
    backgroundColor: Colors.accentWarm,
  },
  line: {
    flex: 1,
    width: 2,
    backgroundColor: Colors.borderSubtle,
    marginVertical: Spacing.xs,
  },
  lineCompleted: {
    backgroundColor: Colors.accentWarmLight,
  },
  content: {
    flex: 1,
    paddingBottom: Spacing.lg,
  },
  title: {
    ...Typography.bodyMedium,
    fontWeight: '700',
    marginBottom: Spacing.xs,
  },
  description: {
    ...Typography.body,
    color: Colors.textSecondary,
  },
});
```

### 5.6 Tab 切换器

```tsx
// components/SegmentedControl.tsx
// 参考截图: 05-trial-details.png 的 "Annual / Monthly" 切换
import React from 'react';
import { View, Text, Pressable, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Typography } from '../theme/typography';
import { Spacing } from '../theme/spacing';
import { Radius } from '../theme/radius';

interface SegmentedControlProps {
  options: string[];
  selectedIndex: number;
  onSelect: (index: number) => void;
}

export function SegmentedControl({
  options,
  selectedIndex,
  onSelect,
}: SegmentedControlProps) {
  return (
    <View style={styles.container}>
      {options.map((option, index) => (
        <Pressable
          key={index}
          onPress={() => onSelect(index)}
          style={[
            styles.segment,
            index === selectedIndex && styles.segmentActive,
          ]}
        >
          <Text style={[
            styles.label,
            index === selectedIndex && styles.labelActive,
          ]}>
            {option}
          </Text>
        </Pressable>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    backgroundColor: Colors.bgMuted,
    borderRadius: Radius.pill,
    padding: 3,
    alignSelf: 'center',
  },
  segment: {
    paddingHorizontal: Spacing.lg,
    paddingVertical: Spacing.sm,
    borderRadius: Radius.pill,
  },
  segmentActive: {
    backgroundColor: Colors.surfaceSelected,
  },
  label: {
    ...Typography.captionMedium,
    color: Colors.textSecondary,
  },
  labelActive: {
    color: Colors.textOnSelected,
  },
});
```

### 5.7 空状态/引导插图区

用于首页、空页面等需要视觉引导的场景。

```tsx
// components/IllustrationHeader.tsx
// 参考截图: 03-main-screen.png 顶部橙色插图区域
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';
import { Spacing } from '../theme/spacing';

interface IllustrationHeaderProps {
  /** 头部渐变背景色 */
  backgroundColor?: string;
  /** 头部高度占屏幕比例 */
  heightRatio?: number;
  children?: React.ReactNode;
}

export function IllustrationHeader({
  backgroundColor = Colors.accentWarm,
  heightRatio = 0.3,
  children,
}: IllustrationHeaderProps) {
  return (
    <View style={[
      styles.container,
      { backgroundColor, aspectRatio: 1 / heightRatio },
    ]}>
      <View style={styles.content}>
        {children}
      </View>
      {/* 底部圆弧过渡到白色内容区 */}
      <View style={styles.curve} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    width: '100%',
    position: 'relative',
    overflow: 'hidden',
  },
  content: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: Spacing.xl,
  },
  curve: {
    position: 'absolute',
    bottom: -1,
    left: -20,
    right: -20,
    height: 30,
    backgroundColor: Colors.bgWarm,
    borderTopLeftRadius: 999,
    borderTopRightRadius: 999,
  },
});
```

---

## 6. 交互模式

### 按压态

所有可交互元素使用一致的按压反馈：

```typescript
// 标准按压态
const pressedStyle = {
  opacity: 0.85,
  transform: [{ scale: 0.98 }],
};
```

### 过渡动画

```typescript
// 使用 React Native Animated 或 Reanimated
const ANIMATION = {
  fast:   150,   // hover/press 响应
  normal: 250,   // 页面元素进入/退出
  slow:   400,   // 页面级过渡
  easing: Easing.bezier(0.4, 0, 0.2, 1),  // Material ease
};
```

### 页面转场

- 推入: 从右滑入，250ms
- 弹窗: 从底部滑入，300ms
- 渐变: 淡入淡出，200ms

### 滚动行为

- 所有列表关闭滚动条 (`showsVerticalScrollIndicator={false}`)
- 卡片横向滚动使用 snap (`snapToInterval`)
- 下拉刷新使用原生指示器

---

## 7. LiteSense 特有页面模式

### 7.1 首页 — 计划卡片列表

```
┌──────────────────────────┐
│  (warm bg #F9F4F2)       │
│                          │
│  Good morning, [Name]    │  ← h2, warm greeting
│  Continue your journey   │  ← bodyLarge, secondary
│                          │
│  ┌─ Card ─────────────┐  │
│  │ 🎯 Learning Plan   │  │  ← surface, shadow.sm
│  │ "Understand ML..."  │  │
│  │ Progress: ████░ 72% │  │
│  │ 3 topics to explore │  │
│  └────────────────────┘  │
│                          │
│  Explore Topics          │  ← h3, section title
│  ┌────┐ ┌────┐ ┌────┐   │
│  │Card│ │Card│ │Card│   │  ← horizontal scroll
│  └────┘ └────┘ └────┘   │
│                          │
└──────────────────────────┘
```

### 7.2 对话页面 — AI 引导式

```
┌──────────────────────────┐
│  ← Topic: "Neural Nets"  │  ← nav bar, h3
├──────────────────────────┤
│  (bgWarm or immersiveBg) │
│                          │
│  ┌─ AI ──────────────┐   │
│  │ What do you already│   │  ← bubbleAI
│  │ know about how     │   │
│  │ neurons connect?   │   │
│  └────────────────────┘   │
│                          │
│         ┌─ User ──────┐  │
│         │ I think they │  │  ← bubbleUser
│         │ pass signals │  │
│         └─────────────┘  │
│                          │
│  ┌─ AI ──────────────┐   │
│  │ Great intuition!   │   │
│  │ Let's explore that │   │
│  │ deeper...          │   │
│  └────────────────────┘   │
│                          │
├──────────────────────────┤
│  [  Type your thoughts ] │  ← input, surface + border
│                     [→]  │  ← accent send button
└──────────────────────────┘
```

### 7.3 计划创建 — 引导式选择

```
┌──────────────────────────┐
│  ┌────────────────────┐  │
│  │  (illustration)    │  │  ← IllustrationHeader
│  │  🌅 warm gradient  │  │
│  └────────────────────┘  │
│                          │
│  What do you want        │  ← h2
│  to explore?             │
│                          │
│  Tell us your goal and   │  ← bodyLarge, secondary
│  we'll create a plan     │
│                          │
│  ┌────────────────────┐  │
│  │ Learn machine...   │  │  ← selected pill (dark)
│  └────────────────────┘  │
│  ┌────────────────────┐  │
│  │ Improve writing    │  │  ← default pill (outline)
│  └────────────────────┘  │
│  ┌────────────────────┐  │
│  │ Build healthy...   │  │  ← default pill
│  └────────────────────┘  │
│  ┌────────────────────┐  │
│  │ Custom goal...     │  │  ← muted pill
│  └────────────────────┘  │
│                          │
│  ┌────────────────────┐  │
│  │    Continue         │  │  ← PrimaryButton accent
│  └────────────────────┘  │
└──────────────────────────┘
```

---

## 使用方式

1. 将此 skill 链接到 LiteSense 前端工程：
   ```bash
   ln -s /Users/eamanc/Documents/pe/skills/litesense-calm-ui-style <project>/.claude/skills/litesense-calm-ui-style
   ```
2. 在开发时告诉 Claude Code："按照 LiteSense calm 风格生成 XX 页面/组件"
3. Claude Code 会参考本 skill 中的设计 token 和代码示例生成代码
4. 精确色值和间距参考 `./references/design-tokens.json`
5. 视觉对照参考 `./references/screenshots/` 目录下的原始截图
