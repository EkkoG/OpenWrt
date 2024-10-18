# OpenWrt

一个可以简单自定义 OpenWrt 固件的工具

## 关于此项目

通常在官方下载的固件会缺少一些软件包，且在初次启动时需要配置拨号账号密码等，官方提供的 [Firmware Selector](https://firmware-selector.openwrt.org/)，不能添加自定义软件源，此项目就是为了解决这些问题，以减少新系统启动时必须的初始化配置为目的，达到开机无需配置即可使用

另外项目会将配置持久化，相比 Firmware Selector，无需每次生成固件都需要重新配置

- 基于 [ImageBuilder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder) 构建，几分钟即可构建完成
- 使用 [Docker](https://www.docker.com/) 运行 ImageBuilder，无需安装额外的软件和依赖

## 特性

- 集成常用代理软件及其最佳实践配置，如 OpenClash, daed, passwall
- 可配置默认 LAN 口 IP，PPPoE 账号密码，推荐的 IPv6 配置，刷机完成后，无需配置网络
- 模块化，更易维护

<!-- Prerequisites -->
## 准备

安装 Docker https://docs.docker.com/engine/install/

## 安装和配置

```bash
git clone https://github.com/ekkog/OpenWrt.git
cd OpenWrt
```

项目配置通过 .env 文件进行，您可以通过修改 .env 文件来配置项目

.env 中可以配置两类变量，一类是 ImageBuilder 的环境变量，一类是项目的环境变量

`CONFIG_` 开头的变量是 ImageBuilder 的环境变量，运行时会将这些变量传递给 ImageBuilder，您可以通过 ImageBuilder 的文档来了解这些变量的含义

`MODULES` 是项目的环境变量，用于配置项目使用的 modules，后面会详细介绍

## 使用

```bash
❯ ./run.sh --help                                                                           
--image: specify imagebuilder docker image, find it in https://hub.docker.com/r/openwrt/imagebuilder/tags or https://hub.docker.com/r/immortalwrt/imagebuilder/tags
--profile: specify profile
--with-pull: pull image before build
--rm-first: remove container before build
--use-mirror: use mirror
-h|--help: print this help
```

示例

```bash
./run.sh --image=immortalwrt/imagebuilder:rockchip-armv8-openwrt-23.05.1 --profile=friendlyarm_nanopi-r2s --rm-first --with-pull --use-mirror=1                                  
```

## modules

本项目所有的特性均通过 modules 进行配置，您可以根据自己的需求，自由选择需要的模块，或者自行添加新的模块

每个 module 都是一个目录，目录名即为 module 名，目录下包含以下文件

```bash
packages #一个文本文件，定义本 module 依赖的软件包, 空格分隔
files/ #定义本 module 需要的文件，按照 [OpenWrt 的 files](https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files) 规范，放置到对应的目录下，最后会将所有 module 的 files 合并到 files 目录下
post-files.sh #定义本 module 的预处理脚本，会在将当前 module 的 files 合并到最终目录后执行
.env #定义本 module 的环境变量，会将其中的变量的值替换到 files/uci-defaults/ 目录下的文件中
```

如果您想在项目根目录的 .env 中统一定义变量，以便在 module 中使用，可以在根目录的 .env 中设置 `USE_SYTEM_ENV=1`，这样在 module 中就可以使用系统环境变量了

您可以通过在项目根目录下的 .env 中定义 MODULES 变量，来选择需要的 module，例如

```bash
MODULES="python -tools"
```

以减号开头的 module 会被排除，上面的例子中，会增加 python module，并排除 tools module

内置 modules https://github.com/EkkoG/OpenWrt/tree/master/modules

默认使用的 modules 参见 https://github.com/EkkoG/OpenWrt/blob/master/build.sh

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
