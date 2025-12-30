#!/bin/bash

# AIskin 测试运行脚本
# 用于快速运行所有测试

echo "🚀 开始运行 AIskin 测试套件..."
echo ""

# 检查后端服务器是否运行
echo "📡 检查后端服务器..."
if curl -s http://localhost:5000 > /dev/null 2>&1; then
    echo "✅ 后端服务器正在运行"
else
    echo "⚠️  警告: 无法连接到后端服务器 (http://localhost:5000)"
    echo "   请确保后端服务器已启动:"
    echo "   cd '/Users/terry/Downloads/aiskin 3/AISkin_backend-main' && npm start"
    echo ""
    read -p "是否继续运行测试? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🔍 查找可用的iOS模拟器..."

# 获取第一个可用的iPhone模拟器名称（正确提取）
# 格式:     iPhone 17 Pro (752ABFA8-46D8-44DC-8E95-0B5C22DF92D2) (Booted)
SIMULATOR_LINE=$(xcrun simctl list devices available | grep -i "iPhone" | grep -v "iPad" | head -1)
SIMULATOR_NAME=$(echo "$SIMULATOR_LINE" | awk -F'(' '{print $1}' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

if [ -z "$SIMULATOR_NAME" ] || [ "$SIMULATOR_NAME" = "Booted" ]; then
    # 如果找不到，使用iPhone 17 Pro（从终端输出看这是可用的）
    SIMULATOR_NAME="iPhone 17 Pro"
    echo "⚠️  无法自动检测设备，使用默认: $SIMULATOR_NAME"
else
    echo "✅ 成功检测到设备: $SIMULATOR_NAME"
fi

echo "📱 使用模拟器: $SIMULATOR_NAME"
echo ""
echo "🧪 运行测试..."
echo ""

# 运行测试
xcodebuild test \
    -scheme AIskin \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME" \
    -only-testing:AIskinTests 2>&1 | tee test_output.log

# 检查测试结果
TEST_EXIT_CODE=$?

if [ $TEST_EXIT_CODE -eq 0 ]; then
    echo ""
    echo "✅ 所有测试通过!"
    exit 0
else
    echo ""
    echo "❌ 部分测试失败，请查看 test_output.log 获取详细信息"
    echo ""
    echo "💡 提示:"
    echo "   - 如果看到 '无法连接到服务器' 错误，请确保后端服务器正在运行"
    echo "   - 如果看到 '未授权' 错误，请检查token是否正确保存"
    echo "   - 查看 test_output.log 文件获取详细错误信息"
    exit 1
fi
