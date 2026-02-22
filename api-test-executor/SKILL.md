---
name: api-test-executor
description: |
  基于接口文档和接口测试文档执行 API 测试。读取接口定义（Swagger/OpenAPI/Markdown/Postman/代码路由），
  结合测试文档中的 mock 数据和预期结果，自动构造请求、执行测试并生成报告。
  自动探测接口协议（REST、GraphQL、JSON-RPC、自定义 HTTP）和项目环境配置。
  支持环境变量替换、接口依赖链、签名注入、多环境切换、批量执行和断言校验。
  触发词：API 测试、接口测试、执行测试用例、跑接口、测试接口、api test、
  run api tests、接口验证、mock 测试、接口回归、回归测试。
---

# API 测试执行器

**文档驱动，数据隔离，链式执行，断言严格。**

所有请求参数来自用户提供的文档和测试数据，不凭空构造。

## 目录

- [输入要求](#输入要求)
- [执行流程](#执行流程)
- [断言语法](#断言语法)
- [异常处理](#异常处理)
- [测试报告](#测试报告)
- [注意事项](#注意事项)

## 参考文档与脚本

| 资源 | 路径 | 何时使用 |
|------|------|---------|
| 请求执行脚本 | `scripts/api-request.sh` | 每次执行 API 请求时调用 |
| Mock 数据模板 | `references/mock-templates.md` | 需要理解测试数据格式或 mock 占位符时 |
| 接口协议探测 | `references/protocol-detection.md` | 探测项目使用 REST/GraphQL/JSON-RPC 时 |
| 代码扫描与环境探测 | `references/code-scanning.md` | 从代码提取 API Schema 或探测环境配置时 |
| 测试范围策略 | `references/test-strategies.md` | 选择测试范围（按模块/优先级/Diff/链路）时 |
| 签名脚本 | `references/signing.md` | 接口需要 HMAC/MD5/RSA 签名时 |
| 响应时间规范 | `references/response-time.md` | 配置或推断响应时间阈值时 |

---

## 输入要求

### 1. 接口文档（必须）

| 格式 | 说明 |
|------|------|
| Swagger/OpenAPI (JSON/YAML) | 标准 API 描述文件 |
| Markdown 接口文档 | 含路径、方法、参数、响应结构 |
| Postman Collection (JSON) | 导出的 Postman 集合 |
| 代码路由定义 | 扫描项目代码，详见 [references/code-scanning.md](references/code-scanning.md) |

### 2. 测试数据文档（必须）

每个用例需包含：

| 字段 | 必须 | 说明 |
|------|------|------|
| 用例名称 | ✅ | 描述测试目的 |
| 接口路径 + 方法 | ✅ | `POST /api/v1/users/register` |
| 请求参数 | ✅ | Body/Query/Path 参数（mock 数据） |
| 预期状态码 | ✅ | 200、201、400 等 |
| 预期响应 | ✅ | 完整响应体或关键字段断言 |
| 请求头 | 可选 | 如 `Authorization: Bearer {{token}}` |
| 前置依赖 | 可选 | 依赖哪个用例的返回值 |
| 提取变量 | 可选 | `token = response.data.token` |

**示例**：

```markdown
## 用例 1：用户登录

- 接口：POST /api/v1/users/login
- 请求体：
  ```json
  { "username": "testuser001", "password": "Test@12345" }
  ```
- 预期状态码：200
- 预期响应：
  ```json
  { "code": 0, "data": { "token": "@isNotEmpty" } }
  ```
- 提取变量：`token = response.data.token`

## 用例 2：获取用户信息

- 接口：GET /api/v1/users/profile
- 请求头：`Authorization: Bearer {{token}}`
- 前置依赖：用例 1
- 预期状态码：200
- 预期响应：
  ```json
  { "code": 0, "data": { "username": "testuser001" } }
  ```
```

Mock 数据模板格式（单用例/表格批量/JSON 结构化）和占位符语法详见 [references/mock-templates.md](references/mock-templates.md)。

### 3. 环境配置（可选）

支持多环境定义：

```markdown
### dev
- BASE_URL: http://localhost:8080

### staging
- BASE_URL: https://staging-api.example.com

### prod ⚠️ 只读
- BASE_URL: https://api.example.com
- READ_ONLY: true
```

未提供时自动探测项目配置，详见 [references/code-scanning.md](references/code-scanning.md) 的「环境配置探测」章节。

---

## 执行流程

```
用户触发（可直接指定范围，如"测用户模块"/"跑 P0"/"回归测试"）
  ↓
Step 0: 探测协议 → 解析文档 → 选择范围 → 构建执行计划
  ↓
Step 1: 选择环境 → 检查连通性 → 初始化变量池
  ↓
Step 2: 按依赖顺序逐个执行用例（变量替换 → 签名 → 请求 → 断言 → 提取变量）
  ↓
Step 3: 生成测试报告
```

### Step 0: 解析与范围选择

#### 0.0 探测接口协议

判定项目使用 REST / GraphQL / JSON-RPC / 自定义 HTTP / 混合模式。
探测信号和各协议请求构造规则详见 [references/protocol-detection.md](references/protocol-detection.md)。

#### 0.1 解析接口文档

1. Swagger/OpenAPI → 解析 paths、schemas、parameters
2. Markdown → 提取路径、方法、参数、响应结构
3. Postman Collection → 解析 item 数组
4. 代码路由 → 按 [references/code-scanning.md](references/code-scanning.md) 扫描（自动识别语言和框架）

同时解析测试数据文档中的用例、签名配置。

#### 0.2 确定测试范围

用户可在触发时直接指定：

| 用户说法 | 映射策略 |
|---------|---------|
| "测用户模块" | 按模块筛选 |
| "跑 P0" / "只测核心" | 按优先级筛选 |
| "回归测试" / "测这次改的" | 按 git diff 筛选 |
| "测下单流程" | 按依赖链路展开 |
| "全量测试" | 全部接口 |
| 未指定 | 展示统计，交互式选择 |

5 种范围划分策略和组合推荐详见 [references/test-strategies.md](references/test-strategies.md)。

**无论选择哪种范围，自动补充前置依赖接口**（如选了创建订单，自动补充登录接口获取 token）。

#### 0.3 构建执行计划

筛选接口 → 补充依赖 → 构建依赖图 → 输出摘要让用户确认。

### Step 1: 环境准备

**环境选择优先级**：

| 优先级 | 场景 | 处理 |
|--------|------|------|
| 1 | 用户指定（如"在 staging 上跑"） | 直接匹配 |
| 2 | 文档定义多个环境 | 列出让用户选择 |
| 3 | 文档只有一个环境 | 直接使用 |
| 4 | 文档无配置 | 自动探测项目配置文件 |
| 5 | 探测无结果 | 询问用户输入 BASE_URL |

- 环境名含 `prod` / `production` → **二次确认**，`READ_ONLY: true` 时仅执行 GET
- 自动探测规则详见 [references/code-scanning.md](references/code-scanning.md) 的「环境配置探测」章节

**检查连通性**：

```bash
scripts/api-request.sh -m GET -u "${BASE_URL}/health" -t 5000
```

初始化变量池（存储接口间传递的动态变量）。

### Step 2: 按依赖顺序执行用例

对每个用例：

#### 2.1 变量替换

将 `{{变量名}}` 替换为变量池中的实际值。

#### 2.2 签名计算（如需要）

按签名配置计算签名值并注入请求，详见 [references/signing.md](references/signing.md)。

#### 2.3 构造并执行请求

使用 `scripts/api-request.sh` 执行请求：

```bash
RESULT=$(scripts/api-request.sh \
  -m "${METHOD}" \
  -u "${BASE_URL}${PATH}" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"key":"value"}' \
  -t 10000)

# 解析结果
STATUS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['status'])")
BODY=$(echo "$RESULT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['body'])")
TIME_MS=$(echo "$RESULT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['time_ms'])")
ERROR=$(echo "$RESULT" | python3 -c "import sys,json; print(json.loads(sys.stdin.read())['error'])")
```

**脚本输出格式**：

```json
{ "status": 200, "body": "{...}", "time_ms": 123, "error": "", "curl_exit": 0 }
```

**参数位置映射**：

| 位置 | 处理方式 |
|------|---------|
| Path 参数 | 替换 URL 中的 `{param}` |
| Query 参数 | 拼接 `?key=value&key2=value2` |
| Body | `-d` 传 JSON |
| Form | 需要 `-H "Content-Type: multipart/form-data"` + curl `-F` |
| Header | `-H` 逐个添加 |

#### 2.4 断言校验

按优先级依次校验：状态码 → 响应时间 → 响应体字段。详见下方[断言语法](#断言语法)。

#### 2.5 提取变量

从响应中提取值存入变量池：`token = response.data.token`。

#### 2.6 记录结果

记录用例名称、状态（PASS/FAIL/ERROR/SKIP）、耗时、失败原因。

### Step 3: 生成测试报告

报告包含：

- **总览**：环境、协议、范围、通过/失败/异常/跳过统计
- **结果表**：每个用例的接口、状态、耗时
- **失败详情**：请求内容、预期 vs 实际、失败的断言
- **跳过的用例**：原因说明
- **变量池快照**：所有提取的变量及来源

报告完成后询问用户：重跑失败用例 / 查看详情 / 修改数据重测 / 结束。

---

## 断言语法

| 语法 | 说明 | 示例 |
|------|------|------|
| `status == 200` | HTTP 状态码 | |
| `"field": "value"` | 精确匹配 | `"username": "test"` |
| `"field": "@isNotEmpty"` | 非空 | `"token": "@isNotEmpty"` |
| `"field": "@isNull"` | 为空 | `"error": "@isNull"` |
| `"field": "@isNumber"` | 数字类型 | `"count": "@isNumber"` |
| `"field": "@contains(sub)"` | 包含子串 | `"msg": "@contains(成功)"` |
| `"field": "@lengthGt(N)"` | 数组长度 > N | `"list": "@lengthGt(0)"` |
| `"field": "@matches(regex)"` | 正则匹配 | `"id": "@matches(^\\d+$)"` |
| `"field": "@between(min,max)"` | 范围 | `"age": "@between(1,150)"` |
| `"field": "@any"` | 跳过校验 | `"timestamp": "@any"` |
| `@responseTimeLt(N)` | 响应时间 < N ms | 用例级别标注 |

**响应时间阈值**优先级：用例指定 > 按接口特征自动推断 > 全局默认 3000ms。
推断规则详见 [references/response-time.md](references/response-time.md)。

---

## 异常处理

| 异常 | 判定 | 处理 |
|------|------|------|
| 连接失败 | `curl_exit` 非 0 | 标记 `ERROR`，记录错误信息 |
| 响应非 JSON | body 无法解析 | 标记 `ERROR`，展示前 500 字符 |
| 变量提取失败 | 目标路径不存在 | 标记 `FAIL`，依赖该变量的后续用例 `SKIP` |
| 变量未定义 | `{{var}}` 不在变量池 | 标记 `ERROR`，不发送请求 |
| 连续 3 个 5xx | 服务端持续出错 | 暂停执行，提示检查服务 |

**用例状态**：

| 状态 | 含义 |
|------|------|
| `PASS` ✅ | 所有断言通过 |
| `FAIL` ❌ | 请求成功但断言未通过 |
| `ERROR` ⚠️ | 请求异常（连接失败、非 JSON、变量缺失） |
| `SKIP` ⏭️ | 前置依赖失败，自动跳过 |

---

## 高级特性

### 接口依赖链

支持多层依赖，自动拓扑排序。前置失败时级联跳过。循环依赖自动检测并报错。

### 批量数据驱动

同一接口多组数据，用表格格式定义（详见 [references/mock-templates.md](references/mock-templates.md) 的模板格式 B）。

### 测试数据清理

测试文档中定义清理步骤时，执行完毕后按顺序执行清理请求。

---

## 注意事项

- **安全**：报告中 Token 只显示前 10 位 + `...`；APP_SECRET 不出现在报告中
- **超时**：默认 10 秒，可通过 `-t` 参数调整
- **编码**：统一 UTF-8
- **幂等**：POST 接口重复执行可能产生重复数据，提醒用户
- **环境隔离**：执行前确认环境，prod 环境二次确认
- **HTTPS 证书**：自签证书使用 `-k` 参数
- **能力边界**：单请求功能测试，不支持并发压测（需压测建议 wrk / k6 / JMeter）

## 反模式

1. **猜参数**：所有参数必须来自文档，不凭空构造
2. **忽略依赖**：有依赖的接口必须按顺序执行
3. **只看状态码**：200 不代表业务正确，必须校验响应体
4. **不清理数据**：测试后提供清理建议
5. **误操作生产**：执行前确认目标环境
