# 接口协议探测规范

## 目录

- [探测信号](#探测信号)
- [JSON-RPC 请求构造](#json-rpc-请求构造)
- [混合模式处理](#混合模式处理)
- [探测结果输出](#探测结果输出)

---

## 探测信号

| 信号来源 | 探测方式 | 判定 |
|---------|---------|------|
| 接口文档 | 统一 `POST /graphql` + `query`/`mutation` | GraphQL |
| 接口文档 | 路径多样（`GET /users`、`POST /orders`），方法多样 | REST |
| 接口文档 | 统一 `POST /rpc` 或 `POST /api`，Body 含 `method`+`params` | JSON-RPC |
| 接口文档 | 以上都不匹配，但有路径 + 方法 + 参数 | 自定义 HTTP |
| 代码扫描 | 依赖含 `apollo-server`/`graphql-yoga`/`type-graphql` | GraphQL |
| 代码扫描 | 依赖含 `json-rpc`/`jayson`/`jsonrpclib` | JSON-RPC |
| 代码扫描 | 存在 `.graphql`/`.gql` schema 文件 | GraphQL |
| 代码扫描 | Controller/Handler 中同时存在多种风格 | 混合模式 |

## JSON-RPC 请求构造

```bash
curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc": "2.0", "method": "user.getProfile", "params": {"userId": "{{userId}}"}, "id": 1}' \
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

## 混合模式处理

项目同时使用多种协议时，按接口逐个标记协议类型：

```
接口清单：
  POST /api/v1/users/register     → REST
  POST /api/v1/users/login        → REST
  POST /graphql (createOrder)     → GraphQL
  POST /rpc (payment.process)     → JSON-RPC
```

构造请求时按各自协议规则处理。

## 探测结果输出

```
🔍 协议探测结果：

  检测到项目使用 REST 风格接口（47 个）
  未发现 GraphQL / JSON-RPC 端点

  依据：
  - 接口路径多样，方法覆盖 GET/POST/PUT/DELETE
  - 项目依赖未包含 GraphQL 或 JSON-RPC 相关库
```

混合场景：
```
🔍 协议探测结果：

  REST 接口：35 个
  GraphQL 端点：1 个（/graphql，包含 12 个 operation）

  将按各自协议规则构造请求和断言。
```
