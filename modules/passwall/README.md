# PassWall

## 概述

此模块用于安装和配置PassWall代理服务，提供功能强大的科学上网解决方案和智能分流功能。

## 功能

- 安装PassWall及相关组件
- 添加专用软件源和GPG密钥
- 配置订阅源支持
- 智能路由和分流规则

## 环境变量配置

### 必要变量
- `PASSWALL_SUBSCRIBE_URL` - PassWall订阅地址

配置示例：
```bash
PASSWALL_SUBSCRIBE_URL=https://passwall.example.com/subscribe
```

## 软件源配置

### GPG密钥
- 密钥文件：`0abda65a492b4887`
- 用于验证软件包完整性和安全性

### 软件源
通过post-files.sh脚本添加：
- PassWall专用软件仓库
- 相关依赖包源

## 主要特性

### 代理协议支持
- 支持多种主流代理协议
- 灵活的节点管理
- 订阅源自动更新
- 节点自动测速

### 智能分流
- 基于域名的分流规则
- GeoIP地理位置分流
- 自定义规则支持
- 广告过滤功能

### 系统集成
- 透明代理模式
- DNS防污染
- IPv6支持
- 开机自启动

## 配置文件

- `example.env` - 环境变量配置示例
- `packages` - 软件包列表
- `post-files.sh` - 后处理脚本
- `files/etc/opkg/keys/0abda65a492b4887` - GPG验证密钥
- `files/etc/uci-defaults/90-passwall` - UCI默认配置

## 依赖关系

- 依赖：`add-feed-base` 模块
- 集成：系统防火墙和网络配置

## 使用场景

适用于需要网络代理的场景：
- 科学上网需求
- 网络加速优化
- 访问地理限制内容
- 企业网络代理
- 智能分流路由

## 注意事项

- 需要有效的订阅源配置
- 遵守当地法律法规
- 合理配置分流规则
- 定期更新订阅和规则