#!/bin/bash
# ============================================
# 服务器端部署脚本 - 留言反馈系统
# 后端端口: 10013, 前端端口: 10023
# ============================================

set -e

# 配置
BACKEND_PORT=10013
FRONTEND_PORT=10023
PROJECT_NAME="message-board"
BASE_DIR="/opt/projects/${PROJECT_NAME}-${BACKEND_PORT}"
JAR_DIR="${BASE_DIR}/jar"
LOG_DIR="${BASE_DIR}/logs"
DATA_DIR="${BASE_DIR}/data-${BACKEND_PORT}"
FRONTEND_DIST="${BASE_DIR}/dist-${FRONTEND_PORT}"
NGINX_CONF="/etc/nginx/conf.d/${PROJECT_NAME}-${FRONTEND_PORT}.conf"

echo "=========================================="
echo "  留言反馈系统部署脚本"
echo "  后端端口: ${BACKEND_PORT}"
echo "  前端端口: ${FRONTEND_PORT}"
echo "=========================================="
echo ""

# 函数：停止占用端口的进程
stop_port_processes() {
    echo "[1/8] 检查并停止占用端口的进程..."
    
    # 停止后端进程
    BACKEND_PID=$(lsof -t -i:${BACKEND_PORT} 2>/dev/null || echo "")
    if [ -n "$BACKEND_PID" ]; then
        echo "  停止后端进程 PID: $BACKEND_PID (端口: ${BACKEND_PORT})"
        kill -9 $BACKEND_PID 2>/dev/null || true
        sleep 1
    fi
    
    # 检查是否还有进程占用
    if lsof -i:${BACKEND_PORT} > /dev/null 2>&1; then
        echo "  警告: 端口 ${BACKEND_PORT} 仍被占用"
    else
        echo "  ✓ 端口 ${BACKEND_PORT} 已释放"
    fi
    
    echo ""
}

# 函数：安装Node.js
install_nodejs() {
    echo "[2/8] 检查Node.js环境..."
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node -v)
        NPM_VERSION=$(npm -v)
        echo "  Node.js已安装: $NODE_VERSION"
        echo "  NPM已安装: $NPM_VERSION"
    else
        echo "  安装Node.js 18.x..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
        apt-get install -y nodejs
        echo "  ✓ Node.js安装完成: $(node -v)"
    fi
    echo ""
}

# 函数：构建前端
build_frontend() {
    echo "[3/8] 构建前端项目..."
    
    FRONTEND_SRC="${BASE_DIR}/frontend-src"
    
    if [ ! -d "$FRONTEND_SRC" ]; then
        echo "  错误: 前端源码目录不存在: $FRONTEND_SRC"
        exit 1
    fi
    
    cd "$FRONTEND_SRC"
    
    echo "  安装依赖..."
    npm install
    
    echo "  构建项目..."
    npm run build
    
    # 复制构建产物
    rm -rf "$FRONTEND_DIST"
    mkdir -p "$FRONTEND_DIST"
    cp -r dist/* "$FRONTEND_DIST/"
    
    echo "  ✓ 前端构建完成"
    echo ""
}

# 函数：创建数据目录
setup_data_dir() {
    echo "[4/8] 设置数据目录..."
    
    mkdir -p "$DATA_DIR"
    
    if [ ! -f "${DATA_DIR}/messages.json" ]; then
        echo "[]" > "${DATA_DIR}/messages.json"
        echo "  创建初始数据文件"
    fi
    
    echo "  数据目录: $DATA_DIR"
    echo "  ✓ 数据目录设置完成"
    echo ""
}

# 函数：配置Nginx
setup_nginx() {
    echo "[5/8] 配置Nginx..."
    
    # 创建Nginx配置
    cat > "$NGINX_CONF" << EOF
server {
    listen ${FRONTEND_PORT};
    server_name localhost;
    root ${FRONTEND_DIST};
    index index.html;

    # 前端页面
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API代理到后端
    location /api {
        proxy_pass http://127.0.0.1:${BACKEND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Connection "";
    }

    # 静态资源缓存
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF
    
    echo "  Nginx配置: $NGINX_CONF"
    
    # 测试配置
    if nginx -t; then
        echo "  ✓ Nginx配置测试通过"
    else
        echo "  ✗ Nginx配置测试失败"
        exit 1
    fi
    
    # 重载Nginx
    systemctl reload nginx
    echo "  ✓ Nginx已重载"
    echo ""
}

# 函数：启动后端
start_backend() {
    echo "[6/8] 启动后端服务..."
    
    JAR_FILE="${JAR_DIR}/message-board-${BACKEND_PORT}.jar"
    
    if [ ! -f "$JAR_FILE" ]; then
        echo "  错误: JAR文件不存在: $JAR_FILE"
        exit 1
    fi
    
    # 启动服务
    nohup java -jar "$JAR_FILE" \
        --server.port=${BACKEND_PORT} \
        --message.data.path=${DATA_DIR}/messages.json \
        > "${LOG_DIR}/app-${BACKEND_PORT}.log" 2>&1 &
    
    # 等待服务启动
    sleep 5
    
    # 检查是否启动成功
    BACKEND_PID=$(lsof -t -i:${BACKEND_PORT} 2>/dev/null || echo "")
    if [ -n "$BACKEND_PID" ]; then
        echo "  ✓ 后端服务已启动 (PID: $BACKEND_PID)"
        echo "  日志文件: ${LOG_DIR}/app-${BACKEND_PORT}.log"
    else
        echo "  ✗ 后端服务启动失败"
        echo "  查看日志: ${LOG_DIR}/app-${BACKEND_PORT}.log"
        exit 1
    fi
    echo ""
}

# 函数：验证部署
verify_deployment() {
    echo "[7/8] 验证部署..."
    
    # 检查后端口
    if lsof -i:${BACKEND_PORT} > /dev/null 2>&1; then
        echo "  ✓ 后端服务运行正常 (端口: ${BACKEND_PORT})"
    else
        echo "  ✗ 后端服务未运行"
        return 1
    fi
    
    # 检查前端端口
    if netstat -tlnp 2>/dev/null | grep -q ":${FRONTEND_PORT}"; then
        echo "  ✓ Nginx前端运行正常 (端口: ${FRONTEND_PORT})"
    else
        echo "  ✗ Nginx前端未运行"
        return 1
    fi
    
    # 测试API
    echo "  测试API接口..."
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:${BACKEND_PORT}/api/messages 2>/dev/null || echo "000")
    if [ "$API_RESPONSE" = "200" ]; then
        echo "  ✓ API接口响应正常"
    else
        echo "  ! API接口返回状态码: $API_RESPONSE"
    fi
    
    echo ""
}

# 函数：显示状态
show_status() {
    echo "[8/8] 部署状态汇总"
    echo "=========================================="
    echo "项目名称: ${PROJECT_NAME}"
    echo "后端端口: ${BACKEND_PORT}"
    echo "前端端口: ${FRONTEND_PORT}"
    echo "------------------------------------------"
    echo "访问地址:"
    echo "  前端: http://$(curl -s ifconfig.me 2>/dev/null || echo '服务器IP'):${FRONTEND_PORT}"
    echo "  后端: http://$(curl -s ifconfig.me 2>/dev/null || echo '服务器IP'):${BACKEND_PORT}"
    echo "------------------------------------------"
    echo "文件位置:"
    echo "  JAR文件: ${JAR_DIR}/message-board-${BACKEND_PORT}.jar"
    echo "  日志文件: ${LOG_DIR}/app-${BACKEND_PORT}.log"
    echo "  数据文件: ${DATA_DIR}/messages.json"
    echo "  前端文件: ${FRONTEND_DIST}"
    echo "  Nginx配置: ${NGINX_CONF}"
    echo "=========================================="
    echo ""
    echo "常用命令:"
    echo "  查看日志: tail -f ${LOG_DIR}/app-${BACKEND_PORT}.log"
    echo "  停止服务: kill $(lsof -t -i:${BACKEND_PORT} 2>/dev/null || echo 'PID')"
    echo "  重启Nginx: systemctl reload nginx"
    echo ""
}

# 主函数
main() {
    # 创建目录
    mkdir -p "$BASE_DIR" "$JAR_DIR" "$LOG_DIR" "$DATA_DIR" "$FRONTEND_DIST"
    
    case "${1:-deploy}" in
        stop)
            stop_port_processes
            echo "服务已停止"
            ;;
        restart)
            stop_port_processes
            start_backend
            ;;
        status)
            show_status
            ;;
        deploy|*)
            stop_port_processes
            install_nodejs
            build_frontend
            setup_data_dir
            setup_nginx
            start_backend
            verify_deployment
            show_status
            echo "✓ 部署完成!"
            ;;
    esac
}

main "$@"
