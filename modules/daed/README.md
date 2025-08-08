# Daed Proxy

## 概述

此模块用于安装和配置Daed代理服务，提供高性能的网络代理解决方案，基于dae项目开发。

## 功能

- 安装Daed代理核心组件
- 配置LuCI Web管理界面
- 集成地理位置数据库
- 提供虚拟网络接口支持

## 包含的软件包

### 核心组件
- `daed-geoip` - GeoIP地理位置数据库
- `daed-geosite` - GeoSite站点分类数据库
- `luci-app-daed` - Daed的LuCI Web管理界面
- `kmod-veth` - 虚拟以太网接口内核模块

### 数据源配置
通过add-feed-base模块添加：
- `dae` - Daed软件包源
- `geodata/MetaCubeX` - MetaCubeX地理数据源

## 技术特点

- 基于eBPF技术的高性能代理
- 支持多种代理协议
- 内置智能路由规则
- 低延迟、高吞吐量
- 支持地理位置和域名分流

## 配置文件

- `packages` - 软件包列表
- `post-files.sh` - 后处理脚本，配置软件源和地理数据

## 依赖关系

- 依赖：`add-feed-base` 模块
- 推荐：配合其他网络配置模块使用

## 使用场景

适用于需要高性能网络代理的场景：
- 智能路由分流
- 网络加速优化
- 访问控制管理
- 流量监控分析