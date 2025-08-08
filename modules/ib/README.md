# ImageBuilder Configuration

## 概述

此模块用于配置OpenWrt ImageBuilder的构建参数和镜像源设置，优化镜像构建过程。

## 功能

- 应用环境变量中的CONFIG_*配置项到.config文件
- 自动检测项目类型（OpenWrt或ImmortalWrt）
- 支持镜像源配置和镜像加速
- 优化构建性能和可靠性

## 主要特性

### 配置管理
- 读取所有以`CONFIG_`开头的环境变量
- 自动更新.config文件中的相应配置
- 支持动态配置调整

### 项目检测
- 自动识别当前构建项目类型
- 支持OpenWrt和ImmortalWrt
- 根据项目类型调整配置

### 镜像源支持
- 支持自定义镜像源配置
- 通过`USE_MIRROR`和`MIRROR`环境变量控制
- 提高下载速度和构建稳定性

## 环境变量

### 必要变量
- `CONFIG_*` - 各种构建配置项
- `USE_MIRROR` - 是否使用镜像源（0/1）
- `MIRROR` - 镜像源地址

## 配置文件

- `post-files.sh` - 配置处理脚本

## 使用场景

适用于需要自动化构建OpenWrt镜像的场景：
- CI/CD构建流水线
- 批量镜像生成
- 自定义镜像构建
- 构建环境优化