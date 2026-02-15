---
name: docker-bluegreen-deploy
description: |
  生成 Docker 蓝绿部署脚本。用于：(1) 新建项目需要零停机部署脚本，(2) 用户说"生成部署脚本"、
  "创建 restart 脚本"、"蓝绿部署"，(3) 需要双容器热切换、健康检查、Nginx 路由切换的场景。
  支持自定义项目名称、端口、健康检查路径、Nginx 配置方式等参数。
author: Claude Code
version: 1.0.0
date: 2026-01-30
---

# Docker 蓝绿部署脚本生成器

## 问题
需要为 Java/Spring Boot 项目生成零停机部署脚本，实现蓝绿部署、健康检查、Nginx 路由自动切换。

## 触发条件
- 用户需要新建项目的部署脚本
- 用户说"生成部署脚本"、"创建 restart 脚本"、"蓝绿部署"
- 需要双容器热切换的场景

## 必需参数

在生成脚本前，需要收集以下信息：

| 参数 | 说明 | 示例 |
|------|------|------|
| `PROJECT_NAME` | 项目名称（小写，用于容器名、目录名） | `adventurex`, `tuopu` |
| `PORT_PRIMARY` | 主容器端口 | `8083` |
| `PORT_SECONDARY` | 备容器端口 | `8084` |
| `NGINX_PORT` | Nginx 对外端口 | `81` |
| `HEALTH_PATH` | 健康检查路径 | `/ops/healthCheck` |
| `DOCKER_ROOT` | Docker 项目根目录 | `/usr/local/www/adventurex-docker` |
| `CODE_DIR` | 代码子目录名 | `adventurex` |

## 可选参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `NGINX_CONFIG_STYLE` | Nginx 配置方式 | `variable` |
| `GRACEFUL_SHUTDOWN_WAIT` | 优雅停机等待时间（秒） | `60` |
| `HEALTH_CHECK_RETRIES` | 健康检查重试次数 | `100` |
| `HEALTH_CHECK_INTERVAL` | 健康检查间隔（秒） | `3` |

### Nginx 配置方式

**1. `variable` 方式（推荐）**
```bash
echo "set \$backend_host 127.0.0.1:${PORT};" > /usr/local/nginx/conf/active_${PROJECT}.conf
```
需要在 Nginx 主配置中使用：
```nginx
include /usr/local/nginx/conf/active_${PROJECT}.conf;
proxy_pass http://$backend_host/${PROJECT}/;
```

**2. `proxy_pass` 方式**
```bash
echo "proxy_pass http://127.0.0.1:${PORT}/${PROJECT}/;" > /usr/local/nginx/conf/active_${PROJECT}.conf
```
需要在 Nginx 主配置中使用：
```nginx
include /usr/local/nginx/conf/active_${PROJECT}.conf;
```

## 脚本范式结构

```
1. 拉取代码（缓存 git pull 结果）
2. 智能构建决策（代码无变化则跳过 builder）
3. 检测当前运行的容器
4. 启动备用容器
5. 健康检查循环
6. 切换 Nginx 路由
7. 二次健康检查（通过 Nginx）
8. 优雅停机旧容器
9. 清理 Docker 垃圾镜像
```

## 生成脚本

当用户提供参数后，使用以下模板生成脚本：

```bash
#!/bin/bash

set -e  # 出错即退出
echo "🚀 开始更新 {{PROJECT_NAME}} 项目..."

# 1. 拉取代码
echo "📦 拉取最新代码..."
cd {{DOCKER_ROOT}}/{{CODE_DIR}}
pull_result=$(git pull)
echo "$pull_result"

# 2. 回到 docker 根目录
cd {{DOCKER_ROOT}}

# 获取容器状态
{{PROJECT_NAME}}_status=$(docker inspect -f '{{.State.Status}}' {{PROJECT_NAME}} 2>/dev/null || echo "not_found")
{{PROJECT_NAME}}2_status=$(docker inspect -f '{{.State.Status}}' {{PROJECT_NAME}}2 2>/dev/null || echo "not_found")

echo "当前容器状态：{{PROJECT_NAME}}=${{PROJECT_NAME}}_status, {{PROJECT_NAME}}2=${{PROJECT_NAME}}2_status"

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
if [[ "${{PROJECT_NAME}}_status" == "running" ]]; then
  echo "🔁 {{PROJECT_NAME}} 正在运行，准备切换到 {{PROJECT_NAME}}2"

  docker-compose stop {{PROJECT_NAME}}2 || true
  docker-compose rm -f {{PROJECT_NAME}}2 || true

  echo "🚀 启动 {{PROJECT_NAME}}2..."
  docker-compose up $UP_FLAGS {{PROJECT_NAME}}2

  echo "🩺 检查 {{PROJECT_NAME}}2 健康状态..."
  HEALTH_URL="http://127.0.0.1:{{PORT_SECONDARY}}/{{PROJECT_NAME}}{{HEALTH_PATH}}"

  set +e
  for i in {1..{{HEALTH_CHECK_RETRIES}}}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 {{PROJECT_NAME}}2..."
          {{NGINX_CONFIG_COMMAND_SECONDARY}}

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:{{NGINX_PORT}}/{{PROJECT_NAME}}{{HEALTH_PATH}}" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ {{PROJECT_NAME}}2 服务已健康启动，准备停止旧容器 {{PROJECT_NAME}}（等待 {{GRACEFUL_SHUTDOWN_WAIT}} 秒以完成任务）"
            sleep {{GRACEFUL_SHUTDOWN_WAIT}}
            echo "⛔️ 停止 {{PROJECT_NAME}} 容器..."
            docker-compose stop {{PROJECT_NAME}}
            docker-compose rm -f {{PROJECT_NAME}}
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，{{HEALTH_CHECK_INTERVAL}} 秒后重试..."
      sleep {{HEALTH_CHECK_INTERVAL}}
  done
  set -e

  if [[ -z "$code" ]]; then
      echo "❌ 健康检查失败：{{PROJECT_NAME}}2 未成功启动！"
      exit 1
  fi

elif [[ "${{PROJECT_NAME}}2_status" == "running" ]]; then
  echo "🔁 {{PROJECT_NAME}}2 正在运行，准备切换到 {{PROJECT_NAME}}"

  docker-compose stop {{PROJECT_NAME}} || true
  docker-compose rm -f {{PROJECT_NAME}} || true

  echo "🚀 启动 {{PROJECT_NAME}}..."
  docker-compose up $UP_FLAGS {{PROJECT_NAME}}

  echo "🩺 检查 {{PROJECT_NAME}} 健康状态..."
  HEALTH_URL="http://127.0.0.1:{{PORT_PRIMARY}}/{{PROJECT_NAME}}{{HEALTH_PATH}}"

  set +e
  for i in {1..{{HEALTH_CHECK_RETRIES}}}; do
      response=$(curl -s --location --request GET "$HEALTH_URL" || true)
      code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
      echo "$code"
      if [[ -n "$code" ]]; then
          echo "🔄 更新 Nginx 路由到 {{PROJECT_NAME}}..."
          {{NGINX_CONFIG_COMMAND_PRIMARY}}

          echo "🔁 重载 Nginx 配置..."
          nginx -s reload

          response=$(curl -s --location --request GET "http://127.0.0.1:{{NGINX_PORT}}/{{PROJECT_NAME}}{{HEALTH_PATH}}" || true)
          code=$(echo "$response" | grep -o '"code":[[:space:]]*200')
          echo "$code"

          if [[ -n "$code" ]]; then
            echo "✅ {{PROJECT_NAME}} 服务已健康启动，准备停止旧容器 {{PROJECT_NAME}}2（等待 {{GRACEFUL_SHUTDOWN_WAIT}} 秒以完成任务）"
            sleep {{GRACEFUL_SHUTDOWN_WAIT}}
            echo "⛔️ 停止 {{PROJECT_NAME}}2 容器..."
            docker-compose stop {{PROJECT_NAME}}2 || true
            docker-compose rm -f {{PROJECT_NAME}}2 || true
          fi
          break
      fi
      echo "⏳ 第 $i 次健康检查未通过，{{HEALTH_CHECK_INTERVAL}} 秒后重试..."
      sleep {{HEALTH_CHECK_INTERVAL}}
  done
  set -e

  if [[ -z "$code" ]]; then
      echo "❌ 健康检查失败：{{PROJECT_NAME}} 未成功启动！"
      exit 1
  fi

else
  echo "⚠️ 没有容器在运行，默认启动 {{PROJECT_NAME}}"
  docker-compose up $UP_FLAGS {{PROJECT_NAME}}
fi

# 清理无用的 Docker 镜像
echo "🧹 清理无用的 Docker 镜像..."
docker image prune -f

echo "✅ 更新完成！"
```

## Nginx 配置命令生成规则

**variable 方式：**
```bash
NGINX_CONFIG_COMMAND_PRIMARY='echo "set \$backend_host 127.0.0.1:{{PORT_PRIMARY}};" > /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf'
NGINX_CONFIG_COMMAND_SECONDARY='echo "set \$backend_host 127.0.0.1:{{PORT_SECONDARY}};" > /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf'
```

**proxy_pass 方式：**
```bash
NGINX_CONFIG_COMMAND_PRIMARY='echo "proxy_pass http://127.0.0.1:{{PORT_PRIMARY}}/{{PROJECT_NAME}}/;" > /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf'
NGINX_CONFIG_COMMAND_SECONDARY='echo "proxy_pass http://127.0.0.1:{{PORT_SECONDARY}}/{{PROJECT_NAME}}/;" > /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf'
```

## 使用示例

**用户输入：**
> 帮我生成一个 myapp 项目的部署脚本，端口用 8085 和 8086，Nginx 端口 82

**收集参数：**
```
PROJECT_NAME: myapp
PORT_PRIMARY: 8085
PORT_SECONDARY: 8086
NGINX_PORT: 82
HEALTH_PATH: /ops/healthCheck
DOCKER_ROOT: /usr/local/www/myapp-docker
CODE_DIR: myapp
NGINX_CONFIG_STYLE: variable (默认)
```

**生成脚本并保存到：** `/usr/local/www/myapp-docker/restart-myapp` 或用户指定位置

## 验证

生成脚本后，建议：
1. 检查脚本语法：`bash -n restart-myapp`
2. 确认目录结构存在
3. 确认 docker-compose.yml 中定义了对应的服务
4. 确认 Nginx 配置正确 include 了 active 配置文件

## 注意事项

- 脚本需要 root 权限或 docker 组权限
- 需要提前配置好 docker-compose.yml
- Nginx 配置需要提前设置好 include
- 健康检查接口需要返回 `{"code": 200, ...}` 格式
