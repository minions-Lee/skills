# docker-compose.yml 模板
# 变量: {{PROJECT_NAME}}, {{CODE_DIR}}, {{PORT_PRIMARY}}, {{PORT_SECONDARY}},
#       {{DEBUG_PORT_PRIMARY}}, {{DEBUG_PORT_SECONDARY}}, {{SPRING_PROFILE}}
#
version: '2.4'
services:
  builder:
    image: maven:3.9.6-eclipse-temurin-17
    working_dir: /app
    volumes:
      - ./{{CODE_DIR}}:/app/{{CODE_DIR}}
      - ~/.m2:/root/.m2
    command: mvn -f {{CODE_DIR}}/pom.xml clean package -DskipTests
    mem_limit: 1024mb
    cpu_quota: 150000  # 限制 CPU，防止打包时系统卡死

  {{PROJECT_NAME}}:
    image: {{PROJECT_NAME}}-docker_{{PROJECT_NAME}}:latest
    build:
      context: .
      dockerfile: Dockerfile
    container_name: {{PROJECT_NAME}}
    ports:
      - "{{PORT_PRIMARY}}:8080"
      - "{{DEBUG_PORT_PRIMARY}}:31050"
    dns:
      - 8.8.8.8
      - 8.8.4.4
    volumes:
      - ./logs:/root/logs
      - ./wechat:/root/wechat/
    environment:
      - SPRING_PROFILES_ACTIVE={{SPRING_PROFILE}}

  {{PROJECT_NAME}}2:
    image: {{PROJECT_NAME}}-docker_{{PROJECT_NAME}}:latest
    build:
      context: .
      dockerfile: Dockerfile
    container_name: {{PROJECT_NAME}}2
    ports:
      - "{{PORT_SECONDARY}}:8080"
      - "{{DEBUG_PORT_SECONDARY}}:31050"
    dns:
      - 8.8.8.8
      - 8.8.4.4
    volumes:
      - ./logs:/root/logs
      - ./wechat:/root/wechat/
    environment:
      - SPRING_PROFILES_ACTIVE={{SPRING_PROFILE}}
