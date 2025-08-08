# System Configuration

## 概述

此模块用于配置OpenWrt系统的基本设置，包括时区、语言和日志级别等系统参数。

## 功能

- 设置系统时区为中国时区
- 配置LuCI界面为中文
- 调整系统日志级别
- 优化系统本地化设置

## 系统配置

### 时区设置
- **时区名称**：`Asia/Shanghai`
- **时区偏移**：`CST-8`（东八区）
- 自动处理夏令时

### 语言设置
- **LuCI界面语言**：`zh_cn`（简体中文）
- 提供完整的中文界面体验

### 日志配置
- **Cron日志级别**：`8`（调试级别）
- **控制台日志级别**：`7`（信息级别）

## 配置详情

### 时区配置
```bash
set system.@system[0].zonename='Asia/Shanghai'
set system.@system[0].timezone='CST-8'
```

### 界面本地化
```bash
set luci.main.lang='zh_cn'
```

### 日志级别
```bash
set system.@system[0].cronloglevel='8'
set system.@system[0].conloglevel='7'
```

## 日志级别说明

- **级别8**：调试信息，详细记录所有操作
- **级别7**：信息级别，记录重要的系统事件
- 更高的数字表示更详细的日志

## 配置文件

- `files/etc/uci-defaults/91-system` - UCI系统配置脚本

## 使用效果

- 系统时间显示为北京时间
- Web管理界面显示中文
- 适合中国大陆用户使用
- 便于系统维护和故障排查

## 适用场景

适用于中文用户的OpenWrt部署：
- 家庭路由器配置
- 企业网络设备
- 学习和实验环境
- 本地化系统定制

## 注意事项

- 配置在系统首次启动时应用
- 重启后保持配置不变
- 可根据需要调整为其他时区
- 日志级别影响存储空间使用