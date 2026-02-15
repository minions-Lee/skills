# Nginx Server 配置模板
# 变量: {{PROJECT_NAME}}, {{LISTEN_PORT}}, {{SERVER_NAME}}, {{BACKEND_PORT}}
#
# 使用方式:
#   1. 复制此模板到 /usr/local/nginx/conf/sites-available/{{PROJECT_NAME}}.conf
#   2. 替换所有 {{变量}}
#   3. 创建软链接到 sites-enabled
#   4. 在 nginx.conf 中 include sites-enabled/*.conf
#
server {
    listen {{LISTEN_PORT}};
    server_name {{SERVER_NAME}};

    # 动态后端配置 (蓝绿部署切换)
    include /usr/local/nginx/conf/active_{{PROJECT_NAME}}.conf;

    # ================================================
    # SSE 流式接口 (需要特殊配置)
    # ================================================
    # 匹配规则: 以下路径使用 SSE 长连接
    # - {{PROJECT_NAME}}/api/agent/stream
    # - {{PROJECT_NAME}}/api/agent/intent/recognition/stream
    # - {{PROJECT_NAME}}/api/agent/wardrobe/entry/stream
    # - {{PROJECT_NAME}}/api/agent/plan-execute/stream
    # - {{PROJECT_NAME}}/agent/admin/plan-execute/stream
    #
    location ~ ^/({{PROJECT_NAME}}/api/agent/(stream|intent/recognition/stream|wardrobe/entry/stream|plan-execute/stream)|{{PROJECT_NAME}}/agent/admin/plan-execute/stream) {
        # CORS 配置
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With, traceid, platform, source, version, noncestr, did, idfa, imei, oaid, finger, token, timestamp, sign";
        add_header Access-Control-Allow-Credentials false;
        add_header Access-Control-Max-Age 86400;

        # 代理配置
        proxy_pass http://$backend_host;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # ========== SSE 专用配置 ==========
        # 禁用缓冲，确保实时推送
        proxy_buffering off;
        proxy_cache off;

        # 长超时配置 (5分钟)
        proxy_read_timeout 300s;
        proxy_send_timeout 300s;
        send_timeout 300s;

        # HTTP/1.1 长连接
        proxy_http_version 1.1;
        proxy_set_header Connection "";

        # 分块传输
        chunked_transfer_encoding on;
        # ================================
    }

    # ================================================
    # 普通接口
    # ================================================
    location /{{PROJECT_NAME}}/ {
        # CORS 配置
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS, PUT, DELETE";
        add_header Access-Control-Allow-Headers "Content-Type, Authorization, X-Requested-With, traceid, platform, source, version, noncestr, did, idfa, imei, oaid, finger, token, timestamp, sign";
        add_header Access-Control-Allow-Credentials false;
        add_header Access-Control-Max-Age 86400;

        # 代理配置
        proxy_pass http://$backend_host;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
