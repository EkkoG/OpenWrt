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
### 可选环境变量

添加额外软件包
```bash
EXTRA_PKGS=natmap python3-light
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

OpenWrt 在首次启动时，会执行 `/etc/uci-defaults/` 目录下的所有脚本，因此您可以通过在该目录下添加脚本，来实现自定义功能。

自定义功能举例：

- 设置默认密码
- 添加信任 SSH 公钥
- 添加 uci 脚本，实现自定义功能


## 致谢
感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)
