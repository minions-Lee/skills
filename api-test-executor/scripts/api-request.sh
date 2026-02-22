#!/usr/bin/env bash
# API 请求执行脚本
# 统一处理 curl 请求构造、执行、响应解析，输出标准化 JSON 结果。
#
# 用法:
#   ./api-request.sh -m METHOD -u URL [-H "Header: Value"]... [-d body] [-t timeout_ms] [-k]
#
# 输出 (stdout JSON):
#   {
#     "status": 200,
#     "body": "{...}",
#     "time_ms": 123,
#     "error": "",
#     "curl_exit": 0
#   }
#
# 示例:
#   ./api-request.sh -m GET -u "http://localhost:8080/api/users" -H "Authorization: Bearer token123"
#   ./api-request.sh -m POST -u "http://localhost:8080/api/login" -d '{"username":"test","password":"123"}' -t 5000

set -euo pipefail

METHOD=""
URL=""
BODY=""
TIMEOUT_MS=10000
INSECURE=""
declare -a HEADERS=()

# 解析参数
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--method)  METHOD="$2"; shift 2 ;;
    -u|--url)     URL="$2"; shift 2 ;;
    -H|--header)  HEADERS+=("-H" "$2"); shift 2 ;;
    -d|--data)    BODY="$2"; shift 2 ;;
    -t|--timeout) TIMEOUT_MS="$2"; shift 2 ;;
    -k|--insecure) INSECURE="-k"; shift ;;
    *) echo "{\"status\":0,\"body\":\"\",\"time_ms\":0,\"error\":\"Unknown arg: $1\",\"curl_exit\":1}" && exit 1 ;;
  esac
done

# 参数校验
if [[ -z "$METHOD" || -z "$URL" ]]; then
  echo '{"status":0,"body":"","time_ms":0,"error":"Missing required: -m METHOD -u URL","curl_exit":1}'
  exit 1
fi

# 超时转秒（curl 用秒）
TIMEOUT_SEC=$(( TIMEOUT_MS / 1000 ))
[[ $TIMEOUT_SEC -lt 1 ]] && TIMEOUT_SEC=1

# 构造 curl 参数
CURL_ARGS=(
  -s
  -w '\n__CURL_META__%{http_code}|%{time_total}'
  -X "$METHOD"
  --max-time "$TIMEOUT_SEC"
  --connect-timeout 5
)

# 添加 headers
if [[ ${#HEADERS[@]} -gt 0 ]]; then
  CURL_ARGS+=("${HEADERS[@]}")
fi

# 添加 body
if [[ -n "$BODY" ]]; then
  # 自动添加 Content-Type（如果用户未指定）
  HAS_CT=false
  for h in "${HEADERS[@]}"; do
    if [[ "$h" =~ [Cc]ontent-[Tt]ype ]]; then
      HAS_CT=true
      break
    fi
  done
  if [[ "$HAS_CT" == false ]]; then
    CURL_ARGS+=(-H "Content-Type: application/json")
  fi
  CURL_ARGS+=(-d "$BODY")
fi

# 添加 insecure
if [[ -n "$INSECURE" ]]; then
  CURL_ARGS+=(-k)
fi

# 执行请求（stderr 单独捕获，避免混入 body）
CURL_EXIT=0
STDERR_FILE=$(mktemp)
RAW_OUTPUT=$(curl "${CURL_ARGS[@]}" "$URL" 2>"$STDERR_FILE") || CURL_EXIT=$?
CURL_STDERR=$(cat "$STDERR_FILE" 2>/dev/null || true)
rm -f "$STDERR_FILE"

# 解析结果
if [[ $CURL_EXIT -ne 0 ]]; then
  ERROR_MSG=""
  case $CURL_EXIT in
    6)  ERROR_MSG="DNS resolution failed" ;;
    7)  ERROR_MSG="Connection refused" ;;
    28) ERROR_MSG="Request timeout (${TIMEOUT_MS}ms)" ;;
    35) ERROR_MSG="SSL/TLS error" ;;
    52) ERROR_MSG="Empty response from server" ;;
    56) ERROR_MSG="Network data receive error" ;;
    *)  ERROR_MSG="curl error code $CURL_EXIT" ;;
  esac
  ESCAPED_STDERR=$(printf '%s' "$CURL_STDERR" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo '""')
  echo "{\"status\":0,\"body\":\"\",\"time_ms\":0,\"error\":\"${ERROR_MSG}\",\"detail\":${ESCAPED_STDERR},\"curl_exit\":${CURL_EXIT}}"
  exit 0
fi

# 分离响应体和元数据
RESPONSE_BODY=$(echo "$RAW_OUTPUT" | sed '$s/__CURL_META__.*$//')
META_LINE=$(echo "$RAW_OUTPUT" | grep -o '__CURL_META__.*$' || echo "__CURL_META__000|0")
META=${META_LINE#__CURL_META__}

HTTP_STATUS=$(echo "$META" | cut -d'|' -f1)
TIME_TOTAL=$(echo "$META" | cut -d'|' -f2)

# 时间转毫秒（time_total 是秒，如 0.123）
TIME_MS=$(python3 -c "print(int(float('${TIME_TOTAL}') * 1000))" 2>/dev/null || echo "0")

# 转义 body 为合法 JSON 字符串
ESCAPED_BODY=$(printf '%s' "$RESPONSE_BODY" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || echo '""')

echo "{\"status\":${HTTP_STATUS},\"body\":${ESCAPED_BODY},\"time_ms\":${TIME_MS},\"error\":\"\",\"curl_exit\":0}"
