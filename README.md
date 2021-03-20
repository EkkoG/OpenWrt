### 介绍

自用 OpenWrt-x86_64 镜像

### 特色

- 采用官方原版 19.07.7 ImageBuilder 构建，可按照官方提供的方式进行自定义
- 集成 [OpenClash](https://github.com/vernesong/OpenClash), [China-DNS](https://github.com/aa65535/openwrt-chinadns), [SmartDNS](https://github.com/pymumu/smartdns/)
- 默认使用 OpenClash+SmartDNS 组合，两个组件间的联动配置已配置好，构建固件时只需要提供 clash 配置链接即可在刷机完成后，直接启动 OpenClash
- 可配置默认 LAN 口 IP，PPPoE 账号密码，刷机完成后，几乎不用任何配置即可使用
- 可以自定义，根据 [UCI](https://openwrt.org/docs/guide-user/base-system/uci) 语法，可以自定义几乎所有配置，只需要将 uci 命令录入 `system-custom.tpl` 即可，system-custom.tpl 也可以酌情删减，**删除时请务必清楚删除的配置的作用！！！**

感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)