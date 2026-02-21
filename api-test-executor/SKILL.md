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

### 3. 环境配置（可选）

```markdown
## 环境变量

- BASE_URL: http://localhost:8080
- AUTH_TOKEN: （留空，由登录接口动态获取）
- DB_HOST: localhost
- TIMEOUT: 10000
```

---

## 执行流程

### Step 0: 解析输入

1. **定位文档**：让用户提供接口文档和测试数据文档的路径
2. **解析接口文档**：
   - Swagger/OpenAPI → 解析 paths、schemas、parameters
   - Markdown → 提取接口路径、方法、参数、响应结构
   - Postman Collection → 解析 item 数组
   - 代码路由 → 扫描 Controller/Router 注解/装饰器
3. **解析测试数据**：提取每个用例的请求数据、预期结果、依赖关系
4. **构建依赖图**：根据用例间的依赖关系确定执行顺序

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

#### 2.2 构造请求

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

#### 2.3 执行请求 & 捕获响应

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

#### 2.4 断言校验

| 断言类型 | 语法 | 说明 |
|---------|------|------|
| 状态码 | `status == 200` | 精确匹配 HTTP 状态码 |
| 精确匹配 | `"field": "value"` | 响应字段值完全相等 |
| 非空断言 | `"field": "@isNotEmpty"` | 字段存在且不为空 |
| 类型断言 | `"field": "@isNumber"` | 字段值为数字类型 |
| 包含断言 | `"field": "@contains(substring)"` | 字段值包含指定子串 |
| 数组长度 | `"field": "@lengthGt(0)"` | 数组长度大于指定值 |
| 正则匹配 | `"field": "@matches(^\\d{4}$)"` | 字段值匹配正则表达式 |
| 忽略字段 | `"field": "@any"` | 跳过该字段不做校验 |

**断言执行逻辑**：
1. 先校验状态码
2. 解析响应体 JSON
3. 递归对比预期响应与实际响应
4. 遇到 `@` 开头的特殊断言，执行对应校验逻辑
5. 记录每个断言的通过/失败状态

#### 2.5 提取变量

如果用例定义了 `提取变量`，从响应中提取值存入变量池：

```
提取变量：token = response.data.token
→ 从实际响应中读取 data.token 的值，存入变量池 token
```

#### 2.6 记录结果

```
用例名称 | 状态 | 耗时 | 失败原因（如有）
```

### Step 3: 生成测试报告

#### 报告格式

```markdown
# API 测试报告

**执行时间**：2026-02-21 14:30:00
**目标环境**：http://localhost:8080
**总用例数**：15
**通过**：12 ✅
**失败**：2 ❌
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
用户提供文档路径
  ↓
Step 0: 解析接口文档 + 测试数据文档
  ↓
Step 1: 确认环境 + 检查连通性
  ↓
Step 2: 拓扑排序 → 逐个执行用例
  ├── 变量替换
  ├── 构造请求
  ├── 发送请求
  ├── 断言校验
  └── 提取变量
  ↓
Step 3: 生成测试报告
  ↓
询问用户：
  ├── 重跑失败用例
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
