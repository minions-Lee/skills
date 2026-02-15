# Nginx Active 后端配置模板
# 变量: {{BACKEND_PORT}}
#
# 文件位置: /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf
#
# 说明:
#   此文件由蓝绿部署脚本自动更新，用于切换后端服务器
#   - 主容器端口: 通常是 8083
#   - 备容器端口: 通常是 8084
#
# 使用方式:
#   在 server 块中 include 此文件，然后使用 $backend_host 变量
#
set $backend_host 127.0.0.1:{{BACKEND_PORT}};
