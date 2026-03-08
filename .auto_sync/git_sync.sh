#!/bin/bash
# Git 自动同步脚本
# 功能：检测文件变动，自动提交并推送到 GitHub

PROJECT_DIR="/Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive"
LOG_FILE="$PROJECT_DIR/.auto_sync/sync.log"

cd "$PROJECT_DIR" || exit 1

# 获取当前时间
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

echo "[$TIMESTAMP] 检查文件变动..." >> "$LOG_FILE"

# 添加所有文件（排除 .git 目录）
git add .

# 检查是否有变动
if [[ -n $(git status -s) ]]; then
    echo "[$TIMESTAMP] 检测到变动，正在提交..." >> "$LOG_FILE"
    
    # 提交变更
    git commit -m "Auto update: $TIMESTAMP" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$TIMESTAMP] 提交成功，正在推送到 GitHub..." >> "$LOG_FILE"
        
        # 推送到 GitHub
        git push origin main >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            echo "[$TIMESTAMP] ✅ 同步完成！" >> "$LOG_FILE"
            echo "✅ 同步完成！"
        else
            echo "[$TIMESTAMP] ❌ 推送失败" >> "$LOG_FILE"
            echo "❌ 推送失败，请检查网络或 Git 配置"
        fi
    else
        echo "[$TIMESTAMP] ❌ 提交失败" >> "$LOG_FILE"
    fi
else
    echo "[$TIMESTAMP] 没有文件变动" >> "$LOG_FILE"
fi
