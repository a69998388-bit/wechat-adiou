#!/bin/bash
#===============================================================================
# 微信音频库 - 文件监控脚本
# 功能：只监控 audio/ 文件夹和 playlist.json 的变动
# 原则：绝不监控 .auto_sync/ 目录，避免无限循环
#===============================================================================

# 路径配置
PROJECT_DIR="/Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive"
SYNC_SCRIPT="$PROJECT_DIR/.auto_sync/git_sync.sh"
LOG_FILE="$PROJECT_DIR/.auto_sync/sync.log"
PID_FILE="$PROJECT_DIR/.auto_sync/monitor.pid"

#===============================================================================
# 查找 fswatch 路径
#===============================================================================
find_fswatch() {
    for path in "/usr/local/bin/fswatch" "/opt/homebrew/bin/fswatch" "/usr/bin/fswatch"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

#===============================================================================
# 主程序
#===============================================================================

# 创建日志文件（如果不存在）
touch "$LOG_FILE"

echo "========================================" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') 监控服务启动" >> "$LOG_FILE"
echo "监控目标:" >> "$LOG_FILE"
echo "  - $PROJECT_DIR/audio/ (音频文件夹)" >> "$LOG_FILE"
echo "  - $PROJECT_DIR/data/playlist.json (播放列表)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# 查找 fswatch
FSWATCH=$(find_fswatch)
if [ -z "$FSWATCH" ]; then
    echo "❌ 未找到 fswatch，请先安装: brew install fswatch"
    echo "❌ 未找到 fswatch" >> "$LOG_FILE"
    exit 1
fi

echo "✅ 使用 fswatch: $FSWATCH" >> "$LOG_FILE"

# 保存 PID
echo $$ > "$PID_FILE"
echo "监控进程 PID: $$" >> "$LOG_FILE"

#===============================================================================
# 启动两个独立的监控进程
#===============================================================================

# 监控 audio/ 文件夹（递归）
# -o: 单次事件触发
# -l 5: 5秒延迟，合并多次变动
# -r: 递归监控子目录
$FSWATCH -o -l 5 -r \
    --exclude='.*' \
    "$PROJECT_DIR/audio" | while read event; do
    
    echo "" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') 检测到 audio 文件夹变动" >> "$LOG_FILE"
    
    # 调用同步脚本
    bash "$SYNC_SCRIPT"
    
    echo "等待下一次变动..." >> "$LOG_FILE"
done &

AUDIO_PID=$!
echo "audio 监控进程 PID: $AUDIO_PID" >> "$LOG_FILE"

# 监控 playlist.json 文件
$FSWATCH -o -l 5 \
    "$PROJECT_DIR/data/playlist.json" | while read event; do
    
    echo "" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') 检测到 playlist.json 变动" >> "$LOG_FILE"
    
    # 调用同步脚本
    bash "$SYNC_SCRIPT"
    
    echo "等待下一次变动..." >> "$LOG_FILE"
done &

JSON_PID=$!
echo "playlist.json 监控进程 PID: $JSON_PID" >> "$LOG_FILE"

#===============================================================================
# 等待子进程
#===============================================================================
echo "监控服务运行中，按 Ctrl+C 停止" >> "$LOG_FILE"

# 等待所有后台进程
wait
