# Add Feed

## 概述

此模块用于添加Ekko软件源到OpenWrt系统中，包括LuCI界面组件和基础软件包。

## 功能

- 添加LuCI主题和界面扩展包源
- 添加基础软件包源
- 依赖add-feed-base模块提供的基础功能

## 软件源类型

### LuCI软件源
提供LuCI Web界面的扩展组件，包括：
- 主题包
- 管理界面插件
- Web应用模块

### Packages软件源
提供基础软件包，按目标架构区分：
- 系统工具
- 网络应用
- 实用程序

## 实现方式

通过调用add-feed-base模块的函数：
- `add_packages("luci")` - 添加LuCI软件源
- `add_packages("packages")` - 添加基础软件包源

## 配置文件

- `post-files.sh` - 后处理脚本，调用基础模块功能

## 依赖关系

- 依赖：`add-feed-base` 模块
- 推荐：`add-feed-key` 模块（用于软件包验证）

## 使用场景

适用于需要扩展OpenWrt软件仓库的场景，为系统提供更多可安装的软件包选择。