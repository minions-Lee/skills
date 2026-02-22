# 多语言项目扫描策略

按项目类型执行针对性扫描。扫描入口识别 → 架构层扫描 → 业务层扫描 → 模糊点识别。

## Java 后端（Spring Boot / Spring Cloud）

```
扫描入口：
├── pom.xml / build.gradle → 依赖分析（Spring 版本、中间件）
├── application.yml / application.properties → 配置分析
├── @SpringBootApplication 入口类 → 包扫描范围
│
├── 架构层：
│   ├── @Controller / @RestController → API 入口清单
│   ├── @Service → 业务逻辑层
│   ├── @Repository / Mapper → 数据访问层
│   ├── @Configuration → 配置类
│   └── @Component → 工具类/监听器
│
├── 业务层：
│   ├── Entity / DO / PO → 数据模型
│   ├── DTO / VO / BO → 数据传输对象
│   ├── Enum → 枚举定义
│   ├── Exception → 自定义异常
│   └── Constant → 常量定义
│
├── 模糊点识别重点：
│   ├── @Transactional 的传播行为和隔离级别
│   ├── 自定义注解的业务含义
│   ├── AOP 切面隐藏的逻辑
│   ├── 配置文件中的业务参数
│   ├── SQL 中的复杂查询条件
│   └── 多数据源/分库分表策略
│
└── 特殊关注：
    ├── Feign/RestTemplate 远程调用
    ├── MQ 消息的发送和消费
    ├── 定时任务 @Scheduled / Quartz
    └── 缓存注解 @Cacheable 的 key 策略
```

## Android（Kotlin / Java）

```
扫描入口：
├── AndroidManifest.xml → 权限、组件注册、入口 Activity
├── build.gradle → 依赖、SDK 版本、构建变体
├── app/src/main/ → 主要代码目录
│
├── 架构层：
│   ├── Activity / Fragment → 页面入口
│   ├── ViewModel / Presenter → 业务逻辑
│   ├── Repository → 数据仓库
│   ├── Room / SQLite → 本地数据库
│   └── Retrofit / OkHttp → 网络请求
│
├── UI 层：
│   ├── res/layout/ → 页面布局
│   ├── res/navigation/ → 导航图
│   ├── Adapter / ViewHolder → 列表相关
│   └── 自定义 View → 特殊 UI 组件
│
├── 模糊点识别重点：
│   ├── Intent 传递的数据和跳转逻辑
│   ├── 生命周期相关的业务处理
│   ├── 后台任务 (WorkManager / Service)
│   ├── 推送通知的处理逻辑
│   ├── 多渠道/多变体的差异
│   └── 权限请求的时机和降级逻辑
│
└── 特殊关注：
    ├── DeepLink / App Link 路由
    ├── 第三方 SDK 初始化和回调
    ├── 混淆规则 proguard-rules.pro
    └── 多进程场景
```

## 前端（React / Vue / Next.js / Nuxt）

```
扫描入口：
├── package.json → 依赖分析（框架版本、UI 库、状态管理）
├── 配置文件 → next.config / nuxt.config / vite.config
├── src/ or app/ → 主要代码目录
│
├── 架构层：
│   ├── pages/ or app/ → 路由结构
│   ├── components/ → 组件树
│   ├── store/ or context/ → 状态管理
│   ├── hooks/ or composables/ → 逻辑复用
│   ├── services/ or api/ → 接口调用
│   └── utils/ or lib/ → 工具函数
│
├── 业务层：
│   ├── 路由守卫/中间件 → 权限控制
│   ├── 表单组件 → 校验规则和提交逻辑
│   ├── 列表/表格 → 筛选、排序、分页逻辑
│   └── 弹窗/抽屉 → 操作流程
│
├── 模糊点识别重点：
│   ├── 组件 props 的业务含义（尤其是 boolean flag）
│   ├── 状态管理中的业务状态 vs UI 状态
│   ├── 接口调用的错误处理和 loading 状态
│   ├── 权限控制的粒度（页面级 / 按钮级）
│   ├── 环境变量的用途
│   └── SSR / CSR 的选择原因
│
└── 特殊关注：
    ├── 国际化 (i18n) 的范围
    ├── 主题/暗黑模式的实现
    ├── 微前端/模块联邦
    └── 性能优化策略（懒加载、缓存）
```

## Node.js 后端（Express / NestJS / Koa）

```
扫描入口：
├── package.json → 依赖分析
├── 入口文件 (index.ts / main.ts / app.ts)
├── 配置 (.env / config/)
│
├── 架构层：
│   ├── Routes / Controllers → API 入口
│   ├── Services → 业务逻辑
│   ├── Models / Schemas → 数据模型 (Mongoose / Sequelize / Prisma)
│   ├── Middleware → 中间件链
│   └── Guards / Pipes (NestJS) → 验证和转换
│
├── 模糊点识别重点：
│   ├── 中间件的执行顺序和职责
│   ├── 认证/授权的实现方式
│   ├── 数据校验的规则和位置
│   ├── 文件上传/流处理逻辑
│   └── WebSocket 事件的业务含义
│
└── 特殊关注：
    ├── ORM 关系定义 (hasMany, belongsTo)
    ├── Migration 文件的业务背景
    ├── 队列任务 (Bull / BullMQ)
    └── GraphQL Schema (如有)
```

## Python 后端（Django / FastAPI / Flask）

```
扫描入口：
├── requirements.txt / pyproject.toml → 依赖分析
├── manage.py / main.py → 入口文件
├── settings.py / .env → 配置
│
├── 架构层（Django）：
│   ├── models.py → 数据模型
│   ├── views.py / viewsets.py → 视图层
│   ├── serializers.py → 序列化
│   ├── urls.py → 路由
│   ├── admin.py → 后台管理配置
│   └── signals.py → 信号处理
│
├── 架构层（FastAPI）：
│   ├── routers/ → 路由
│   ├── schemas/ → Pydantic 模型
│   ├── models/ → ORM 模型
│   ├── services/ → 业务逻辑
│   └── dependencies/ → 依赖注入
│
├── 模糊点识别重点：
│   ├── Django Signal 触发的隐式逻辑
│   ├── Celery Task 的业务含义
│   ├── Model Manager 的自定义查询
│   ├── Middleware 的处理逻辑
│   └── 权限类 (Permission Classes) 的规则
│
└── 特殊关注：
    ├── Migration 历史和数据迁移
    ├── Management Commands
    ├── 第三方 App 的集成方式
    └── 异步视图 (async views) 的使用场景
```

## Go 后端

```
扫描入口：
├── go.mod → 依赖分析
├── main.go / cmd/ → 入口
├── internal/ or pkg/ → 代码组织
│
├── 架构层：
│   ├── handler/ or controller/ → HTTP 处理
│   ├── service/ → 业务逻辑
│   ├── repository/ or dao/ → 数据访问
│   ├── model/ or entity/ → 数据结构
│   ├── middleware/ → 中间件
│   └── router/ → 路由注册
│
├── 模糊点识别重点：
│   ├── interface 定义的业务抽象
│   ├── goroutine 的并发逻辑
│   ├── channel 的数据传递含义
│   ├── context 的传播和取消逻辑
│   └── error wrapping 的层级
│
└── 特殊关注：
    ├── wire / fx 依赖注入
    ├── protobuf / gRPC 定义
    ├── 配置热更新
    └── 优雅关停逻辑
```

## Rust

```
扫描入口：
├── Cargo.toml → 依赖分析、feature flags
├── src/main.rs or src/lib.rs → 入口
│
├── 架构层：
│   ├── mod.rs → 模块划分
│   ├── trait 定义 → 抽象接口
│   ├── impl 块 → 具体实现
│   ├── error.rs → 错误类型定义
│   └── config.rs → 配置结构
│
├── 模糊点识别重点：
│   ├── trait 的业务语义
│   ├── 生命周期标注的设计原因
│   ├── unsafe 块的必要性和安全保证
│   ├── 宏定义的业务含义
│   └── 错误处理链的设计
│
└── 特殊关注：
    ├── async runtime 的选择（tokio / async-std）
    ├── FFI 绑定
    ├── feature flag 的组合逻辑
    └── build.rs 的构建逻辑
```

## Flutter

```
扫描入口：
├── pubspec.yaml → 依赖分析
├── lib/main.dart → 入口
│
├── 架构层：
│   ├── screens/ or pages/ → 页面
│   ├── widgets/ → 自定义组件
│   ├── providers/ or blocs/ → 状态管理
│   ├── models/ → 数据模型
│   ├── services/ or repositories/ → 数据层
│   └── utils/ → 工具
│
├── 模糊点识别重点：
│   ├── Widget 树的业务结构
│   ├── 状态管理方案的选择原因
│   ├── 路由传参和页面间通信
│   ├── Platform Channel 的原生交互
│   └── 主题和样式的组织方式
│
└── 特殊关注：
    ├── 多平台适配逻辑 (iOS / Android / Web)
    ├── 国际化配置
    ├── 动画和手势的业务含义
    └── 插件的使用和自定义
```

## .NET / C#

```
扫描入口：
├── *.sln / *.csproj → 解决方案和项目结构
├── Program.cs / Startup.cs → 入口和配置
├── appsettings.json → 配置
│
├── 架构层：
│   ├── Controllers/ → API 入口
│   ├── Services/ → 业务逻辑
│   ├── Repositories/ → 数据访问
│   ├── Models/ or Entities/ → 数据模型
│   ├── DTOs/ → 数据传输对象
│   └── Middleware/ → 中间件
│
├── 模糊点识别重点：
│   ├── DI 容器注册的服务生命周期
│   ├── 特性 (Attribute) 的业务含义
│   ├── LINQ 查询的业务过滤逻辑
│   ├── Entity Framework 的导航属性关系
│   └── 自定义中间件的处理逻辑
│
└── 特殊关注：
    ├── Background Service / Hosted Service
    ├── SignalR Hub 的业务事件
    ├── Identity 认证配置
    └── Migration 历史
```

## Monorepo / 多模块项目

当检测到多个项目类型共存时：

1. 识别项目组织方式（Nx / Turborepo / Lerna / Maven 多模块 / Go workspace）
2. 列出所有子项目及其类型
3. 让用户选择扫描范围（全部 / 指定子项目）
4. 对每个子项目应用对应语言的扫描策略
5. 额外关注子项目间的依赖和通信方式
