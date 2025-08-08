# OpenClash

## 概述

此模块用于安装和配置OpenClash代理服务，提供完整的Clash内核代理解决方案和Web管理界面。

## 功能

- 安装OpenClash及相关组件
- 配置订阅源和DNS服务器
- 启用IPv6和Meta内核支持
- 自动更新地理位置数据库
- 自定义Fallback过滤规则

## 包含的软件包

通过post-files.sh添加软件源，包含：
- OpenClash核心组件
- 相关依赖包
- 管理界面组件

## 环境变量配置

### 必要变量
- `CLASH_CONFIG_URL` - Clash配置文件订阅地址
- `DASHBOARD_PASSWORD` - 管理面板密码（可选，未设置将自动生成）

## 主要配置特性

### DNS配置
- 主DNS：119.29.29.29 (UDP)
- 备用DNS：8.8.8.8 (TCP)
- 支持IPv6 DNS解析
- 禁用默认DNS追加

### 核心设置
- 使用Clash Meta内核
- 运行模式：redir-host
- 启用IPv6支持和代理
- 启用中国IP路由优化

### 自动更新
- GeoIP数据库：每日4点更新
- GeoSite数据库：每日0点更新
- 中国路由：每日3点更新
- 配置文件：支持自动更新
- 系统重启：每日3点自动重启

### 高级功能
- 启用尊重规则
- 自定义Fallback过滤
- 禁用UDP QUIC协议
- 进程查找模式关闭

## 配置文件

- `example.env` - 环境变量配置示例
- `packages` - 软件包列表
- `post-files.sh` - 后处理脚本
- `files/etc/uci-defaults/90-openclash` - UCI默认配置
- `files/etc/openclash/custom/openclash_custom_fallback_filter.yaml` - 自定义过滤规则

## 依赖关系

- 依赖：`add-feed-base` 模块
- 推荐：配合其他网络模块使用

## 使用场景

适用于需要灵活代理配置的场景：
- 智能分流代理
- 全局网络加速
- 访问控制管理
- 多协议代理支持