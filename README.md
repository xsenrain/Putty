# PuTTY 0.85 源码

> PuTTY 0.85 官方源码的个人镜像与二次开发底座。
>
> **本仓库不是 PuTTY 官方仓库**，仅用于源码阅读、学习与二次开发。上游项目由 Simon Tatham 维护，请以官方发布为准。
>
> 二次开发过程与决策记录见 **[DEVLOG.md](DEVLOG.md)**。

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

## 从源码构建

PuTTY 使用 **CMake** 构建，支持 Linux、Windows、macOS。

### 通用步骤

```bash
cmake .
cmake --build .
```

### Windows（MSVC）

先加载 MSVC 环境（让 `cl.exe` 出现在 PATH 中），例如在 “x64 Native Tools Command Prompt” 中执行：

```bat
vcvars64.bat
cmake .
cmake --build . --config Release
```

### Linux / macOS

```bash
cmake .
cmake --build .
sudo cmake --build . --target install   # 可选：安装
```

> 在 Unix 上，若希望 `pterm` 能记录登录信息（写入 `/var/run/utmp`、`/var/log/wtmp`），需要手动为其设置 setuid/setgid 权限，CMake 安装步骤不会自动处理。

### 构建文档（可选）

文档由 `doc/` 下的 Halibut（`.but`）源文件生成，需要先安装 [Halibut](https://www.chiark.greenend.org.uk/~sgtatham/halibut/)：

```bash
cmake --build . --target doc
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
