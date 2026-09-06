<p align="center">
  <img src="assets/nonap-icon.png" width="112" alt="NoNap 图标">
</p>

<h1 align="center">NoNap</h1>

<p align="center"><strong>合盖不停工。</strong></p>
<p align="center"><a href="README.md">English</a></p>

NoNap 是一个轻量的 macOS 菜单栏工具，适合需要长时间运行本地任务的人。合盖前打开开关，MacBook 即使没有外接显示器，也可以继续编译、下载、训练模型或运行智能体任务。

它使用 macOS 原生的 `pmset disablesleep` 设置，不安装守护进程或内核扩展，不需要账号，也不收集遥测数据。

## 界面

<p align="center">
  <img src="assets/nonap-panel.png" width="296" alt="NoNap 菜单栏界面">
</p>

## 功能

- 一个开关控制合盖后是否继续运行。
- 自动停止时间可设为 0–24 小时；`0` 表示不限时。
- 电量保护阈值可设为 5%–50%。
- 使用电池且进入低电量模式时自动停止。
- 根据 macOS IOKit 数据显示预计可用时间，仅供参考。
- 可选“登录时打开”，界面支持简体中文和英文。

首次启动时，Mac 的首选语言以 `zh` 开头便使用简体中文，否则使用英文。手动选择语言后，NoNap 会记住该选择。

## 安装

NoNap 目前面向运行 macOS 26 或更高版本的 Apple 芯片 Mac。

```sh
git clone https://github.com/Tsan1024/NoNap.git
cd NoNap
./install.sh
```

安装脚本会构建 `/Applications/NoNap.app`，请求一次管理员授权，写入一条严格限定的 sudoers 规则，然后启动应用。

该规则只允许当前用户免密执行以下两个命令：

```text
/usr/bin/pmset -a disablesleep 0
/usr/bin/pmset -a disablesleep 1
```

只构建应用、不安装：

```sh
./build.sh
```

制作 DMG 安装包：

```sh
./package.sh
```

## 卸载

```sh
./uninstall.sh
```

卸载脚本会恢复正常睡眠、移除应用和登录项、删除 sudoers 规则，并验证 `pmset` 已无法免密执行。

## 使用提醒

合盖运行可能增加发热和耗电。请保证电脑通风，设置合适的电量保护阈值；长时间无人看管时，建议同时设置自动停止时间。预计可用时间会随负载变化，不参与安全保护判断。

权限模型见 [SECURITY.md](SECURITY.md)，验证步骤见 [docs/AUDIT.md](docs/AUDIT.md)。

## 致谢

NoNap 最初衍生自 Adam Boudjemaa 创建的 [Sleepless](https://github.com/Aboudjem/Sleepless)。感谢 Adam 与 Sleepless 项目提供最初的菜单栏实现和 `pmset` 思路。NoNap 现为独立维护项目，并非 Sleepless 官方版本；原始版权声明依照 MIT 许可证继续保留。

## 许可证

[MIT](LICENSE)
