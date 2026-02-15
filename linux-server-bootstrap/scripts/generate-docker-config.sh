#!/bin/bash
#
# generate-docker-config.sh - Docker 配置生成器
# 生成 docker-compose.yml 和 Dockerfile
#
# 使用方法: bash generate-docker-config.sh
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

# ============================================
# 收集参数
# ============================================
collect_params() {
    echo ""
    echo -e "${BLUE}=== Docker 配置生成器 ===${NC}"
    echo ""

    read -p "项目名称: " PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        log_error "项目名称不能为空"
        exit 1
    fi

    # 默认目录
    DEFAULT_DIR="/usr/local/www/${PROJECT_NAME}-docker"
    read -p "项目目录 [${DEFAULT_DIR}]: " PROJECT_DIR
    PROJECT_DIR=${PROJECT_DIR:-$DEFAULT_DIR}

    read -p "代码子目录名 [${PROJECT_NAME}]: " CODE_DIR
    CODE_DIR=${CODE_DIR:-$PROJECT_NAME}

    read -p "主容器端口 [8083]: " PORT_PRIMARY
    PORT_PRIMARY=${PORT_PRIMARY:-8083}

    read -p "备容器端口 [8084]: " PORT_SECONDARY
    PORT_SECONDARY=${PORT_SECONDARY:-8084}

    read -p "主调试端口 [31053]: " DEBUG_PORT_PRIMARY
    DEBUG_PORT_PRIMARY=${DEBUG_PORT_PRIMARY:-31053}

    read -p "备调试端口 [31054]: " DEBUG_PORT_SECONDARY
    DEBUG_PORT_SECONDARY=${DEBUG_PORT_SECONDARY:-31054}

    read -p "Spring Profile [test]: " SPRING_PROFILE
    SPRING_PROFILE=${SPRING_PROFILE:-test}

    read -p "Maven 镜像 [docker.m.daocloud.io/library/maven:3.9.6-eclipse-temurin-17]: " MAVEN_IMAGE
    MAVEN_IMAGE=${MAVEN_IMAGE:-docker.m.daocloud.io/library/maven:3.9.6-eclipse-temurin-17}

    read -p "JDK 镜像 [docker.m.daocloud.io/library/eclipse-temurin:17-jdk]: " JDK_IMAGE
    JDK_IMAGE=${JDK_IMAGE:-docker.m.daocloud.io/library/eclipse-temurin:17-jdk}

    read -p "Builder 内存限制 [1024mb]: " BUILDER_MEM
    BUILDER_MEM=${BUILDER_MEM:-1024mb}

    read -p "Builder CPU 配额 [150000]: " BUILDER_CPU
    BUILDER_CPU=${BUILDER_CPU:-150000}

    # 确认
    echo ""
    echo -e "${YELLOW}=== 参数确认 ===${NC}"
    echo "项目名称:       $PROJECT_NAME"
    echo "项目目录:       $PROJECT_DIR"
    echo "代码目录:       $CODE_DIR"
    echo "主容器端口:     $PORT_PRIMARY"
    echo "备容器端口:     $PORT_SECONDARY"
    echo "调试端口:       $DEBUG_PORT_PRIMARY / $DEBUG_PORT_SECONDARY"
    echo "Spring Profile: $SPRING_PROFILE"
    echo "Maven 镜像:     $MAVEN_IMAGE"
    echo "JDK 镜像:       $JDK_IMAGE"
    echo ""
    read -p "确认生成? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        log_warn "已取消"
        exit 0
    fi
}

# ============================================
# 生成 docker-compose.yml
# ============================================
generate_docker_compose() {
    local OUTPUT="${PROJECT_DIR}/docker-compose.yml"

    log_info "生成 docker-compose.yml: $OUTPUT"

    mkdir -p "$PROJECT_DIR"

    cat > "$OUTPUT" << EOF
# docker-compose.yml
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 生成工具: generate-docker-config.sh
services:
  builder:
    image: ${MAVEN_IMAGE}
    working_dir: /app
    volumes:
      - ./${CODE_DIR}:/app/${CODE_DIR}
      - ~/.m2:/root/.m2
    command: mvn -f ${CODE_DIR}/pom.xml clean package -DskipTests
    mem_limit: ${BUILDER_MEM}
    cpu_quota: ${BUILDER_CPU}

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
    local OUTPUT="${PROJECT_DIR}/Dockerfile"

    log_info "生成 Dockerfile: $OUTPUT"

    cat > "$OUTPUT" << EOF
# Dockerfile
# 项目: ${PROJECT_NAME}
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 生成工具: generate-docker-config.sh
FROM ${JDK_IMAGE}
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
# 创建辅助目录
# ============================================
create_directories() {
    log_info "创建辅助目录..."
    mkdir -p "${PROJECT_DIR}/logs"
    mkdir -p "${PROJECT_DIR}/wechat"
    log_success "目录创建完成"
}

# ============================================
# 主函数
# ============================================
main() {
    collect_params
    generate_docker_compose
    generate_dockerfile
    create_directories

    echo ""
    echo -e "${GREEN}=== 完成 ===${NC}"
    echo "docker-compose.yml: ${PROJECT_DIR}/docker-compose.yml"
    echo "Dockerfile:         ${PROJECT_DIR}/Dockerfile"
    echo ""
    echo "后续操作:"
    echo "  1. 克隆代码:  cd ${PROJECT_DIR} && git clone <GIT_URL> ${CODE_DIR}"
    echo "  2. 构建镜像:  docker-compose run --rm builder"
    echo "  3. 启动服务:  docker-compose up --build -d ${PROJECT_NAME}"
    echo ""
}

main "$@"
