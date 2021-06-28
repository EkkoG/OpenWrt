### 介绍

自用 OpenWrt x86_64/R2S/WNDR4300 镜像

### 项目目标

尽量减少新系统启动时必须的配置如 DNS, Clash 配置文件等，只需要提供必须的配置信息以构建固件，达到开机即可用！同时，恢复出厂后也几乎不用修改配置

### 特色

- 采用官方原版 ImageBuilder 构建，可按照官方提供的方式进行自定义，无代码修改，版本支持见 [版本支持情况](#版本支持情况)
- 集成常用软件，软件列表见 [软件列表](软件列表)
- 默认使用 Clash+Overture组合，两个组件间的联动配置已配置好，构建固件时只需要提供 clash 配置链接即可在刷机完成后，直接启动 OpenClash
- 可配置默认 LAN 口 IP，PPPoE 账号密码，刷机完成后，不用配置网络
- 可以自定义，根据 [UCI](https://openwrt.org/docs/guide-user/base-system/uci) 语法，可以自定义几乎所有配置，只需要将 uci 命令录入 `diy_files/diy.sh` 即可，diy.sh 也可以酌情删减，**删除时请务必清楚删除的配置的作用！！！**

#### 版本支持情况

|  设备   | 19.07  | 21.02 |
|  ----  | ----  | ---- |
| x86_64  | ✅ | ✅ |
| R2S | ❌ | ✅ |
| WNDR4300 | ✅ | ❌ |

#### 软件列表

- https://github.com/jerrykuku/luci-app-jd-dailybonus
- https://github.com/frainzy1477/luci-app-clash
- https://github.com/EXSERENS/overture-openwrt
- https://github.com/jerrykuku/luci-theme-argon

### 使用

- git clone https://github.com/cielpy/OpenWrt.git
- cd OpenWrt
- 新建 .env 文件，配置环境变量，请参考 [支持配置的环境变量](支持配置的环境变量)
- 修改 diy_files/diy.sh（非必须，修改须谨慎）
- ./run.sh rockchip_21/amd64_21/amd64_19


### 支持配置的环境变量

```bash
CUSTOM_PPPOE_PASSWORD=
CUSTOM_PPPOE_USERNAME=
CUSTOM_LAN_IP=
CUSTOM_CLASH_CONFIG_URL=
CUSTOM_PASSWALL_SUBSCRIBE_URL=
WAN_TYPE=
FLAG=
```

感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [China-DNS](https://github.com/aa65535/openwrt-chinadns)
- [Overture](https://github.com/shawn1m/overture)
- [overture for OpenWrt](https://github.com/EXSERENS/overture-openwrt)
