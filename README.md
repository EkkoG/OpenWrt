### 介绍

自用 OpenWrt x86_64/R2S 镜像

### 项目目标

尽量减少新系统启动时必须的配置如 DNS, Clash 配置文件等，只需要提供必须的配置信息以构建固件，达到开机即可用！

### 特色

- 采用官方原版 ImageBuilder 构建，可按照官方提供的方式进行自定义，无代码修改，版本支持见 [版本支持情况](#版本支持情况)
- 集成常用软件
- 默认使用 Clash+Overture组合，两个组件间的联动配置已配置好，构建固件时只需要提供 clash 配置链接即可在刷机完成后，直接启动 OpenClash
- 可配置默认 LAN 口 IP，PPPoE 账号密码，刷机完成后，不用配置网络
- 支持自定义

#### 版本支持情况

|  设备   | 19.07  | 21.02 |
|  ----  | ----  | ---- |
| x86_64  | ✅ | ✅ |
| R2S | ❌ | ✅ |

#### 软件列表

- https://github.com/vernesong/OpenClash
- https://github.com/EXSERENS/overture-openwrt
- https://github.com/jerrykuku/luci-theme-argon

### 使用

- git clone https://github.com/ekkog/OpenWrt.git
- cd OpenWrt
- 新建 .env 文件，配置 PPPOE 等相关变量
- ./run.sh rockchip_21/amd64_21/amd64_19

### 自定义

#### 添加 SSH key

在 diy 文件夹下创建文件夹 `ssh`，并将公钥录入到 `ssh/authorized_keys` 即可

#### UCI 自定义

将需要 uci 命令录入 `diy/uci/other.sh` 即可，由于本项目也是使用 uci 命令来进行自定义，所以在录入时建议看一下内置的命令是否会冲突，内置的命令在 uci 文件夹的 common.sh 和 network.sh 两个文件中

### 支持配置的环境变量

```bash
PPPOE_PASSWORD=
PPPOE_USERNAME=
LAN_IP=
CLASH_CONFIG_URL=
PASSWALL_SUBSCRIBE_URL=
```

感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [China-DNS](https://github.com/aa65535/openwrt-chinadns)
- [Overture](https://github.com/shawn1m/overture)
- [overture for OpenWrt](https://github.com/EXSERENS/overture-openwrt)
