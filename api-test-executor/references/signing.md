# API 签名脚本规范

## 签名流程

```
构造请求参数 → 按规则排序/拼接 → 执行签名计算 → 注入请求头或参数 → 发送请求
```

## 签名配置

在测试数据文档或环境配置中定义：

```markdown
## 签名配置

- 签名算法：HmacSHA256 | MD5 | RSA-SHA256
- App Key：{{APP_KEY}}
- App Secret：{{APP_SECRET}}
- 签名脚本路径：./scripts/sign.sh
- 签名位置：Header（X-Signature） | Query（sign=xxx）
- 时间戳字段：timestamp（秒级/毫秒级）
- Nonce 字段：nonce（随机字符串）
```

## 内置签名模板

### 模板 1：通用 HMAC-SHA256

```
待签名字符串 = HTTP_METHOD + "\n" + PATH + "\n" + SORTED_PARAMS + "\n" + TIMESTAMP + "\n" + NONCE
签名值 = HMAC-SHA256(待签名字符串, APP_SECRET)
```

```bash
SIGN_STRING="${METHOD}\n${PATH}\n${SORTED_PARAMS}\n${TIMESTAMP}\n${NONCE}"
SIGNATURE=$(echo -ne "$SIGN_STRING" | openssl dgst -sha256 -hmac "${APP_SECRET}" -binary | base64)
```

### 模板 2：MD5 参数签名

```
参数按 key 字母序排列 → key1=value1&key2=value2&...&key=APP_SECRET
签名值 = MD5(拼接字符串).toUpperCase()
```

### 模板 3：自定义签名脚本

```bash
SIGNATURE=$(bash ./scripts/sign.sh \
  --method "${METHOD}" \
  --path "${PATH}" \
  --body "${BODY_JSON}" \
  --timestamp "${TIMESTAMP}" \
  --app-key "${APP_KEY}" \
  --app-secret "${APP_SECRET}")
```

## 签名注入

| 注入位置 | 方式 |
|---------|------|
| Header | `-H "X-Signature: ${SIGNATURE}" -H "X-Timestamp: ${TIMESTAMP}" -H "X-Nonce: ${NONCE}"` |
| Query | URL 追加 `&sign=${SIGNATURE}&timestamp=${TIMESTAMP}&nonce=${NONCE}` |
| Body | JSON body 中追加签名字段 |

> **安全提示**：APP_SECRET 不应出现在测试报告中，仅在执行时从环境变量或配置文件读取。
