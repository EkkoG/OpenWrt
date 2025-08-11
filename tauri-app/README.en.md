# OpenWrt Builder

English | [简体中文](README.md)

A cross‑platform desktop app to conveniently build customized OpenWrt firmware. Tech stack: Tauri 2 · Vue 3 · TypeScript · Vuetify · Vite.

- **Goal**: Wrap common OpenWrt/ImmortalWrt ImageBuilder actions with a GUI to lower the barrier for firmware customization.
- **Platforms**: macOS (supported) / Windows (in progress) / Linux (in progress) — packaging supported by Tauri natively.

## Features

- **Image source selection**: Switch between `openwrt/imagebuilder` and `immortalwrt/imagebuilder`
- **Target platform/version**: Presets for `rockchip-armv8`, `x86-64`, etc.
- **Module/package management**: Visual selection of common modules and components
- **Configuration presets**: Save and switch among multiple build configurations
- **Build output directory**: Default ` /tmp/openwrt-output` (changeable in app)
- **One‑click build**: Integrated logs and progress feedback

> The actual options depend on the app version; features evolve over time.

## Directory structure

```
tauri-app/
├─ src/                     # Frontend (Vue 3 + Vuetify)
│  ├─ views/                # Pages (Build, Modules, Settings…)
│  ├─ components/           # Components
│  ├─ stores/               # Pinia stores
│  ├─ router/               # Router
│  └─ main.ts               # Entry
├─ src-tauri/               # Backend (Rust + Tauri 2)
│  ├─ src/                  # Rust sources
│  ├─ tauri.conf.json       # Tauri config
│  └─ Cargo.toml            # Rust package config
├─ vite.config.ts           # Vite config (dev port fixed at 1420)
├─ package.json             # Scripts and dependencies
└─ README.md
```

## Requirements

- **Docker**: Required. The GUI orchestrates the CLI (Docker) to perform builds
- **Node.js**: 18+
- **pnpm**: 8+ (this project uses pnpm)
- **Rust**: stable (install via `rustup`)
- **Platform prerequisites**: per Tauri docs
  - macOS: Xcode Command Line Tools
  - Windows: Visual Studio with Desktop development with C++ workload
  - Linux: common GTK/WebKit dependencies

More details: Tauri 2 prerequisites `https://v2.tauri.app/start/prerequisites/`.

## Getting started

1) Install dependencies (inside `tauri-app/`)

```bash
# Ensure pnpm is installed
npm i -g pnpm

cd tauri-app
pnpm install
```

2) Start development

- Frontend only (browser preview)

```bash
pnpm dev
```

- Desktop app (Tauri dev)

```bash
pnpm tauri dev
```

Note: `src-tauri/tauri.conf.json` is configured with `beforeDevCommand: pnpm dev` and `devUrl: http://localhost:1420`, so `pnpm tauri dev` will start the frontend and open the desktop shell automatically.

3) Production build / packaging

- Build frontend static assets

```bash
pnpm build
```

- Package the desktop app (installer/executable)

```bash
pnpm tauri build
```

Artifacts are usually located under `src-tauri/target/release` (or platform‑specific subdirs).

## Packaged resources

During packaging, `src-tauri/tauri.conf.json` bundles these resources (relative to `src-tauri/`):

- `../../build.sh`
- `../../run.sh`
- `../../setup`
- `../../modules`

Ensure these paths exist at the repo root, otherwise packaging may fail.

## FAQ

- **Docker not installed/running**: The GUI requires Docker. Install and start Docker Desktop (macOS/Windows) or Docker Engine (Linux).
- **pnpm not found**: Run `npm i -g pnpm`. If you switch to npm/yarn, update Tauri config accordingly.
- **Rust toolchain missing**: Install stable Rust via `rustup`, then reopen the terminal to refresh env vars.
- **Windows build fails**: Ensure Visual Studio desktop C++ workload is installed and use x64 Native Tools terminal.
- **Linux missing deps**: Install required GTK/WebKit libs as per Tauri docs.

## Scripts

- `pnpm dev`: Start Vite dev server (port 1420, fixed)
- `pnpm build`: Type‑check and build frontend (outputs to `dist/`)
- `pnpm preview`: Preview built frontend
- `pnpm tauri dev`: Start Tauri desktop dev (runs `pnpm dev`)
- `pnpm tauri build`: Package desktop app

## Contributing

Issues and PRs are welcome. Before submitting:
- Keep code style consistent and naming clear
- Ensure `pnpm build` passes (and tests if present)

## License

MIT License. See `LICENSE` at the repo root.
