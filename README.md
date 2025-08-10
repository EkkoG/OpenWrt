<div align="center">

# OpenWrt Builder

轻松定制您专属的 OpenWrt 固件

图形界面 + 命令行，让固件构建更简单高效

[![Release](https://img.shields.io/github/v/release/EkkoG/OpenWrt?include_prereleases&style=flat-square&label=alpha)](https://github.com/EkkoG/OpenWrt/releases/tag/alpha)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](LICENSE)
[![Stars](https://img.shields.io/github/stars/EkkoG/OpenWrt?style=flat-square)](https://github.com/EkkoG/OpenWrt/stargazers)

</div>

---

## 特性一览

- **开箱即用**: 基于官方 ImageBuilder，几分钟生成固件
- **模块化**: 内置常用模块，支持自定义模块目录
- **一键构建**: 图形界面或脚本命令，实时日志与进度
- **容器化**: Docker 隔离构建环境，无需配置编译工具链
- **配置可复用**: 多套构建方案，环境变量集中管理

## 界面预览

<div align="center">
<table>
<tr>
<td><img src="./assets/screentshot1.png" width="420" alt="主界面" /></td>
<td><img src="./assets/screentshot2.png" width="420" alt="构建页面" /></td>
</tr>
</table>
</div>

---

## 下载与安装（GUI）

- 从发布页下载预编译安装包: [Releases](https://github.com/EkkoG/OpenWrt/releases)

| 平台 | 安装包格式 | 说明 |
|------|-----------|------|
| macOS | `.dmg` | Apple Silicon 选 `aarch64`，Intel 选 `x86_64` |
| Windows | （适配中） | 即将提供 `.msi` 安装包 |
| Linux | （适配中） | 即将提供 `.AppImage` 安装包 |

也可从源码构建：见文档后半部分“开发与构建”。

注意：使用 GUI 构建固件前，请先安装并启动 Docker。

---

## 快速使用指南

### 方式一：图形界面（推荐）

0) 安装并启动 Docker（必需）
1) 安装并打开应用（或从源码运行 GUI）
2) 选择镜像（OpenWrt/ImmortalWrt）与目标平台/版本
3) 在“模块”页面勾选需要的功能模块
4) 可选：设置输出目录、镜像加速等
5) 在“构建中心”一键构建，等待完成

提示：首次构建会下载较多资源，后续会显著加快。

### 方式二：命令行（进阶）

在仓库根目录使用 `run.sh`：

```bash
# 查看帮助
./run.sh --help

# 最小示例（以 ImmortalWrt Rockchip 为例）
./run.sh \
  --image=immortalwrt/imagebuilder:rockchip-armv8-openwrt-23.05.1 \
  --profile=friendlyarm_nanopi-r2s \
  --with-pull --rm-first --use-mirror
```

常用参数：

```
--image=...         指定 ImageBuilder 镜像（必需）
--profile=...       指定设备 Profile（可选）
--output=...        指定输出目录（默认：./bin）
--custom-modules=... 指定自定义模块目录（默认：./custom_modules）
--with-pull         构建前拉取镜像
--rm-first          构建前清理容器
--use-mirror        使用镜像加速（默认启用）
--mirror=...        指定镜像站域名，例如 mirrors.pku.edu.cn
```

环境变量（`.env`）示例：

```bash
# 在默认模块集基础上增减
MODULES="openclash lan pppoe -tools"

# 或完全覆盖默认模块集（更高优先级）
ENABLE_MODULES="argon base lan"

# 与模块共享环境变量
USE_SYSTEM_ENV=1

# 传递给 ImageBuilder 的常见参数
CONFIG_TARGET_KERNEL_PARTSIZE=32
CONFIG_TARGET_ROOTFS_PARTSIZE=256
```

输出目录默认为 `./bin`，可通过 `--output` 修改。

---

## 模块系统（简述）

- **默认模块集**: `add-all-device-to-lan argon base opkg-mirror prefer-ipv6-settings statistics system tools`
- 两种选择方式：
  - **ENABLE_MODULES**: 完全覆盖启用模块列表
  - **MODULES**: 在默认模块集基础上增减（前缀 `-` 表示排除）
- 模块目录：同时支持 `modules/`（内置）与 `custom_modules/`（自定义）
- 目录结构：

```
my-module/
├─ packages           # 依赖包（空格分隔或可执行脚本）
├─ files/             # 随固件打包进系统的文件
├─ post-files.sh      # 可选：files 拷贝后处理
├─ .env               # 可选：模块级变量
└─ README.md          # 可选：模块说明
```

高级特性：
- 环境变量共享：设置 `USE_SYSTEM_ENV=1` 后，模块可引用根 `.env` 中的变量
- 变量替换：`files/etc/uci-defaults` 下的文件支持 `$VARNAME` 替换
- 冲突保护：若不同模块生成同名目标文件，构建会失败以避免覆盖

---

## 常见问题（FAQ）

- 构建很慢/网速受限？建议启用 `--use-mirror` 或指定 `--mirror=mirrors.pku.edu.cn`
- 没有安装 Docker？请先安装 Docker Desktop（macOS/Windows）或 Docker Engine（Linux）
- 构建完成后产物在哪？默认在 `./bin`（可通过 `--output` 修改）
- GUI 构建失败/无响应？请确认 Docker 已安装并正在运行；从源码运行还需 Node.js 18+ 与 pnpm 8+，详见下文“开发与构建”

---

## 开发与构建

目录结构：

```
.
├─ build.sh                 # 容器内实际构建脚本（由 run.sh 调用）
├─ run.sh                   # 一键构建（Docker Compose 方式）
├─ modules/                 # 内置模块库
├─ custom_modules/          # 建议放置自定义模块
├─ setup/                   # 构建前置设置脚本
├─ tauri-app/               # GUI 应用（Tauri 2 + Vue 3）
└─ LICENSE                  # MIT 许可证
```

GUI 从源码运行与打包：

```bash
cd tauri-app
pnpm install

# 开发（Tauri 调试，固定端口 1420）
pnpm tauri dev

# 生产打包（生成桌面安装包）
pnpm tauri build
```

说明：打包会将仓库根的 `build.sh`、`run.sh`、`setup/`、`modules/` 作为资源一并包含。

---

## 贡献指南

- **Bug 报告**: [提交 Issue](https://github.com/EkkoG/OpenWrt/issues)
- **功能建议**: [功能请求](https://github.com/EkkoG/OpenWrt/issues/new)
- **代码贡献**: [提交 Pull Request](https://github.com/EkkoG/OpenWrt/pulls)
- **文档完善**: 完善 README 和 Wiki
- **模块分享**: 分享你的自定义模块

## 致谢

<div align="center">

### 核心依赖
[**OpenWrt**](https://openwrt.org/) • [**ImmortalWrt**](http://immortalwrt.org/) • [**Docker**](https://www.docker.com/)

### 网络工具
[**OpenClash**](https://github.com/vernesong/OpenClash) • [**dae**](https://github.com/daeuniverse/dae) • [**Passwall**](https://github.com/xiaorouji/openwrt-passwall)

### 技术框架
[**Tauri**](https://tauri.app/) • [**Vue.js**](https://vuejs.org/) • [**Vuetify**](https://vuetifyjs.com/)

</div>

## 许可证

本项目基于 MIT 协议发布，详见 `LICENSE`。

---

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=EkkoG/OpenWrt&type=Date)](https://star-history.com/#EkkoG/OpenWrt&Date)

</div>
