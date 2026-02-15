#!/bin/bash
#
# init-project.sh - 项目初始化脚本
# 功能: Git clone + Docker 配置生成 + Nginx 配置生成 + 蓝绿部署脚本
#
# 使用方法: bash init-project.sh
#

# 确保使用 bash 运行
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

set -e

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/../templates"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ============================================
# SSH 密钥检测
# ============================================
check_ssh_key() {
    local SSH_PUB="$HOME/.ssh/id_rsa.pub"

    log_info "检测 SSH 密钥 ..."

    if [ -f "$SSH_PUB" ]; then
        log_success "SSH 密钥已存在"
        echo ""
        echo -e "${GREEN}========== SSH 公钥 ==========${NC}"
        cat "$SSH_PUB"
        echo -e "${GREEN}===============================${NC}"
        echo ""
    else
        log_warn "未检测到 SSH 密钥，正在生成..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t rsa -b 4096 -C "server-$(hostname)-$(date +%Y%m%d)" -f "$HOME/.ssh/id_rsa" -N ""
        chmod 600 "$HOME/.ssh/id_rsa"
        chmod 644 "$SSH_PUB"
        log_success "SSH 密钥生成完成"
        echo ""
        echo -e "${GREEN}========== 新生成的 SSH 公钥 ==========${NC}"
        cat "$SSH_PUB"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "${YELLOW}请将上述公钥添加到 Git 仓库的 SSH Keys 中，然后按 Enter 继续...${NC}"
        read -r
    fi
}

# ============================================
# 收集项目参数
# ============================================
collect_params() {
    echo ""
    echo -e "${BLUE}=== 项目初始化参数收集 ===${NC}"
    echo ""

    # 必填参数
    read -p "Git 仓库地址 (必填): " GIT_URL
    if [ -z "$GIT_URL" ]; then
        log_error "Git 仓库地址不能为空"
        exit 1
    fi

    # 从 Git URL 提取默认项目名
    DEFAULT_PROJECT_NAME=$(basename "$GIT_URL" .git)
    read -p "项目名称 [${DEFAULT_PROJECT_NAME}]: " PROJECT_NAME
    PROJECT_NAME=${PROJECT_NAME:-$DEFAULT_PROJECT_NAME}

    # 可选参数
    read -p "主容器端口 [8083]: " PORT_PRIMARY
    PORT_PRIMARY=${PORT_PRIMARY:-8083}

    read -p "备容器端口 [8084]: " PORT_SECONDARY
    PORT_SECONDARY=${PORT_SECONDARY:-8084}

    read -p "Nginx 端口 [81]: " NGINX_PORT
    NGINX_PORT=${NGINX_PORT:-81}

    read -p "主调试端口 [31053]: " DEBUG_PORT_PRIMARY
    DEBUG_PORT_PRIMARY=${DEBUG_PORT_PRIMARY:-31053}

    read -p "备调试端口 [31054]: " DEBUG_PORT_SECONDARY
    DEBUG_PORT_SECONDARY=${DEBUG_PORT_SECONDARY:-31054}

    read -p "Spring Profile [test]: " SPRING_PROFILE
    SPRING_PROFILE=${SPRING_PROFILE:-test}

    read -p "健康检查路径 [/ops/healthCheck]: " HEALTH_PATH
    HEALTH_PATH=${HEALTH_PATH:-/ops/healthCheck}

    read -p "服务器 IP/域名 (多个用空格分隔) [127.0.0.1]: " SERVER_NAME
    SERVER_NAME=${SERVER_NAME:-127.0.0.1}

    # 计算衍生变量
    DOCKER_ROOT="/usr/local/www/${PROJECT_NAME}-docker"
    CODE_DIR="${PROJECT_NAME}"

    # 确认参数
    echo ""
    echo -e "${YELLOW}=== 参数确认 ===${NC}"
    echo "Git 地址:       $GIT_URL"
    echo "项目名称:       $PROJECT_NAME"
    echo "项目目录:       $DOCKER_ROOT"
    echo "代码目录:       $DOCKER_ROOT/$CODE_DIR"
    echo "主容器端口:     $PORT_PRIMARY"
    echo "备容器端口:     $PORT_SECONDARY"
    echo "Nginx 端口:     $NGINX_PORT"
    echo "调试端口:       $DEBUG_PORT_PRIMARY / $DEBUG_PORT_SECONDARY"
    echo "Spring Profile: $SPRING_PROFILE"
    echo "健康检查:       $HEALTH_PATH"
    echo "服务器地址:     $SERVER_NAME"
    echo ""
    read -p "确认以上参数? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        log_warn "已取消"
        exit 0
    fi
}

# ============================================
# 创建目录结构
# ============================================
create_directories() {
    log_info "创建目录结构: $DOCKER_ROOT"

    mkdir -p "$DOCKER_ROOT"
    mkdir -p "$DOCKER_ROOT/logs"
    mkdir -p "$DOCKER_ROOT/wechat"

    log_success "目录创建完成"
}

# ============================================
# Git Clone
# ============================================
git_clone() {
    log_info "克隆代码仓库..."

    cd "$DOCKER_ROOT"

    if [ -d "$CODE_DIR/.git" ]; then
        log_warn "代码目录已存在，执行 git pull..."
        cd "$CODE_DIR"
        git pull
    else
        git clone "$GIT_URL" "$CODE_DIR"
    fi

    log_success "代码克隆完成"
}

# ============================================
# 生成 docker-compose.yml
# ============================================
generate_docker_compose() {
    log_info "生成 docker-compose.yml..."

    cat > "$DOCKER_ROOT/docker-compose.yml" << EOF
# docker-compose.yml
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
services:
  builder:
    image: docker.m.daocloud.io/library/maven:3.9.6-eclipse-temurin-17
    working_dir: /app
    volumes:
      - ./${CODE_DIR}:/app/${CODE_DIR}
      - ~/.m2:/root/.m2
    command: mvn -f ${CODE_DIR}/pom.xml clean package -DskipTests
    mem_limit: 1024mb
    cpu_quota: 150000

  ${PROJECT_NAME}:
    build:
      context: .
      dockerfile: Dockerfile
    pull_policy: never
    container_name: ${PROJECT_NAME}
    ports:
      - "${PORT_PRIMARY}:8080"
      - "${DEBUG_PORT_PRIMARY}:31050"
    dns:
      - 8.8.8.8
      - 8.8.4.4
    volumes:
      - ./logs:/root/logs
      - ./wechat:/root/wechat/
    environment:
      - SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}

  ${PROJECT_NAME}2:
    build:
      context: .
      dockerfile: Dockerfile
    pull_policy: never
    container_name: ${PROJECT_NAME}2
    ports:
      - "${PORT_SECONDARY}:8080"
      - "${DEBUG_PORT_SECONDARY}:31050"
    dns:
      - 8.8.8.8
      - 8.8.4.4
    volumes:
      - ./logs:/root/logs
      - ./wechat:/root/wechat/
    environment:
      - SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}
EOF

    log_success "docker-compose.yml 生成完成"
}

# ============================================
# 生成 Dockerfile
# ============================================
generate_dockerfile() {
    log_info "生成 Dockerfile..."

    cat > "$DOCKER_ROOT/Dockerfile" << EOF
# Dockerfile
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
FROM docker.m.daocloud.io/library/eclipse-temurin:17-jdk
WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/\$TZ /etc/localtime && echo \$TZ > /etc/timezone

COPY ./${CODE_DIR}/${CODE_DIR}-web/target/${PROJECT_NAME}.jar ${PROJECT_NAME}.jar

# 开放端口
EXPOSE 8080

# 设置默认 profile
ENV SPRING_PROFILES_ACTIVE=${SPRING_PROFILE}

# 启动应用
CMD ["java", "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:31050", "-Dspring.devtools.restart.enabled=false", "-jar", "${PROJECT_NAME}.jar"]
EOF

    log_success "Dockerfile 生成完成"
}

# ============================================
# 生成 Nginx 配置
# ============================================
generate_nginx_config() {
    log_info "生成 Nginx 配置..."

    local NGINX_CONF_DIR="/usr/local/nginx/conf"
    local SITE_CONF="${NGINX_CONF_DIR}/sites-available/${PROJECT_NAME}.conf"
    local ACTIVE_CONF="${NGINX_CONF_DIR}/active_${PROJECT_NAME}.conf"

    # 确保目录存在
    mkdir -p "${NGINX_CONF_DIR}/sites-available"

    # 生成 active 配置 (动态后端)
    cat > "$ACTIVE_CONF" << EOF
set \$backend_host 127.0.0.1:${PORT_PRIMARY};
EOF

    # 生成 server 配置
    cat > "$SITE_CONF" << EOF
# Nginx 配置
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
server {
    listen ${NGINX_PORT};
    server_name ${SERVER_NAME};

    include ${NGINX_CONF_DIR}/active_${PROJECT_NAME}.conf;

    # SSE 流式接口 (需要特殊配置)
    location ~ ^/(${PROJECT_NAME}/api/agent/(stream|intent/recognition/stream|wardrobe/entry/stream|plan-execute/stream)|${PROJECT_NAME}/agent/admin/plan-execute/stream) {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With, traceid, platform, source, version, noncestr, did, idfa, imei, oaid, finger, token, timestamp, sign";
        add_header Access-Control-Allow-Credentials false;
        add_header Access-Control-Max-Age 86400;

        proxy_pass http://\$backend_host;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

        # SSE 专用配置
        proxy_buffering off;
        proxy_cache off;
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        send_timeout 300s;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding on;
    }

    # 普通接口
    location /${PROJECT_NAME}/ {
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With, traceid, platform, source, version, noncestr, did, idfa, imei, oaid, finger, token, timestamp, sign";
        add_header Access-Control-Allow-Credentials false;
        add_header Access-Control-Max-Age 86400;

        proxy_pass http://\$backend_host;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

    # 创建软链接到 sites-enabled
    mkdir -p "${NGINX_CONF_DIR}/sites-enabled"
    ln -sf "$SITE_CONF" "${NGINX_CONF_DIR}/sites-enabled/${PROJECT_NAME}.conf"

    log_success "Nginx 配置生成完成"
    log_info "配置文件: $SITE_CONF"
    log_info "Active 配置: $ACTIVE_CONF"

    # 检查是否需要在主配置中 include
    if ! grep -q "include.*sites-enabled" "${NGINX_CONF_DIR}/nginx.conf" 2>/dev/null; then
        log_warn "请在 ${NGINX_CONF_DIR}/nginx.conf 的 http 块中添加:"
        echo "    include ${NGINX_CONF_DIR}/sites-enabled/*.conf;"
    fi
}

# ============================================
# 生成蓝绿部署脚本
# ============================================
generate_restart_script() {
    log_info "生成蓝绿部署脚本..."

    local RESTART_SCRIPT="${DOCKER_ROOT}/restart-${PROJECT_NAME}"

    cat > "$RESTART_SCRIPT" << 'SCRIPT_EOF'
#!/bin/bash

set -e
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
  for i in {1..100}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 __PROJECT_NAME__2..."
          echo "set \$backend_host 127.0.0.1:__PORT_SECONDARY__;" > /usr/local/nginx/conf/active___PROJECT_NAME__.conf

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:__NGINX_PORT__/__PROJECT_NAME____HEALTH_PATH__" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ __PROJECT_NAME__2 服务已健康启动，准备停止旧容器 __PROJECT_NAME__（等待 60 秒以完成任务）"
            sleep 60
            echo "⛔️ 停止 __PROJECT_NAME__ 容器..."
            docker-compose stop __PROJECT_NAME__
            docker-compose rm -f __PROJECT_NAME__
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，3 秒后重试..."
      sleep 3
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
  for i in {1..100}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 __PROJECT_NAME__..."
          echo "set \$backend_host 127.0.0.1:__PORT_PRIMARY__;" > /usr/local/nginx/conf/active___PROJECT_NAME__.conf

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:__NGINX_PORT__/__PROJECT_NAME____HEALTH_PATH__" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ __PROJECT_NAME__ 服务已健康启动，准备停止旧容器 __PROJECT_NAME__2（等待 60 秒以完成任务）"
            sleep 60
            echo "⛔️ 停止 __PROJECT_NAME__2 容器..."
            docker-compose stop __PROJECT_NAME__2 || true
            docker-compose rm -f __PROJECT_NAME__2 || true
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，3 秒后重试..."
      sleep 3
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
    sed -i "s|__PROJECT_NAME__|${PROJECT_NAME}|g" "$RESTART_SCRIPT"
    sed -i "s|__DOCKER_ROOT__|${DOCKER_ROOT}|g" "$RESTART_SCRIPT"
    sed -i "s|__CODE_DIR__|${CODE_DIR}|g" "$RESTART_SCRIPT"
    sed -i "s|__PORT_PRIMARY__|${PORT_PRIMARY}|g" "$RESTART_SCRIPT"
    sed -i "s|__PORT_SECONDARY__|${PORT_SECONDARY}|g" "$RESTART_SCRIPT"
    sed -i "s|__NGINX_PORT__|${NGINX_PORT}|g" "$RESTART_SCRIPT"
    sed -i "s|__HEALTH_PATH__|${HEALTH_PATH}|g" "$RESTART_SCRIPT"

    chmod +x "$RESTART_SCRIPT"

    # 创建全局可执行软链接
    ln -sf "$RESTART_SCRIPT" "/usr/local/bin/restart-${PROJECT_NAME}"
    log_success "蓝绿部署脚本生成完成: $RESTART_SCRIPT"
    log_info "全局命令已创建: restart-${PROJECT_NAME}"
}

# ============================================
# 首次构建
# ============================================
first_build() {
    read -p "是否执行首次构建? [Y/n]: " DO_BUILD
    if [[ "$DO_BUILD" =~ ^[Nn] ]]; then
        log_info "跳过首次构建"
        return 0
    fi

    log_info "执行首次构建..."

    cd "$DOCKER_ROOT"

    # 运行 builder
    docker-compose run --rm builder

    # 构建并启动主容器
    docker-compose up --build -d "${PROJECT_NAME}"

    log_success "首次构建完成，容器已启动"
    docker ps | grep "${PROJECT_NAME}"
}

# ============================================
# 主函数
# ============================================
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      项目初始化脚本 v1.0                   ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # 1. 检测 SSH 密钥
    check_ssh_key

    # 2. 收集参数
    collect_params

    # 3. 创建目录
    create_directories

    # 4. Git clone
    git_clone

    # 5. 生成 docker-compose.yml
    generate_docker_compose

    # 6. 生成 Dockerfile
    generate_dockerfile

    # 7. 生成 Nginx 配置
    generate_nginx_config

    # 8. 生成蓝绿部署脚本
    generate_restart_script

    # 9. 首次构建 (可选)
    first_build

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}      项目初始化完成!                       ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""
    echo "项目目录:        $DOCKER_ROOT"
    echo "代码目录:        $DOCKER_ROOT/$CODE_DIR"
    echo "Docker Compose:  $DOCKER_ROOT/docker-compose.yml"
    echo "Dockerfile:      $DOCKER_ROOT/Dockerfile"
    echo "部署脚本:        $DOCKER_ROOT/restart-${PROJECT_NAME}"
    echo "Nginx 配置:      /usr/local/nginx/conf/sites-available/${PROJECT_NAME}.conf"
    echo ""
    echo "后续操作:"
    echo "  1. 重载 Nginx:  nginx -s reload"
    echo "  2. 部署更新:    $DOCKER_ROOT/restart-${PROJECT_NAME}"
    echo ""
}

# 执行主函数
main "$@"
