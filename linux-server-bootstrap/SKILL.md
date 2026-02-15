---
name: linux-server-bootstrap
description: |
  Linux 服务器环境初始化和项目部署工具。用于：(1) 新服务器初始化安装 JRE17/Docker/Nginx/MySQL/Redis，
  (2) 新项目初始化（Git clone + Docker 配置 + Nginx 配置 + 蓝绿部署脚本），(3) 用户说"初始化服务器"、
  "部署新项目"、"生成 Docker 配置"、"生成 Nginx 配置"时触发。
  支持安装检测（已安装则跳过）、SSH 密钥初始化、调用 docker-bluegreen-deploy 生成部署脚本。
  MySQL/Redis 默认仅允许本地 (127.0.0.1) 连接，安装后打印所有配置文件路径。
author: Claude Code
version: 1.1.0
date: 2026-01-31
dependencies:
  - docker-bluegreen-deploy
---

# Linux 服务器环境初始化工具

## 概述

本 Skill 提供完整的 Linux 服务器环境初始化和 Java 项目部署能力，包括：
- 服务端依赖安装（带检测，已安装则跳过）
- 项目初始化（Git clone + 配置生成）
- Nginx 配置生成（支持 SSE 流式接口）
- Docker 配置生成（支持蓝绿部署）

## 触发条件

- 用户需要初始化新服务器环境
- 用户说"初始化服务器"、"安装环境"、"部署新项目"
- 用户说"生成 Docker 配置"、"生成 Nginx 配置"
- 需要为 Java/Spring Boot 项目配置部署环境

## 脚本清单

| 脚本 | 说明 |
|------|------|
| `scripts/install-npm-codex-v2ray.sh` | 开发工具安装 (npm/OpenAI Codex/v2rayA) |
| `scripts/install-jre-docker-nginx-mysql-redis.sh` | 服务端依赖安装 |
| `scripts/init-project.sh` | 项目初始化脚本 |
| `scripts/generate-nginx-config.sh` | Nginx 配置生成器 |
| `scripts/generate-docker-config.sh` | Docker 配置生成器 |

## 模板文件

| 模板 | 说明 |
|------|------|
| `templates/nginx-server.conf.tpl` | Nginx server 块模板 |
| `templates/nginx-active.conf.tpl` | Nginx active 配置模板 |
| `templates/docker-compose.yml.tpl` | docker-compose 模板 |
| `templates/Dockerfile.tpl` | Dockerfile 模板 |

---

## 一、服务端依赖安装

### 安装组件

| 组件 | 版本 | 检测命令 | 配置文件 |
|------|------|----------|----------|
| JRE | 17 (Eclipse Temurin) | `java -version 2>&1 \| grep "17"` | - |
| Docker | 最新稳定版 | `docker --version` | `/etc/docker/daemon.json` |
| Docker Compose | v2.x | `docker compose version` | - |
| Nginx | 1.24.0 | `nginx -v 2>&1 \| grep "1.24"` | `/usr/local/nginx/conf/nginx.conf` |
| MySQL | 8.x | Docker 容器检测 | `/data/mysql/conf/my.cnf` |
| Redis | 5.0 | Docker 容器检测 | `/data/redis/conf/redis.conf` |

### 安全配置

- **MySQL**: 仅绑定 `127.0.0.1:3306`，禁止外部连接
- **Redis**: 仅绑定 `127.0.0.1:6379`，禁止外部连接，已禁用危险命令

### MySQL 默认凭证

```
Host:     127.0.0.1 / localhost
Port:     3306
User:     root
Password: liqize@#Pwd
```

### 配置文件路径

安装完成后，脚本会打印所有配置文件路径：

```
Nginx 主配置:    /usr/local/nginx/conf/nginx.conf
Nginx 站点:      /usr/local/nginx/conf/sites-available/
MySQL 配置:      /data/mysql/conf/my.cnf
MySQL 数据:      /data/mysql/data/
Redis 配置:      /data/redis/conf/redis.conf
Redis 数据:      /data/redis/data/
凭证文件:        /root/.mysql_credentials, /root/.redis_credentials
```

### 使用方法

```bash
# 直接运行脚本
sudo ./scripts/install-jre-docker-nginx-mysql-redis.sh

# 或通过 Skill 调用
> 帮我初始化服务器环境
```

### 检测逻辑

所有组件安装前会先检测是否已安装，已安装则自动跳过：

```bash
check_and_install "JRE 17" "java -version 2>&1 | grep -q '17'" install_jre17
```

---

## 二、项目初始化

### 必需参数

| 参数 | 说明 | 示例 |
|------|------|------|
| `GIT_URL` | Git 仓库地址 | `git@github.com:company/myapp.git` |
| `PROJECT_NAME` | 项目名称 | `adventurex` |

### 可选参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `PORT_PRIMARY` | 主容器端口 | `8083` |
| `PORT_SECONDARY` | 备容器端口 | `8084` |
| `NGINX_PORT` | Nginx 端口 | `81` |
| `DEBUG_PORT_PRIMARY` | 主调试端口 | `31053` |
| `DEBUG_PORT_SECONDARY` | 备调试端口 | `31054` |
| `SPRING_PROFILE` | Spring 环境 | `test` |
| `HEALTH_PATH` | 健康检查路径 | `/ops/healthCheck` |

### 目录结构

```
/usr/local/www/{PROJECT_NAME}-docker/
├── {PROJECT_NAME}/              # Git 代码目录
│   └── ... (git clone)
├── docker-compose.yml           # Docker 编排文件
├── Dockerfile                   # 镜像构建文件
├── restart-{PROJECT_NAME}       # 蓝绿部署脚本
├── logs/                        # 日志目录
└── wechat/                      # 其他挂载目录
```

### 使用示例

```bash
# 交互式初始化
./scripts/init-project.sh

# 或通过 Skill 调用
> 帮我初始化一个新项目
> Git 地址: git@github.com:company/adventurex.git
> 项目名称: adventurex
> 主端口: 8083, 备端口: 8084, Nginx端口: 81
```

---

## 三、Nginx 配置生成

### 配置参数

```yaml
PROJECT_NAME: adventurex
LISTEN_PORT: 81
SERVER_NAME: "127.0.0.1 121.196.237.41"
BACKEND_PORT: 8084

# SSE 流式接口路径 (正则)
SSE_PATHS:
  - "api/agent/stream"
  - "api/agent/intent/recognition/stream"
  - "api/agent/wardrobe/entry/stream"
  - "api/agent/plan-execute/stream"
  - "agent/admin/plan-execute/stream"
```

### 生成文件

- `/usr/local/nginx/conf/sites-available/{PROJECT_NAME}.conf`
- `/usr/local/nginx/conf/active_{PROJECT_NAME}.conf`

### SSE 流式接口配置

自动为 SSE 接口添加特殊配置：

```nginx
# SSE 专用配置
proxy_buffering off;
proxy_cache off;
proxy_read_timeout 300s;
proxy_send_timeout 300s;
proxy_http_version 1.1;
proxy_set_header Connection "";
chunked_transfer_encoding on;
```

---

## 四、Docker 配置生成

### 配置参数

```yaml
PROJECT_NAME: adventurex
PORT_PRIMARY: 8083
PORT_SECONDARY: 8084
DEBUG_PORT_PRIMARY: 31053
DEBUG_PORT_SECONDARY: 31054
CONTAINER_PORT: 8080
DEBUG_CONTAINER_PORT: 31050

MAVEN_IMAGE: "maven:3.9.6-eclipse-temurin-17"
JDK_IMAGE: "eclipse-temurin:17-jdk"
SPRING_PROFILE: test
TIMEZONE: Asia/Shanghai

# 资源限制
BUILDER_MEM_LIMIT: 1024mb
BUILDER_CPU_QUOTA: 150000
```

### 生成文件

- `docker-compose.yml` - 包含 builder + 双容器蓝绿部署
- `Dockerfile` - JDK 17 运行时镜像

---

## 五、蓝绿部署脚本生成

本 Skill 集成了 `docker-bluegreen-deploy` Skill，可以自动生成蓝绿部署脚本。

### 调用方式

在项目初始化时自动调用，或单独调用：

```
> 调用 docker-bluegreen-deploy 为 adventurex 项目生成部署脚本
```

### 生成的脚本

`restart-{PROJECT_NAME}` - 零停机蓝绿部署脚本，包含：
- Git 拉取 + 智能构建
- 双容器切换
- 健康检查
- Nginx 路由切换
- 优雅停机

---

## 六、完整工作流程

```
1. 初始化服务器环境
   └── install-jre-docker-nginx-mysql-redis.sh
       ├── 检测并安装 JRE 17
       ├── 检测并安装 Docker + Compose
       ├── 检测并安装 Nginx 1.24.0
       ├── 检测并安装 MySQL 8
       └── 检测并安装 Redis 5.0

2. 初始化新项目
   └── init-project.sh
       ├── 检测/生成 SSH 密钥
       ├── 创建目录结构
       ├── Git clone 代码
       ├── 生成 docker-compose.yml
       ├── 生成 Dockerfile
       ├── 生成 Nginx 配置
       ├── 调用 docker-bluegreen-deploy 生成 restart 脚本
       └── 首次构建启动
```

---

## 七、注意事项

1. **权限要求**：大部分脚本需要 root 权限或 sudo
2. **SSH 密钥**：首次运行会自动检测/生成 SSH 密钥并打印公钥
3. **防火墙**：脚本会尝试自动开放端口，若失败需手动配置
4. **Nginx 源码编译**：Nginx 1.24.0 需要源码编译以确保版本一致
5. **MySQL/Redis**：可选择 Docker 容器方式或直接安装

---

## 八、后续迭代方向

- [ ] 支持配置文件批量初始化多个项目
- [ ] 支持各组件版本自定义选择
- [ ] 添加安装后自动验证
- [ ] 支持卸载/回滚功能
- [ ] 多 Linux 发行版自动识别 (CentOS/Ubuntu/Debian)
