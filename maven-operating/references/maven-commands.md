# Maven 命令参考

## 生命周期阶段

```
clean → validate → compile → test → package → verify → install → deploy
```

## 常用命令

### 基础操作

```bash
# 清理
mvn clean

# 编译
mvn compile

# 编译测试代码
mvn test-compile

# 运行测试
mvn test

# 打包
mvn package

# 安装到本地仓库
mvn install

# 部署到远程仓库
mvn deploy
```

### 组合操作

```bash
# 清理并打包
mvn clean package

# 清理并安装
mvn clean install

# 清理并部署
mvn clean deploy

# 跳过测试打包
mvn clean package -DskipTests

# 跳过测试编译和执行
mvn clean package -Dmaven.test.skip=true
```

### 依赖管理

```bash
# 查看依赖树
mvn dependency:tree

# 查看依赖树（只显示指定包）
mvn dependency:tree -Dincludes=com.google.guava

# 分析依赖（找出未使用和缺失的依赖）
mvn dependency:analyze

# 下载源码
mvn dependency:sources

# 下载 javadoc
mvn dependency:resolve -Dclassifier=javadoc

# 复制依赖到指定目录
mvn dependency:copy-dependencies -DoutputDirectory=./libs
```

### 多模块操作

```bash
# 只构建指定模块（包含依赖模块）
mvn package -pl module-name -am

# 只构建指定模块（不含依赖）
mvn package -pl module-name

# 构建多个模块
mvn package -pl module-a,module-b -am

# 排除某模块
mvn package -pl !module-name

# 从指定模块开始构建
mvn package -rf :module-name
```

### 版本管理

```bash
# 查看可更新的依赖
mvn versions:display-dependency-updates

# 查看可更新的插件
mvn versions:display-plugin-updates

# 设置版本号
mvn versions:set -DnewVersion=1.0.1

# 回退版本修改
mvn versions:revert

# 确认版本修改
mvn versions:commit
```

### 调试与信息

```bash
# 显示有效 POM
mvn help:effective-pom

# 显示有效 settings
mvn help:effective-settings

# 显示系统属性和环境变量
mvn help:system

# 详细输出模式
mvn package -X

# 静默模式
mvn package -q

# 离线模式
mvn package -o

# 强制更新快照
mvn package -U
```

### Profile 相关

```bash
# 使用指定 profile
mvn package -P profile-name

# 使用多个 profile
mvn package -P profile1,profile2

# 查看激活的 profile
mvn help:active-profiles

# 查看所有 profile
mvn help:all-profiles
```

## 常用参数

| 参数 | 作用 |
|-----|------|
| `-DskipTests` | 跳过测试执行（仍编译测试代码） |
| `-Dmaven.test.skip=true` | 跳过测试编译和执行 |
| `-P profile` | 激活指定 profile |
| `-pl module` | 只构建指定模块 |
| `-am` | 同时构建依赖模块 |
| `-amd` | 同时构建依赖此模块的模块 |
| `-rf :module` | 从指定模块恢复构建 |
| `-T 4` | 使用 4 线程并行构建 |
| `-o` | 离线模式 |
| `-U` | 强制更新快照 |
| `-X` | Debug 输出 |
| `-q` | 静默模式 |
| `-s file` | 指定 settings.xml |
| `-f pom` | 指定 pom.xml |

## Spring Boot 相关

```bash
# 运行 Spring Boot 应用
mvn spring-boot:run

# 指定 profile 运行
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 生成构建信息
mvn spring-boot:build-info

# 打包可执行 jar
mvn package spring-boot:repackage
```
