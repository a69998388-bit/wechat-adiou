#!/bin/bash
#===============================================================================
# 微信音频库 - Git 自动同步脚本
# 功能：检测 audio/ 和 playlist.json 变动，自动提交推送到 GitHub
# 
# 核心原则：
# 1. 只监控 audio/ 文件夹和 playlist.json
# 2. 绝不监控 .auto_sync/ 目录
# 3. 使用 git pull --rebase 避免历史分叉
# 4. 自动处理 .gitignore
#===============================================================================

# 路径配置
PROJECT_DIR="/Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive"
LOG_FILE="$PROJECT_DIR/.auto_sync/sync.log"
GITIGNORE_FILE="$PROJECT_DIR/.gitignore"

#===============================================================================
# 函数：记录日志
#===============================================================================
log() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

#===============================================================================
# 函数：初始化 .gitignore
#===============================================================================
init_gitignore() {
    if [ ! -f "$GITIGNORE_FILE" ]; then
        log "创建 .gitignore 文件..."
        cat > "$GITIGNORE_FILE" << 'EOF'
# 忽略自动同步目录
.auto_sync/
*.log

# 忽略系统文件
.DS_Store
*.DS_Store
._*

# 忽略临时文件
*.tmp
*.swp
*~

# 忽略依赖目录（如果有）
node_modules/
EOF
        log ".gitignore 创建完成"
    fi
}

#===============================================================================
# 函数：检查并重命名音频文件夹
#===============================================================================
check_audio_directory() {
    # 检查 audio 目录是否存在
    if [ ! -d "$PROJECT_DIR/audio" ]; then
        # 查找可能的音频目录
        for dir in "$PROJECT_DIR"/*/; do
            if [ -d "$dir" ]; then
                dirname=$(basename "$dir")
                # 检查是否包含音频文件
                if ls "$dir"*.m4a "$dir"*.mp3 "$dir"*.wav 2>/dev/null | head -1 > /dev/null; then
                    if [ "$dirname" != "audio" ] && [ "$dirname" != "data" ] && [ "$dirname" != ".auto_sync" ]; then
                        log "发现音频目录 '$dirname'，重命名为 'audio'..."
                        mv "$dir" "$PROJECT_DIR/audio"
                        break
                    fi
                fi
            fi
        done
    fi
}

#===============================================================================
# 函数：执行 Git 同步
#===============================================================================
git_sync() {
    log "========== 开始同步 =========="
    
    cd "$PROJECT_DIR" || { log "错误：无法进入项目目录"; return 1; }
    
    # 1. 初始化 .gitignore
    init_gitignore
    
    # 2. 检查音频目录
    check_audio_directory
    
    # 3. 清理已删除文件的暂存（如果有）
    git add -u audio/ 2>/dev/null
    git add -u data/playlist.json 2>/dev/null
    
    # 4. 添加需要同步的文件
    git add audio/
    git add data/playlist.json
    git add .gitignore
    git add index.html 2>/dev/null
    
    # 5. 检查是否有有效变动
    if ! git diff --staged --quiet; then
        # 显示变动内容
        log "检测到变动:"
        git diff --staged --name-status >> "$LOG_FILE"
        
        # 6. 先拉取远程最新代码（变基）
        log "执行 git pull --rebase..."
        if ! git pull --rebase origin main >> "$LOG_FILE" 2>&1; then
            log "⚠️ 拉取失败，可能有冲突"
            log "请手动解决冲突后重新运行"
            
            # 中止变基
            git rebase --abort 2>/dev/null
            return 1
        fi
        
        # 7. 提交变动
        local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
        log "提交变动..."
        if git commit -m "Auto update: $timestamp" >> "$LOG_FILE" 2>&1; then
            log "提交成功"
            
            # 8. 推送到远程
            log "推送到 GitHub..."
            if git push origin main >> "$LOG_FILE" 2>&1; then
                log "✅ 同步完成！"
                return 0
            else
                log "❌ 推送失败，请检查网络或认证配置"
                return 1
            fi
        else
            log "❌ 提交失败"
            return 1
        fi
    else
        log "没有有效文件变动，跳过"
        return 0
    fi
}

#===============================================================================
# 主程序
#===============================================================================
log "检查同步条件..."

# 切换到项目目录
cd "$PROJECT_DIR" || exit 1

# 检查 audio 目录是否存在
if [ ! -d "audio" ]; then
    log "音频目录不存在，等待下次触发..."
    exit 0
fi

# 检查是否有 audio 文件变动
if git diff --quiet audio/ data/playlist.json 2>/dev/null; then
    # 没有变动，检查是否有新文件
    if [ -z "$(git ls-files --others --exclude-standard audio/ data/playlist.json 2>/dev/null)" ]; then
        log "没有文件变动，跳过"
        exit 0
    fi
fi

# 执行同步
git_sync
exit $?
