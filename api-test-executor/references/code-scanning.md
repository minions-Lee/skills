# 多语言代码扫描规范

## 目录

- [API Schema 提取](#api-schema-提取)
  - [Java (Spring Boot)](#java-spring-boot)
  - [Python (FastAPI / Flask / Django)](#python)
  - [Go (Gin / Echo / Chi)](#go)
  - [Node.js (Express / NestJS / Koa)](#nodejs)
  - [通用扫描策略](#通用扫描策略)
- [环境配置探测](#环境配置探测)
  - [通用探测策略](#通用探测策略)
  - [Java](#java-环境探测)
  - [Node.js](#nodejs-环境探测)
  - [Python](#python-环境探测)
  - [Go](#go-环境探测)
  - [Docker](#docker-环境探测)
  - [探测优先级](#探测优先级)

---

## API Schema 提取

当用户未提供独立的接口文档，而是让你从项目代码中提取 API 定义时，按以下规范扫描。

### Java (Spring Boot)

**扫描目标**：`*Controller.java`、`*Resource.java`

| 注解/结构 | 提取内容 |
|-----------|---------|
| `@RestController` / `@Controller` | 标识 Controller 类 |
| `@RequestMapping("/api/v1/xxx")` | 基础路径前缀 |
| `@GetMapping` / `@PostMapping` / `@PutMapping` / `@DeleteMapping` | 接口路径 + 方法 |
| `@PathVariable` | Path 参数 |
| `@RequestParam` | Query 参数 |
| `@RequestBody` | Body 参数（跳转到对应 DTO/VO 类提取字段） |
| `@Valid` / `@NotNull` / `@Size` 等 | 参数校验规则 |
| 返回类型 `ResponseEntity<T>` / `Result<T>` | 响应结构（跳转到泛型类提取字段） |

**DTO/VO 解析**：定位 `@RequestBody` 引用的类（通常在 `dto/`、`vo/`、`model/` 包下），提取所有字段名、类型、校验注解，嵌套对象递归解析。

### Python

| 框架 | 提取方式 |
|------|---------|
| FastAPI | `@app.get/post()` 装饰器 + Pydantic Model |
| Flask | `@app.route()` 装饰器 + docstring / marshmallow schema |
| Django REST | `ViewSet` 类 + `serializers.py` 中的 Serializer 定义 |

### Go

| 框架 | 提取方式 |
|------|---------|
| Gin | `r.GET/POST()` 路由注册 + `c.ShouldBindJSON(&struct)` |
| Echo | `e.GET/POST()` + `c.Bind(&struct)` |
| Chi | `r.Get/Post()` + `json.NewDecoder(r.Body).Decode(&struct)` |

提取 Struct Tag：`json:"field_name"` 和 `binding:"required"` / `validate:"required"`。

### Node.js

| 框架 | 提取方式 |
|------|---------|
| Express | `router.get/post()` + `req.body` / `req.query` / `req.params` 的使用 |
| NestJS | `@Get()` / `@Post()` 装饰器 + `@Body()` DTO 类 |
| Koa | `router.get/post()` + `ctx.request.body` 的使用 |

### 通用扫描策略

```
1. 识别项目语言和框架（package.json / pom.xml / go.mod / requirements.txt）
2. 定位路由/Controller 入口文件
3. 逐个提取：路径、方法、参数（位置+类型+校验）、响应结构
4. 输出标准化的接口清单（Markdown 表格格式）
5. 让用户确认后，用于构造测试请求
```

> **注意**：从代码提取的 Schema 可能不完整（如动态路由、中间件注入的参数）。提取后应让用户确认补充。

---

## 环境配置探测

当用户未在测试文档中提供环境配置时，自动从项目配置文件中探测。

### 通用探测策略

```
1. 识别项目语言和框架（复用 Schema 提取阶段的识别结果）
2. 按语言规范扫描环境配置文件
3. 提取所有环境的 BASE_URL（host + port + context-path）
4. 识别环境名称（dev / staging / prod 等）
5. 输出探测结果，让用户确认或修正
```

### Java 环境探测

**扫描**：`src/main/resources/application*.yml` / `application*.properties`

| 配置键 | 用途 |
|--------|------|
| `server.port` | 服务端口 |
| `server.servlet.context-path` | 上下文路径 |
| `spring.profiles.active` | 当前激活环境 |

**拼接**：`BASE_URL = http://localhost:{server.port}{context-path}`

### Node.js 环境探测

**扫描**：`.env` / `.env.*` / `config/*.json` / `package.json` scripts

| 变量名 | 用途 |
|--------|------|
| `PORT` | 服务端口 |
| `BASE_URL` / `API_URL` | 服务地址 |
| `NODE_ENV` | 环境标识 |
| `API_PREFIX` | 路径前缀 |

从 `package.json` scripts 中提取 `PORT=3000` 等环境变量。

### Python 环境探测

**扫描**：

| 框架 | 扫描文件 |
|------|---------|
| Django | `settings/base.py`, `settings/dev.py`, `settings/staging.py`, `settings/prod.py` |
| FastAPI / Flask | `.env`, `config.py`, `settings.py`, `core/config.py` |

提取 `HOST`、`PORT`、`DEBUG`（可推断环境）。从启动命令（uvicorn/gunicorn）提取端口。

### Go 环境探测

**扫描**：`config.yaml` / `config/*.yaml` / `.env` / `main.go`

提取 `server.port`、`http.addr`、`env`。扫描 `main.go` 中的 `Run`/`Start`/`ListenAndServe` 调用提取默认端口。

### Docker 环境探测

**扫描**：`docker-compose*.yml` / `Dockerfile`

提取 `ports` 映射中的宿主机端口 + `environment` 中的环境变量。每个 compose 文件对应一个环境。

### 探测优先级

| 优先级 | 来源 |
|--------|------|
| 1（最高） | 用户在测试文档中手动配置 |
| 2 | `.env` / `.env.*` 文件 |
| 3 | 框架配置文件（`application.yml` 等） |
| 4 | `docker-compose*.yml` |
| 5 | 启动命令 / 代码中的默认值 |

> **注意**：自动探测可能不完整（外部配置中心、Kubernetes ConfigMap 等）。探测结果仅作为建议，始终让用户确认。
