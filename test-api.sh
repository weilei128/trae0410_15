#!/bin/bash
# ============================================
# API测试脚本 - 留言反馈系统完整测试
# ============================================

set -e

# 配置
BASE_URL="${BASE_URL:-http://49.235.161.106:10013}"
FRONTEND_URL="${FRONTEND_URL:-http://49.235.161.106:10023}"

echo "=========================================="
echo "  留言反馈系统 - API测试脚本"
echo "=========================================="
echo "后端地址: $BASE_URL"
echo "前端地址: $FRONTEND_URL"
echo ""

# 计数器
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
test_api() {
    local name="$1"
    local method="$2"
    local endpoint="$3"
    local data="${4:-}"
    local expected_status="${5:-200}"
    
    echo -n "测试: $name ... "
    
    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            -H "Content-Type: application/json" \
            -d "$data" \
            "${BASE_URL}${endpoint}" 2>/dev/null || echo "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" \
            "${BASE_URL}${endpoint}" 2>/dev/null || echo "\n000")
    fi
    
    status_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✓ 通过 (HTTP $status_code)"
        ((TESTS_PASSED++))
        return 0
    else
        echo "✗ 失败 (期望 HTTP $expected_status, 实际 HTTP $status_code)"
        echo "  响应: $body"
        ((TESTS_FAILED++))
        return 1
    fi
}

test_cors() {
    echo -n "测试: 跨域(CORS)支持 ... "
    
    response=$(curl -s -I -X OPTIONS \
        -H "Origin: http://example.com" \
        -H "Access-Control-Request-Method: POST" \
        -H "Access-Control-Request-Headers: Content-Type" \
        "${BASE_URL}/api/messages" 2>/dev/null)
    
    if echo "$response" | grep -q "Access-Control-Allow-Origin"; then
        echo "✓ 通过 (支持CORS)"
        ((TESTS_PASSED++))
    else
        echo "✗ 失败 (CORS头缺失)"
        ((TESTS_FAILED++))
    fi
}

echo "=========================================="
echo "一、基础接口测试"
echo "=========================================="

# 1. 获取留言列表
test_api "获取留言列表(分页)" "GET" "/api/messages?page=1&size=10"

# 2. 获取所有留言
test_api "获取所有留言" "GET" "/api/messages/all"

echo ""
echo "=========================================="
echo "二、功能测试 - 提交留言"
echo "=========================================="

# 3. 正常提交留言
test_api "提交正常留言" "POST" "/api/messages" \
    '{"username":"测试用户","content":"这是一条测试留言","isAdmin":false}'

# 4. 管理员提交留言
test_api "提交管理员留言" "POST" "/api/messages" \
    '{"username":"管理员","content":"这是管理员发布的公告","isAdmin":true}'

echo ""
echo "=========================================="
echo "三、敏感词过滤测试"
echo "=========================================="

# 5. 包含敏感词的留言
echo -n "测试: 提交含敏感词留言 ... "
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"测试用户","content":"这条留言包含脏话和广告"}' \
    "${BASE_URL}/api/messages" 2>/dev/null)

if echo "$response" | grep -q "\*\*"; then
    echo "✓ 通过 (敏感词已被过滤)"
    ((TESTS_PASSED++))
else
    echo "✗ 失败 (敏感词未被过滤)"
    echo "  响应: $response"
    ((TESTS_FAILED++))
fi

# 6. 多个敏感词
echo -n "测试: 提交含多个敏感词 ... "
response=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"测试用户","content":"色情、赌博、毒品都是违法的"}' \
    "${BASE_URL}/api/messages" 2>/dev/null)

if echo "$response" | grep -q "\*\*"; then
    echo "✓ 通过 (多个敏感词已被过滤)"
    ((TESTS_PASSED++))
else
    echo "✗ 失败 (敏感词未被过滤)"
    echo "  响应: $response"
    ((TESTS_FAILED++))
fi

echo ""
echo "=========================================="
echo "四、异常场景测试"
echo "=========================================="

# 7. 空内容提交
test_api "提交空内容留言(应失败)" "POST" "/api/messages" \
    '{"username":"测试用户","content":""}' "400"

# 8. 空用户名提交
test_api "提交空用户名(应失败)" "POST" "/api/messages" \
    '{"username":"","content":"内容"}' "400"

# 9. 超长内容提交 (1000字符)
LONG_CONTENT=$(python3 -c "print('A'*1000)" 2>/dev/null || printf 'A%.0s' {1..1000})
test_api "提交超长内容(1000字符)" "POST" "/api/messages" \
    "{\"username\":\"测试用户\",\"content\":\"$LONG_CONTENT\"}"

# 10. 特殊字符提交
test_api "提交含特殊字符留言" "POST" "/api/messages" \
    '{"username":"测试<>用户","content":"内容<script>alert(1)</script>"}'

# 11. 获取不存在的留言
test_api "获取不存在的留言(应404)" "GET" "/api/messages/99999" "" "404"

echo ""
echo "=========================================="
echo "五、分页和排序测试"
echo "=========================================="

# 12. 不同分页参数
test_api "分页测试 - 第1页10条" "GET" "/api/messages?page=1&size=10"
test_api "分页测试 - 第2页5条" "GET" "/api/messages?page=2&size=5"

# 13. 管理员筛选
test_api "筛选管理员留言" "GET" "/api/messages?isAdmin=true"
test_api "筛选普通留言" "GET" "/api/messages?isAdmin=false"

echo ""
echo "=========================================="
echo "六、跨域测试"
echo "=========================================="

test_cors

echo ""
echo "=========================================="
echo "七、前端页面测试"
echo "=========================================="

echo -n "测试: 前端页面可访问 ... "
response=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}/" 2>/dev/null || echo "000")
if [ "$response" = "200" ]; then
    echo "✓ 通过 (HTTP 200)"
    ((TESTS_PASSED++))
else
    echo "✗ 失败 (HTTP $response)"
    ((TESTS_FAILED++))
fi

echo -n "测试: 前端API代理 ... "
response=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}/api/messages" 2>/dev/null || echo "000")
if [ "$response" = "200" ]; then
    echo "✓ 通过 (代理正常)"
    ((TESTS_PASSED++))
else
    echo "✗ 失败 (HTTP $response)"
    ((TESTS_FAILED++))
fi

echo ""
echo "=========================================="
echo "八、数据持久化测试"
echo "=========================================="

# 提交一条新留言
echo "提交测试留言用于持久化验证..."
new_message=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"持久化测试","content":"验证数据不丢失"}' \
    "${BASE_URL}/api/messages" 2>/dev/null)

echo -n "测试: 数据已保存 ... "
if echo "$new_message" | grep -q "持久化测试"; then
    echo "✓ 通过"
    ((TESTS_PASSED++))
else
    echo "✗ 失败"
    ((TESTS_FAILED++))
fi

echo ""
echo "=========================================="
echo "九、删除功能测试"
echo "=========================================="

# 先创建一条留言用于删除
echo "创建待删除的测试留言..."
delete_test=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"username":"删除测试","content":"这条留言将被删除"}' \
    "${BASE_URL}/api/messages" 2>/dev/null)

# 提取ID (简单处理)
delete_id=$(echo "$delete_test" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -n "$delete_id" ]; then
    echo "创建成功，留言ID: $delete_id"
    
    # 删除留言
    test_api "删除留言" "DELETE" "/api/messages/${delete_id}"
    
    # 验证已删除
    test_api "验证留言已删除(应404)" "GET" "/api/messages/${delete_id}" "" "404"
else
    echo "✗ 无法获取留言ID，跳过删除测试"
    ((TESTS_FAILED+=2))
fi

echo ""
echo "=========================================="
echo "十、性能测试"
echo "=========================================="

echo "执行10次并发请求测试..."
START_TIME=$(date +%s%N)

for i in {1..10}; do
    curl -s -o /dev/null "${BASE_URL}/api/messages" &
done
wait

END_TIME=$(date +%s%N)
DURATION=$(( (END_TIME - START_TIME) / 1000000 ))

echo "  10次请求完成，耗时: ${DURATION}ms"
if [ $DURATION -lt 5000 ]; then
    echo "  ✓ 性能良好"
else
    echo "  ! 性能一般 (耗时较长)"
fi

echo ""
echo "=========================================="
echo "测试汇总"
echo "=========================================="
echo "通过: $TESTS_PASSED"
echo "失败: $TESTS_FAILED"
echo "总计: $((TESTS_PASSED + TESTS_FAILED))"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo "✓ 所有测试通过!"
    exit 0
else
    echo "✗ 存在失败的测试"
    exit 1
fi
