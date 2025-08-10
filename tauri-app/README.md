# OpenWrt Builder

一个用于便捷构建定制化 OpenWrt 固件的跨平台桌面应用。技术栈：Tauri 2 · Vue 3 · TypeScript · Vuetify · Vite。

- **目标**: 以图形界面封装 OpenWrt/ImmortalWrt ImageBuilder 的常见操作，降低固件定制门槛。
- **平台**: macOS（已支持） / Windows（适配中） / Linux（适配中）（Tauri 原生打包支持）。

## 功能特性

- **镜像源选择**: 一键切换 `openwrt/imagebuilder` 与 `immortalwrt/imagebuilder` 等仓库
- **目标平台/版本**: 预置 `rockchip-armv8`、`x86-64` 等常见目标与版本
- **模块/软件包管理**: 可视化勾选常用模块与组件
- **配置预设**: 多套构建配置的保存与切换
- **构建输出目录**: 默认 ` /tmp/openwrt-output`（可在应用内修改）
- **一键构建**: 集成日志输出与进度反馈

> 实际可用项以应用界面为准；功能会随版本演进而更新。

## 目录结构

```
tauri-app/
├─ src/                     # 前端 (Vue 3 + Vuetify)
│  ├─ views/                # 页面视图（构建、模块、设置…）
│  ├─ components/           # 组件
│  ├─ stores/               # Pinia 状态管理
│  ├─ router/               # 路由
│  └─ main.ts               # 入口
├─ src-tauri/               # 后端 (Rust + Tauri 2)
│  ├─ src/                  # Rust 源码
│  ├─ tauri.conf.json       # Tauri 配置
│  └─ Cargo.toml            # Rust 包配置
├─ vite.config.ts           # Vite 配置（开发端口固定 1420）
├─ package.json             # 脚本与依赖
└─ README.md
```

## 环境要求

- **Docker**: 必需。GUI 构建流程依赖 CLI（Docker）执行实际构建
- **Node.js**: 18+（LTS）
- **pnpm**: 8+（本项目统一使用 pnpm）
- **Rust**: 稳定版（通过 `rustup` 安装）
- **平台依赖**: 参考 Tauri 官方先决条件
  - macOS: Xcode Command Line Tools
  - Windows: Visual Studio（含 C++ 桌面开发工作负载）
  - Linux: 常见 GTK/WebKit 等依赖

更多详情参考 Tauri 2 官方文档先决条件：`https://v2.tauri.app/start/prerequisites/`

## 快速开始

1) 安装依赖（在 `tauri-app/` 目录内）

```bash
# 确保已安装 pnpm
npm i -g pnpm

cd tauri-app
pnpm install
```

2) 启动开发

- 仅前端（浏览器预览）

```bash
pnpm dev
```

- 桌面应用（Tauri 调试）

```bash
pnpm tauri dev
```

说明：`src-tauri/tauri.conf.json` 中已配置 `beforeDevCommand: pnpm dev`、`devUrl: http://localhost:1420`，运行 `pnpm tauri dev` 会自动启动前端并打开桌面壳。

3) 生产构建 / 打包

- 构建前端静态资源

```bash
pnpm build
```

- 打包桌面应用（生成安装包/可执行文件）

```bash
pnpm tauri build
```

打包产物通常位于 `src-tauri/target/release`（或对应平台目录）。

## 打包资源说明

`src-tauri/tauri.conf.json` 在打包阶段会将以下资源一并包含（相对于 `src-tauri/` 路径）：

- `../../build.sh`
- `../../run.sh`
- `../../setup`
- `../../modules`

请确保上述文件/目录在仓库根目录存在，否则打包可能失败。

## 常见问题（FAQ）

- **提示未安装/未运行 Docker**: GUI 需要 Docker 进行构建，请安装并启动 Docker Desktop（macOS/Windows）或 Docker Engine（Linux）。
- **提示未找到 pnpm**: 先执行 `npm i -g pnpm`；如改用 npm/yarn，请同步更新 Tauri 配置中的命令。
- **提示未安装 Rust 工具链**: 按照 `rustup` 指引安装稳定版 Rust，并重新打开终端以刷新环境变量。
- **Windows 构建失败**: 确保安装了 Visual Studio 的 C++ 桌面开发组件，并使用 x64 Native Tools 命令行。
- **Linux 构建缺依赖**: 根据 Tauri 文档安装所需系统库（GTK/WebKit 等）。

## 可用脚本

- `pnpm dev`: 启动 Vite 开发服务器（端口 1420，严格占用）
- `pnpm build`: 类型检查并构建前端（输出至 `dist/`）
- `pnpm preview`: 预览已构建的前端产物
- `pnpm tauri dev`: 启动 Tauri 桌面调试（会执行 `pnpm dev`）
- `pnpm tauri build`: 打包生成桌面应用

## 贡献

欢迎提交 Issue 与 Pull Request。提交前请：
- 保持代码风格一致、命名清晰
- 确保 `pnpm build` 通过（如有测试请保持通过）

## 许可证

本项目遵循 **MIT License**。详见仓库根目录的 `LICENSE` 文件。
