#!/bin/bash
#
# generate-nginx-config.sh - Nginx 配置生成器
# 根据参数生成 Nginx server 配置和 active 配置
#
# 使用方法: bash generate-nginx-config.sh
#

# 确保使用 bash 运行
if [ -z "$BASH_VERSION" ]; then
    exec bash "$0" "$@"
fi

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 默认配置
NGINX_CONF_DIR="/usr/local/nginx/conf"

# ============================================
# 收集参数
# ============================================
collect_params() {
    echo ""
    echo -e "${BLUE}=== Nginx 配置生成器 ===${NC}"
    echo ""

    read -p "项目名称: " PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        log_error "项目名称不能为空"
        exit 1
    fi

    read -p "监听端口 [81]: " LISTEN_PORT
    LISTEN_PORT=${LISTEN_PORT:-81}

    read -p "服务器地址 (多个用空格分隔) [127.0.0.1]: " SERVER_NAME
    SERVER_NAME=${SERVER_NAME:-127.0.0.1}

    read -p "后端端口 [8083]: " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-8083}

    read -p "Nginx 配置目录 [${NGINX_CONF_DIR}]: " CUSTOM_CONF_DIR
    NGINX_CONF_DIR=${CUSTOM_CONF_DIR:-$NGINX_CONF_DIR}

    # SSE 路径配置
    echo ""
    echo "SSE 流式接口路径 (默认包含标准路径，直接回车使用默认):"
    echo "  - api/agent/stream"
    echo "  - api/agent/intent/recognition/stream"
    echo "  - api/agent/wardrobe/entry/stream"
    echo "  - api/agent/plan-execute/stream"
    echo "  - agent/admin/plan-execute/stream"
    read -p "是否使用自定义 SSE 路径? [y/N]: " CUSTOM_SSE

    if [[ "$CUSTOM_SSE" =~ ^[Yy] ]]; then
        echo "请输入 SSE 路径 (每行一个，输入空行结束):"
        SSE_PATHS=()
        while true; do
            read -p "> " path
            [ -z "$path" ] && break
            SSE_PATHS+=("$path")
        done
    else
        SSE_PATHS=(
            "api/agent/stream"
            "api/agent/intent/recognition/stream"
            "api/agent/wardrobe/entry/stream"
            "api/agent/plan-execute/stream"
            "agent/admin/plan-execute/stream"
        )
    fi

    # 确认
    echo ""
    echo -e "${YELLOW}=== 参数确认 ===${NC}"
    echo "项目名称:     $PROJECT_NAME"
    echo "监听端口:     $LISTEN_PORT"
    echo "服务器地址:   $SERVER_NAME"
    echo "后端端口:     $BACKEND_PORT"
    echo "配置目录:     $NGINX_CONF_DIR"
    echo "SSE 路径数:   ${#SSE_PATHS[@]}"
    echo ""
    read -p "确认生成? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        log_warn "已取消"
        exit 0
    fi
}

# ============================================
# 生成 SSE 路径正则
# ============================================
generate_sse_regex() {
    local paths=("$@")
    local regex=""

    for path in "${paths[@]}"; do
        if [ -n "$regex" ]; then
            regex="${regex}|"
        fi
        regex="${regex}${PROJECT_NAME}/${path}"
    done

    echo "$regex"
}

# ============================================
# 生成配置文件
# ============================================
generate_configs() {
    local SITE_CONF="${NGINX_CONF_DIR}/sites-available/${PROJECT_NAME}.conf"
    local ACTIVE_CONF="${NGINX_CONF_DIR}/active_${PROJECT_NAME}.conf"

    # 确保目录存在
    mkdir -p "${NGINX_CONF_DIR}/sites-available"
    mkdir -p "${NGINX_CONF_DIR}/sites-enabled"

    # 生成 SSE 正则
    SSE_REGEX=$(generate_sse_regex "${SSE_PATHS[@]}")

    log_info "生成 Active 配置: $ACTIVE_CONF"
    cat > "$ACTIVE_CONF" << EOF
set \$backend_host 127.0.0.1:${BACKEND_PORT};
EOF

    log_info "生成 Server 配置: $SITE_CONF"
    cat > "$SITE_CONF" << EOF
# Nginx 配置
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 生成工具: generate-nginx-config.sh
server {
    listen ${LISTEN_PORT};
    server_name ${SERVER_NAME};

    # 动态后端配置 (蓝绿部署切换)
    include ${NGINX_CONF_DIR}/active_${PROJECT_NAME}.conf;

    # SSE 流式接口
    location ~ ^/(${SSE_REGEX}) {
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

    # 创建软链接
    ln -sf "$SITE_CONF" "${NGINX_CONF_DIR}/sites-enabled/${PROJECT_NAME}.conf"

    log_success "配置生成完成"
}

# ============================================
# 验证配置
# ============================================
verify_config() {
    log_info "验证 Nginx 配置..."

    if nginx -t 2>&1; then
        log_success "配置验证通过"

        read -p "是否重载 Nginx? [Y/n]: " RELOAD
        if [[ ! "$RELOAD" =~ ^[Nn] ]]; then
            nginx -s reload
            log_success "Nginx 已重载"
        fi
    else
        log_error "配置验证失败，请检查配置文件"
        exit 1
    fi
}

# ============================================
# 主函数
# ============================================
main() {
    collect_params
    generate_configs
    verify_config

    echo ""
    echo -e "${GREEN}=== 完成 ===${NC}"
    echo "Server 配置: ${NGINX_CONF_DIR}/sites-available/${PROJECT_NAME}.conf"
    echo "Active 配置: ${NGINX_CONF_DIR}/active_${PROJECT_NAME}.conf"
    echo ""
}

main "$@"
