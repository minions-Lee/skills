---
name: api-test-executor
description: |
  基于接口文档和接口测试文档执行 API 测试。读取接口文档（Swagger/OpenAPI/Markdown）中的
  接口定义，结合测试文档中的 mock 数据和预期结果，自动构造请求、执行测试并生成测试报告。
  支持 REST API、GraphQL。支持环境变量替换、接口依赖链（上一个接口的返回值作为下一个接口的入参）、
  批量执行和断言校验。
  触发词：API 测试、接口测试、执行测试用例、跑接口、测试接口、api test、
  run api tests、接口验证、mock 测试、接口回归。
author: Claude Code
version: 1.0.0
date: 2026-02-21
tags: [api-testing, mock, automation, test-execution, quality-assurance]
---

# API 测试执行器

基于接口文档和测试用例文档，自动执行 API 测试并生成报告。

## 核心原则

**文档驱动，数据隔离，链式执行，断言严格。**

不写死任何请求参数。所有请求构造都基于用户提供的接口文档和测试数据文档，确保测试可复现、可追溯。

---

## 输入要求

### 1. 接口文档（必须）

支持以下格式，任选其一：

| 格式 | 说明 |
|------|------|
| Swagger/OpenAPI (JSON/YAML) | 标准 API 描述文件，自动解析 |
| Markdown 接口文档 | 需包含：路径、方法、请求参数、响应结构 |
| Postman Collection (JSON) | 导出的 Postman 集合文件 |
| 代码中的路由定义 | 直接扫描项目代码中的路由/Controller |

### 2. 测试数据文档（必须）

包含具体的测试用例，每个用例应有：

| 字段 | 说明 | 是否必须 |
|------|------|---------|
| 用例名称 | 描述测试目的 | ✅ |
| 接口路径 | 对应的 API 路径 | ✅ |
| 请求方法 | GET/POST/PUT/DELETE 等 | ✅ |
| 请求头 | Headers（如 Authorization） | 可选 |
| 请求参数 | Query/Body/Path 参数（mock 数据） | ✅ |
| 预期状态码 | 如 200、201、400 | ✅ |
| 预期响应 | 完整响应体或关键字段断言 | ✅ |
| 前置依赖 | 依赖哪个接口的返回值 | 可选 |

#### 测试数据文档示例

```markdown
## 用例 1：用户注册 - 正常流程

- 接口：POST /api/v1/users/register
- 请求体：
  ```json
  {
    "username": "testuser001",
    "password": "Test@12345",
    "email": "test001@example.com"
  }
  ```
- 预期状态码：201
- 预期响应：
  ```json
  {
    "code": 0,
    "message": "success",
    "data": {
      "userId": "@isNotEmpty",
      "username": "testuser001"
    }
  }
  ```
- 提取变量：`userId = response.data.userId`

## 用例 2：用户登录 - 正常流程

- 接口：POST /api/v1/users/login
- 请求体：
  ```json
  {
    "username": "testuser001",
    "password": "Test@12345"
  }
  ```
- 预期状态码：200
- 预期响应：
  ```json
  {
    "code": 0,
    "data": {
      "token": "@isNotEmpty"
    }
  }
  ```
- 提取变量：`token = response.data.token`

## 用例 3：获取用户信息 - 需要鉴权

- 接口：GET /api/v1/users/profile
- 请求头：
  ```
  Authorization: Bearer {{token}}
  ```
- 前置依赖：用例 2
- 预期状态码：200
- 预期响应：
  ```json
  {
    "code": 0,
    "data": {
      "username": "testuser001",
      "email": "test001@example.com"
    }
  }
  ```
```

### 3. Mock 数据模板

当测试数据文档中需要大量 mock 数据时，使用以下模板规范来定义，确保数据一致、可复用、可读性强。

#### 模板格式 A：单用例完整定义（Markdown）

适用于少量用例、每个用例独立描述的场景。

```markdown
## 用例：{用例编号} - {用例名称}

- 分类：{正向/异常/边界/性能}
- 接口：{METHOD} {PATH}
- 请求头：
  ```
  Content-Type: application/json
  Authorization: Bearer {{token}}
  ```
- Path 参数：
  ```json
  { "id": "{{userId}}" }
  ```
- Query 参数：
  ```json
  { "page": 1, "size": 10 }
  ```
- 请求体：
  ```json
  {
    "field1": "value1",
    "field2": 123,
    "nested": {
      "subField": true
    }
  }
  ```
- 预期状态码：200
- 预期响应：
  ```json
  {
    "code": 0,
    "data": {
      "id": "@isNotEmpty",
      "field1": "value1",
      "list": "@lengthGt(0)"
    }
  }
  ```
- 提取变量：`varName = response.data.xxx`
- 前置依赖：用例 {N}
```

#### 模板格式 B：表格批量定义

适用于同一个接口的多组参数校验、边界值测试。表头定义字段，每行是一组 mock 数据。

```markdown
## 用例组：{接口名称} - {测试目的}

- 接口：{METHOD} {PATH}
- 公共请求头：
  ```
  Authorization: Bearer {{token}}
  ```

| # | 场景 | 请求体 | 预期状态码 | 预期响应（关键字段） |
|---|------|--------|-----------|-------------------|
| 1 | 正常创建 | `{"name":"test","age":25}` | 200 | `{"code":0,"data.id":"@isNotEmpty"}` |
| 2 | name 为空 | `{"name":"","age":25}` | 400 | `{"code":1001,"message":"@contains(名称)"}` |
| 3 | age 为负数 | `{"name":"test","age":-1}` | 400 | `{"code":1002}` |
| 4 | 缺少必填字段 | `{"age":25}` | 400 | `{"code":1001}` |
| 5 | 超长 name（255+字符） | `{"name":"a]x256...","age":25}` | 400 | `{"code":1003}` |
```

#### 模板格式 C：JSON 结构化定义

适用于需要程序化处理、或从 Postman/Apifox 导出的场景。

```json
{
  "suite": "用户模块接口测试",
  "baseUrl": "{{BASE_URL}}",
  "globalHeaders": {
    "Content-Type": "application/json"
  },
  "cases": [
    {
      "id": "TC001",
      "name": "用户注册 - 正常",
      "category": "positive",
      "request": {
        "method": "POST",
        "path": "/api/v1/users/register",
        "headers": {},
        "body": {
          "username": "testuser001",
          "password": "Test@12345",
          "email": "test001@example.com"
        }
      },
      "expected": {
        "status": 201,
        "body": {
          "code": 0,
          "data": {
            "userId": "@isNotEmpty",
            "username": "testuser001"
          }
        }
      },
      "extract": {
        "userId": "response.data.userId"
      },
      "dependsOn": []
    },
    {
      "id": "TC002",
      "name": "用户登录 - 正常",
      "category": "positive",
      "request": {
        "method": "POST",
        "path": "/api/v1/users/login",
        "headers": {},
        "body": {
          "username": "testuser001",
          "password": "Test@12345"
        }
      },
      "expected": {
        "status": 200,
        "body": {
          "code": 0,
          "data": {
            "token": "@isNotEmpty"
          }
        }
      },
      "extract": {
        "token": "response.data.token"
      },
      "dependsOn": ["TC001"]
    }
  ]
}
```

#### Mock 数据生成规则

当用例中需要动态生成 mock 数据时，可使用以下占位符（在执行前自动替换）：

| 占位符 | 说明 | 示例输出 |
|--------|------|---------|
| `@randomString(N)` | N 位随机字母数字串 | `aB3kF9xZ` |
| `@randomInt(min,max)` | 范围内随机整数 | `42` |
| `@randomEmail` | 随机邮箱 | `user_a3k9@test.com` |
| `@randomPhone` | 随机手机号 | `13800138000` |
| `@randomUUID` | UUID v4 | `550e8400-e29b-41d4-a716-446655440000` |
| `@timestamp` | 当前时间戳（秒） | `1708502400` |
| `@timestampMs` | 当前时间戳（毫秒） | `1708502400000` |
| `@datetime` | 当前时间 ISO 格式 | `2026-02-21T14:30:00Z` |
| `@date` | 当前日期 | `2026-02-21` |
| `@randomName` | 随机中文姓名 | `张三` |
| `@randomIdCard` | 随机身份证号 | `310101199001011234` |
| `@sequence(prefix,start)` | 自增序列 | `ORDER_001`, `ORDER_002`... |
| `@fromPool(varName)` | 从变量池取值 | 等同于 `{{varName}}` |

**使用示例**：
```json
{
  "username": "user_@randomString(6)",
  "email": "@randomEmail",
  "phone": "@randomPhone",
  "orderId": "@sequence(ORD,1000)",
  "createTime": "@datetime",
  "token": "@fromPool(token)"
}
```

#### 用例分类标签

每个用例应标注分类，方便按类型筛选执行：

| 分类 | 说明 | 示例 |
|------|------|------|
| `positive` | 正向用例，正常流程 | 正确参数注册成功 |
| `negative` | 异常用例，错误输入 | 密码为空、格式错误 |
| `boundary` | 边界值测试 | 最大长度、最小值、0 |
| `auth` | 鉴权相关 | 无 token、过期 token、错误 token |
| `idempotent` | 幂等性测试 | 同一请求重复发送 |
| `concurrency` | 并发测试 | 同时创建相同资源 |
| `performance` | 性能基准 | 单接口响应时间阈值 |

### 4. 环境配置（可选）

支持多环境定义，执行时选择目标环境。

```markdown
## 环境配置

### dev（开发环境）
- BASE_URL: http://localhost:8080
- AUTH_TOKEN:（留空，由登录接口动态获取）
- TIMEOUT: 10000

### staging（测试环境）
- BASE_URL: https://staging-api.example.com
- AUTH_TOKEN:（留空）
- TIMEOUT: 15000

### prod（生产环境）⚠️ 只读
- BASE_URL: https://api.example.com
- AUTH_TOKEN:（留空）
- TIMEOUT: 10000
- READ_ONLY: true
```

**环境选择逻辑**：

| 场景 | 处理 |
|------|------|
| 文档中定义了多个环境 | Step 1 时列出环境让用户选择 |
| 文档中只有一个环境 | 直接使用，不追问 |
| 文档中没有环境配置 | 询问用户输入 BASE_URL |
| 用户在触发时指定了环境（如"在 staging 上跑"） | 直接匹配对应环境 |

**生产环境保护**：
- 环境名包含 `prod` / `production` 时，二次确认
- 如果标记了 `READ_ONLY: true`，只执行 GET 请求，跳过所有写操作（POST/PUT/DELETE），并在报告中注明

---

## 多语言 API Schema 提取规范

当用户未提供独立的接口文档，而是让你直接从项目代码中提取 API 定义时，按以下语言规范扫描。

### Java (Spring Boot)

**扫描目标**：`*Controller.java`、`*Resource.java`

**提取位置**：

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

**DTO/VO 解析**：
- 定位 `@RequestBody` 引用的类（通常在 `dto/`、`vo/`、`model/` 包下）
- 提取所有字段名、类型、校验注解
- 嵌套对象递归解析

**示例提取路径**：
```
Controller → @PostMapping("/users")
  → 参数: @RequestBody UserCreateDTO
    → 跳转 UserCreateDTO.java → 提取 {username: String @NotNull, email: String @Email, ...}
  → 返回: Result<UserVO>
    → 跳转 UserVO.java → 提取 {userId: Long, username: String, ...}
```

### Python (FastAPI / Flask / Django)

**扫描目标**：`routes/*.py`、`views/*.py`、`api/*.py`

| 框架 | 提取方式 |
|------|---------|
| FastAPI | `@app.get/post()` 装饰器 + Pydantic Model（自带类型和校验） |
| Flask | `@app.route()` 装饰器 + docstring / marshmallow schema |
| Django REST | `ViewSet` 类 + `serializers.py` 中的 Serializer 定义 |

### Go (Gin / Echo / Chi)

**扫描目标**：`router.go`、`handler/*.go`

| 框架 | 提取方式 |
|------|---------|
| Gin | `r.GET/POST()` 路由注册 + handler 函数中的 `c.ShouldBindJSON(&struct)` |
| Echo | `e.GET/POST()` + `c.Bind(&struct)` |
| Chi | `r.Get/Post()` + `json.NewDecoder(r.Body).Decode(&struct)` |

**Struct Tag 解析**：提取 `json:"field_name"` 和 `binding:"required"` / `validate:"required"` 标签。

### Node.js (Express / NestJS / Koa)

| 框架 | 提取方式 |
|------|---------|
| Express | `router.get/post()` + `req.body` / `req.query` / `req.params` 的使用 |
| NestJS | `@Get()` / `@Post()` 装饰器 + `@Body()` DTO 类（class-validator 装饰器） |
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

## 签名脚本

部分 API 需要请求签名（如 HMAC、RSA 签名），在发送请求前需要执行签名计算。

### 签名流程

```
构造请求参数
  ↓
按签名规则排序/拼接参数
  ↓
执行签名脚本计算签名值
  ↓
将签名注入请求头或请求参数
  ↓
发送请求
```

### 签名配置

在测试数据文档或环境配置中定义签名信息：

```markdown
## 签名配置

- 签名算法：HmacSHA256 | MD5 | RSA-SHA256
- App Key：{{APP_KEY}}
- App Secret：{{APP_SECRET}}
- 签名脚本路径：./scripts/sign.sh（或 sign.py / sign.js）
- 签名位置：Header（X-Signature） | Query（sign=xxx）
- 时间戳字段：timestamp（秒级/毫秒级）
- Nonce 字段：nonce（随机字符串）
```

### 内置签名模板

#### 模板 1：通用 HMAC-SHA256 签名

签名串拼接规则：
```
待签名字符串 = HTTP_METHOD + "\n" + PATH + "\n" + SORTED_PARAMS + "\n" + TIMESTAMP + "\n" + NONCE
签名值 = HMAC-SHA256(待签名字符串, APP_SECRET)
```

执行方式：
```bash
SIGN_STRING="${METHOD}\n${PATH}\n${SORTED_PARAMS}\n${TIMESTAMP}\n${NONCE}"
SIGNATURE=$(echo -ne "$SIGN_STRING" | openssl dgst -sha256 -hmac "${APP_SECRET}" -binary | base64)
```

#### 模板 2：MD5 参数签名

签名串拼接规则：
```
参数按 key 字母序排列 → key1=value1&key2=value2&...&key=APP_SECRET
签名值 = MD5(拼接字符串).toUpperCase()
```

#### 模板 3：自定义签名脚本

如果项目有特殊的签名逻辑，用户可提供自定义签名脚本：

```markdown
## 自定义签名脚本

- 脚本路径：./scripts/sign.sh
- 输入参数：METHOD, PATH, BODY_JSON, TIMESTAMP, APP_KEY, APP_SECRET
- 输出：签名值（stdout 输出纯文本）
```

调用方式：
```bash
SIGNATURE=$(bash ./scripts/sign.sh \
  --method "${METHOD}" \
  --path "${PATH}" \
  --body "${BODY_JSON}" \
  --timestamp "${TIMESTAMP}" \
  --app-key "${APP_KEY}" \
  --app-secret "${APP_SECRET}")
```

### 签名注入

签名计算完成后，根据配置自动注入到请求中：

| 注入位置 | 方式 |
|---------|------|
| Header | 添加 `-H "X-Signature: ${SIGNATURE}" -H "X-Timestamp: ${TIMESTAMP}" -H "X-Nonce: ${NONCE}"` |
| Query | URL 追加 `&sign=${SIGNATURE}&timestamp=${TIMESTAMP}&nonce=${NONCE}` |
| Body | JSON body 中追加签名字段 |

> **安全提示**：APP_SECRET 不应出现在测试报告中，仅在执行时从环境变量或配置文件读取。

> **待补充**：用户可在此处补充具体项目的签名规则和脚本实现。

---

## 测试范围划分策略

项目接口可能有几十甚至上百个，不可能也不应该一次全测。以下提供 5 种划分策略，可组合使用。

### 策略 1：按业务模块划分

将接口按业务域分组，逐模块测试。

```
项目接口全集
├── 用户模块（注册/登录/信息/权限）
├── 商品模块（列表/详情/搜索/分类）
├── 订单模块（创建/支付/取消/退款）
├── 消息模块（发送/列表/已读/推送）
└── 管理后台（审核/统计/配置）
```

**操作方式**：
1. 扫描项目代码的 Controller / Router 文件，按包名或路径前缀自动分组
2. 输出模块清单，让用户选择本次测试哪些模块
3. 按模块生成独立的测试报告

**自动分组规则**：

| 语言 | 分组依据 |
|------|---------|
| Java | 按 `controller` 包下的类名分组（`UserController` → 用户模块） |
| Python | 按 `routes/` 或 `views/` 下的文件名分组（`user.py` → 用户模块） |
| Go | 按 `handler/` 下的文件名分组（`user_handler.go` → 用户模块） |
| Node.js | 按 `routes/` 下的文件名分组（`user.ts` → 用户模块） |

### 策略 2：按优先级/风险等级划分

根据接口的业务重要性和风险程度排优先级。

| 等级 | 标准 | 示例 | 测试要求 |
|------|------|------|---------|
| **P0 - 核心链路** | 主流程必经接口，挂了业务直接不可用 | 登录、下单、支付 | 正向 + 异常 + 边界，每次必测 |
| **P1 - 重要功能** | 高频使用，影响主要业务体验 | 商品搜索、订单列表、消息推送 | 正向 + 主要异常 |
| **P2 - 一般功能** | 低频使用，影响范围有限 | 修改头像、地址管理、收藏 | 正向用例 |
| **P3 - 边缘功能** | 极少使用，或有降级方案 | 日志导出、运营配置 | 按需测试 |

**自动推断优先级的信号**：

| 信号 | 推断逻辑 |
|------|---------|
| 接口被其他接口依赖（被 `dependsOn` 引用多次） | 优先级提升 |
| 涉及资金/支付的路径关键词（`pay`、`order`、`refund`） | 自动标 P0 |
| 涉及认证鉴权（`login`、`auth`、`token`） | 自动标 P0 |
| 路径中包含 `admin` / `manage` / `config` | 标为 P2-P3 |
| 接口方法为 DELETE | 风险提升一级 |

### 策略 3：按变更 Diff 划分（回归测试）

只测本次改动涉及的接口，适用于 CI/CD 和迭代回归。

```
git diff --name-only HEAD~1
  ↓
筛选出变更的 Controller / Router / Service / DTO 文件
  ↓
反向追踪影响到哪些接口
  ↓
只执行这些接口的用例
```

**变更追踪规则**：

| 变更文件类型 | 影响范围 |
|-------------|---------|
| Controller / Router | 直接影响：该文件中的所有接口 |
| Service / UseCase | 间接影响：调用该 Service 的所有 Controller 接口 |
| DTO / VO / Model | 间接影响：使用该 DTO 作为入参或出参的接口 |
| Repository / DAO | 间接影响：依赖该数据层的 Service → Controller |
| 配置文件 / 中间件 | 全局影响：可能影响所有接口，建议全量回归 |

**示例**：
```
变更文件：OrderService.java
  ↓ 被引用于
OrderController.java → POST /api/v1/orders, GET /api/v1/orders/{id}, PUT /api/v1/orders/{id}/cancel
  ↓
本次只执行订单相关的 3 个接口测试用例
```

### 策略 4：按接口覆盖矩阵划分

将接口与测试维度交叉，形成覆盖矩阵，确保每个接口至少被关键维度覆盖。

```markdown
## 接口覆盖矩阵

| 接口 | 正向 | 参数校验 | 鉴权 | 权限 | 幂等 | 并发 | 性能 |
|------|------|---------|------|------|------|------|------|
| POST /users/register | ✅ | ✅ | - | - | ✅ | ✅ | ⬜ |
| POST /users/login | ✅ | ✅ | - | - | ✅ | ⬜ | ⬜ |
| GET /users/profile | ✅ | - | ✅ | ✅ | - | - | ⬜ |
| POST /orders | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| DELETE /orders/{id} | ✅ | - | ✅ | ✅ | ✅ | ✅ | ⬜ |
```

图例：✅ 已有用例 | ⬜ 待补充 | `-` 不适用

**使用方式**：
1. 扫描所有接口 + 现有测试用例
2. 生成覆盖矩阵
3. 标出空白区域，建议用户补充
4. 按矩阵中「已有用例」的部分执行测试

### 策略 5：按依赖链路划分

从一个入口接口出发，自动追踪整条业务链路。

```
用户指定入口："测一下下单流程"
  ↓
自动识别链路：
  登录 → 获取商品列表 → 查看商品详情 → 加入购物车 → 创建订单 → 支付 → 查看订单状态
  ↓
只执行这条链路上的接口用例
```

**链路识别方式**：
- 根据测试文档中的 `dependsOn` 关系构建
- 根据业务关键词匹配（用户说"下单流程" → 匹配 order 相关接口）
- 根据接口间的数据依赖（A 的输出是 B 的输入）

---

### 策略组合推荐

| 场景 | 推荐组合 |
|------|---------|
| **首次接入项目，全量摸底** | 策略 1（按模块） + 策略 4（覆盖矩阵） |
| **日常迭代回归** | 策略 3（按 Diff）+ 策略 2（P0 必跑） |
| **上线前验收** | 策略 2（P0+P1）+ 策略 5（核心链路） |
| **新功能开发完成** | 策略 1（单模块）+ 策略 4（补齐覆盖） |
| **紧急修复 hotfix** | 策略 3（仅 Diff 涉及接口） |

### 执行时的选择交互

在 Step 0 解析完接口后，询问用户：

```
检测到项目共有 47 个接口，分布在 6 个模块。请选择测试范围：

1. 全量执行（47 个接口）
2. 按模块选择（列出模块清单）
3. 仅核心链路（P0 接口，共 12 个）
4. 仅变更涉及（基于 git diff，共 5 个接口）
5. 自定义（指定接口路径或用例编号）
```

---

## 执行流程

### Step 0: 解析输入与范围选择

#### 0.0 探测接口协议

项目不一定遵循 REST 或 GraphQL 规范，可能是 JSON-RPC、自定义 HTTP、甚至多种混合。在解析接口文档之前，先探测项目使用的协议风格。

**探测信号**：

| 信号来源 | 探测方式 | 判定 |
|---------|---------|------|
| **接口文档** | 文档中统一使用 `POST /graphql` + `query`/`mutation` | GraphQL |
| **接口文档** | 文档中路径多样（`GET /users`、`POST /orders`），方法多样 | REST 风格 |
| **接口文档** | 文档中统一 `POST /rpc` 或 `POST /api`，Body 含 `method`+`params` | JSON-RPC |
| **接口文档** | 以上都不匹配，但有路径 + 方法 + 参数 | 自定义 HTTP |
| **代码扫描** | 项目依赖含 `apollo-server`/`graphql-yoga`/`type-graphql` | GraphQL |
| **代码扫描** | 项目依赖含 `json-rpc`/`jayson`/`jsonrpclib` | JSON-RPC |
| **代码扫描** | 项目存在 `.graphql`/`.gql` schema 文件 | GraphQL |
| **代码扫描** | Controller/Handler 中同时存在多种风格 | 混合模式 |

**各协议的请求构造差异**：

| 协议 | 请求构造 | 成功判定 | 错误判定 |
|------|---------|---------|---------|
| **REST** | 按接口定义的 METHOD + PATH + 参数 | HTTP 状态码 2xx | 状态码 4xx/5xx |
| **GraphQL** | 统一 `POST /graphql`，Body 含 `query`+`variables` | 状态码 200 + `data` 非空 | 状态码 200 + `errors` 数组 |
| **JSON-RPC** | 统一 `POST`，Body 含 `jsonrpc`+`method`+`params`+`id` | `result` 字段存在 | `error` 字段存在 |
| **自定义 HTTP** | 按文档定义的路径和方法，不假设任何规范 | 按用例中的预期状态码和响应体判定 | 同左 |

**JSON-RPC 请求示例**：

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "user.getProfile",
    "params": { "userId": "{{userId}}" },
    "id": 1
  }' \
  "${BASE_URL}/rpc"
```

**JSON-RPC 断言差异**：

| 断言 | 说明 |
|------|------|
| `"result.fieldName": "value"` | 成功时校验 `result` 字段 |
| `"error": "@isNull"` | 正向用例：无错误 |
| `"error.code": -32600` | 异常用例：匹配错误码 |
| `"error.message": "@contains(xxx)"` | 异常用例：错误信息包含指定内容 |
| `"id": 1` | 请求 ID 一致性校验 |

**混合模式处理**：

如果检测到项目同时使用多种协议（如 REST + GraphQL），按接口逐个标记协议类型，构造请求时按各自规则处理：

```
接口清单：
  POST /api/v1/users/register     → REST
  POST /api/v1/users/login        → REST
  POST /graphql (createOrder)     → GraphQL
  POST /rpc (payment.process)     → JSON-RPC
```

**探测结果输出**：

```
🔍 协议探测结果：

  检测到项目使用 REST 风格接口（47 个）
  未发现 GraphQL / JSON-RPC 端点

  依据：
  - 接口路径多样，方法覆盖 GET/POST/PUT/DELETE
  - 项目依赖未包含 GraphQL 或 JSON-RPC 相关库
```

或混合场景：
```
🔍 协议探测结果：

  REST 接口：35 个
  GraphQL 端点：1 个（/graphql，包含 12 个 operation）

  将按各自协议规则构造请求和断言。
```

#### 0.1 解析接口文档

1. **定位文档**：让用户提供接口文档和测试数据文档的路径
2. **解析接口文档**：
   - Swagger/OpenAPI → 解析 paths、schemas、parameters
   - Markdown → 提取接口路径、方法、参数、响应结构
   - Postman Collection → 解析 item 数组
   - 代码路由 → 按「多语言 API Schema 提取规范」扫描（自动识别语言和框架）
3. **解析测试数据**：提取每个用例的请求数据、预期结果、依赖关系
4. **解析签名配置**：如果测试文档中包含签名配置，加载签名算法、密钥和脚本路径

#### 0.2 确定测试范围

解析完成后，统计接口全集并询问用户选择测试范围。

**触发方式一：用户在初始请求中指定范围**

用户可以在触发 skill 时直接指定范围，无需二次交互：

| 用户说法 | 识别为 | 执行范围 |
|---------|--------|---------|
| "测一下用户模块" | 策略 1 - 按模块 | 筛选路径前缀为 `/user` 或 Controller 名含 `User` 的接口 |
| "只测核心接口" / "跑 P0" | 策略 2 - 按优先级 | 按优先级推断规则筛选 P0 接口 |
| "测这次改的接口" / "回归测试" | 策略 3 - 按 Diff | 执行 `git diff` 追踪变更涉及的接口 |
| "测下单流程" / "测支付链路" | 策略 5 - 按链路 | 从关键词匹配入口，沿依赖链展开 |
| "全量测试" / "所有接口" | 全量 | 执行所有接口用例 |
| "测 POST /api/orders 和 GET /api/users" | 自定义 | 仅执行指定接口 |

**触发方式二：交互式选择（用户未指定范围时）**

```
📊 解析完成，共发现 47 个接口，分布如下：

  模块              接口数    P0    P1    P2
  ─────────────────────────────────────────
  用户模块           8       2     3     3
  商品模块           12      1     4     7
  订单模块           10      4     4     2
  支付模块           5       3     2     0
  消息模块           7       1     2     4
  管理后台           5       0     1     4
  ─────────────────────────────────────────
  合计              47      11    16    20

请选择测试范围：
1. 全量执行（47 个接口）
2. 按模块选择 → 追问选哪些模块
3. 仅核心接口（P0，共 11 个）
4. 核心 + 重要（P0 + P1，共 27 个）
5. 仅变更涉及（基于 git diff）
6. 按业务链路 → 追问测哪条链路
7. 自定义（输入接口路径或编号）
```

**各选项的后续处理**：

| 选项 | 后续交互 | 执行逻辑 |
|------|---------|---------|
| 1. 全量 | 无需追问，直接执行 | 所有接口 + 所有用例 |
| 2. 按模块 | 展示模块清单，用户勾选 | 仅执行选中模块的接口，外加该模块依赖的前置接口（如登录） |
| 3. 仅 P0 | 无需追问 | 按优先级推断规则筛选，自动补充必要的前置依赖接口 |
| 4. P0 + P1 | 无需追问 | 同上，范围扩大到 P1 |
| 5. 按 Diff | 无需追问，自动执行 `git diff` | 变更追踪 → 受影响接口 → 自动补充前置依赖 |
| 6. 按链路 | 展示可识别的链路，用户选择 | 沿依赖链展开完整链路 |
| 7. 自定义 | 用户输入接口路径列表 | 精确匹配 + 自动补充前置依赖 |

**自动补充前置依赖**：

无论选择哪种范围，如果被选中的接口依赖其他接口的输出（如需要 token），系统自动将前置接口加入执行范围：

```
用户选择：仅测 POST /api/orders（创建订单）
  ↓
检测到依赖：需要 {{token}} → 来自 POST /api/auth/login
检测到依赖：需要 {{productId}} → 来自 GET /api/products
  ↓
实际执行顺序：
  1. POST /api/auth/login      ← 自动补充
  2. GET /api/products          ← 自动补充
  3. POST /api/orders           ← 用户指定
```

#### 0.3 构建执行计划

根据选定范围，构建最终执行计划：

1. **筛选接口**：从全集中筛出目标接口
2. **补充依赖**：追加前置依赖接口
3. **构建依赖图**：根据用例间的依赖关系确定执行顺序
4. **输出执行计划摘要**：

```
📋 执行计划：

  本次测试范围：订单模块（用户选择）+ 前置依赖（自动补充）
  接口数：10 + 2（前置）= 12
  用例数：34
  预计执行：依赖链深度 3 层

  执行顺序：
  ┌─ 第 1 层（前置依赖）
  │   POST /api/auth/login
  │   GET /api/products
  ├─ 第 2 层
  │   POST /api/orders
  │   GET /api/orders
  │   ...
  └─ 第 3 层
      POST /api/orders/{id}/pay
      POST /api/orders/{id}/refund

确认执行？(Y/n)
```

### Step 1: 环境准备

1. **确认基础 URL**：
   - 优先使用测试文档中指定的环境变量
   - 未指定时，询问用户目标环境地址
2. **检查连通性**：
   ```bash
   curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/health
   ```
   - 如果目标服务未启动，提示用户启动服务
3. **初始化变量池**：用于存储接口间传递的动态变量（如 token、userId）

### Step 2: 按依赖顺序执行用例

对每个用例执行以下步骤：

#### 2.1 变量替换

将请求中的 `{{变量名}}` 替换为变量池中的实际值。

```
示例：
  Authorization: Bearer {{token}}
  → Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
```

#### 2.2 签名计算（如需要）

如果接口配置了签名，在构造请求前执行签名流程：
1. 生成 timestamp 和 nonce
2. 按签名配置拼接待签名字符串
3. 调用内置模板或自定义签名脚本计算签名值
4. 将签名值、timestamp、nonce 存入当前请求的 Header/Query/Body（按配置决定）

#### 2.3 构造请求

根据接口文档和用例数据构造 curl 命令：

```bash
curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{token}}" \
  -d '{"key": "value"}' \
  "${BASE_URL}/api/v1/endpoint"
```

**请求构造规则**：

| 参数位置 | 处理方式 |
|---------|---------|
| Path 参数 | 替换 URL 中的 `{param}` |
| Query 参数 | 拼接到 URL `?key=value&key2=value2` |
| Body 参数 | `-d` 传递 JSON |
| Form 参数 | `-F` 传递 |
| Header | `-H` 逐个添加 |

#### 2.4 执行请求 & 捕获响应

```bash
# 执行并分离响应体和状态码
RESPONSE=$(curl -s -w "\n---HTTP_STATUS_CODE---%{http_code}" \
  -X ${METHOD} \
  -H "Content-Type: application/json" \
  ${HEADERS} \
  ${BODY} \
  "${BASE_URL}${PATH}")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$RESPONSE" | grep -o '[0-9]\{3\}$')
```

#### 2.5 断言校验

| 断言类型 | 语法 | 说明 |
|---------|------|------|
| 状态码 | `status == 200` | 精确匹配 HTTP 状态码 |
| 精确匹配 | `"field": "value"` | 响应字段值完全相等 |
| 非空断言 | `"field": "@isNotEmpty"` | 字段存在且不为空 |
| 类型断言 | `"field": "@isNumber"` | 字段值为数字类型 |
| 包含断言 | `"field": "@contains(substring)"` | 字段值包含指定子串 |
| 数组长度 | `"field": "@lengthGt(0)"` | 数组长度大于指定值 |
| 正则匹配 | `"field": "@matches(^\\d{4}$)"` | 字段值匹配正则表达式 |
| 范围断言 | `"field": "@between(1,100)"` | 字段值在指定范围内 |
| 响应时间 | `@responseTimeLt(500)` | 响应时间小于 500ms（写在用例级别，不在响应体内） |
| 忽略字段 | `"field": "@any"` | 跳过该字段不做校验 |

**响应时间断言用法**：

不同接口可接受的响应时间差异很大，不应该一刀切。支持三种方式设定阈值：

**方式一：用例级别 — 每个用例单独指定（最精确）**

```markdown
- 响应时间要求：@responseTimeLt(500)
```
或在 JSON 格式中：
```json
{
  "id": "TC001",
  "expected": {
    "status": 200,
    "responseTime": "@responseTimeLt(500)",
    "body": { ... }
  }
}
```

**方式二：按接口特征自动推断（用户未指定时的默认值）**

当用例没有显式配置响应时间阈值时，根据接口特征自动分配默认阈值：

| 接口特征 | 识别方式 | 默认阈值 | 理由 |
|---------|---------|---------|------|
| 认证登录 | 路径含 `login`/`auth`/`token` | 1000ms | 可能涉及加密/外部验证 |
| 简单查询 | `GET` + 路径不含 `list`/`search`/`export` | 500ms | 单条数据读取，应该快 |
| 列表查询 | `GET` + 路径含 `list`/`search` 或有分页参数 | 2000ms | 涉及分页和条件查询 |
| 数据写入 | `POST`/`PUT`/`PATCH`（非特殊路径） | 1000ms | 写入+校验 |
| 删除操作 | `DELETE` | 500ms | 通常是简单操作 |
| 文件上传 | 请求含 `multipart/form-data` | 10000ms | 文件大小不可控 |
| 数据导出 | 路径含 `export`/`download`/`report` | 30000ms | 大量数据处理，天然慢 |
| 数据导入/洗数据 | 路径含 `import`/`batch`/`sync`/`migrate` | 60000ms | 批量操作，耗时长 |
| 聚合统计 | 路径含 `statistics`/`summary`/`dashboard`/`analytics` | 5000ms | 复杂计算 |

**方式三：全局默认值 — 兜底**

如果用例没有指定、特征也无法匹配，使用全局默认值 `3000ms`。可在环境配置中覆盖：

```markdown
## 环境配置
- DEFAULT_RESPONSE_TIME: 3000
```

**优先级**：用例级别 > 接口特征推断 > 全局默认值

**报告中的展示**：

```
| # | 用例 | 接口 | 耗时 | 阈值 | 阈值来源 | 结果 |
|---|------|------|------|------|---------|------|
| 1 | 用户登录 | POST /login | 320ms | 1000ms | 自动推断(认证) | ✅ |
| 2 | 订单列表 | GET /orders | 1850ms | 2000ms | 自动推断(列表) | ✅ |
| 3 | 数据导出 | GET /export | 8500ms | 30000ms | 自动推断(导出) | ✅ |
| 4 | 商品详情 | GET /products/1 | 2100ms | 500ms | 用例指定 | ❌ |
```

**断言执行逻辑**：
1. 先校验状态码
2. 校验响应时间（如配置了 `@responseTimeLt`）
3. 解析响应体 JSON
4. 递归对比预期响应与实际响应
5. 遇到 `@` 开头的特殊断言，执行对应校验逻辑
6. 记录每个断言的通过/失败状态

#### 2.6 提取变量

如果用例定义了 `提取变量`，从响应中提取值存入变量池：

```
提取变量：token = response.data.token
→ 从实际响应中读取 data.token 的值，存入变量池 token
```

#### 2.7 记录结果

```
用例名称 | 状态 | 耗时 | 失败原因（如有）
```

#### 2.8 执行异常处理

测试执行中不可避免会遇到非预期情况，按以下规则处理：

| 异常场景 | 判定方式 | 处理 |
|---------|---------|------|
| **连接失败** | curl exit code 非 0（如 7=连接拒绝, 28=超时） | 标记该用例为 `ERROR`，记录 curl 错误码和信息，继续执行下一个无依赖的用例 |
| **响应非 JSON** | 响应体无法 `json` 解析（如返回 HTML 错误页） | 标记为 `ERROR`，报告中展示响应体前 500 字符，提示用户检查服务状态 |
| **变量提取失败** | 响应中目标路径不存在（如 `response.data.token` 但 `data` 为 null） | 标记当前用例为 `FAIL`，变量池中该变量置为 `__EXTRACT_FAILED__`，依赖该变量的后续用例自动跳过 |
| **变量未定义** | 请求中引用 `{{varName}}` 但变量池中不存在 | 标记为 `ERROR`，不发送请求，报告中提示缺失变量来源 |
| **HTTP 重定向** | 状态码 301/302 | 不自动跟随重定向，记录实际状态码和 `Location` 头，让用户决定是否调整 |
| **状态码 5xx** | 服务端错误 | 正常记录，如果连续 3 个用例都返回 5xx，暂停执行并提示用户检查服务 |

**用例状态扩展**：

| 状态 | 含义 |
|------|------|
| `PASS` ✅ | 所有断言通过 |
| `FAIL` ❌ | 请求成功但断言未通过 |
| `ERROR` ⚠️ | 请求本身异常（连接失败、非 JSON、变量缺失等） |
| `SKIP` ⏭️ | 前置依赖失败/出错，自动跳过 |

### Step 3: 生成测试报告

#### 报告格式

```markdown
# API 测试报告

**执行时间**：2026-02-21 14:30:00
**目标环境**：staging（https://staging-api.example.com）
**接口协议**：REST
**测试范围**：订单模块（用户选择）+ 前置依赖 2 个（自动补充）
**总用例数**：15
**通过**：11 ✅
**失败**：2 ❌
**异常**：1 ⚠️（连接超时）
**跳过**：1 ⏭️（依赖的前置用例失败）

## 总览

| # | 用例 | 接口 | 状态 | 耗时 |
|---|------|------|------|------|
| 1 | 用户注册-正常 | POST /api/v1/users/register | ✅ 通过 | 120ms |
| 2 | 用户登录-正常 | POST /api/v1/users/login | ✅ 通过 | 85ms |
| 3 | 获取用户信息 | GET /api/v1/users/profile | ❌ 失败 | 95ms |

## 失败详情

### ❌ 用例 3：获取用户信息

**接口**：GET /api/v1/users/profile

**请求**：
​```
GET /api/v1/users/profile
Authorization: Bearer eyJhbG...
​```

**预期**：
​```json
{
  "code": 0,
  "data": {
    "username": "testuser001",
    "email": "test001@example.com"
  }
}
​```

**实际**：
​```json
{
  "code": 0,
  "data": {
    "username": "testuser001",
    "email": null
  }
}
​```

**失败断言**：
- `data.email`：预期 `"test001@example.com"`，实际 `null`

## 跳过的用例

| 用例 | 原因 |
|------|------|
| 用例 8：修改用户头像 | 前置依赖"用例 3"失败，自动跳过 |

## 变量池快照

| 变量 | 值 | 来源用例 |
|------|-----|---------|
| userId | 10042 | 用例 1 |
| token | eyJhbG... | 用例 2 |
```

---

## 高级特性

### 接口依赖链

支持多层依赖，自动拓扑排序执行：

```
用例 1（注册）→ 提取 userId
  └→ 用例 2（登录）→ 提取 token
      └→ 用例 3（查看信息）→ 需要 token
      └→ 用例 4（修改信息）→ 需要 token + userId
```

**规则**：
- 前置用例失败时，依赖它的所有后续用例自动标记为「跳过」
- 循环依赖检测：发现循环时报错并提示用户修正

### GraphQL 支持

除 REST API 外，同样支持 GraphQL 接口测试。

**识别方式**：
- 接口文档中路径统一为 `/graphql`（或 `/gql`）
- 请求体包含 `query` 或 `mutation` 字段
- 项目代码中存在 `.graphql` / `.gql` schema 文件

**请求构造**：

GraphQL 请求统一用 POST 方法，Body 为 JSON：

```bash
curl -s -w "\n---HTTP_STATUS_CODE---%{http_code}" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{token}}" \
  -d '{
    "query": "mutation CreateOrder($input: OrderInput!) { createOrder(input: $input) { id status totalAmount } }",
    "variables": {
      "input": {
        "productId": "{{productId}}",
        "quantity": 2
      }
    }
  }' \
  "${BASE_URL}/graphql"
```

**测试用例格式**（Markdown）：

```markdown
## 用例：创建订单 - GraphQL

- 接口：POST /graphql
- 操作类型：mutation
- 请求体：
  ```json
  {
    "query": "mutation CreateOrder($input: OrderInput!) { createOrder(input: $input) { id status } }",
    "variables": {
      "input": { "productId": "{{productId}}", "quantity": 2 }
    }
  }
  ```
- 预期状态码：200
- 预期响应：
  ```json
  {
    "data": {
      "createOrder": {
        "id": "@isNotEmpty",
        "status": "PENDING"
      }
    }
  }
  ```
- 提取变量：`orderId = response.data.createOrder.id`
```

**GraphQL 特有的断言**：

| 断言 | 说明 |
|------|------|
| `"errors": "@isNull"` | 无错误（正向用例） |
| `"errors[0].message": "@contains(xxx)"` | 错误消息包含指定内容（异常用例） |
| `"errors[0].extensions.code": "UNAUTHENTICATED"` | 错误码匹配（鉴权测试） |
| `"data.fieldName": null` | 异常时 data 字段为 null |

**与 REST 的差异处理**：

| 项目 | REST | GraphQL |
|------|------|---------|
| 路径 | 每个接口不同路径 | 统一 `/graphql` |
| 方法 | GET/POST/PUT/DELETE | 统一 POST |
| 错误响应 | HTTP 状态码 4xx/5xx | 状态码 200 + `errors` 数组 |
| 断言重点 | 状态码 + 响应体 | `data` 字段 + `errors` 是否为空 |
| 接口区分 | 按 URL 路径 | 按 operation name（`query`/`mutation` 名称） |

### 批量数据驱动

同一个接口，多组数据：

```markdown
## 用例组：用户注册 - 参数校验

| 场景 | username | password | email | 预期状态码 | 预期 message |
|------|----------|----------|-------|-----------|-------------|
| 正常注册 | user001 | Test@123 | a@b.com | 201 | success |
| 用户名为空 | | Test@123 | a@b.com | 400 | 用户名不能为空 |
| 密码过短 | user002 | 123 | a@b.com | 400 | 密码长度不足 |
| 邮箱格式错误 | user003 | Test@123 | invalid | 400 | 邮箱格式错误 |
```

### 测试数据清理

测试执行完毕后，如果测试文档中定义了清理步骤，按顺序执行：

```markdown
## 清理步骤

1. DELETE /api/v1/users/{{userId}}
2. 确认返回 200
```

---

## 工作流程总结

```
用户触发测试（可直接指定范围，如"测用户模块"/"跑 P0"/"回归测试"）
  ↓
Step 0: 探测 + 解析 + 范围选择
  ├── 0.0 探测接口协议（REST / GraphQL / JSON-RPC / 自定义 / 混合）
  ├── 0.1 解析接口文档 + 测试数据 + 签名配置
  ├── 0.2 确定测试范围（自然语言匹配 / 交互式选择）
  │     └── 自动补充前置依赖
  └── 0.3 构建执行计划 → 用户确认
  ↓
Step 1: 环境准备
  ├── 选择目标环境（dev/staging/prod）
  ├── 检查连通性
  └── 初始化变量池
  ↓
Step 2: 按依赖顺序执行用例
  ├── 变量替换
  ├── 签名计算（如需要）
  ├── 构造请求（REST / GraphQL）
  ├── 发送请求
  ├── 断言校验（状态码 + 响应时间分级阈值 + 响应体）
  ├── 提取变量
  └── 异常处理（连接失败/非 JSON/变量缺失 → ERROR 状态）
  ↓
Step 3: 生成测试报告（PASS / FAIL / ERROR / SKIP 四种状态）
  ↓
询问用户：
  ├── 重跑失败/出错用例
  ├── 查看某个用例详情
  ├── 修改测试数据重新执行
  └── 测试完成
```

---

## 注意事项

- **安全**：不要在报告中明文展示完整的 Authorization Token，只显示前 10 位 + `...`
- **超时**：每个请求默认 10 秒超时，超时视为失败
- **编码**：请求体和响应体统一使用 UTF-8
- **幂等性**：注意 POST 接口的幂等性问题，重复执行可能产生重复数据
- **环境隔离**：提醒用户确认测试环境，避免误操作生产环境
- **大文件上传**：如果接口涉及文件上传，使用 `-F "file=@filepath"` 方式
- **HTTPS 证书**：测试环境自签证书时，使用 `curl -k` 跳过校验

## 反模式

1. **不看文档直接猜参数**：所有请求参数必须来自文档或测试数据，不能凭空构造
2. **忽略依赖顺序**：有依赖关系的接口必须按顺序执行
3. **只看状态码不看响应体**：状态码 200 不代表业务正确，必须校验响应内容
4. **测试数据污染**：测试完成后应提供清理建议或执行清理步骤
5. **在生产环境执行**：执行前必须确认目标环境

---

## 示例

### 示例 1：标准 REST API 测试

**用户**："帮我根据这份接口文档和测试用例跑一下接口测试"

**执行**：
1. 读取用户指定的接口文档和测试数据文档
2. 解析出 12 个测试用例，构建依赖图
3. 确认目标环境 `http://localhost:8080`
4. 按拓扑顺序执行，实时输出每个用例结果
5. 生成完整测试报告

### 示例 2：参数校验批量测试

**用户**："这个注册接口需要做参数校验测试，测试文档里有一个表格列了所有场景"

**执行**：
1. 解析表格中的多组数据
2. 同一接口，逐行执行不同参数组合
3. 汇总哪些校验通过、哪些不符合预期

### 示例 3：带鉴权的接口链

**用户**："先登录拿到 token，再用 token 测后面的接口"

**执行**：
1. 执行登录接口，提取 token 存入变量池
2. 后续接口自动注入 `Authorization: Bearer {{token}}`
3. 如果 token 过期，提示用户重新执行登录用例
