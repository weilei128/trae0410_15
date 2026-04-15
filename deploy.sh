#!/bin/bash

# 部署脚本 - 留言反馈系统
# 后端端口: 10013, 前端端口: 10023

set -e

# 配置
SERVER_IP="49.235.161.106"
SSH_PORT=22
BACKEND_PORT=10013
FRONTEND_PORT=10023
PROJECT_NAME="message-board"

# 本地路径
LOCAL_BACKEND_JAR="backend/target/message-board-1.0.0.jar"
LOCAL_FRONTEND_DIR="frontend"

# 服务器路径
REMOTE_BASE_DIR="/opt/projects/${PROJECT_NAME}-${BACKEND_PORT}"
REMOTE_JAR_DIR="${REMOTE_BASE_DIR}/jar"
REMOTE_LOG_DIR="${REMOTE_BASE_DIR}/logs"
REMOTE_DATA_DIR="${REMOTE_BASE_DIR}/data-${BACKEND_PORT}"
REMOTE_FRONTEND_DIR="${REMOTE_BASE_DIR}/dist-${FRONTEND_PORT}"
REMOTE_NGINX_CONF="/etc/nginx/conf.d/${PROJECT_NAME}-${FRONTEND_PORT}.conf"

echo "========== 开始部署 =========="
echo "后端端口: ${BACKEND_PORT}"
echo "前端端口: ${FRONTEND_PORT}"
echo ""

# 检查参数
if [ "$1" == "local-build" ]; then
    echo "========== 本地构建 =========="

    # 打包后端
    echo "打包后端..."
    cd backend
    mvn clean package -DskipTests
    cd ..

    # 上传文件到服务器
    echo "上传后端JAR到服务器..."
    ssh -p ${SSH_PORT} root@${SERVER_IP} "mkdir -p ${REMOTE_JAR_DIR} ${REMOTE_LOG_DIR} ${REMOTE_DATA_DIR} ${REMOTE_FRONTEND_DIR}"
    scp -P ${SSH_PORT} ${LOCAL_BACKEND_JAR} root@${SERVER_IP}:${REMOTE_JAR_DIR}/message-board-${BACKEND_PORT}.jar

    # 上传前端源码到服务器构建
    echo "上传前端源码到服务器..."
    scp -P ${SSH_PORT} -r ${LOCAL_FRONTEND_DIR} root@${SERVER_IP}:${REMOTE_BASE_DIR}/
fi

# 服务器端操作
echo ""
echo "========== 服务器端操作 =========="

ssh -p ${SSH_PORT} root@${SERVER_IP} << EOF
    set -e

    echo "1. 检查并停止占用端口的进程..."
    # 停止后端进程
    BACKEND_PID=\$(lsof -t -i:${BACKEND_PORT} 2>/dev/null || echo "")
    if [ -n "\$BACKEND_PID" ]; then
        echo "  停止后端进程 PID: \$BACKEND_PID"
        kill -9 \$BACKEND_PID 2>/dev/null || true
    fi

    # 检查Nginx配置
    if [ -f "${REMOTE_NGINX_CONF}" ]; then
        echo "  移除旧的Nginx配置..."
        rm -f ${REMOTE_NGINX_CONF}
    fi

    echo "2. 检查Node.js环境..."
    if ! command -v node &> /dev/null; then
        echo "  安装Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
    fi
    echo "  Node版本: \$(node -v)"
    echo "  NPM版本: \$(npm -v)"

    echo "3. 构建前端..."
    cd ${REMOTE_BASE_DIR}/frontend
    npm install
    npm run build

    # 移动构建产物到正确位置
    rm -rf ${REMOTE_FRONTEND_DIR}/*
    cp -r dist/* ${REMOTE_FRONTEND_DIR}/

    echo "4. 创建数据目录..."
    mkdir -p ${REMOTE_DATA_DIR}
    if [ ! -f "${REMOTE_DATA_DIR}/messages.json" ]; then
        echo "[]" > ${REMOTE_DATA_DIR}/messages.json
    fi

    echo "5. 配置Nginx..."
    cat > ${REMOTE_NGINX_CONF} << 'NGINX_EOF'
server {
    listen ${FRONTEND_PORT};
    server_name localhost;

    location / {
        root ${REMOTE_FRONTEND_DIR};
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:${BACKEND_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_EOF

    echo "6. 测试Nginx配置..."
    nginx -t

    echo "7. 重载Nginx..."
    systemctl reload nginx

    echo "8. 启动后端服务..."
    cd ${REMOTE_BASE_DIR}
    nohup java -jar ${REMOTE_JAR_DIR}/message-board-${BACKEND_PORT}.jar \
        --server.port=${BACKEND_PORT} \
        --message.data.path=${REMOTE_DATA_DIR}/messages.json \
        > ${REMOTE_LOG_DIR}/app-${BACKEND_PORT}.log 2>&1 &

    sleep 3

    echo "9. 检查服务状态..."
    BACKEND_PID=\$(lsof -t -i:${BACKEND_PORT} 2>/dev/null || echo "")
    if [ -n "\$BACKEND_PID" ]; then
        echo "  ✓ 后端服务已启动 (PID: \$BACKEND_PID, 端口: ${BACKEND_PORT})"
    else
        echo "  ✗ 后端服务启动失败"
        exit 1
    fi

    # 检查Nginx监听端口
    NGINX_LISTEN=\$(netstat -tlnp 2>/dev/null | grep ":${FRONTEND_PORT}" || echo "")
    if [ -n "\$NGINX_LISTEN" ]; then
        echo "  ✓ Nginx已监听端口 ${FRONTEND_PORT}"
    else
        echo "  ✗ Nginx未监听端口 ${FRONTEND_PORT}"
        exit 1
    fi

    echo ""
    echo "========== 部署完成 =========="
    echo "后端地址: http://${SERVER_IP}:${BACKEND_PORT}"
    echo "前端地址: http://${SERVER_IP}:${FRONTEND_PORT}"
    echo "日志文件: ${REMOTE_LOG_DIR}/app-${BACKEND_PORT}.log"
    echo "数据文件: ${REMOTE_DATA_DIR}/messages.json"
EOF

echo ""
echo "部署脚本执行完成!"
