#!/bin/bash

# 验证测试环境设置脚本

echo "🔍 验证测试环境设置..."
echo ""

# 1. 检查后端服务器
echo "1️⃣ 检查后端服务器..."
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo "   ✅ 后端服务器运行正常 (http://localhost:5000)"
else
    echo "   ❌ 后端服务器未运行"
    echo "   💡 请运行: cd '/Users/terry/Downloads/aiskin 3/AISkin_backend-main' && npm start"
    exit 1
fi

# 2. 检查图片文件
echo ""
echo "2️⃣ 检查测试图片文件..."

SKIN_IMAGE="/Users/terry/Desktop/coding/projiect/skin/skintest/AIskin/AIskinTests/1924903380_1761459787694.jpg"
PRODUCT_IMAGE="/Users/terry/Desktop/coding/projiect/skin/skintest/AIskin/AIskinTests/images.jpeg"

if [ -f "$SKIN_IMAGE" ]; then
    SIZE=$(stat -f%z "$SKIN_IMAGE" 2>/dev/null || stat -c%s "$SKIN_IMAGE" 2>/dev/null)
    SIZE_KB=$((SIZE / 1024))
    echo "   ✅ 皮肤分析图片存在: $SKIN_IMAGE ($SIZE_KB KB)"
else
    echo "   ❌ 皮肤分析图片不存在: $SKIN_IMAGE"
fi

if [ -f "$PRODUCT_IMAGE" ]; then
    SIZE=$(stat -f%z "$PRODUCT_IMAGE" 2>/dev/null || stat -c%s "$PRODUCT_IMAGE" 2>/dev/null)
    SIZE_KB=$((SIZE / 1024))
    echo "   ✅ 产品图片存在: $PRODUCT_IMAGE ($SIZE_KB KB)"
else
    echo "   ❌ 产品图片不存在: $PRODUCT_IMAGE"
fi

# 3. 检查测试文件
echo ""
echo "3️⃣ 检查测试文件..."

TEST_FILES=(
    "AIskinTests/APIClientTests.swift"
    "AIskinTests/UserApiServiceTests.swift"
    "AIskinTests/ProductApiServiceTests.swift"
    "AIskinTests/SkinAnalysisApiServiceTests.swift"
    "AIskinTests/PlanApiServiceTests.swift"
    "AIskinTests/ConflictApiServiceTests.swift"
    "AIskinTests/IngredientAnalysisApiServiceTests.swift"
    "AIskinTests/AuthServiceTests.swift"
    "AIskinTests/IntegrationTests.swift"
    "AIskinTests/RealImageTests.swift"
)

BASE_DIR="/Users/terry/Desktop/coding/projiect/skin/skintest/AIskin"
ALL_TESTS_EXIST=true

for test_file in "${TEST_FILES[@]}"; do
    if [ -f "$BASE_DIR/$test_file" ]; then
        echo "   ✅ $test_file"
    else
        echo "   ❌ $test_file (不存在)"
        ALL_TESTS_EXIST=false
    fi
done

# 4. 检查可用的模拟器
echo ""
echo "4️⃣ 检查可用的iOS模拟器..."

SIMULATORS=$(xcrun simctl list devices available | grep -i "iPhone" | grep -v "iPad" | head -3)
if [ -n "$SIMULATORS" ]; then
    echo "   ✅ 找到可用模拟器:"
    echo "$SIMULATORS" | while read -r line; do
        echo "      $line"
    done
else
    echo "   ⚠️  未找到可用的iPhone模拟器"
fi

# 5. 总结
echo ""
echo "============================================================"
echo "📊 验证结果总结"
echo "============================================================"

if [ -f "$SKIN_IMAGE" ] && [ -f "$PRODUCT_IMAGE" ] && [ "$ALL_TESTS_EXIST" = true ]; then
    echo "✅ 所有检查通过！"
    echo ""
    echo "🚀 可以开始运行测试:"
    echo "   ./run_tests.sh              # 运行所有测试"
    echo "   ./run_real_image_tests.sh   # 运行真实图片测试"
    exit 0
else
    echo "⚠️  部分检查未通过，请修复后重试"
    exit 1
fi

