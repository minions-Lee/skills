# Dockerfile 模板
# 变量: {{PROJECT_NAME}}, {{CODE_DIR}}, {{SPRING_PROFILE}}
#
FROM eclipse-temurin:17-jdk
WORKDIR /app

# 设置时区为上海
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./{{CODE_DIR}}/{{CODE_DIR}}-web/target/{{PROJECT_NAME}}.jar {{PROJECT_NAME}}.jar

# 开放端口
EXPOSE 8080

# 可选：设置默认 profile（也可运行时覆盖）
ENV SPRING_PROFILES_ACTIVE={{SPRING_PROFILE}}

# 启动应用，读取外部指定的 profile
CMD ["java", "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:31050", "-Dspring.devtools.restart.enabled=false", "-jar", "{{PROJECT_NAME}}.jar"]
