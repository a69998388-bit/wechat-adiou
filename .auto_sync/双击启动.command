#!/bin/bash
# 双击运行 - 启动自动同步服务

cd "$(dirname "$0")/.."
SCRIPT_DIR="$(pwd)/.auto_sync/install.sh"

bash "$SCRIPT_DIR"
