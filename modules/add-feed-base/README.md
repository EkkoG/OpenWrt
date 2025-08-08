# Add Feed Base

## 概述

此模块提供添加Ekko OpenWrt软件源的基础脚本功能，用于扩展OpenWrt的软件包仓库。

## 功能

- 添加Ekko自定义软件源到系统
- 支持不同架构的软件包仓库
- 支持LuCI界面扩展包
- 支持地理数据包（GeoData）
- 使用GitHub代理镜像加速下载

## 主要函数

### add_packages()
添加指定类型的软件包源，支持：
- 基础软件包（按架构区分）
- LuCI界面包

### add_geodata()
添加地理数据软件源，用于：
- GeoIP数据库
- GeoSite规则集

## 软件源配置

软件源基于SourceForge托管，通过GitHub代理镜像访问：
- 主源：`https://downloads.sourceforge.net/project/ekko-openwrt-dist/`
- 代理：`https://ghproxy.imciel.com/`

## 配置文件

- `base.sh` - 基础脚本函数库
- `files/etc/opkg/customfeeds.conf` - 自定义软件源配置
- `repositories.conf` - 仓库配置文件

## 使用方法

此模块作为其他模块的依赖，提供基础的软件源添加功能。