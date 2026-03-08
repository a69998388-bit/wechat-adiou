#!/bin/bash
# 微信音频库 - 自动同步安装脚本
# 功能：安装依赖、配置 Git、启动后台监控服务

PROJECT_DIR="/Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive"
AUTO_SYNC_DIR="$PROJECT_DIR/.auto_sync"

echo "========================================"
echo "🎵 微信音频库 - 自动同步安装程序"
echo "========================================"

# 1. 检查并安装 fswatch
echo ""
echo "📦 检查 fswatch..."
if ! command -v fswatch &> /dev/null; then
    echo "   fswatch 未安装，正在安装..."
    brew install fswatch
    if [ $? -eq 0 ]; then
        echo "   ✅ fswatch 安装成功"
    else
        echo "   ❌ fswatch 安装失败，请手动运行: brew install fswatch"
        exit 1
    fi
else
    echo "   ✅ fswatch 已安装"
fi

# 2. 设置脚本权限
echo ""
echo "🔧 设置脚本权限..."
chmod +x "$AUTO_SYNC_DIR/git_sync.sh"
chmod +x "$AUTO_SYNC_DIR/monitor.sh"
echo "   ✅ 权限设置完成"

# 3. 检查 Git 配置
echo ""
echo "🔐 检查 Git 配置..."
cd "$PROJECT_DIR"

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    echo "   ⚠️ 目录不是 Git 仓库，正在初始化..."
    git init
    git add .
    git commit -m "Initial commit"
    
    echo ""
    echo "   请设置远程仓库地址："
    echo "   git remote add origin https://github.com/a69998388-bit/wechat-adiou.git"
    echo "   然后重新运行此脚本"
    exit 0
fi

# 检查远程仓库
if ! git remote -v | grep -q origin; then
    echo "   ⚠️ 未设置远程仓库，正在设置..."
    git remote add origin https://github.com/a69998388-bit/wechat-adiou.git
fi

echo "   ✅ Git 配置完成"

# 4. 首次手动同步
echo ""
echo "📤 执行首次同步..."
bash "$AUTO_SYNC_DIR/git_sync.sh"

# 5. 启动后台监控服务
echo ""
echo "🚀 启动后台监控服务..."

# 使用 nohup 在后台运行
nohup bash "$AUTO_SYNC_DIR/monitor.sh" > /dev/null 2>&1 &
MONITOR_PID=$!

echo "   ✅ 监控服务已启动 (PID: $MONITOR_PID)"

# 保存 PID
echo "$MONITOR_PID" > "$AUTO_SYNC_DIR/monitor.pid"

echo ""
echo "========================================"
echo "🎉 安装完成！"
echo "========================================"
echo ""
echo "📋 使用说明："
echo "   1. 监控服务已在后台运行"
echo "   2. 当 audio 文件夹或 playlist.json 变动时，会自动同步到 GitHub"
echo "   3. 查看同步日志: open $AUTO_SYNC_DIR/sync.log"
echo "   4. 停止监控: kill \$(cat $AUTO_SYNC_DIR/monitor.pid)"
echo ""
echo "🌐 GitHub Pages 网址："
echo "   https://a69998388-bit.github.io/wechat-adiou"
echo ""
