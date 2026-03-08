#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
微信音频归档处理器
功能：扫描指定文件夹中的音频文件，按创建时间排序，生成播放列表 JSON
"""

import os
import json
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import List, Dict, Optional

# 支持的音频格式
SUPPORTED_FORMATS = {'.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg'}


class AudioProcessor:
    """音频文件处理器"""
    
    def __init__(self, source_dir: str, output_dir: str):
        """
        初始化处理器
        
        Args:
            source_dir: 源文件夹路径（存放导出的微信音频）
            output_dir: 输出文件夹路径（存放整理后的音频）
        """
        self.source_dir = Path(source_dir)
        self.output_dir = Path(output_dir)
        self.audio_dir = self.output_dir / 'audio'
        self.data_dir = self.output_dir / 'data'
        
    def get_file_creation_time(self, file_path: Path) -> datetime:
        """
        获取文件创建时间
        
        Args:
            file_path: 文件路径
            
        Returns:
            创建时间（datetime 对象）
        """
        # Mac 平台获取文件创建时间
        stat_info = os.stat(file_path)
        try:
            # macOS 使用 st_birthtime = stat_info.st
            timestamp_birthtime
        except AttributeError:
            # 如果不支持，使用修改时间
            timestamp = stat_info.st_mtime
        
        return datetime.fromtimestamp(timestamp)
    
    def get_audio_duration(self, file_path: Path) -> Optional[int]:
        """
        获取音频时长（秒）
        
        Args:
            file_path: 音频文件路径
            
        Returns:
            时长（秒），失败返回 None
        """
        try:
            # 使用 ffprobe 获取音频时长
            result = subprocess.run(
                ['ffprobe', '-v', 'error', '-show_entries', 
                 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1',
                 str(file_path)],
                capture_output=True,
                text=True,
                timeout=10
            )
            if result.returncode == 0:
                duration = float(result.stdout.strip())
                return int(duration)
        except Exception as e:
            print(f"获取时长失败: {e}")
        return None
    
    def extract_sender_from_filename(self, filename: str) -> str:
        """
        从文件名中提取发送者名称
        
        Args:
            filename: 原始文件名
            
        Returns:
            发送者名称
        """
        # 移除扩展名
        name = Path(filename).stem
        
        # 尝试识别常见模式
        # 例如："微信语音_20231027_143005.mp3" 或 "群聊分享_张三.mp3"
        
        # 移除常见前缀
        prefixes = ['微信语音', '微信音频', '语音', 'audio', 'voice']
        for prefix in prefixes:
            if name.startswith(prefix):
                name = name[len(prefix):].strip('_')
        
        # 如果仍然有内容，作为发送者名称
        if name and len(name) > 0:
            return name[:20]  # 限制长度
        
        return '未知发送者'
    
    def process_files(self) -> List[Dict]:
        """
        处理所有音频文件
        
        Returns:
            音频信息列表
        """
        # 确保输出目录存在
        self.audio_dir.mkdir(parents=True, exist_ok=True)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        
        # 扫描源文件夹
        audio_files = []
        for file_path in self.source_dir.rglob('*'):
            if file_path.is_file() and file_path.suffix.lower() in SUPPORTED_FORMATS:
                audio_files.append(file_path)
        
        print(f"找到 {len(audio_files)} 个音频文件")
        
        # 处理每个文件
        playlist = []
        for idx, file_path in enumerate(audio_files, 1):
            try:
                # 获取创建时间
                created_time = self.get_file_creation_time(file_path)
                
                # 提取发送者
                sender = self.extract_sender_from_filename(file_path.name)
                
                # 生成新文件名：时间戳_序号.mp3
                timestamp_str = created_time.strftime('%Y%m%d_%H%M%S')
                new_filename = f"{timestamp_str}_{idx:03d}{file_path.suffix}"
                new_path = self.audio_dir / new_filename
                
                # 复制文件
                shutil.copy2(file_path, new_path)
                
                # 获取时长
                duration = self.get_audio_duration(new_path)
                
                # 构建条目
                entry = {
                    'id': f'audio_{idx:03d}',
                    'filename': new_filename,
                    'url': f'./audio/{new_filename}',
                    'sender': sender,
                    'timestamp': int(created_time.timestamp()),
                    'date_display': created_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'duration': duration,
                    'original_name': file_path.name
                }
                
                playlist.append(entry)
                print(f"处理: {file_path.name} -> {new_filename}")
                
            except Exception as e:
                print(f"处理失败 {file_path.name}: {e}")
        
        # 按时间排序
        playlist.sort(key=lambda x: x['timestamp'])
        
        # 重新编号
        for idx, entry in enumerate(playlist, 1):
            entry['id'] = f'audio_{idx:03d}'
        
        return playlist
    
    def save_playlist(self, playlist: List[Dict], group_name: str = '默认群聊'):
        """
        保存播放列表到 JSON 文件
        
        Args:
            playlist: 音频信息列表
            group_name: 群聊名称
        """
        output_data = {
            'group_name': group_name,
            'total_count': len(playlist),
            'created_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'playlist': playlist
        }
        
        output_file = self.data_dir / 'playlist.json'
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2)
        
        print(f"\n播放列表已保存到: {output_file}")
        print(f"共 {len(playlist)} 个音频文件")


def main():
    """主函数"""
    import sys
    
    # 默认路径
    source_dir = input("请输入源文件夹路径（微信导出的音频所在文件夹）: ").strip()
    output_dir = input("请输入输出文件夹路径（整理后的文件存放位置）: ").strip()
    group_name = input("请输入群聊名称（用于显示）: ").strip() or "微信群音频"
    
    # 如果直接回车，使用默认示例
    if not source_dir:
        source_dir = './sample_audio'
    if not output_dir:
        output_dir = './output'
    
    # 如果源目录不存在，创建示例
    if not os.path.exists(source_dir):
        print(f"\n源文件夹不存在: {source_dir}")
        print("将创建示例数据用于演示...")
        os.makedirs(source_dir, exist_ok=True)
        # 注意：实际使用时，请将微信导出的音频放入源文件夹
        print(f"请将音频文件放入: {os.path.abspath(source_dir)}")
        print("然后重新运行脚本")
        return
    
    # 处理
    processor = AudioProcessor(source_dir, output_dir)
    playlist = processor.process_files()
    
    if playlist:
        processor.save_playlist(playlist, group_name)
        print("\n✅ 处理完成！")
        print(f"输出目录: {os.path.abspath(output_dir)}")
        print("\n下一步：")
        print(f"1. 将 {output_dir}/data/playlist.json 复制到网页的 data 文件夹")
        print(f"2. 将 {output_dir}/audio/ 文件夹的内容复制到网页的 audio 文件夹")
        print("3. 打开网页播放器即可")
    else:
        print("\n❌ 未找到音频文件")


if __name__ == '__main__':
    main()
