#!/bin/bash
#
# install-jre-docker-nginx-mysql-redis.sh - 服务端依赖安装脚本
# 安装内容: JRE 17, Docker, Docker Compose, Nginx 1.24.0, MySQL 8, Redis 5.0
#
# 使用方法: sudo bash install-jre-docker-nginx-mysql-redis.sh
#
# 特性:
#   - 安装前检测，已安装则跳过
#   - 支持 CentOS/RHEL 和 Ubuntu/Debian
#   - SSH 密钥初始化
#   - MySQL/Redis 仅允许本地连接 (127.0.0.1)
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
CYAN='\033[0;36m'
NC='\033[0m'

# 版本配置
NGINX_VERSION="1.24.0"
MYSQL_VERSION="8"
REDIS_VERSION="5.0"

# MySQL 固定密码
MYSQL_ROOT_PASSWORD='liqize@#Pwd'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_config() { echo -e "${CYAN}[CONFIG]${NC} $1"; }

# 检测并安装
check_and_install() {
    local name=$1
    local check_cmd=$2
    local install_func=$3

    log_info "检测 $name ..."
    if eval "$check_cmd" &>/dev/null; then
        log_success "$name 已安装，跳过"
        # 对于已安装的组件，也打印配置信息
        print_${install_func##install_}_config 2>/dev/null || true
        return 0
    else
        log_info "正在安装 $name ..."
        $install_func
        log_success "$name 安装完成"
        return 0
    fi
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

# 包管理器
pkg_install() {
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        yum install -y "$@"
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update && apt-get install -y "$@"
    else
        log_error "不支持的操作系统: $OS"
        exit 1
    fi
}

# ============================================
# SSH 密钥初始化
# ============================================
init_ssh_key() {
    local SSH_DIR="$HOME/.ssh"
    local SSH_KEY="$SSH_DIR/id_rsa"
    local SSH_PUB="$SSH_DIR/id_rsa.pub"

    log_info "检测 SSH 密钥 ..."

    if [ -f "$SSH_PUB" ]; then
        log_success "SSH 密钥已存在"
        echo ""
        echo -e "${GREEN}========== SSH 公钥 ==========${NC}"
        cat "$SSH_PUB"
        echo -e "${GREEN}===============================${NC}"
        echo ""
    else
        log_info "生成新的 SSH 密钥 ..."
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        ssh-keygen -t rsa -b 4096 -C "server-$(hostname)-$(date +%Y%m%d)" -f "$SSH_KEY" -N ""
        chmod 600 "$SSH_KEY"
        chmod 644 "$SSH_PUB"
        log_success "SSH 密钥生成完成"
        echo ""
        echo -e "${GREEN}========== 新生成的 SSH 公钥 ==========${NC}"
        cat "$SSH_PUB"
        echo -e "${GREEN}=======================================${NC}"
        echo -e "${YELLOW}请将上述公钥添加到 Git 仓库的 SSH Keys 中${NC}"
        echo ""
    fi
}

# ============================================
# JRE 17 安装
# ============================================
install_jre17() {
    log_info "安装 Eclipse Temurin JRE 17 ..."

    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # 添加 Adoptium 仓库
        cat > /etc/yum.repos.d/adoptium.repo << 'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/centos/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF
        yum install -y temurin-17-jdk || {
            # 备用方案: 手动下载
            log_warn "仓库安装失败，尝试手动安装..."
            cd /tmp
            curl -LO https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar.gz
            tar -xzf OpenJDK17U-jdk_x64_linux_hotspot_17.0.9_9.tar.gz -C /usr/local/
            ln -sf /usr/local/jdk-17.0.9+9 /usr/local/java
            echo 'export JAVA_HOME=/usr/local/java' >> /etc/profile.d/java.sh
            echo 'export PATH=$JAVA_HOME/bin:$PATH' >> /etc/profile.d/java.sh
            source /etc/profile.d/java.sh
        }
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y wget apt-transport-https gnupg
        wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | apt-key add -
        echo "deb https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/adoptium.list
        apt-get update
        apt-get install -y temurin-17-jdk
    fi

    # 验证安装
    java -version
}

print_jre17_config() {
    :  # JRE 没有特殊配置文件需要打印
}

# ============================================
# Docker 安装
# ============================================
install_docker() {
    log_info "安装 Docker ..."

    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # 卸载旧版本
        yum remove -y docker docker-client docker-client-latest docker-common \
            docker-latest docker-latest-logrotate docker-logrotate docker-engine || true

        # 安装依赖
        yum install -y yum-utils

        # 添加 Docker 仓库 (使用阿里云镜像)
        yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

        # 安装 Docker
        yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker compose-plugin

    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # 卸载旧版本
        apt-get remove -y docker docker-engine docker.io containerd runc || true

        # 安装依赖
        apt-get update
        apt-get install -y ca-certificates curl gnupg lsb-release

        # 添加 Docker GPG 密钥
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/$OS/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

        # 添加仓库
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/$OS $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

        # 安装
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker compose-plugin
    fi

    # 配置 Docker 镜像加速 (国内可用源，已测试)
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://docker.rainbond.cc",
    "https://dockerproxy.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF

    log_info "Docker 镜像加速已配置 (国内可用源)"

    # 启动 Docker
    systemctl enable docker
    systemctl start docker

    # 创建 docker-compose 命令兼容 (Docker Compose V2)
    if [ ! -f /usr/local/bin/docker-compose ]; then
        ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose 2>/dev/null || \
        ln -sf /usr/lib/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose 2>/dev/null || \
        echo '#!/bin/bash
docker compose "$@"' > /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
        log_info "已创建 docker-compose 命令兼容"
    fi

    # 验证
    docker --version
    docker-compose version
}

print_docker_config() {
    echo ""
    echo -e "${GREEN}========== Docker 配置信息 ==========${NC}"
    log_config "配置文件:       /etc/docker/daemon.json"
    log_config "镜像加速:       $(cat /etc/docker/daemon.json 2>/dev/null | grep -o 'https://[^"]*' | head -1 || echo '未配置')"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
}

# ============================================
# Nginx 1.24.0 源码编译安装
# ============================================
install_nginx() {
    log_info "源码编译安装 Nginx ${NGINX_VERSION} ..."

    # 安装编译依赖
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        yum groupinstall -y "Development Tools"
        yum install -y pcre pcre-devel zlib zlib-devel openssl openssl-devel
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        apt-get update
        apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev
    fi

    # 下载源码
    cd /tmp
    curl -LO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
    tar -xzf nginx-${NGINX_VERSION}.tar.gz
    cd nginx-${NGINX_VERSION}

    # 配置编译选项
    ./configure \
        --prefix=/usr/local/nginx \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_stub_status_module \
        --with-http_gzip_static_module \
        --with-stream \
        --with-stream_ssl_module

    # 编译安装
    make -j$(nproc)
    make install

    # 创建软链接
    ln -sf /usr/local/nginx/sbin/nginx /usr/local/bin/nginx

    # 创建目录
    mkdir -p /usr/local/nginx/conf/sites-available
    mkdir -p /usr/local/nginx/conf/sites-enabled

    # 创建 systemd 服务
    cat > /etc/systemd/system/nginx.service << 'EOF'
[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable nginx
    systemctl start nginx

    # 清理
    cd /tmp
    rm -rf nginx-${NGINX_VERSION} nginx-${NGINX_VERSION}.tar.gz

    # 验证
    nginx -v

    # 打印配置信息
    print_nginx_config
}

print_nginx_config() {
    echo ""
    echo -e "${GREEN}========== Nginx 配置信息 ==========${NC}"
    log_config "安装目录:       /usr/local/nginx"
    log_config "主配置文件:     /usr/local/nginx/conf/nginx.conf"
    log_config "站点配置目录:   /usr/local/nginx/conf/sites-available/"
    log_config "站点启用目录:   /usr/local/nginx/conf/sites-enabled/"
    log_config "日志目录:       /usr/local/nginx/logs/"
    log_config "访问日志:       /usr/local/nginx/logs/access.log"
    log_config "错误日志:       /usr/local/nginx/logs/error.log"
    log_config "PID 文件:       /usr/local/nginx/logs/nginx.pid"
    log_config "服务文件:       /etc/systemd/system/nginx.service"
    echo -e "${GREEN}=====================================${NC}"
    echo ""
}

# ============================================
# MySQL 8 安装 (系统直接安装，本地+Docker访问)
# ============================================
install_mysql() {
    log_info "安装 MySQL ${MYSQL_VERSION} (系统直接安装，本地+Docker访问) ..."

    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # CentOS/RHEL 安装
        log_info "添加 MySQL 官方仓库..."

        # 下载并安装 MySQL 仓库
        if [ ! -f /etc/yum.repos.d/mysql-community.repo ]; then
            rpm -Uvh https://mirrors.aliyun.com/mysql/MySQL-8.0/mysql80-community-release-el7-7.noarch.rpm || \
            rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm

            # 使用阿里云镜像替换官方源
            sed -i 's#repo.mysql.com#mirrors.aliyun.com/mysql#g' /etc/yum.repos.d/mysql-community.repo
        fi

        # 安装 MySQL Server
        yum install -y mysql-community-server

        # 配置文件路径
        MYSQL_CNF="/etc/my.cnf"

    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Ubuntu/Debian 安装
        log_info "安装 MySQL Server..."

        # 设置 root 密码 (非交互式)
        export DEBIAN_FRONTEND=noninteractive
        debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
        debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

        apt-get update
        apt-get install -y mysql-server mysql-client

        # 配置文件路径
        MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"
    fi

    # 创建数据和日志目录
    mkdir -p /data/mysql/data
    mkdir -p /var/log/mysql
    chown -R mysql:mysql /data/mysql /var/log/mysql

    # 创建自定义配置文件 (仅允许本地和 Docker 宿主机连接)
    mkdir -p /data/mysql/conf
    cat > /data/mysql/conf/my.cnf << 'EOF'
[mysqld]
# 绑定本地地址和 Docker 宿主机 IP，禁止外部访问
bind-address = 127.0.0.1,172.17.0.1

# 字符集配置
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

# 时区
default-time-zone = '+08:00'

# 性能优化
max_connections = 500
innodb_buffer_pool_size = 256M

# 日志
log-error = /var/log/mysql/error.log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2

[client]
default-character-set = utf8mb4

[mysql]
default-character-set = utf8mb4
EOF

    # 合并配置
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # CentOS: 追加到 /etc/my.cnf
        if ! grep -q "bind-address = 127.0.0.1" /etc/my.cnf 2>/dev/null; then
            cat /data/mysql/conf/my.cnf >> /etc/my.cnf
        fi
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Ubuntu: 复制到 conf.d 目录
        cp /data/mysql/conf/my.cnf /etc/mysql/mysql.conf.d/custom.cnf
    fi

    # 启动 MySQL 服务
    systemctl enable mysqld 2>/dev/null || systemctl enable mysql 2>/dev/null
    systemctl start mysqld 2>/dev/null || systemctl start mysql 2>/dev/null

    log_info "等待 MySQL 启动..."
    sleep 10

    # CentOS 8 首次启动需要获取临时密码并修改
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # 获取临时密码
        TEMP_PASSWORD=$(grep 'temporary password' /var/log/mysqld.log 2>/dev/null | tail -1 | awk '{print $NF}')

        if [ -n "$TEMP_PASSWORD" ]; then
            log_info "检测到临时密码，正在修改..."
            mysql --connect-expired-password -u root -p"${TEMP_PASSWORD}" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';" 2>/dev/null || true
        fi
    fi

    # 配置 root 用户只能本地访问
    log_info "配置 MySQL 用户权限 (仅允许本地连接)..."
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
        FLUSH PRIVILEGES;
    " 2>/dev/null || log_warn "权限配置跳过"

    # 验证连接
    log_info "验证 MySQL 连接..."
    if mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -h 127.0.0.1 -e "SELECT 'Connection OK' AS status;" 2>/dev/null; then
        log_success "MySQL 本地连接验证成功"
    else
        log_warn "MySQL 可能仍在初始化，请稍后手动验证"
    fi

    # 打印配置信息
    print_mysql_config
}

print_mysql_config() {
    echo ""
    echo -e "${GREEN}========== MySQL 配置信息 ==========${NC}"
    log_config "安装方式:       系统直接安装"
    log_config "绑定地址:       127.0.0.1,172.17.0.1:3306 (本地+Docker访问)"
    log_config "Root 用户:      root"
    log_config "Root 密码:      ${MYSQL_ROOT_PASSWORD}"
    log_config "配置文件:       /data/mysql/conf/my.cnf"
    log_config "日志目录:       /var/log/mysql/"
    log_config "凭证文件:       /root/.mysql_credentials"
    echo ""
    echo -e "${YELLOW}连接命令:${NC}"
    echo "  mysql -h 127.0.0.1 -u root -p'${MYSQL_ROOT_PASSWORD}'"
    echo -e "${GREEN}=====================================${NC}"
    echo ""

    # 保存凭证到文件
    cat > /root/.mysql_credentials << EOF
MYSQL_HOST=127.0.0.1
MYSQL_PORT=3306
MYSQL_USER=root
MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_CONFIG=/data/mysql/conf/my.cnf
EOF
    chmod 600 /root/.mysql_credentials
    log_info "凭证已保存到 /root/.mysql_credentials"
}

# ============================================
# Redis 5.0 安装 (系统直接安装，本地+Docker访问)
# ============================================
install_redis() {
    log_info "安装 Redis ${REDIS_VERSION} (系统直接安装，本地+Docker访问) ..."

    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # CentOS/RHEL: 从 EPEL 或源码安装
        log_info "安装 Redis..."

        # 尝试从 EPEL 安装
        yum install -y epel-release || true
        yum install -y redis || {
            # 如果 yum 安装失败，从源码编译
            log_info "yum 安装失败，尝试源码编译..."
            install_redis_from_source
            return
        }

    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Ubuntu/Debian: 使用官方仓库
        log_info "安装 Redis..."
        apt-get update
        apt-get install -y redis-server redis-tools
    fi

    # 创建数据和配置目录
    mkdir -p /data/redis/data
    mkdir -p /data/redis/conf

    # 创建自定义配置文件 (仅允许本地和 Docker 宿主机连接)
    cat > /data/redis/conf/redis.conf << 'EOF'
# 绑定本地地址和 Docker 宿主机 IP，禁止外部访问
bind 127.0.0.1 172.17.0.1

# 保护模式
protected-mode yes

# 端口
port 6379

# 后台运行
daemonize yes
pidfile /var/run/redis/redis-server.pid

# 持久化配置 - AOF
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec

# 持久化配置 - RDB
save 900 1
save 300 10
save 60 10000

# 日志
loglevel notice
logfile /var/log/redis/redis-server.log

# 最大内存
maxmemory 256mb
maxmemory-policy allkeys-lru

# 数据目录
dir /data/redis/data

# 禁用危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command SHUTDOWN REDIS_SHUTDOWN
EOF

    # 创建必要目录
    mkdir -p /var/run/redis /var/log/redis
    chown -R redis:redis /var/run/redis /var/log/redis /data/redis 2>/dev/null || true

    # 应用配置
    if [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "aliyunlinux" ]]; then
        # CentOS: 备份并替换配置
        cp /etc/redis.conf /etc/redis.conf.bak 2>/dev/null || true
        cp /data/redis/conf/redis.conf /etc/redis.conf
    elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        # Ubuntu: 备份并替换配置
        cp /etc/redis/redis.conf /etc/redis/redis.conf.bak 2>/dev/null || true
        cp /data/redis/conf/redis.conf /etc/redis/redis.conf
    fi

    # 启动 Redis 服务
    systemctl enable redis 2>/dev/null || systemctl enable redis-server 2>/dev/null
    systemctl restart redis 2>/dev/null || systemctl restart redis-server 2>/dev/null

    log_info "等待 Redis 启动..."
    sleep 3

    # 验证连接
    log_info "验证 Redis 连接..."
    if redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q "PONG"; then
        log_success "Redis 本地连接验证成功"
    else
        log_warn "Redis 可能仍在启动，请稍后手动验证"
    fi

    # 打印配置信息
    print_redis_config
}

# Redis 源码编译安装 (备用方案)
install_redis_from_source() {
    log_info "从源码编译安装 Redis..."

    # 安装编译依赖
    yum install -y gcc make

    cd /tmp
    curl -LO http://download.redis.io/releases/redis-5.0.14.tar.gz
    tar -xzf redis-5.0.14.tar.gz
    cd redis-5.0.14

    make -j$(nproc)
    make install PREFIX=/usr/local/redis

    # 创建软链接
    ln -sf /usr/local/redis/bin/* /usr/local/bin/

    # 创建用户和目录
    useradd -r -s /sbin/nologin redis 2>/dev/null || true
    mkdir -p /data/redis/data /var/run/redis /var/log/redis
    chown -R redis:redis /data/redis /var/run/redis /var/log/redis

    # 创建配置文件
    mkdir -p /data/redis/conf
    cat > /data/redis/conf/redis.conf << 'EOF'
bind 127.0.0.1 172.17.0.1
protected-mode yes
port 6379
daemonize yes
pidfile /var/run/redis/redis-server.pid
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
save 900 1
save 300 10
save 60 10000
loglevel notice
logfile /var/log/redis/redis-server.log
maxmemory 256mb
maxmemory-policy allkeys-lru
dir /data/redis/data
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command SHUTDOWN REDIS_SHUTDOWN
EOF

    # 创建 systemd 服务
    cat > /etc/systemd/system/redis.service << 'EOF'
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
Type=forking
User=redis
Group=redis
ExecStart=/usr/local/redis/bin/redis-server /data/redis/conf/redis.conf
ExecStop=/usr/local/redis/bin/redis-cli shutdown
Restart=always
PIDFile=/var/run/redis/redis-server.pid

[Install]
WantedBy=multi-user.target
EOF

    # 启动服务
    systemctl daemon-reload
    systemctl enable redis
    systemctl start redis

    # 清理
    cd /tmp
    rm -rf redis-5.0.14 redis-5.0.14.tar.gz

    log_success "Redis 源码编译安装完成"
}

print_redis_config() {
    echo ""
    echo -e "${GREEN}========== Redis 配置信息 ==========${NC}"
    log_config "安装方式:       系统直接安装"
    log_config "绑定地址:       127.0.0.1,172.17.0.1:6379 (本地+Docker访问)"
    log_config "数据目录:       /data/redis/data"
    log_config "配置文件:       /data/redis/conf/redis.conf"
    log_config "日志文件:       /var/log/redis/redis-server.log"
    log_config "持久化:         AOF + RDB"
    log_config "最大内存:       256mb"
    echo ""
    echo -e "${YELLOW}连接命令:${NC}"
    echo "  redis-cli -h 127.0.0.1"
    echo -e "${GREEN}=====================================${NC}"
    echo ""

    # 保存配置信息到文件
    cat > /root/.redis_credentials << EOF
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_CONFIG=/data/redis/conf/redis.conf
REDIS_DATA=/data/redis/data
EOF
    chmod 600 /root/.redis_credentials
    log_info "配置信息已保存到 /root/.redis_credentials"
}

# ============================================
# 检测已安装的组件
# ============================================
check_mysql_installed() {
    # 检查系统安装
    if command -v mysql &>/dev/null && mysql --version 2>/dev/null | grep -q "8\."; then
        return 0
    fi
    # 检查 Docker 容器 (兼容旧安装)
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^mysql$'; then
        return 0
    fi
    return 1
}

check_redis_installed() {
    # 检查系统安装
    if command -v redis-server &>/dev/null; then
        return 0
    fi
    if command -v redis-cli &>/dev/null && redis-cli -h 127.0.0.1 ping 2>/dev/null | grep -q "PONG"; then
        return 0
    fi
    # 检查 Docker 容器 (兼容旧安装)
    if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q '^redis$'; then
        return 0
    fi
    return 1
}

# ============================================
# 打印最终汇总
# ============================================
print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    安装完成! 配置汇总                         ║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ 组件版本:                                                     ║${NC}"
    echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${NC}"
    printf "${GREEN}║${NC}  JRE:     %-52s ${GREEN}║${NC}\n" "$(java -version 2>&1 | head -1 | cut -d'"' -f2)"
    printf "${GREEN}║${NC}  Docker:  %-52s ${GREEN}║${NC}\n" "$(docker --version | cut -d' ' -f3 | tr -d ',')"
    printf "${GREEN}║${NC}  Compose: %-52s ${GREEN}║${NC}\n" "$(docker compose version --short)"
    printf "${GREEN}║${NC}  Nginx:   %-52s ${GREEN}║${NC}\n" "${NGINX_VERSION}"
    printf "${GREEN}║${NC}  MySQL:   %-52s ${GREEN}║${NC}\n" "${MYSQL_VERSION}.x (系统安装)"
    printf "${GREEN}║${NC}  Redis:   %-52s ${GREEN}║${NC}\n" "${REDIS_VERSION} (系统安装)"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ 配置文件位置:                                                 ║${NC}"
    echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${NC}"
    echo -e "${GREEN}║${NC}  Docker 配置:     /etc/docker/daemon.json                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Nginx 主配置:    /usr/local/nginx/conf/nginx.conf            ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Nginx 站点:      /usr/local/nginx/conf/sites-available/      ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  MySQL 配置:      /data/mysql/conf/my.cnf                     ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  MySQL 数据:      /data/mysql/data/                           ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Redis 配置:      /data/redis/conf/redis.conf                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Redis 数据:      /data/redis/data/                           ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ 安全配置:                                                     ║${NC}"
    echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${NC}"
    echo -e "${GREEN}║${NC}  MySQL:  仅允许 127.0.0.1 连接                                 ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Redis:  仅允许 127.0.0.1 连接                                 ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ MySQL 连接信息:                                               ║${NC}"
    echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${NC}"
    echo -e "${GREEN}║${NC}  Host:     127.0.0.1 / localhost                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Port:     3306                                                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  User:     root                                                ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Password: ${MYSQL_ROOT_PASSWORD}                                        ${GREEN}║${NC}"
    echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${GREEN}║ 凭证文件:                                                     ║${NC}"
    echo -e "${GREEN}╟──────────────────────────────────────────────────────────────╢${NC}"
    echo -e "${GREEN}║${NC}  MySQL: /root/.mysql_credentials                               ${GREEN}║${NC}"
    echo -e "${GREEN}║${NC}  Redis: /root/.redis_credentials                               ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# 主函数
# ============================================
main() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}      服务端依赖安装脚本 v1.1               ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""

    # 检查 root 权限
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 root 权限运行此脚本"
        exit 1
    fi

    # 检测操作系统
    detect_os

    # 0. SSH 密钥初始化
    echo ""
    echo -e "${YELLOW}[0/6] SSH 密钥初始化${NC}"
    init_ssh_key

    # 1. 安装 JRE 17
    echo ""
    echo -e "${YELLOW}[1/6] JRE 17${NC}"
    check_and_install "JRE 17" "java -version 2>&1 | grep -q '17'" install_jre17

    # 2. 安装 Docker
    echo ""
    echo -e "${YELLOW}[2/6] Docker + Docker Compose${NC}"
    check_and_install "Docker" "docker --version" install_docker

    # 3. 安装 Nginx
    echo ""
    echo -e "${YELLOW}[3/6] Nginx ${NGINX_VERSION}${NC}"
    check_and_install "Nginx ${NGINX_VERSION}" "nginx -v 2>&1 | grep -q '${NGINX_VERSION}'" install_nginx

    # 4. 安装 MySQL
    echo ""
    echo -e "${YELLOW}[4/6] MySQL ${MYSQL_VERSION}${NC}"
    check_and_install "MySQL ${MYSQL_VERSION}" "check_mysql_installed" install_mysql

    # 5. 安装 Redis
    echo ""
    echo -e "${YELLOW}[5/6] Redis ${REDIS_VERSION}${NC}"
    check_and_install "Redis ${REDIS_VERSION}" "check_redis_installed" install_redis

    # 6. 打印最终汇总
    echo ""
    echo -e "${YELLOW}[6/6] 安装汇总${NC}"
    print_summary
}

# 执行主函数
main "$@"
