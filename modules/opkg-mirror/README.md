# OPKG Mirror Configuration

## 概述

此模块用于配置OpenWrt软件包管理器(opkg)使用国内镜像源，提高软件包下载速度和稳定性。

## 功能

- 替换默认软件源为国内镜像
- 提高软件包下载速度
- 增强网络连接稳定性
- 支持ImmortalWrt项目

## 镜像源配置

### 替换规则
- `https://downloads.immortalwrt.org` → `https://mirror.nju.edu.cn/immortalwrt`
- `https://mirrors.vsean.net/openwrt` → `https://mirror.nju.edu.cn/immortalwrt`

### 镜像源特点
- **南京大学镜像站** - 稳定可靠的教育网镜像
- 高速带宽支持
- 定期同步更新
- 全国访问友好

## 实现原理

1. 使用sed命令替换配置文件中的URL
2. 备份原始配置文件（.bak后缀）
3. 修改`/etc/opkg/distfeeds.conf`配置文件
4. 在系统首次启动时自动应用

## 配置文件

- `files/etc/uci-defaults/99-opkg` - 镜像源替换脚本

## 使用效果

- 大幅提升软件包下载速度
- 减少下载超时和失败
- 改善opkg update体验
- 适合中国大陆网络环境

## 注意事项

- 仅适用于ImmortalWrt项目
- 原始配置文件会自动备份
- 镜像同步可能存在轻微延迟
- 可根据需要修改为其他镜像源