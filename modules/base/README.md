# Base Packages

## 概述

此模块提供OpenWrt系统的基础软件包集合，包含Web管理界面、系统工具和必要的系统组件。

## 功能

- 安装基础系统组件和工具
- 配置LuCI Web管理界面
- 提供中文语言支持
- 根据OpenWrt版本动态调整包列表

## 包含的软件包

### 核心组件
- `zoneinfo-all` - 时区信息数据
- `luci` - LuCI Web管理界面
- `luci-compat` - LuCI兼容性支持
- `luci-lib-ipkg` - 软件包管理库
- `dnsmasq-full` - 功能完整的DNS/DHCP服务（替换精简版dnsmasq）
- `openssl-util` - OpenSSL实用工具

### 中文界面支持
- `luci-i18n-base-zh-cn` - 基础界面中文翻译
- `luci-i18n-firewall-zh-cn` - 防火墙界面中文翻译

### 版本相关包
- OpenWrt 24.10或快照版本：`luci-i18n-package-manager-zh-cn`
- 其他版本：`luci-i18n-opkg-zh-cn`

## 版本适配

模块会根据环境变量自动检测OpenWrt版本：
- `OPENWRT_VERSION` - OpenWrt版本号
- `IS_SNAPSHOT_BUILD` - 是否为快照构建

## 配置文件

- `packages` - 动态生成软件包列表的脚本

## 使用场景

作为所有OpenWrt系统的基础模块，提供完整的Web管理界面和基本系统功能。适用于需要图形化管理界面的OpenWrt部署。