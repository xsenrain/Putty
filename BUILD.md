# BUILD.md — 编译指南

> 本文档说明如何从源码构建 PuTTY 0.85。所有命令均已对照本仓库的 `CMakeLists.txt`、`cmake/*.cmake`、`windows/`、`unix/` 构建脚本核实。
>
> **诚实声明**：本仓库**尚未完成一次完整编译**（只完成了 CMake 配置阶段的验证，见文末「实测记录」）。文中标注 `✅ 已核实` 的是从构建脚本读出的确定事实；标注 `⚠️ 待验证` 的需要你实际跑一遍确认。

---

## 1. 前置条件

| 项 | 要求 | 依据 |
|----|------|------|
| CMake | **≥ 3.7**（`cmake_minimum_required(VERSION 3.7...3.28)`） | ✅ 已核实 |
| C 语言标准 | **C99**（`set(CMAKE_C_STANDARD 99)`） | ✅ 已核实 |
| 编译器 | Windows：MSVC 2019+ 或 MinGW-w64；Unix：gcc / clang | ✅ 已核实（脚本按平台分目录） |
| pkg-config | Linux/macOS 构建 GTK 界面时需要 | ✅ 已核实（`cmake/gtk.cmake` 用 `pkg_check_modules`） |
| GTK | **可选**，缺失时只构建命令行工具 | ✅ 已核实（`unix/CMakeLists.txt` 的 `if(GTK_FOUND)` 分支） |
| Halibut | 仅构建文档时需要 | ✅ 已核实（源码 `README`） |

> Windows 构建**不需要**任何外部第三方库（加密、压缩均为自带实现），这是 PuTTY 的一大优势。

---

## 2. 快速开始（三条命令）

```bash
cmake -S . -B ../putty-build
cmake --build ../putty-build
# 产物在 ../putty-build/ 下
```

**推荐 out-of-source 构建**（在源码目录之外生成构建产物），避免污染工作区、避免构建产物被误提交（见 `PITFALLS.md` P-014）。

---

## 3. Windows 构建

### 3.1 方式 A：Ninja + MSVC（推荐）

使用 **x64 Native Tools Command Prompt for VS**（开始菜单搜索即可），或用 `vcvars64.bat` 初始化环境：

```bat
call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
cmake -S . -B ..\putty-build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build ..\putty-build
```

产物：`..\putty-build\putty.exe`、`pscp.exe`、`psftp.exe`、`plink.exe`、`puttygen.exe`、`pageant.exe` ✅ 已核实目标名（见 `CMakeLists.txt`）

### 3.2 方式 B：Visual Studio 生成器

```bat
cmake -S . -B ..\putty-build -G "Visual Studio 17 2022" -A x64
cmake --build ..\putty-build --config Release
```

⚠️ **本机实测问题**：使用 `-G "Visual Studio 18 2026"` 时，CMake 报
```
-- The C compiler identification is unknown
CMake Error at CMakeLists.txt:2 (project): No CMAKE_C_COMPILER could be found.
```
即 VS 18 的 C++ 工具集未注册给 CMake。**改用方式 A（Ninja + vcvars64）可绕开**。详见第 7 节排错。

### 3.3 MinGW 交叉编译（可选）

需要 MinGW-w64 工具链，把 `gcc` 放到 PATH 后：

```bash
cmake -S . -B ../putty-build-mingw -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build ../putty-build-mingw
```

⚠️ 待验证：MinGW 下部分 Windows API（如 `-municode`、资源文件）可能需要额外参数。

---

## 4. Linux 构建

### 4.1 安装依赖

```bash
# Debian / Ubuntu
sudo apt install build-essential cmake pkg-config libgtk-3-dev libx11-dev

# Fedora / RHEL
sudo dnf install gcc cmake pkgconf-pkg-config gtk3-devel libX11-devel

# Arch
sudo pacman -S base-devel cmake pkgconf gtk3 libx11
```

### 4.2 构建

```bash
cmake -S . -B ../putty-build -DCMAKE_BUILD_TYPE=Release
cmake --build ../putty-build -j$(nproc)
```

### 4.3 无 GTK 环境（服务器/纯命令行）

```bash
cmake -S . -B ../putty-build -DPUTTY_GTK_VERSION=NONE
cmake --build ../putty-build -j$(nproc)
```

此时只能构建 `plink`、`pscp`、`psftp`、`psusan` 等命令行工具，**不会**生成 `putty` / `pterm` GUI。✅ 已核实（`unix/CMakeLists.txt` 中非 GTK 目标使用 `no-gtk.c`）

### 4.4 安装

```bash
sudo cmake --build ../putty-build --target install
```

> `pterm` 若需写入 `/var/run/utmp`、`/var/log/wtmp`，安装后需手动设置 setuid/setgid（见 `PITFALLS.md` P-010）。

---

## 5. macOS 构建

```bash
xcode-select --install          # Xcode 命令行工具
brew install cmake pkg-config gtk+3   # gtk+3 仅 GUI 需要

cmake -S . -B ../putty-build -DCMAKE_BUILD_TYPE=Release
cmake --build ../putty-build -j$(sysctl -n hw.ncpu)
```

---

## 6. CMake 选项

均通过 `-D<NAME>=<VALUE>` 传入。✅ 已核实（`cmake/setup.cmake`、`cmake/gtk.cmake`）

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `PUTTY_GTK_VERSION` | `ANY` | 可选 `ANY` / `3` / `2` / `1` / `NONE`；`NONE` 表示不构建 GTK GUI |
| `PUTTY_IPV6` | `ON` | 是否启用 IPv6 支持 |
| `PUTTY_DEBUG` | `OFF` | 调试构建（含断言、调试输出） |
| `PUTTY_FUZZING` | `OFF` | 构建 fuzzing 目标（配合 `fuzzterm`） |
| `PUTTY_COVERAGE` | `OFF` | 覆盖率插桩构建 |
| `PUTTY_COMPRESS_SCROLLBACK` | `ON` | 回滚缓冲压缩（省内存，略微增加 CPU） |
| `CMAKE_BUILD_TYPE` | 空 | `Release` / `Debug` / `RelWithDebInfo`（单配置生成器有效） |

示例：调试构建

```bash
cmake -S . -B ../putty-build-debug -DCMAKE_BUILD_TYPE=Debug -DPUTTY_DEBUG=ON -DPUTTY_COMPRESS_SCROLLBACK=OFF
```

---

## 7. 常见构建错误排查

| 报错 | 原因 | 解法 |
|------|------|------|
| `No CMAKE_C_COMPILER could be found` | 生成器找不到编译器（VS 18 + CMake 4.x 实测出现） | 改用 Ninja + `vcvars64.bat`；或换 `-G "Visual Studio 17 2022"` |
| `Could NOT find PkgConfig` | 缺 pkg-config | `apt install pkg-config` / `brew install pkg-config` |
| `Checking for module 'gtk+-3.0'... not found` | 没装 GTK3 开发包 | 装 `libgtk-3-dev`，或用 `-DPUTTY_GTK_VERSION=NONE` 跳过 GUI |
| `undefined reference to XCreateWindow` 之类 | 缺 X11 开发包 | `apt install libx11-dev libxrender-dev` |
| `cmake_minimum_required` 版本策略错误 | CMake 4.x 对 < 3.5 的项目报错（本项目 3.7 不受影响） | 确认 CMake ≥ 3.7 |
| 构建目录里出现 `CMakeCache.txt` 被 `git status` 捕获 | 在源码目录内做了 in-source 构建 | 删除该文件，改用 `-B ../putty-build` |
| 改了 `doc/*.but` 但文档没变 | 生成文档需要 Halibut | 安装 Halibut 后构建 `doc` 目标 |

---

## 8. 构建产物一览

| 产物 | 平台 | 说明 |
|------|------|------|
| `putty` / `putty.exe` | 全平台 | SSH/Telnet/Serial 客户端 |
| `puttytel` | 全平台 | 仅 Telnet |
| `pterm` | Unix | 终端包装器 |
| `pscp` | 全平台 | SCP 客户端 |
| `psftp` | 全平台 | SFTP 客户端 |
| `plink` | 全平台 | 命令行 SSH（自动化用） |
| `puttygen` | 全平台 | 密钥工具 |
| `pageant` | Windows | SSH 认证代理 |
| `psocks` | 全平台 | SOCKS 代理 |
| `testcrypt` | — | 测试用加密后端（供 Python 测试套件调用）✅ 已核实（`CMakeLists.txt:77`） |

---

## 9. 文档构建（可选）

```bash
# 需先安装 Halibut: https://www.chiark.greenend.org.uk/~sgtatham/halibut/
cmake --build ../putty-build --target doc
```

文档源文件在 `doc/*.but`，可生成 HTML、CHM、man page、纯文本。⚠️ 待验证：目标是否在无 Halibut 时自动跳过。

---

## 10. 测试

`test/` 目录下有 35 个 Python 测试脚本（如 `cryptsuite.py`、`agenttest.py`），依赖构建出的 `testcrypt` 可执行文件。

⚠️ 待验证：具体入口与调用方式尚未确认（见 `PITFALLS.md` O-003）。确认后请更新本节。

---

## 11. 实测记录（本仓库）

| 日期 | 环境 | 结果 |
|------|------|------|
| 2026-10-26 | Windows 11 + VS 18 Community（MSVC 14.51）+ CMake 4.3.1-msvc1 | `-G "Visual Studio 18 2026"` 配置失败：`No CMAKE_C_COMPILER could be found`。**尚未完成完整编译** |

> 完成一次成功编译后，请在此表追加一行，并在 `DEVLOG.md` 记录产物验证情况（能启动、能连接、版本号正确）。
