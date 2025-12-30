#!/bin/bash

# 真实图片测试运行脚本
# 专门用于测试皮肤分析和成分提取功能

echo "🎯 开始运行真实图片测试..."
echo "📷 测试图片:"
echo "   - 皮肤分析: 1924903380_1761459787694.jpg"
echo "   - 成分提取: images.jpeg"
echo ""

# 检查后端服务器
echo "📡 检查后端服务器..."
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo "✅ 后端服务器正在运行"
else
    echo "⚠️  警告: 无法连接到后端服务器 (http://localhost:5000)"
    echo "   请确保后端服务器已启动"
    exit 1
fi

echo ""
echo "🔍 查找可用的iOS模拟器..."

# 获取第一个可用的iPhone模拟器（正确提取设备名称）
# 格式:     iPhone 17 Pro (752ABFA8-46D8-44DC-8E95-0B5C22DF92D2) (Booted)
# 我们需要提取 "iPhone 17 Pro" 这部分（在第一个括号之前）
SIMULATOR_LINE=$(xcrun simctl list devices available | grep -i "iPhone" | grep -v "iPad" | head -1)

# 方法1: 使用awk提取第一个括号之前的内容
SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | awk -F'(' '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

# 方法2: 如果失败，尝试使用sed
if [ -z "$SIMULATOR_NAME" ] || [ "$SIMULATOR_NAME" = "Booted" ]; then
    SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | sed -E 's/^[[:space:]]*([^(]+)\(.*/\1/' | sed 's/[[:space:]]*$//')
fi

# 方法3: 如果还是失败，使用默认值
if [ -z "$SIMULATOR_NAME" ] || [ "$SIMULATOR_NAME" = "Booted" ] || [ "$SIMULATOR_NAME" = "" ]; then
    SIMULATOR_NAME="iPhone 17 Pro"
    echo "⚠️  无法自动检测设备，使用默认: $SIMULATOR_NAME"
    echo "   原始设备列表: $SIMULATOR_LINE"
else
    echo "✅ 成功检测到设备: $SIMULATOR_NAME"
fi

echo "📱 使用模拟器: $SIMULATOR_NAME"
echo ""
echo "🧪 运行真实图片测试..."
echo ""

# 运行真实图片测试
echo "🔧 执行命令: xcodebuild test -scheme AIskin -destination 'platform=iOS Simulator,name=$SIMULATOR_NAME' -only-testing:AIskinTests/RealImageTests"
echo ""

# 使用临时文件保存退出码，因为tee会改变$?
TEMP_LOG=$(mktemp)
xcodebuild test \
    -scheme AIskin \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -only-testing:AIskinTests/RealImageTests 2>&1 | tee "$TEMP_LOG" | tee real_image_test_output.log
TEST_EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "📊 测试退出码: $TEST_EXIT_CODE"

# 检查日志中是否有严重错误（设备未找到等）
if grep -qi "error:" real_image_test_output.log && grep -qi "Unable to find a device" real_image_test_output.log; then
    echo "❌ 严重错误: 找不到指定的模拟器设备"
    echo "   请检查模拟器名称是否正确: $SIMULATOR_NAME"
    rm -f "$TEMP_LOG"
    exit 1
fi

# 检查是否有测试执行
if ! grep -qi "Test Suite\|Test Case\|passed\|failed" real_image_test_output.log; then
    echo "⚠️  警告: 未检测到测试执行记录，测试可能未成功运行"
    echo "   请检查模拟器是否可用，以及Xcode项目配置"
    rm -f "$TEMP_LOG"
    exit 1
fi

rm -f "$TEMP_LOG"

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ 真实图片测试完成!"
    echo ""
    echo "📊 测试结果摘要:"
    echo "   - 皮肤分析测试: 已执行"
    echo "   - 成分提取测试: 已执行"
    echo ""
    echo "💡 查看详细日志: real_image_test_output.log"
    echo "💡 查看后端日志: 检查后端服务器终端输出"
    exit 0
else
    echo ""
    echo "❌ 部分测试失败，请查看 real_image_test_output.log"
    echo ""
    echo "💡 常见问题:"
    echo "   1. 图片文件未找到 - 确保图片在 AIskinTests 目录中"
    echo "   2. 后端AI服务未配置 - 检查后端环境变量"
    echo "   3. 网络连接问题 - 检查后端服务器状态"
    echo "   4. 模拟器问题 - 检查模拟器名称是否正确"
    exit 1
fi

