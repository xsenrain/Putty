# 二次开发日志

本文件记录本仓库（PuTTY 0.85 源码镜像）的二次开发过程：环境搭建、代码改动、编译验证与遗留问题。

目的有两个：一是保留决策上下文，避免「几个月后忘了为什么这么改」；二是让每一次改动都能追溯到具体提交，回滚时有据可依。

---

## 基线信息

| 项 | 值 |
|----|-----|
| 上游项目 | PuTTY（作者 Simon Tatham） |
| 上游仓库 | `https://git.tartarus.org/simon/putty.git` |
| 基线版本 | **0.85**（见 `LATEST.VER`） |
| 源码导入提交 | `141511c` Import PuTTY 0.85 source code |
| 仓库初始化提交 | `ddc348d` Merge remote-tracking branch 'origin/main' |
| 文档提交 | `6da9870` docs: 重写 README |
| 语言 / 构建 | C / CMake |
| 许可证 | MIT（见 `LICENCE`） |

> 基线版本一旦变更（例如同步到上游新版本），需在此表中更新并另起一条日志，说明同步范围与冲突处理。

---

## 记录约定

每条日志建议包含以下字段，便于统一检索：

- **日期 / 目标**：这次要解决什么问题
- **改动范围**：涉及哪些目录或文件
- **提交**：对应的 commit hash
- **验证方式**：编译通过？运行验证？仅静态检查？
- **遗留问题**：没做完的部分、已知风险

---

## 2026-10-26 仓库初始化

### 目标

把本地 PuTTY 0.85 源码纳入 Git 管理并托管到 GitHub，作为后续二次开发的工作底座。

### 完成事项

| 时间 | 事项 | 说明 | 提交 |
|------|------|------|------|
| 20:00 | 源码导入 | 本地 `C:\Users\Administrator\Desktop\putty-0.85` 初始化 Git 仓库（`main` 分支），提交 710 个文件 | `141511c` |
| 20:00 | 与远程合并 | 远程仓库原有一个仅含 7 字节 `README.md` 的初始提交，以 `merge --allow-unrelated-histories` 方式合并，**未强推、未覆盖原有内容** | `ddc348d` |
| 20:01 | 推送 | 推送至 https://github.com/xsenrain/Putty ，建立 upstream 跟踪 | — |
| 20:03 | 重写 README | 补充项目简介、组件清单、目录结构、二开切入点、CMake 构建步骤、文档章节速览、许可说明 | `6da9870` |
| 20:04 | 建立本日志 | 新增 `DEVLOG.md`，记录初始化过程与基线信息 | 本条提交 |

### 环境与工具

| 项 | 状态 |
|----|------|
| Git | 2.55.0.windows.3 ✅ |
| 凭据管理 | `credential.helper=manager`，GitHub 凭据已缓存，可非交互推送 ✅ |
| GitHub CLI (`gh`) | ❌ 未安装（如需建 PR / 管理 Issue 需另装） |
| CMake | ❌ 当前 shell 未找到 |
| C 编译器（gcc / cl） | ❌ 当前 shell 未找到 |

### 源码完整性说明

- 导入 710 个文件；上游源码包共 722 个文件，差额 12 个为 `doc/*.1`、`doc/putty.chm`、`doc/puttydoc.txt` 等**编译生成的文档产物**，被 PuTTY 自带 `.gitignore` 排除，属正常行为，不影响源码完整性（文档源文件位于 `doc/*.but`）。
- 版本校验：`LATEST.VER` = `0.85`。

### 遗留问题

1. **编译尚未验证**：本机当前 shell 未配置 CMake 与 C 编译器，`cmake . && cmake --build .` 未实际执行，构建可用性待验证。
2. **开发分支未建立**：目前直接在 `main` 上提交，正式改动前建议切出 `dev` 分支。
3. **上游基线未打标签**：建议补 `upstream-0.85` 标签，便于后续与上游 diff。
4. **文档 HTML 未入库**：官方 `puttydoc` 文档（22 个 HTML）暂未提交，是否作为 `docs/` 托管待定。

### 下一步计划（待确认）

- [ ] 配置构建环境（CMake + MSVC 或 MinGW），跑通一次完整编译
- [ ] 建立 `dev` 开发分支与 `upstream-0.85` 基线标签
- [ ] 确定二次开发方向（候选：界面改造 / 跳板机增强 / 会话管理 / 加密套件调整）
- [ ] 按方向确定首批改动模块，参考 README 中的「二开切入点」表

---

## 2026-10-26 建立长期记忆与协作文档体系

### 目标

让**任何智能体或新协作者首次进入仓库时，无需口头交接即可接手**：知道项目是什么、到哪一步了、改动守什么规矩、哪里有坑、怎么编译。

### 完成事项

| 时间 | 事项 | 提交 |
|------|------|------|
| 20:05 | 新增 `AGENTS.md`：入职须知（必读顺序、现状、目录地图、一任务一提交规范、禁止事项、上下文获取优先级、交接模板） | `5708bd3` |
| 20:08 | 新增 `PITFALLS.md`：避坑清单（Git 操作 / 选型排除 / 构建 / 代码规范四类） | `1c099f5` |
| 20:12 | 新增 `BUILD.md`：编译指南（前置条件、三平台步骤、CMake 选项表、产物清单、排错表、实测记录） | `6282f8a` |
| 20:12 | `README.md` 增加「文档导航」与「编译帮助」速查章节 | `49c735a` |
| 20:13 | `PITFALLS.md` 修正 P-011、新增 P-016（VS18 + CMake 4 生成器报错） | `4290816` |
| 20:14 | 本条日志 | 本条提交 |

### 文档体系设计思路

四份文档职责互斥，避免信息重复维护：

- `README.md` —— **对外**：项目是什么、有什么、怎么编（速查）
- `AGENTS.md` —— **对协作者**：规矩与流程（怎么提交、禁什么）
- `PITFALLS.md` —— **对执行**：具体坑与解法（现象→原因→解法）
- `DEVLOG.md` —— **对时间**：发生了什么、为什么这么决定（本条）

### 事故记录：本地目录丢失

- **时间**：2026-10-26 约 20:08（写入 `PITFALLS.md` 之后、提交之前）
- **现象**：`C:\Users\Administrator\Desktop\putty-0.85` 整目录消失，磁盘与回收站均未找到；未提交的 `PITFALLS.md` 丢失
- **恢复**：`git clone https://github.com/xsenrain/Putty putty-0.85` 完整恢复（历史、文件全部在远程）；丢失的 `PITFALLS.md` 依据上下文重写
- **后续**：用户自行恢复了原始源码目录（无 `.git`），用 `git init` + `git remote add` + `git fetch` + `git reset origin/main` + `git checkout -- .` 重新挂接，最终与远程**完全一致（714 文件，工作区干净）**
- **教训**：已录入 `PITFALLS.md` P-015 —— **改动必须立即提交推送，不要攒批**

### 工具链探查（重要修正）

之前判断「本机无 CMake / 无编译器」**是错的**，实际环境：

| 组件 | 实际情况 |
|------|---------|
| Visual Studio | VS 18 Community 已安装，MSVC **14.51.36231** |
| CMake | VS 自带 **4.3.1-msvc1**（在 `Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\`） |
| Ninja | VS 自带（同目录 `Ninja\ninja.exe`） |
| `D:\CMake` | **空壳目录**，`bin` 下只有一个 `.rbf` 文件，不可用 |
| Git Bash 的 PATH | 上述工具均不在 PATH，需 `vcvars64.bat` 注入 |

### 编译验证进展

- 已执行：`cmake -S . -B <workspace>/putty-build`，默认选中 `Visual Studio 18 2026` 生成器
- 结果：**失败** —— `The C compiler identification is unknown` / `No CMAKE_C_COMPILER could be found`
- 结论：VS 18 工具集未注册给 CMake 4.x 的 VS 生成器，应改用 **Ninja + vcvars64**（已写入 `BUILD.md` 第 3.1 节与 `PITFALLS.md` P-016）
- **完整编译仍未完成**，构建产物尚未产生

### 遗留问题（更新）

1. **完整编译未验证** —— 下一步用 Ninja + vcvars64 实际编译一次，成功后回填 `BUILD.md` 第 11 节
2. 未建立 `dev` 分支，未打 `upstream-0.85` 标签
3. 测试套件入口未确认（`test/` 下 35 个 Python 脚本，依赖 `testcrypt`）
4. 二次开发方向仍未确定

## 2026-10-26 编译验证通过（Windows / MSVC）

### 目标

回答「怎样才能编译成功」——把 POSIX 环境下的摸索变成一条可复现、可脚本化的路径。

### 结论：三条命令搞定

```bat
contrib\build-windows-msvc.bat
```

即在 **x64 Native Tools Command Prompt** 中：`vcvars64` → 补 SDK 的 `PATH/INCLUDE/LIB` → `cmake -G Ninja`（`CMAKE_RC_COMPILER` 用正斜杠）→ `cmake --build -- -j 1`。

### 排障过程（四层，逐层剥）

| # | 现象 | 真正原因 | 处理 |
|---|------|---------|------|
| 1 | `No CMAKE_C_COMPILER could be found` | CMake 4.x 的 `Visual Studio 18 2026` 生成器未拿到 VS 18 工具集 | 改用 Ninja（P-016） |
| 2 | `RC Pass 1 ... no such file or directory` | `vcvars64.bat` 靠 `reg.exe` 查 SDK，`reg.exe` 被安全策略拦截 → SDK 未初始化 | 手动把 SDK `bin\<ver>\x64` 加进 PATH（P-017） |
| 3 | `LNK1104: 无法打开文件"kernel32.lib"` | 同一原因，`LIB` / `INCLUDE` 里没有 SDK 路径 | 手动补 `LIB` 与 `INCLUDE`（P-017） |
| 4 | `Invalid character escape '\P'` | `-DCMAKE_RC_COMPILER` 传了反斜杠，被写进 `.cmake` 当转义符 | 改用正斜杠（P-018） |

另外遇到一次并行构建死锁（停在 456/467，`cl.exe` 空转 10 分钟无产物），用 `-j 1` 增量重跑解决（P-019）；写批处理时中文注释被 GBK 解析成乱码，改纯 ASCII（P-020）。

### 验证结果

```
$ plink.exe -V
plink: Release 0.85
Build platform: 64-bit x86 Windows
Compiler: Visual Studio, _MSC_VER=1951, _MSC_FULL_VER=195136257
```

| 产物 | 大小 |
|------|------|
| putty.exe | 1.1 MB |
| psftp.exe / pscp.exe | 779 / 770 KB |
| plink.exe | 765 KB |
| puttytel.exe | 505 KB |
| pterm.exe | 433 KB |
| puttygen.exe | 400 KB |
| pageant.exe | 374 KB |

构建输出目录：`Desktop\putty-build`（out-of-source，未污染仓库）。

### 交付物

| 文件 | 说明 | 提交 |
|------|------|------|
| `contrib/build-windows-msvc.bat` | 一键构建脚本：自动定位 VS / SDK、注入环境、调用 Ninja，默认 `-j 1` | `f38f79b` |
| `BUILD.md` | 3.0 一键脚本、3.1 手工等价步骤、3.2 为何不用 VS 生成器；第 11 节实测记录 | `f38f79b` |
| `PITFALLS.md` | 新增 P-017 ~ P-020 | `cd4266a` |
| `README.md` | Windows 构建改为已验证路径 + 构建状态行 | `3056769` |

### 遗留问题

1. Linux / macOS 路径未实测（`pkg-config` + GTK3 相关分支未验证）
2. 测试套件入口未确认（`testcrypt` 已随构建产出，Python 脚本如何调用待查）
3. `-j 1` 的死锁只是绕过，未找到根因（疑安全软件实时扫描）

## 2026-10-26 README 编译说明重构（编译方法前置）

### 目标

此前「如何编译」藏在 README 靠后的「编译帮助」速查节，且缺少三块关键信息：装什么环境、怎么判断编译成功、失败时最可能是哪三个原因。任何新读者（人或智能体）打开仓库都容易在第一步卡住。

### 改动范围

| 文件 | 改动 | 提交 |
|------|------|------|
| `README.md` | 原「编译帮助」章节整体重写为 **「如何编译」**，并上移到「文档导航」之后（第 26 行）；新增环境准备表、成功验证小节、产物大小表、三个致命坑表；文档导航表增加章节内锚点链接 | `d1e20d7` |
| `contrib/build-windows-msvc.bat` | 注释里的用法路径 `tools\` 更正为 `contrib\`（脚本早已移到 contrib 目录） | `8b65b26` |

「如何编译」新章节结构（9 小节）：

0. 环境准备（三平台依赖表，Windows 明确需 VS + Windows SDK、无需第三方库）
1. Windows 一条命令（`contrib\build-windows-msvc.bat`）
2. Windows 手工等价步骤（含 SDK 环境变量注入，可复制粘贴）
3. Linux（含 `-DPUTTY_GTK_VERSION=NONE` 无 GTK 场景）
4. macOS
5. **验证是否真的编译成功**（`plink.exe -V` 实测输出 + 8 个产物的大小与用途）
6. **三个致命坑**（P-016 VS 生成器 / P-017 SDK 环境缺失 / P-018 RC 路径反斜杠）
7. 常用 CMake 选项表
8. 构建文档（Halibut）
9. 其他常见错误

### 验证方式

- 内容全部取自本仓库已验证事实：脚本实测 467 步 0 报错；`plink -V` 输出、产物大小均为 2026-10-26 真实构建结果，非推测
- 章节标题层级、锚点链接、表格渲染经本地 grep 校验，章节结构与行号已核对
- 未重新执行编译（本次仅文档改动，未触及源码；上次编译验证结论仍有效）

### 遗留问题

1. Linux / macOS 命令仍为「按官方 CMake 结构推导」，未在真实机器上验证（沿用上一条日志的遗留项）
2. README 内的 SDK 版本号 `10.0.26100.0` 是实测机器上的版本，其他机器需自行替换（已在正文加提示）

---

<!-- 新增日志请从下方追加，保持时间倒序或正序一致即可 -->


