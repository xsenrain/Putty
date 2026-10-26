# PITFALLS.md — 误点避坑清单

> **动手前必扫一遍。** 这里是本项目已知的坑，无论是环境、Git 操作、构建还是选型。
>
> 规则：**同一个坑踩第二次，先修文档再修代码。**

---

## 使用说明

每条记录包含五个字段：

| 字段 | 含义 |
|------|------|
| **现象** | 你看到什么（报错、异常行为） |
| **原因** | 为什么会这样 |
| **解法** | 怎么绕过或修掉 |
| **状态** | `已验证`（本仓库实际发生过）／`待验证`（来自官方文档或经验，未在本机复现） |
| **记录日期** | 首次记录时间 |

新增条目：编号顺延，不要复用已删除的编号。

---

## 一、Git 与仓库操作

### P-001 提交时大量 `LF will be replaced by CRLF` 警告

- **现象**：`git add` 时刷屏输出 `warning: in the working copy of 'xxx.c', LF will be replaced by CRLF the next time Git touches it`。
- **原因**：本机 `core.autocrlf=true`，Git 入库时把 CRLF 转成 LF、检出时再转回 CRLF。PuTTY 源码里混有 LF，所以每个文件都会告警。
- **影响**：不影响编译，但**与上游做 diff / 打 patch 时会产生「整文件全变」的假差异**，看不出真实改动。
- **解法**：
  - 对比上游时用 `git diff --ignore-cr-at-eol` 或 `git diff -w`；
  - 需要长期与上游同步，可考虑 `git config core.autocrlf input`；
  - **不要**盲目新增 `.gitattributes`（如 `* text=auto`），会触发全仓库一次性重写，产生巨大无意义 diff。
- **状态**：已验证（本仓库多次出现）
- **记录日期**：2026-10-26

### P-002 源码包 722 个文件，仓库只有 710 个 —— 不是丢文件

- **现象**：`find . -type f` 数出 722 个，`git ls-files` 只有 710 个，差额 12 个。
- **原因**：差额是 `doc/putty.1`、`doc/putty.chm`、`doc/puttydoc.txt` 等**编译生成的文档产物**，被 PuTTY 自带的 `.gitignore` 排除，属正常。
- **影响**：容易误判为「导入不全」，浪费时间重新下载。
- **解法**：用 `git status --ignored --short` 确认被忽略清单；文档源文件在 `doc/*.but`，不缺失。
- **状态**：已验证
- **记录日期**：2026-10-26

### P-003 远程仓库已有初始提交时，直接 push 会被拒

- **现象**：`! [rejected] main -> main (fetch first)` 或 `non-fast-forward`。
- **原因**：远程已有 commit（本仓库初始时有一个只含 7 字节 `README.md` 的提交），本地历史与之无关联。
- **解法**：
  ```bash
  git fetch origin
  git merge --allow-unrelated-histories origin/main
  git push origin main
  ```
  **不要**用 `push --force` 图省事——会抹掉远程已有内容。
- **状态**：已验证
- **记录日期**：2026-10-26

### P-004 没有 `gh` CLI，无法命令行建 PR / 管 Issue

- **现象**：`gh: command not found`。
- **原因**：开发机未安装 GitHub CLI。
- **影响**：只能用 `git push` 推代码；PR、Issue、Release 需在网页操作。
- **解法**：安装 `gh` 并 `gh auth login`；或在 GitHub 网页操作。
- **状态**：已验证
- **记录日期**：2026-10-26

### P-005 `putty.org` 不是 PuTTY 官网

- **现象**：搜索「PuTTY 官网」首先出现 `putty.org`，页面夹杂 Bitvise 产品推荐。
- **原因**：该域名已被商业公司 **Bitvise** 收购并重新利用，页面上的 PuTTY 下载链接只是导流。
- **影响**：可能下载到非官方构建，或引用错误的技术资料。
- **解法**：官方站点是 `https://www.chiark.greenend.org.uk/~sgtatham/putty/`；源码用 `https://git.tartarus.org/simon/putty.git`；下载用 `https://the.earth.li/~sgtatham/putty/latest/`。
- **状态**：已验证（2026-10 核实）
- **记录日期**：2026-10-26

### P-015 本地工作目录可能被外部删除，改动务必及时提交

- **现象**：2026-10-26 20:08 前后，本地 `C:\Users\Administrator\Desktop\putty-0.85` 目录在未执行任何删除命令的情况下消失，磁盘与回收站均无法找到（未提交的 `PITFALLS.md` 因此丢失，已重写）。
- **原因**：未确定。疑为清理工具、杀毒隔离或人为误删。
- **影响**：**未提交的改动会直接丢失**。
- **解法**：
  - **改完立刻 commit 并 push**，不要攒着；
  - 目录丢失时用 `git clone https://github.com/xsenrain/Putty putty-0.85` 即可完整恢复（历史、分支、标签都在远程）；
  - 原始源码包 `C:\Users\Administrator\Downloads\putty-0.85.tar.gz` 可作二次兜底。
- **状态**：已验证（本仓库实际发生）
- **记录日期**：2026-10-26

---

## 二、选型阶段已排除的坑（避免重复调研）

> 这几条来自前期「找 C/C++ SSH 成品项目做二开底座」的调研结论，**不要重复走弯路**。

### P-006 WindTerm 是「半开源」，不能二开

- **现象**：WindTerm（32K+ star）功能强、性能好，仓库标 Apache-2.0，看起来很适合当底座。
- **原因**：官方 README 明确写 *"WindTerm is a **partial open source** project, and the source will be **gradually opened**"*。仓库仅含零散工具类，**SSH 协议栈、终端仿真、UI 主体均未放出**，无法完整构建。
- **影响**：fork 后改不了核心、编不出产品。
- **解法**：**只用不改**可以，**二开不要选**。二开选 PuTTY（MIT 全开源）。
- **状态**：已验证（查证官方 README 与仓库内容）
- **记录日期**：2026-10-26

### P-007 KiTTY 基线停在 PuTTY 0.76（2021），不适合当底座

- **现象**：KiTTY 是 PuTTY 的增强分支，功能比原版多，看起来很合适。
- **原因**：其基线长期停留在 PuTTY **0.76**，后续上游 0.77→0.85 的安全修复与算法更新均未跟进；正式版本更新缓慢（近年停滞）。
- **影响**：以它为起点，等于从 2021 年的代码起步，安全补丁要自己补。
- **解法**：直接用 PuTTY 0.85 做底座，需要 KiTTY 的某些特性时**按需移植单个特性**，不要整体 fork。
- **状态**：已验证
- **记录日期**：2026-10-26

### P-008 做二开应基于开发快照，而非 release 源码包

- **现象**：用 release 包（如本次的 0.85 包）起步。
- **原因**：PuTTY 官方 README 说明——正式发布后会对代码做大范围改动，基于 release 的改动**难以合并回上游**；官方建议基于开发快照（snapshot）开发。
- **影响**：后续想同步上游会非常痛苦。
- **解法**：若计划长期跟进上游，从 `git clone https://git.tartarus.org/simon/putty.git` 起步，或用 snapshot；纯内部产品/不打算回馈上游则用 release 包也可以（本仓库即此定位）。
- **状态**：待验证（结论来自官方 README，未在本机实测合并成本）
- **记录日期**：2026-10-26

---

## 三、构建相关

### P-009 文档产物需要 Halibut 生成，源文件是 `.but`

- **现象**：仓库里没有 `putty.chm`、`*.1`、`puttydoc.txt`；改了 `doc/*.but` 却看不到效果。
- **原因**：这些是 Halibut 从 `.but` 源文件编译出的产物，且被 `.gitignore` 排除。
- **影响**：误以为文档缺失；或改完文档无法验证。
- **解法**：安装 Halibut（`https://www.chiark.greenend.org.uk/~sgtatham/halibut/`）后构建 `doc` 目标。
- **状态**：待验证（需实际构建后确认目标名与行为）
- **记录日期**：2026-10-26

### P-010 Unix 下 `pterm` 需要 setuid/setgid 才能记录登录信息

- **现象**：`pterm` 能用，但 `/var/run/utmp`、`/var/log/wtmp` 里没有登录记录。
- **原因**：写登录记录需要特权；CMake 的 install 步骤**不会**自动加权限。
- **影响**：`who` / `last` 查不到 pterm 登录会话。
- **解法**：安装后手动 `chown` / `chgrp` / `chmod` 该二进制（参考源码根目录 `README`）。
- **状态**：待验证（来自官方 README）
- **记录日期**：2026-10-26

### P-011 构建工具链缺失时不要下「编译通过」结论

- **现象**：`cmake --version`、`gcc --version`、`cl` 在 Git Bash 里均 `command not found`。
- **原因**：开发机**实际装有** VS 18 Community（MSVC 14.51）与 VS 自带 CMake 4.3.1，但它们**不在默认 PATH** 中——VS 环境必须靠 `vcvars64.bat` 注入，CMake 在 `%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\`。
- **影响**：容易误判为「机器上没有编译器」而放弃构建；更危险的是**未经编译就声称改动可用**。
- **解法**：
  - 先确认是否只是 PATH 问题：
    ```bash
    ls "/c/Program Files/Microsoft Visual Studio/18/Community/VC/Tools/MSVC/*/bin/Hostx64/x64/cl.exe"
    ls "/c/Program Files/Microsoft Visual Studio/18/Community/Common7/IDE/CommonExtensions/Microsoft/CMake/CMake/bin/cmake.exe"
    ```
  - 真正无法构建时，在 commit 信息与 `DEVLOG.md` 中**明确写「未编译验证」**。
- **状态**：已验证（2026-10-26 复查，之前「未安装」的结论有误，已更正）
- **记录日期**：2026-10-26

### P-016 VS 18 + CMake 4.x 用 VS 生成器报「找不到 C 编译器」

- **现象**：
  ```
  -- Building for: Visual Studio 18 2026
  -- The C compiler identification is unknown
  CMake Error at CMakeLists.txt:2 (project): No CMAKE_C_COMPILER could be found.
  ```
- **原因**：VS 18（2026）的 C++ 工具集未注册给 CMake 的 VS 生成器；CMake 版本为 `4.3.1-msvc1`。
- **影响**：按「常识」直接 `cmake -S . -B build` 会失败，容易误以为源码有问题。
- **解法**：改用 **Ninja + vcvars64**：
  ```bat
  call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
  cmake -S . -B ..\putty-build -G Ninja -DCMAKE_BUILD_TYPE=Release
  ```
  或换 `-G "Visual Studio 17 2022" -A x64`。
- **状态**：已验证（2026-10-26 实测报错）
- **记录日期**：2026-10-26

### P-017 `vcvars64.bat` 跑完仍缺 `rc.exe` / `mt.exe` / `kernel32.lib`

- **现象**：
  1. 链接时报 `RC Pass 1: command "rc /fo ..." failed ... no such file or directory`
  2. 补上 rc 后变成 `LINK : fatal error LNK1104: 无法打开文件"kernel32.lib"`
- **原因**：`vcvars64.bat` 依赖 `reg.exe` 查询 Windows SDK 的安装路径。当 `reg.exe` 被安全策略/沙箱拦截时，脚本**静默跳过** SDK 初始化，`PATH` 里没有 `rc.exe`/`mt.exe`，`INCLUDE`/`LIB` 里没有 SDK 头文件与库——但**编译器本身正常**，所以 `cl.exe` 能找到，只在链接阶段暴露。
- **影响**：报错位置具有迷惑性（像是链接器/库缺失），实际是环境初始化不完整。
- **解法**：手工补三条环境变量（版本号按 `C:\Program Files (x86)\Windows Kits\10\bin` 下实际目录调整）：
  ```bat
  set KITS=C:\Program Files (x86)\Windows Kits\10
  set SDKVER=10.0.26100.0
  set PATH=%KITS%\bin\%SDKVER%\x64;%PATH%
  set INCLUDE=%KITS%\Include\%SDKVER%\um;%KITS%\Include\%SDKVER%\ucrt;%KITS%\Include\%SDKVER%\shared;%INCLUDE%
  set LIB=%KITS%\Lib\%SDKVER%\um\x64;%KITS%\Lib\%SDKVER%\ucrt\x64;%LIB%
  ```
  验证：`where rc` 与 `where mt` 都应输出路径。
- **状态**：已验证（2026-10-26 实际踩坑并修复）
- **记录日期**：2026-10-26

### P-018 `CMAKE_RC_COMPILER` 传反斜杠路径导致 CMake 解析报错

- **现象**：
  ```
  CMake Error at .../CMakeRCCompiler.cmake:1 (set):
    Syntax error ... when parsing string
      C:\Program Files (x86)\Windows Kits\10\bin\10.0.26100.0\x64\rc.exe
    Invalid character escape '\P'.
  ```
- **原因**：CMake 把 `-DCMAKE_RC_COMPILER=` 的原始值写进 `.cmake` 文件，反斜杠被当作转义符（`\P` 非法）。
- **影响**：配置阶段就失败，且报错指向生成的文件，不易联想到命令行参数。
- **解法**：`CMAKE_RC_COMPILER` 与 `CMAKE_MT` 一律用**正斜杠**：
  ```bat
  -DCMAKE_RC_COMPILER="C:/Program Files (x86)/Windows Kits/10/bin/10.0.26100.0/x64/rc.exe"
  ```
- **状态**：已验证（2026-10-26 实测）
- **记录日期**：2026-10-26

### P-019 并行 Ninja 偶发卡死：`cl.exe` 空转、无产物、日志不推进

- **现象**：构建停在 `[456/467]` 后完全不动，`cl.exe` 进程存活 10 分钟以上但目标目录没有任何新文件，`.ninja_log` 也不追加。
- **原因**：未完全确定。疑与安全软件/沙箱对编译子进程的实时扫描有关（并行时多个 cl 同时触发扫描更容易卡）。
- **影响**：看起来像「编译很久」，实际是死锁，干等无意义。
- **判断方法**：`find <build> -name "*.obj" -newermt "-3 minutes"` 无输出即卡死，不要干等。
- **解法**：杀掉后单线程增量重跑（已完成的步骤会命中缓存，很快）：
  ```bash
  taskkill /F /IM cl.exe /T
  cmake --build <build_dir> -- -j 1
  ```
  本仓库的一键脚本默认已带 `-j 1`。
- **状态**：已验证（2026-10-26 实际卡死，`-j 1` 后 14 步补齐并成功）
- **记录日期**：2026-10-26

### P-020 Windows 批处理脚本里写中文注释会被 GBK 解析成乱码

- **现象**：`.bat` 运行时刷出 `'ram' 不是内部或外部命令`、`'nv' 不是内部或外部命令`，以及一堆 `系统找不到指定的路径`。
- **原因**：文件以 UTF-8 保存，`cmd.exe` 按系统代码页（中文 Windows 为 GBK/936）解析，多字节字符会吞掉相邻字节，把 `rem` 注释切断成乱命令。
- **影响**：脚本行为完全错乱，且报错信息与真实逻辑无关。
- **解法**：`.bat` 内**只用 ASCII**（注释也用英文）；确需中文时另存为 GBK 编码，或改用 `.ps1`（UTF-8 BOM）。
- **状态**：已验证（2026-10-26 实测）
- **记录日期**：2026-10-26


---

## 四、代码改动规范（避免结构性错误）

### P-012 平台相关代码放错目录会导致跨平台构建失败

- **现象**：在 Linux 上编译通过，Windows 构建报找不到 `windows.h`；或反之。
- **原因**：PuTTY 用目录隔离平台代码：`windows/`（Win32）、`unix/`（GTK/POSIX），共享逻辑在顶层与 `terminal/`、`ssh/`、`utils/`。
- **影响**：一个平台的改动直接破坏另一个平台的构建。
- **解法**：平台相关 API 只写在对应目录；共享层通过 `putty.h` 中的抽象接口（如 `Backend`、`Terminal`、`Seat`）调用。
- **状态**：待验证（结构事实已确认，未实测编译）
- **记录日期**：2026-10-26

### P-013 不要改动 `LICENCE` 与版权声明

- **现象**：想「清理」或「换成自己的许可证」。
- **原因**：PuTTY 为 MIT 许可，**必须保留原版权声明与许可声明**，否则构成许可违约。
- **影响**：法律风险，且会让整个仓库的合规性失效。
- **解法**：保留 `LICENCE` 原文；如需声明自己的修改，另加 `NOTICE` 或在 README 中说明「基于 PuTTY 0.85，遵循 MIT」。
- **状态**：已验证（MIT 条款要求）
- **记录日期**：2026-10-26

### P-014 构建产物与大文件不要入库

- **现象**：`git status` 出现 `CMakeCache.txt`、`*.o`、`*.exe`、`build/`。
- **原因**：本地执行过 CMake 或编译。
- **影响**：仓库膨胀、diff 噪音、跨机器污染。
- **解法**：确认 `.gitignore` 覆盖（本仓库已有 PuTTY 自带规则）；编译请在**源码目录之外**做 out-of-source 构建：
  ```bash
  cmake -S . -B ../putty-build
  cmake --build ../putty-build
  ```
- **状态**：待验证（未实际编译，建议沿用 out-of-source）
- **记录日期**：2026-10-26

---

## 待观察清单（尚无定论，不要当结论用）

| 编号 | 事项 | 待确认什么 |
|------|------|-----------|
| O-001 | 行尾符是否需统一为 LF | 与上游 patch 的实际冲突率；决定是否引入 `.gitattributes` |
| O-002 | GTK2 与 GTK3 构建差异 | 0.85 下 `unix/CMakeLists.txt` 对两种版本分支不同，需实测 |
| O-003 | 测试套件如何运行 | `test/` 下有 35 个 Python 脚本，依赖 `testcrypt` 可执行文件，具体入口待确认 |
| O-004 | MSVC 与 MinGW 产物差异 | 是否影响后续分发 |
