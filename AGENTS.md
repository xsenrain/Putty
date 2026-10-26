# AGENTS.md — 智能体入职须知

> **给任何首次接触本仓库的人类或 AI 智能体：先读这一页，再动代码。**
>
> 本文件是项目长期记忆的入口。它回答四个问题：这是什么、现在到哪一步了、改动要遵守什么规则、坑在哪里。

---

## 0. 30 秒速览

| 问题 | 答案 |
|------|------|
| 这是什么 | PuTTY 0.85 官方源码的个人镜像，作为**二次开发底座** |
| 是否官方 | ❌ 不是。上游由 Simon Tatham 维护，本仓库仅为学习与二开 |
| 代码规模 | 约 **48,700 行** C 代码（450 个 `.c` + 89 个 `.h`），722 个文件 |
| 构建 | CMake 3.7+，C99 |
| 许可证 | MIT —— **改动后可闭源商用，但必须保留 `LICENCE` 与版权声明** |
| 当前状态 | 仓库已初始化、文档体系已建立、**Windows 编译已验证通过**（467 步，产物 `plink -V` 显示 `Release 0.85`）；尚未开始任何功能代码改动 |
| 最重要的一条规则 | **一次任务 = 一次 commit，改完即推送 GitHub** |

---

## 1. 必读顺序（按此顺序读，不要跳）

| 顺序 | 文件 | 读它是为了知道 |
|------|------|----------------|
| 1 | `README.md` | 项目是什么、有哪些组件、目录怎么分、二开该动哪块 |
| 2 | **`AGENTS.md`**（本文件） | 协作规则、提交规范、禁止事项 |
| 3 | `BUILD.md` | 怎么把代码编出来、编不出来怎么办 |
| 4 | `PITFALLS.md` | 前人踩过的坑，**动手前必扫一遍** |
| 5 | `DEVLOG.md` | 每个决策的时间线与提交 hash，追溯改动原因 |

> 只读 README 就开始改代码，大概率会重复踩 `PITFALLS.md` 里已经记录过的坑。

---

## 2. 项目现状

### 已完成

- [x] 源码导入（基线 `0.85`，导入提交 `141511c`）
- [x] 与远程初始提交合并（`ddc348d`）
- [x] README 重写：项目简介、组件表、目录结构、二开切入点（`6da9870`）
- [x] 二次开发日志 `DEVLOG.md`（`6a1c40b`）
- [x] 智能体协作规范、避坑清单、编译指南（`5708bd3` / `1c099f5` / `6282f8a`）
- [x] **Windows 编译跑通**：`contrib/build-windows-msvc.bat` 467/467 步通过，产物版本 `Release 0.85`（`f38f79b`）

### 未完成 / 已知缺口

- [ ] Linux / macOS 构建路径未实测
- [ ] 未建立 `dev` 开发分支，未打 `upstream-0.85` 基线标签
- [ ] 二次开发方向未确定（候选：界面改造 / 跳板机 / 会话管理 / 加密套件）
- [ ] 尚未有任何功能代码改动
- [ ] 测试套件（`test/` 下 35 个 Python 脚本）入口未确认

---

## 3. 目录地图（改哪里）

| 想改的东西 | 去哪个目录 |
|-----------|-----------|
| 界面布局、对话框、菜单 | `windows/`（Win32）、`unix/`（GTK）、`dialog.c`、`config.c` |
| 终端仿真（配色、回滚、按键、鼠标） | `terminal/` |
| SSH 协议（KEX、认证、通道、算法协商） | `ssh/` |
| 加密算法实现 | `crypto/` |
| 代理、跳板机、ProxyCommand | `proxy/` |
| 配置项增删与持久化 | `config.c`、`settings.c`、`conf.h` |
| 文件传输（SCP/SFTP） | `pscp.c`、`psftp.c`、`ssh/` 下的 SFTP 子系统 |
| 命令行工具行为 | `cmdline.c`、`plink` 相关 |
| 跨平台通用工具函数 | `utils/`（内存池、字符串、二叉树、时间、日志） |
| 文档 | `doc/*.but`（Halibut 格式） |

**不要**在 `windows/` 里写业务逻辑，也**不要**把平台相关代码塞进 `terminal/` 或 `ssh/` —— 这会导致跨平台编译失败（详见 `PITFALLS.md`）。

---

## 4. 变更流程（硬性规则）

### 4.1 一任务一提交

每个独立任务 = **一个 commit**，不要把多个不相关的改动揉在一起。

```
任务：给配置对话框加一个「保持连接间隔」输入框
  → commit 1: feat: 新增 keepalive 间隔配置项（config.c/settings.c）
  → commit 2: feat: 对话框增加 keepalive 输入控件（windows/config.c）
```

好处：任何一次改动都可以单独 `git revert`，不会被无关改动牵连。

### 4.2 提交信息规范

格式：`<type>: <中文描述>`

| type | 用途 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 会话列表支持按标签分组` |
| `fix` | 修 bug | `fix: 修复断开后重连丢失端口转发配置` |
| `refactor` | 重构（不改行为） | `refactor: 抽出通道管理公共逻辑到 ssh/` |
| `docs` | 文档 | `docs: 补充 MinGW 交叉编译步骤` |
| `build` | 构建脚本/CMake | `build: 增加 ARM64 目标` |
| `chore` | 杂项 | `chore: 更新 .gitignore` |
| `sync` | 同步上游 | `sync: 合并上游 0.86 变更` |

描述用中文，一句话说清「做了什么」，不要写「update」「fix bug」这种无信息量的内容。

### 4.3 提交前检查清单

- [ ] 代码能编译通过（或在提交信息里**明确说明未编译及原因**）
- [ ] 没有把构建产物（`*.o`、`*.exe`、`CMakeCache.txt`、`build/`）加入提交
- [ ] 涉及行为变更的，已同步更新 `DEVLOG.md`
- [ ] 踩到新坑或解决了旧坑，已更新 `PITFALLS.md`（新增编号 / 改状态）
- [ ] 没有修改 `LICENCE` 的版权声明

### 4.4 推送流程

```bash
git add -A
git commit -m "feat: xxx"
git push origin main      # 或当前开发分支
```

推送后建议 `git log --oneline -1` 确认，必要时用 `git ls-remote` 或重新克隆验证远程状态。

### 4.5 禁止事项

| 禁止 | 原因 |
|------|------|
| `git push --force` 到 `main` | 会抹掉他人/其他智能体的提交历史 |
| 删除或改写 `LICENCE` | 违反 MIT 许可证，法律风险 |
| 提交大于 10MB 的二进制文件 | GitHub 单文件限制 100MB，仓库会迅速膨胀；用 Release 附件或外部存储 |
| 提交构建产物 | 污染历史，diff 噪音 |
| 删除 `doc/*.but` 原文件 | 那是文档源文件，删了就没法重新生成文档 |
| 直接改 `main` 做实验性开发 | 建议先切 `dev` 分支 |

---

## 5. 遇到新问题怎么办

1. **先查** `PITFALLS.md` —— 可能已经有人踩过
2. **没查到** → 解决后立即追加一条，编号顺延（`P-012`、`P-013`…）
3. 每条必须写清：**现象 / 原因 / 解法 / 状态（已验证｜待验证）/ 日期**
4. 同一个坑第二次出现 → 说明文档没写清楚，**先修文档再修代码**

---

## 6. 上下文获取渠道（信息优先级）

遇到不确定的事，按此顺序求证，**不要凭印象编**：

| 优先级 | 渠道 | 说明 |
|--------|------|------|
| 1 | 仓库内文件 | `README`、`LICENCE`、`CMakeLists.txt`、`doc/*.but` |
| 2 | 本仓库文档 | `BUILD.md`、`PITFALLS.md`、`DEVLOG.md` |
| 3 | 上游源码 | `https://git.tartarus.org/simon/putty.git` |
| 4 | 官方文档 | `https://the.earth.li/~sgtatham/putty/latest/htmldoc/` |
| 5 | 官方站点 | `https://www.chiark.greenend.org.uk/~sgtatham/putty/` |

⚠️ **注意**：`putty.org` 域名已被商业公司 Bitvise 收购，**不是** PuTTY 官网，不要作为技术依据（见 `PITFALLS.md` P-005）。

---

## 7. 环境限制（当前开发机）

| 工具 | 状态 | 影响 |
|------|------|------|
| Git | ✅ 2.55.0.windows.3 | 正常 |
| GitHub 凭据 | ✅ 已缓存（credential.helper=manager） | 可非交互 push |
| GitHub CLI `gh` | ❌ 未安装 | 无法命令行建 PR / 管 Issue，需网页操作 |
| Visual Studio | ✅ VS 18 Community，MSVC 14.51（不在 PATH，需 `vcvars64.bat`） | 可编译 |
| CMake | ✅ 4.3.1-msvc1，位于 `%VS%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\` | 可配置构建 |
| Ninja | ✅ VS 自带，同目录 `Ninja\ninja.exe` | 推荐生成器 |
| Windows SDK | ✅ 10.0.26100.0（`C:\Program Files (x86)\Windows Kits\10`） | 需手动补 PATH/INCLUDE/LIB，见 P-017 |

> **直接构建**：`contrib\build-windows-msvc.bat`（脚本已处理上述所有环境细节）。**不要**用 `-G "Visual Studio 18 2026"`（P-016），**不要**省略 `-j 1`（P-019）。

---

## 8. 交接模板

如果你（智能体）完成了一段工作准备交棒，请在 `DEVLOG.md` 追加一条，至少包含：

```markdown
## YYYY-MM-DD 任务标题

### 目标
### 改动范围（文件/目录）
### 提交（commit hash）
### 验证方式（编译？运行？仅静态检查？）
### 遗留问题与下一步
```

这样下一位接手者能在 1 分钟内搞清楚「现在在哪、下一步做什么、哪里有雷」。
