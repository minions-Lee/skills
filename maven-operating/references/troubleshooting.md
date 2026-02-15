# Maven 常见问题排查

## 认证问题

### 401 Unauthorized

**现象**：
```
Could not transfer artifact from/to nexus:
status code: 401, reason phrase: Unauthorized
```

**解决**：
1. 检查 `settings.xml` 中的 server 配置：
```xml
<server>
  <id>maven-releases</id>  <!-- 必须与 pom.xml 中 repository id 一致 -->
  <username>deployment</username>
  <password>deployment123</password>
</server>
```

2. 确认 pom.xml 中的 repository id 匹配：
```xml
<distributionManagement>
  <repository>
    <id>maven-releases</id>  <!-- 与 server id 一致 -->
    <url>https://nexus.fenxianglife.com/repository/...</url>
  </repository>
</distributionManagement>
```

### 403 Forbidden

**现象**：部署时返回 403

**原因**：
- 账号没有部署权限
- 尝试覆盖已发布的 release 版本（Nexus 默认禁止）

**解决**：
- 联系管理员开通权限
- 如需重新发布，先修改版本号

## 依赖问题

### 找不到依赖

**现象**：
```
Could not find artifact com.xxx:xxx:jar:1.0.0
```

**排查步骤**：
1. 检查版本号是否正确
2. 检查私有仓库是否配置
3. 强制更新：`mvn clean install -U`
4. 检查本地仓库是否有损坏的文件：
```bash
find ~/.m2/repository -name "*.lastUpdated" -delete
```

### SNAPSHOT 版本不更新

**现象**：依赖的 SNAPSHOT 版本没有拉取最新

**解决**：
```bash
mvn clean install -U  # 强制更新快照
```

### 依赖冲突

**排查**：
```bash
# 查看依赖树
mvn dependency:tree

# 查看特定依赖的来源
mvn dependency:tree -Dincludes=com.google.guava
```

**解决**：在 pom.xml 中排除冲突依赖：
```xml
<dependency>
  <groupId>com.xxx</groupId>
  <artifactId>xxx</artifactId>
  <exclusions>
    <exclusion>
      <groupId>com.google.guava</groupId>
      <artifactId>guava</artifactId>
    </exclusion>
  </exclusions>
</dependency>
```

## 编译问题

### 编译版本不匹配

**现象**：
```
source release 17 requires target release 17
```

**解决**：检查 pom.xml 中的 Java 版本配置：
```xml
<properties>
  <java.version>17</java.version>
  <maven.compiler.source>17</maven.compiler.source>
  <maven.compiler.target>17</maven.compiler.target>
</properties>
```

### 编码问题

**现象**：中文乱码或编译失败

**解决**：
```xml
<properties>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

或命令行指定：
```bash
mvn compile -Dfile.encoding=UTF-8
```

## 网络问题

### 下载超时

**解决**：
1. 检查网络连接
2. 使用阿里云镜像（已在 settings.xml 配置）
3. 增加超时时间：
```bash
mvn package -Dmaven.wagon.http.connectionTimeout=60000 -Dmaven.wagon.http.readTimeout=60000
```

### SSL 证书问题

**现象**：
```
PKIX path building failed
```

**解决**：
```bash
# 跳过 SSL 验证（不推荐生产使用）
mvn package -Dmaven.wagon.http.ssl.insecure=true -Dmaven.wagon.http.ssl.allowall=true
```

## 内存问题

### OutOfMemoryError

**解决**：增加 Maven 内存：
```bash
export MAVEN_OPTS="-Xmx2048m -XX:MaxMetaspaceSize=512m"
```

或在 `.mvn/jvm.config` 中配置：
```
-Xmx2048m
-XX:MaxMetaspaceSize=512m
```

## mvnw 问题

### mvnw 执行失败

**现象**：`./mvnw: Permission denied`

**解决**：
```bash
chmod +x mvnw
```

### Wrapper 下载失败

**现象**：无法下载 maven-wrapper.jar

**解决**：手动下载或使用系统 Maven：
```bash
/Users/eamanc/Documents/env/apache-maven-3.6.0/bin/mvn package
```

## 多模块问题

### 模块找不到

**现象**：`Could not find artifact xxx:xxx:pom:1.0.0-SNAPSHOT`

**解决**：先安装父模块和依赖模块：
```bash
mvn install -N  # 只安装父 POM
mvn install -pl module-dependency -am  # 安装依赖模块
```

### 构建顺序错误

**解决**：使用 reactor 参数控制顺序：
```bash
mvn package -pl module-a,module-b -am  # 自动按依赖顺序构建
```
