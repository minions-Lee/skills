#!/bin/bash
#
# install-npm-codex-v2ray.sh - 开发工具安装脚本
# 安装内容: Node.js + npm, OpenAI Codex CLI, v2rayA
#
# 使用方法: sudo bash install-npm-codex-v2ray.sh
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
NC='\033[0m' # No Color

# v2rayA 配置
V2RAYA_WEB_PORT=2017      # v2rayA Web 管理界面端口

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检测函数
check_installed() {
    local name=$1
    local check_cmd=$2

    log_info "检测 $name ..."
    if eval "$check_cmd" &>/dev/null; then
        log_success "$name 已安装，跳过"
        return 0
    fi
    return 1
}

# 检测操作系统
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        OS="centos"
    else
        OS="unknown"
    fi
    log_info "检测到操作系统: $OS $OS_VERSION"
}

# ============================================
# Node.js + npm 安装
# ============================================
install_nodejs() {
    if check_installed "Node.js" "command -v node"; then
        node_version=$(node -v)
        log_info "当前版本: $node_version"
        return 0
    fi

    log_info "安装 Node.js ..."

    # 方案1: 使用 NodeSource 仓库安装 (推荐，速度快)
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        log_info "使用 NodeSource 仓库安装 Node.js 20.x ..."
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        yum install -y nodejs
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        log_info "使用 NodeSource 仓库安装 Node.js 20.x ..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
    else
        # 方案2: 直接下载二进制包
        log_info "直接下载 Node.js 二进制包 ..."
        NODE_VERSION="v20.11.0"
        cd /tmp
        curl -LO https://npmmirror.com/mirrors/node/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz
        tar -xf node-${NODE_VERSION}-linux-x64.tar.xz -C /usr/local/
        ln -sf /usr/local/node-${NODE_VERSION}-linux-x64/bin/node /usr/local/bin/node
        ln -sf /usr/local/node-${NODE_VERSION}-linux-x64/bin/npm /usr/local/bin/npm
        ln -sf /usr/local/node-${NODE_VERSION}-linux-x64/bin/npx /usr/local/bin/npx
        rm -f node-${NODE_VERSION}-linux-x64.tar.xz
    fi

    # 配置 npm 使用淘宝镜像
    npm config set registry https://registry.npmmirror.com

    log_success "Node.js 安装完成: $(node -v)"
    log_success "npm 版本: $(npm -v)"
    log_info "npm 镜像: $(npm config get registry)"
}

# ============================================
# OpenAI Codex CLI 安装
# ============================================
install_codex() {
    if check_installed "OpenAI Codex" "command -v codex"; then
        log_info "当前版本: $(codex --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    log_info "安装 OpenAI Codex CLI ..."

    # 确保 npm 可用
    if ! command -v npm &>/dev/null; then
        log_error "npm 未安装，请先安装 Node.js"
        return 1
    fi

    npm install -g @openai/codex

    log_success "OpenAI Codex CLI 安装完成"
    log_info "使用前需要设置 OPENAI_API_KEY 或登录 ChatGPT"
    log_info "运行 'codex' 后选择 'Sign in with ChatGPT' 登录"
}

# ============================================
# v2rayA 安装 (带 Web UI 的 V2Ray 客户端)
# ============================================
install_v2raya() {
    if check_installed "v2rayA" "command -v v2raya"; then
        log_info "v2rayA 已安装"
        if systemctl is-active --quiet v2raya 2>/dev/null; then
            log_success "v2rayA 服务正在运行"
            log_info "Web 管理界面: http://127.0.0.1:${V2RAYA_WEB_PORT}"
        else
            log_warn "v2rayA 服务未运行，尝试启动..."
            systemctl start v2raya || true
        fi
        return 0
    fi

    log_info "安装 v2rayA ..."

    # v2rayA 需要 v2ray-core 作为后端
    if ! command -v v2ray &>/dev/null && ! command -v xray &>/dev/null; then
        log_info "安装 v2ray-core (v2rayA 后端)..."
        install_v2ray_core
    fi

    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        install_v2raya_rpm
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        install_v2raya_deb
    else
        log_error "不支持的操作系统: $OS"
        log_info "请参考官方文档手动安装: https://v2raya.org/docs/prologue/installation/"
        return 1
    fi

    # 启动服务
    systemctl daemon-reload
    systemctl enable v2raya
    systemctl start v2raya

    # 验证启动
    sleep 2
    if systemctl is-active --quiet v2raya; then
        log_success "v2rayA 服务启动成功"
    else
        log_error "v2rayA 服务启动失败，查看日志:"
        journalctl -u v2raya --no-pager -n 20
        return 1
    fi

    # 配置防火墙
    if command -v firewall-cmd &>/dev/null; then
        firewall-cmd --permanent --add-port=${V2RAYA_WEB_PORT}/tcp
        firewall-cmd --reload
        log_info "防火墙已开放端口 ${V2RAYA_WEB_PORT}"
    elif command -v ufw &>/dev/null; then
        ufw allow ${V2RAYA_WEB_PORT}/tcp
        log_info "UFW 已开放端口 ${V2RAYA_WEB_PORT}"
    else
        log_warn "请手动开放防火墙端口: ${V2RAYA_WEB_PORT}"
    fi

    log_success "v2rayA 安装完成"
    echo ""
    echo -e "${GREEN}========== v2rayA 配置信息 ==========${NC}"
    echo -e "Web 管理界面: http://127.0.0.1:${V2RAYA_WEB_PORT}"
    echo -e ""
    echo -e "${YELLOW}首次使用说明:${NC}"
    echo -e "1. 浏览器访问 http://<服务器IP>:${V2RAYA_WEB_PORT}"
    echo -e "2. 创建管理员账号"
    echo -e "3. 导入订阅链接或手动添加节点"
    echo -e "4. 选择节点并启动代理"
    echo -e ""
    echo -e "${YELLOW}重要: 如果使用阿里云/腾讯云，需要在安全组开放端口 ${V2RAYA_WEB_PORT}${NC}"
    echo -e "${GREEN}====================================${NC}"
    echo ""
}

# GitHub 镜像源 (国内加速)
GITHUB_MIRROR="https://gh.ddlc.top"

# 安装 v2ray-core (v2rayA 后端)
install_v2ray_core() {
    log_info "下载 v2ray-core..."
    cd /tmp

    # 确保 unzip 已安装
    if ! command -v unzip &>/dev/null; then
        if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
            yum install -y unzip
        elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
            apt-get install -y unzip
        fi
    fi

    # 动态获取最新版本的下载链接
    log_info "获取 v2ray-core 最新版本..."
    V2RAY_URL_ORIG=$(curl -s "https://api.github.com/repos/v2fly/v2ray-core/releases/latest" | \
        grep "browser_download_url" | \
        grep "v2ray-linux-64.zip" | \
        grep -v "sha256\|dgst" | \
        head -1 | \
        cut -d'"' -f4)

    if [ -z "$V2RAY_URL_ORIG" ]; then
        log_error "无法获取 v2ray-core 下载链接"
        return 1
    fi

    # 使用国内镜像加速
    V2RAY_URL="${GITHUB_MIRROR}/${V2RAY_URL_ORIG}"
    log_info "下载链接: $V2RAY_URL"
    rm -f v2ray.zip

    # 下载 (超时 10 分钟)
    if curl -fL --connect-timeout 15 --max-time 600 --progress-bar -o v2ray.zip "$V2RAY_URL"; then
        FILE_SIZE=$(stat -c%s v2ray.zip 2>/dev/null || stat -f%z v2ray.zip 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -gt 10000000 ]; then
            if unzip -t v2ray.zip &>/dev/null; then
                log_success "下载成功 (${FILE_SIZE} bytes)"
            else
                log_error "ZIP 文件验证失败"
                return 1
            fi
        else
            log_error "下载文件太小，可能不完整"
            return 1
        fi
    else
        log_error "v2ray-core 下载失败"
        return 1
    fi

    # 解压安装
    mkdir -p /tmp/v2ray-install
    unzip -o v2ray.zip -d /tmp/v2ray-install/

    # 安装到系统目录
    mkdir -p /usr/local/share/v2ray
    cp /tmp/v2ray-install/v2ray /usr/local/bin/
    cp /tmp/v2ray-install/*.dat /usr/local/share/v2ray/ 2>/dev/null || true
    chmod +x /usr/local/bin/v2ray

    rm -rf /tmp/v2ray-install v2ray.zip
    log_success "v2ray-core 安装完成"
}

# CentOS/RHEL 安装 v2rayA
install_v2raya_rpm() {
    log_info "通过 RPM 安装 v2rayA..."

    cd /tmp

    # 动态获取最新版本的下载链接
    log_info "获取 v2rayA 最新版本..."
    V2RAYA_URL_ORIG=$(curl -s "https://api.github.com/repos/v2rayA/v2rayA/releases/latest" | \
        grep "browser_download_url" | \
        grep "installer_redhat_x64_" | \
        grep -v "sha256" | \
        head -1 | \
        cut -d'"' -f4)

    if [ -z "$V2RAYA_URL_ORIG" ]; then
        log_error "无法获取 v2rayA 下载链接"
        return 1
    fi

    # 使用国内镜像加速
    V2RAYA_URL="${GITHUB_MIRROR}/${V2RAYA_URL_ORIG}"
    log_info "下载链接: $V2RAYA_URL"
    rm -f v2raya.rpm

    # 下载 (超时 10 分钟)
    if curl -fL --connect-timeout 15 --max-time 600 --progress-bar -o v2raya.rpm "$V2RAYA_URL"; then
        FILE_SIZE=$(stat -c%s v2raya.rpm 2>/dev/null || stat -f%z v2raya.rpm 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -gt 1000000 ]; then
            log_success "下载成功 (${FILE_SIZE} bytes)"
        else
            log_error "下载文件太小，可能不完整"
            return 1
        fi
    else
        log_error "v2rayA 下载失败"
        return 1
    fi

    rpm -Uvh v2raya.rpm
    rm -f v2raya.rpm
    log_success "v2rayA RPM 安装完成"
}

# Ubuntu/Debian 安装 v2rayA (直接下载 deb 包)
install_v2raya_deb() {
    log_info "通过 DEB 包安装 v2rayA..."

    cd /tmp

    # 动态获取最新版本的下载链接
    log_info "获取 v2rayA 最新版本..."
    V2RAYA_URL_ORIG=$(curl -s "https://api.github.com/repos/v2rayA/v2rayA/releases/latest" | \
        grep "browser_download_url" | \
        grep "installer_debian_x64_" | \
        grep -v "sha256" | \
        head -1 | \
        cut -d'"' -f4)

    if [ -z "$V2RAYA_URL_ORIG" ]; then
        log_error "无法获取 v2rayA 下载链接"
        return 1
    fi

    # 使用国内镜像加速
    V2RAYA_URL="${GITHUB_MIRROR}/${V2RAYA_URL_ORIG}"
    log_info "下载链接: $V2RAYA_URL"
    rm -f v2raya.deb

    # 下载 (超时 10 分钟)
    if curl -fL --connect-timeout 15 --max-time 600 --progress-bar -o v2raya.deb "$V2RAYA_URL"; then
        FILE_SIZE=$(stat -c%s v2raya.deb 2>/dev/null || stat -f%z v2raya.deb 2>/dev/null || echo "0")
        if [ "$FILE_SIZE" -gt 1000000 ]; then
            log_success "下载成功 (${FILE_SIZE} bytes)"
        else
            log_error "下载文件太小，可能不完整"
            return 1
        fi
    else
        log_error "v2rayA 下载失败"
        return 1
    fi

    dpkg -i v2raya.deb || apt-get install -f -y
    rm -f v2raya.deb
    log_success "v2rayA DEB 安装完成"
}

# ============================================
# 主函数
# ============================================
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      开发工具安装脚本 v1.1                  ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # 检测操作系统
    detect_os

    # 1. 安装 Node.js + npm
    echo ""
    echo -e "${YELLOW}[1/3] Node.js + npm${NC}"
    install_nodejs

    # 2. 安装 OpenAI Codex CLI
    echo ""
    echo -e "${YELLOW}[2/3] OpenAI Codex CLI${NC}"
    install_codex

    # 3. 安装 v2rayA
    echo ""
    echo -e "${YELLOW}[3/3] v2rayA${NC}"
    install_v2raya

    echo ""
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}      所有开发工具安装完成!                   ${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo ""

    # 显示安装结果汇总
    echo "安装结果汇总:"
    command -v node &>/dev/null && echo "  - Node.js: $(node -v)"
    command -v npm &>/dev/null && echo "  - npm: $(npm -v)"
    command -v codex &>/dev/null && echo "  - OpenAI Codex: $(codex --version 2>/dev/null || echo '已安装')"
    command -v v2raya &>/dev/null && echo "  - v2rayA: http://127.0.0.1:${V2RAYA_WEB_PORT}"
    echo ""
}

# 执行主函数
main "$@"
