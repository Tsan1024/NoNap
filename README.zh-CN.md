<!-- Language switcher. Keep this row identical across every README.<lang>.md. -->
<p align="center">
  <b>English</b> &nbsp;·&nbsp;
  <a href="README.zh-CN.md">简体中文</a> &nbsp;·&nbsp;
  <a href="README.es.md">Español</a> &nbsp;·&nbsp;
  <a href="README.ja.md">日本語</a> &nbsp;·&nbsp;
  <a href="README.fr.md">Français</a> &nbsp;·&nbsp;
  <a href="README.de.md">Deutsch</a>
</p>

> 本翻译由社区或机器生成，可能落后于英文版 README。请以英文版本为准。请参阅 [English README](README.md)。

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/hero-dark.gif">
    <source media="(prefers-color-scheme: light)" srcset="assets/hero-light.gif">
    <img alt="Sleepless: keep your Mac awake with the lid closed" src="assets/hero-light.gif" width="780">
  </picture>
</p>

<p align="center">
  <b>Sleepless 让你的 MacBook 在合盖、使用电池、没有外接显示器的情况下保持唤醒。</b><br>
  <sub>一个原生菜单栏开关，配合自动关闭定时器和电量下限截止，让你永远不会把电耗光。</sub>
</p>

<p align="center">
  <a href="https://github.com/Aboudjem/Sleepless/actions/workflows/ci.yml"><img alt="CI" src="https://img.shields.io/github/actions/workflow/status/Aboudjem/Sleepless/ci.yml?branch=main&label=CI&logo=githubactions&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases/latest"><img alt="Release" src="https://img.shields.io/github/v/release/Aboudjem/Sleepless?label=release&logo=apple&logoColor=white"></a>
  <a href="https://github.com/Aboudjem/Sleepless/releases"><img alt="Downloads" src="https://img.shields.io/github/downloads/Aboudjem/Sleepless/total?label=downloads"></a>
  <a href="LICENSE"><img alt="License: MIT" src="https://img.shields.io/github/license/Aboudjem/Sleepless?color=blue"></a>
  <img alt="Platform" src="https://img.shields.io/badge/macOS-26%20·%20Apple%20Silicon-7c5cf0?logo=apple&logoColor=white">
  <a href="https://github.com/Aboudjem/Sleepless/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/Aboudjem/Sleepless?style=social"></a>
</p>

<p align="center">
  <img alt="Sleepless demo: flip the switch, set an auto-off timer, drag the battery-floor slider" src="assets/demo.gif" width="760">
</p>

> [!NOTE]
> 合上盖子通常会让你的 Mac 进入睡眠，而基于 `caffeinate` 的应用（KeepingYouAwake 之类）从设计上就**无法**改变这一点。Sleepless 切换的是唯一能做到这件事的设置，`pmset disablesleep`，再用一个自动关闭定时器和电量下限截止来加以保护，所以你完全可以放心地把它忘掉。

## Sleepless 是做什么的

Sleepless 是一个极小的 macOS 菜单栏应用，让你的 MacBook 在合盖、使用电池、没有外接显示器、也没有假 HDMI 插头的情况下保持唤醒。你点击菜单栏里的咖啡杯，拨动一个开关，然后合上盖子：你的 Mac 会继续运行。把开关拨回去，或者让自动关闭定时器或电量下限替你关掉它，正常睡眠就会恢复。重启总是会把它重置。

它就是一个原生的 AppKit 文件。没有 Dock 图标，没有后台守护进程，没有内核扩展，没有任何依赖。如果你曾经在终端里敲过 `sudo pmset -a disablesleep 1`，然后忘了把它关回去，那么这个应用就是把那条命令做成了一个安全的、一键式的开关。

## 为什么别的防睡眠应用做不到

大多数防睡眠应用（KeepingYouAwake、Caffeine、Theine、Lungo，以及系统自带的 `caffeinate` 命令）都建立在 macOS 的电源断言（power assertions）之上。电源断言能阻止*空闲*计时器，但无法覆盖硬件层面的合盖触发，所以合上盖子的 Mac 仍然会睡眠。KeepingYouAwake 的维护者把这一点说得很直白：“caffeinate doesn't support this. KYA uses caffeinate under the hood”（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。

唯一能覆盖合盖睡眠的设置是 `pmset disablesleep`，它会设置内核的 `SleepDisabled` 标志。Sleepless 切换的正是这一项，并把值读回来，所以菜单栏绝不会撒谎，同时还用多重安全机制把它包裹起来。Amphetamine 同样可以在合盖时保持唤醒，但它建立在同一套断言层之上，并被普遍反映会在电源切换时于 Apple Silicon 上失效（[Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)）。

## 功能特性

|  |  |
|---|---|
| ☕ **一个开关** | 点击菜单栏里的咖啡杯，拨动开关。空杯表示正常睡眠，满杯表示保持唤醒，满杯加一个点表示在电池供电下唤醒且安全机制已生效。 |
| ⏲️ **自动关闭定时器** | 保持唤醒 1 小时或 2 小时，并实时倒计时，到点后自动关闭。定时器只存在内存里，所以退出或重启都会清掉它。 |
| 🔋 **电量下限截止** | 设定一个下限（5–50%，默认 15%）。在电池供电时，Sleepless 会在你耗光电量之前自动关闭。 |
| 🪫 **Low Power Mode 自动关闭** | 在电池供电时，如果 Low Power Mode 已开启，Sleepless 会让位，让 Mac 正常睡眠，安全逻辑和电量下限是同一个思路。 |
| 🖥️ **无需显示器，无需转接** | 只要合上盖子、使用电池即可。不需要外接显示器，不需要假 HDMI 插头，也不需要 clamshell 转接器。 |
| 🚀 **登录时启动** | 可选，默认关闭。它始终以关闭状态启动，绝不会自行重新开启防睡眠。 |
| 🪶 **小巧且原生** | 一个 AppKit 文件，搭配 SF Symbols。没有 Dock 图标，没有后台守护进程，没有 kext，没有任何依赖。 |

## 安装

**Homebrew**（推荐）：

```sh
brew install --cask aboudjem/tap/sleepless
# one-time: add the passwordless grant (it prints exactly what it writes first)
/Applications/Sleepless.app/Contents/Resources/grant.sh
```

**从源码构建**（信任路径：自己读、自己构建，不会有 Gatekeeper 提示）：

```sh
git clone https://github.com/Aboudjem/Sleepless.git
cd Sleepless && ./install.sh
```

**或者直接下载应用：** 获取[最新发布版本](https://github.com/Aboudjem/Sleepless/releases/latest)，解压，把 `Sleepless.app` 移动到 `/Applications`。它是临时签名（ad-hoc）的，所以请在首次启动时通过 **系统设置 → 隐私与安全性 → 仍要打开** 来批准（以前右键 → 打开的小技巧已在 macOS 15 中被移除）。

下载了发布版本？你可以确认它确实是本项目构建出来的，整个过程无需 Apple 账户：

```sh
shasum -a 256 -c SHA256SUMS
gh attestation verify Sleepless-*.app.zip -R Aboudjem/Sleepless
```

完整的验证步骤见 [docs/AUDIT.md](docs/AUDIT.md)。

## 怎么用

1. 点击菜单栏里的咖啡杯。
2. 把 **Keep awake with lid closed** 打开。
3. 可选：挑一个 1 小时或 2 小时的自动关闭定时器，并设定一个你信得过的电量下限。
4. 合上盖子。你的 Mac 会在电池供电下继续运行。

把开关关掉、让定时器或电量下限替你关掉它，或者重启，正常睡眠就会恢复。`./uninstall.sh` 会移除所有内容，并证明授权已经清除。

## Sleepless 与其他方案对比

| | **Sleepless** | Amphetamine | KeepingYouAwake | `caffeinate` |
|---|:---:|:---:|:---:|:---:|
| 合盖、无显示器时保持唤醒 | ✅ ¹ | ⚠️ ² | ❌ ³ | ❌ |
| 电池供电 | ✅ | ✅ | ✅（开盖） | ⚠️ ⁴ |
| 自动关闭定时器 | ✅ | ✅ | ✅ | ❌ |
| 低电量时自动关闭 | ✅ | ✅ | ✅ | ❌ |
| 开源 | ✅ MIT | ❌ App Store | ✅ MIT | Apple |
| 价格 | 免费 | 免费 | 免费 | 免费 |

<sub>数据截至 2026-06。¹ Sleepless 使用 `pmset disablesleep`，这正是为合盖场景设计的机制，并会把标志读回来让界面反映真实状态；不过任何防睡眠工具的实际表现仍然取决于硬件和 macOS 版本。² Amphetamine 文档里写了合盖显示模式，但被普遍反映会在电源切换时于 Apple Silicon 上失效（[Amphetamine-Enhancer #28](https://github.com/x74353/Amphetamine-Enhancer/issues/28)；以及开发者自己的[会话失败说明](https://iffy.freshdesk.com/support/solutions/articles/48001180528)）；应用本身是闭源的（只有它的支持仓库是开放的）。³ KeepingYouAwake 从设计上就无法在合盖时保持唤醒，因为它只是封装了 `caffeinate`（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。⁴ `caffeinate -i` 可在电池供电下运行；按 man 手册，`-s` 仅在接通电源时有效。欢迎指正。</sub>

## 用它来……

- 🤖 **走开之后让长任务自己跑完。** 一次 AI 智能体运行、一次构建、一次渲染、ML 训练、一个大的 `brew`/`npm` 安装：打开开关，合上盖子，把它放进包里，回来时任务已经完成。
- 📡 **移动中共享你的热点。** Mac 上的互联网共享 / 个人热点在合盖时也会继续提供服务。
- ⬇️ **让大型传输继续运行。** 大文件下载、上传，或一次 Time Machine 备份会在你离开时完成。
- 🖥️ **保持服务器或 SSH 会话存活。** 本地开发服务器、同步守护进程，或远程会话在合盖时仍然可达。
- 🎧 **让音频持续播放。** 音乐或长时间渲染会在包里继续进行。

> [!TIP]
> 把电量下限设到你信得过的水平（比如 20%），再加一个自动关闭定时器，上面这些事你都能做，而不必盯着电量。

## 工作原理

`caffeinate` 以及它所用的电源断言无法覆盖硬件层面的合盖触发，所以合上盖子总是会让 Mac 睡眠。唯一能覆盖它的系统设置是 `pmset disablesleep`，它会切换内核的 `SleepDisabled` 标志。Sleepless 从一个原生开关来切换它，把实时值读回来让界面绝不撒谎，并在到达你的电量下限、进入 Low Power Mode 或定时器结束时把它还原。重启同样会把它重置。

由于 GUI 应用无法输入密码，安装程序会添加一条范围严格限定的 `/etc/sudoers.d` 规则（root 所有，`0440`），它**只允许两条命令，别无其他**：

```
<you> ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1
```

- **它无法被放宽。** `sudoers` 按字面匹配参数，没有通配符，所以任何其他命令都会重新要求密码。
- **没有守护进程、没有辅助脚本**可供攻击者劫持。它直接用一个 argv 数组调用 Apple 的 `/usr/bin/pmset`，不经过 shell。
- **始终可逆。** 重启会重置该标志，电量下限和定时器会把它关掉，`./uninstall.sh` 会移除授权并加以证明。

完整的威胁模型、未被记录但真实存在的 `disablesleep` 证据、它为何无法上架 Mac App Store，以及如何验证下载，都在 **[SECURITY.md](SECURITY.md)** 和 **[docs/AUDIT.md](docs/AUDIT.md)** 中。

## 常见问题

<details>
<summary><b>怎样在没有显示器的情况下合盖让 MacBook 不休眠？</b></summary>

安装 Sleepless，点击菜单栏里的咖啡杯，拨动开关打开，然后合上盖子。它会用 `pmset disablesleep` 让 Mac 在电池供电、没有外接显示器的情况下保持唤醒。不需要假 HDMI 插头，也不需要 clamshell 转接器。
</details>

<details>
<summary><b>为什么装了 Amphetamine 或 KeepingYouAwake，合盖时 MacBook 还是会睡眠？</b></summary>

因为这些工具都建立在 macOS 的电源断言之上，电源断言能阻止空闲计时器，但无法覆盖硬件层面的合盖触发。KeepingYouAwake 封装的是 `caffeinate`，它的维护者也确认它“doesn't support this”（[issue #66](https://github.com/newmarcel/KeepingYouAwake/issues/66)）。Amphetamine 试图做到，但被普遍反映会在电源切换时于 Apple Silicon 上失效。而 Sleepless 使用的 `pmset disablesleep` 是一个更底层的设置，可以覆盖合盖睡眠。
</details>

<details>
<summary><b><code>pmset disablesleep</code> 在 Apple Silicon（M1/M2/M3）上还有效吗？</b></summary>

`pmset -a disablesleep 1` 在 Apple Silicon 上仍然会设置 `SleepDisabled` 标志，并且在第一手反馈中，确实能让 MacBook 在合盖、电池供电的情况下保持唤醒，不过 Apple 并未官方记录这个设置，所以它的具体表现可能因机型和 macOS 版本而异。你可以在自己的机器上用 `pmset -g | grep SleepDisabled` 来验证（它应该读作 `1`）。大多数说它“在 M1/M2/M3 上不再有效”的说法，其实描述的是 `caffeinate` 或基于 caffeinate 的应用（Amphetamine、KeepingYouAwake），它们本来就无法阻止合盖睡眠，那是另一套机制，并不是 `pmset disablesleep` 的退化。
</details>

<details>
<summary><b>能让 MacBook 在合盖、电池供电的情况下保持唤醒吗？</b></summary>

可以。这正是 Sleepless 的全部意义，也是它和基于 `caffeinate` 的应用拉开差距的地方。设一个电量下限和一个自动关闭定时器，它在无人看管运行时就不会把 Mac 的电耗光。
</details>

<details>
<summary><b><code>caffeinate</code> 和禁用合盖睡眠有什么区别？</b></summary>

`caffeinate` 持有一个电源断言，在开盖时阻止*空闲*睡眠，但它无法阻止合上盖子让 Mac 睡眠。而用 `pmset disablesleep` 禁用合盖睡眠会切换一个内核标志，直接覆盖合盖触发本身，这就是它在合盖时仍然有效的原因。
</details>

<details>
<summary><b>Sleepless 和 Amphetamine、KeepingYouAwake 有什么不同？</b></summary>

Sleepless 只做一件事，合盖、电池供电时保持唤醒，并且采用安全优先的设计：一个自动关闭定时器、一个电量下限截止、Low Power Mode 自动关闭，以及重启重置。它是开源的（MIT），是一个小小的 AppKit 文件，没有守护进程也没有 kext，而且它使用 `pmset disablesleep`，而不是限制其他工具的那套断言层。
</details>

<details>
<summary><b>合盖运行 MacBook 安全吗？会过热或耗光电池吗？</b></summary>

对于下载、同步或共享热点这类轻量、无人看管的任务来说是安全的。如果在完全合盖的情况下长时间高负载运行，散热气流会受限，所以那种场景要自己掂量。为了保护电池，Sleepless 会在你设定的下限处以及 Low Power Mode 下自动关闭，自动关闭定时器也会限制它保持开启的时长。
</details>

<details>
<summary><b>用 clamshell 模式需要插一个假 HDMI 显示器插头吗？</b></summary>

不需要。Apple 官方的 clamshell 模式需要外接电源和显示器，但 Sleepless 只靠电池就能让 Mac 在合盖时保持唤醒，不需要显示器，也不需要 HDMI 转接头。
</details>

<details>
<summary><b>Sleepless 需要 sudo、内核扩展或后台守护进程吗？</b></summary>

它需要一条范围严格限定的 `sudo` 授权（两条精确的 `pmset` 命令，别无其他），这样 GUI 应用才能在不弹出密码提示的情况下切换这个设置。没有内核扩展，也没有后台守护进程。整个应用就是一个 AppKit 文件。
</details>

<details>
<summary><b>菜单栏里没有显示咖啡杯。</b></summary>

macOS 26 可能会隐藏菜单栏项目。请检查系统设置（控制中心 / 菜单栏），允许 Sleepless 显示它的项目。用 <code>pgrep -x Sleepless</code> 确认它正在运行。
</details>

<details>
<summary><b>怎样停止 Sleepless 并恢复正常睡眠？</b></summary>

把开关关掉，或者让自动关闭定时器或电量下限替你关掉它，正常睡眠会立即恢复。重启同样会把它重置，`./uninstall.sh` 会移除应用、登录项和 sudoers 授权，然后证明授权已经清除。
</details>

<details>
<summary><b>能合盖整夜跑 AI 智能体或长任务吗？</b></summary>

可以。打开 Sleepless，设一个电量下限，合上盖子，AI 智能体运行、构建、渲染或训练任务都会继续跑。要通宵跑就接上电源，或者保持电池供电并设好下限和定时器，让它在电量过低之前自己停下来。
</details>

<details>
<summary><b>为什么它没有公证？</b></summary>

它是一个个人的开源工具，没有付费的 Apple Developer ID，所以采用临时签名（ad-hoc）。从源码构建可以完全跳过 Gatekeeper，或者对预构建的应用使用 **仍要打开** 流程。公证已在 [docs/AUDIT.md](docs/AUDIT.md) 中作为计划中的下一步记录在案。
</details>

<details>
<summary><b>它能在 Intel 或更旧的 macOS 上工作吗？</b></summary>

它已在 **macOS 26 Apple Silicon** 上验证。`disablesleep` 未被记录，所以其他版本或硬件不保证可用。试一试并反馈，欢迎诚实的报告。
</details>

## 参与贡献

欢迎提交 Issue 和 PR，尤其欢迎翻译以及来自其他硬件的测试报告。请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 和[行为准则](CODE_OF_CONDUCT.md)。Sleepless 会刻意保持小巧。

## 许可证

[MIT](LICENSE) © 2026 Adam Boudjemaa。

<p align="center">
  <sub>如果 Sleepless 帮你省去了一趟终端，点个 ⭐ 能帮助更多人发现它。</sub>
</p>
