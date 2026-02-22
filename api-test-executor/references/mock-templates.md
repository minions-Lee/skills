# Mock 数据模板与用例格式规范

## 目录

- [模板格式 A：单用例完整定义](#模板格式-a单用例完整定义)
- [模板格式 B：表格批量定义](#模板格式-b表格批量定义)
- [模板格式 C：JSON 结构化定义](#模板格式-cjson-结构化定义)
- [Mock 数据占位符](#mock-数据占位符)
- [用例分类标签](#用例分类标签)

---

## 模板格式 A：单用例完整定义

适用于少量用例、每个用例独立描述的场景。

```markdown
## 用例：{用例编号} - {用例名称}

- 分类：{正向/异常/边界}
- 接口：{METHOD} {PATH}
- 请求头：
  ```
  Content-Type: application/json
  Authorization: Bearer {{token}}
  ```
- Path 参数：`{ "id": "{{userId}}" }`
- Query 参数：`{ "page": 1, "size": 10 }`
- 请求体：
  ```json
  { "field1": "value1", "field2": 123 }
  ```
- 预期状态码：200
- 预期响应：
  ```json
  { "code": 0, "data": { "id": "@isNotEmpty", "list": "@lengthGt(0)" } }
  ```
- 提取变量：`varName = response.data.xxx`
- 前置依赖：用例 {N}
```

## 模板格式 B：表格批量定义

适用于同一接口的多组参数校验、边界值测试。

```markdown
## 用例组：{接口名称} - {测试目的}

- 接口：{METHOD} {PATH}
- 公共请求头：Authorization: Bearer {{token}}

| # | 场景 | 请求体 | 预期状态码 | 预期响应（关键字段） |
|---|------|--------|-----------|-------------------|
| 1 | 正常创建 | `{"name":"test","age":25}` | 200 | `{"code":0,"data.id":"@isNotEmpty"}` |
| 2 | name 为空 | `{"name":"","age":25}` | 400 | `{"code":1001,"message":"@contains(名称)"}` |
| 3 | age 为负数 | `{"name":"test","age":-1}` | 400 | `{"code":1002}` |
```

## 模板格式 C：JSON 结构化定义

适用于从 Postman/Apifox 导出或程序化处理的场景。

```json
{
  "suite": "用户模块接口测试",
  "baseUrl": "{{BASE_URL}}",
  "globalHeaders": { "Content-Type": "application/json" },
  "cases": [
    {
      "id": "TC001",
      "name": "用户注册 - 正常",
      "category": "positive",
      "request": {
        "method": "POST",
        "path": "/api/v1/users/register",
        "body": { "username": "testuser001", "password": "Test@12345", "email": "test001@example.com" }
      },
      "expected": {
        "status": 201,
        "body": { "code": 0, "data": { "userId": "@isNotEmpty" } }
      },
      "extract": { "userId": "response.data.userId" },
      "dependsOn": []
    }
  ]
}
```

## Mock 数据占位符

在执行前自动替换：

| 占位符 | 说明 | 示例输出 |
|--------|------|---------|
| `@randomString(N)` | N 位随机字母数字串 | `aB3kF9xZ` |
| `@randomInt(min,max)` | 范围内随机整数 | `42` |
| `@randomEmail` | 随机邮箱 | `user_a3k9@test.com` |
| `@randomPhone` | 随机手机号 | `13800138000` |
| `@randomUUID` | UUID v4 | `550e8400-...` |
| `@timestamp` | 当前时间戳（秒） | `1708502400` |
| `@timestampMs` | 当前时间戳（毫秒） | `1708502400000` |
| `@datetime` | 当前时间 ISO 格式 | `2026-02-21T14:30:00Z` |
| `@date` | 当前日期 | `2026-02-21` |
| `@randomName` | 随机中文姓名 | `张三` |
| `@randomIdCard` | 随机身份证号 | `310101199001011234` |
| `@sequence(prefix,start)` | 自增序列 | `ORDER_001` |
| `@fromPool(varName)` | 从变量池取值 | 等同于 `{{varName}}` |

## 用例分类标签

| 分类 | 说明 | 示例 |
|------|------|------|
| `positive` | 正向用例，正常流程 | 正确参数注册成功 |
| `negative` | 异常用例，错误输入 | 密码为空、格式错误 |
| `boundary` | 边界值测试 | 最大长度、最小值、0 |
| `auth` | 鉴权相关 | 无 token、过期 token |
| `idempotent` | 幂等性测试 | 同一请求重复发送 |
