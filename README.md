自定义 OpenWrt 固件，以减少新系统启动时必须的初始化配置为目标，尽可能达到开机无需配置即可使用

## 特色

- 采用官方原版 [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) 构建而，几分钟即可构建完成
- 集成常用代理软件及其最佳实践配置，包括 [openclsh](https://github.com/vernesong/OpenClash), [daed](https://github.com/daeuniverse/daed), [passwall](https://github.com/xiaorouji/openwrt-passwall)
- 可配置默认 LAN 口 IP，PPPoE 账号密码，推荐的 IPv6 配置，刷机完成后，无需配置网络
- 模块化配置，详见 [modules](https://github.com/EkkoG/OpenWrt#modules-%E4%BB%8B%E7%BB%8D)

## modules 介绍

本项目所有的特性均通过 modules 进行配置，您可以根据自己的需求，自由选择需要的模块，或者自行添加新的模块

每个 module 都是一个目录，目录名即为 module 名，目录下包含以下文件

```bash
packages #定义本 module 依赖的软件包
files/ #定义本 module 需要的文件，按照 [OpenWrt 的 files](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files) 规范，放置到对应的目录下，最后会将所有 module 的 files 合并到一个目录下
post-files.sh #定义本 module 的预处理脚本，会在将当前 module 的 files 合并到最终目录后执行
.env #定义本 module 的环境变量，会将其中的变量的值替换到 files/uci-defaults/ 目录下的文件中
```

您可以通过在项目根目录下的 .env 中定义 MODULES 变量，来选择需要的 module，例如

```bash
MODULES="python -tools"
```

以减号开头的 module 会被排除，上面的例子中，会增加 python module，并排除 tools module

内置 modules https://github.com/EkkoG/OpenWrt/tree/master/modules
默认使用的 modules 参见 https://github.com/EkkoG/OpenWrt/blob/master/build.sh


## 依赖

- [Docker Compose](https://docs.docker.com/compose/install/)

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
- [dae](https://github.com/daeuniverse/dae)
