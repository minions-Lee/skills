---
name: maven-operating
description: "Maven/mvn 构建部署工具。当用户提到以下任何关键词时必须使用此 skill：mvn部署、mvn deploy、maven部署、maven deploy、mvn打包、mvn package、mvn编译、mvn compile、mvn install、mvn安装、mvn clean、mvn运行、mvn启动、maven打包、maven编译、maven运行、部署jar、打包jar、编译项目、项目部署、项目打包。此 skill 包含本机 Maven 路径、settings.xml 位置、Nexus 仓库认证等关键配置，不使用此 skill 会导致 mvn 命令找不到或认证失败。"
---

# Maven 操作

执行 Maven 构建相关的所有操作，自动适配项目配置。

## 环境配置

```bash
# 可用的 Maven 版本
MAVEN_360="/Users/eamanc/Documents/env/apache-maven-3.6.0"
MAVEN_384="/Users/eamanc/Documents/env/apache-maven-3.8.4"

# 默认版本（推荐使用较新版本，兼容性更好）
MAVEN_DEFAULT="${MAVEN_384}"

# settings.xml 位置（两个版本共用）
SETTINGS_FILE="/Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml"
```

## 执行前检查

### 1. 确认项目目录

检查当前目录是否存在 `pom.xml`，如果不存在则提示用户切换到正确目录。

### 2. 选择 Maven 执行器

**优先级**：mvnw > 用户指定版本 > 默认版本（3.8.4）

```bash
if [ -f "./mvnw" ]; then
    MVN_CMD="./mvnw"
    echo "使用 Maven Wrapper"
else
    # 默认使用 3.8.4（兼容性更好）
    MVN_CMD="${MAVEN_DEFAULT}/bin/mvn"
    echo "使用系统 Maven 3.8.4"
fi
```

### 3. 版本切换

用户可以指定 Maven 版本：

| 用户说 | 使用版本 |
|-------|---------|
| "用 3.6 打包" | `${MAVEN_360}/bin/mvn` |
| "用 3.8 编译" | `${MAVEN_384}/bin/mvn` |
| "打包"（默认） | `${MAVEN_384}/bin/mvn` |

### 4. 构建基础命令

```bash
# 基础参数（始终使用同一个 settings.xml）
BASE_OPTS="-s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml"

# 默认 Profile
PROFILE="-P local"

# 跳过测试（package/install/deploy 默认启用）
SKIP_TESTS="-DskipTests"
```

## 常用操作

| 用户说 | 执行命令 |
|-------|---------|
| clean | `${MVN_CMD} clean ${BASE_OPTS} ${PROFILE}` |
| 编译 / compile | `${MVN_CMD} compile ${BASE_OPTS} ${PROFILE}` |
| 打包 / package | `${MVN_CMD} package ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}` |
| 安装 / install | `${MVN_CMD} install ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}` |
| 部署 / deploy | `${MVN_CMD} deploy ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}` |
| 测试 / test | `${MVN_CMD} test ${BASE_OPTS} ${PROFILE}` |
| 依赖树 | `${MVN_CMD} dependency:tree ${BASE_OPTS}` |
| clean package | `${MVN_CMD} clean package ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}` |
| **运行 / 启动 / run** | `${MVN_CMD} spring-boot:run ${BASE_OPTS} ${PROFILE}` |
| **运行 jar** | `java -jar target/*.jar --spring.profiles.active=local` |

## Profile 切换

用户明确指定环境时，替换默认的 `-P local`：

```
"打包 test 环境" → -P test
"部署到 dev" → -P dev
"编译 prod 配置" → -P prod
```

可用 Profile：`local`、`dev`、`test`、`test2`、`pre`、`prod`

## 本地运行

### Spring Boot 项目

```bash
# 方式一：maven 插件运行（推荐开发时使用）
${MVN_CMD} spring-boot:run ${BASE_OPTS} -Dspring-boot.run.profiles=local

# 方式二：运行打包后的 jar
java -jar target/xxx-server.jar --spring.profiles.active=local
```

### 多模块项目运行

多模块项目需要进入 server 模块目录运行：

```bash
# 先打包整个项目
${MVN_CMD} clean package ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}

# 进入 server 模块运行
cd xxx-server
${MVN_CMD} spring-boot:run ${BASE_OPTS} -Dspring-boot.run.profiles=local
```

或者直接运行 jar：
```bash
java -jar xxx-server/target/xxx-server.jar --spring.profiles.active=local
```

### 指定运行环境

| 用户说 | 执行 |
|-------|------|
| "运行" / "启动" | `-Dspring-boot.run.profiles=local` |
| "运行 dev 环境" | `-Dspring-boot.run.profiles=dev` |
| "运行 test 环境" | `-Dspring-boot.run.profiles=test` |

## 多模块操作

项目存在多个模块时，支持指定模块构建：

```bash
# 只构建指定模块（包含依赖）
${MVN_CMD} package -pl module-name -am ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}

# 只构建指定模块（不含依赖）
${MVN_CMD} package -pl module-name ${BASE_OPTS} ${PROFILE} ${SKIP_TESTS}
```

**示例**：
- "只打包 server 模块" → `-pl xxx-server -am`
- "编译 api 和 impl" → `-pl xxx-api,xxx-impl -am`

## 完整执行流程

```
1. 检查 pom.xml 是否存在
2. 检测 mvnw 或使用系统 Maven
3. 解析用户意图（操作类型 + 环境 + 模块）
4. 组装命令并执行
5. 输出构建结果
```

## 示例命令

```bash
# 有 mvnw 的项目
./mvnw clean package -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -P local -DskipTests

# 无 mvnw 的项目（默认用 3.8.4）
/Users/eamanc/Documents/env/apache-maven-3.8.4/bin/mvn deploy -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -P local -DskipTests

# 指定用 3.6 版本
/Users/eamanc/Documents/env/apache-maven-3.6.0/bin/mvn compile -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -P local

# 只编译 server 模块
/Users/eamanc/Documents/env/apache-maven-3.8.4/bin/mvn compile -pl xxx-server -am -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -P local

# 本地运行 Spring Boot（默认 local 环境）
./mvnw spring-boot:run -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -P local

# 运行指定环境（如 dev）
./mvnw spring-boot:run -s /Users/eamanc/Documents/env/apache-maven-3.6.0/conf/settings.xml -Dspring-boot.run.profiles=dev

# 运行打包后的 jar
java -jar target/xxx-server.jar --spring.profiles.active=local
```

## 常见问题

详见 `./references/troubleshooting.md`

## 高级命令

详见 `./references/maven-commands.md`
