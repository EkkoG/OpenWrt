# Reject Netflix IPv6

## 概述

此模块用于禁止Netflix相关域名解析IPv6地址，强制使用IPv4连接，解决IPv6网络环境下的访问问题。

## 功能

- 阻止Netflix域名的IPv6 DNS解析
- 强制使用IPv4连接Netflix服务
- 解决IPv6环境下的地理位置检测问题
- 提高Netflix访问稳定性

## 阻止的域名

- `netflix.com` - Netflix主域名
- `netflix.net` - Netflix网络域名  
- `nflxext.com` - Netflix扩展服务
- `nflximg.net` - Netflix图片服务
- `nflxvideo.net` - Netflix视频服务

## 实现原理

### DNS配置
- 使用dnsmasq配置文件阻止IPv6解析
- `server=/domain/#` - 禁止域名DNS查询
- `address=/domain/::` - 返回空IPv6地址

### 技术细节
- 不影响IPv4正常解析
- 只针对特定域名生效
- 保持其他服务IPv6功能
- 自动应用配置到系统

## 配置文件

- `files/etc/dnsmasq.d/netflix.conf` - dnsmasq配置文件
- `files/etc/uci-defaults/99-reject-netflix-ipv6` - UCI默认配置脚本

## 使用场景

适用于以下情况：
- IPv6环境下Netflix无法正常访问
- 地理位置检测错误
- 双栈网络环境优化
- 强制IPv4连接需求

## 注意事项

- 此配置会影响所有Netflix相关域名
- 仅阻止IPv6，不影响IPv4连接
- 可能需要清除浏览器DNS缓存
- 适用于需要稳定IPv4连接的场景