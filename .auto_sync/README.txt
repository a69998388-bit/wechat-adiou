# 微信音频库 - 自动同步使用说明

## 功能说明

自动监控 `audio` 文件夹和 `playlist.json` 的变动，当检测到新文件或修改时，自动提交并推送到 GitHub，触发 GitHub Pages 更新。

## 首次设置

### 1. 安装依赖

打开终端，运行：

```bash
brew install fswatch
```

### 2. 运行安装脚本

双击运行 `双击启动.command`，或终端运行：

```bash
bash /Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive/.auto_sync/install.sh
```

### 3. 首次同步

安装过程中会：
- 检查 fswatch 是否安装
- 配置 Git 仓库
- 执行首次同步到 GitHub

## 日常使用

1. **添加新音频**：
   - 把音频放到 `~/Desktop/微信音频整理/audio` 文件夹
   - 双击运行 `~/Desktop/微信音频整理/processor/双击运行.command`

2. **自动同步**：
   - 脚本会自动检测 `wechat-audio-archive` 目录的变动
   - 3 秒无新变动后自动提交推送到 GitHub
   - 约 1-2 分钟后 GitHub Pages 自动更新

3. **查看同步日志**：
   ```bash
   cat /Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive/.auto_sync/sync.log
   ```

## GitHub Pages 网址

```
https://a69998388-bit.github.io/wechat-adiou
```

（如果不行，可能需要先在 GitHub 仓库设置中启用 GitHub Pages）

## 常见问题

### Q: 如何停止自动同步？
```bash
kill $(cat /Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive/.auto_sync/monitor.pid)
```

### Q: 如何重新启动？
```bash
cd /Users/vv/.minimax-agent-cn/projects/2/wechat-audio-archive/.auto_sync
nohup bash monitor.sh > /dev/null 2>&1 &
echo $! > monitor.pid
```

### Q: 为什么 GitHub Pages 没更新？
- 等待 1-2 分钟
- 尝试强制刷新浏览器缓存 (Cmd+Shift+R)
- 检查 GitHub 仓库的 Actions 是否在构建

## 文件结构

```
wechat-audio-archive/
├── .auto_sync/
│   ├── git_sync.sh       # Git 同步脚本
│   ├── monitor.sh        # 文件监控脚本
│   ├── install.sh        # 安装脚本
│   ├── sync.log         # 同步日志
│   └── monitor.pid      # 进程 PID
├── audio/               # 音频文件
├── data/
│   └── playlist.json    # 播放列表
└── index.html           # 播放器
```
