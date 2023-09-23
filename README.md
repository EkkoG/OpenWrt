自用 OpenWrt 固件，以减少新系统启动时必须的初始化配置为目标，达到开机无需配置即可使用

## 特色

- 采用官方原版 [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) 构建而非从源码构建，几分钟即可构建完成
- 集成 OpenClash，构建固件时只需要提供 clash 配置链接即可在刷机完成后，直接启动 OpenClash
- 可配置默认 LAN 口 IP，PPPoE 账号密码，推荐的 IPv6 配置，刷机完成后，不用配置网络
- 可按照官方推荐的 uci 功能进行自定义，无需代码修改，您可以通过 uci 进行几乎任何自定义

## 依赖

- Docker
- docker-compose v1 or v2
## 使用

本项目通过改变使用不同的 ImageBuilder 镜像，来构建不同的固件，镜像名可以从 [Docker Hub](https://hub.docker.com/r/openwrtorg/imagebuilder/tags) 上查看
ImmortalWrt 的镜像名字可以从 [Docker Hub](https://hub.docker.com/r/immortalwrt/imagebuilder/tags) 查看

```bash
git clone https://github.com/ekkog/OpenWrt.git
cd OpenWrt
新建 .env 文件，配置 PPPOE 等相关变量
./run.sh --image=openwrtorg/imagebuilder:mvebu-cortexa9-22.03.3 --profile=linksys_wrt3200acm
```

## 更多

请查看 [Wiki](https://github.com/EkkoG/OpenWrt/wiki)

## 致谢
感谢以下项目，使得我的上网体验又有所提升

- [OpenWrt](https://openwrt.org/)
- [ImmortalWrt](http://immortalwrt.org/)
- [clash](https://github.com/Dreamacro/clash)
- [OpenClash](https://github.com/vernesong/OpenClash)
- [Clash.Meta](https://github.com/MetaCubeX/Clash.Meta)
