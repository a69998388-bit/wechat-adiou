#!/bin/bash
# 文件监控脚本
# 功能：监控目录变动，自动触发 Git 同步

PROJECT_DIR="/Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive"
SYNC_SCRIPT="$PROJECT_DIR/.auto_sync/git_sync.sh"
LOG_FILE="$PROJECT_DIR/.auto_sync/sync.log"

echo "========================================" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') 监控服务已启动" >> "$LOG_FILE"
echo "监控目录: $PROJECT_DIR" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"

# 查找 fswatch 路径
FSWATCH_PATH="/usr/local/bin/fswatch"
if [ ! -f "$FSWATCH_PATH" ]; then
    FSWATCH_PATH="/opt/homebrew/bin/fswatch"
fi

if [ ! -f "$FSWATCH_PATH" ]; then
    echo "❌ 未找到 fswatch，请先安装: brew install fswatch" | tee -a "$LOG_FILE"
    exit 1
fi

echo "✅ fswatch 路径: $FSWATCH_PATH" >> "$LOG_FILE"

# 监控目录，忽略 .git 文件夹变化，等待 3 秒合并多次变动
$FSWATCH_PATH -o -l 3 -r \
    --exclude='\.git' \
    --exclude='\.DS_Store' \
    "$PROJECT_DIR" | while read num_event; do
    
    echo "" >> "$LOG_FILE"
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') 检测到文件变动，触发同步..." >> "$LOG_FILE"
    
    # 执行同步
    bash "$SYNC_SCRIPT"
    
    echo "----------------------------------------" >> "$LOG_FILE"
    echo "等待下一次变动..." >> "$LOG_FILE"
done
