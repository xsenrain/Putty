# PuTTY 0.85 源码

> PuTTY 0.85 官方源码的个人镜像与二次开发底座。
>
> **本仓库不是 PuTTY 官方仓库**，仅用于源码阅读、学习与二次开发。上游项目由 Simon Tatham 维护，请以官方发布为准。
>
> 二次开发过程与决策记录见 **[DEVLOG.md](DEVLOG.md)**。

---

## 文档导航

**首次接触本仓库，请按此顺序阅读：**

| 文档 | 内容 | 什么时候看 |
|------|------|-----------|
| [AGENTS.md](AGENTS.md) | 智能体/协作者入职须知：项目现状、目录地图、**提交规范**、禁止事项 | **动手改代码前必读** |
| [BUILD.md](BUILD.md) | 编译指南：Windows / Linux / macOS 构建步骤、CMake 选项、排错表 | 要把代码编出来时 |
| [PITFALLS.md](PITFALLS.md) | 误点避坑清单：16 条已知坑 + 待观察项 | **动手前扫一遍**，省几小时 |
| [DEVLOG.md](DEVLOG.md) | 二次开发日志：每次改动的时间线、提交 hash、遗留问题 | 想知道「现在到哪一步了」 |

> 核心约定：**一次任务 = 一次 commit = 一次推送**；踩到新坑必须录入 `PITFALLS.md`。

---

## 项目简介

PuTTY 是一款免费、开源的 SSH / Telnet 客户端，最初由 Simon Tatham 为 Windows 平台开发，现已成为跨平台的经典实现。项目采用 **C 语言**编写，自 1997 年持续维护至今，经过长期的安全审计与生产环境验证，是学习 SSH 协议实现与终端仿真的优秀范本。

本仓库收录 **PuTTY 0.85** 完整源码（722 个文件，约 13 MB）。

| 项目 | 信息 |
|------|------|
| 版本 | **0.85**（见 `LATEST.VER`） |
| 语言 | C（450 个 `.c` / 89 个 `.h`） |
| 许可证 | MIT（见 `LICENCE`） |
| 构建系统 | CMake |
| 上游地址 | <https://git.tartarus.org/simon/putty.git> |
| 官方网站 | <https://www.chiark.greenend.org.uk/~sgtatham/putty/> |
| 官方文档 | <https://the.earth.li/~sgtatham/putty/latest/htmldoc/> |

---

## 包含的组件

| 组件 | 说明 |
|------|------|
| `putty` | SSH / Telnet / Serial 图形客户端（Windows） |
| `puttytel` | 仅含 Telnet 的精简客户端 |
| `pterm` | Unix 下的 PuTTY 风格终端包装器 |
| `pscp` | SCP 客户端（命令行安全文件复制） |
| `psftp` | SFTP 客户端（交互式文件传输） |
| `plink` | PuTTY 后端的命令行接口（常用于自动化、Git over SSH） |
| `pageant` | SSH 认证代理 |
| `puttygen` | 密钥生成与管理工具（RSA / DSA / ECDSA / EdDSA） |
| `psocks` | SOCKS 代理工具 |

---

## 目录结构

### 顶层核心模块

| 文件 / 目录 | 职责 |
|-------------|------|
| `putty.h` / `defs.h` | 全局定义与核心数据结构 |
| `config.c` | 配置项定义与序列化（会话配置的中枢） |
| `dialog.c` / `dialog.h` | 通用配置对话框框架 |
| `settings.c` | 配置读写（注册表 / 配置文件 / 命令行） |
| `cmdline.c` | 命令行参数解析 |
| `terminal/` | 终端仿真引擎（VT100/xterm、字符集、回滚缓冲、选择与剪贴板） |
| `ssh/` | SSH 协议实现（协议层 bpp、密钥交换、认证、通道、GSSAPI） |
| `proxy/` | 代理与跳板支持（HTTP / SOCKS / ProxyCommand） |
| `crypto/` | 加密算法（AES、ChaCha20-Poly1305、SHA、HMAC、Ed25519、ECDSA 等） |
| `keygen/` | 密钥生成流程（puttygen 后端） |
| `unicode/` | Unicode 与字符集转换辅助 |
| `charset/` | 字符编码转换表 |
| `otherbackends/` | SSH 之外的协议后端（Telnet、Raw、Serial、Rlogin、SUPDUP） |
| `utils/` | 通用工具（内存池、字符串、二叉树、时间、日志等） |
| `windows/` | Windows 平台层（Win32 GUI、控制台、安装包、Pageant 集成） |
| `unix/` | Unix 平台层（GTK GUI、pterm、Unix 信号与终端处理） |
| `doc/` | 文档源码（Halibut `.but` 格式，可生成 HTML / CHM / man） |
| `cmake/` | CMake 构建辅助脚本 |
| `test/` | 测试代码与测试数据 |
| `contrib/` | 社区贡献的辅助脚本 |

### 二开常用切入点

| 需求 | 建议关注的模块 |
|------|----------------|
| 改界面 / 加配置项 | `windows/`（Win32 GUI）、`dialog.c`、`config.c` |
| 改终端行为（配色、回滚、按键） | `terminal/` |
| 换 / 加加密算法、KEX | `crypto/`、`ssh/kex*.c` |
| 加跳板机 / 代理逻辑 | `proxy/` |
| 加文件传输功能 | `psftp.c`、`pscp.c`、`ssh/` 中的 SFTP 子系统 |
| 做自动化命令行 | `plink`（后端复用 `cmdline.c` + `ssh/`） |

---

## 编译帮助

> 本节为速查版。完整说明（选项表、产物清单、排错对照表、实测记录）见 **[BUILD.md](BUILD.md)**。

### 前置条件

| 项 | 要求 |
|----|------|
| CMake | **≥ 3.7**（`CMakeLists.txt` 声明 `3.7...3.28`） |
| C 标准 | **C99** |
| 编译器 | Windows：MSVC 2019+ 或 MinGW-w64；Linux/macOS：gcc / clang |
| GTK | **可选**（仅 Unix GUI 需要；缺失时只构建命令行工具） |
| Halibut | 可选（仅生成文档需要） |

Windows 构建**无需任何外部第三方库**，加密与压缩均为自带实现。

### 快速开始

```bash
cmake -S . -B ../putty-build
cmake --build ../putty-build
```

推荐 **out-of-source** 构建（产物生成在源码目录之外），避免构建产物污染仓库。

### Windows（MSVC，推荐 Ninja）

在 **x64 Native Tools Command Prompt for VS** 中执行：

```bat
call vcvars64.bat
cmake -S . -B ..\putty-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ..\putty-build
```

产物：`..\putty-build\putty.exe`、`pscp.exe`、`psftp.exe`、`plink.exe`、`puttygen.exe`、`pageant.exe`

也可以直接用 VS 生成器，但**注意**：本机实测 `-G "Visual Studio 18 2026"` 会报 `No CMAKE_C_COMPILER could be found`（VS 18 工具集未注册给 CMake），此时请改用上面的 Ninja 方式，或换 `-G "Visual Studio 17 2022" -A x64`。

### Linux

```bash
# Debian / Ubuntu 依赖
sudo apt install build-essential cmake pkg-config libgtk-3-dev libx11-dev

cmake -S . -B ../putty-build -DCMAKE_BUILD_TYPE=Release
cmake --build ../putty-build -j$(nproc)
sudo cmake --build ../putty-build --target install   # 可选：安装
```

服务器无 GTK 时，加 `-DPUTTY_GTK_VERSION=NONE`，仅构建 `plink` / `pscp` / `psftp` 等命令行工具。

> Unix 上若希望 `pterm` 能记录登录信息（写入 `/var/run/utmp`、`/var/log/wtmp`），需手动设置 setuid/setgid 权限，CMake 安装步骤不会自动处理。

### macOS

```bash
xcode-select --install
brew install cmake pkg-config gtk+3

cmake -S . -B ../putty-build -DCMAKE_BUILD_TYPE=Release
cmake --build ../putty-build -j$(sysctl -n hw.ncpu)
```

### 常用 CMake 选项

| 选项 | 默认 | 说明 |
|------|------|------|
| `PUTTY_GTK_VERSION` | `ANY` | `ANY` / `3` / `2` / `1` / `NONE`，`NONE` 关闭 GTK GUI |
| `PUTTY_IPV6` | `ON` | IPv6 支持 |
| `PUTTY_DEBUG` | `OFF` | 调试构建 |
| `PUTTY_FUZZING` | `OFF` | fuzzing 目标 |
| `PUTTY_COVERAGE` | `OFF` | 覆盖率插桩 |
| `PUTTY_COMPRESS_SCROLLBACK` | `ON` | 回滚缓冲压缩 |

### 常见错误

| 报错 | 解法 |
|------|------|
| `No CMAKE_C_COMPILER could be found` | 改用 Ninja + `vcvars64.bat`，或换 VS 2022 生成器 |
| `Could NOT find PkgConfig` | 装 `pkg-config` |
| `gtk+-3.0 not found` | 装 `libgtk-3-dev`，或加 `-DPUTTY_GTK_VERSION=NONE` |
| `CMakeCache.txt` 出现在 `git status` | 你做了 in-source 构建，删掉并改用 `-B ../putty-build` |

### 构建文档（可选）

文档由 `doc/` 下的 Halibut（`.but`）源文件生成，需先安装 [Halibut](https://www.chiark.greenend.org.uk/~sgtatham/halibut/)：

```bash
cmake --build ../putty-build --target doc
```

---

## 参考文档

- **官方在线文档**：<https://the.earth.li/~sgtatham/putty/latest/htmldoc/>
- **官方文档打包下载**：`puttydoc.zip` / `puttydoc.txt`（<https://the.earth.li/~sgtatham/putty/latest/>）
- **源码内文档**：`doc/` 目录下的 `.but` 源文件，涵盖使用手册、配置说明、SSH 协议细节与常见问题

文档章节速览：

| 章节 | 内容 |
|------|------|
| Chapter 1–2 | 简介与入门（下载、首次连接） |
| Chapter 3 | 使用 PuTTY（会话、登录、终端操作） |
| Chapter 4 | 配置参考（全部选项详解） |
| Chapter 5–8 | PSCP / PSFTP / Plink / Pageant / PuTTYgen 使用 |
| Chapter 9–10 | 代理、跳板、端口转发等进阶用法 |
| Appendix A–I | 常见问题、命令行选项、许可证、反馈渠道等 |

---

## 许可证

PuTTY 采用 **MIT 许可证**，允许自由使用、修改、合并、发布、再许可和销售，只需在副本中保留版权声明与许可声明。

```
PuTTY is copyright 1997-2026 Simon Tatham.
```

完整条款见仓库根目录 [`LICENCE`](LICENCE) 文件。

---

## 说明与免责

- 本仓库为**个人维护的源码镜像**，用于学习与二次开发，与 PuTTY 官方项目无隶属关系。
- 同步上游请使用官方 Git 仓库：`git clone https://git.tartarus.org/simon/putty.git`。
- 安全相关的缺陷请反馈给上游项目；本仓库不提供官方支持。
- 二次开发时请遵守 MIT 许可证的署名要求，保留 `LICENCE` 与版权声明。
