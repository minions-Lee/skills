# 跨端技术学习分层框架

不同技术栈的通用分层结构。具体知识点需根据学习者的实际工程动态生成。

## 通用 5 层模型

### Level 1: 看懂代码（What）
> 能读懂项目中的基本代码，理解"这是什么"

核心问题：这段代码在做什么？

| 技术栈 | 典型知识点 |
|--------|-----------|
| React Native | 组件、JSX、基础标签（View/Text）、Flexbox 布局、StyleSheet |
| Flutter | Widget 树、StatelessWidget/StatefulWidget、Material 组件、布局系统 |
| Next.js | 页面组件、App Router、Server/Client Component、JSX |
| Vue.js | 模板语法、单文件组件(.vue)、v-bind/v-if/v-for、组件注册 |
| SwiftUI | View 协议、修饰符链、HStack/VStack/ZStack、预览 |

### Level 2: 理解行为（How）
> 理解页面如何响应用户操作，数据何时变化

核心问题：用户做了 X，代码怎么响应的？

| 技术栈 | 典型知识点 |
|--------|-----------|
| React Native | Props/State、useState、事件处理(onPress)、useEffect、自定义 Hook |
| Flutter | setState、生命周期、GestureDetector、FutureBuilder/StreamBuilder |
| Next.js | Server Actions、useFormState、事件处理、数据获取(fetch) |
| Vue.js | data/computed/methods、watch、生命周期钩子、v-on 事件绑定 |
| SwiftUI | @State/@Binding/@ObservedObject、onAppear、手势识别 |

### Level 3: 理解架构（Why）
> 理解多页面如何组织，全局数据如何管理

核心问题：整个 App 是怎么组织的？数据在哪里管理？

| 技术栈 | 典型知识点 |
|--------|-----------|
| React Native | React Navigation、Zustand/Redux、React Query、Context |
| Flutter | GoRouter/Navigator 2.0、Provider/Riverpod/Bloc、GetIt |
| Next.js | 文件系统路由、Layout 嵌套、Middleware、Server State |
| Vue.js | Vue Router、Pinia/Vuex、组合式 API(Composables) |
| SwiftUI | NavigationStack、@EnvironmentObject、Combine |

### Level 4: 理解通信（Connect）
> 理解 App 如何与后端/外部世界交互

核心问题：数据从哪来？怎么到屏幕上的？

| 技术栈 | 典型知识点 |
|--------|-----------|
| React Native | HTTP(Axios/fetch)、SSE/WebSocket、Token 认证、多环境配置 |
| Flutter | http/dio 包、WebSocket、SharedPreferences、环境配置 |
| Next.js | Route Handlers、Server Components 数据获取、缓存策略、中间件认证 |
| Vue.js | Axios 封装、拦截器、环境变量、代理配置 |
| SwiftUI | URLSession、async/await、Keychain、Configuration |

### Level 5: 掌握全貌（Master）
> 理解高级模式，能独立开发新功能

核心问题：如果要我从零写一个新功能，我知道怎么做吗？

| 技术栈 | 典型知识点 |
|--------|-----------|
| React Native | 性能优化(memo/useMemo)、原生模块、TypeScript 深入、发布打包 |
| Flutter | 自定义 Widget、Platform Channel、性能分析、发布流程 |
| Next.js | ISR/SSG 策略、Edge Runtime、中间件链、部署优化 |
| Vue.js | 自定义指令、插件开发、SSR/SSG(Nuxt)、性能优化 |
| SwiftUI | 自定义 ViewModifier、UIKit 互操作、性能优化、App Store 发布 |

## 跨栈类比映射

帮助有经验的开发者快速建立认知桥梁：

### Java 后端 → React Native
| Java 概念 | RN 对应 | 说明 |
|-----------|---------|------|
| Class | Component(函数) | 组件是函数，返回 UI 而非数据 |
| Constructor 参数 | Props | 外部传入的只读数据 |
| 成员变量 | State(useState) | 组件内部可变数据 |
| Interface | Props 类型定义(TypeScript) | 约定组件接收什么参数 |
| @PostConstruct | useEffect([], ...) | 组件加载完成后执行 |
| Spring Bean(单例) | Context/Store(Zustand) | 全局共享状态 |
| Servlet Filter | Navigation Middleware | 路由拦截 |
| DTO | TypeScript Interface/Type | 数据结构定义 |
| Maven/Gradle | npm/yarn | 包管理 |
| application.yml | .env / config | 环境配置 |

### Python → React Native
| Python 概念 | RN 对应 | 说明 |
|-------------|---------|------|
| 函数 | Component(函数) | 返回 JSX 而非值 |
| dict 参数 | Props(解构) | `{price, color}` 类似 `**kwargs` |
| 类变量 | State | 组件内部可变数据 |
| decorator | HOC(高阶组件) | 包装组件增加功能 |
| pip | npm/yarn | 包管理 |
| requirements.txt | package.json | 依赖声明 |

### Go → React Native
| Go 概念 | RN 对应 | 说明 |
|---------|---------|------|
| struct | Props 类型 | 数据结构定义 |
| interface | Props 接口 | 约定行为 |
| goroutine | useEffect + async | 异步操作 |
| channel | State + callback | 数据流通信 |
| go mod | npm/yarn | 包管理 |
