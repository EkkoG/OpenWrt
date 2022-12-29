自用 OpenWrt x86_64/R2S/R4S 固件，以减少新系统启动时必须的初始化配置为目标，达到开机无需配置即可使用

## 特色

- 采用官方原版 [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) 构建而非从源码构建，几分钟即可构建完成
- 集成 OpenClash，构建固件时只需要提供 clash 配置链接即可在刷机完成后，直接启动 OpenClash
- 可配置默认 LAN 口 IP，PPPoE 账号密码，刷机完成后，不用配置网络
- 可按照官方推荐的 uci 功能进行自定义，无需代码修改，您可以通过 uci 进行几乎任何自定义

## 使用

```bash
git clone https://github.com/ekkog/OpenWrt.git
cd OpenWrt
新建 .env 文件，配置 PPPOE 等相关变量
./run.sh amd64_21|amd64_22|rockchip_r2s_21|rockchip_r2s_22|rockchip_r4s_21|rockchip_r4s_22|immortalwrt_amd_21|immortalwrt_rockchip_r2s_21|immortalwrt_rockchip_r4s_21
```

### 必须配置的环境变量

```bash
PPPOE_USERNAME=
PPPOE_PASSWORD=
LAN_IP=
CLASH_CONFIG_URL=
```

### 版本支持情况

|  设备   | 21.02  | 22.03 |
|  ----  | ----  | ---- |
| x86_64  | ✅ | ✅ |
| R2S | ✅ | ✅ |
| R4S | ✅ | ✅ |

另外支持了 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 21.02

### 内置软件列表

- <https://github.com/vernesong/OpenClash>
- <https://github.com/jerrykuku/luci-theme-argon>


## 自定义

### 添加 SSH key

在根目录创建文件夹 `ssh`，并将公钥录入到 `ssh/authorized_keys` 即可

### UCI 自定义

将 uci 命令录入 `uci/other.sh` 即可
注意：由于本项目也是使用 uci 命令来进行自定义，所以在录入时建议看一下内置的命令是否会冲突，内置的命令在 uci 文件夹的 common.sh 和 network.sh 两个文件中

感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)
