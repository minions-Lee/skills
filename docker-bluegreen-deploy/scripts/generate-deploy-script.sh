#!/bin/bash

# Docker 蓝绿部署脚本生成器
# 用法: ./generate-deploy-script.sh

set -e

echo "=== Docker 蓝绿部署脚本生成器 ==="
echo ""

# 收集必需参数
read -p "项目名称 (小写，如 myapp): " PROJECT_NAME
read -p "主容器端口 (如 8083): " PORT_PRIMARY
read -p "备容器端口 (如 8084): " PORT_SECONDARY
read -p "Nginx 对外端口 (如 81): " NGINX_PORT
read -p "健康检查路径 (默认 /ops/healthCheck): " HEALTH_PATH
HEALTH_PATH=${HEALTH_PATH:-/ops/healthCheck}
read -p "Docker 项目根目录 (如 /usr/local/www/${PROJECT_NAME}-docker): " DOCKER_ROOT
DOCKER_ROOT=${DOCKER_ROOT:-/usr/local/www/${PROJECT_NAME}-docker}
read -p "代码子目录名 (默认与项目名相同): " CODE_DIR
CODE_DIR=${CODE_DIR:-$PROJECT_NAME}

# 收集可选参数
read -p "Nginx 配置方式 [variable/proxy_pass] (默认 variable): " NGINX_CONFIG_STYLE
NGINX_CONFIG_STYLE=${NGINX_CONFIG_STYLE:-variable}
read -p "优雅停机等待时间秒 (默认 60): " GRACEFUL_SHUTDOWN_WAIT
GRACEFUL_SHUTDOWN_WAIT=${GRACEFUL_SHUTDOWN_WAIT:-60}
read -p "健康检查重试次数 (默认 100): " HEALTH_CHECK_RETRIES
HEALTH_CHECK_RETRIES=${HEALTH_CHECK_RETRIES:-100}
read -p "健康检查间隔秒 (默认 3): " HEALTH_CHECK_INTERVAL
HEALTH_CHECK_INTERVAL=${HEALTH_CHECK_INTERVAL:-3}

# 生成 Nginx 配置命令
if [[ "$NGINX_CONFIG_STYLE" == "proxy_pass" ]]; then
    NGINX_CMD_PRIMARY="echo \"proxy_pass http://127.0.0.1:${PORT_PRIMARY}/${PROJECT_NAME}/;\" > /usr/local/nginx/conf/active_${PROJECT_NAME}.conf"
    NGINX_CMD_SECONDARY="echo \"proxy_pass http://127.0.0.1:${PORT_SECONDARY}/${PROJECT_NAME}/;\" > /usr/local/nginx/conf/active_${PROJECT_NAME}.conf"
else
    NGINX_CMD_PRIMARY="echo \"set \\\$backend_host 127.0.0.1:${PORT_PRIMARY};\" > /usr/local/nginx/conf/active_${PROJECT_NAME}.conf"
    NGINX_CMD_SECONDARY="echo \"set \\\$backend_host 127.0.0.1:${PORT_SECONDARY};\" > /usr/local/nginx/conf/active_${PROJECT_NAME}.conf"
fi

# 输出文件
OUTPUT_FILE="restart-${PROJECT_NAME}"
read -p "输出文件名 (默认 $OUTPUT_FILE): " CUSTOM_OUTPUT
OUTPUT_FILE=${CUSTOM_OUTPUT:-$OUTPUT_FILE}

cat > "$OUTPUT_FILE" << 'SCRIPT_EOF'
#!/bin/bash

set -e  # 出错即退出
echo "🚀 开始更新 __PROJECT_NAME__ 项目..."

# 1. 拉取代码
echo "📦 拉取最新代码..."
cd __DOCKER_ROOT__/__CODE_DIR__
pull_result=$(git pull)
echo "$pull_result"

# 2. 回到 docker 根目录
cd __DOCKER_ROOT__

# 获取容器状态
__PROJECT_NAME___status=$(docker inspect -f '{{.State.Status}}' __PROJECT_NAME__ 2>/dev/null || echo "not_found")
__PROJECT_NAME__2_status=$(docker inspect -f '{{.State.Status}}' __PROJECT_NAME__2 2>/dev/null || echo "not_found")

echo "当前容器状态：__PROJECT_NAME__=$__PROJECT_NAME___status, __PROJECT_NAME__2=$__PROJECT_NAME__2_status"

# 3. 设置构建决策逻辑
UP_FLAGS="-d"
if [[ "$pull_result" == *"Already up to date"* ]]; then
    echo "✅ 代码已经是最新，将跳过 Maven 编译(builder)并直接启动现有镜像。"
else
    echo "🔧 检测到代码更新，正在执行 builder 容器进行打包..."
    docker-compose run --rm builder
    UP_FLAGS="--build -d"
fi

# 启动目标容器，并健康检查成功后再停止旧容器
if [[ "$__PROJECT_NAME___status" == "running" ]]; then
  echo "🔁 __PROJECT_NAME__ 正在运行，准备切换到 __PROJECT_NAME__2"

  docker-compose stop __PROJECT_NAME__2 || true
  docker-compose rm -f __PROJECT_NAME__2 || true

  echo "🚀 启动 __PROJECT_NAME__2..."
  docker-compose up $UP_FLAGS __PROJECT_NAME__2

  echo "🩺 检查 __PROJECT_NAME__2 健康状态..."
  HEALTH_URL="http://127.0.0.1:__PORT_SECONDARY__/__PROJECT_NAME____HEALTH_PATH__"

  set +e
  for i in {1..__HEALTH_CHECK_RETRIES__}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 __PROJECT_NAME__2..."
          __NGINX_CMD_SECONDARY__

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:__NGINX_PORT__/__PROJECT_NAME____HEALTH_PATH__" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ __PROJECT_NAME__2 服务已健康启动，准备停止旧容器 __PROJECT_NAME__（等待 __GRACEFUL_SHUTDOWN_WAIT__ 秒以完成任务）"
            sleep __GRACEFUL_SHUTDOWN_WAIT__
            echo "⛔️ 停止 __PROJECT_NAME__ 容器..."
            docker-compose stop __PROJECT_NAME__
            docker-compose rm -f __PROJECT_NAME__
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，__HEALTH_CHECK_INTERVAL__ 秒后重试..."
      sleep __HEALTH_CHECK_INTERVAL__
  done
  set -e

  if [[ -z "$code" ]]; then
      echo "❌ 健康检查失败：__PROJECT_NAME__2 未成功启动！"
      exit 1
  fi

elif [[ "$__PROJECT_NAME__2_status" == "running" ]]; then
  echo "🔁 __PROJECT_NAME__2 正在运行，准备切换到 __PROJECT_NAME__"

  docker-compose stop __PROJECT_NAME__ || true
  docker-compose rm -f __PROJECT_NAME__ || true

  echo "🚀 启动 __PROJECT_NAME__..."
  docker-compose up $UP_FLAGS __PROJECT_NAME__

  echo "🩺 检查 __PROJECT_NAME__ 健康状态..."
  HEALTH_URL="http://127.0.0.1:__PORT_PRIMARY__/__PROJECT_NAME____HEALTH_PATH__"

  set +e
  for i in {1..__HEALTH_CHECK_RETRIES__}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 __PROJECT_NAME__..."
          __NGINX_CMD_PRIMARY__

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:__NGINX_PORT__/__PROJECT_NAME____HEALTH_PATH__" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ __PROJECT_NAME__ 服务已健康启动，准备停止旧容器 __PROJECT_NAME__2（等待 __GRACEFUL_SHUTDOWN_WAIT__ 秒以完成任务）"
            sleep __GRACEFUL_SHUTDOWN_WAIT__
            echo "⛔️ 停止 __PROJECT_NAME__2 容器..."
            docker-compose stop __PROJECT_NAME__2 || true
            docker-compose rm -f __PROJECT_NAME__2 || true
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，__HEALTH_CHECK_INTERVAL__ 秒后重试..."
      sleep __HEALTH_CHECK_INTERVAL__
  done
  set -e

  if [[ -z "$code" ]]; then
      echo "❌ 健康检查失败：__PROJECT_NAME__ 未成功启动！"
      exit 1
  fi

else
  echo "⚠️ 没有容器在运行，默认启动 __PROJECT_NAME__"
  docker-compose up $UP_FLAGS __PROJECT_NAME__
fi

# 清理无用的 Docker 镜像
echo "🧹 清理无用的 Docker 镜像..."
docker image prune -f

echo "✅ 更新完成！"
SCRIPT_EOF

# 替换占位符
sed -i '' "s|__PROJECT_NAME__|${PROJECT_NAME}|g" "$OUTPUT_FILE"
sed -i '' "s|__PORT_PRIMARY__|${PORT_PRIMARY}|g" "$OUTPUT_FILE"
sed -i '' "s|__PORT_SECONDARY__|${PORT_SECONDARY}|g" "$OUTPUT_FILE"
sed -i '' "s|__NGINX_PORT__|${NGINX_PORT}|g" "$OUTPUT_FILE"
sed -i '' "s|__HEALTH_PATH__|${HEALTH_PATH}|g" "$OUTPUT_FILE"
sed -i '' "s|__DOCKER_ROOT__|${DOCKER_ROOT}|g" "$OUTPUT_FILE"
sed -i '' "s|__CODE_DIR__|${CODE_DIR}|g" "$OUTPUT_FILE"
sed -i '' "s|__GRACEFUL_SHUTDOWN_WAIT__|${GRACEFUL_SHUTDOWN_WAIT}|g" "$OUTPUT_FILE"
sed -i '' "s|__HEALTH_CHECK_RETRIES__|${HEALTH_CHECK_RETRIES}|g" "$OUTPUT_FILE"
sed -i '' "s|__HEALTH_CHECK_INTERVAL__|${HEALTH_CHECK_INTERVAL}|g" "$OUTPUT_FILE"
sed -i '' "s|__NGINX_CMD_PRIMARY__|${NGINX_CMD_PRIMARY}|g" "$OUTPUT_FILE"
sed -i '' "s|__NGINX_CMD_SECONDARY__|${NGINX_CMD_SECONDARY}|g" "$OUTPUT_FILE"

chmod +x "$OUTPUT_FILE"

echo ""
echo "✅ 脚本已生成: $OUTPUT_FILE"
echo ""
echo "参数汇总:"
echo "  项目名称: $PROJECT_NAME"
echo "  主容器端口: $PORT_PRIMARY"
echo "  备容器端口: $PORT_SECONDARY"
echo "  Nginx 端口: $NGINX_PORT"
echo "  健康检查路径: $HEALTH_PATH"
echo "  Docker 根目录: $DOCKER_ROOT"
echo "  代码目录: $CODE_DIR"
echo "  Nginx 配置方式: $NGINX_CONFIG_STYLE"
