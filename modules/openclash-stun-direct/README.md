# OpenClash STUN Direct

## 概述

此模块为OpenClash提供STUN协议直连配置，确保STUN流量不经过代理直接连接，避免P2P连接问题。

## 功能

- 配置STUN协议端口3478的直连规则
- 支持TCP和UDP协议
- 兼容nftables和iptables防火墙
- 自动检测防火墙类型并应用相应规则

## STUN协议说明

STUN（Session Traversal Utilities for NAT）协议用于：
- NAT穿透和类型检测
- P2P连接建立
- WebRTC应用支持
- 实时通信优化

## 实现原理

### nftables规则（fw4）
- 在openclash表中添加TCP/UDP 3478端口的RETURN规则
- 在openclash_mangle表中添加相应规则
- 在openclash_output表中添加输出规则

### iptables规则（传统防火墙）
- 在mangle表的openclash链中添加RETURN规则
- 在nat表的openclash和openclash_output链中添加规则
- 确保STUN流量绕过代理处理

## 技术特性

- 自动检测防火墙类型（fw4/iptables）
- 支持双栈（IPv4/IPv6）网络环境
- 规则优先级最高（position 0或-I 1）
- 完整的日志记录支持

## 配置文件

- `files/etc/openclash/custom/openclash_custom_firewall_rules.sh` - 自定义防火墙规则脚本

## 使用场景

适用于需要P2P连接的应用：
- WebRTC视频通话
- 游戏P2P连接
- 点对点文件传输
- 实时音视频应用

## 注意事项

- 此模块需要OpenClash已安装并运行
- STUN流量将直接访问，不经过代理
- 适用于需要真实IP进行NAT检测的场景